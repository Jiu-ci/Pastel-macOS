#!/usr/bin/env python3
"""Run Go with a checked temporary dependency patch; preserve the module cache."""

import hashlib
import json
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile


def main():
    root = Path(__file__).resolve().parent.parent
    project = root / "StoreHelper"
    go = os.environ.get("PASTEL_GO", "go")
    arguments = sys.argv[1:]
    upstream = arguments[:1] == ["--upstream"]
    if upstream:
        arguments.pop(0)
    if not arguments or arguments[0] not in {"build", "test", "run", "vet"}:
        sys.exit("Usage: StoreHelperGo.py [--upstream] <build|test|run|vet> [Go arguments]")
    module = json.loads(subprocess.check_output(
        [go, "mod", "download", "-json", "github.com/majd/ipatool/v2"], cwd=project, text=True
    ))
    if module.get("Version") != "v2.8.0" or module.get("Error"):
        sys.exit("Re-review the asset patch before changing the pinned ipatool version.")
    module_dir = Path(module["Dir"])
    relative = Path("internal/sap/assets/http_range.go")
    original = module_dir / relative
    expected = "edb6c4a6d8708f138035483b7762e7f1d5410fafbb9e4b726d884b965ad6ea8f"
    if hashlib.sha256(original.read_bytes()).hexdigest() != expected:
        sys.exit("Pinned ipatool asset source changed; refusing an unchecked patch.")

    with tempfile.TemporaryDirectory(prefix="panghu-store-build-") as temporary:
        staging = Path(temporary)
        # Go forbids source overlays within GOMODCACHE. Patch an isolated copy
        # instead, using a relative replace in an equally isolated helper copy.
        patched_module = staging / "ipatool"
        shutil.copytree(module_dir, patched_module, copy_function=shutil.copyfile)
        # Module cache directories are read-only; copytree preserves their mode.
        for directory in [patched_module, *patched_module.rglob("*")]:
            if directory.is_dir():
                directory.chmod(directory.stat().st_mode | 0o700)
        subprocess.run([
            "/usr/bin/patch", "--batch", "--forward", "--fuzz=0", "-p1", "-i",
            str(project / "patches/ipatool-v2.8.0-assets.patch"),
        ], cwd=patched_module, check=True)
        if arguments[0] == "test":
            shutil.copyfile(
                root / "Scripts/Tests/StoreAssetsTests.go",
                patched_module / "internal/sap/assets/panghu_http_range_test.go",
            )
        working_directory = patched_module
        if not upstream:
            working_directory = staging / "helper"
            shutil.copytree(project, working_directory, copy_function=shutil.copyfile)
            subprocess.run([
                go, "mod", "edit", "-replace=github.com/majd/ipatool/v2=../ipatool",
            ], cwd=working_directory, check=True)
        return subprocess.call(
            [go, *arguments], cwd=working_directory,
        )


if __name__ == "__main__":
    sys.exit(main())
