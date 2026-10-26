# Firebase Functions in Dart, with Dartastic

Firebase's Dart support (`firebase_functions` on pub.dev) is experimental:
enable it with `firebase experiments:enable dartfunctions`. Only HTTPS
(`onRequest`) and callable (`onCall`) functions deploy, and a callable is
called from the app by URL (`httpsCallableFromURL`), not by name. The
handlers are shelf handlers, so the tracing is the same as any Dart
server: see `dart-servers.md` for `HeaderGetter`, `MapSetter` and the
reasoning.

## Dependencies

In `functions/pubspec.yaml`, alongside `firebase_functions`:

```sh
dart pub add 'dartastic_opentelemetry_native:{"hosted":"https://pub.dartastic.io"}'
```

The Firebase CLI compiles the functions on the developer's machine, so
`dart pub token add` for Dartastic Pub must have been run there (or in
the CI job that deploys).

## Endpoint and token

Bind both as Firebase params, so they reach the function as the standard
environment variables the SDK reads:

```dart
final otlpEndpoint = defineString('OTEL_EXPORTER_OTLP_ENDPOINT');
final otlpHeaders = defineSecret('OTEL_EXPORTER_OTLP_HEADERS');
```

Set the secret once with `firebase functions:secrets:set
OTEL_EXPORTER_OTLP_HEADERS` and the value `authorization=Bearer <OTLP token>`,
typed at the prompt by the developer. **Every function that exports must
list the secret** in its options; a function without it runs, but exports
nothing.

## The functions

```dart
import 'package:dartastic_opentelemetry_native/dartastic_opentelemetry_native.dart';
import 'package:firebase_functions/firebase_functions.dart';

Future<void> main(List<String> args) async {
  OTelAPI.setErrorHandler((e, s) => print('OpenTelemetry: $e'));
  await DOTel.initialize(
    serviceName: 'acme-functions',
    serviceVersion: release,
    resourceAttributes: DOTel.attributesFromSemanticMap({
      Cloud.cloudPlatform: 'gcp_cloud_functions',
    }),
  );

  await runFunctions((firebase) {
    firebase.https.onRequest(
      name: 'quote',
      // Secrets are params, not constants; firebase_functions' own examples
      // bind them this way.
      // ignore: non_const_argument_for_const_parameter
      options: HttpsOptions(secrets: [otlpHeaders]),
      (request) => traced('quote', request.headers, () async {
        final quote = await priceFor(request.url.queryParameters['sku']);
        return Response.ok(jsonEncode(quote));
      }),
    );

    firebase.https.onCall(
      name: 'placeOrder',
      // ignore: non_const_argument_for_const_parameter
      options: CallableOptions(secrets: [otlpHeaders]),
      (request, response) {
        final data = request.data! as Map<String, dynamic>;
        // A callable's context comes in its data (see the skill), with the
        // request headers as the fallback when called over plain HTTPS.
        final carrier = {
          ...request.rawRequest.headers,
          ...?(data['_trace'] as Map?)?.cast<String, String>(),
        };
        return traced('placeOrder', carrier, () async {
          final id = await orders.place(data);
          return CallableResult({'orderId': id});
        });
      },
    );
  });
}

/// Runs [body] in a SERVER span that continues the caller's trace, then
/// flushes, because the instance may get no CPU once the response is sent.
Future<T> traced<T>(String name, Map<String, String> carrier,
    Future<T> Function() body) async {
  final parent = OTelAPI.textMapPropagator
      .extract(Context.current, carrier, HeaderGetter(carrier));
  final span = DOTel.tracer('functions').startSpan(name,
      kind: SpanKind.server,
      context: parent,
      attributes: DOTel.attributesFromSemanticMap({Faas.faasName: name}));
  try {
    return await parent.withSpan(span).run(body);
  } catch (e, s) {
    span.recordException(e, stackTrace: s);
    span.setStatus(SpanStatusCode.Error, e.runtimeType.toString());
    rethrow;
  } finally {
    span.end();
    await DOTel.tracerProvider().forceFlush();
  }
}
```

Notes:

- Initialize before `runFunctions`, once per instance, never per request.
- `forceFlush` after each request costs a few milliseconds and makes sure
  the spans leave before the instance is frozen. On a busy function you
  may drop it and rely on the batch and the shutdown flush.
- Use one `service.name` for the codebase and `faas.name` per function,
  or one `service.name` per function; keep to one choice.
- For the app side of a callable, see the skill: pass the context in the
  data, because the Firebase client cannot add headers.
