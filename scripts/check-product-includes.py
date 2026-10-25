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

# Kati rejects even assigning "false" to a variable declared obsolete.
# Check literal declarations; computed/dynamic declarations still need a real build.
obsolete = set()
for source in (build_make / 'core').rglob('*.mk'):
    text = source.read_text().replace('\\\n', ' ')
    for argument in re.findall(r'\$\(KATI_obsolete_var\s+([^,)]+)', text):
        obsolete.update(re.findall(r'\b[A-Z][A-Z0-9_]+\b', argument))
errors = []
for source in device_root.glob('*.mk'):
    for number, line in enumerate(source.read_text().splitlines(), 1):
        assignment = re.match(r'\s*([A-Z][A-Z0-9_]+)\s*[:+?]?=', line)
        if assignment and assignment[1] in obsolete:
            errors.append(f'{source.name}:{number}: obsolete variable {assignment[1]}')
if errors:
    sys.exit('\n'.join(errors))
print(f'No device assignments use the {len(obsolete)} literal obsolete variables.')
