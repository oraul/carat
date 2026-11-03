#!/bin/sh
# The analysis budget: compiles each compile root given, to C only (-c, so
# no C compiler time is spent), with SP_TIMING=1, which makes Spinel report
# on standard error how long each phase of its analysis took and how many
# rounds its fixpoint and its re-narrowing needed. The roots compile in
# parallel, each into build/analysis/<name>.c with its report in
# build/analysis/<name>.timing.
#
# The re-narrowing rounds are the budget: a value that widens to untyped
# and flows on through the program costs the analysis extra rounds over
# the whole library, and the count is the same on every machine for the
# same sources and compiler, so the target fails when a root needs more
# than MAX_ROUNDS. The analysis time depends on the machine, so a root
# slower than MAX_MS milliseconds is only a warning.
#
# Usage: tools/analysis_budget.sh MAX_ROUNDS MAX_MS ROOT...
#        run through make analysis-budget, which passes the compiler flags
#        in SPIN_FLAGS
set -eu

if [ "$#" -lt 3 ]; then
  echo "usage: tools/analysis_budget.sh MAX_ROUNDS MAX_MS ROOT..." >&2
  exit 2
fi
max_rounds=$1
max_ms=$2
shift 2

out=build/analysis
mkdir -p "$out"

# One background compile per root; each writes its report and an exit file.
for root in "$@"; do
  name=$(echo "$root" | tr / _ | sed 's/\.rb$//')
  (
    status=0
    SP_TIMING=1 spinel ${SPIN_FLAGS:-} "$root" -c -o "$out/$name.c" >/dev/null 2>"$out/$name.timing" || status=$?
    echo "$status" > "$out/$name.exit"
  ) &
done
wait

# The value of a key=value field on the line of a phase, "?" when absent.
field() {
  awk -v phase="$2" -v key="$3" '
    index($0, "phase=" phase " ") { for (i = 1; i <= NF; i++) if (index($i, key "=") == 1) { print substr($i, length(key) + 2); found = 1; exit } }
    END { if (!found) print "?" }' "$1"
}

failed=0
for root in "$@"; do
  name=$(echo "$root" | tr / _ | sed 's/\.rb$//')
  report="$out/$name.timing"
  if [ "$(cat "$out/$name.exit")" != "0" ]; then
    cat "$report" >&2
    echo "analysis budget: $root did not compile" >&2
    failed=1
    continue
  fi
  ms=$(field "$report" analysis ms)
  fixpoint=$(field "$report" analysis_fixpoint rounds)
  rounds=$(field "$report" analysis_renarrow rounds)
  echo "analysis budget: $root: analysis $ms ms, fixpoint $fixpoint rounds, re-narrowing $rounds rounds"
  if [ "$rounds" = "?" ]; then
    echo "analysis budget: $root: the report has no re-narrowing rounds; see $report" >&2
    failed=1
  elif [ "$rounds" -gt "$max_rounds" ]; then
    echo "analysis budget: $root needs $rounds re-narrowing rounds, more than $max_rounds: a value widened to untyped; compare spinel --emit-rbs of this root against main" >&2
    failed=1
  fi
  if [ "$ms" != "?" ] && awk -v a="$ms" -v m="$max_ms" 'BEGIN { exit !(a > m) }'; then
    echo "analysis budget: warning: $root took $ms ms of analysis, more than $max_ms (machine dependent, not a failure)" >&2
  fi
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi
echo "analysis budget: every root within $max_rounds re-narrowing rounds"
