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
#   findings   findings are append-only: every `### ` heading under
#              docs/findings/ at BASE or at an earlier commit of the branch
#              is still there at HEAD; only a branch appending groom's
#              sprint row to docs/sprints.tsv (groom_row: the delivery
#              whose groom carried the sprint plan) may remove entries,
#              each one filed under docs/backlog/ or removed by the plan's
#              groom.txt (a security entry only listed or fixed)
#   attribution  .claude/settings.json sets Claude Code's attribution to
#              exactly the trailer on commits, no pull request text, and no
#              session link
#   security   the security review is recorded as pass at a commit whose
#              difference to HEAD touches only the records-only paths of
#              tools/rules.sh: openspec/, docs/backlog/, docs/findings/,
#              the lane queues docs/queue-feature.md and
#              docs/queue-backlog.md, the lane histories
#              docs/metrics-feature.tsv and docs/metrics-backlog.tsv, and
#              docs/sprints.tsv, but never docs/goals.md, which agents act
#              on (INSTRUCTION_RECORDS_RE)
#   stages     phase.check is at such a commit and every canonical stage
#              (STAGES, else the CHECK_STAGES line of the Makefile beside
#              this script) passed at exactly that commit
#   pushes     at most one push plus one per CI fix and one review fix
#   passed     a clean tracked tree, phase.check and a pass of
#              review.security and review.bench, each at a commit settled
#              at the pushed head, HEAD (no delivery reviews quality: the
#              contributor's own step does)
#   records    each review.KIND (and phase.check for check) of the run state
#              has the result and commit the workflow received, given as
#              RECORDS, which must hold security (refused when unset)
#   pr-body F  the pull request body F, a file and not a link (a link could
#              make it the run state), has the template's shape, no comment,
#              angle bracket, empty bullet, footer, URL, email, session id, or
#              model name, and a Testing line naming the security review
#   static     trailer, content, snapshots, docs, scenarios, cases, findings,
#              attribution
#              (make gates)
#   origin     no risky configuration key (core.hooksPath among them), no
#              hook but a sample in .git/hooks; an origin/ base equal to origin's
#   pre-push   origin, static, security, stages (tools/run_state.sh push)
#   merge F    origin, trailer, content, findings, security, stages, passed,
#              records, pushes, pr-body F, then gated: the head they passed at
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

# The records-only paths agents act on as instructions (docs/goals.md: the
# tiers, the budgets, the critical-change routing), which settled_at never
# settles a pass across although RECORDS_RE lists them, so CI's and the
# checker's scopes still read them as documentation. tools/run_state.sh
# keeps the same line (tools/tools_test.sh compares them).
INSTRUCTION_RECORDS_RE='docs/goals\.md$'

# What makes an entry a security entry, the copy of tools/run_state.sh's
# SECURITY_MARK (tools/tools_test.sh compares the lines): the findings gate
# lets a carrier's removed security entry leave only by listed or fixed.
SECURITY_SEVERITY='(critical|high|medium|low|disputed)s?'
SECURITY_MARK="(^|[^a-z])security[^a-z](.*[^a-z])?$SECURITY_SEVERITY([^a-z]|\$)|(^|[^a-z])$SECURITY_SEVERITY[^a-z](.*[^a-z])?security([^a-z]|\$)|(^|[^a-z])(critical|high|medium|low) \\([0-9]+\\)"

