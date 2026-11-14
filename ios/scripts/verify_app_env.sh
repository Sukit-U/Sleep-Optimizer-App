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
# because of a base64 flag difference.
decoded=""
old_ifs=$IFS
IFS=,
for define in ${DART_DEFINES:-}; do
  entry=$(printf '%s' "$define" | base64 --decode 2>/dev/null ||
    printf '%s' "$define" | base64 -D 2>/dev/null ||
    printf '%s' "$define")
  decoded="$decoded,$entry"
done
IFS=$old_ifs

# base64 of "APP_ENV=dev" and "APP_ENV=prod" (standard and url-safe alphabet).
case ",${DART_DEFINES:-}," in
  *,QVBQX0VOVj1kZXY=,* | *,QVBQX0VOVj1wcm9k,*) exit 0 ;;
esac

case "$decoded" in
  *APP_ENV=dev* | *APP_ENV=prod*) exit 0 ;;
esac

echo "error: this iOS ${CONFIGURATION} build has no --dart-define=APP_ENV." >&2
echo "" >&2
echo "A release/profile iOS build has to name its Firebase project, otherwise" >&2
echo "it falls back to the dev default. Before archiving, run:" >&2
echo "" >&2
echo "  flutter build ios --config-only --release --dart-define=APP_ENV=prod" >&2
echo "" >&2
echo "then archive from ios/Runner.xcworkspace. See docs/ENVIRONMENTS.md." >&2
exit 1
