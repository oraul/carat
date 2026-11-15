#!/bin/sh
# Fails a build on a Spinel warning, a standard error line of the form
# "spinel: FILE:LINE:COL: warning: MESSAGE", or "spinel: warning: MESSAGE"
# for the warnings without a location (an --rbs ivar pin dropped, type
# inference that did not converge), which Spinel prints and still exits 0
# on.
#
# check LABEL FILE...: print every warning line of the files once (a
# missing file has none), then "LABEL: Spinel printed N warning(s)", and exit 1
# when there was one; exit 0 otherwise. The Makefile targets that
# compile with Spinel (dev-build, test-build, build, test-one, bench,
# bench-budget, types, gen-config, diagnose, diagnose-one) run it on the
# standard error they kept.
#
# Any other arguments: the compiler spinel-doctor runs when SPINEL names
# this file. Runs spinel with the arguments, copies its standard error
# back, appends its warning lines to SPINEL_WARNINGS_LOG, and exits with
# spinel's status, so make diagnose sees the warnings spinel-doctor's
# --quiet output leaves out.
set -u

PATTERN='^spinel: (.*: )?warning: '

if [ "${1:-}" = check ]; then
  if [ $# -lt 3 ]; then
    echo "usage: sh tools/spinel_warnings.sh check LABEL FILE..." >&2
    exit 2
  fi
  label=$2
  shift 2
  # each once: spinel-doctor compiles a root more than once
  lines=$(grep -h -s -E "$PATTERN" "$@" | awk '!seen[$0]++')
  [ -z "$lines" ] && exit 0
  printf '%s\n' "$lines" >&2
  count=$(printf '%s\n' "$lines" | wc -l | tr -d ' ')
  echo "$label: Spinel printed $count warning(s); a build fails on any (docs/spinel-notes.md)" >&2
  exit 1
fi

if [ -z "${SPINEL_WARNINGS_LOG:-}" ]; then
  echo "spinel_warnings: SPINEL_WARNINGS_LOG names no log for the warnings of spinel $*" >&2
  exit 2
fi
err=$(mktemp "${TMPDIR:-/tmp}/carat-spinel.XXXXXX") || exit 2
spinel "$@" 2> "$err"
status=$?
cat "$err" >&2
grep -E "$PATTERN" "$err" >> "$SPINEL_WARNINGS_LOG"
rm -f "$err"
exit $status
