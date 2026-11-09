#!/usr/bin/env python3
"""Reject bundled executables whose deployment target exceeds macOS 15."""

import re
import subprocess
import sys


def verify(binary):
    architectures = subprocess.check_output(["/usr/bin/lipo", "-archs", binary], text=True).strip()
    if architectures != "arm64":
        raise ValueError(f"{binary}: expected arm64, found {architectures}")
    commands = subprocess.check_output(["xcrun", "vtool", "-show-build", binary], text=True)
    minimums = re.findall(r"^\s*(?:minos|version)\s+(\d+(?:\.\d+)*)\s*$", commands, re.M)
    # 'version' inside the LC_BUILD_VERSION tool list is the linker version.
    if "LC_BUILD_VERSION" in commands:
        minimums = re.findall(r"^\s*minos\s+(\d+(?:\.\d+)*)\s*$", commands, re.M)
    if not minimums:
        raise ValueError(f"{binary}: missing Mach-O minimum OS")
    for value in minimums:
        version = tuple((list(map(int, value.split("."))) + [0, 0])[:3])
        if version > (15, 0, 0):
            raise ValueError(f"{binary}: requires macOS {value}, maximum allowed is 15.0")
    print(f"macOS 15 compatibility: {binary} (arm64, minOS {', '.join(minimums)})")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Usage: VerifyMacOSCompatibility.py <executable> [<executable> ...]")
    try:
        for binary in sys.argv[1:]:
            verify(binary)
    except (ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
