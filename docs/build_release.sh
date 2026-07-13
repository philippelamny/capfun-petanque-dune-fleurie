#!/usr/bin/env bash
# Builds a release APK, copies it into docs/releases with a versioned,
# timestamped name, builds the web app into docs/appli, then regenerates
# docs/index.html so the download link and the "play in browser" link
# always point at the latest build.
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

REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")

echo "==> flutter build web --release"
flutter build web --release --base-href "/${REPO_NAME}/appli/"

rm -rf docs/appli
mkdir -p docs/appli
cp -r build/web/. docs/appli/
echo "==> Copied web app to docs/appli/"

cd docs
python3 generate_site.py
