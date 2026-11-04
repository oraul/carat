#!/bin/sh
# The rule gates of CLAUDE.md as checks: each gate compares the branch with
# BASE (origin/main) and prints "ok GATE" or "FAIL GATE: why" lines; the
# script exits 1 when any gate failed.
#
# Usage: sh tools/gates.sh GATE|GROUP [PR-BODY-FILE]
#   trailer    every branch commit ends with the co-author trailer, once, after
#              a blank line, and has no other trailer line
#   content    the diff's added lines and the commit messages hold no URL, no
#              email address but the trailer's, no session id, no model name
#   snapshots  a changed test/*.rb.expected has its test and equals the
#              runner's output (build/test/run_all, from make test-build)
#   docs       files added, moved, or removed under the source roots need the
#              code map; make targets or agent, command, or workflow files
#              added or removed need CLAUDE.md; the default configuration, the
#              compatibility table, make targets, or process files need README.md
#   security   the security review is recorded as pass at a commit whose
#              difference to HEAD touches only openspec/, docs/backlog.md,
#              docs/queue.md, docs/goals.md, and docs/metrics.tsv
#   stages     every canonical stage passed at such a commit
#   pushes     at most one push plus one per CI fix
#   passed     phase.check and a pass of review.quality, review.security, and
#              review.bench, each at a commit settled at the pushed head, HEAD
#   records    each review.KIND of the run state has the result and commit
#              the workflow received, given as RECORDS (refused when unset)
#   pr-body F  the pull request body F, a file and not a link (a link could
#              make it the run state), has the template's shape, no comment,
#              angle bracket, empty bullet, footer, URL, email, session id, or
#              model name, and a Testing line naming the security review
#   static     trailer, content, snapshots, docs (make gates)
#   pre-push   static, security, stages (tools/run_state.sh push)
#   merge F    trailer, content, security, passed, records, pushes, pr-body F
#              (the merger)
#
# Environment: BASE (origin/main), CHANGE (the branch name after its type),
# RECORDS (the workflow's review results, "KIND:RESULT:COMMIT" words),
# TEST_BIN (build/test/run_all), STAGES (make -s stages when unset).
set -u

here=$(cd "$(dirname "$0")" && pwd)
base=${BASE:-origin/main}
change=${CHANGE:-$(git rev-parse --abbrev-ref HEAD | sed 's|.*/||')}
TRAILER='Co-Authored-By: Claude <noreply@anthropic.com>'
TAB=$(printf '\t')
failed=0
gate=""

# The patterns of the content and pr-body gates, and scan.
. "$here/rules.sh"

bad() {
  echo "FAIL $gate: $*"
  failed=1
}

ok() {
  echo "ok   $gate${1:+: $1}"
}

# True when VALUE is a commit hash of 7 to 40 hexadecimal digits on one
# line, so a value read from the run state never reaches git as an option.
hex() {
  case "$1" in *[[:cntrl:]]*|"") return 1 ;; esac
  printf '%s' "$1" | grep -q -x -E '[0-9a-f]{7,40}'
}

state() {
  sh "$here/run_state.sh" get "$change" "$1" 2>/dev/null
}

# True when the difference from COMMIT to HEAD touches only files no check
# reads but docs-lint: the OpenSpec change (archived after the checks), the
# backlog, and the planning records the package step writes (queue, goals,
# and metrics history), whose docs-lint the package step and CI run again.
settled_at() {
  hex "$1" || return 1
  rest=$(git diff --name-only --end-of-options "$1" HEAD -- 2>/dev/null) || return 1
  [ -z "$(printf '%s\n' "$rest" | grep -v -E '^(openspec/|docs/(backlog|queue|goals)\.md$|docs/metrics\.tsv$|$)')" ]
}

require_base() {
  git rev-parse --verify -q "$base" >/dev/null || {
    echo "FAIL gates: the base $base does not exist; fetch it or set BASE"
    exit 1
  }
}

gate_trailer() {
  gate=trailer
  start=$failed
  commits=$(git rev-list "$base..HEAD")
  for c in $commits; do
    short=$(git rev-parse --short "$c")
    msg=$(git log -1 --format=%B "$c" | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}')
    last=$(printf '%s\n' "$msg" | tail -1)
    before=$(printf '%s\n' "$msg" | tail -2 | head -1)
    [ "$last" = "$TRAILER" ] || bad "$short: the last line is not the co-author trailer"
    [ -z "$before" ] || bad "$short: no blank line before the trailer"
    n=$(printf '%s\n' "$msg" | grep -c -i '^co-authored-by:')
    [ "$n" -eq 1 ] || bad "$short: $n co-author lines; exactly one is allowed"
    others=$(printf '%s\n' "$msg" | grep -i -E '^[a-z][a-z-]*-(by|session):|generated with' |
      grep -v -i '^co-authored-by:')
    [ -z "$others" ] || bad "$short: another trailer: $others"
  done
  [ $failed -ne $start ] || ok "$(printf '%s\n' "$commits" | grep -c .) commit(s)"
}

