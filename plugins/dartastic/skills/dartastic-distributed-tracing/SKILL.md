---
name: dartastic-distributed-tracing
description: Join a Flutter app's traces to its backends with Dartastic so one trace runs from a tap through every server, function and database call - W3C traceparent and baggage propagation, Dart servers (shelf, Serverpod, gRPC, dart_frog), Firebase Functions in Dart with Dartastic, Firebase Functions in TypeScript with OpenTelemetry JS, callables, CORS for Flutter web, and flushing in serverless. Use this whenever someone connects app and backend telemetry, instruments an API, server, Cloud Function, Cloud Run service or microservice, sees app and server spans in separate traces, asks about traceparent, context propagation or baggage, or sees CORS failures after adding tracing.
---

# Distributed tracing with Dartastic

One trace should run from the user's tap, through the app's HTTP call,
into every service that call touched, and back. That needs three things:

1. The **client** creates a span for each request and sends its context
   in the W3C `traceparent` header (plus `tracestate` and `baggage`).
2. Each **server** reads that header, makes its own span a child of it,
   and makes that span current while it handles the request, so its own
   outgoing calls and database spans nest under it.
3. Every service **exports to the same Dartastic organization**, each with
   its own `service.name`.

When any link is missing, the app and the server show up as two separate
traces. Find the broken link before adding more instrumentation.

## The client side (Flutter or Dart)

DOTel does not wrap HTTP itself. Use the instrumented client for the HTTP
library the app already uses (details in `dartastic-integrations`):

```dart
// package:http
final client = OTelHttpClient(http.Client(),
    ignoreUrlPatterns: [RegExp(r'^https://otlp\.')]);   // never trace the exporter

// package:dio: add it first in the chain
final dio = Dio()..interceptors.insert(0, OTelDioInterceptor());
```

Create these after `DOTel.initialize`, and use one client everywhere. A
request made inside a tap handler is automatically a child of the tap's
span.

**Third-party hosts.** The client adds `traceparent` to every request. For
a host that rejects unknown headers (some CDNs, map-tile and payment
APIs, especially from Flutter web, where an extra header triggers a CORS
preflight), list it in `ignoreUrlPatterns`, or use a separate plain
client for it. Never send trace headers to a host the developer doesn't
control without a reason.

**Firebase callables do not carry headers.** `cloud_functions`'
`httpsCallable` has no way to add `traceparent`. `otel_cloud_functions`
records the client span, but the function's span starts a new trace. Two
fixes, in order of preference:

1. Make the function an HTTPS function (`onRequest`) and call it with the
   instrumented HTTP client. The trace joins with no extra code.
2. Keep the callable and pass the context in its data, then extract it in
   the function (see the Firebase references):

   ```dart
   final carrier = <String, String>{};
   // MapSetter: the four-line helper in references/dart-servers.md.
   OTelAPI.textMapPropagator.inject(Context.current, carrier, MapSetter(carrier));
   await callable.call({...payload, '_trace': carrier});
   ```

**Baggage** carries a value to every service in the trace (a tenant id, an
experiment arm). Keep it small, never personal, and remember every
downstream service, including third parties, can read it.

## The server side

Pick the reference for the backend:

| Backend                                    | Read                                                                                                                   |
|--------------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| Dart: shelf, dart_frog, Serverpod, gRPC    | `references/dart-servers.md`                                                                                           |
| Firebase Functions in Dart (Dartastic)     | `references/firebase-functions-dart.md`                                                                                |
| Firebase Functions in TypeScript (OTel JS) | `references/firebase-functions-typescript.md`                                                                          |
| Anything else (Go, Java, Python, Node...)  | Use that language's OpenTelemetry SDK with the W3C propagator, and export to the same OTLP endpoint with an OTLP token |

All of them export with the same two standard variables as the app:

```sh
OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.cloud.dartastic.io
OTEL_EXPORTER_OTLP_HEADERS=authorization=Bearer <OTLP token>
```

Store the token in the platform's secret store (Secret Manager, the CI's
secrets), never in the repo. Use an **OTLP** token on servers. A Browser
OTLP token is only for web pages, and an OTLP token sent from a browser
is refused.

## Flutter web: CORS

From a browser, `traceparent`, `tracestate` and `baggage` are non-simple
headers, so the browser sends a preflight `OPTIONS` request first. Every
API the web app calls with trace headers must allow them:

```text
Access-Control-Allow-Headers: Content-Type, Authorization, traceparent, tracestate, baggage
```

Put the CORS handling **outside** the tracing middleware, so preflights
don't become spans. A hand-written CORS allow-list that predates tracing
is the usual culprit when "the web build broke after adding tracing".
Firebase Functions' own `cors:` option reflects the requested headers, so
it needs no change.

## Serverless: export before the instance freezes

Cloud Run, Cloud Functions and Lambda may stop giving the instance CPU as
soon as the response is sent, and they stop instances without warning
beyond a short `SIGTERM`. So:

- **Shut the SDK down on `SIGTERM`**, which flushes what is queued (about
  10 seconds of grace on Cloud Run).
- **For low-traffic functions, flush before returning** the response, or
  the last spans can wait in the queue until the next request (or be
  lost). The references show both.
- Don't start the SDK per request. Start it once per instance.

## Naming the services

Each backend gets its own `service.name` (`orders-api`, `payments-worker`).
For many functions in one codebase, one `service.name` plus `faas.name`
per function keeps them comparable. See `dartastic-resource-attributes`.

## Check it

Make one request from the app, then with `dartastic-verify-telemetry`
find the trace and confirm it contains the app's client span, the
server's span as its child (same trace id), and the server's own child
spans. If the server span has a different trace id, the header did not
arrive or was not extracted; if it has the same trace id but its own
children are siblings, the server span was not made current.
