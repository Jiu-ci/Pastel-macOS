#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
staging=$(mktemp -d "${TMPDIR:-/tmp}/panghu-login-tests.XXXXXX")
trap 'rm -rf "$staging"' EXIT HUP INT TERM

# Compile the real Debug account state without launching the app or loading the
# user's accounts. The isolated simulation bypasses Node and Keychain access.
python3 - "${project_root}/Pastel/PastelApp.swift" "${staging}/PastelApp.swift" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text()
assert source.count("@main\n") == 1
Path(sys.argv[2]).write_text(source.replace("@main\n", "", 1))
PY
set -- "${staging}/PastelApp.swift"
for source in "${project_root}"/Pastel/*.swift; do
    [ "$(basename "$source")" = PastelApp.swift ] || set -- "$@" "$source"
done
xcrun swiftc -parse-as-library -D DEBUG -swift-version 6 \
    -target arm64-apple-macosx15.0 "$@" \
    "${project_root}/Scripts/Tests/LoginSimulationTests.swift" \
    -o "${staging}/login-tests"
"${staging}/login-tests"