# True when the difference from COMMIT to HEAD touches only files no check
# reads but docs-lint: the records-only paths of tools/rules.sh
# (RECORDS_RE): the OpenSpec change (archived after the checks), the
# backlog and the findings files, and the planning records the package
# step writes (the lane queues, goals, the lane metrics histories, and
# the sprint row groom appends to docs/sprints.tsv), whose docs-lint the
# package step and CI run again. docs/sprints.tsv counts only by groom's
# one appended row (appended_rows, groom_row): an edited, forged, or second
# row moves the sprint base, which the sprint-end security review starts
# from. An instruction record (INSTRUCTION_RECORDS_RE) never counts:
# agents act on its rules, so a pass before an edit of it is stale. The
# security, stages, and passed gates share it. Without rename
# detection, a file moved into openspec/ counts by its old path too.
# The three helpers set only names of their own (settled_, row_, rows_),
# since a gate calls them between setting and reading its own (want).
settled_at() {
  hex "$1" || return 1
  settled_rest=$(git diff --no-renames --name-only --end-of-options "$1" HEAD -- 2>/dev/null) || return 1
  [ -z "$(printf '%s\n' "$settled_rest" | grep -v -E "^($RECORDS_RE|\$)")" ] || return 1
  ! printf '%s\n' "$settled_rest" | grep -q -E "^($INSTRUCTION_RECORDS_RE)" || return 1
  ! printf '%s\n' "$settled_rest" | grep -q -x -F docs/sprints.tsv || { appended_rows "$1" docs/sprints.tsv && groom_row "$1"; }
}

# True when the bytes HEAD appended to docs/sprints.tsv since COMMIT are
# exactly the one row groom appends for the sprint the plan's marker names
# (tools/run_state.sh sprint-row COMMIT committed, the copy beside this
# script, which reads the history rows from HEAD's committed files, never
# the working tree), so no forged row, second row, or extra line break moves
# the sprint base, and the two lane histories only grew since COMMIT. Both
# sides are compared as files, byte for byte, since a
# command substitution would drop trailing line breaks (sprint-guard-lows).
groom_row() {
  # The history rows the sprint row is computed from only grew since
  # COMMIT: no earlier row edited after the review.
  for row_file in docs/metrics-feature.tsv docs/metrics-backlog.tsv; do
    appended_rows "$1" "$row_file" || return 1
  done
  row_size=$(git cat-file -s "$1:docs/sprints.tsv" 2>/dev/null) || row_size=0
  row_have=$(mktemp "${TMPDIR:-/tmp}/carat-groom-have.XXXXXX") || return 1
  row_need=$(mktemp "${TMPDIR:-/tmp}/carat-groom-need.XXXXXX") || { rm -f "$row_have"; return 1; }
  git cat-file blob HEAD:docs/sprints.tsv 2>/dev/null | tail -c +$((row_size + 1)) > "$row_have"
  row_ok=1
  sh "$here/run_state.sh" sprint-row "$1" committed > "$row_need" 2>/dev/null || row_ok=
  [ -z "$row_ok" ] || [ -s "$row_need" ] || row_ok=
  [ -z "$row_ok" ] || cmp -s "$row_have" "$row_need" || row_ok=
  rm -f "$row_have" "$row_need"
  [ -n "$row_ok" ]
}

# True when FILE at HEAD is FILE at COMMIT with lines appended: absent at
# COMMIT, or empty or ending in a line break there, and its bytes at COMMIT
# the first bytes at HEAD.
appended_rows() {
  rows_before=$(git rev-parse -q --verify --end-of-options "$1:$2" 2>/dev/null) || return 0
  rows_size=$(git cat-file -s "$rows_before") || return 1
  [ "$rows_size" -eq 0 ] && return 0
  [ -z "$(git cat-file blob "$rows_before" | tail -c 1)" ] || return 1
  rows_prefix=$(git cat-file blob "HEAD:$2" 2>/dev/null | head -c "$rows_size" | git hash-object --stdin) || return 1
  [ "$rows_prefix" = "$rows_before" ]
}

require_base() {
  git rev-parse --verify -q "$base" >/dev/null || {
    echo "FAIL gates: the base $base does not exist; fetch it or set BASE"
    exit 1
  }
}

