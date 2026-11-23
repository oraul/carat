# Backlog: tools/run_tests.sh

### runner=$1 under set -u fails with the shell's parameter-not-set at tools/run_tests.sh:17 (sprint-30 sweep quality, note 43)

- Location: tools/run_tests.sh:17
- Why: runner=$1 under set -u fails with the shell's parameter-not-set error when no runner is given, before the usage the header documents
- Fix: check $# first and print the usage line with exit 1
- Category: pipeline
- Added: 2026-11-23