gate_content() {
  gate=content
  start=$failed
  scan "$(git diff -U0 --no-color "$base...HEAD" |
    awk '/^\+\+\+ / { path = substr($0, 7); next } /^\+/ { print path "\t" substr($0, 2) }')"
  scan "$(for c in $(git rev-list "$base..HEAD"); do
    git log -1 --format=%B "$c" | sed "s/^/commit $(git rev-parse --short "$c")$TAB/"
  done)"
  [ $failed -ne $start ] || ok "diff and commit messages"
}

gate_snapshots() {
  gate=snapshots
  start=$failed
  changed=$(git diff --name-only --diff-filter=AMR "$base...HEAD" -- 'test/*.expected')
  [ -n "$changed" ] || { ok "no snapshot changed"; return; }
  tests=""
  for f in $changed; do
    rb=${f%.expected}
    if [ -f "$rb" ]; then tests="$tests $rb"; else bad "$f has no test $rb"; fi
  done
  runner=${TEST_BIN:-build/test/run_all}
  if [ ! -x "$runner" ]; then
    bad "$runner is missing; make test-build compiles the runner the snapshots must equal"
  elif [ -n "$tests" ]; then
    # shellcheck disable=SC2086
    sh "$here/run_tests.sh" "$runner" $tests > /dev/null 2>&1 ||
      bad "a changed snapshot differs from the runner's output; only make snapshots writes them:$tests"
  fi
  [ $failed -ne $start ] || ok "changed snapshots equal the runner's output"
}

targets() {
  grep -o -E '^## [a-z-]+:' | sort
}

gate_docs() {
  gate=docs
  start=$failed
  names=$(git diff --name-only "$base...HEAD")
  moved=$(git diff --name-status -M "$base...HEAD" |
    awk -F'\t' '$1 ~ /^[ADR]/ { print $2; if ($1 ~ /^R/) print $3 }')
  has() { printf '%s\n' "$names" | grep -q -x "$1"; }
  if printf '%s\n' "$moved" | grep -q -E '^(carat/|bin/|test/|bench/|tools/|carat\.rb$)' && ! has docs/codebase-map.md; then
    bad "files were added, moved, or removed under the source roots, but docs/codebase-map.md did not change"
  fi
  target_change=0
  if [ "$(git show "$base:Makefile" 2>/dev/null | targets)" != "$(targets < Makefile)" ]; then
    target_change=1
  fi
  process=$(printf '%s\n' "$moved" | grep -E '^\.claude/(agents/|commands/[^/]*$|workflows/)')
  if { [ $target_change -eq 1 ] || [ -n "$process" ]; } && ! has CLAUDE.md; then
    bad "make targets or agent, command, or workflow files were added or removed, but CLAUDE.md did not change"
  fi
  visible=$(printf '%s\n' "$names" |
    grep -E '^(config/default\.caratrc|docs/compatibility\.md|\.claude/agents/.*|\.claude/commands/[^/]*|\.claude/workflows/.*)$')
  if { [ $target_change -eq 1 ] || [ -n "$visible" ]; } && ! has README.md; then
    bad "a command, binding, option, make target, or the process changed, but README.md did not"
  fi
  [ $failed -ne $start ] || ok "map, CLAUDE.md, and README.md"
}

gate_security() {
  gate=security
  record=$(state review.security)
  at=$(echo "$record" | cut -d' ' -f2)
  case "$record" in
    "") bad "no security review is recorded for $change (tools/run_state.sh review $change security ...)" ;;
    pass\ *)
      if settled_at "$at"; then ok "pass at $at"
      else bad "the review passed at $at, but code changed since; review the committed diff again"; fi ;;
    *) bad "the security review did not pass: $record" ;;
  esac
}

gate_stages() {
  gate=stages
  start=$failed
  stages=${STAGES:-$(make -s --no-print-directory stages)}
  for s in $stages; do
    record=$(state "stage.$s")
    at=$(echo "$record" | cut -d' ' -f3)
    case "$record" in
      "0 "*) settled_at "$at" || bad "$s passed at $at, but code changed since" ;;
      "") bad "$s has not run (tools/run_state.sh check $change)" ;;
      *) bad "$s failed: $record" ;;
    esac
  done
  [ $failed -ne $start ] || ok "every stage passed"
}

gate_pushes() {
  gate=pushes
  pushes=$(state pushes)
  fixes=$(state ci_fixes)
  if [ "${pushes:-0}" -gt $((1 + ${fixes:-0})) ]; then
    bad "$pushes pushes for ${fixes:-0} CI fix(es); one is allowed, plus one per CI fix"
  else
    ok "${pushes:-0} push(es), ${fixes:-0} CI fix(es)"
  fi
}