# The repository the gates read: branch code run by the checks can write
# .git/config and the ref origin/main, so no key of RISKY_CONFIG is set
# (core.hooksPath among them, so git runs no hook the branch tracks), no
# hook other than a sample is in the common git directory's hooks folder,
# and an origin/NAME base is origin's NAME: the default fetch refspec (a
# fetch restores the ref), an origin that is not a local repository (whose
# fake branch ls-remote would report), and the ref equal to the branch
# git ls-remote reports. A local base checks the configuration only.
gate_origin() {
  gate=origin
  remote=""
  start=$failed
  git_common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  keys=$(git config --local --name-only --list 2>/dev/null | grep -i -E "$RISKY_CONFIG" | sort -u | tr '\n' ' ')
  [ -z "$keys" ] || bad "the repository configuration sets ${keys% }, which runs a command or redirects origin; remove it from .git/config"
  hooks=${git_common:+$git_common/hooks}
  planted=$([ -z "$hooks" ] || ! [ -d "$hooks" ] || ls -A "$hooks" | grep -v -E "[.]sample\$" | tr "\n" " "; true)
  [ -z "$planted" ] || bad "the hooks directory holds ${planted% }, which git runs on a checkout or a fetch; remove it"
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

# The checker's stage list: STAGES, else the FAST_STAGES line of the
# Makefile beside this script, else its CHECK_STAGES line, read rather than
# run, so the merge's copy of main lists main's stages whatever the
# branch's Makefile says; CI runs the rest of CHECK_STAGES.
stage_list() {
  if [ -n "${STAGES:-}" ]; then echo "$STAGES"; return; fi
  fast=$(sed -n 's/^FAST_STAGES := //p' "$here/../Makefile")
  if [ -n "$fast" ]; then echo "$fast"; return; fi
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
  [ -n "$stages" ] || bad "no stage list (STAGES, or FAST_STAGES or CHECK_STAGES in $here/../Makefile)"
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
  reviews=$(state review_fixes)
  # A run state written before merge-main-path has no main_moved: 0.
  moved=$(state main_moved)
  texts=$(state pr_text_fixes)
  if [ "${reviews:-0}" -gt 1 ]; then
    bad "$reviews review fix pushes; one is allowed a run"
  elif [ "${moved:-0}" -gt 1 ]; then
    bad "$moved main-moved pushes; one is allowed a run"
  elif [ "${texts:-0}" -gt 1 ]; then
    bad "$texts pull request text pushes; one is allowed a run"
  elif [ "${pushes:-0}" -gt $((1 + ${fixes:-0} + ${reviews:-0} + ${moved:-0} + ${texts:-0})) ]; then
    bad "$pushes pushes for ${fixes:-0} CI fix(es), ${reviews:-0} review fix(es), ${moved:-0} main-moved push(es), and ${texts:-0} pull request text push(es); one is allowed, plus one per CI fix, one review fix, one main-moved push, and one pull request text push"
  else
    ok "${pushes:-0} push(es), ${fixes:-0} CI fix(es), ${reviews:-0} review fix(es), ${moved:-0} main-moved push(es), ${texts:-0} pull request text push(es)"
  fi
}

# The pass records a merge needs, at the pushed head: phase.check and the
# security and bench reviews, each at a commit settled at HEAD,
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
  for kind in check security bench; do
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
  [ $failed -ne $start ] || ok "check, security, and bench passed at the pushed head $pushed"
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

# Findings are append-only: each `### ` heading under docs/findings/ at
# the fork point of BASE and HEAD, and each one a non-merge commit of BASE..HEAD added, is still
# present at HEAD, in the same file (a merge of a moved main brings in the
# groomed entries it removed, so the merged tree is not compared). Only a
# branch that appends to docs/sprints.tsv from the fork point exactly the
# row groom appends for the plan's sprint (groom_row), the delivery whose
# package step ran groom (planner-loop), which folds and prunes the
# findings, may remove one, and only one groom filed: its heading stands
# under docs/backlog/ at HEAD (or a "- Merged:" line there names it), or a
# line of the plan's groom.txt removes it, a security entry (SECURITY_MARK)
# only by listed or fixed (carrier_unproven); a forged or second row
# removes none.
gate_findings() {
  gate=findings
  start=$failed
  fork=$(git merge-base "$base" HEAD 2>/dev/null) || fork=$base
  carrier=""
  git diff --quiet "$fork" HEAD -- docs/sprints.tsv 2>/dev/null
  if [ $? -eq 1 ] && appended_rows "$fork" docs/sprints.tsv && groom_row "$fork"; then
    carrier=1
  fi
  findings_now=$(git grep -I --no-color -e '^### ' HEAD -- docs/findings 2>/dev/null | sed 's/^[^:]*://' | sort -u)
  findings_gone=$( {
    git grep -I --no-color -e '^### ' "$fork" -- docs/findings 2>/dev/null | sed 's/^[^:]*://'
    git log --no-merges --no-color --no-renames --no-ext-diff --no-textconv --src-prefix=a/ --dst-prefix=b/ --format= -p "$fork..HEAD" -- docs/findings 2>/dev/null |
      awk '/^\+\+\+ /{ f = substr($0, 7) } /^\+### /{ print f ":" substr($0, 2) }'
  } | sort -u | grep -v -x -F -e "$findings_now" )
  carried=""
  if [ -n "$carrier" ] && [ -n "$findings_gone" ]; then
    findings_gone=$(carrier_unproven "$findings_gone")
    carried=1
  fi
  if [ -n "$carrier" ]; then
    [ -z "$findings_gone" ] || bad "a branch carrying a sprint's groom removed an entry of docs/findings/ that docs/backlog/ does not hold and its plan does not remove (a security entry leaves only listed or fixed, or merged into another entry):
$findings_gone"
  else
    [ -z "$findings_gone" ] || bad "an entry of docs/findings/ present at the base or added by a commit of the branch is missing at HEAD (findings are append-only):
$findings_gone"
  fi
  [ $failed -ne $start ] && return
  if [ -n "$carried" ]; then
    ok "a branch carrying a sprint's groom removed only entries filed in docs/backlog/ or removed by its plan"
  else
    ok "no findings entry removed"
  fi
}

# The text of the entry under heading $2 of findings file $1 in its last
# version: the branch's newest commit holding it, else the fork point.
findings_entry_text() {
  for entry_rev in $(git rev-list --no-merges "$fork..HEAD" -- "$1" 2>/dev/null) "$fork"; do
    entry_text=$(git show "$entry_rev:$1" 2>/dev/null | H="$2" awk '/^#+ / { on = ($0 == ENVIRON["H"]) } on { print }')
    [ -z "$entry_text" ] || { printf '%s\n' "$entry_text"; return; }
  done
}

# The kinds of the lines of the plan's groom.txt that remove heading $1,
# one per line (the plan is local, so none in CI); $2 is the text of the
# entry. A listed or fixed line counts only when groom's proof of it holds
# (run_state.sh groom-proof, against the sprint in progress at the fork
# point): a change of the sprint whose queue item lists the heading, a
# commit of the sprint's range changing a file the entry names. The plan
# is a file the carrying contributor can write, so a line groom would
# refuse proves nothing.
groom_removals() {
  [ -f "${PLAN_DIR:-build/plan}/groom.txt" ] || return 0
  while IFS= read -r removal_line || [ -n "$removal_line" ]; do
    removal_rest=${removal_line#* }
    case "${removal_line%% *}" in
      listed|fixed) removal_head=${removal_rest#* } ;;
      gone) removal_head=${removal_rest% -- *} ;;
      duplicate) removal_head=$removal_rest ;;
      merged) removal_head=${removal_rest#* <= } ;;
      *) continue ;;
    esac
    [ "$removal_head" = "$1" ] || continue
    case "${removal_line%% *}" in
      listed|fixed) printf '%s\n' "$2" | sh "$here/run_state.sh" groom-proof "$fork" "$removal_line" 2>/dev/null || continue ;;
    esac
    echo "${removal_line%% *}"
  done < "${PLAN_DIR:-build/plan}/groom.txt"
}

