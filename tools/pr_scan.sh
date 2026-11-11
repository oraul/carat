#!/bin/sh
# The pull request scan .github/workflows/scan.yml runs on every opened,
# edited, reopened, and synchronized pull request, and runnable locally:
# the title, the body, every commit message, and every commit's added
# lines against each parent, through the tools/scan_text.sh beside this
# script, each hit named. The workflow runs the base commit's copy, checked
# out to its own path, in the head's repository, so a pull request that
# edits the scanner is still read by the base's.
# Because an edit of the title or body reruns it, a footer added after the
# pull request opened turns the check red until the body is clean. The
# text arrives in the environment and is only ever piped to the scanner,
# never placed in a command.
#
# Usage: sh PATH/tools/pr_scan.sh, in the repository holding both commits
# Environment: PR_TITLE and PR_BODY, the pull request's text; BASE_SHA and
#   HEAD_SHA, its base and head commits (7 to 40 hexadecimal digits), both
#   in the local repository.
# Exits 1 when anything matched, 2 on a missing or unknown commit.
set -u

here=$(cd "$(dirname "$0")" && pwd)
scan="$here/scan_text.sh"
failed=0

for sha in "${BASE_SHA:-}" "${HEAD_SHA:-}"; do
  printf '%s' "$sha" | grep -q -x -E '[0-9a-f]{7,40}' &&
    git rev-parse --verify -q "$sha^{commit}" >/dev/null || {
    echo "FAIL scan: BASE_SHA and HEAD_SHA must name commits of this repository" >&2
    exit 2
  }
done

# shown OUTPUT STATUS: prints the scanner's OUTPUT, and fails on a STATUS
# other than 0.
shown() {
  [ -z "$1" ] || printf '%s\n' "$1"
  [ "$2" -eq 0 ] || failed=1
}

out=$(printf '%s\n' "${PR_TITLE:-}" | tr -d '\r' | sh "$scan" --where title)
shown "$out" $?
out=$(printf '%s\n' "${PR_BODY:-}" | tr -d '\r' | sh "$scan" --where body)
shown "$out" $?
commits=$(git rev-list "$BASE_SHA..$HEAD_SHA") || exit 2
for c in $commits; do
  out=$(git log -1 --format=%B "$c" | sh "$scan" --where "commit $(git rev-parse --short "$c")")
  shown "$out" $?
done
out=$(git log -p -m -U0 --no-color --no-renames --no-ext-diff --no-textconv --format= "$BASE_SHA..$HEAD_SHA" |
  sh "$scan" --diff)
status=$?
shown "$(printf '%s\n' "$out" | sort -u | grep .)" "$status"

if [ "$failed" -ne 0 ]; then
  echo "FAIL scan: the pull request holds text CLAUDE.md forbids; remove each hit above (an edited title or body reruns this check)"
  exit 1
fi
echo "ok   scan: the title, the body, $(printf '%s\n' "$commits" | grep -c .) commit message(s), and their added lines"
