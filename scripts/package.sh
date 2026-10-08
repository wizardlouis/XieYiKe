#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/test.sh
scripts/build.sh
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
name="XieYiKe-$version-macOS-universal"
# Use local temporary storage: cloud-synced folders can reintroduce Finder metadata.
staging=$(mktemp -d "${TMPDIR:-/tmp}/xieyike-package.XXXXXX")
trap 'rm -rf "$staging"' EXIT
ditto "dist/歇一刻.app" "$staging/歇一刻.app"
ln -s /Applications "$staging/Applications"
cp docs/INSTALL.txt "$staging/安装说明.txt"
cp LICENSE "$staging/LICENSE.txt"
xattr -cr "$staging/歇一刻.app"
codesign --verify --deep --strict "$staging/歇一刻.app"
hdiutil create -volname "XieYiKe $version" -srcfolder "$staging" -ov -format UDZO "dist/$name.dmg"
COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$staging/歇一刻.app" "dist/$name.zip"
(cd dist && shasum -a 256 "$name.dmg" "$name.zip" > SHA256SUMS.txt)
printf 'Packaged %s\n' "$name"
