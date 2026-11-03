#!/bin/sh
# The analysis budget. Spinel reports, with SP_TIMING=1, how long each
# phase of its analysis of a compile root took and how many rounds its
# fixpoint and its re-narrowing needed. The re-narrowing rounds are the
# budget: a value that widens to untyped and flows on through the program
# costs the analysis extra rounds over the whole library, and the count is
# the same on every machine for the same sources and compiler, so a root
# that needs more than MAX_ROUNDS fails. The analysis time depends on the
# machine, so a root slower than MAX_MS milliseconds is only a warning.
#
# Usage:
#   tools/analysis_budget.sh MAX_ROUNDS MAX_MS ROOT...
#       compiles each root to C only (-c, so no C compiler time is spent),
#       one after another, into build/analysis/<name>.c with its report in
#       build/analysis/<name>.timing, and checks every report; run through
#       make analysis-budget, which passes the compiler flags in SPIN_FLAGS
#   tools/analysis_budget.sh --check MAX_ROUNDS MAX_MS ROOT REPORT
#       checks the report a build of ROOT already wrote, as make test-build
#       does for the test runner, so the budget costs no second analysis
set -eu

check_only=0
if [ "${1:-}" = "--check" ]; then
  check_only=1
  shift
fi
if [ "$#" -lt 3 ] || { [ "$check_only" -eq 1 ] && [ "$#" -ne 4 ]; }; then
  echo "usage: tools/analysis_budget.sh MAX_ROUNDS MAX_MS ROOT..." >&2
  echo "       tools/analysis_budget.sh --check MAX_ROUNDS MAX_MS ROOT REPORT" >&2
  exit 2
fi
max_rounds=$1
max_ms=$2
shift 2

# The value of a key=value field on the line of a phase, "?" when absent.
field() {
  awk -v phase="$2" -v key="$3" '
    index($0, "phase=" phase " ") { for (i = 1; i <= NF; i++) if (index($i, key "=") == 1) { print substr($i, length(key) + 2); found = 1; exit } }
    END { if (!found) print "?" }' "$1"
}

# Checks the report of one root; returns 1 when it is over the budget.
check() {
  root=$1
  report=$2
  ms=$(field "$report" analysis ms)
  fixpoint=$(field "$report" analysis_fixpoint rounds)
  rounds=$(field "$report" analysis_renarrow rounds)
  echo "analysis budget: $root: analysis $ms ms, fixpoint $fixpoint rounds, re-narrowing $rounds rounds"
  if [ "$ms" != "?" ] && awk -v a="$ms" -v m="$max_ms" 'BEGIN { exit !(a > m) }'; then
    echo "analysis budget: warning: $root took $ms ms of analysis, more than $max_ms (machine dependent, not a failure)" >&2
  fi
  if [ "$rounds" = "?" ]; then
    echo "analysis budget: $root: the report has no re-narrowing rounds; see $report" >&2
    return 1
  fi
  if [ "$rounds" -gt "$max_rounds" ]; then
    echo "analysis budget: $root needs $rounds re-narrowing rounds, more than $max_rounds: a value widened to untyped; compare spinel --emit-rbs of this root against main" >&2
    return 1
  fi
  return 0
}

if [ "$check_only" -eq 1 ]; then
  check "$1" "$2" || exit 1
  echo "analysis budget: $1 within $max_rounds re-narrowing rounds"
  exit 0
fi

out=build/analysis
mkdir -p "$out"
failed=0
for root in "$@"; do
  name=$(echo "$root" | tr / _ | sed 's/\.rb$//')
  report="$out/$name.timing"
  if ! SP_TIMING=1 spinel ${SPIN_FLAGS:-} "$root" -c -o "$out/$name.c" >/dev/null 2>"$report"; then
    grep -v '^spinel-timing' "$report" >&2 || true
    echo "analysis budget: $root did not compile" >&2
    failed=1
    continue
  fi
  check "$root" "$report" || failed=1
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi
echo "analysis budget: every root within $max_rounds re-narrowing rounds"
