#!/bin/sh
# The pull request opened on the branch push. A pull request created or
# edited over GitHub's API from a cloud session reaches GitHub with a
# footer the session's network layer appends, and its git proxy refuses a
# tag push and a ref delete, while a branch push arrives unchanged; so no
# session creates or edits a pull request with a tool or GitHub's API.
# The package step, and a body fix, commits the title and the gated body
# as pr.md in the archived OpenSpec change and pushes the branch; the
# push runs .github/workflows/branch-push.yml, whose completion runs
# .github/workflows/open-pr.yml from main, which opens the pull request
# from that file, or sets an open one's title and body to it, with main's
# copy of this script, never the branch's.
#
# Usage:
#   sh tools/open_pr.sh write CHANGE TITLE   the contributor, before its
#       push: gates TITLE and build/pipeline/CHANGE.body.md and writes the
#       title, a blank line, and the body to pr.md in the change's one
#       archive directory, openspec/changes/archive/DATE-CHANGE/
#   sh tools/open_pr.sh wait CHANGE [SECONDS]   the contributor: waits, at
#       most SECONDS (1 to 540, default 540), until a pull request's head
#       is the pushed head, and records its number (tools/run_state.sh set
#       CHANGE pr N): the one such pull request, or the one recorded at an
#       earlier push among several; refuses several otherwise, since a
#       fork's pull request can share the commit; the number taken is read
#       back with gh and recorded only when its head is the run state's
#       repo and branch (a fork's is refused, an unreadable one waited
#       for); the merger checks the head repository again before the merge
#   sh tools/open_pr.sh message CHANGE SHA   the merger, before its squash
#       merge: prints the squash message, the body of the change's one
#       archived pr.md at SHA (40 digits; the archive's own entries, as the
#       merge tool's guard picks them), its trailing blank lines dropped,
#       one blank line, and the co-author trailer, every other byte kept,
#       the four sections' headings and dividers included
#   sh tools/open_pr.sh read BRANCH DIR      the workflow: refuses a branch
#       of no allowed type; fetches the branch's tip and reads the one
#       pr.md of an archived change that HEAD's tree (main's) lacks into
#       DIR/title and DIR/body; leaves DIR empty, with nothing to open,
#       when the branch is gone or holds no new pr.md
#   sh tools/open_pr.sh gate DIR TOOLS       the workflow: TOOLS/gates.sh
#       pr-body on DIR/body and TOOLS/scan_text.sh on DIR/title, TOOLS
#       the tools directory of main's checkout
#   sh tools/open_pr.sh rule                 the workflow, with GH_TOKEN
#       and GH_REPO, before the token step: refuses unless the environment
#       AI admits exactly one deployment ref, the branch main, the setting
#       that keeps PR_TOKEN from any branch's own workflow
#   sh tools/open_pr.sh open BRANCH DIR      the workflow, with GH_TOKEN
#       and GH_REPO: opens the pull request from DIR/title and DIR/body
#       with gh, or, when the branch has one open in GH_REPO, sets its
#       title and body to them where either differs (more than one open is
#       refused); a fork's pull request on a branch of the same name is
#       neither counted nor edited; reads the text back by number and
#       fails unless both equal the files but for trailing newlines
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
# The one trailer CLAUDE.md allows, the squash message's last line, as the
# merge tool's guard requires it (SQUASH_TRAILER in tools/agent_guard.sh).
SQUASH_TRAILER='Co-Authored-By: Claude <noreply@anthropic.com>'

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

# live_text NUMBER DIR: the pull request's title and body, as gh reads
# them back, into DIR/title.live and DIR/body.live.
live_text() {
  gh pr view "$1" --repo "$GH_REPO" --json title --jq .title > "$2/title.live" || refuse "cannot read the title back"
  gh pr view "$1" --repo "$GH_REPO" --json body --jq .body > "$2/body.live" || refuse "cannot read the body back"
}

