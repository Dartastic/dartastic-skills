---
name: dartastic-integrations
description: Instrument the libraries a Flutter or Dart app uses with Dartastic - HTTP (http, dio, chopper), routing (go_router, auto_route), Firebase (Firestore, Auth, Functions, Analytics), state management (bloc, riverpod, provider), logging (logging, logger, talker), storage and databases, gRPC and GraphQL - and hundreds of services (AWS, Azure, Google Cloud, Supabase, Twilio, Segment, Algolia, Stripe, RevenueCat, OpenAI, Anthropic, Gemini, Vertex AI and more) with the 651 open-source otel_* packages, and add well-named spans and metrics around LLM calls, payments and subscriptions. Use this whenever someone asks how to trace or monitor a specific package, SDK or third-party service, wants network requests, navigation, database queries, AI calls, payments or subscriptions to show up in the Observatory, or asks "is there an otel package for X".
---

# Integrations: the libraries around the app

Most of what an app does happens inside libraries. Instrument the
library once, at the place it is created, rather than wrapping every
call site.

## Rules for every `otel_*` package

- **Look in the catalog first.** There are 651 `otel_<name>` packages,
  for Dart libraries and for hundreds of services (AWS, Azure, Google
  Cloud, Supabase, Twilio, Segment, Algolia and so on). All are open
  source on pub.dev and depend only on the OpenTelemetry API, so they
  report through DOTel after a plain `flutter pub add otel_<name>`. Search
  `references/catalog.md` for the library or service before writing any
  instrumentation by hand.
- **Not on pub.dev yet?** The packages are being released one by one. If
  pub cannot find one, wrap the call by hand (below) and tell the
  developer the package exists, so they can switch when it lands.
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

`references/catalog.md` lists every package by category, what it
instruments and its entry point. Read the package's README for the version
you got: it has the full setup and what each helper's `invoke` returns.

## Libraries without a package

For a library with no `otel_*` package, or one not released yet, wrap the few functions the
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
