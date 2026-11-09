#!/bin/sh
set -eu

# Rebuild the bundled helper after changes to StoreHelper or its pinned ipatool.
# Xcode consumes this archive; it does not invoke Go during normal app builds.
project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
go_bin=${PASTEL_GO:-go}
staging=$(mktemp -d "${TMPDIR:-/tmp}/pastel-store-helper.XXXXXX")
trap 'rm -rf "$staging"' EXIT HUP INT TERM
cd "${project_root}/StoreHelper"
# Pin both C compilation and linking; a newer build host must not raise the
# helper's minimum OS above the app's macOS 15 deployment target.
export MACOSX_DEPLOYMENT_TARGET=15.0
export CGO_CFLAGS="${CGO_CFLAGS:-} -mmacosx-version-min=15.0"
export CGO_LDFLAGS="${CGO_LDFLAGS:-} -mmacosx-version-min=15.0"
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 "$go_bin" build -mod=readonly -trimpath -ldflags='-s -w' -o "$staging/store-helper" .
python3 "${project_root}/Scripts/VerifyMacOSCompatibility.py" "$staging/store-helper"
"$go_bin" version -m "$staging/store-helper"
gzip -n -c "$staging/store-helper" > "$staging/store-helper.gz"
cp "$staging/store-helper.gz" "${project_root}/node/bin/store-helper.gz"
