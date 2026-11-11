#!/bin/sh
# The pull request by tag. A pull request created or edited over GitHub's
# API from a cloud session reaches GitHub with a footer the session's
# network layer appends, while a git push arrives unchanged; so the
# delivery never creates a pull request from its session. The contributor
# pushes an annotated tag pr/BRANCH whose message is the title, a blank
# line, and the gated body; its push runs .github/workflows/pr-tag.yml,
# whose completion runs .github/workflows/open-pr.yml from main, which
# creates the pull request from it with main's copy of this script, never
# the tagged commit's.
#
# Usage:
#   sh tools/pr_tag.sh push CHANGE TITLE    the contributor, after
#       tools/run_state.sh push: gates build/pipeline/CHANGE.body.md and
#       TITLE, tags the pushed head pr/BRANCH, and pushes only that tag;
#       when a pull request's head is already the pushed head (a resumed
#       package step), it pushes nothing and says to run wait
#   sh tools/pr_tag.sh wait CHANGE [SECONDS]   the contributor: waits, at
#       most SECONDS (1 to 540, default 540), until the tag is gone from
#       origin and a pull request's head is the pushed head, and records
#       its number (tools/run_state.sh set CHANGE pr N)
#   sh tools/pr_tag.sh read TAG DIR         the workflow: TAG's message
#       into DIR/title and DIR/body
#   sh tools/pr_tag.sh branch BRANCH        the workflow: refuses a branch
#       of no allowed type or missing on origin
#   sh tools/pr_tag.sh gate DIR TOOLS       the workflow: TOOLS/gates.sh
#       pr-body on DIR/body and TOOLS/scan_text.sh on DIR/title, TOOLS
#       the tools directory of main's checkout
#   sh tools/pr_tag.sh same DIR             the workflow: DIR/title.live and
#       DIR/body.live, read back from the pull request, equal DIR/title
#       and DIR/body but for trailing newlines
#
# Environment: WAIT_STEP, the seconds between two reads of origin (10).
# Exit status: 0 done, 1 refused or not equal, 2 a usage error.
set -u

here=$(cd "$(dirname "$0")" && pwd)
# The branch types of CLAUDE.md, the guard's pattern.
BRANCH_RE='^(feature|bugfix|hotfix|release|chore)/[a-z0-9][a-z0-9-]*$'
CHANGE_RE='^[a-z0-9][a-z0-9-]*$'
MAX_WAIT=540

