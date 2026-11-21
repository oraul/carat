#!/bin/sh
# A delivery lane's facts, read from git and the run state's check log,
# never typed (contributor-harness): an agent reports these values instead
# of copying a hash by hand, and the workflow reads the head and the dirty
# count from them after each contributor start. One "key value" line each:
#   head      git rev-parse --short=12 HEAD in the lane, tmp/.lane-CHANGE
#   branch    the lane's branch, or detached
#   base      the merge base of HEAD and origin/main, 12 characters, or none
#   pushed    yes when origin's branch (refs/remotes/origin/BRANCH, as the
#             last fetch left it) is HEAD, else no
#   dirty     the count of uncommitted paths, git status --porcelain, or
#             unknown when that fails
#   check     the verdict of the last check, the last line of
#             build/stages/CHANGE/check.log: passed, failed, killed,
#             superseded, or escaped, or none without one
#   check_at  the commit that check ran at, or none
#   machinery yes when a path changed from base to HEAD lies under tools/,
#             is the Makefile, or lies under test/runner/, the check's own
#             machinery, whose stage records the branch's runner wrote, so
#             the workflow backs no contributor's pass; no otherwise;
#             unknown without a base or when git diff fails
# Runs from the main checkout or any worktree of it: the lane and the check
# log are the main checkout's. Exits 2, printing nothing on stdout, for a
# bad change name, no repository, or no lane worktree.
#
# Usage: sh tools/lane_facts.sh CHANGE
set -u

die() {
  echo "lane_facts: $*" >&2
  exit 2
}

[ $# -eq 1 ] || die "usage: sh tools/lane_facts.sh CHANGE"
change=$1
case "$change" in
  "" | -* | *[!a-z0-9-]*) die "not a change name: $change" ;;
esac
common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || die "not a git repository"
[ "$(basename "$common")" = .git ] || die "the main checkout has no .git directory: $common"
top=$(dirname "$common")
lane=$top/tmp/.lane-$change
[ -f "$lane/.git" ] || die "no lane worktree tmp/.lane-$change"

lane_git() {
  git -C "$lane" "$@"
}

head=$(lane_git rev-parse --verify -q --short=12 HEAD) || die "the lane tmp/.lane-$change has no HEAD"
full=$(lane_git rev-parse --verify -q HEAD)
branch=$(lane_git symbolic-ref -q --short HEAD) || branch=detached
base=none
merge_base=$(lane_git merge-base HEAD refs/remotes/origin/main 2>/dev/null) &&
  base=$(lane_git rev-parse --short=12 "$merge_base")
pushed=no
if [ "$branch" != detached ] &&
  [ "$(lane_git rev-parse --verify -q "refs/remotes/origin/$branch" 2>/dev/null)" = "$full" ]; then
  pushed=yes
fi
# unknown when git status fails, never 0, so a reader cannot take an
# unreadable tree for a committed one.
dirty=unknown
if porcelain=$(lane_git status --porcelain 2>/dev/null); then
  dirty=$(printf '%s\n' "$porcelain" | grep -c .)
fi

# The check's own machinery: the scripts and recipes that run the stages.
machinery=unknown
if [ -n "${merge_base:-}" ] && changed=$(lane_git diff --no-renames --name-only "$merge_base" HEAD 2>/dev/null); then
  machinery=no
  ! printf '%s\n' "$changed" | grep -q -E '^(tools/|Makefile$|test/runner/)' || machinery=yes
fi

# The verdict line: "check: every stage passed at C[; ...]" or
# "check: stage S WORD at C[; read LOG]".
check=none
check_at=none
last=$(tail -1 "$top/build/stages/$change/check.log" 2>/dev/null)
case "$last" in
  "check: every stage passed at "*)
    word=passed
    at=${last#"check: every stage passed at "} ;;
  "check: stage "*" at "*)
    rest=${last#"check: stage "}
    rest=${rest#* }
    word=${rest%% *}
    at=${rest#* at } ;;
  *) word="" at="" ;;
esac
at=${at%%;*}
at=${at%% *}
case "$word" in
  passed | failed | killed | superseded | escaped)
    case "$at" in
      "" | *[!0-9a-f]*) ;;
      *) check=$word check_at=$at ;;
    esac ;;
esac

printf 'head %s\nbranch %s\nbase %s\npushed %s\ndirty %s\ncheck %s\ncheck_at %s\nmachinery %s\n' \
  "$head" "$branch" "$base" "$pushed" "$dirty" "$check" "$check_at" "$machinery"