# The pass records a merge needs, at the pushed head: phase.check and the
# quality, security, and bench reviews, each at a commit settled at HEAD,
# which must be the recorded push.
gate_passed() {
  gate=passed
  start=$failed
  pushed=$(state pushed)
  head=$(git rev-parse --verify -q HEAD)
  if ! hex "$pushed"; then
    bad "no push is recorded for $change (pushed is \"$pushed\")"
  elif [ "$(git rev-parse --verify -q --end-of-options "$pushed^{commit}")" != "$head" ]; then
    bad "HEAD $(git rev-parse --short=12 HEAD) is not the pushed head $pushed"
  fi
  for kind in check quality security bench; do
    if [ "$kind" = check ]; then
      at=$(state phase.check)
      record=${at:+pass $at}
    else
      record=$(state "review.$kind")
      at=$(echo "$record" | cut -d' ' -f2)
    fi
    case "$record" in
      "") bad "$kind has no pass record" ;;
      pass\ *) settled_at "$at" || bad "$kind passed at $at, but code changed since" ;;
      *) bad "$kind has no pass record: $record" ;;
    esac
  done
  [ $failed -ne $start ] || ok "check, quality, security, and bench passed at the pushed head $pushed"
}

# The run state's review records against the results the workflow received
# (RECORDS), so a record changed outside the workflow stops the merge.
gate_records() {
  gate=records
  start=$failed
  if [ -z "${RECORDS:-}" ]; then
    bad "no workflow records given (RECORDS); the workflow passes its review results"
    return
  fi
  set -f
  for item in $RECORDS; do
    if ! printf '%s' "$item" | grep -q -x -E '[a-z-]+:(pass|blocked):[0-9a-f]{7,40}'; then
      bad "not a KIND:RESULT:COMMIT record: $item"
      continue
    fi
    kind=${item%%:*}
    rest=${item#*:}
    result=${rest%%:*}
    want=$(git rev-parse --verify -q "${rest#*:}^{commit}")
    record=$(state "review.$kind")
    at=$(git rev-parse --verify -q "$(echo "$record" | cut -d' ' -f2)^{commit}")
    if [ "${record%% *}" != "$result" ] || [ -z "$want" ] || [ "$at" != "$want" ]; then
      bad "review.$kind is \"$record\", but the workflow received $result at ${rest#*:}"
    fi
  done
  set +f
  [ $failed -ne $start ] || ok "the run state holds the workflow's $(echo $RECORDS | wc -w | tr -d ' ') review(s)"
}

gate_pr_body() {
  gate=pr-body
  start=$failed
  file=$1
  [ ! -L "$file" ] || { bad "the body file $file is a link"; return; }
  [ -f "$file" ] || { bad "no body file $file"; return; }
  [ "$(sed -n 1p "$file")" = "## Summary" ] || bad "the body does not start with ## Summary"
  headings=$(grep '^## ' "$file" | tr '\n' '|')
  [ "$headings" = "## Summary|## Changes|## Testing|## Notes|" ] ||
    bad "the sections are not exactly Summary, Changes, Testing, Notes: $headings"
  [ "$(grep -c -x -e '---' "$file")" -eq 3 ] || bad "not exactly three --- separators"
  hits=$(grep -n -e '<' -e '>' "$file")
  [ -z "$hits" ] || bad "a comment or angle bracket:
$hits"
  hits=$(grep -n -E '^- *$' "$file")
  [ -z "$hits" ] || bad "an empty bullet: $hits"
  hits=$(grep -n -i -E 'generated with|co-authored-by' "$file")
  [ -z "$hits" ] || bad "a footer or attribution line: $hits"
  sed -n '/^## Testing/,/^## Notes/p' "$file" | grep -q -i 'security review' ||
    bad "the Testing section does not report the security review"
  address=${TRAILER#*<}
  hits=$(grep -n -F "${address%>}" "$file")
  [ -z "$hits" ] || bad "an email address: $hits"
  scan "$(sed "s/^/pr-body$TAB/" "$file")"
  [ $failed -ne $start ] || ok "$file"
}

[ $# -ge 1 ] || { sed -n '/^# Usage:/,/^# Environment:/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
target=$1
body=${2:-}
require_base
case "$target" in
  trailer) gate_trailer ;;
  content) gate_content ;;
  snapshots) gate_snapshots ;;
  docs) gate_docs ;;
  security) gate_security ;;
  stages) gate_stages ;;
  pushes) gate_pushes ;;
  records) gate_records ;;
  pr-body) gate_pr_body "$body" ;;
  static) gate_trailer; gate_content; gate_snapshots; gate_docs ;;
  pre-push) gate_trailer; gate_content; gate_snapshots; gate_docs; gate_security; gate_stages ;;
  passed) gate_passed ;;
  merge) gate_trailer; gate_content; gate_security; gate_passed; gate_records; gate_pushes; gate_pr_body "$body" ;;
  *) echo "gates: unknown gate $target" >&2; exit 2 ;;
esac
exit $failed
