# Firebase Functions in TypeScript, with OpenTelemetry JS

TypeScript functions use the standard OpenTelemetry Node SDK and export
over OTLP/HTTP to the organization's OTLP endpoint. Nothing
Dartastic-specific is installed: the endpoint and the OTLP token are all
Dartastic needs. This setup runs in production on Firebase Functions
(2nd gen).

## Packages

```sh
npm install @opentelemetry/api @opentelemetry/sdk-node \
  @opentelemetry/exporter-trace-otlp-http @opentelemetry/exporter-metrics-otlp-http \
  @opentelemetry/exporter-logs-otlp-http @opentelemetry/sdk-metrics @opentelemetry/sdk-logs \
  @opentelemetry/instrumentation-http @opentelemetry/instrumentation-express \
  @opentelemetry/resources @opentelemetry/semantic-conventions
```

**Don't use `@opentelemetry/auto-instrumentations-node`.** It loads every
instrumentation package (about 40) at start, which costs cold-start time
and has taken a function down when one unused package failed to load.
List only the instrumentations the code needs.

## `src/otel.ts`

```ts
import {diag, DiagLogLevel} from "@opentelemetry/api";
import {NodeSDK} from "@opentelemetry/sdk-node";
import {HttpInstrumentation} from "@opentelemetry/instrumentation-http";
import {ExpressInstrumentation} from "@opentelemetry/instrumentation-express";
import {OTLPTraceExporter} from "@opentelemetry/exporter-trace-otlp-http";
import {OTLPMetricExporter} from "@opentelemetry/exporter-metrics-otlp-http";
import {OTLPLogExporter} from "@opentelemetry/exporter-logs-otlp-http";
import {PeriodicExportingMetricReader} from "@opentelemetry/sdk-metrics";
import {BatchLogRecordProcessor} from "@opentelemetry/sdk-logs";
import {resourceFromAttributes} from "@opentelemetry/resources";
import {ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION} from "@opentelemetry/semantic-conventions";

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT;
const headers = parseHeaders(process.env.OTEL_EXPORTER_OTLP_HEADERS);

if (process.env.OTEL_SDK_DISABLED !== "true" && endpoint && headers) {
  // Export failures go to diag, which is silent unless a logger is set.
  diag.setLogger({
    error: (m, ...a) => console.error("OTEL EXPORT FAILED:", m, ...a),
    warn: () => {}, info: () => {}, debug: () => {}, verbose: () => {},
  }, DiagLogLevel.ERROR);

  const sdk = new NodeSDK({
    resource: resourceFromAttributes({
      [ATTR_SERVICE_NAME]: "acme-functions",
      [ATTR_SERVICE_VERSION]: process.env.RELEASE ?? "unknown",
      "deployment.environment.name": environmentFor(process.env.GCLOUD_PROJECT),
    }),
    traceExporter: new OTLPTraceExporter({url: `${endpoint}/v1/traces`, headers}),
    metricReaders: [new PeriodicExportingMetricReader({
      exporter: new OTLPMetricExporter({url: `${endpoint}/v1/metrics`, headers}),
      exportIntervalMillis: 60_000,
    })],
    logRecordProcessors: [new BatchLogRecordProcessor({
      exporter: new OTLPLogExporter({url: `${endpoint}/v1/logs`, headers}),
    })],
    instrumentations: [new HttpInstrumentation(), new ExpressInstrumentation()],
  });
  sdk.start();
  // Cloud Run sends SIGTERM about 10 s before it stops an instance.
  process.once("SIGTERM", () => void sdk.shutdown().catch(() => {}));
}

/** "authorization=Bearer <token>" (comma-separated k=v, values percent-decoded). */
function parseHeaders(raw?: string): Record<string, string> | undefined {
  if (!raw) return undefined;
  const out: Record<string, string> = {};
  for (const pair of raw.split(",")) {
    const eq = pair.indexOf("=");
    if (eq > 0) out[pair.slice(0, eq).trim()] = decodeURIComponent(pair.slice(eq + 1).trim());
  }
  return out.authorization ? out : undefined;
}

function environmentFor(project?: string): string {
  if (process.env.FUNCTIONS_EMULATOR === "true") return "local";
  // Map each Firebase project to its environment; never guess "prod".
  const byProject: Record<string, string> = {"acme-dev": "dev", "acme-prod": "prod"};
  const env = project && byProject[project];
  if (!env) throw new Error(`no deployment environment for project ${project}`);
  return env;
}
```

