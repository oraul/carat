#!/bin/sh
# The rule gates of CLAUDE.md as checks: each gate compares the branch with
# BASE (origin/main) and prints "ok GATE" or "FAIL GATE: why" lines; the
# script exits 1 when any gate failed.
#
# Usage: sh tools/gates.sh GATE|GROUP [PR-BODY-FILE]
#   trailer    every branch commit ends with the co-author trailer, once, after
#              a blank line, and has no other trailer line
#   content    the added lines of every branch commit, against each parent,
#              and the commit messages hold no URL, no email address but the
#              trailer's, no session id, no model name, and no secret (a
#              private key, a platform token, a literal password or token);
#              (tools/scan_text.sh); no commit adds a .env or .env.* file
#              or a hook under .githooks but commit-msg and pre-commit
#   snapshots  a changed test/*.rb.expected has its test and equals the
#              runner's output (build/test/run_all, from make test-build)
#   docs       files added, moved, or removed under the source roots need the
#              code map; make targets or agent, command, or workflow files
#              added or removed need CLAUDE.md; the default configuration, the
#              compatibility table, make targets, or process files need README.md;
#              a spec change needs README.md and docs/architecture.md, and a
#              change to agents, workflows, commands, the Makefile, or the
#              gates, run state, or guard script needs CLAUDE.md, unless a
#              proposal in the diff holds "- DOC: unchanged, REASON"
#   scenarios  every ADDED or MODIFIED scenario of a delta spec in the diff is
#              named, in any case, by a file under test/ or tools/tools_test.sh
#   cases      a branch changing a code line (not blank, not a comment) of a
#              shell script under tools/ other than tools_test.sh adds or
#              changes an expect case in tools/tools_test.sh
#   attribution  .claude/settings.json sets Claude Code's attribution to
#              exactly the trailer on commits, no pull request text, and no
#              session link
#   security   the security review is recorded as pass at a commit whose
#              difference to HEAD touches only openspec/, docs/backlog.md,
#              docs/queue.md, docs/goals.md, and docs/metrics.tsv
#   stages     phase.check is at such a commit and every canonical stage
#              (STAGES, else the CHECK_STAGES line of the Makefile beside
#              this script) passed at exactly that commit
#   pushes     at most one push plus one per CI fix
#   passed     a clean tracked tree, phase.check and a pass of
#              review.quality, review.security, and review.bench, each at a
#              commit settled at the pushed head, HEAD
#   records    each review.KIND (and phase.check for check) of the run state
#              has the result and commit the workflow received, given as
#              RECORDS, which must hold security (refused when unset)
#   pr-body F  the pull request body F, a file and not a link (a link could
#              make it the run state), has the template's shape, no comment,
#              angle bracket, empty bullet, footer, URL, email, session id, or
#              model name, and a Testing line naming the security review
#   static     trailer, content, snapshots, docs, scenarios, cases, attribution
#              (make gates)
#   origin     no risky configuration key (core.hooksPath only as .githooks),
#              no hook but a sample in .git/hooks, none but commit-msg and
#              pre-commit in .githooks; an origin/ base equal to origin's
#   pre-push   origin, static, security, stages (tools/run_state.sh push)
#   backup     trailer, content (tools/run_state.sh backup, with BASE the
#              branch's base, so every commit the backup publishes)
#   merge F    origin, trailer, content, security, stages, passed, records,
#              pushes, pr-body F, then gated: the head they passed at
#              (the merger, from a worktree of origin/main at
#              tmp/.merge-gates, so the branch cannot have edited the gates)
#
# Environment: BASE (origin/main), CHANGE (the branch name after its type),
# RECORDS (the workflow's review and check results, "KIND:RESULT:COMMIT"
# words), TEST_BIN (build/test/run_all), STAGES (the Makefile's when unset).
set -u

# The gates' git reads no global or system configuration, which branch
# code run by the checks can write as well as .git/config: a global
# insteadOf would let a fake origin answer for the real one.
GIT_CONFIG_GLOBAL=/dev/null
GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM

here=$(cd "$(dirname "$0")" && pwd)
base=${BASE:-origin/main}
change=${CHANGE:-$(git rev-parse --abbrev-ref HEAD | sed 's|.*/||')}
TRAILER='Co-Authored-By: Claude <noreply@anthropic.com>'
TAB=$(printf '\t')
failed=0
gate=""

# The patterns of the content and pr-body gates, and report.
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
# Without rename detection, a file moved into openspec/ counts by its old
# path too.
settled_at() {
  hex "$1" || return 1
  rest=$(git diff --no-renames --name-only --end-of-options "$1" HEAD -- 2>/dev/null) || return 1
  [ -z "$(printf '%s\n' "$rest" | grep -v -E '^(openspec/|docs/(backlog|queue|goals)\.md$|docs/metrics\.tsv$|$)')" ]
}

