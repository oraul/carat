#!/bin/sh
# Runs the key benchmark built at build/bench/keys and adds the allocations
# per key to each scenario's line. Allocations come from Spinel's
# SPINEL_ALLOC_REPORT, which counts every object a program allocates and
# writes the totals at exit: each scenario is run twice, with SMALL and
# with LARGE keys, and the difference of the two totals divided by the
# difference of the key counts is what one key allocates, with the setup
# of the scenario cancelled out. When taskset exists the runs are pinned to
# one core.
#
# Usage: bench/run.sh [SCENARIO...]       every scenario when none is named
#        bench/run.sh --budget SCENARIO MAX
#                                         fail unless SCENARIO allocates
#                                         fewer than MAX objects per key
set -eu

BIN=${BENCH_BIN:-build/bench/keys}
SMALL=${BENCH_SMALL:-200}
LARGE=${BENCH_LARGE:-1200}
REPORT=$(mktemp "${TMPDIR:-/tmp}/carat-bench-alloc.XXXXXX")

pin() {
  if command -v taskset >/dev/null 2>&1; then
    taskset -c "${BENCH_CORE:-0}" "$@"
  else
    "$@"
  fi
}

# The objects and bytes a run allocates, from its report.
totals() {
  awk '/^alloc;/ { n += $2 } /^# bytes / { b += $4 } END { printf "%d %d\n", n, b }' "$1"
}

# Prints "objects bytes" per key for a scenario.
per_key() {
  SPINEL_ALLOC_REPORT="$REPORT" pin "$BIN" "$1" "$SMALL" >/dev/null
  set -- "$1" $(totals "$REPORT")
  small_n=$2
  small_b=$3
  SPINEL_ALLOC_REPORT="$REPORT" pin "$BIN" "$1" "$LARGE" >/dev/null
  set -- "$1" $(totals "$REPORT")
  rm -f "$REPORT"
  awk -v a="$small_n" -v b="$2" -v c="$small_b" -v d="$3" -v k="$((LARGE - SMALL))" \
    'BEGIN { printf "%.1f %.0f\n", (b - a) / k, (d - c) / k }'
}

if [ ! -x "$BIN" ]; then
  echo "bench/run.sh: $BIN is missing; run make bench" >&2
  exit 2
fi

if [ "${1:-}" = "--budget" ]; then
  scenario=$2
  max=$3
  set -- $(per_key "$scenario")
  if awk -v n="$1" -v m="$max" 'BEGIN { exit !(n < m) }'; then
    echo "allocation budget: $scenario allocates $1 objects ($2 bytes) per key, under $max"
  else
    echo "allocation budget exceeded: $scenario allocates $1 objects ($2 bytes) per key, the budget is under $max" >&2
    exit 1
  fi
  exit 0
fi

if [ $# -eq 0 ]; then
  set -- lh j insert w ddp lh-utf8 j-utf8 long-ascii long-utf8 lh-explorer j-explorer
fi
for scenario in "$@"; do
  line=$(pin "$BIN" "$scenario")
  set -- $(per_key "$scenario")
  echo "$line allocs=$1 alloc_bytes=$2"
done