# True when docs/backlog at HEAD holds, under a security entry, the line
# "- Merged: HEADING" ($1) of an entry groom merged into it, and the body
# of the merged entry ($2, its text) stands after that line: a security
# entry merges only into another security entry (groom's rule), judged by
# the kept entry's own lines, before its first "- Merged:" line, since the
# merged body brings a severity of its own, and no merged line without its
# body keeps the finding.
merged_security_kept() {
  merged_body=$(printf '%s\n' "$2" | awk '/^#+ / || /^- (Category|Added): / || !NF { next } { print }')
  git grep -I -l -F -e "- Merged: $1" HEAD -- docs/backlog 2>/dev/null | while IFS= read -r merged_file; do
    git show "$merged_file" 2>/dev/null | H="- Merged: $1" M="$SECURITY_MARK" B="$merged_body" awk '
      function check(   i, n, own, want, ok) {
        if (!hit) return
        own = tolower(own_text) " "
        if (own !~ ENVIRON["M"]) return
        n = split(ENVIRON["B"], want, "\n"); ok = 1
        for (i = 1; i <= n; i++) if (want[i] != "" && !(want[i] in after)) ok = 0
        if (ok) found = 1
      }
      /^#+ / { check(); hit = 0; merged = 0; own_text = ""; split("", after) }
      /^- Merged: / { merged = 1 }
      !merged { own_text = own_text " " $0 }
      $0 == ENVIRON["H"] { hit = 1; split("", after) }
      merged { after[$0] = 1 }
      END { check(); if (found) print "ok" }'
  done | grep -q -x ok
}