require_base() {
  git rev-parse --verify -q "$base" >/dev/null || {
    echo "FAIL gates: the base $base does not exist; fetch it or set BASE"
    exit 1
  }
}

# The repository the gates read: branch code run by the checks can write
# .git/config and the ref origin/main, so no key of RISKY_CONFIG is set
# (core.hooksPath only as the absolute path of HOOKS_PATH in the main
# worktree, the parent of --git-common-dir, as make hooks sets it, since
# git reads a relative value from the top of each linked worktree), no
# hook other than a sample is in .git/hooks, none but HOOK_FILES_RE's in
# that HOOKS_PATH,
# and an origin/NAME base is origin's NAME: the default fetch refspec (a
# fetch restores the ref), an origin that is not a local repository (whose
# fake branch ls-remote would report), and the ref equal to the branch
# git ls-remote reports. A local base checks the configuration only.
gate_origin() {
  gate=origin
  remote=""
  start=$failed
  git_common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  tracked_hooks=${git_common:+${git_common%/*}/$HOOKS_PATH}
  keys=$(git config --local --name-only --list 2>/dev/null | grep -i -E "$RISKY_CONFIG" | sort -u)
  [ -z "$tracked_hooks" ] || [ "$(git config --local --get-all core.hooksPath 2>/dev/null)" != "$tracked_hooks" ] ||
    keys=$(printf '%s\n' "$keys" | grep -v -i -x 'core[.]hookspath')
  keys=$(printf '%s\n' "$keys" | grep . | tr '\n' ' ')
  [ -z "$keys" ] || bad "the repository configuration sets ${keys% }, which runs a command or redirects origin; remove it from .git/config (make hooks sets the one core.hooksPath allowed)"
  hooks=${git_common:+$git_common/hooks}
  planted=$([ -z "$hooks" ] || ! [ -d "$hooks" ] || ls -A "$hooks" | grep -v -E "[.]sample\$" | tr "\n" " "; true)
  [ -z "$planted" ] || bad "the hooks directory holds ${planted% }, which git runs on a checkout or a fetch; remove it"
  extra=$([ -z "$tracked_hooks" ] || ! [ -d "$tracked_hooks" ] || ls -A "$tracked_hooks" | grep -v -E "$HOOK_FILES_RE" | tr "\n" " "; true)
  [ -z "$extra" ] || bad "$HOOKS_PATH holds ${extra% }, which git would run on a checkout or a fetch once make hooks set core.hooksPath; only commit-msg and pre-commit belong there"
  case "$base" in
    origin/*)
      name=${base#origin/}
      fetch=$(git config --local --get-all remote.origin.fetch 2>/dev/null)
      [ "$fetch" = '+refs/heads/*:refs/remotes/origin/*' ] ||
        bad "remote.origin.fetch is \"$(printf '%s' "$fetch" | tr '\n' ' ')\", not the default refspec, so a fetch cannot restore $base"
      url=$(git config --local --get remote.origin.url 2>/dev/null)
      case "$url" in
        ""|/*|.*|file:*|ext::*|[A-Za-z]:*) bad "origin is \"$url\", a local repository or none, not the hosted one" ;;
        *) [ ! -d "$url" ] || bad "origin is \"$url\", a local repository, not the hosted one" ;;
      esac
      remote=$(git ls-remote origin "refs/heads/$name" 2>/dev/null | cut -f1)
      local_ref=$(git rev-parse --verify -q "$base^{commit}")
      if [ -z "$remote" ]; then
        bad "origin has no branch $name, or ls-remote failed"
      elif [ "$remote" != "$local_ref" ]; then
        bad "$base is $local_ref, but origin's $name is $remote: fetch, or the ref was rewritten"
      fi ;;
  esac
  [ $failed -ne $start ] || ok "the configuration sets no risky key and no hook${remote:+, and $base is origin's $name}"
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

# A push publishes every commit, not the net diff: the added lines of each
# commit against each of its parents (-m, so a merge's resolution too), and
# every added .env or .env.* file.
gate_content() {
  gate=content
  start=$failed
  report "$(git log -p -m -U0 --no-color --no-renames --no-ext-diff --no-textconv --format= "$base..HEAD" |
    sh "$here/scan_text.sh" --diff | sort -u)"
  # The names unquoted (-z), so a path git would quote matches too.
  added=$(git log -z -m --no-renames --diff-filter=A --name-only --format= "$base..HEAD" | tr '\000' '\n')
  envs=$(printf '%s\n' "$added" | grep -E '(^|/)\.env(\.[^/]*)?$' | sort -u)
  [ -z "$envs" ] || bad "an added .env file (secrets stay out of the repository):
$envs"
  hooks=$(printf '%s\n' "$added" | sed -n "s|^[.]${HOOKS_PATH#.}/||p" | grep -v -E "$HOOK_FILES_RE" | sort -u)
  [ -z "$hooks" ] || bad "an added hook under $HOOKS_PATH other than commit-msg and pre-commit, which git would run on a checkout or a fetch:
$hooks"
  for c in $(git rev-list "$base..HEAD"); do
    report "$(git log -1 --format=%B "$c" | sh "$here/scan_text.sh" --where "commit $(git rev-parse --short "$c")")"
  done
  [ $failed -ne $start ] || ok "every commit's added lines and files, and commit messages"
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
  # Doc prose a change leaves behind: a spec change touches README.md and
  # docs/architecture.md, a process change CLAUDE.md, or a proposal in the
  # diff says why one stays ("- README.md: unchanged, REASON").
  proposals=$(printf '%s\n' "$names" | grep -E '^openspec/changes/(archive/)?[^/]+/proposal\.md$')
  stays() {
    for p in $proposals; do
      git show "HEAD:$p" 2>/dev/null | grep -q -E "^- \`?$(printf '%s' "$1" | sed 's/\./\\./g')\`?: unchanged, [^ ]" && return 0
    done
    return 1
  }
  specs=$(printf '%s\n' "$names" | grep -E '^openspec/(specs/[^/]+/spec\.md|changes/.+/specs/.+\.md)$')
  if [ -n "$specs" ]; then
    for doc in README.md docs/architecture.md; do
      has "$doc" || stays "$doc" ||
        bad "a spec changed, but $doc did not; update it or say why in the proposal: - $doc: unchanged, REASON"
    done
  fi
  process_change=$(printf '%s\n' "$names" |
    grep -E '^(\.claude/(agents/|workflows/|commands/[^/]*$)|Makefile$|tools/(gates|run_state|agent_guard)\.sh$)')
  if [ -n "$process_change" ] && ! has CLAUDE.md && ! stays CLAUDE.md; then
    bad "a process file changed, but CLAUDE.md did not; update it or say why in the proposal: - CLAUDE.md: unchanged, REASON"
  fi
  [ $failed -ne $start ] || ok "map, CLAUDE.md, and README.md"
}

# Every ADDED or MODIFIED scenario of a delta spec in the diff, archived or
# not, is named (in any case) by a file under test/ or by tools/tools_test.sh
# at HEAD, in a label or a comment.
gate_scenarios() {
  gate=scenarios
  start=$failed
  count=0
  deltas=$(git diff --name-only "$base...HEAD" | grep -E '^openspec/changes/.+/specs/.+\.md$')
  for spec in $deltas; do
    found=$(git show "HEAD:$spec" 2>/dev/null | awk '
      /^## / { keep = ($0 ~ /^## (ADDED|MODIFIED) /) }
      keep && /^#### Scenario:/ { sub(/^#### Scenario:[ \t]*/, ""); sub(/[ \t]+$/, ""); print }')
    [ -n "$found" ] || continue
    while IFS= read -r scenario; do
      [ -n "$scenario" ] || continue
      count=$((count + 1))
      git grep -q -i -F -e "$scenario" HEAD -- test tools/tools_test.sh 2>/dev/null ||
        bad "$spec: scenario \"$scenario\" is named by no test under test/ or in tools/tools_test.sh"
    done <<EOF
$found
EOF
  done
  [ $failed -ne $start ] || ok "$count scenarios named by tests"
}

