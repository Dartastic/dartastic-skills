# Dart servers with Dartastic

A Dart server depends on `dartastic_opentelemetry_native` (and, for
process and container metrics, `dartastic_opentelemetry_dart_metrics`),
from the organization's Dartastic Pub:

```sh
dart pub add 'dartastic_opentelemetry_native:{"hosted":"https://pub.dartastic.io"}'
dart pub add 'dartastic_opentelemetry_dart_metrics:{"hosted":"https://pub.dartastic.io"}'
```

`otel_*` packages (`otel_postgres`, `otel_redis`, `otel_grpc` and the
rest) come from pub.dev with a plain `dart pub add`.

## Start once, stop cleanly

```dart
import 'dart:io';
import 'package:dartastic_opentelemetry_dart_metrics/dartastic_opentelemetry_dart_metrics.dart';
import 'package:dartastic_opentelemetry_native/dartastic_opentelemetry_native.dart';

Future<void> main() async {
  OTelAPI.setErrorHandler((error, stackTrace) =>
      stderr.writeln('OpenTelemetry: $error'));
  await DOTel.initialize(serviceName: 'orders-api', serviceVersion: release);
  DartasticDartMetrics.start();

  final server = await serve(handler, InternetAddress.anyIPv4,
      int.parse(Platform.environment['PORT'] ?? '8080'));

  // Cloud Run, Kubernetes and Docker send SIGTERM before they kill the
  // process; shutting the SDK down flushes what is still queued.
  ProcessSignal.sigterm.watch().first.then((_) async {
    await server.close();
    await DOTel.shutdown();
    exit(0);
  });
}
```

The endpoint and token come from `OTEL_EXPORTER_OTLP_ENDPOINT` and
`OTEL_EXPORTER_OTLP_HEADERS` in the server's environment. Exiting without
`DOTel.shutdown()` loses the last batch.

## The propagation helpers

The API defines the getter and setter interfaces; a server needs these
two small implementations once:

```dart
/// Reads trace headers from a request's headers, case-insensitively.
final class HeaderGetter implements TextMapGetter<String> {
  HeaderGetter(this._headers);
  final Map<String, String> _headers;

  @override
  String? get(String key) {
    final lower = key.toLowerCase();
    for (final e in _headers.entries) {
      if (e.key.toLowerCase() == lower) return e.value;
    }
    return null;
  }

  @override
  Iterable<String> keys() => _headers.keys;
}

/// Writes trace headers into a map.
final class MapSetter implements TextMapSetter<String> {
  MapSetter(this._carrier);
  final Map<String, String> _carrier;

  @override
  void set(String key, String value) => _carrier[key] = value;
}
```

## shelf (and anything built on it)

The middleware must do three things: extract the inbound context, start a
`SERVER` span as its child, and run the handler **with that span
current**. The last step is what makes the handler's own spans and
outgoing calls its children.

```dart
import 'package:shelf/shelf.dart';

Middleware tracing({String Function(Request)? spanName}) {
  final tracer = DOTel.tracer('http.server');
  return (Handler inner) => (Request request) async {
        final parent = OTelAPI.textMapPropagator.extract(
            Context.current, request.headers, HeaderGetter(request.headers));
        final method = request.method.toUpperCase();
        final span = tracer.startSpan(
          spanName?.call(request) ?? method,
          kind: SpanKind.server,
          context: parent,
          attributes: DOTel.attributesFromSemanticMap({
            Http.httpRequestMethod: method,
            Url.urlPath: request.requestedUri.path,
          }),
        );
        try {
          final response = await parent.withSpan(span).run(() async => inner(request));
          span.setIntAttribute(
              Http.httpResponseStatusCode.key, response.statusCode);
          if (response.statusCode >= 500) {
            span.setStatus(SpanStatusCode.Error, 'HTTP ${response.statusCode}');
          }
          return response;
        } catch (e, s) {
          span.recordException(e, stackTrace: s);
          span.setStatus(SpanStatusCode.Error, e.runtimeType.toString());
          rethrow;
        } finally {
          span.end();
        }
      };
}

final handler = const Pipeline()
    .addMiddleware(cors())          // outside tracing: preflights are not spans
    .addMiddleware(tracing(spanName: (r) => '${r.method} ${routeTemplateOf(r)}'))
    .addHandler(router.call);
```

- **Span names use the route template**, never the raw path:
  `GET /orders/{id}`, not `GET /orders/8812`. Without a template, use the
  method alone. Set `http.route` to the template too when you have it.
- 4xx is the client's error and does not mark the server span as an error;
  5xx does.
- **dart_frog** has no dedicated package. Its middleware is shelf-shaped:
  wrap the same logic in a `_middleware.dart` with
  `handler.use(fromShelfMiddleware(tracing()))`.
- Outgoing calls from the server use `OTelHttpClient` or `OTelDioInterceptor`
  (see `dartastic-integrations`), so the next service joins the trace.

## Serverpod

`otel_serverpod` (pub.dev) does it for you, including database spans:

```dart
await DOTel.initialize(serviceName: 'mypod-server', serviceVersion: release);
final pod = Serverpod(args, Protocol(), Endpoints(),
    databaseInterceptor: OtelServerpod.databaseInterceptor);
OtelServerpod.install(pod);   // after initialize, before start
await pod.start();
```

Endpoint spans are named `POST endpoint.method` with `http.route`. SQL
text is recorded only if you opt in with `captureDbStatements: true`; keep
it off unless the queries carry no personal data. On the app side,
Serverpod's generated client takes an HTTP client: pass it one that
injects `traceparent`.

## gRPC

`otel_grpc` adds `OTelGrpcServerInterceptor` to the server's interceptors
and `OTelGrpcClientInterceptor` to the client channel; both use the
standard propagator.

## Databases and other dependencies

Use the matching `otel_*` package (`otel_postgres`, `otel_redis`,
`otel_mongodb`, `otel_mysql`, ...). Each needs a span to be current to
nest under, which the middleware above provides.
