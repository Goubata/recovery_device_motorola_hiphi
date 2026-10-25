#!/usr/bin/env python3
"""Check the recovery ramdisk's ELF dependencies and dynamic symbol resolution.

Every executable's NEEDED closure must be present, and every non-weak undefined
symbol in that closure must be defined by some object in it. Libraries that are
only dlopen()ed (hw/ modules) are checked against their own closure plus the
host process, which is reported as a warning because it cannot be resolved
statically. This proves linkability, not successful TEE communication.
"""
import collections
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(sys.argv[1]).resolve()
CRYPTO_EXECUTABLES = (
    'system/bin/android.hardware.security.keymint-service-qti',
    'system/bin/android.hardware.gatekeeper@1.0-service-qti',
    'system/bin/qseecomd',
    'system/bin/keystore2',
)


BINDINGS = {'LOCAL', 'GLOBAL', 'WEAK', 'UNIQUE', 'GNU_UNIQUE'}
ELF_DIRS = {'bin', 'lib', 'lib64', 'hw'}


def readelf(*args):
    return subprocess.run(['readelf', '-W', *args], capture_output=True, text=True,
                          env={'LC_ALL': 'C'}).stdout


def is_dynamic_elf(path):
    with open(path, 'rb') as f:
        if f.read(4) != b'\x7fELF':
            return False
    return re.search(r'Type:\s+(DYN|EXEC)', readelf('-h', str(path))) is not None


class Elf:
    def __init__(self, path):
        self.path = path
        self.needed = re.findall(r'\(NEEDED\).*\[(.*?)\]', readelf('-d', str(path)))
        self.defined = set()
        self.undefined = set()
        for line in readelf('--dyn-syms', str(path)).splitlines():
            fields = line.split()
            binds = [f for f in fields if f in BINDINGS]
            if len(fields) < 8 or not fields[0].endswith(':') or not binds:
                continue
            # IFUNC types print as "<OS specific>: 10", so index from the right.
            bind, ndx, name = binds[0], fields[-2], fields[-1].split('@')[0]
            if ndx == 'UND':
                if bind != 'WEAK':
                    self.undefined.add(name)
            elif bind != 'LOCAL':
                self.defined.add(name)


elves = {}
by_name = collections.defaultdict(list)


def resolve(path):
    # Ramdisk symlinks are absolute paths inside the recovery root.
    for _ in range(16):
        if not path.is_symlink():
            return path
        target = pathlib.Path(path.readlink())
        path = root / target.relative_to('/') if target.is_absolute() else path.parent / target
    return path


for path in sorted(root.rglob('*')):
    if not ELF_DIRS.intersection(path.relative_to(root).parts[:-1]):
        continue
    target = resolve(path)
    if not target.is_file() or not is_dynamic_elf(target):
        continue
    if target not in elves:
        elves[target] = Elf(target)
    if target not in by_name[path.name]:
        by_name[path.name].append(target)


def closure(start):
    seen, queue, missing = [], [start], set()
    while queue:
        path = queue.pop(0)
        if path in seen:
            continue
        seen.append(path)
        for name in elves[path].needed:
            if name in by_name:
                queue.extend(by_name[name])
            else:
                missing.add(f'{path.relative_to(root)} needs missing {name}')
    return seen, missing


# The dynamic linker itself provides the __loader_* symbols used by libdl.
linker = root / 'system/bin/linker64'
loader_symbols = elves[linker].defined if linker in elves else set()

errors, warnings = set(), set()
for relative in CRYPTO_EXECUTABLES:
    if root.joinpath(relative) not in elves:
        errors.add(f'Missing crypto executable: {relative}')

for path, elf in elves.items():
    is_executable = '/bin/' in f'/{path.relative_to(root)}'
    objects, missing = closure(path)
    if path.parent.name == 'hw':
        warnings.update(missing)
    else:
        errors.update(missing)
    if not is_executable:
        continue
    available = loader_symbols.union(*(elves[o].defined for o in objects))
    for obj in objects:
        for symbol in sorted(elves[obj].undefined - available):
            errors.add(f'{path.relative_to(root)}: {obj.relative_to(root)} '
                       f'has unresolved symbol {symbol}')

for path, elf in elves.items():
    if path.parent.name == 'hw':
        objects, _ = closure(path)
        available = loader_symbols.union(*(elves[o].defined for o in objects))
        unresolved = sorted(set().union(*(elves[o].undefined for o in objects)) - available)
        if unresolved:
            warnings.add(f'{path.relative_to(root)} (dlopen) relies on host symbols: '
                         + ', '.join(unresolved[:8]) + (' ...' if len(unresolved) > 8 else ''))

for warning in sorted(warnings):
    print(f'warning: {warning}')
if errors:
    print('\n'.join(sorted(errors)))
    sys.exit(1)
print(f'All {len(elves)} ELF files: dependencies present, executable symbols resolved.')