# Prints each line "FILE:### HEADING" of $1 that groom did not file or
# remove: its heading stands under docs/backlog/ at HEAD, or is named
# there by a "- Merged:" line (a security entry only under another
# security entry, its body kept: merged_security_kept); else a groom.txt
# line removes it with groom's proof (groom_removals), and a security
# entry (groom's SECURITY_MARK) only by listed or fixed.
carrier_unproven() {
  printf '%s\n' "$1" | while IFS= read -r unproven_line; do
    [ -n "$unproven_line" ] || continue
    unproven_path=${unproven_line%%:*}
    unproven_head=${unproven_line#*:}
    git grep -I -h --no-color -F -e "$unproven_head" HEAD -- docs/backlog 2>/dev/null | grep -q -x -F -e "$unproven_head" && continue
    unproven_text=$(findings_entry_text "$unproven_path" "$unproven_head")
    merged_line=""
    git grep -I -h --no-color -F -e "- Merged: $unproven_head" HEAD -- docs/backlog 2>/dev/null | grep -q -x -F -e "- Merged: $unproven_head" && merged_line=1
    if printf '%s %s\n' "$unproven_head" "$unproven_text" | tr '\n' ' ' | grep -q -i -E "$SECURITY_MARK"; then
      if [ -n "$merged_line" ] && merged_security_kept "$unproven_head" "$unproven_text"; then continue; fi
      groom_removals "$unproven_head" "$unproven_text" | grep -q -x -E 'listed|fixed' && continue
    else
      [ -z "$merged_line" ] || continue
      [ -z "$(groom_removals "$unproven_head" "$unproven_text")" ] || continue
    fi
    printf '%s\n' "$unproven_line"
  done
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
  # The pull request is created with this file's text byte for byte, so a
  # session line here would reach GitHub's activity.
  hits=$(grep -n -i -E '(^|[^a-z])(claude-)?session([ _-]?(id|link|url))?:' "$file")
  [ -z "$hits" ] || bad "a session line: $hits"
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
  findings) gate_findings ;;
  attribution) gate_attribution ;;
  origin) gate_origin ;;
  security) gate_security ;;
  stages) gate_stages ;;
  pushes) gate_pushes ;;
  records) gate_records ;;
  pr-body) gate_pr_body "$body" ;;
  static) gate_trailer; gate_content; gate_snapshots; gate_docs; gate_scenarios; gate_cases; gate_findings; gate_attribution ;;
  pre-push) gate_origin; gate_trailer; gate_content; gate_snapshots; gate_docs; gate_scenarios; gate_cases; gate_findings; gate_security; gate_stages ;;
  passed) gate_passed ;;
  merge)
    sh "$here/run_state.sh" gated "$change" clear >/dev/null || bad "the merge record gated could not be cleared"
    gate_origin; gate_trailer; gate_content; gate_findings; gate_security; gate_stages; gate_passed; gate_records; gate_pushes; gate_pr_body "$body"
    # The head every merge gate passed at, which the merge tool's hook in
    # tools/agent_guard.sh requires as the expected head.
    [ $failed -ne 0 ] || sh "$here/run_state.sh" gated "$change" pass >/dev/null || bad "the merge record gated could not be written" ;;
  *) echo "gates: unknown gate $target" >&2; exit 2 ;;
esac
exit $failed
