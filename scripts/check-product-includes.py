#!/usr/bin/env python3
"""Resolve the device's product inherits against the actual build/make checkout."""
import pathlib
import re
import sys

build_make = pathlib.Path(sys.argv[1]).resolve()
device_root = pathlib.Path(__file__).resolve().parent.parent
missing = []
count = 0
for source in device_root.glob('*.mk'):
    for relative in re.findall(r'\$\(SRC_TARGET_DIR\)/([^\s,)]+)', source.read_text()):
        count += 1
        target = build_make / 'target' / relative
        if not target.is_file():
            missing.append(f'{source.name}: missing {target}')
if not count:
    sys.exit('No product inherits found; check validator input.')
if missing:
    sys.exit('\n'.join(missing))
print(f'All {count} product includes exist in {build_make}.')