# The shell scripts under tools/ whose diff from the base changes a line that is
# not blank and not a comment, beside tools/tools_test.sh, need a case: the
# diff of tools/tools_test.sh adds an expect line. Per script, since the
# cases call the scripts by subcommand, not by function.
gate_cases() {
  gate=cases
  scripts=$(git diff --name-only "$base...HEAD" -- tools/ | grep -E "\.sh\$" | grep -v -x "tools/tools_test.sh" |
    while read -r path; do
      git diff -U0 "$base...HEAD" -- "$path" | grep -E "^[-+]" | grep -v -E "^(\+\+\+ (b/|/dev/null)|--- (a/|/dev/null))" |
        grep -q -v -E "^[-+][[:space:]]*(#.*)?$" && printf "%s " "$path"
    done)
  if [ -n "$scripts" ] && ! git diff -U0 "$base...HEAD" -- tools/tools_test.sh | grep -q -E "^\+[[:space:]]*expect "; then
    bad "${scripts% } changed code but tools/tools_test.sh adds or changes no expect case"
    return
  fi
  [ -n "$scripts" ] || scripts="no tool changed "
  ok "${scripts% }"
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

# The canonical stage list: STAGES, else the CHECK_STAGES line of the
# Makefile beside this script, read rather than run, so the merge's copy of
# main lists main's stages whatever the branch's Makefile says.
stage_list() {
  if [ -n "${STAGES:-}" ]; then echo "$STAGES"; return; fi
  sed -n 's/^CHECK_STAGES := //p' "$here/../Makefile"
}

# Every stage passed at the commit of phase.check, the check the workflow
# recorded, settled at HEAD: a stage record at another commit, which no
# check record backs, does not count.
gate_stages() {
  gate=stages
  start=$failed
  checked=$(state phase.check)
  if ! hex "$checked"; then
    bad "no check is recorded for $change (phase.check; tools/run_state.sh check $change)"
    return
  fi
  want=$(git rev-parse --verify -q --end-of-options "$checked^{commit}")
  settled_at "$checked" || bad "the check passed at $checked, but code changed since"
  stages=$(stage_list)
  [ -n "$stages" ] || bad "no stage list (STAGES, or CHECK_STAGES in $here/../Makefile)"
  for s in $stages; do
    record=$(state "stage.$s")
    at=$(echo "$record" | cut -d' ' -f3)
    case "$record" in
      "0 "*)
        if ! hex "$at" || [ "$(git rev-parse --verify -q --end-of-options "$at^{commit}")" != "$want" ]; then
          bad "$s passed at $at, not at the recorded check $checked"
        fi ;;
      "") bad "$s has not run (tools/run_state.sh check $change)" ;;
      *) bad "$s failed: $record" ;;
    esac
  done
  [ $failed -ne $start ] || ok "every stage passed at the recorded check $checked"
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
  dirty=$(git status --porcelain --untracked-files=no)
  [ -z "$dirty" ] || bad "tracked files differ from HEAD: $(printf '%s\n' "$dirty" | head -3 | tr '\n' ' ')"
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
    if [ "$kind" = check ]; then
      record=$(state phase.check)
      record=${record:+pass $record}
      name=phase.check
    else
      record=$(state "review.$kind")
      name=review.$kind
    fi
    at=$(git rev-parse --verify -q "$(echo "$record" | cut -d' ' -f2)^{commit}")
    if [ "${record%% *}" != "$result" ] || [ -z "$want" ] || [ "$at" != "$want" ]; then
      bad "$name is \"$record\", but the workflow received $result at ${rest#*:}"
    fi
  done
  set +f
  case " $RECORDS " in
    *" security:"*) ;;
    *) bad "no security record given (RECORDS); the merge needs the review the workflow received" ;;
  esac
  [ $failed -ne $start ] || ok "the run state holds the workflow's $(echo $RECORDS | wc -w | tr -d ' ') record(s)"
}

