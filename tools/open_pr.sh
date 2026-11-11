#!/bin/sh
# The pull request opened on the branch push. A pull request created or
# edited over GitHub's API from a cloud session reaches GitHub with a
# footer the session's network layer appends, and its git proxy refuses a
# tag push and a ref delete, while a branch push arrives unchanged; so the
# delivery never creates a pull request from its session. The package
# step commits the title and the gated body as pr.md in the archived
# OpenSpec change and pushes the branch; the push runs
# .github/workflows/branch-push.yml, whose completion runs
# .github/workflows/open-pr.yml from main, which opens the pull request
# from that file with main's copy of this script, never the branch's.
#
# Usage:
#   sh tools/open_pr.sh write CHANGE TITLE   the contributor, before its
#       push: gates TITLE and build/pipeline/CHANGE.body.md and writes the
#       title, a blank line, and the body to pr.md in the change's one
#       archive directory, openspec/changes/archive/DATE-CHANGE/
#   sh tools/open_pr.sh wait CHANGE [SECONDS]   the contributor: waits, at
#       most SECONDS (1 to 540, default 540), until a pull request's head
#       is the pushed head, and records its number (tools/run_state.sh set
#       CHANGE pr N)
#   sh tools/open_pr.sh read BRANCH DIR      the workflow: refuses a branch
#       of no allowed type; fetches the branch's tip and reads the one
#       pr.md of an archived change that HEAD's tree (main's) lacks into
#       DIR/title and DIR/body; leaves DIR empty, with nothing to open,
#       when the branch is gone or holds no new pr.md
#   sh tools/open_pr.sh gate DIR TOOLS       the workflow: TOOLS/gates.sh
#       pr-body on DIR/body and TOOLS/scan_text.sh on DIR/title, TOOLS
#       the tools directory of main's checkout
#   sh tools/open_pr.sh open BRANCH DIR      the workflow, with GH_TOKEN
#       and GH_REPO: leaves a branch with an open pull request alone;
#       otherwise opens it from DIR/title and DIR/body with gh, reads it
#       back, and fails unless both equal the files but for trailing
#       newlines
#
# Environment: WAIT_STEP, the seconds between two reads of origin (10).
# Exit status: 0 done or nothing to do, 1 refused or not equal, 2 a usage
# error.
set -u

here=$(cd "$(dirname "$0")" && pwd)
# The branch types of CLAUDE.md, the guard's pattern.
BRANCH_RE='^(feature|bugfix|hotfix|release|chore)/[a-z0-9][a-z0-9-]*$'
CHANGE_RE='^[a-z0-9][a-z0-9-]*$'
PR_MD_RE='^openspec/changes/archive/[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9][a-z0-9-]*/pr[.]md$'
MAX_WAIT=540

