#!/usr/bin/env python3
"""Apply the stand-in rows of tests/standins/*.tsv for one step (the offline tests only).

A row stands in for what a PERSON would have produced at a manual step, so that later AUTO steps
find it. Tab-separated, one per line, '#' comments allowed:

  STEP  value     NAME  VALUE                      penv_set NAME VALUE (overrides the generic fake value)
  STEP  file      PATH  CONTENT                    write CONTENT (\\n for newlines) to PATH
  STEP  evidence  STEP2 SLUG E-ID TISAX LOCATION [FILE]   evidence_add, as a person would type it
  STEP  commit    RELPATH CONTENT                  a file merged on PLATFORM_REPO_DIR's main (commit, push)
  STEP  shell     COMMAND                          a shell line run with ~/.platform-env sourced

STEP is a step id, or * for the world itself (applied once, before any phase runs).
In PATH, CONTENT and COMMAND: $HOME, $BLD, $PRD, $DATE and ${NAME} of any value are expanded.
usage: standin.py STEP DIR...   (prints one line per row applied)
"""
import os, re, subprocess, sys, datetime, glob

step, dirs = sys.argv[1], sys.argv[2:]
# Paths given as files are used as they are; a directory means every *.tsv in it.
# The tests pass only the phases under test for '*' (world) rows, and every file for step rows.
env_file = os.path.join(os.environ['HOME'], '.platform-env')


def sh(cmd):
    return subprocess.run(['bash', '-c', '. "$HOME/.platform-env" >/dev/null 2>&1; ' + cmd],
                          capture_output=True, text=True)


def value(name):
    if not os.path.exists(env_file):
        return ''
    r = sh('printf %%s "${%s-}"' % name)
    return r.stdout


def expand(s):
    s = s.replace('$DATE', datetime.datetime.utcnow().strftime('%Y-%m-%d'))
    s = s.replace('$BLD', os.environ.get('BLD', '')).replace('$PRD', os.environ.get('PRD', ''))
    s = s.replace('$HOME', os.environ['HOME'])
    return re.sub(r'\$\{([A-Z0-9_]+)\}', lambda m: value(m.group(1)), s)


def q(s):
    return "'" + s.replace("'", "'\\''") + "'"


rows = []
files = []
for d in dirs:
    files += sorted(glob.glob(os.path.join(d, '*.tsv'))) if os.path.isdir(d) else ([d] if os.path.isfile(d) else [])
for f in files:
    if True:
        for line in open(f, encoding='utf-8'):
            line = line.rstrip('\n')
            if not line.strip() or line.lstrip().startswith('#'):
                continue
            parts = line.split('\t')
            if parts[0] == step:
                rows.append((os.path.basename(f), parts[1:]))

for src, p in rows:
    kind, args = p[0], [expand(a) for a in p[1:]]
    if kind == 'value':
        r = sh('penv_set --force %s %s 2>&1 || penv_set %s %s' % (args[0], q(args[1]), args[0], q(args[1]))) if value(args[0]) else sh('penv_set %s %s' % (args[0], q(args[1])))
        print('standin %s value %s' % (step, args[0]))
    elif kind == 'file':
        os.makedirs(os.path.dirname(args[0]), exist_ok=True)
        open(args[0], 'w').write(args[1].replace('\\n', '\n'))
        print('standin %s file %s' % (step, args[0]))
    elif kind == 'evidence':
        r = sh('evidence_add ' + ' '.join(q(a) for a in args))
        print('standin %s evidence %s %s' % (step, args[0], (r.stdout + r.stderr).strip()[:120]))
    elif kind == 'commit':
        prd = value('PLATFORM_REPO_DIR') or os.environ.get('PRD', '')
        if not prd or not os.path.isdir(prd):
            print('standin %s commit: PLATFORM_REPO_DIR is not a directory; nothing written' % step, file=sys.stderr); continue
        path = os.path.join(prd, args[0]); os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'w').write(args[1].replace('\\n', '\n'))
        r = subprocess.run(['bash', '-c', 'cd %s && git add %s && git commit -qm %s && (git push -q origin HEAD:main 2>/dev/null || true)'
                            % (q(prd), q(args[0]), q('test stand-in: merged ' + args[0]))], capture_output=True, text=True)
        print('standin %s commit %s' % (step, args[0]))
    elif kind == 'shell':
        r = subprocess.run(['bash', '-c', '. "$HOME/.platform-env" >/dev/null 2>&1; cd "$HOME" || exit 2; ' + args[0]],
                           capture_output=True, text=True, cwd=os.environ['HOME'])
        print('standin %s shell rc=%d' % (step, r.returncode))
    else:
        print('standin %s: unknown kind %s in %s' % (step, kind, src), file=sys.stderr); sys.exit(2)
