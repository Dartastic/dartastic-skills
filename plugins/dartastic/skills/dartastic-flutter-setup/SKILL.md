---
name: dartastic-flutter-setup
description: Add Dartastic OpenTelemetry (DOTel, the Dartastic Pro SDK) to a Flutter app, end to end - registry token, packages, DOTel.initialize, endpoint and OTLP token, screen views, taps, errors, metrics, sessions, replay, and release builds. Use this whenever someone wants to add observability, telemetry, monitoring, RUM, crash reporting, tracing, OpenTelemetry or Dartastic to a Flutter app, asks why nothing shows up in the Dartastic Observatory, or is migrating from Firebase Crashlytics, Sentry, Datadog or another RUM tool to Dartastic, even if they never say "OpenTelemetry".
---

# Add Dartastic to a Flutter app

The goal is an app whose every session, screen, tap, error, crash, slow
frame and network call arrives in the Dartastic Observatory, correctly
named, symbolized and joined to the backend traces it caused. Work through
the steps in order; each one ends with something you can check.

Other skills in this set go deeper. Read them when the step calls for it:

| Skill                           | When                                                   |
|---------------------------------|--------------------------------------------------------|
| `dartastic-resource-attributes` | Naming the service and choosing resource attributes    |
| `dartastic-errors-and-symbols`  | Error capture, crashes, obfuscated builds, symbols     |
| `dartastic-custom-telemetry`    | The app's own spans, metrics, logs and attribute names |
| `dartastic-distributed-tracing` | Joining app traces to servers and Firebase Functions   |
| `dartastic-webviews`            | Screens that embed a WebView                           |
| `dartastic-integrations`        | http, dio, routers, Firebase, state, LLMs, payments    |
| `dartastic-verify-telemetry`    | Proving the telemetry arrived, with the Dartastic MCP  |

## Before you start: what to ask the developer

Ask only what you cannot find in the project:

1. **Which Dartastic plan?** It decides the hosts. Cloud uses
   `https://pub.dartastic.io` and `https://otlp.cloud.dartastic.io`.
   Hosted uses `https://pub.<subdomain>.dartastic.io` and
   `https://otlp.<subdomain>.dartastic.io`. Self-Hosted uses
   `https://pub.<their-domain>` and `https://otlp.<their-domain>`. The
   Control Room's Help pages show the organization's exact hosts. Never
   guess a subdomain.
2. **Do they have a Pub token and an OTLP token?** Both are minted in the
   Control Room under **Tokens** (**+ Pub** and **+ OTLP**). A token is shown
   once. Never ask them to paste a token into the chat, and never write one
   into a source file, a commit or a log.
3. **Which platforms ship?** Android, iOS, web, macOS, Windows, Linux.
   Flutter web needs a **Browser OTLP** token instead of an OTLP token.

Requirements: Flutter 3.44 and Dart 3.12 or newer for every feature
(the Flutter metrics package needs them); Flutter 3.22 and Dart 3.4 for all
but the Flutter metrics.

## Step 1: Let pub reach Dartastic Pub

The developer runs this once per machine, in their own terminal, so the
token never passes through you:

```sh
dart pub token add https://pub.dartastic.io
```

It prompts `Enter secret token:`; they paste the Pub token and press Enter
(the prompt shows nothing while pasting). Use their organization's Pub URL
if it is not Cloud. In CI, use the CI exchange described on the Help page
**Pub from CI** rather than a stored token.

Dartastic Pub is also a pass-through to pub.dev, so nothing else changes.

## Step 2: Add the packages

```sh
flutter pub add 'dartastic_opentelemetry_native:{"hosted":"https://pub.dartastic.io"}'
flutter pub add 'dartastic_opentelemetry_native_flutter:{"hosted":"https://pub.dartastic.io"}'
flutter pub add 'dartastic_opentelemetry_flutter_metrics:{"hosted":"https://pub.dartastic.io"}'
```

Then add this to `pubspec.yaml` by hand, because every `otel_*`
instrumentation package on pub.dev names the SDK from pub.dev, and pub takes
a package from only one host:

```yaml
dependency_overrides:
  dartastic_opentelemetry:
    hosted: https://pub.dartastic.io
    version: ^1.1.0-beta.17
```

This override is the normal state, not a workaround. Keep
`dartastic_opentelemetry_native` and `dartastic_opentelemetry_native_flutter`
on the same version: they release together. Run `flutter pub get` and
confirm it resolves.

What each package is for:

| Package                                   | What it gives the app                                                          |
|-------------------------------------------|--------------------------------------------------------------------------------|
| `dartastic_opentelemetry_native`          | `DOTel`: traces, metrics, logs, sessions, the persistent queue, crash recovery |
| `dartastic_opentelemetry_native_flutter`  | Screen views, taps, INP, ANR, jank attribution, app identity, WebView bridge   |
| `dartastic_opentelemetry_flutter_metrics` | Frame, startup, lifecycle, battery, thermal and memory metrics; error capture  |

## Step 3: Initialize before `runApp`

```dart
import 'package:dartastic_opentelemetry_flutter_metrics/dartastic_opentelemetry_flutter_metrics.dart';
import 'package:dartastic_opentelemetry_native/dartastic_opentelemetry_native.dart';
import 'package:dartastic_opentelemetry_native_flutter/dartastic_opentelemetry_native_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DOTel.initialize(
    serviceName: 'checkout-app',
    serviceVersion: '1.4.0',
    // app.build_id: the build's identity, from its version and build number.
    resourceAttributes: await DartasticAppIdentity.resourceAttributes(),
  );
  // Error capture, frame and startup metrics. Without this call no
  // uncaught error is recorded.
  await DartasticFlutterMetrics.start();

  runApp(MaterialApp(
    navigatorObservers: [
      DartasticViewObserver(), // screen views, screen timing
      DartasticFlutterMetrics.navigatorObserver, // screen names on errors and frames
    ],
    home: const HomeScreen(),
  ));
}
```

Rules that matter:

- **`DOTel.initialize` never throws.** Problems go to the OpenTelemetry
  error handler. Send them to the app's own logger so they are seen, and
  never let telemetry throw into app code:

  ```dart
  OTelAPI.setErrorHandler((error, stackTrace) {
    myLogger.warning('OpenTelemetry: $error', error, stackTrace);
  });
  ```

- **`serviceName` names the app, not the package.** Use a short, stable,
  kebab-case product name (`checkout-app`), the same across platforms and
  releases. See `dartastic-resource-attributes`.
- **`serviceVersion` is the app's version** from `pubspec.yaml`
  (`1.4.0`, without the build number). Keep it in one place: read it with
  `package_info_plus` or pass it in with a `--dart-define`, rather than a
  second hand-typed copy that drifts.
- **Do not pass `endpoint:` or tokens in code.** Use the standard
  environment variables (Step 4), so one build runs against any
  organization and no credential lands in source.
- **Construct instrumentation after `initialize`.** `otel_*` observers,
  interceptors and clients look up their tracer when they are created.
- **Add both navigator observers.** `DartasticViewObserver` records screen
  views; `DartasticFlutterMetrics.navigatorObserver` puts `app.screen.name`
  on errors and frame metrics. With `go_router`, pass them in
  `GoRouter(observers: [...])` and also in each `ShellRoute` or
  `StatefulShellRoute` branch's `observers:`, because a root observer
  cannot see navigation inside a shell.
- **Name the routes.** Screen names come from `RouteSettings.name`;
  unnamed routes report `<unnamed>`. go_router and auto_route name them for
  you. Screens that are not routes (tabs, `IndexedStack`, `PageView`) call
  `DartasticViewObserver.activateScreen('orders')` when they change, and
  once for the first one.

## Step 4: Point it at the organization

The endpoint and the OTLP token are the standard OpenTelemetry variables.
On a phone they are `--dart-define`s, baked in at build time:

```sh
flutter run \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.cloud.dartastic.io \
  --dart-define=OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer $DARTASTIC_OTLP_TOKEN"
```

- Keep `authorization` lowercase: it works for every protocol.
- The token comes from an environment variable the developer sets
  (`DARTASTIC_OTLP_TOKEN`), never from a file in the repo. An OTLP token can
  only send telemetry to its organization; it reads nothing and changes
  nothing.