# Claude Code's attribution, set in .claude/settings.json at the top of the
# work tree: exactly the trailer on commits, no text added to a pull
# request, and no session link in either. Fixed-string matches: the file is
# small and hand-written, and the shell has no JSON tool.
gate_attribution() {
  gate=attribution
  start=$failed
  file="$(git rev-parse --show-toplevel)/.claude/settings.json"
  [ -f "$file" ] || { bad "no .claude/settings.json"; return; }
  for want in '"attribution": {' "\"commit\": \"$TRAILER\"" '"pr": ""' '"sessionUrl": false'; do
    grep -q -F -e "$want" "$file" || bad ".claude/settings.json lacks the line $want"
  done
  [ $failed -ne $start ] || ok "the trailer only, no pull request text, no session link"
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
  report "$(sh "$here/scan_text.sh" --where pr-body "$file")"
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
  scenarios) gate_scenarios ;;
  cases) gate_cases ;;
  attribution) gate_attribution ;;
  origin) gate_origin ;;
  security) gate_security ;;
  stages) gate_stages ;;
  pushes) gate_pushes ;;
  records) gate_records ;;
  pr-body) gate_pr_body "$body" ;;
  static) gate_trailer; gate_content; gate_snapshots; gate_docs; gate_scenarios; gate_cases; gate_attribution ;;
  pre-push) gate_origin; gate_trailer; gate_content; gate_snapshots; gate_docs; gate_scenarios; gate_cases; gate_security; gate_stages ;;
  backup) gate_trailer; gate_content ;;
  passed) gate_passed ;;
  merge)
    sh "$here/run_state.sh" gated "$change" clear >/dev/null || bad "the merge record gated could not be cleared"
    gate_origin; gate_trailer; gate_content; gate_security; gate_stages; gate_passed; gate_records; gate_pushes; gate_pr_body "$body"
    # The head every merge gate passed at, which the merge tool's hook in
    # tools/agent_guard.sh requires as the expected head.
    [ $failed -ne 0 ] || sh "$here/run_state.sh" gated "$change" pass >/dev/null || bad "the merge record gated could not be written" ;;
  *) echo "gates: unknown gate $target" >&2; exit 2 ;;
esac
exit $failed
