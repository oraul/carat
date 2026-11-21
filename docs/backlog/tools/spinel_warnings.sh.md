# Backlog: tools/spinel_warnings.sh

### tools/spinel_warnings.sh:42 the wrapper's temporary file has no trap

- Where: tools/spinel_warnings.sh:42.
- Why: the wrapper's mktemp file has no trap, so an interrupted or killed diagnose compile leaves carat-spinel.XXXXXX files in TMPDIR (quality advisory, shell hygiene).
- Fix: trap 'rm -f "$err"' EXIT INT TERM after mktemp.
- Category: pipeline
- Added: 2026-11-15