- For IDE runs, put the same two defines in the launch configuration
  (`.vscode/launch.json` `toolArgs`, or Android Studio's "Additional run
  args") that reads the token from the environment, or a
  `--dart-define-from-file` file that is in `.gitignore`.
- **Flutter web**: use a **Browser OTLP** token, and list the site's exact
  origin on it in the Control Room (`http://localhost:8080` for local runs,
  with `flutter run -d chrome --web-port 8080` so the port is fixed). A
  normal OTLP token sent from a browser is refused.
- **macOS**: add `com.apple.security.network.client` to both
  `DebugProfile.entitlements` and `Release.entitlements`. Without it nothing
  is sent and nothing says why.

If nothing arrives, run with `--dart-define=OTEL_LOG_LEVEL=debug` and look
for `OTelEnv: Parsed 1 header(s)`. A 401 means the token is wrong, revoked,
or from another organization.

## Step 5: Users, sessions and taps

These work once Step 3 is in:

- **Sessions** are automatic: one `session.id` on every span and log, a new
  session after 15 minutes in the background or after 4 hours.
- **Taps** are automatic: each tap is a root span named
  `tap <screen>` (for example `tap checkout`) with everything its handler
  starts nested under it, including HTTP calls. Give important widgets a
  `Key` (`ValueKey('pay-button')`): the key becomes `app.widget.id`, which
  is how a tap is told apart from other taps on the same screen. Never put
  user text in a key.
- **The signed-in user**: call `DOTel.setUser(userId)` after sign-in, and
  on every launch (it is not persisted). Call `DOTel.clearUser()` at sign
  out; it also starts a new session. Use an opaque id, not an email.
- **Rage and error taps** are detected automatically. **Dead taps** (a tap
  that changed nothing) need session replay at pixel level with
  `onScreenSettled` wired (Step 6).
- **Jank attribution** (which widget build made a frame slow) is opt-in:
  call `DartasticJankAttributionReporter.start()` after `initialize`.
- **INP on the web** is opt-in: call `DartasticInpReporter.start()` after
  `initialize`. On other platforms it is automatic.

## Step 6: Session replay (optional)

Replay records what the user saw, held on the device and released around
errors, crashes and ANRs. Read `references/replay.md` for the packages, the
`ReplayRecorder` wiring, fidelity levels, masking a sensitive screen, and
wiring `onScreenSettled` for dead taps.

## Step 7: Network, Firebase and the rest of the stack

DOTel does not wrap HTTP by itself. Add `otel_http` or `otel_dio` (see
`dartastic-integrations`) so every request is a client span that carries
`traceparent` to the server, and so error taps and "screen settled" timing
can see network calls. Then follow `dartastic-distributed-tracing` for the
server side.

## Step 8: Release builds

Production Flutter builds should be obfuscated, and their symbols published
so crashes come back as source lines. Follow `dartastic-errors-and-symbols`
for the exact build and publish commands. The short form:

```sh
flutter build appbundle --release --obfuscate --split-debug-info=symbols/ \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=... \
  --dart-define=OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer $DARTASTIC_OTLP_TOKEN" \
  --dart-define=OTEL_RESOURCE_ATTRIBUTES=flutter.app_package_name=<pubspec name>
```

## Step 9: Prove it

Run the app, use it for a minute (open screens, tap, trigger an error), then
verify with `dartastic-verify-telemetry`. Don't call the work done until the
Observatory shows the session, its screens, its taps and the error.

## Behavior worth knowing (so you don't "fix" it)

- In the background the SDK flushes once, then stops sampling and
  collecting metrics until the app returns. Gaps in metrics while
  backgrounded are expected.
- Telemetry is queued on disk and survives restarts and offline periods;
  after a crash, the next launch reports it.
- `DARTASTIC_*` switches (for example `DARTASTIC_ACTION_TRACKER=off`) are
  build-time `--dart-define`s on mobile. Passing one to an already built
  binary does nothing.
- `OTEL_LOG_LEVEL=none` is ignored; use `fatal` to quiet the SDK.
