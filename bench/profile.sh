#!/bin/sh
# Records scenarios of the key benchmark built with spinel --profile and
# prints the functions that take the most time by themselves, each named
# the way Ruby names it, from the symbol map Spinel writes beside the
# binary. Uses perf, or the binary PERF names; when no working perf is
# found it says so and leaves the profiling build for another sampler.
#
# Usage: bench/profile.sh [BINARY]   (default build/profile/keys)
set -eu

BIN=${1:-build/profile/keys}
PERF=${PERF:-perf}
MAP=$BIN.symbols.json
OUT=$(dirname "$BIN")
TOP=${PROFILE_TOP:-25}

if ! "$PERF" --version >/dev/null 2>&1; then
  echo "make profile: perf is not available ('$PERF --version' failed), so nothing was recorded."
  echo "The profiling build is $BIN; record it with any sampler that reads frame pointers, or set PERF to a working perf binary."
  exit 0
fi

for scenario in ${PROFILE_SCENARIOS:-j lh}; do
  data=$OUT/$scenario.data
  "$PERF" record -q -g -o "$data" "$BIN" "$scenario"
  echo "== $scenario: top $TOP functions by self time"
  "$PERF" report -i "$data" --stdio --no-children -g none --sort symbol 2>/dev/null | awk -v map="$MAP" -v top="$TOP" '
    BEGIN {
      while ((getline line < map) > 0) {
        if (match(line, /"c":"[^"]*"/)) {
          c = substr(line, RSTART + 5, RLENGTH - 6)
          if (match(line, /"ruby":"[^"]*"/)) names[c] = substr(line, RSTART + 8, RLENGTH - 9)
        }
      }
    }
    /^ +[0-9.]+%/ {
      symbol = $NF
      base = symbol
      sub(/\..*/, "", base)
      printf "%8s  %s\n", $1, (base in names) ? names[base] : symbol
      if (++shown >= top) exit
    }'
done
