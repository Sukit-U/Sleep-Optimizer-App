#!/bin/sh
#
# Xcode build phase: refuse an iOS Release/Profile build that never named its
# Firebase environment.
#
# Xcode never sees `--dart-define`. `flutter build ios` (including
# `flutter build ios --config-only`) writes the defines, base64-encoded, into
# ios/Flutter/Generated.xcconfig as DART_DEFINES, and this phase reads it as a
# build setting. Without the define the Dart code falls back to `dev`, so an
# archive taken straight from Xcode would ship a release binary pointed at the
# dev project. The launch-time guard in lib/app/firebase_environment.dart is
# the second line of defence; this one fails the archive itself.
#
# Debug builds are untouched.
set -eu

case "${CONFIGURATION:-}" in
  Release | Profile) ;;
  *) exit 0 ;;
esac

# Each define is base64 on its own and the encoded defines are comma separated.
# Two decoder spellings are tried (GNU `--decode`, BSD/macOS `-D`) and the raw
# text is kept as a fallback, so a macOS runner cannot fail this check merely
# because of a base64 flag difference. Dart uses last-wins semantics when
# duplicate `--dart-define=APP_ENV=...` arguments are passed, so track the last
# decoded `APP_ENV=*` entry and reject unanchored substrings or invalid values.
last_app_env=""
old_ifs=$IFS
IFS=,
for define in ${DART_DEFINES:-}; do
  [ -n "$define" ] || continue
  entry=$(printf '%s' "$define" | base64 --decode 2>/dev/null ||
    printf '%s' "$define" | base64 -D 2>/dev/null ||
    printf '%s' "$define")
  case "$entry" in
    APP_ENV=*) last_app_env=${entry#APP_ENV=} ;;
  esac
done
IFS=$old_ifs

case "$last_app_env" in
  dev | prod) exit 0 ;;
esac

echo "error: this iOS ${CONFIGURATION} build has no --dart-define=APP_ENV." >&2
echo "" >&2
echo "A release/profile iOS build has to name its Firebase project, otherwise" >&2
echo "it falls back to the dev default. Before archiving, run:" >&2
echo "" >&2
echo "  # TestFlight beta (targets sleep-optimizer-dev):" >&2
echo "  flutter build ios --config-only --release --dart-define=APP_ENV=dev" >&2
echo "" >&2
echo "  # App Store production (targets sleep-optimizer-59c83):" >&2
echo "  flutter build ios --config-only --release --dart-define=APP_ENV=prod" >&2
echo "" >&2
echo "then archive from ios/Runner.xcworkspace. See docs/ENVIRONMENTS.md." >&2
exit 1