# head_owned NUMBER REPO BRANCH: whether pull request NUMBER of REPO is
# from BRANCH of REPO itself, as gh reads it: 0 yes, 1 no (a fork's or
# another branch's), 2 unread (no gh, a failure, or an answer of no shape).
head_owned() {
  [ -n "$2" ] && [ -n "$3" ] || return 2
  answer=$(gh pr view "$1" --repo "$2" --json isCrossRepository,headRefName --jq '"\(.isCrossRepository) \(.headRefName)"' 2>/dev/null) || return 2
  case $answer in
    "false $3") return 0 ;;
    "true "*|"false "*) return 1 ;;
  esac
  return 2
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
    # Git shows no pull request's head repository, so a fork's pull request
    # on the pushed commit looks like ours: one number is taken, or the one
    # the run state recorded at an earlier push; more are refused. The
    # number taken is then read back with gh (head_owned): it is recorded
    # only when its head is this repository's and the change's branch; a
    # fork's is refused, one gh cannot read yet is waited for. The merger
    # reads the head repository again before the merge.
    recorded=$(state pr)
    repo=$(state repo)
    branch=$(state branch)
    unread=""
    waited=0
    while :; do
      refs=$(git ls-remote origin 'refs/pull/*/head') || refs=""
      numbers=$(printf '%s\n' "$refs" | awk -v sha="$pushed" '$1 == sha && $2 ~ /^refs\/pull\/[0-9]+\/head$/ { split($2, p, "/"); print p[3] + 0 }' | sort -n -u)
      number=""
      unread=""
      if [ -n "$numbers" ] && [ "$(printf '%s\n' "$numbers" | wc -l)" -eq 1 ]; then
        number=$numbers
      elif [ -n "$numbers" ]; then
        if matches "$recorded" '[0-9]+' && printf '%s\n' "$numbers" | grep -q -x -F "$recorded"; then
          number=$recorded
        else
          refuse "more than one pull request's head is $pushed ($(printf '%s\n' "$numbers" | tr '\n' ' ' | sed 's/ $//')): a fork's can share the commit, so none is recorded; read the open-pr workflow's log for the number"
        fi
      fi
      if [ -n "$number" ]; then
        head_owned "$number" "$repo" "$branch"
        case $? in
          0)
            sh "$here/run_state.sh" set "$change" pr "$number" >/dev/null || refuse "the run state did not take pr $number"
            echo "open_pr: pull request $number at $pushed"
            exit 0 ;;
          1) refuse "pull request $number has the pushed head but not from $branch of $repo (a fork's, or another branch): none is recorded" ;;
          *) unread=$number ;;
        esac
      fi
      [ "$waited" -lt "$seconds" ] || break
      sleep "$step" || refuse "sleep failed"
      waited=$((waited + step))
    done
    [ -z "$unread" ] || refuse "pull request $unread has the pushed head, but its head repository could not be read with gh after $seconds seconds: none is recorded"
    refuse "after $seconds seconds no pull request's head is $pushed: read the open-pr workflow's log, never open the pull request another way" ;;
  message)
    [ $# -eq 2 ] || usage
    change=$1
    sha=$2
    matches "$change" "$CHANGE_RE" || refuse "not a change name: $change"
    matches "$sha" '[0-9a-f]{40}' || refuse "not a full commit sha (40 digits): $sha"
    # The archive's own entries at the pushed head, not the worktree's.
    found=$(git ls-tree --name-only "$sha" -- openspec/changes/archive/ 2>/dev/null |
      grep -x -E "openspec/changes/archive/[0-9]{4}-[0-9]{2}-[0-9]{2}-$change" | while IFS= read -r dir; do
        [ "$(git cat-file -t "$sha:$dir/pr.md" 2>/dev/null)" != blob ] || printf '%s\n' "$dir/pr.md"
      done)
    [ -n "$found" ] && [ "$(printf '%s\n' "$found" | wc -l)" -eq 1 ] || refuse "$sha holds no one archived pr.md of $change"
    text=$(git show "$sha:$found") || refuse "cannot read $found at $sha"
    # Each command substitution drops every trailing newline, so the
    # body's trailing blank lines are gone; every other byte is kept.
    body=$(printf '%s\n' "$text" | LC_ALL=C sed '1,2d')
    [ -n "$(printf '%s' "$body" | tr -d ' \t\r\n')" ] || refuse "$found has no body"
    printf '%s\n\n%s\n' "$body" "$SQUASH_TRAILER" ;;
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
  rule)
    [ $# -eq 0 ] || usage
    [ -n "${GH_REPO:-}" ] || refuse "GH_REPO is not set"
    # The environment's secrets reach a job only on a deployment ref its
    # rule admits; with every branch admitted, a branch's own workflow
    # naming AI reads PR_TOKEN. null is the rule admitting every branch.
    policy=$(gh api "repos/$GH_REPO/environments/AI" --jq '.deployment_branch_policy | if . == null then "every branch" else "\(.protected_branches) \(.custom_branch_policies)" end') ||
      refuse "cannot read the environment AI of $GH_REPO"
    refs=""
    if [ "$policy" = "false true" ]; then
      refs=$(gh api "repos/$GH_REPO/environments/AI/deployment-branch-policies" --jq '.branch_policies[] | "\(.type // "branch") \(.name)"') ||
        refuse "cannot read the deployment refs of the environment AI"
    fi
    if [ "$policy" != "false true" ] || [ "$refs" != "branch main" ]; then
      case "$policy" in
        "every branch") admitted="every branch" ;;
        "false true") admitted=$(printf '%s' "${refs:-no ref}" | tr '\n' ';' | sed 's/;/; /g') ;;
        "true "*) admitted="the protected branches" ;;
        *) admitted="an unknown rule ($policy)" ;;
      esac
      refuse "the environment AI admits $admitted as deployment refs, not the branch main alone: set its deployment branches to the selected branch main, or any branch's own workflow can read PR_TOKEN"
    fi
    echo "open_pr: the environment AI admits the branch main alone" ;;
  open)
    [ $# -eq 2 ] || usage
    branch=$1
    dir=$2
    matches "$branch" "$BRANCH_RE" || refuse "not a Conventional Branch of an allowed type: $branch"
    [ -n "${GH_REPO:-}" ] || refuse "GH_REPO is not set"
    # --head matches a head branch's name in any repository, so a fork's
    # pull request on a branch of the same name is listed too: only those
    # of this repository count, and each is named by its number, never by
    # the branch, which gh resolves to any pull request of that head name.
    listed=$(gh pr list --repo "$GH_REPO" --head "$branch" --state open --json number,isCrossRepository --jq '.[] | "\(.number) \(.isCrossRepository)"') ||
      refuse "cannot list the pull requests of $branch"
    numbers=$(printf '%s\n' "$listed" | awk '
      $0 == "" { next }
      $0 !~ /^[0-9]+ (true|false)$/ { bad = 1; exit }
      $2 == "false" { print $1 }
      END { exit bad }') ||
      refuse "gh pr list printed no number and repository flag: $listed"
    count=$(printf '%s' "$numbers" | grep -c '^' || true)
    [ "$count" -le 1 ] || refuse "$branch has $count open pull requests in $GH_REPO: close all but one"
    if [ "$count" -eq 1 ]; then
      number=$numbers
      live_text "$number" "$dir"
      if [ "$(chomped "$dir/title")" = "$(chomped "$dir/title.live")" ] && [ "$(chomped "$dir/body")" = "$(chomped "$dir/body.live")" ]; then
        echo "open_pr: the open pull request $number of $branch already holds pr.md's title and body"
        exit 0
      fi
      gh pr edit "$number" --repo "$GH_REPO" --title "$(cat "$dir/title")" --body-file "$dir/body" ||
        refuse "gh pr edit failed"
      done_text="set the title and body of the open pull request $number of $branch"
    else
      created=$(gh pr create --repo "$GH_REPO" --base main --head "$branch" --title "$(cat "$dir/title")" --body-file "$dir/body") ||
        refuse "gh pr create failed"
      # gh prints the new pull request's address, its number last.
      number=$(printf '%s\n' "$created" | sed -n '$s|.*/pull/\([0-9][0-9]*\)$|\1|p')
      matches "$number" '[0-9]+' || refuse "gh pr create printed no pull request number: $created"
      done_text="opened the pull request $number of $branch"
    fi
    live_text "$number" "$dir"
    for part in title body; do
      [ "$(chomped "$dir/$part")" = "$(chomped "$dir/$part.live")" ] ||
        refuse "the pull request's $part differs from pr.md's"
    done
    echo "open_pr: $done_text, its title and body equal to pr.md's" ;;
  *) usage ;;
esac
