# A release build that publishes its own symbols

Add this as `tool/release.sh` in the app. It builds every platform this
host can build, obfuscated, collects their symbols under `symbols/`,
checks the package, and publishes it once. Run it on each operating
system that ships (macOS builds Android and Apple; Windows and Linux build
their own) or in the matching CI jobs, but publish only from the last one:
a version is published once.

Before the first run: `publish_to:` in `pubspec.yaml`, a write-enabled Pub
token (`dart pub token add <pub url>`), a `LICENSE` and a `.pubignore`, as
in the skill. The OTLP endpoint and token come from the environment.

```bash
#!/usr/bin/env bash
# Release build with symbols, published to Dartastic Pub.
#   OTLP_ENDPOINT=https://otlp.cloud.dartastic.io DARTASTIC_OTLP_TOKEN=... tool/release.sh
#   PLATFORMS="appbundle ipa" tool/release.sh     # choose the targets
#   DRY_RUN=1 tool/release.sh                     # build, do not publish
set -euo pipefail
cd "$(dirname "$0")/.."

die() { echo "release: $*" >&2; exit 1; }
: "${OTLP_ENDPOINT:?set OTLP_ENDPOINT to the organization's OTLP host}"
: "${DARTASTIC_OTLP_TOKEN:?set DARTASTIC_OTLP_TOKEN (an OTLP token, never committed)}"

NAME=$(awk '/^name:/{print $2; exit}' pubspec.yaml)
VERSION=$(awk '/^version:/{print $2; exit}' pubspec.yaml)
grep -q '^publish_to: https://' pubspec.yaml || die "set publish_to: to your Pub URL"

case "$(uname -s)" in
  Darwin) default="appbundle ipa macos" ;;
  Linux)  default="appbundle linux" ;;
  *)      default="windows" ;;
esac
read -ra targets <<< "${PLATFORMS:-$default}"

defines=(
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT="$OTLP_ENDPOINT"
  --dart-define=OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer $DARTASTIC_OTLP_TOKEN"
  --dart-define=OTEL_RESOURCE_ATTRIBUTES="flutter.app_package_name=$NAME,deployment.environment.name=prod"
)

rm -rf symbols
flutter clean    # an incremental build can skip writing symbols
flutter pub get

for t in "${targets[@]}"; do
  if [ "$t" = web ]; then
    flutter build web --release --source-maps "${defines[@]}"
    mkdir -p symbols/web
    find build/web -name '*.js.map' -exec cp {} symbols/web/ \;
  else
    extra=()
    case "$t" in appbundle|apk) extra+=(--extra-gen-snapshot-options=--strip) ;; esac
    flutter build "$t" --release --obfuscate --split-debug-info="symbols/$t" \
      ${extra[@]+"${extra[@]}"} "${defines[@]}"   # the macOS bash 3.2 form of an empty array
  fi
  n=$(find "symbols/$t" -name '*.symbols' -o -name '*.js.map' | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] || die "$t produced no symbols"
  echo "release: $t: $n symbol files"
done

[ "${DRY_RUN:-0}" = 1 ] && { echo "release: built, not published (these binaries match no published symbols)"; exit 0; }

dart pub publish --dry-run
dart pub publish    # asks before publishing; a version is published once
echo "release: published $NAME $VERSION. Ship exactly the binaries in build/."
```

Notes:

- `--extra-gen-snapshot-options=--strip` on Android strips the debug
  information the compiler would otherwise leave for Gradle; the symbols
  were already saved by `--split-debug-info`.
- iOS symbols do not need a signed build. If the signed archive is made
  elsewhere (Xcode, Fastlane), make it from the same `flutter build ipa`
  output, never from a second build.
- Put `/symbols/` in `.gitignore`: it is a build output. It must not be in
  `.pubignore`.
- Bump `version:` in `pubspec.yaml` for every release.