usage() {
  sed -n '/^# Usage:/,/^# Exit status:/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

refuse() {
  echo "open_pr: refused: $*" >&2
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
  write)
    [ $# -eq 2 ] || usage
    change=$1
    title=$2
    matches "$change" "$CHANGE_RE" || refuse "not a change name: $change"
    case "$title" in *"
"*) refuse "the title is more than one line" ;; esac
    dirs=$(ls -d openspec/changes/archive/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-"$change" 2>/dev/null)
    [ -n "$dirs" ] || refuse "no archived change $change: archive it first"
    [ "$(printf '%s\n' "$dirs" | wc -l)" -eq 1 ] || refuse "more than one archive of $change"
    body=build/pipeline/$change.body.md
    [ -f "$body" ] || refuse "no body file $body"
    work=$(mktemp -d) || exit 1
    trap 'rm -rf "$work"' EXIT
    printf '%s\n' "$title" > "$work/title"
    gate_text "$work/title" "$body" "$here"
    { printf '%s\n\n' "$title"; cat "$body"; } > "$dirs/pr.md" || refuse "cannot write $dirs/pr.md"
    echo "open_pr: wrote $dirs/pr.md; commit it, then push with tools/run_state.sh push" ;;
  wait)
    [ $# -ge 1 ] && [ $# -le 2 ] || usage
    change=$1
    seconds=${2:-$MAX_WAIT}
    matches "$change" "$CHANGE_RE" || refuse "not a change name: $change"
    case "$seconds" in ""|*[!0-9]*|????*) refuse "wait 1 to $MAX_WAIT seconds: $seconds" ;; esac
    [ "$seconds" -ge 1 ] && [ "$seconds" -le $MAX_WAIT ] || refuse "wait 1 to $MAX_WAIT seconds: $seconds"
    step=${WAIT_STEP:-10}
    matches "$step" '[0-9]{1,3}' || refuse "WAIT_STEP is not a number of seconds: $step"
    pushed=$(state pushed)
    matches "$pushed" '[0-9a-f]{40}' || refuse "no pushed head in the run state"
    waited=0
    while :; do
      refs=$(git ls-remote origin 'refs/pull/*/head') || refs=""
      number=$(printf '%s\n' "$refs" | awk -v sha="$pushed" '$1 == sha && $2 ~ /^refs\/pull\/[0-9]+\/head$/ { split($2, p, "/"); if (p[3] + 0 > n) n = p[3] + 0 } END { if (n) print n }')
      if [ -n "$number" ]; then
        sh "$here/run_state.sh" set "$change" pr "$number" >/dev/null || refuse "the run state did not take pr $number"
        echo "open_pr: pull request $number at $pushed"
        exit 0
      fi
      [ "$waited" -lt "$seconds" ] || break
      sleep "$step" || refuse "sleep failed"
      waited=$((waited + step))
    done
    refuse "after $seconds seconds no pull request's head is $pushed: read the open-pr workflow's log, never open the pull request another way" ;;
  read)
    [ $# -eq 2 ] || usage
    branch=$1
    dir=$2
    matches "$branch" "$BRANCH_RE" || refuse "not a Conventional Branch of an allowed type: $branch"
    mkdir -p "$dir" || exit 1
    if ! git ls-remote --exit-code --heads origin "refs/heads/$branch" >/dev/null 2>&1; then
      echo "open_pr: no branch $branch on origin: nothing to open"
      exit 0
    fi
    ref=refs/remotes/origin/$branch
    git fetch -q --depth=1 --no-tags origin "+refs/heads/$branch:$ref" || refuse "cannot fetch $branch"
    # A pr.md main's tree also holds is an older change's record.
    found=$(git ls-tree -r --name-only "$ref" -- openspec/changes/archive |
      grep -E "$PR_MD_RE" | while IFS= read -r path; do
        git cat-file -e "HEAD:$path" 2>/dev/null || printf '%s\n' "$path"
      done)
    if [ -z "$found" ]; then
      echo "open_pr: $branch holds no new pr.md: nothing to open"
      exit 0
    fi
    [ "$(printf '%s\n' "$found" | wc -l)" -eq 1 ] || refuse "$branch holds more than one new pr.md:
$found"
    git show "$ref:$found" > "$dir/message" || refuse "cannot read $found"
    sed -n 1p "$dir/message" > "$dir/title.read"
    [ -n "$(tr -d ' \t\r\n' < "$dir/title.read")" ] || refuse "$found has no title line"
    [ -z "$(sed -n 2p "$dir/message")" ] || refuse "the second line of $found is not blank"
    sed '1,2d' "$dir/message" > "$dir/body"
    [ -s "$dir/body" ] || refuse "$found has no body"
    # The title last: its presence tells the workflow there is one to open.
    mv "$dir/title.read" "$dir/title"
    echo "open_pr: read $found from $branch" ;;
  gate)
    [ $# -eq 2 ] || usage
    gate_text "$1/title" "$1/body" "$2"
    echo "open_pr: the title and body pass" ;;
  open)
    [ $# -eq 2 ] || usage
    branch=$1
    dir=$2
    matches "$branch" "$BRANCH_RE" || refuse "not a Conventional Branch of an allowed type: $branch"
    [ -n "${GH_REPO:-}" ] || refuse "GH_REPO is not set"
    count=$(gh pr list --repo "$GH_REPO" --head "$branch" --state open --json number --jq length) ||
      refuse "cannot list the pull requests of $branch"
    matches "$count" '[0-9]+' || refuse "gh pr list printed no count: $count"
    if [ "$count" -gt 0 ]; then
      echo "open_pr: $branch already has an open pull request: nothing to open"
      exit 0
    fi
    gh pr create --repo "$GH_REPO" --base main --head "$branch" --title "$(cat "$dir/title")" --body-file "$dir/body" ||
      refuse "gh pr create failed"
    gh pr view "$branch" --repo "$GH_REPO" --json title --jq .title > "$dir/title.live" || refuse "cannot read the title back"
    gh pr view "$branch" --repo "$GH_REPO" --json body --jq .body > "$dir/body.live" || refuse "cannot read the body back"
    for part in title body; do
      [ "$(chomped "$dir/$part")" = "$(chomped "$dir/$part.live")" ] ||
        refuse "the pull request's $part differs from pr.md's"
    done
    echo "open_pr: opened the pull request of $branch, its title and body equal to pr.md's" ;;
  *) usage ;;
esac
