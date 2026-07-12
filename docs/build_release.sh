#!/usr/bin/env bash
# Builds a release APK, copies it into docs/releases with a versioned,
# timestamped name, then regenerates docs/index.html so the download link
# on the site always points at the latest build.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

mkdir -p docs/releases

VERSION=$(grep '^version:' pubspec.yaml | head -n 1 | cut -d ' ' -f2 | tr -d '\r' | tr '+' '-')
TIMESTAMP=$(date +%Y%m%d-%H%M)
APK_NAME="tournois_petanque-${VERSION}-${TIMESTAMP}.apk"

echo "==> flutter build apk --release"
flutter build apk --release

cp "build/app/outputs/flutter-apk/app-release.apk" "docs/releases/${APK_NAME}"
echo "==> Copied to docs/releases/${APK_NAME}"

cd docs
python3 generate_site.py
