#!/usr/bin/env bash
# Builds the signed release APK and app bundle and copies them to dist/
# with readable names, e.g. dist/SunClock-1.0.0.apk.
# Usage: bash tool/build_release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)

flutter build apk --release
flutter build appbundle --release

mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk "dist/SunClock-$version.apk"
cp build/app/outputs/bundle/release/app-release.aab "dist/SunClock-$version.aab"
echo "dist/SunClock-$version.apk"
echo "dist/SunClock-$version.aab"
