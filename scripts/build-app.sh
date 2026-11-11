#!/bin/zsh
# Builds a universal "Locator.app" into ./build. Pass --install to copy it to ~/Applications,
# or --zip to make build/Locator-<version>.zip for a GitHub release.
set -euo pipefail
cd "$(dirname "$0")/.."

# Universal binary: build each architecture, then join them with lipo.
for arch in arm64 x86_64; do
  swift build -c release --triple "$arch-apple-macosx14.0"
done
BIN=".build/universal/LocatorBar"
mkdir -p .build/universal
lipo -create -output "$BIN" .build/arm64-apple-macosx/release/LocatorBar .build/x86_64-apple-macosx/release/LocatorBar
APP="build/Locator.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/LocatorBar"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns Resources/cqzones.json Resources/ituzones.json Resources/zones-LICENSE.txt "$APP/Contents/Resources/"
codesign --force --sign - "$APP"   # ad-hoc signature, fine for running on your own Macs
echo "Built $APP"

if [[ "${1:-}" == "--zip" ]]; then
  VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
  ZIP="build/Locator-$VERSION.zip"
  rm -f "$ZIP"
  ditto -c -k --keepParent "$APP" "$ZIP"
  echo "Zipped $ZIP"
fi

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p ~/Applications
  rm -rf ~/Applications/"Locator.app"
  cp -R "$APP" ~/Applications/
  echo "Installed to ~/Applications/Locator.app"
fi