usage() {
  sed -n '/^# Usage:/,/^# Exit status:/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

refuse() {
  echo "pr_tag: refused: $*" >&2
  exit 1
}

matches() {
  printf '%s\n' "$1" | grep -q -x -E "$2"
}

state() {
  sh "$here/run_state.sh" get "$change" "$1" 2>/dev/null
}

# gate_text TITLE-FILE BODY-FILE TOOLS: the pr-body gate and the title scan
# of TOOLS, main's in the workflow.
gate_text() {
  [ "$(wc -l < "$1")" -eq 1 ] && [ -n "$(tr -d ' \t\r\n' < "$1")" ] || refuse "the title is not one line of text"
  out=$(sh "$3/gates.sh" pr-body "$2") || refuse "the body fails the pr-body gate:
$out"
  out=$(tr -d '\r' < "$1" | sh "$3/scan_text.sh" --where title)
  [ -z "$out" ] || refuse "the title holds forbidden text:
$out"
}

# chomped FILE: the file's text without its trailing newlines.
chomped() {
  printf '%s' "$(cat "$1")"
}

cmd=${1:-}
[ -n "$cmd" ] || usage
shift
case "$cmd" in
  push)
    [ $# -eq 2 ] || usage
    change=$1
    title=$2
    matches "$change" "$CHANGE_RE" || refuse "not a change name: $change"
    branch=$(state branch)
    pushed=$(state pushed)
    matches "$branch" "$BRANCH_RE" || refuse "the run state's branch is not a Conventional Branch: $branch"
    matches "$pushed" '[0-9a-f]{40}' || refuse "no pushed head in the run state; push with tools/run_state.sh push first"
    [ "$(git rev-parse HEAD)" = "$pushed" ] || refuse "HEAD is not the pushed head $pushed"
    case "$title" in *"
"*) refuse "the title is more than one line" ;; esac
    tag=pr/$branch
    refs=$(git ls-remote origin "refs/tags/$tag" 'refs/pull/*/head') || refuse "origin cannot be read"
    if printf '%s\n' "$refs" | grep -q -F "refs/tags/$tag"; then
      refuse "the tag $tag is on origin: the open-pr workflow has not consumed it (pending or failed; read its log)"
    fi
    # A resumed package step: open-pr consumed the tag and the pull request
    # is open at the pushed head, so a second tag would only fail to open it.
    if printf '%s\n' "$refs" | awk -v sha="$pushed" '$1 == sha && $2 ~ /^refs\/pull\/[0-9]+\/head$/ { f = 1 } END { exit !f }'; then
      echo "pr_tag: a pull request's head is already $pushed, so $tag is not pushed again; run sh tools/pr_tag.sh wait $change"
      exit 0
    fi
    work=$(mktemp -d) || exit 1
    trap 'rm -rf "$work"' EXIT
    printf '%s\n' "$title" > "$work/title"
    body=build/pipeline/$change.body.md
    gate_text "$work/title" "$body" "$here"
    { printf '%s\n\n' "$title"; cat "$body"; } > "$work/message"
    git tag -d "$tag" >/dev/null 2>&1 || true
    # Verbatim, since the default cleanup strips the body's ## headings.
    git -c user.name=Claude -c user.email=noreply@anthropic.com tag -a --cleanup=verbatim -F "$work/message" "$tag" "$pushed" ||
      refuse "git tag failed"
    git push -q origin "refs/tags/$tag" || refuse "the push of $tag failed"
    echo "pr_tag: pushed $tag at $pushed; wait with sh tools/pr_tag.sh wait $change" ;;
  wait)
    [ $# -ge 1 ] && [ $# -le 2 ] || usage
    change=$1
    seconds=${2:-$MAX_WAIT}
    matches "$change" "$CHANGE_RE" || refuse "not a change name: $change"
    case "$seconds" in ""|*[!0-9]*|????*) refuse "wait 1 to $MAX_WAIT seconds: $seconds" ;; esac
    [ "$seconds" -ge 1 ] && [ "$seconds" -le $MAX_WAIT ] || refuse "wait 1 to $MAX_WAIT seconds: $seconds"
    step=${WAIT_STEP:-10}
    matches "$step" '[0-9]{1,3}' || refuse "WAIT_STEP is not a number of seconds: $step"
    branch=$(state branch)
    pushed=$(state pushed)
    matches "$pushed" '[0-9a-f]{40}' || refuse "no pushed head in the run state"
    tag=pr/$branch
    waited=0
    while :; do
      refs=$(git ls-remote origin "refs/tags/$tag" 'refs/pull/*/head') || refs=""
      if ! printf '%s\n' "$refs" | grep -q -F "refs/tags/$tag"; then
        number=$(printf '%s\n' "$refs" | awk -v sha="$pushed" '$1 == sha && $2 ~ /^refs\/pull\/[0-9]+\/head$/ { split($2, p, "/"); if (p[3] + 0 > n) n = p[3] + 0 } END { if (n) print n }')
        if [ -n "$number" ]; then
          sh "$here/run_state.sh" set "$change" pr "$number" >/dev/null || refuse "the run state did not take pr $number"
          echo "pr_tag: pull request $number at $pushed"
          exit 0
        fi
      fi
      [ "$waited" -lt "$seconds" ] || break
      sleep "$step" || refuse "sleep failed"
      waited=$((waited + step))
    done
    if printf '%s\n' "$refs" | grep -q -F "refs/tags/$tag"; then
      refuse "after $seconds seconds the tag $tag is still on origin: the open-pr workflow is pending or failed; read its log, never create the pull request another way"
    fi
    refuse "after $seconds seconds no pull request's head is $pushed: read the open-pr workflow's log" ;;
  read)
    [ $# -eq 2 ] || usage
    tag=$1
    dir=$2
    case "$tag" in pr/*) ;; *) refuse "not a pr/ tag: $tag" ;; esac
    [ "$(git cat-file -t "refs/tags/$tag" 2>/dev/null)" = tag ] || refuse "$tag is not an annotated tag"
    mkdir -p "$dir" || exit 1
    git cat-file tag "refs/tags/$tag" | sed '1,/^$/d' > "$dir/message"
    sed -n 1p "$dir/message" > "$dir/title"
    [ -n "$(tr -d ' \t\r\n' < "$dir/title")" ] || refuse "the tag's message has no title line"
    [ -z "$(sed -n 2p "$dir/message")" ] || refuse "the tag's second line is not blank"
    sed '1,2d' "$dir/message" > "$dir/body"
    [ -s "$dir/body" ] || refuse "the tag's message has no body"
    echo "pr_tag: read $tag" ;;
  branch)
    [ $# -eq 1 ] || usage
    matches "$1" "$BRANCH_RE" || refuse "not a Conventional Branch of an allowed type: $1"
    git ls-remote --exit-code --heads origin "refs/heads/$1" >/dev/null 2>&1 || refuse "no branch $1 on origin"
    echo "pr_tag: branch $1" ;;
  gate)
    [ $# -eq 2 ] || usage
    gate_text "$1/title" "$1/body" "$2"
    echo "pr_tag: the title and body pass" ;;
  same)
    [ $# -eq 1 ] || usage
    for part in title body; do
      [ "$(chomped "$1/$part")" = "$(chomped "$1/$part.live")" ] ||
        refuse "the pull request's $part differs from the tag's"
    done
    echo "pr_tag: the pull request's title and body equal the tag's" ;;
  *) usage ;;
esac
