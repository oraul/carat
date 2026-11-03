#!/bin/sh
# The measurements a change is compared on, and the comparison. Allocations
# per key and Spinel's re-narrowing rounds are the same on every machine for
# the same sources, so more of either than the base fails; time depends on
# the machine and the run, so time slower than the base by more than
# TIME_TOLERANCE percent only warns.
#
# Usage: sh tools/metrics.sh measure OUT [SCENARIO...]
#          write OUT, "name<TAB>value" lines: rounds.carat and
#          analysis_ms.carat from make dev-build's report, rounds.runner and
#          analysis_ms.runner from make test-build's, and allocs.S (objects
#          per key) and us.S (microseconds per key, handling and rendering)
#          for each scenario S, from bench/run.sh on make bench-budget's
#          binary; the scenarios default to DEFAULT_SCENARIOS below
#        sh tools/metrics.sh compare BASE CURRENT
#          print every name with both values; fail when an allocs.* or
#          rounds.* value grew or was not measured; warn when a us.* or
#          analysis_ms.* value grew by more than TIME_TOLERANCE percent; a
#          missing BASE is a notice and passes
#
# Environment: CARAT_TIMING (build/dev/carat.timing), RUNNER_TIMING
# (build/test/run_all.timing), BENCH_BIN (build/bench/keys-budget),
# BENCH_RUN (sh bench/run.sh), TIME_TOLERANCE (20), GITHUB_ACTIONS (when
# set, warnings and notices are also printed as annotations).
set -u

here=$(cd "$(dirname "$0")" && pwd)
# Cursor motion, scrolling, insert, delete and put, undo, repeat, the Ruby
# tokenizer, and opening a file: about eleven seconds on four cores.
DEFAULT_SCENARIOS="lh j insert ddp undo dot-ciw lh-ruby open-ruby"

die() {
  echo "metrics: $*" >&2
  exit 1
}

annotate() {
  [ -z "${GITHUB_ACTIONS:-}" ] || echo "::$1::$2"
}

measure() {
  out=$1
  shift
  scenarios=${*:-$DEFAULT_SCENARIOS}
  carat=${CARAT_TIMING:-build/dev/carat.timing}
  runner=${RUNNER_TIMING:-build/test/run_all.timing}
  for report in "$carat" "$runner"; do
    [ -f "$report" ] || die "$report is missing; make dev-build, test-build, and bench-budget write what this measures"
  done
  # shellcheck disable=SC2086
  lines=$(BENCH_BIN=${BENCH_BIN:-build/bench/keys-budget} ${BENCH_RUN:-sh bench/run.sh} $scenarios) ||
    die "the benchmark failed for: $scenarios"
  mkdir -p "$(dirname "$out")"
  {
    set -- $(sh "$here/analysis_budget.sh" --fields "$carat")
    printf 'rounds.carat\t%s\nanalysis_ms.carat\t%s\n' "$2" "$1"
    set -- $(sh "$here/analysis_budget.sh" --fields "$runner")
    printf 'rounds.runner\t%s\nanalysis_ms.runner\t%s\n' "$2" "$1"
    # A bench line: "NAME lines=... total=   68.7us ... allocs=27.0 ...".
    printf '%s\n' "$lines" | awk '
      NF {
        allocs = "?"; us = "?"
        for (i = 2; i <= NF; i++) {
          if ($i ~ /^allocs=/) allocs = substr($i, 8)
          else if ($i == "total=") us = $(i + 1)
          else if ($i ~ /^total=[0-9]/) us = substr($i, 7)
        }
        sub(/us$/, "", us)
        printf "allocs.%s\t%s\nus.%s\t%s\n", $1, allocs, $1, us
      }'
  } > "$out.tmp.$$" && mv "$out.tmp.$$" "$out"
  echo "metrics: wrote $out"
  cat "$out"
}

compare() {
  base=$1
  current=$2
  [ -f "$current" ] || die "$current is missing; run make metrics"
  if [ ! -f "$base" ]; then
    echo "metrics: no base measurement at $base; nothing compared"
    annotate notice "no measurement of main to compare with; nothing compared"
    return 0
  fi
  awk -F'\t' -v tol="${TIME_TOLERANCE:-20}" -v gh="${GITHUB_ACTIONS:-}" '
    NR == FNR { base[$1] = $2; next }
    {
      name = $1; cur = $2
      kind = name; sub(/\..*/, "", kind)
      strict = (kind == "allocs" || kind == "rounds")
      if (!(name in base)) { printf "new      %-22s %s\n", name, cur; next }
      was = base[name]
      if (strict && (cur == "?" || was == "?")) {
        printf "FAIL     %-22s %s -> %s: not measured\n", name, was, cur; failed = 1
      } else if (strict && cur + 0 > was + 0) {
        printf "FAIL     %-22s %s -> %s: more than main\n", name, was, cur; failed = 1
        if (gh) printf "::error::%s grew from %s to %s\n", name, was, cur
      } else if (!strict && was + 0 > 0 && cur != "?" && (cur - was) * 100 / was > tol + 0) {
        printf "warning  %-22s %s -> %s: %.0f%% slower, above %s%%\n", name, was, cur, (cur - was) * 100 / was, tol
        if (gh) printf "::warning::%s is %.0f%% slower than main (%s to %s)\n", name, (cur - was) * 100 / was, was, cur
      } else {
        printf "ok       %-22s %s -> %s\n", name, was, cur
      }
    }
    END { exit failed }' "$base" "$current" || { echo "metrics: allocations or analysis rounds grew; see the FAIL lines"; return 1; }
  echo "metrics: no allocation or analysis-round regression"
}

[ $# -ge 1 ] || { sed -n '/^# Usage:/,/^# Environment:/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
command=$1
shift
case "$command" in
  measure) [ $# -ge 1 ] || die "usage: measure OUT [SCENARIO...]"; measure "$@" ;;
  compare) [ $# -eq 2 ] || die "usage: compare BASE CURRENT"; compare "$@" ;;
  *) echo "metrics: unknown command $command" >&2; exit 2 ;;
esac
