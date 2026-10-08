#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build dist
app="dist/歇一刻.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
for arch in arm64 x86_64; do
    xcrun swiftc -O -target "$arch-apple-macosx12.0" Sources/Countdown.swift Sources/main.swift \
        -framework Cocoa -o ".build/XieYiKe-$arch"
done
xcrun lipo -create .build/XieYiKe-arm64 .build/XieYiKe-x86_64 -output "$app/Contents/MacOS/XieYiKe"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
# Strip Finder metadata on our build artifact before sealing its resources.
xattr -cr "$app"
if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$app"
else
    codesign --force --sign - "$app"
fi
codesign --verify --deep --strict "$app"
xcrun lipo "$app/Contents/MacOS/XieYiKe" -verify_arch arm64 x86_64
printf 'Built %s\n' "$app"
