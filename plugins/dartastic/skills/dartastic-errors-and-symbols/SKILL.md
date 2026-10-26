---
name: dartastic-errors-and-symbols
description: Capture errors and crashes in Flutter and Dart apps with Dartastic, record handled errors well, and make obfuscated release stack traces readable by publishing symbols to Dartastic Pub. Use this whenever someone works on error handling, crash reporting, try/catch blocks that swallow errors, FlutterError.onError, PlatformDispatcher.onError, runZonedGuarded, --obfuscate, --split-debug-info, source maps, unreadable or obfuscated stack traces, "symbols not published", release pipelines for a Flutter app, or replacing Crashlytics or Sentry crash reporting.
---

# Errors, crashes and symbols with Dartastic

Three jobs, in order: catch every error, record the ones the app handles
so they still count, and make release stack traces readable.

## 1. Catch every uncaught error

`DartasticFlutterMetrics.start()` installs the handlers. Call it once,
right after `DOTel.initialize` and before `runApp`:

```dart
await DOTel.initialize(serviceName: 'checkout-app', serviceVersion: version);
await DartasticFlutterMetrics.start();
runApp(const App());
```

It chains `FlutterError.onError` and `PlatformDispatcher.instance.onError`,
keeping any handler already installed, so it can sit beside another tool
during a migration. Then:

- **Don't add `runZonedGuarded`** just for error reporting. Uncaught async
  errors already reach `PlatformDispatcher.onError`, and a guarded zone
  wrapped around `runApp` causes zone-mismatch warnings.
- **Don't replace the handlers afterwards.** If the app sets
  `FlutterError.onError` itself, set it before `DartasticFlutterMetrics.start()`
  so it is chained rather than overwritten.
- **Native crashes** (a crash in platform code, an out-of-memory kill) are
  reported on the next launch as an `app.crash` event and a
  `dartastic.crash.detected` span linked to the traces the crashed run had
  in flight. This needs nothing beyond `DOTel.initialize`.
- **ANRs** (the UI thread stuck while the app is in the foreground) are
  reported as `dartastic.app.anr` events with a severity: info from 250 ms,
  mild from 2 seconds, severe from 5 seconds. An idle or backgrounded app is
  never judged.

Every error is recorded on the span it happened in: the active span, or a
span that already recorded the same error. With none, it gets a root span
of its own named `error <type>`. So an error inside a tap handler or a
request handler is joined to that tap or request, with no extra code.

## 2. Record handled errors

A `catch` that recovers is still an error the team should see. Record it,
then handle it:

```dart
Future<void> pay(Order order) async {
  final span = DOTel.tracer().startSpan('checkout.pay');
  try {
    await payments.charge(order);
  } catch (e, s) {
    DartasticErrorTracker.recordError(e, s, span: span);
    showRetry();
  } finally {
    span.end();
  }
}
```

- `handled: true` is the default; pass `handled: false` only for an error
  the app could not recover from.
- Pass the span the error belongs to while it is still recording. Without
  `span:`, the active span is used.
- Use `recordError`, not `span.setAttribute('exception.message', ...)`:
  only `recordError` keeps the stack trace, the type and the screen.
- **Typed errors**: implement `DartasticTypedError` on the app's own
  exceptions so `error.type` is a stable code (`card_declined`) rather than
  a class name, which keeps error groups stable across refactors:

  ```dart
  class PaymentDeclined implements Exception, DartasticTypedError {
    PaymentDeclined(this.reason);
    final String reason;
    @override
    String get errorType => 'card_declined';
  }
  ```

- Never put personal data in an exception message: messages are stored as
  sent. Say `card declined` rather than including the card holder's name.

### Find the swallowed ones

When adding Dartastic to an existing app, search for catches that hide
errors and fix each one:

```sh
grep -rnE "catch \(\w+(, ?\w+)?\) \{\s*\}|catch \(_\)|on \w+ catch" lib/
```

For each: record it with `recordError` if the app recovers, or let it
propagate if the app cannot. A `catch (_) {}` around app logic is a bug to
report to the developer, not something to keep quiet.

## 3. Readable release stack traces

Release builds should be obfuscated (`--obfuscate`), which turns stack
traces into nonsense unless the build's symbols are available. Dartastic
reads the symbols from the app's own package on Dartastic Pub: publishing
the app with its symbols inside is the upload. Builds are matched by the
compiled binary's own build id, not by version, so each crash is
symbolized against the exact binary that crashed.

### One-time setup

1. In `pubspec.yaml`, set `publish_to:` to the organization's Pub URL:

   ```yaml
   publish_to: https://pub.dartastic.io
   ```

2. The Pub token must allow write (publish) access. In the Control Room,
   **Tokens**, **+ Pub**, check **Allow write (publish) access**.
3. Add a `LICENSE` file if the app has none (pub requires one; a short
   proprietary notice is fine).
4. Add a `.pubignore`. It replaces `.gitignore` for publishing, which
   matters because Flutter's template `.gitignore` drops `*.symbols`.
   Root-anchor the platform folders so they never match inside `symbols/`:

   ```gitignore
   /android/
   /ios/
   /macos/
   /linux/
   /windows/
   /web/
   /build/
   .dart_tool/
   .idea/
   *.iml
   ```

### Each release

Read `references/release-build.md` for a complete script. The essentials:

```sh
flutter clean   # an incremental build can reuse the AOT snapshot and emit no symbols
flutter build appbundle --release --obfuscate --split-debug-info=symbols/android \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT="$OTLP_ENDPOINT" \
  --dart-define=OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer $DARTASTIC_OTLP_TOKEN" \
  --dart-define=OTEL_RESOURCE_ATTRIBUTES=flutter.app_package_name=<pubspec name>
flutter build ipa --release --obfuscate --split-debug-info=symbols/ios <same defines>
dart pub publish --dry-run
dart pub publish
```

The rules behind it:

- **Ship the binary you published symbols for.** Obfuscation is different
  on every build. A rebuild of the same version, even from the same
  commit, does not match the published symbols.
- **All platforms in one version.** A published version cannot be changed,
  so build every platform that ships, then publish once. Bump `version:` in
  `pubspec.yaml` for the next release.
- **`flutter.app_package_name`** must be passed in obfuscated builds: the
  SDK normally reads it from a stack trace, which obfuscation scrambles.
  Use the `name:` from `pubspec.yaml`.
- **Web**: build with `flutter build web --release --source-maps` and
  publish the `.js.map` files the same way.
- **CI**: publishing from CI uses the CI exchange (Help: **Pub from CI**),
  with no token stored in the CI system.
- `symbols/` is a build output: keep it out of git (`/symbols/` in
  `.gitignore`) but in the package (not in `.pubignore`).

### When a stack is not symbolized

The Observatory says why on the error. The common causes:

| What it says                        | Fix                                                             |
|-------------------------------------|-----------------------------------------------------------------|
| The symbols were not published      | Publish that build's symbols, or ship the build you published   |
| No published build matches this one | The binary was rebuilt after publishing; ship the published one |
| The app is unknown                  | Pass `flutter.app_package_name` in the build's defines          |

## Check it

Add a temporary debug-only button that throws, run a release build with
the defines, tap it, and confirm with `dartastic-verify-telemetry` that
the error arrived on the tap's trace, with readable frames. Remove the
button afterwards.
