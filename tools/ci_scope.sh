#!/bin/sh
# Decides whether a CI run needs the toolchain, the builds, and the tests,
# so the job named spin always reports, and a required check on it passes,
# even when they are skipped. Writes run=true or run=false and the reason to
# GITHUB_OUTPUT (to standard output when that is not set).
#
# The checks are skipped when
#   - every file the change touches is documentation that no test reads
#     (documentation in tools/rules.sh: the records, a LICENSE file, and
#     Markdown or .claude/ files but those a test or tools case reads);
#   - on a pull request, every file the merge commit changes against the
#     newest earlier head of the pull request whose spin check passed is
#     such documentation (GREEN_LOOKUPS heads back at most);
#   - a push to main is the squash commit of a pull request whose head has
#     the same tree and whose spin check passed: the tests ran on exactly
#     these files already.
# It also writes tools=true or tools=false: whether make tools-test reads
# a changed file (TOOLS_RE in tools/rules.sh), true on a run by hand or
# when the changed files are unknown, false on the equal-tree push. And it
# writes compile=true or compile=false: whether the steps that compile run,
# true when the checks run, and on a push also when CACHED, the hit of a
# lookup-only probe of the compile cache's exact entry, is not true, so an
# equal-tree push of sources main already compiled compiles nothing while
# one main has not compiled warms the cache, measures main, and builds the
# release binary.
# Anything it cannot establish, an API call that fails included, runs the
# checks.
#
# Environment: EVENT (github.event_name), REPO (owner/name), SHA (the
# commit checked out), GH_TOKEN for the gh calls, CACHED on a push, and on
# a pull request
# PR (its number) and HEAD_SHA (its head). The checkout needs the commit's
# first parent (fetch-depth 2): on a pull request the checked out commit
# is the merge of the head into the base, whose first parent is the base;
# a green head missing from the checkout is fetched by its sha.
set -u

# answer RUN REASON: writes RUN, REASON, tools, and compile; the reason goes on one line whatever it holds, so
# GITHUB_OUTPUT keeps one run= and one reason= line. printf, never echo:
# dash's echo expands backslash escapes, and git quotes a path holding a
# line break as "x\ny", which echo would turn back into a line break.
answer() {
  reason=$(printf '%s' "$2" | tr '\r\n' '  ')
  compile=false
  if [ "$1" = true ] || { [ "$event" = push ] && [ "${CACHED:-}" != true ]; }; then compile=true; fi
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf 'run=%s\n' "$1" >> "$GITHUB_OUTPUT"
    printf 'reason=%s\n' "$reason" >> "$GITHUB_OUTPUT"
    printf 'tools=%s\n' "$tools" >> "$GITHUB_OUTPUT"
    printf 'compile=%s\n' "$compile" >> "$GITHUB_OUTPUT"
  fi
  printf 'run=%s: %s\n' "$1" "$reason"
  printf 'tools=%s\n' "$tools"
  printf 'compile=%s\n' "$compile"
  exit 0
}

# A gh answer is used only when it is the kind of value asked for: digits
# prints a non-empty run of digits (a number or a count), hex one of
# lowercase hex digits (a commit or tree sha), and nothing for any other
# answer, an error body included, which leaves it unknown.
digits() {
  case "$1" in ""|*[!0-9]*) ;; *) printf '%s' "$1" ;; esac
}
hex() {
  case "$1" in ""|*[!0-9a-f]*) ;; *) printf '%s' "$1" ;; esac
}

here=$(cd "$(dirname "$0")" && pwd)
. "$here/rules.sh"

GREEN_LOOKUPS=10
tools=true
event=${EVENT:-}
if [ "$event" != "pull_request" ] && [ "$event" != "push" ]; then
  answer true "a $event run always runs the checks"
fi

if [ "$event" = "push" ]; then
  head=$(hex "$(gh api "repos/$REPO/commits/$SHA/pulls" --jq '.[0].head.sha // empty' 2>/dev/null)")
  number=$(digits "$(gh api "repos/$REPO/commits/$SHA/pulls" --jq '.[0].number // empty' 2>/dev/null)")
  if [ -n "$head" ] && [ -n "$number" ]; then
    head_tree=$(hex "$(gh api "repos/$REPO/commits/$head" --jq '.commit.tree.sha' 2>/dev/null)")
    passed=$(digits "$(gh api "repos/$REPO/commits/$head/check-runs?check_name=spin" --jq '[.check_runs[] | select(.conclusion == "success")] | length' 2>/dev/null)")
    tree=$(git rev-parse HEAD^{tree})
    if [ -n "$head_tree" ] && [ "$head_tree" = "$tree" ] && [ "${passed:-0}" -gt 0 ]; then
      tools=false
      answer false "the tree equals the head of pull request $number, whose spin check passed"
    fi
  fi
fi

changed=$(git diff --name-only HEAD^1 HEAD 2>/dev/null) || answer true "the first parent is not available to compare with"
if [ -z "$changed" ]; then
  answer true "no changed file was found"
fi
printf '%s\n' "$changed" | grep -q -E "$TOOLS_RE" || tools=false
code=""
for path in $changed; do
  documentation "$path" || { code=$path; break; }
done
[ -n "$code" ] || answer false "only documentation that no test reads changed"
[ "$event" = "pull_request" ] || answer true "$code is code, configuration, or a document a test reads"
[ -n "${PR:-}" ] && [ -n "${HEAD_SHA:-}" ] || answer true "$code is code, configuration, or a document a test reads, and no pull request was named"

# The newest earlier head of the pull request whose spin check passed, at
# most GREEN_LOOKUPS commits back from the head; the merge commit is
# compared with it, so a base that moved with code since runs the checks.
green=""
commits=$(gh api "repos/$REPO/pulls/${PR:-}/commits?per_page=100" --jq '.[].sha' 2>/dev/null || true)
lookups=0
for sha in $(printf '%s\n' $commits | awk '{ l[NR] = $0 } END { for (i = NR; i > 0; i--) print l[i] }'); do
  [ -n "$(hex "$sha")" ] || continue
  [ "$sha" != "${HEAD_SHA:-}" ] || continue
  lookups=$((lookups + 1))
  [ "$lookups" -le "$GREEN_LOOKUPS" ] || break
  passed=$(digits "$(gh api "repos/$REPO/commits/$sha/check-runs?check_name=spin" --jq '[.check_runs[] | select(.conclusion == "success")] | length' 2>/dev/null)")
  if [ "${passed:-0}" -gt 0 ]; then green=$sha; break; fi
done
[ -n "$green" ] || answer true "$code is code, configuration, or a document a test reads, and no earlier head of the pull request passed"
git cat-file -e "$green^{commit}" 2>/dev/null || git fetch -q --depth=1 origin "$green" 2>/dev/null || answer true "$code is code, and the last green head $green could not be fetched"
since=$(git diff --name-only "$green" HEAD 2>/dev/null) || answer true "$code is code, and the last green head $green could not be compared"
for path in $since; do
  documentation "$path" || answer true "$path is code, configuration, or a document a test reads, changed since the last green head $green"
done
answer false "only documentation that no test reads changed since the last green head $green"
