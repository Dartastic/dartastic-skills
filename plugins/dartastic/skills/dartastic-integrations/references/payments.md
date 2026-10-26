# Payments and subscriptions: Stripe, RevenueCat, in-app purchase

Payment flows are where failures cost the most and are hardest to see.
Trace each step the user waits on, as a `CLIENT` span under the tap that
started it, and count the outcomes. OpenTelemetry has no payment
conventions, so the keys live in the developer's own namespace (`acme.`),
declared once as an enum (see `dartastic-custom-telemetry`).

## Use the package when there is one

`otel_stripe` (`tracedStripeCall(resource:, operation:, invoke:)`),
`otel_revenuecat` (`tracedRevenueCatPurchase`, `tracedRevenueCatRestore`),
`otel_in_app_purchase` (`tracedInAppPurchase(operation:, invoke:)`) and
others in the "Payments, finance and commerce" section of `catalog.md`
create the payment spans with the provider's attributes. Leave their
optional `customerId` and `appUserId` parameters out unless the developer
says to record them (see "Never record"). They don't count outcomes, so
add the counter from this page around them.

When pub cannot find the package yet, use the wrapper below.

## Never record

Card numbers, CVCs, bank details, billing addresses, client secrets,
ephemeral keys, receipts or tokens. Amounts, currencies, product ids,
statuses and error codes are fine. Customer and app-user ids are personal
data in many places: record them only if the developer says so.

## Keys

```dart
enum Payment implements OTelSemantic {
  provider('acme.payment.provider'),        // stripe, revenuecat, app_store, play
  operation('acme.payment.operation'),      // present_sheet, confirm, purchase, restore
  productId('acme.payment.product_id'),
  amount('acme.payment.amount'),            // minor units (cents), an int
  currency('acme.payment.currency'),        // ISO 4217, lowercase
  outcome('acme.payment.outcome');          // succeeded, canceled, failed

  const Payment(this.key);
  @override
  final String key;
}
```

## The wrapper

```dart
final _tracer = DOTel.tracer('payments');
final _outcomes = DOTel.meter('payments').createCounter<int>(
  name: 'acme.payment.attempts',
  unit: '{attempt}',
  description: 'Payment and purchase attempts by outcome.',
);

Future<T> tracedPayment<T>({
  required String provider,
  required String operation,
  String? productId,
  int? amount,
  String? currency,
  required Future<T> Function() call,
  required String Function(T result) outcome,
}) async {
  final span = _tracer.startSpan('$provider $operation',
      kind: SpanKind.client,
      attributes: DOTel.attributesFromSemanticMap({
        Payment.provider: provider,
        Payment.operation: operation,
        Payment.productId: ?productId,
        Payment.amount: ?amount,
        Payment.currency: ?currency,
      }));
  var result = 'failed';
  try {
    final value = await DOTel.withSpanAsync(span, call);
    result = outcome(value);
    return value;
  } catch (e, s) {
    // A user canceling is not an error; anything else is.
    if (isUserCancel(e)) {
      result = 'canceled';
    } else {
      DartasticErrorTracker.recordError(e, s, span: span);
    }
    rethrow;
  } finally {
    span.setStringAttribute(Payment.outcome.key, result);
    span.end();
    _outcomes.add(1, DOTel.attributesFromSemanticMap({
      Payment.provider: provider,
      Payment.operation: operation,
      Payment.outcome: result,
    }));
  }
}
```

`isUserCancel` is the app's own check for each SDK's cancel exception.

## Stripe (flutter_stripe)

The PaymentIntent is created on the server: instrument that endpoint
like any server span (`dartastic-distributed-tracing`), so the app's
request and the server's call to Stripe join in one trace. In the app:

```dart
await tracedPayment(
  provider: 'stripe', operation: 'present_sheet',
  amount: order.totalCents, currency: 'usd',
  call: () => Stripe.instance.presentPaymentSheet(),
  outcome: (_) => 'succeeded',
);
```

`StripeException` with `FailureCode.Canceled` is the user's cancel. Use
the failure code (`e.error.code.name`) as `error.type`, by implementing a
small typed error, so declines group by reason.

## RevenueCat (purchases_flutter)

```dart
final result = await tracedPayment(
  provider: 'revenuecat', operation: 'purchase',
  productId: package.storeProduct.identifier,
  call: () => Purchases.purchase(PurchaseParams.package(package)),
  outcome: (_) => 'succeeded',
);
```

A `PlatformException` whose `PurchasesErrorHelper.getErrorCode(e)` is
`PurchasesErrorCode.purchaseCancelledError` is the user's cancel. Restore
(`Purchases.restorePurchases()`) and `logIn` are worth their own spans;
paywall views are screen views, so name the paywall's route.

## in_app_purchase

Purchases complete asynchronously on `purchaseStream`. Start the span
when `buyNonConsumable` or `buyConsumable` is called, keep it by product
id, and end it when the stream delivers `purchased`, `restored`, `error`
or `canceled` for that product. Count the outcome the same way.

## Check it

Run a test-mode purchase, a canceled one and a declined one (the
provider's test cards or sandbox accounts), then with
`dartastic-verify-telemetry` confirm three spans with the right outcomes,
the decline recorded as an error with its code, and no card or personal
data anywhere.
