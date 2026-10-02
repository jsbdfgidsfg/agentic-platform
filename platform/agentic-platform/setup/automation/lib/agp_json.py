#!/usr/bin/env python3
"""Small JSON helpers for agp-platform, so the script needs no jq. Standard library only.

  get PATH            print the value at a dotted path (list indexes are numbers); exit 1 if absent
  has-binding M ROLE  exit 0 when the IAM policy on stdin binds member M to ROLE (conditions ignored)
  missing PERM...     print the permissions a testIamPermissions response on stdin does NOT grant
  names SELECTED      the `names` report, from the step table on stdin
"""
import json, sys


def _load():
    raw = sys.stdin.read()
    return json.loads(raw) if raw.strip() else None


def get(path):
    d = _load()
    for part in [p for p in path.split('.') if p]:
        if isinstance(d, list) and part.isdigit() and int(part) < len(d):
            d = d[int(part)]
        elif isinstance(d, dict) and part in d:
            d = d[part]
        else:
            return 1
    print(d if isinstance(d, str) else json.dumps(d))
    return 0


def has_binding(member, role):
    pol = _load() or {}
    for b in pol.get('bindings', []):
        if b.get('role') == role and member in b.get('members', []):
            return 0
    return 1


def missing(perms):
    granted = set((_load() or {}).get('permissions', []))
    for p in perms:
        if p not in granted:
            print(p)
    return 0


def names(selected):
    sel = set(selected.split())
    setter, readers, have = {}, {}, set()
    for line in sys.stdin.read().splitlines():
        if not line.strip():
            continue
        phase, step, needs, sets, valued = (line.split('\t') + [''] * 5)[:5]
        for n in sets.split():
            setter.setdefault(n, step)
        if phase in sel:
            for n in needs.split():
                readers.setdefault(n, []).append(step)
        have.update(valued.split())
    rows = []
    for n in sorted(set(readers) | {k for k, s in setter.items()}):
        if n not in readers and n not in have and setter.get(n) is None:
            continue
        who = setter.get(n, 'you, or a step outside the platform phases (setup/README §5.2)')
        state = 'set' if n in have else '*tbd*'
        first = readers.get(n, ['-'])[0]
        rows.append((state, n, who, first))
    print('%-6s %-34s %-22s %s' % ('state', 'name', 'set by', 'first read by'))
    for r in rows:
        print('%-6s %-34s %-22s %s' % r)
    todo = [r for r in rows if r[0] != 'set' and r[2].startswith('you')]
    print('\n%d names have a value; %d are set by a step; %d must be supplied (penv_set NAME VALUE, from the signed NAMES record):'
          % (sum(1 for r in rows if r[0] == 'set'), sum(1 for r in rows if not r[2].startswith('you')), len(todo)))
    for r in todo:
        print('  ' + r[1])
    return 0


def main(argv):
    if not argv:
        print(__doc__); return 2
    cmd, args = argv[0], argv[1:]
    if cmd == 'get':
        return get(args[0])
    if cmd == 'has-binding':
        return has_binding(args[0], args[1])
    if cmd == 'missing':
        return missing(args)
    if cmd == 'names':
        return names(args[0] if args else '')
    print('unknown command ' + cmd, file=sys.stderr); return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
