#!/bin/sh
# Decides whether a CI run needs the toolchain, the builds, and the tests,
# so the job named spin always reports, and a required check on it passes,
# even when they are skipped. Writes run=true or run=false and the reason to
# GITHUB_OUTPUT (to standard output when that is not set).
#
# The checks are skipped when
#   - every file the change touches is documentation that no test reads:
#     a Markdown file other than docs/actions.md and docs/compatibility.md,
#     which the action and ex tests compare with the code, and
#     docs/codebase-map.md, whose coverage the lint test checks, or a file
#     under openspec/ or .claude/ other than the agents, the workflows, and
#     .claude/settings.json, which make tools-test reads;
#   - on a pull request, every file the merge commit changes against the
#     newest earlier head of the pull request whose spin check passed is
#     such documentation (GREEN_LOOKUPS heads back at most);
#   - a push to main is the squash commit of a pull request whose head has
#     the same tree and whose spin check passed: the tests ran on exactly
#     these files already.
# Anything it cannot establish, an API call that fails included, runs the
# checks.
#
# Environment: EVENT (github.event_name), REPO (owner/name), SHA (the
# commit checked out), GH_TOKEN for the gh calls, and on a pull request
# PR (its number) and HEAD_SHA (its head). The checkout needs the commit's
# first parent (fetch-depth 2): on a pull request the checked out commit
# is the merge of the head into the base, whose first parent is the base;
# a green head missing from the checkout is fetched by its sha.
set -u

answer() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "run=$1" >> "$GITHUB_OUTPUT"
    echo "reason=$2" >> "$GITHUB_OUTPUT"
  fi
  echo "run=$1: $2"
  exit 0
}

here=$(cd "$(dirname "$0")" && pwd)
. "$here/rules.sh"

# True when a path is documentation no test reads: a records-only path of
# tools/rules.sh (RECORDS_RE), or one of the case below.
documentation() {
  ! printf '%s\n' "$1" | grep -q -E "^($RECORDS_RE)" || return 0
  case "$1" in
    docs/actions.md|docs/compatibility.md|docs/codebase-map.md) return 1 ;;
    .claude/agents/*|.claude/workflows/*|.claude/settings.json) return 1 ;;
    .claude/*|*.md) return 0 ;;
    *) return 1 ;;
  esac
}

GREEN_LOOKUPS=10
event=${EVENT:-}
if [ "$event" != "pull_request" ] && [ "$event" != "push" ]; then
  answer true "a $event run always runs the checks"
fi

if [ "$event" = "push" ]; then
  head=$(gh api "repos/$REPO/commits/$SHA/pulls" --jq '.[0].head.sha // empty' 2>/dev/null || true)
  number=$(gh api "repos/$REPO/commits/$SHA/pulls" --jq '.[0].number // empty' 2>/dev/null || true)
  if [ -n "$head" ]; then
    head_tree=$(gh api "repos/$REPO/commits/$head" --jq '.commit.tree.sha' 2>/dev/null || true)
    passed=$(gh api "repos/$REPO/commits/$head/check-runs?check_name=spin" --jq '[.check_runs[] | select(.conclusion == "success")] | length' 2>/dev/null || echo 0)
    tree=$(git rev-parse HEAD^{tree})
    if [ -n "$head_tree" ] && [ "$head_tree" = "$tree" ] && [ "${passed:-0}" -gt 0 ]; then
      answer false "the tree equals the head of pull request $number, whose spin check passed"
    fi
  fi
fi

changed=$(git diff --name-only HEAD^1 HEAD 2>/dev/null) || answer true "the first parent is not available to compare with"
if [ -z "$changed" ]; then
  answer true "no changed file was found"
fi
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
  case "$sha" in *[!0-9a-f]*|"") continue ;; esac
  [ "$sha" != "${HEAD_SHA:-}" ] || continue
  lookups=$((lookups + 1))
  [ "$lookups" -le "$GREEN_LOOKUPS" ] || break
  passed=$(gh api "repos/$REPO/commits/$sha/check-runs?check_name=spin" --jq '[.check_runs[] | select(.conclusion == "success")] | length' 2>/dev/null || echo 0)
  case "$passed" in ""|*[!0-9]*) passed=0 ;; esac
  if [ "$passed" -gt 0 ]; then green=$sha; break; fi
done
[ -n "$green" ] || answer true "$code is code, configuration, or a document a test reads, and no earlier head of the pull request passed"
git cat-file -e "$green^{commit}" 2>/dev/null || git fetch -q --depth=1 origin "$green" 2>/dev/null || answer true "$code is code, and the last green head $green could not be fetched"
since=$(git diff --name-only "$green" HEAD 2>/dev/null) || answer true "$code is code, and the last green head $green could not be compared"
for path in $since; do
  documentation "$path" || answer true "$path is code, configuration, or a document a test reads, changed since the last green head $green"
done
answer false "only documentation that no test reads changed since the last green head $green"
