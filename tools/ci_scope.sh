#!/bin/sh
# Decides whether a CI run needs the toolchain, the builds, and the tests,
# so the job named spin always reports, and a required check on it passes,
# even when they are skipped. Writes run=true or run=false and the reason to
# GITHUB_OUTPUT (to standard output when that is not set).
#
# The checks are skipped when
#   - every file the change touches is documentation that no test reads:
#     a Markdown file other than docs/actions.md and docs/compatibility.md,
#     which the action and ex tests compare with the code, or a file under
#     openspec/ or .claude/;
#   - a push to main is the squash commit of a pull request whose head has
#     the same tree and whose spin check passed: the tests ran on exactly
#     these files already.
# Anything it cannot establish, an API call that fails included, runs the
# checks.
#
# Environment: EVENT (github.event_name), REPO (owner/name), SHA (the
# commit checked out), GH_TOKEN for the gh calls on a push. The checkout
# needs the commit's first parent (fetch-depth 2): on a pull request the
# checked out commit is the merge of the head into the base, whose first
# parent is the base.
set -u

answer() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "run=$1" >> "$GITHUB_OUTPUT"
    echo "reason=$2" >> "$GITHUB_OUTPUT"
  fi
  echo "run=$1: $2"
  exit 0
}

# True when a path is documentation no test reads.
documentation() {
  case "$1" in
    docs/actions.md|docs/compatibility.md) return 1 ;;
    openspec/*|.claude/*|*.md) return 0 ;;
    *) return 1 ;;
  esac
}

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
for path in $changed; do
  documentation "$path" || answer true "$path is code, configuration, or a document a test reads"
done
answer false "only documentation that no test reads changed"
