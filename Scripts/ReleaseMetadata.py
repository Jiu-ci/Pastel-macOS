#!/usr/bin/env python3
"""Validate a release tag against both Xcode configurations, without building."""
import argparse
import os
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--tag', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
project = (root / 'Pastel.xcodeproj/project.pbxproj').read_text()


def setting(name, pattern):
    values = re.findall(rf'\b{name}\s*=\s*([^;]+);', project)
    if len(values) != 2 or len(set(values)) != 1 or not re.fullmatch(pattern, values[0]):
        raise SystemExit(f'{name} must have two matching, valid values in Debug and Release')
    return values[0]


version = setting('MARKETING_VERSION', r'\d+\.\d+(?:\.\d+)?')
build = setting('CURRENT_PROJECT_VERSION', r'\d+')
if args.tag != f'Pastel{version}':
    raise SystemExit(f'Tag must be Pastel{version}, got {args.tag!r}')
notes = f'release-notes/{version}/release-notes.md'
if not (root / notes).is_file():
    raise SystemExit(f'Missing release notes: {notes}')
metadata = {
    'version': version,
    'build': build,
    'tag': args.tag,
    'dmg': f'Pastel-{version}-build-{build}.dmg',
    'notes': notes,
}
output = ''.join(f'{key}={value}\n' for key, value in metadata.items())
print(output, end='')
if os.environ.get('GITHUB_OUTPUT'):
    with open(os.environ['GITHUB_OUTPUT'], 'a') as handle:
        handle.write(output)
