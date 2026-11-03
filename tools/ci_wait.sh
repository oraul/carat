#!/bin/sh
# The merger's wait between two reads of a pull request's check runs: it
# sleeps in the foreground, so the merger's shell call blocks and its turn
# goes on; a background sleep ends a subagent's turn, and the merger then
# returned pending minutes into a CI run. At most 540 seconds, under the
# shell tool's ten-minute limit for one call.
#
# Usage: sh tools/ci_wait.sh SECONDS   (a whole number from 1 to 540)
set -u

MAX=540
case "${1:-}" in
  ""|*[!0-9]*) echo "ci_wait: not a whole number of seconds: ${1:-}" >&2; exit 2 ;;
  # Four digits or more is past the bound; refused here, because a number
  # past the shell's integer range makes both tests below error and fail
  # open.
  ????*) echo "ci_wait: refused: $1 seconds; wait 1 to $MAX seconds at a time" >&2; exit 2 ;;
esac
seconds=$(expr "$1" + 0)
if [ "$seconds" -lt 1 ] || [ "$seconds" -gt $MAX ]; then
  echo "ci_wait: refused: $1 seconds; wait 1 to $MAX seconds at a time" >&2
  exit 2
fi
sleep "$seconds"
echo "ci_wait: waited $seconds seconds"
