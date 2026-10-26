---
name: dartastic-integrations
description: Instrument the libraries a Flutter or Dart app uses with Dartastic - HTTP (http, dio, chopper), routing (go_router, auto_route), Firebase (Firestore, Auth, Functions, Analytics), state management (bloc, riverpod, provider), logging (logging, logger, talker), storage and databases, gRPC and GraphQL - with the otel_* packages, and add well-named spans and metrics around LLM calls (OpenAI, Anthropic, Gemini, Firebase AI, Vertex AI), Stripe payments and RevenueCat purchases. Use this whenever someone asks how to trace or monitor a specific package or SDK, wants network requests, navigation, database queries, AI calls, payments or subscriptions to show up in the Observatory, or asks "is there an otel package for X".
---

# Integrations: the libraries around the app

Most of what an app does happens inside libraries. Instrument the
library once, at the place it is created, rather than wrapping every
call site.

## Rules for every `otel_*` package

- Packages named `otel_<library>` are on pub.dev and work with DOTel.
  They need the `dependency_overrides` entry for `dartastic_opentelemetry`
  from Dartastic Pub (`dartastic-flutter-setup`, Step 2); without it,
  version solving fails.
- **Create observers, interceptors and clients after `DOTel.initialize`.**
  They look up their tracer when constructed, and get a no-op one before.
- **Configure once, where the library is created** (the `Dio` instance,
  the `GoRouter`, the `Bloc.observer`), and reuse it.
- **Keep values opt-in.** Packages that can record payloads (state
  values, SQL text, event parameters) keep that off by default. Turn it
  on only for data with nothing personal in it.
- **Don't trace the exporter.** Exclude the OTLP host from HTTP
  instrumentation (`ignoreUrlPatterns`), or every export creates a span
  that is itself exported.

## The common ones

```dart
// HTTP: package:http
final client = OTelHttpClient(http.Client(),
    ignoreUrlPatterns: [RegExp(r'^https://otlp\.')]);

// HTTP: dio (first in the chain, so it sees the final request)
final dio = Dio()..interceptors.insert(0, OTelDioInterceptor());

// Routing: go_router, plus the same observers on each ShellRoute
final router = GoRouter(
  observers: [DartasticViewObserver(), DartasticFlutterMetrics.navigatorObserver, OTelGoRouterObserver()],
  routes: [...],
);

// State: bloc (combine with MultiBlocObserver if the app has its own)
Bloc.observer = OTelBlocObserver();

// Logging: package:logging records become OpenTelemetry logs on the active span
PackageLoggingBridge.install();

// Firebase callable (records the client span; see dartastic-distributed-tracing
// for why the function's span starts a new trace, and the fix)
final result = await tracedHttpsCall(
    FirebaseFunctions.instance.httpsCallable('placeOrder'),
    name: 'placeOrder', parameters: payload);
```

HTTP instrumentation matters most: it creates the client span for each
request, sends `traceparent` to the server, and lets Dartastic see the
network calls behind error taps and slow screens.

`references/catalog.md` lists every package, what it instruments and its
one-line setup. Check pub.dev for the current version before adding one.

## Libraries without a package

For a library that has no `otel_*` package, wrap the few functions the
app calls through, in one place (a repository or service class), with a
`CLIENT` span using the OpenTelemetry semantic conventions for that kind
of call. Name the span `<operation> <target>`, set the convention's
attributes, record errors, and keep payloads out.

Read the reference that fits:

| Calls to                                                                            | Read                     |
|-------------------------------------------------------------------------------------|--------------------------|
| LLMs: OpenAI, Anthropic, Gemini, Firebase AI, Vertex AI, any chat or embeddings API | `references/llm.md`      |
| Payments and subscriptions: Stripe, RevenueCat, in-app purchase                     | `references/payments.md` |

## Check it

Exercise the instrumented code, then with `dartastic-verify-telemetry`
search for the spans by name and open one trace. Confirm the spans nest
under the tap or request that caused them, and that no payload or
personal data is in their attributes.
