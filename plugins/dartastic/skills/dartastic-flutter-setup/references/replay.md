# Session replay

Replay is captured on the device by `rum_replay_capture` and sent through
OpenTelemetry by `otel_rum_replay`. DOTel supplies the two facts only the
device knows: the most this build may ever record (the ceiling) and the
recording in force right now.

## Packages

```sh
flutter pub add 'rum_replay_capture:{"hosted":"https://pub.dartastic.io"}'
flutter pub add 'rum_replay_format:{"hosted":"https://pub.dartastic.io"}'
flutter pub add 'otel_rum_replay:{"hosted":"https://pub.dartastic.io"}'
```

Use the organization's own Pub URL if it is not Cloud.

## Wiring

```dart
final controller = ReplayCaptureController(
  sink: OtelReplaySink(
    sessionIdProvider: () => DartasticSessionManager.instance.sessionId,
    screenIdProvider: () => DartasticViewObserver.currentScreenId,
  ),
  mode: ReplayMode.bufferUntilTrigger,
  screenNameProvider: () => DartasticViewObserver.currentScreenName,
  screenIdProvider: () => DartasticViewObserver.currentScreenId,
  // The build's maximum. Null when the build sets none: no ceiling.
  ceiling: () => switch (DOTel.rumCeiling) {
        final c? => ReplayFidelity.fromWire(c.wireName),
        null => ReplayFidelity.pixel,
      },
  // The recording in force on this device, if any.
  recording: () => switch (DOTel.rumRecording) {
        final r? => ReplayRecording(
            fidelity: ReplayFidelity.fromWire(r.fidelity.wireName),
            provenance: r.provenance),
        null => null,
      },
  // Dead taps: lets the SDK judge whether a tap changed the screen.
  onScreenSettled: (since, at, changed) =>
      DartasticFrustrationSignals.noteScreenSettled(
          sinceUnixMs: since, atUnixMs: at, changed: changed),
);

runApp(ReplayRecorder(
  controller: controller,
  child: MaterialApp(
    navigatorObservers: [
      DartasticViewObserver(),
      DartasticFlutterMetrics.navigatorObserver,
      ReplayNavigatorObserver(controller: controller),
    ],
    home: const HomeScreen(),
  ),
));
```

Create the controller after `DOTel.initialize`.

## Modes

| Mode                            | What it does                                                                   |
|---------------------------------|--------------------------------------------------------------------------------|
| `ReplayMode.off`                | The default. Installs nothing                                                  |
| `ReplayMode.bufferUntilTrigger` | Holds recent frames on the device; releases them around an error, crash or ANR |
| `streamEveryFrameDrainsBattery` | Sends everything. For debugging only; the name is the warning                  |

Use `bufferUntilTrigger` in production.

## Fidelity

Levels, least to most visible: `events`, `outline`, `wireframe`, `shadow`,
`pixel`. What is captured is `min(ceiling, recording ?? default)`.

- `DARTASTIC_RUM_FIDELITY` (build define) is the app's default level.
  Default `pixel`.
- `DARTASTIC_RUM_FIDELITY_MAX` (build define) is an optional ceiling for
  the whole build that nothing can exceed. Set it when a build must never
  capture pixels, for example `--dart-define=DARTASTIC_RUM_FIDELITY_MAX=wireframe`.
- The app can raise or lower the level on one device for a while, for
  example from a "help me debug this" switch in its settings:
  `DOTel.startRumRecording(DartasticRumFidelity.pixel, duration: const Duration(hours: 1))`
  and `DOTel.stopRumRecording()`. The ceiling still holds.

## Sensitive screens and text

Masking is the app's decision, so the default is to record the screen as
it is. Ask the developer what users see, then choose:

- `masking: ReplayMasking.textFields` on the controller masks what users
  type; `ReplayMasking.allText` masks all text.
- Lower a screen that shows card numbers, health data or messages:

  ```dart
  controller.setFidelity(ReplayFidelity.events, route: '/checkout/card');
  ```

  The lower level holds on that screen even during a raised recording.

Prefer lowering a whole screen over hoping one widget is masked.

## Dead taps

A tap is judged dead only from the screen itself: the replay must record
at `pixel` and `onScreenSettled` must be wired as above. Without both,
there are no dead-tap signals, which is correct rather than a bug.