Fill in the service name, the project map and how the release is stamped.

## `src/index.ts`: import it first

```ts
import "./otel";            // MUST be first: instrumentation patches http at load
import {onRequest, onCall} from "firebase-functions/v2/https";
```

Anything that loads `http` before `./otel` is not traced.

## Bind the endpoint and the token to every function

```ts
import {defineSecret, defineString} from "firebase-functions/params";
// Declared so the CLI asks for the endpoint at deploy; it reaches the
// function as the environment variable of the same name.
export const otlpEndpoint = defineString("OTEL_EXPORTER_OTLP_ENDPOINT");
export const otlpHeaders = defineSecret("OTEL_EXPORTER_OTLP_HEADERS");

export const quote = onRequest({secrets: [otlpHeaders], cors: true}, async (req, res) => {
  ...
});
```

- Set the secret with `firebase functions:secrets:set OTEL_EXPORTER_OTLP_HEADERS`
  (value `authorization=Bearer <OTLP token>`), typed by the developer.
- A function's own `secrets` list **replaces** any global list, so each
  function must name the OTLP secret. Keep one shared constant, and a test
  that every exported function binds it.
- Turn off Google's client-library tracing so it does not double-trace or
  fight the SDK: `GOOGLE_CLOUD_OPENTELEMETRY_TRACING_ENABLED=false`.
- In the emulator, set `OTEL_SDK_DISABLED=true` unless you want local
  spans.

## Joining the app's trace

- **`onRequest`**: `HttpInstrumentation` reads `traceparent` and makes the
  request's span a child of the app's span, with no code. Add attributes to
  it with `trace.getActiveSpan()?.setAttributes({...})`.
- **`onCall`**: the Firebase client cannot add headers. If the app passes
  its context in the data (see the skill), continue it:

  ```ts
  import {propagation, trace, ROOT_CONTEXT, SpanKind, SpanStatusCode} from "@opentelemetry/api";

  export const placeOrder = onCall({secrets: [otlpHeaders]}, async (request) => {
    const parent = propagation.extract(ROOT_CONTEXT, request.data?._trace ?? {});
    const tracer = trace.getTracer("functions");
    return tracer.startActiveSpan("placeOrder", {kind: SpanKind.SERVER}, parent, async (span) => {
      try {
        return await placeOrderImpl(request.data);
      } catch (e) {
        span.recordException(e as Error);
        span.setStatus({code: SpanStatusCode.ERROR});
        throw e;
      } finally {
        span.end();
      }
    });
  });
  ```

- **Calling the next service**: outgoing `http`/`https` calls made while a
  span is current carry `traceparent` automatically through
  `HttpInstrumentation`. Node's built-in `fetch` is not `http`: add
  `@opentelemetry/instrumentation-undici` (`new UndiciInstrumentation()`)
  if the code uses `fetch`. For any other client, inject by hand with
  `propagation.inject(context.active(), headers)`.

## Flushing

The batch processor exports in the background, and Cloud Run may give an
instance no CPU once the response is sent. The `SIGTERM` shutdown covers
instances being stopped. For a low-traffic function whose spans must not
wait for the next request, flush before responding:

```ts
// in otel.ts
import {trace, ProxyTracerProvider} from "@opentelemetry/api";
export async function flushTelemetry(): Promise<void> {
  const provider = (trace.getTracerProvider() as ProxyTracerProvider).getDelegate() as
    {forceFlush?: () => Promise<void>};
  await provider.forceFlush?.().catch(() => {});
}

// in a handler, just before res.send(...) or return
await flushTelemetry();
```

## Cold starts

The SDK with two instrumentations adds roughly 0.1 to 0.2 seconds to a
cold start. Keep the instrumentation list short, and keep heavy clients
(Firestore, Secret Manager) lazy.
