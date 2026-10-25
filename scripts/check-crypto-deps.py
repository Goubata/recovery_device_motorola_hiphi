#!/usr/bin/env python3
"""Check ELF dependency presence for the recovery crypto stack (not ABI compatibility)."""
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(sys.argv[1]).resolve()
files = {}
for path in root.rglob('*'):
    if path.is_file():
        files.setdefault(path.name, []).append(path)
queue = [root / 'system/bin' / name for name in (
    'android.hardware.security.keymint-service-qti',
    'android.hardware.gatekeeper@1.0-service-qti', 'qseecomd', 'keystore2')]
visited = set()
errors = []
while queue:
    path = queue.pop()
    if path in visited:
        continue
    visited.add(path)
    if not path.is_file():
        errors.append(f'Missing crypto executable/library: {path}')
        continue
    output = subprocess.check_output(['readelf', '-d', str(path)], text=True)
    for name in re.findall(r'\(NEEDED\).*\[(.*?)\]', output):
        if name not in files:
            errors.append(f'{path.relative_to(root)} needs missing {name}')
        else:
            queue.extend(files[name])
if errors:
    print('\n'.join(sorted(set(errors))))
    sys.exit(1)
print(f'Crypto ELF dependencies present ({len(visited)} files checked).')
