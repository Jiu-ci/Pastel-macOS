#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
developer_dir=${DEVELOPER_DIR:-$(xcode-select -p)}
# Keep products outside the iCloud-synced source tree. Finder/iCloud metadata on
# app bundles can be rejected by codesign as resource-fork detritus.
derived_data=${PASTEL_DERIVED_DATA:-"${TMPDIR:-/tmp}/PastelDistributionDerivedData"}
output_dir=${PASTEL_OUTPUT_DIR:-"${project_root}/dist"}

export DEVELOPER_DIR="$developer_dir"

sh "${project_root}/Scripts/VerifyDeviceGUIDImplementation.sh" \
    "${project_root}/Pastel/PastelApp.swift"

xcodebuild \
    -project "${project_root}/Pastel.xcodeproj" \
    -scheme Pastel \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=YES \
    build

app="${derived_data}/Build/Products/Release/Pastel.app"
node="${app}/Contents/Resources/node/bin/node"
signer="${app}/Contents/Resources/sap-signer"

test -d "$app"
# Test the bundled code and dependencies, even on a clean CI checkout with no
# NodeProject/node_modules. Keep test fixtures outside the signed app bundle.
(
    test_workspace=$(mktemp -d "${TMPDIR:-/tmp}/pastel-tests.XXXXXX")
    trap 'rm -rf "$test_workspace"' EXIT HUP INT TERM
    ditto "${project_root}/NodeProject/test" "${test_workspace}/test"
    bundled_project="${app}/Contents/Resources/NodeProject"
    for item in src main.js package.json node_modules; do
        ln -s "${bundled_project}/${item}" "${test_workspace}/${item}"
    done
    "$node" --test "${test_workspace}/test/"*.test.js
)
test "$(/usr/bin/lipo -archs "${app}/Contents/MacOS/Pastel")" = "arm64"
test "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "${app}/Contents/Info.plist")" = "15.0"
codesign --verify --strict "$signer"
codesign --verify --strict "$node"
codesign --verify --deep --strict "$app"

# Validate Node after every enclosing signature has been applied. Merely checking
# the entitlement plist would not prove that V8 can create executable JIT pages.
"$node" -e '
function hot(value) { return (value * 3 + 7) ^ 0x55; }
let result = 0;
for (let index = 0; index < 1000000; index += 1) result = hot(result + index);
if (!process.versions.node.startsWith("24.") || !Number.isInteger(result)) process.exit(1);
process.stdout.write(`Node ${process.versions.node} JIT validation passed\n`);
'

version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${app}/Contents/Info.plist")
build=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${app}/Contents/Info.plist")
dmg="${output_dir}/Pastel-${version}-build-${build}.dmg"
staging=$(mktemp -d "${TMPDIR:-/tmp}/pastel-dmg.XXXXXX")
trap 'rm -rf "$staging"' EXIT HUP INT TERM

mkdir -p "$output_dir"
ditto "$app" "${staging}/Pastel.app"
ln -s /Applications "${staging}/Applications"
hdiutil create -quiet -ov -fs HFS+ -volname Pastel -srcfolder "$staging" -format UDZO "$dmg"

hdiutil verify "$dmg"
echo "Created ${dmg}"
