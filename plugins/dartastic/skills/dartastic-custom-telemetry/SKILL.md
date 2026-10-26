---
name: dartastic-custom-telemetry
description: Add an app's or server's own OpenTelemetry spans, metrics, logs and attributes with Dartastic (DOTel) in Dart and Flutter, named and shaped so they are useful in the Observatory - span names, attribute keys as constants, semantic conventions, histograms with the right buckets, counters, cardinality limits, and privacy. Use this whenever someone wants to trace a function or business flow, time something, count something, add a custom metric or log, add attributes or tags to spans, record business events (checkout, sign-up, search), or asks how to name telemetry, even if they only say "track", "measure" or "log this".
---

# Custom telemetry with Dartastic

Automatic instrumentation shows what the app did. Custom telemetry shows
what it meant: a checkout, a search, a sync. Add it where a question
about the product would otherwise have no answer, not everywhere.

Get the instruments from `DOTel` after `DOTel.initialize`:

```dart
final tracer = DOTel.tracer('checkout');
final meter = DOTel.meter('checkout');
final logger = DOTel.logger('checkout');
```

The name is the instrumentation scope: the area of the code it comes
from. Use one per feature or module, not one per class.

## Spans: one per meaningful unit of work

```dart
Future<Receipt> placeOrder(Cart cart) =>
    tracer.startActiveSpanAsync(
      name: 'checkout.place_order',
      attributes: DOTel.attributesFromSemanticMap({
        Checkout.cartItems: cart.items.length,
        Checkout.paymentMethod: cart.paymentMethod.name,
      }),
      fn: (span) async {
        final receipt = await api.placeOrder(cart);
        span.setStringAttribute(Checkout.orderId.key, receipt.orderId);
        return receipt;
      },
    );
```

- `startActiveSpanAsync` makes the span current for everything inside
  `fn`, so HTTP calls and child spans nest under it, and it records an
  exception and sets the error status if `fn` throws. Prefer it to
  `startSpan` plus a hand-written `try`/`finally`.
- Use `startSpan` only when the work does not fit a closure, and always
  end the span in `finally`.
- **Name spans by the operation, with low cardinality**:
  `checkout.place_order`, `search.query`, `sync.upload`. Never put ids,
  user input, URLs or counts in a span name; those are attributes.
- Don't wrap trivial synchronous code. A span costs a little on every
  call; a hot loop of spans costs a lot. Measure frequent work with a
  histogram instead.
- Inside a tap handler, spans automatically nest under the tap's span
  (`tap checkout`). Don't start a separate root span for a user action.

## Attribute keys are constants, never inline strings

A key typed twice is a key spelled two ways. Declare the app's own keys
once, as an enum implementing `OTelSemantic`:

```dart
/// Telemetry keys for checkout. One place, so a key is spelled one way.
enum Checkout implements OTelSemantic {
  cartItems('acme.checkout.cart_items'),
  paymentMethod('acme.checkout.payment_method'),
  orderId('acme.checkout.order_id');

  const Checkout(this.key);
  @override
  final String key;
}
```

Then:

- **Use an OpenTelemetry convention when one fits** before inventing a
  key. They ship with the SDK as enums: `ErrorAttributes.errorType`,
  `Http...`, `Db...`, `App.appScreenName`, `User.userId` and many more.
  (For LLM calls, see `dartastic-integrations`' `references/llm.md`.) Browse them in your editor, or ask the Dartastic MCP's
  `describe_telemetry` tool what a key means.
- **The app's own keys go under the developer's namespace** (`acme.`),
  in `snake_case` segments separated by dots. Never use `dartastic.*`,
  `app.*`, `session.*` or any other namespace OpenTelemetry or Dartastic
  defines; telemetry that claims them can be rejected or misread.
- Build attribute sets with `DOTel.attributesFromSemanticMap({...})`, so
  the keys stay typed.
- Values: strings, booleans, ints, doubles, or lists of one of those.
  Enums go in as `.name`.

## Metrics: counters for counts, histograms for durations and sizes

```dart
final ordersPlaced = meter.createCounter<int>(
  name: 'acme.checkout.orders',
  unit: '{order}',
  description: 'Orders placed.',
);
ordersPlaced.add(1, DOTel.attributesFromSemanticMap({
  Checkout.paymentMethod: method.name,
}));
```

For a histogram, use a semantic-convention metric when one fits, with
`createHistogramFor`, which creates it with the convention's name, unit,
description and recommended bucket boundaries:

```dart
final duration = meter.createHistogramFor<double>(
    RegistryMetric.httpClientRequestDuration);
```

For the app's own histogram, choose the unit and the buckets yourself:

```dart
final syncDuration = meter.createHistogram<double>(
  name: 'acme.sync.duration',
  unit: 's',
  description: 'Time to sync the local store with the server.',
  advisory: InstrumentAdvisory(explicitBucketBoundaries: [
    0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30,
  ]),
);
```

- **Durations in seconds (`s`) as doubles**, as OpenTelemetry recommends.
  The SDK's default buckets fit milliseconds (0 to 10000), so a seconds
  histogram without explicit buckets puts nearly every value in the first
  bucket. Always give buckets that cover the real range.
- Create each instrument **once** (a field or a top-level final), not per
  call.
- Units in UCUM form: `s`, `ms`, `By` (bytes), `1` (a ratio), `{order}`
  (a count of things).
- A gauge for a value you read rather than count (queue depth, cache
  size): `createObservableGauge` with a callback.

## Cardinality: the rule that keeps metrics useful

Every distinct combination of metric attribute values is a separate time
series. Keep metric attributes to a small, fixed set of values:
`payment_method` (5 values) yes; `order_id`, `user_id`, a URL, an error
message or a timestamp, never. Those belong on spans and logs, which are
searched, not aggregated. If you can't list a metric attribute's possible
values, it doesn't belong on the metric.

## Logs: events and breadcrumbs

```dart
logger.emit(
  severityNumber: Severity.INFO,
  body: 'Order placed',
  attributes: DOTel.attributesFromSemanticMap({Checkout.orderId: id}),
);
```

- A log emitted inside a span carries that span's trace and span id, so it
  shows on the trace. Emit inside the work, not after it.
- If the app already uses `package:logging`, `logger` or another logging
  library, bridge it with the matching `otel_*` package (see
  `dartastic-integrations`) instead of rewriting every call.
- To send `print()` output too, pass `logPrint: true` to `DOTel.initialize`.
- For a business event to count and chart, emit a log with an
  `eventName:` (`acme.checkout.completed`) and attributes, rather than a
  sentence in the body.

## Users, tenants and baggage

- The signed-in user: `DOTel.setUser(opaqueId)` (see `dartastic-flutter-setup`).
- A value every span in a request should carry, and that the backend
  should see too (a tenant id, an experiment arm), goes in baggage, which
  travels with the trace context to servers. See
  `dartastic-distributed-tracing`.

## Privacy

Telemetry is stored as sent. Never record passwords, tokens, payment
card numbers, full addresses, email addresses or message contents in
span names, attributes, metric attributes or log bodies. Use opaque ids.
When in doubt, leave it out, and ask the developer.

## Check it

Run the flow, then with `dartastic-verify-telemetry` search for the span
by name, open its trace, and query the metric. Confirm the names, units
and attribute values are what you intended.
