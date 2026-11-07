#!/bin/sh
# The run state of one change in the delivery pipeline, and the one writer
# of it and of the stage logs (.claude/workflows/deliver-change.js).
#
# State: build/pipeline/CHANGE.json, one flat JSON object of string values,
# one key per line, rewritten through a temporary file and a rename:
#   change, branch   the change, its branch, and repo, the GitHub owner/name
#   phase.NAME       the commit the phase finished at
#   stage.NAME       "EXIT SECONDSs COMMIT UTC-TIME" of the last run at the
#                    commit it started on, with "carried-from-COMMIT" when
#                    check carried it (below); EXIT is "running" while it
#                    runs, "killed" when a signal ended it, "superseded"
#                    when HEAD moved while it ran
#   review.KIND      "RESULT COMMIT SUMMARY" (security, quality, bench, and
#                    periodic-security and periodic-quality after a merge)
#   pushes, ci_fixes the pushes made and the CI fixes they may answer
#   gates_failed     the push attempts the pre-push gates refused
#   gated            the full sha every merge gate passed at, which the
#                    merge tool's hook requires; "none" after a push
#   pushed, pr, ci   the full sha of the last pushed commit, which the
#                    merger passes as the expected head, the pull
#                    request number, and
#                    "green|red COMMIT"
#   backup, base     the commit last pushed to refs/backup/BRANCH, until
#                    the branch's push, the merge, or abandon deletes that
#                    ref, and the branch's base pushed beside it
#   merged           the squash commit on main
#   metric.NAME      one measurement or figure of the run: tools/metrics.sh
#                    names, rework, ci_min, estimate (the plan's size), phase.KEY
#                    ("TOKENS/CALLS" of a phase so far), first.GATE (0 or 1,
#                    its first verdict), extra (fix rounds granted beyond
#                    three), stop (rounds when a start stopped at the
#                    limit, else none), planned (0 when the planner was
#                    skipped), and calib.KIND ("TIER/EFFORT" of a kind of
#                    agent start), stored by the workflow, every figure in each
#                    metric line it runs; total_tokens and wall_min, summed
#                    over the starts by usage; older runs stored
#                    first_pass, out_tokens, tool_calls, phases
#   note.N           "KIND TEXT": a retrospective proposal or a finding
# Logs: build/stages/CHANGE/STAGE.log, ending in "EXIT n", "KILLED: ...",
# or "SUPERSEDED: ..."; check.log, the runner's output, ending in its
# verdict line, and check.pid, "PID COMMIT" while the runner runs.
# Compile passes: build/pipeline/compiled, "STAGE KEY SUM" per stage of
# COMPILE_STAGES, kept across changes.
#
# History: docs/metrics.tsv, one row per merged change, appended by history
# from the run states that have none yet, so the next change carries the
# rows of the runs before it (columns in HEADER below). A row's estimate is
# metric.estimate, else the size word of the change's queue item, its
# actual the total_tokens and wall_min, with out_tokens beside them.
#
# Usage: sh tools/run_state.sh COMMAND ...
#   init CHANGE BRANCH          create the state unless it exists, then show it
#   show CHANGE                 print the state
#   trusted CHANGE              print the state a resume may trust: without a
#                               phase.*, review.*, or merged record whose
#                               commit is an ancestor of neither HEAD nor BASE,
#                               or a line write_key would not write, those
#                               keys named in "untrusted"
#   get CHANGE KEY              print one value, empty when absent
#   gated CHANGE clear|pass     the merge gates' record: none (in every run
#                               state), or HEAD's full sha
#   set CHANGE KEY VALUE        write one value; refuses review.*, phase.*, gated,
#                               and stage.*, which their own commands write,
#                               and a merged or pushed value but a commit hash;
#                               merged also deletes the backup refs
# Every write refuses a key outside [a-z0-9_.-] and a key or value holding a
# control character (newline, carriage return, tab, or another), so no write
# adds a line of its own.
#   phase CHANGE NAME [COMMIT]  record the phase (one of PHASES) done at
#                               COMMIT, HEAD when omitted
#   review CHANGE KIND RESULT SUMMARY [COMMIT]
#                               record a review (KIND one of REVIEW_KINDS,
#                               RESULT pass or blocked, and for the periodic
#                               kinds also partial, some areas not reviewed,
#                               or not-run, no result) at COMMIT, HEAD when
#                               omitted; a pass also records phase.KIND
# The delivery workflow, not its agents, runs phase and review: it builds
# them from the results it received (tools/agent_guard.sh keeps the agents
# off them, and the merge gate compares them with RECORDS).
#   stage CHANGE NAME CMD...    run CMD with its log and record its result
#   check CHANGE [COMMIT]       refuse a dirty tracked tree or an untracked
#                               file under carat/ bin/ test/ bench/, then
#                               run the canonical stages (make -s stages) in
#                               order and stop at the first failure (the
#                               workflow records phase.check); a stage record
#                               counts only at COMMIT, the last check the
#                               workflow passed, or carried from it: skipped
#                               when COMMIT is HEAD, carried to HEAD for a
#                               stage outside TEST_STAGES when only tests
#                               changed since COMMIT; a stage of
#                               COMPILE_STAGES is skipped on the code key of
#                               its last pass with its outputs unchanged. The
#                               stages run in a runner (check-run, no agent's)
#                               detached from the caller, rejoined by a check
#                               at the same HEAD and stopped by one at another;
#                               check waits CHECK_WAIT seconds, prints its log,
#                               and exits 0 on a pass, 1 otherwise, 3 while it
#                               runs; the last line is the verdict: "check:
#                               every stage passed at C", "check: stage S
#                               failed|killed|superseded at C; read LOG" (S
#                               none before a stage), or "check: still running"
#   scope CHANGE COMMIT [FILE...]
#                               print "fix: ..." and exit 0 when every path
#                               changed from COMMIT to HEAD is a FILE or
#                               matches TEST_ONLY, so the quality review of a
#                               fix reads only its diff; "branch: ..." and
#                               exit 1 otherwise or when nothing changed
#   bench CHANGE                record the metrics stage's measurement and
#                               compare it with main's through make
#                               metrics-compare: the newest merged change
#                               without a history row, else the last row;
#                               exit 0 when allocations and rounds equal
#                               them, 1 otherwise
#   push CHANGE [--ci-fix]      run the pre-push gates, refuse a push beyond one
#                               plus one per CI fix (a CI fix needs ci red), push
#                               the branch with upstream tracking, and count it;
#                               then delete the branch's backup refs
#   backup CHANGE               before the branch's push, run the trailer and
#                               content gates from the branch's base (the
#                               commit of main it forked from, recorded as
#                               base) and push HEAD to refs/backup/BRANCH and
#                               the base to refs/backup-base/BRANCH on origin,
#                               no branch, so a reclaimed container loses no
#                               commit
#   restore BRANCH              create BRANCH from refs/backup/BRANCH on origin
#                               when it exists neither here nor on origin;
#                               refuse a backup whose recorded base is missing
#                               or not on BASE, or holding a commit that does
#                               not descend from it
#   abandon CHANGE              delete the change's backup refs on origin, for
#                               a run that will not resume (the user's; no
#                               agent runs it); set CHANGE merged does too
#   metric CHANGE NAME=VALUE... record metric.NAME; names are [a-z0-9_.-], values
#                               [A-Za-z0-9_.,:/=+-]
#   metrics CHANGE FILE         record each "name<TAB>value" line of a
#                               tools/metrics.sh measurement as metric.name,
#                               dropping one whose value is ? (not measured)
#   note CHANGE KIND TEXT       record note.N, the next number, as "KIND TEXT";
#                               a quality-advisory whose TEXT, without its
#                               leading commit, is already noted is not
#   usage CHANGE TOKENS MINUTES add one start's total tokens (input plus
#                               output) and wall minutes, as the Workflow
#                               tool reported them, to metric.total_tokens
#                               and metric.wall_min, then print the budget
#   review-due CHANGE           print "due: REASON" and exit 0 when the merged
#                               change touched a sensitive area or five changes
#                               merged since the last periodic review; print
#                               "not due: ..." and exit 1 otherwise
#   plan-needed CHANGE          print "needed: REASON" and exit 0 when the
#                               change is not the head of docs/queue.md or a
#                               pending change holds a proposal or finding
#                               (PLAN_NOTES) to place; print "not needed:
#                               ..." with the head item's size and exit 1
#   budget CHANGE               print "over:", "under:", "unmeasured:", or
#                               "no estimate:" with the change's estimate, its
#                               budget (TOKEN_BUDGETS, MINUTE_BUDGETS), its
#                               total tokens and wall minutes, and its output
#                               tokens
#   spent CHANGE                print "under:", "over:", or "no estimate:" with
#                               the output tokens spent so far against the
#                               output budget of the change's estimate
#                               (TOKEN_BUDGETS / OUTPUT_SHARE) and the total
#                               tokens earlier starts recorded against
#                               TOKEN_BUDGETS; a note after a passing check,
#                               always exit 0
#   pending                     the merged changes with no history row yet
#   history                     append a history row for each pending change;
#                               a gate without a stored first verdict is
#                               left out of its first passes
#   status                      the queue, the running change, the last metrics
#                               row, and the first-pass rates of the history
#
# Environment: BASE (origin/main), RUN_STATE_DIR (build/pipeline),
# STAGE_DIR (build/stages), STAGES (the stage list; make -s stages when
# unset), MAKE (make), METRICS_FILE (docs/metrics.tsv), METRICS_OUT
# (build/metrics/current.tsv), CHECK_WAIT (540, seconds check waits).
set -u

here=$(cd "$(dirname "$0")" && pwd)
state_dir=${RUN_STATE_DIR:-build/pipeline}
stage_dir=${STAGE_DIR:-build/stages}
make_cmd=${MAKE:-make}
metrics_file=${METRICS_FILE:-docs/metrics.tsv}
metrics_out=${METRICS_OUT:-build/metrics/current.tsv}
PHASES="plan implement check quality security bench package ci merge retro report"
# The stages that read what a test-only commit may change, which such a
# commit runs again: test-build and test-run compile and run the tests,
# diagnose runs spinel-doctor on the test runner, metrics reads the runner's
# rounds from test-build's report, docs-lint reads docs/*.md and the test
# paths the docs name, and gates reads the commit; check carries the others.
# TEST_ONLY: the paths such a commit may change, tests and their snapshots,
# the OpenSpec records, and the planning records and metrics history, which
# no carried stage reads.
TEST_STAGES="test-build test-run diagnose metrics docs-lint gates"
TEST_ONLY='^(test/|openspec/|docs/(backlog|queue|goals)\.md$|docs/metrics\.tsv$|$)'
# The compile stages, skipped when the code they read is the code of their
# last pass and their outputs are the ones it left: the code key hashes
# every tracked path but NOT_COMPILED, which no compile stage reads, except
# BUILD_TOOLS, which dev-build and test-build run. COMPILED keeps each
# stage's last pass, "STAGE KEY SUM", across changes, in the run state's
# directory, which only this script writes.
COMPILE_STAGES="dev-build test-build diagnose"
NOT_COMPILED='^([.]claude/|[.]github/|docs/|openspec/|tools/[^/]+[.]sh$|[^/]+[.]md$)'
BUILD_TOOLS='^tools/analysis_budget[.]sh$'
compiled_file=$state_dir/compiled
# A Conventional Branch, as CLAUDE.md names them: the only branches backup
# and restore take.
BRANCH_PATTERN='(feature|bugfix|hotfix|release|chore)/[a-z0-9][a-z0-9-]*'
# The gates of a history row's first passes, in order, before gates.
GATES="check quality security bench ci"
REVIEW_KINDS="security quality bench periodic-security periodic-quality"
# The total-token budget (input plus output) of each size a queue item is
# estimated at, and the wall-minute budget of the sizes that have one, as
# docs/goals.md gives them.
TOKEN_BUDGETS="small=500000 medium=1200000 large=2500000"
MINUTE_BUDGETS="small=25"
# The total tokens per output token that a run's output budget assumes,
# for spent: the median of the history's rows with both figures was 5.5
# (4.1 to 9.1), rounded up so the note comes early rather than late.
OUTPUT_SHARE=6
# The note kinds of a pending change that the planner places: retrospective
# proposals, overruns, and periodic review findings.
PLAN_NOTES='retro|overrun|security|quality'
TAB=$(printf '\t')
# Columns 16 and 17 came after estimate, so rates ($5, $6) and review_due
# ($14) read the same columns in every row.
HEADER="change${TAB}date${TAB}merged${TAB}pr${TAB}rework${TAB}first_pass${TAB}ci_min${TAB}rounds${TAB}allocs${TAB}us_per_key${TAB}out_tokens${TAB}tool_calls${TAB}phases${TAB}review${TAB}estimate${TAB}total_tokens${TAB}wall_min${TAB}calibration"
# The areas whose change makes a periodic review of the whole codebase due,
# one "label=path pattern" per line, the first match named. An edit of
# config/default.caratrc that adds or removes only key bindings, comments,
# and blank lines leaves the file and its mirror out (keymap_only); an
# agent file counts as the guard's wiring only when its tools or hook lines
# change (agent_hooks). Other tooling, docs, and keymap-only changes count
# only toward the five.
REVIEW_AREAS='config loading=^(config/|bin/carat-gen-config[.]rb$|carat/(adapters/rc_config_gateway|ports/config_port|domain/(config|default_config|manifest_check|rc_[a-z_]+))[.]rb$)
file access=^carat/(drivers/disk_files[.]rb|ports/file_port[.]rb|domain/path_(policy|info)[.]rb|use_cases/files/)
plugin boundaries=^carat/(plugin_api[.]rb|plugins/|use_cases/plugins/)
terminal output=^carat/(drivers/ansi_terminal|ports/terminal_port|adapters/(screen_presenter|frame_presenter|painted_rows|sgr_table|key_decoder)|domain/(frame|display_width|utf8|decoded_line))[.]rb$
process spawning=^carat/drivers/
entry point=^bin/carat[.]rb$
guard and gates=^(tools/(agent_guard|gates|rules|ci_scope)[.]sh$|tools/noruby/|[.]claude/settings[.]json$|[.]github/workflows/)'

die() {
  echo "run_state: $*" >&2
  exit 1
}

head_commit() {
  git rev-parse --short=12 HEAD
}

# The twelve-digit form of COMMIT, HEAD when empty; dies unless it names a
# commit.
commit_at() {
  [ -n "$1" ] || { head_commit; return; }
  valid '[0-9a-f]{7,40}' "$1" || die "not a commit: $1"
  git rev-parse --verify -q --short=12 "$1^{commit}" || die "not a commit: $1"
}

# True when WORD is one of the words of LIST.
one_of() {
  case " $2 " in *" $1 "*) return 0 ;; esac
  return 1
}

state_file() {
  echo "$state_dir/$change.json"
}

# A value escaped for JSON; write_key and init refuse a control character
# first, so one key is one line.
escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Dies unless VALUE (named by WHAT) is free of control characters: a
# newline, carriage return, tab, escape, or any other would let a write add
# a line of its own, such as a forged review.* or phase.* record.
plain() {
  case "$1" in
    *[[:cntrl:]]*) die "refused: $2 holds a control character (newline, carriage return, tab, or another)" ;;
  esac
}

# Dies unless KEY is a run state key: lowercase letters, digits, _, ., -.
plain_key() {
  plain "$1" "the key"
  case "$1" in
    [a-z0-9]*) ;;
    *) die "refused: not a run state key: $1" ;;
  esac
  case "$1" in
    *[!a-z0-9_.-]*) die "refused: not a run state key: $1" ;;
  esac
}

read_key() {
  file=$(state_file)
  [ -f "$file" ] || return 0
  K="$1" awk '
    /^  "/ {
      key = $0; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (key != ENVIRON["K"]) next
      value = $0; sub(/^  "[^"]*": "/, "", value); sub(/",?$/, "", value)
      gsub(/\\"/, "\"", value); gsub(/\\\\/, "\\", value)
      print value; exit
    }' "$file"
}

write_key() {
  file=$(state_file)
  [ -f "$file" ] || die "no run state for $change; run init first"
  plain_key "$1"
  plain "$2" "the value of $1"
  K="$1" V=$(escape "$2") awk '
    /^  "/ {
      line = $0; sub(/,$/, "", line)
      key = line; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (key == ENVIRON["K"]) { line = "  \"" key "\": \"" ENVIRON["V"] "\""; found = 1 }
      lines[n++] = line
    }
    END {
      if (!found) lines[n++] = "  \"" ENVIRON["K"] "\": \"" ENVIRON["V"] "\""
      print "{"
      for (i = 0; i < n; i++) print lines[i] (i < n - 1 ? "," : "")
      print "}"
    }' "$file" > "$file.tmp.$$" && mv "$file.tmp.$$" "$file"
}

# Remove KEY from the run state; nothing happens when it is absent.
drop_key() {
  file=$(state_file)
  [ -f "$file" ] || die "no run state for $change; run init first"
  K="$1" awk '
    /^  "/ {
      line = $0; sub(/,$/, "", line)
      key = line; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (key != ENVIRON["K"]) lines[n++] = line
    }
    END {
      print "{"
      for (i = 0; i < n; i++) print lines[i] (i < n - 1 ? "," : "")
      print "}"
    }' "$file" > "$file.tmp.$$" && mv "$file.tmp.$$" "$file"
}

utc_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

# run_stage NAME CMD...: run CMD with its log and record its result at the
# commit it started on. The record reads "running" while it runs; its first
# word is then the exit status, "killed" when a signal ended the command
# (KILLED_STATUSES: a hang-up, interrupt, kill, or terminate), or
# "superseded" when HEAD moved while it ran, and the log's last line says
# which. The command runs in the background and is waited for, so a signal
# the check traps interrupts the wait at once (check_signalled). Sets
# stage_word to the record's first word; returns the status, 1 for a
# superseded stage that exited 0.
KILLED_STATUSES="129 130 137 143"
run_stage() {
  name=$1
  shift
  dir=$stage_dir/$change
  mkdir -p "$dir"
  log=$dir/$name.log
  at=$(head_commit)
  start=$(date +%s)
  write_key "stage.$name" "running 0s $at $(utc_now)"
  running_stage=$name
  "$@" > "$log" 2>&1 < /dev/null &
  child=$!
  wait "$child"
  status=$?
  child=''
  running_stage=''
  secs=$(( $(date +%s) - start ))
  now=$(head_commit)
  stage_word=$status
  if [ "$now" != "$at" ]; then
    stage_word=superseded
    echo "EXIT $status" >> "$log"
    echo "SUPERSEDED: HEAD moved from $at to $now while the stage ran" >> "$log"
  elif one_of "$status" "$KILLED_STATUSES"; then
    stage_word=killed
    echo "KILLED: exit $status, a signal ended the stage" >> "$log"
  else
    echo "EXIT $status" >> "$log"
  fi
  write_key "stage.$name" "$stage_word ${secs}s $at $(utc_now)"
  if [ "$stage_word" = "$status" ]; then
    echo "stage $name: exit $status in ${secs}s, log $log"
  else
    echo "stage $name: $stage_word (exit $status) in ${secs}s, log $log"
  fi
  [ "$stage_word" != superseded ] || [ "$status" -ne 0 ] || return 1
  return $status
}

# True when every path changed from COMMIT to HEAD matches TEST_ONLY; a
# rename counts both paths, so a file moved under test/ is no test-only change.
tests_only_since() {
  rest=$(git diff --no-renames --name-only "$1" HEAD 2>/dev/null) || return 1
  [ -z "$(printf '%s\n' "$rest" | grep -v -E "$TEST_ONLY")" ]
}

# The stages in order: a stage record counts only at BACKED, the last
# commit whose check the workflow recorded (empty: none), or carried from
# it, so a record at HEAD that no workflow record backs runs again. A stage
# passed at BACKED is skipped when BACKED is HEAD, and carried to HEAD when
# it reads no test program and only tests changed since BACKED.
# The runner (check-run) runs them detached from the waiter (check_wait);
# each stage that does not pass ends the run with its verdict line.
check_stages() {
  stages=${STAGES:-$("$make_cmd" -s --no-print-directory stages)}
  backed=$1
  key=$(code_key)
  for s in $stages; do
    record=$(read_key "stage.$s")
    at=$(echo "$record" | cut -d' ' -f3)
    from=$(echo "$record" | sed -n 's/.* carried-from-\([0-9a-f]*\)$/\1/p')
    case "$record" in
      "0 "*)
        if [ -n "$backed" ] && [ "$at" = "$backed" ] && [ "$at" = "$head" ]; then
          echo "stage $s: passed at $head, skipped"
          continue
        fi
        if [ -n "$backed" ] && { [ "$at" = "$backed" ] || [ "$from" = "$backed" ]; } &&
            ! one_of "$s" "$TEST_STAGES" && tests_only_since "$backed"; then
          write_key "stage.$s" "0 0s $head $(utc_now) carried-from-$backed"
          echo "stage $s: passed at $backed, carried to $head (only tests changed since)"
          continue
        fi ;;
    esac
    if one_of "$s" "$COMPILE_STAGES" && compiled_same "$s" "$key"; then
      write_key "stage.$s" "0 0s $head $(utc_now) compiled-$(echo "$key" | cut -c1-12)"
      echo "stage $s: passed on the same code (key $(echo "$key" | cut -c1-12)) with its outputs unchanged, skipped"
      continue
    fi
    one_of "$s" "$COMPILE_STAGES" && compiled_set "$s" ""
    if ! run_stage "$s" "$make_cmd" --no-print-directory check-stage "S=$s"; then
      case "$stage_word" in killed|superseded) word=$stage_word ;; *) word=failed ;; esac
      echo "check: stage $s $word at $head; read $stage_dir/$change/$s.log"
      exit 1
    fi
    one_of "$s" "$COMPILE_STAGES" && compiled_set "$s" "$key $(outputs_sum "$s")"
  done
  # The workflow records phase.check from the checker's result, so a check
  # run outside it backs nothing.
  echo "check: every stage passed at $head; the workflow records the check"
}

# The check's files: the runner's pid file, "PID COMMIT", while it runs,
# and its output, which ends with its verdict line.
check_pid_file() {
  echo "$stage_dir/$change/check.pid"
}
check_log() {
  echo "$stage_dir/$change/check.log"
}

# True when PID is a live check runner (a reused pid is another program).
runner_alive() {
  [ -n "$1" ] && kill -0 "$1" 2>/dev/null &&
    ps -p "$1" -o args= 2>/dev/null | grep -q 'run_state[.]sh check-run'
}

# The verdict line ending the runner's output, empty while it has none.
check_verdict() {
  last=$(tail -1 "$(check_log)" 2>/dev/null)
  case "$last" in "check: "*) echo "$last" ;; esac
}

# check-run BACKED: the runner, started detached by check_wait. It writes
# the pid file, removes it on exit while it still names it, and on a
# hang-up, interrupt, or terminate signal records its running stage as
# killed, or superseded when HEAD moved, and prints that verdict.
check_run() {
  head=$(head_commit)
  pid_file=$(check_pid_file)
  echo "$$ $head" > "$pid_file"
  running_stage=''
  child=''
  trap 'check_signalled HUP' HUP
  trap 'check_signalled INT' INT
  trap 'check_signalled TERM' TERM
  trap 'own=$(cut -d" " -f1 "$pid_file" 2>/dev/null); [ "$own" != "$$" ] || rm -f "$pid_file"' EXIT
  check_stages "$1"
}

check_signalled() {
  trap '' HUP INT TERM
  [ -z "$child" ] || kill -TERM "$child" 2>/dev/null
  # Detached by setsid, the runner leads its process group: the stage's
  # make and compilers stop with it.
  [ "$(ps -o pgid= -p $$ 2>/dev/null | tr -d ' ')" != "$$" ] || kill -TERM 0 2>/dev/null
  word=killed
  [ "$(head_commit)" = "$head" ] || word=superseded
  if [ -n "$running_stage" ]; then
    log=$stage_dir/$change/$running_stage.log
    echo "KILLED: the check received SIG$1 during the stage" >> "$log"
    write_key "stage.$running_stage" "$word $(( $(date +%s) - start ))s $head $(utc_now)"
    echo "check: stage $running_stage $word at $head; read $log"
  else
    echo "check: stage none $word at $head; read $(check_log)"
  fi
  exit 1
}

# A runner gone without a verdict (killed by a signal it cannot trap):
# its running stage, if any, is recorded as killed and its log says so;
# prints the verdict line and appends it to the runner's output.
check_lost() {
  at=$1
  lost=$(grep -E '^  "stage\.[^"]*": "running ' "$(state_file)" | head -1 | sed 's/^  "stage\.\([^"]*\)": "running \(.*\)",*$/\1 \2/')
  if [ -n "$lost" ]; then
    s=${lost%% *}
    rest=${lost#* }
    log=$stage_dir/$change/$s.log
    echo "KILLED: the check ended without a verdict during the stage" >> "$log"
    write_key "stage.$s" "killed $rest"
    line="check: stage $s killed at $at; read $log"
  else
    line="check: stage none killed at $at; read $(check_log)"
  fi
  echo "$line" >> "$(check_log)"
  echo "$line"
}

# check BACKED: refuse a dirty tree, then rejoin the runner running at
# HEAD, stop one at another commit (its verdict reads superseded), or
# start one detached from this shell (setsid), so the end of the caller's
# turn or tool call cannot kill the stages. Waits at most CHECK_WAIT
# seconds: prints the runner's output and exits 0 when every stage
# passed, 1 otherwise, and 3 while it still runs.
check_wait() {
  dirty=$(git status --porcelain --untracked-files=no)
  [ -z "$dirty" ] || die "check: refused: tracked files differ from HEAD; commit them first: $(printf '%s\n' "$dirty" | head -3 | tr '\n' ' ')"
  loose=$(git ls-files --others --exclude-standard -- carat bin test bench)
  [ -z "$loose" ] || die "check: refused: untracked files under carat/, bin/, test/, or bench/, which spin compiles: $(printf '%s\n' "$loose" | head -3 | tr '\n' ' ')"
  [ -f "$(state_file)" ] || die "no run state for $change; run init first"
  mkdir -p "$stage_dir/$change"
  head=$(head_commit)
  pid_file=$(check_pid_file)
  pid=''
  at=''
  [ ! -f "$pid_file" ] || read -r pid at < "$pid_file"
  joined=0
  if runner_alive "$pid" && [ "$at" = "$head" ]; then
    echo "check: rejoining the check running at $head (pid $pid)"
    joined=1
  elif runner_alive "$pid"; then
    echo "check: the check running at $at is superseded by $head; stopping it"
    kill -TERM "$pid" 2>/dev/null
    n=0
    while runner_alive "$pid" && [ $n -lt 150 ]; do pause; n=$((n + 1)); done
    echo "the superseded check: $(check_verdict)"
  elif [ -f "$pid_file" ]; then
    [ -n "$(check_verdict)" ] || echo "the last check: $(check_lost "$at")"
    rm -f "$pid_file"
  fi
  if [ "$joined" = 0 ]; then
    rm -f "$pid_file"
    : > "$(check_log)"
    if command -v setsid > /dev/null 2>&1; then
      setsid -f sh "$here/run_state.sh" check-run "$change" ${1:+"$1"} > "$(check_log)" 2>&1 < /dev/null
    else
      (sh "$here/run_state.sh" check-run "$change" ${1:+"$1"} > "$(check_log)" 2>&1 < /dev/null &)
    fi
  fi
  begun=$(date +%s)
  limit=${CHECK_WAIT:-540}
  seen=$joined
  while :; do
    verdict=$(check_verdict)
    [ -z "$verdict" ] || break
    read_pid
    if runner_alive "$pid"; then
      seen=1
    elif [ -n "$pid" ] || [ "$seen" = 1 ] || [ $(( $(date +%s) - begun )) -ge 10 ]; then
      # Gone, or never started, without a verdict: the pid file holds
      # only the runner started or rejoined here.
      [ -n "$(check_verdict)" ] || check_lost "$head" > /dev/null
      rm -f "$pid_file"
      continue
    fi
    if [ $(( $(date +%s) - begun )) -ge "$limit" ]; then
      echo "check: still running at $head (pid $pid, $(( $(date +%s) - begun ))s waited); run the same command again to wait"
      exit 3
    fi
    pause
  done
  cat "$(check_log)"
  case "$verdict" in "check: every stage passed at "*) return 0 ;; esac
  return 1
}

# The pid file's runner and commit as pid and at, empty without one.
read_pid() {
  pid=''
  at=''
  [ ! -f "$pid_file" ] || read -r pid at 2>/dev/null < "$pid_file" || true
}

# A fifth of a second, or a second where sleep takes whole seconds only.
pause() {
  sleep 0.2 2>/dev/null || sleep 1
}

# The key of the code the compile stages read: the blobs of every tracked
# path at HEAD but those NOT_COMPILED names (BUILD_TOOLS excepted), hashed.
code_key() {
  git ls-tree -r --full-tree HEAD |
    awk -F'\t' -v skip="$NOT_COMPILED" -v keep="$BUILD_TOOLS" '$2 !~ skip || $2 ~ keep' |
    git hash-object --stdin
}

# The outputs of a compile stage, which later stages read (test-run and
# metrics), as the Makefile names them (DEV_BIN, TEST_BIN).
compile_outputs() {
  case "$1" in
    dev-build) echo build/dev/carat build/dev/carat.timing ;;
    test-build) echo build/test/run_all build/test/run_all.timing ;;
  esac
}

# The checksum of a compile stage's outputs: "-" without outputs, "missing"
# when one is absent.
outputs_sum() {
  files=$(compile_outputs "$1")
  [ -n "$files" ] || { echo -; return; }
  for f in $files; do [ -f "$f" ] || { echo missing; return; }; done
  # shellcheck disable=SC2086
  cat $files | cksum | tr ' ' '-'
}

# True when the compile stage last passed on KEY and its outputs still have
# the checksum that pass left (COMPILED).
compiled_same() {
  [ -f "$compiled_file" ] || return 1
  sum=$(outputs_sum "$1")
  [ "$sum" != missing ] || return 1
  awk -v s="$1" -v k="$2 $sum" '$1 == s { found = (substr($0, length(s) + 2) == k) } END { exit !found }' "$compiled_file"
}

# compiled_set STAGE VALUE: the stage's line of COMPILED, "KEY SUM", or none
# when VALUE is empty.
compiled_set() {
  mkdir -p "$state_dir"
  touch "$compiled_file"
  awk -v s="$1" -v v="$2" '$1 != s { print } END { if (v != "") print s " " v }' "$compiled_file" > "$compiled_file.tmp.$$" &&
    mv "$compiled_file.tmp.$$" "$compiled_file"
}

# scope COMMIT [FILE...]: whether the fix since COMMIT stays within the
# files the blocking findings at COMMIT name, tests, and the OpenSpec and
# planning records (TEST_ONLY), so the next quality review may read only
# its diff; renames count both paths.
fix_scope() {
  since=$(commit_at "$1") || exit 1
  shift
  for f in "$@"; do
    valid '[A-Za-z0-9_][A-Za-z0-9_./-]*' "$f" && parent_free "$f" || die "scope: not a plain relative path: $f"
  done
  rest=$(git diff --no-renames --name-only "$since" HEAD) || die "scope: git diff failed"
  if [ -z "$rest" ]; then
    echo "branch: nothing changed since $since; review the whole branch diff"
    return 1
  fi
  other=$(printf '%s\n' "$rest" | while IFS= read -r path; do
    printf '%s\n' "$path" | grep -q -E "$TEST_ONLY" && continue
    named=0
    for f in "$@"; do [ "$f" != "$path" ] || named=1; done
    [ "$named" -eq 1 ] || { printf '%s\n' "$path"; break; }
  done)
  if [ -n "$other" ]; then
    echo "branch: $other changed since $since and no blocking finding names it; review the whole branch diff"
    return 1
  fi
  echo "fix: review only git diff $since HEAD against the findings and the rules"
}

# True when PATH has no parent step (..) as a segment.
parent_free() {
  case "/$1/" in */../*) return 1 ;; esac
}

count() {
  value=$(read_key "$1")
  echo "${value:-0}"
}

# The merge gates' first step: every run state under the run state's
# directory holding a gated value other than none, not only this change's,
# gets none, since the merge tool's hook reads them all and branch code run
# by the checks can plant one. A file that cannot be rewritten fails it.
gated_clear() {
  for other in "$state_dir"/*.json; do
    grep -s '"gated"' "$other" | grep -q -v -E '^  "gated": "none",?$' || continue
    (change=$(basename "$other" .json) && write_key gated none) || return 1
  done
  write_key gated none
}

push_branch() {
  pushes=$(count pushes)
  fixes=$(count ci_fixes)
  if [ "${1:-}" = "--ci-fix" ]; then
    case "$(read_key ci)" in
      red*) fixes=$((fixes + 1)) ;;
      *) die "push: refused: a CI fix push needs a red CI run recorded (ci)" ;;
    esac
  fi
  if [ "$pushes" -ge $((1 + fixes)) ]; then
    die "push: refused: $pushes push(es) made; one is allowed, plus one per CI fix ($fixes)"
  fi
  branch=$(git rev-parse --abbrev-ref HEAD)
  [ "$branch" != "main" ] || die "push: refused: never push main"
  if ! CHANGE=$change sh "$here/gates.sh" pre-push; then
    write_key gates_failed $(($(count gates_failed) + 1))
    die "push: refused: the pre-push gates failed"
  fi
  git push -u origin "$branch" || die "push: git push failed"
  write_key pushes $((pushes + 1))
  write_key ci_fixes "$fixes"
  write_key pushed "$(git rev-parse HEAD)"
  # A new head needs the merge gates again, and a marker branch code
  # planted in this run state before the push is gone; the merge gates
  # clear every other run state's (gated_clear).
  write_key gated none
  # The pushed branch holds every commit the backup held, whichever run
  # state made it; a deletion that fails is reported, and recording merged
  # tries it again.
  drop_backup "$branch" push || true
}

# drop_backup BRANCH WHO: delete refs/backup/BRANCH and
# refs/backup-base/BRANCH on origin when they exist, in one push, and drop
# the backup record; says what it deleted, nothing when there was none;
# returns 1 when the deletion failed.
drop_backup() {
  valid "$BRANCH_PATTERN" "$1" || return 0
  refs=$(git ls-remote origin "refs/backup/$1" "refs/backup-base/$1" 2> /dev/null |
    B="$1" awk '$2 == "refs/backup/" ENVIRON["B"] || $2 == "refs/backup-base/" ENVIRON["B"] { print $2 }')
  if [ -n "$refs" ]; then
    # shellcheck disable=SC2086 # the two ref names, which hold no space
    if ! git push -q origin --delete $refs > /dev/null 2>&1; then
      echo "$2: could not delete the backup of $1 on origin; abandon $change deletes it" >&2
      return 1
    fi
    echo "$2: deleted the backup of $1 ($(echo $refs))"
  fi
  [ -z "$(read_key backup)" ] || drop_key backup
}

# The commit BRANCH forked from: the parent of the oldest first-parent
# commit of HEAD not on BASE (origin/main), HEAD when every commit is, so a
# later merge of origin/main, whose first parent is the branch, keeps it.
branch_base() {
  oldest=$(git rev-list --first-parent HEAD --not "${BASE:-origin/main}" -- 2> /dev/null | tail -1)
  if [ -z "$oldest" ]; then
    git rev-parse --verify -q HEAD
  else
    git rev-parse --verify -q "$oldest^1"
  fi
}

# backup: push HEAD of the change's branch, not pushed yet, to
# refs/backup/BRANCH on origin, and its base (branch_base, recorded as base)
# to refs/backup-base/BRANCH, so a reclaimed container loses no commit and
# restore can check what it takes. The trailer and content gates run from
# that base, a commit of main, so they read every commit the push publishes.
# The refs are no branch: no pull request or CI run starts from them. A
# plain atomic push, since the branch's history only grows.
backup_branch() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  [ "$branch" != main ] && [ "$branch" = "$(read_key branch)" ] ||
    die "backup: refused: HEAD is on $branch, not the change's branch $(read_key branch)"
  valid "$BRANCH_PATTERN" "$branch" || die "backup: refused: not a Conventional Branch: $branch"
  if [ "$(count pushes)" -gt 0 ]; then
    echo "backup: $branch is on origin since its push; nothing to back up"
    return 0
  fi
  main_ref=${BASE:-origin/main}
  base=$(branch_base) || die "backup: refused: no base of $branch on $main_ref"
  git merge-base --is-ancestor "$base" "$main_ref" 2> /dev/null ||
    die "backup: refused: the base $(git rev-parse --short=12 "$base") is not on $main_ref"
  write_key base "$(git rev-parse --short=12 "$base")"
  BASE=$base CHANGE=$change sh "$here/gates.sh" backup || die "backup: refused: the backup gates failed"
  git push -q --atomic origin "HEAD:refs/backup/$branch" "$base:refs/backup-base/$branch" ||
    die "backup: git push failed (a backup of an older run of $branch? abandon $change deletes it)"
  write_key backup "$(head_commit)"
  echo "backup: $(head_commit) at refs/backup/$branch on origin"
}

# restore BRANCH: create BRANCH from its backup on origin when it exists
# neither here nor on origin and the backup's history is rooted at its
# recorded base: refs/backup-base/BRANCH, a commit of BASE (origin/main),
# from which every commit of the backup descends; exit 1 with the reason
# otherwise.
restore_branch() {
  valid "$BRANCH_PATTERN" "$1" || die "restore: not a Conventional Branch: $1"
  if git rev-parse --verify -q "refs/heads/$1" > /dev/null; then
    echo "restore: $1 exists here; nothing to restore"
    return 1
  fi
  if git ls-remote --exit-code origin "refs/heads/$1" > /dev/null 2>&1; then
    echo "restore: $1 is on origin; check it out from there"
    return 1
  fi
  if ! git fetch -q origin "refs/backup/$1" 2> /dev/null; then
    echo "restore: no backup of $1 on origin"
    return 1
  fi
  tip=$(git rev-parse --verify -q FETCH_HEAD) || die "restore: no fetched head"
  if ! git fetch -q origin "refs/backup-base/$1" 2> /dev/null; then
    echo "restore: refused: the backup of $1 has no recorded base (refs/backup-base/$1)"
    return 1
  fi
  base=$(git rev-parse --verify -q FETCH_HEAD) || die "restore: no fetched base"
  if ! git merge-base --is-ancestor "$base" "${BASE:-origin/main}" 2> /dev/null; then
    echo "restore: refused: the recorded base $(git rev-parse --short=12 "$base") of $1 is not on ${BASE:-origin/main}"
    return 1
  fi
  if ! git merge-base --is-ancestor "$base" "$tip" ||
      [ "$(git rev-list --count --ancestry-path "$base..$tip")" != "$(git rev-list --count "$base..$tip")" ]; then
    echo "restore: refused: the backup of $1 holds commits that do not descend from its recorded base $(git rev-parse --short=12 "$base")"
    return 1
  fi
  git branch "$1" "$tip" || die "restore: git branch failed"
  echo "restore: $1 created from its backup at $(git rev-parse --short=12 "$1")"
}

show_status() {
  if [ -f docs/queue.md ]; then
    echo "== queue (docs/queue.md)"
    cat docs/queue.md
  else
    echo "queue: none (docs/queue.md does not exist)"
  fi
  running=""
  for file in $(ls -t "$state_dir"/*.json 2>/dev/null); do
    change=$(basename "$file" .json)
    if [ -z "$(read_key merged)" ]; then running=$change; break; fi
  done
  if [ -n "$running" ]; then
    change=$running
    done_list=""
    next=""
    for p in $PHASES; do
      if [ -n "$(read_key "phase.$p")" ]; then done_list="$done_list $p"
      elif [ -z "$next" ]; then next=$p; fi
    done
    echo "== running: $change on $(read_key branch)"
    echo "phases done:${done_list:- none}"
    echo "next phase: ${next:-none}"
    grep -E '"(stage|review)\.|"(pr|ci|pushes)"' "$(state_file)" | sed 's/^  /  /; s/,$//'
  else
    echo "running: none"
  fi
  if [ -f "$metrics_file" ] && [ "$(wc -l < "$metrics_file")" -gt 1 ]; then
    echo "== last metrics row ($metrics_file)"
    head -1 "$metrics_file"
    tail -1 "$metrics_file"
    rates
  else
    echo "metrics: none ($metrics_file has no row)"
  fi
}

# The first-pass rate of each gate and the rework rounds over the history.
rates() {
  awk -F'\t' '
    NR > 1 && $6 != "-" {
      rows++
      n = split($6, pairs, ",")
      for (i = 1; i <= n; i++) {
        split(pairs[i], kv, ":")
        if (!(kv[1] in tried)) order[++gates] = kv[1]
        tried[kv[1]]++
        if (kv[2] == "1") passed[kv[1]]++
      }
    }
    NR > 1 && $5 != "-" { rework += $5; changes++ }
    END {
      line = "first-pass rates over " rows + 0 " change(s):"
      for (i = 1; i <= gates; i++) line = line " " order[i] " " passed[order[i]] + 0 "/" tried[order[i]]
      print line
      print "rework rounds: " rework + 0 " over " changes + 0 " change(s)"
    }' "$metrics_file"
}

# True when VALUE matches PATTERN whole; a value holding a control
# character never does, since grep -x would match it one line at a time.
valid() {
  case "$2" in *[[:cntrl:]]*) return 1 ;; esac
  printf '%s' "$2" | grep -q -x -E "$1"
}

record_metric() {
  name=${1%%=*}
  value=${1#*=}
  case "$1" in *=*) ;; *) die "metric: $1 is not NAME=VALUE" ;; esac
  valid '[a-z0-9_.-]+' "$name" || die "metric: not a metric name: $name"
  valid '[A-Za-z0-9_.,:/=+-]*' "$value" || die "metric: $name: not a metric value: $value"
  write_key "metric.$name" "$value"
}

import_metrics() {
  [ -f "$1" ] || die "metrics: no measurement $1"
  recorded=0
  skipped=0
  while IFS="$TAB" read -r name value; do
    [ -n "$name" ] || continue
    # tools/metrics.sh writes ? for a value it could not measure; an
    # unmeasured value is not stored, and a figure an earlier import
    # recorded for it is removed so it does not pass for this one.
    if [ "$value" = "?" ]; then
      valid '[a-z0-9_.-]+' "$name" || die "metrics: not a metric name: $name"
      drop_key "metric.$name"
      skipped=$((skipped + 1))
      continue
    fi
    record_metric "$name=$value"
    recorded=$((recorded + 1))
  done < "$1"
  echo "metrics: recorded $recorded measurement(s) of $change, skipped $skipped unmeasured"
}

# The squash commit of the change, merged, when it is 7 to 40 hexadecimal
# digits; nothing otherwise, so no stored value reaches git as an option.
# Every git call on it also passes it after --end-of-options.
merged_commit() {
  merged=$(read_key merged)
  valid '[0-9a-f]{7,40}' "$merged" && echo "$merged"
  return 0
}

# The newest merged change without a history row, by its squash commit's
# time; nothing when none is pending.
newest_pending() {
  for name in $(pending_list); do
    merged=$(change=$name; merged_commit)
    printf '%s %s\n' "$(git log -1 --format=%ct --end-of-options "$merged" -- 2>/dev/null || echo 0)" "$name"
  done | sort -n -k1,1 | tail -1 | cut -d' ' -f2
}

# The bench command: the metrics stage's measurement against main's. The
# history row of a merged change is appended in the next change's package
# step, after this one, so main's figures are those of the newest merged
# change without a row (its run state's metric.rounds.*, allocs.*, us.*),
# and the last history row only when no merged change is pending.
bench_compare() {
  record=$(read_key stage.metrics)
  case "$record" in
    "0 "*) [ "$(echo "$record" | cut -d' ' -f3)" = "$(head_commit)" ] ||
      die "bench: the metrics stage passed at another commit; run the checks first" ;;
    *) die "bench: the metrics stage has not passed at HEAD; run the checks first" ;;
  esac
  import_metrics "$metrics_out"
  last=$(dirname "$metrics_out")/last.tsv
  base=$(newest_pending)
  if [ -n "$base" ]; then
    (change=$base; keys_under metric.) | awk '
      /^(rounds|allocs|us)[.][^=]*=/ { name = $0; sub(/=.*/, "", name); sub(/^[^=]*=/, ""); print name "\t" $0 }' > "$last"
    if ! grep -q -E '^(allocs|rounds)[.]' "$last"; then
      echo "bench: the newest merged change $base has no recorded allocations or rounds to compare with"
      return 1
    fi
    source="the run state of $base, merged without a history row yet"
  else
    if [ ! -f "$metrics_file" ] || [ "$(wc -l < "$metrics_file")" -le 1 ]; then
      echo "bench: no history row in $metrics_file to compare with"
      return 1
    fi
    tail -1 "$metrics_file" | awk -F'\t' '
      function out(kind, list,   n, i, p, kv) {
        if (list == "-" || list == "") return
        n = split(list, p, ",")
        for (i = 1; i <= n; i++) { split(p[i], kv, "="); printf "%s.%s\t%s\n", kind, kv[1], kv[2] }
      }
      { out("rounds", $8); out("allocs", $9); out("us", $10) }' > "$last"
    source="the history row of $(tail -1 "$metrics_file" | cut -f1)"
  fi
  echo "bench: comparing with $source"
  "$make_cmd" --no-print-directory metrics-compare "BASE_METRICS=$last"
  differ=$(awk -F'\t' '
    NR == FNR { if ($1 ~ /^(allocs|rounds)[.]/) base[$1] = $2; next }
    $1 ~ /^(allocs|rounds)[.]/ {
      seen[$1] = 1
      if (!($1 in base) || $2 == "?" || base[$1] + 0 != $2 + 0) print $1 " " ($1 in base ? base[$1] : "none") " -> " $2
    }
    END { for (k in base) if (!(k in seen)) print k " " base[k] " -> none" }' "$last" "$metrics_out")
  if [ -n "$differ" ]; then
    echo "bench: differs from $source:"
    printf '%s\n' "$differ"
    return 1
  fi
  echo "bench: same allocations and rounds as $source"
}

add_note() {
  valid '[a-z-]+' "$1" || die "note: the kind is lowercase words joined by hyphens, not $1"
  # An advisory a later round repeats is one note: its text is compared
  # without the leading commit of the review that found it.
  # Both sides strip one pattern, a commit of 7 to 40 hexadecimal digits,
  # so a text starting with a word of hex letters (add, dead) is kept whole.
  if [ "$1" = quality-advisory ]; then
    if keys_under note. | T="$(escape "$2")" awk '
        function bare(s) { return match(s, /^[0-9a-f]+ /) && RLENGTH >= 8 && RLENGTH <= 41 ? substr(s, RLENGTH + 1) : s }
        { sub(/^[0-9]+=/, "") }
        sub(/^quality-advisory /, "") { if (bare($0) == bare(ENVIRON["T"])) found = 1 }
        END { exit !found }'; then
      echo "note: the advisory is already recorded; not recorded again"
      return 0
    fi
  fi
  n=$(($(grep -c '^  "note[.]' "$(state_file)") + 1))
  write_key "note.$n" "$1 $2"
}

has_row() {
  [ -f "$metrics_file" ] && awk -F'\t' -v c="$1" 'NR > 1 && $1 == c { found = 1 } END { exit !found }' "$metrics_file"
}

# The merged changes whose run state has no history row, one per line; a
# merged value that is not a commit hash is not a merge.
pending_list() {
  for file in "$state_dir"/*.json; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .json)
    [ -n "$(change=$name; merged_commit)" ] || continue
    has_row "$name" || echo "$name"
  done
}

# The keys of the run state under PREFIX as "suffix=value" lines.
keys_under() {
  P="$1" awk '
    /^  "/ {
      key = $0; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (index(key, ENVIRON["P"]) != 1) next
      value = $0; sub(/^  "[^"]*": "/, "", value); sub(/",?$/, "", value)
      print substr(key, length(ENVIRON["P"]) + 1) "=" value
    }' "$(state_file)"
}

# metric.PREFIX.* of the run state as "suffix=value,...", "-" when none.
group() {
  out=$(keys_under "metric.$1." | paste -s -d, -)
  echo "${out:--}"
}

value() {
  v=$(read_key "$1")
  echo "${v:--}"
}

# The first verdict of GATE, 1 or 0: metric.first.GATE as the workflow
# stored it, else the gate's entry of an older run's metric.first_pass;
# nothing when neither says. The stage.*, review.*, and ci lines hold each
# gate's last result, which for a merged change is a pass, so they say
# nothing about the first.
first_of() {
  v=$(read_key "metric.first.$1")
  [ -z "$v" ] || { echo "$v"; return; }
  read_key metric.first_pass | tr ',' '\n' | sed -n "s/^$1://p"
}

# The output tokens of the run: the sum of its metric.phase.* figures, else
# an older run's metric.out_tokens; "-" when neither was recorded.
out_tokens() {
  if [ "$(group phase)" = "-" ]; then
    value metric.out_tokens
  else
    keys_under metric.phase. | awk -F'[=/]' '{ n += $2 } END { print n + 0 }'
  fi
}

# The size the change was estimated at, small, medium, or large:
# metric.estimate, which the workflow stores from the plan, so it outlives
# the queue item; else, for a run that stored none, the "estimated SIZE" of
# its item ("N. `CHANGE` ...") in docs/queue.md at the parent of its squash
# commit, the queue it was delivered from; "-" when neither states a size.
estimate_of() {
  size=$(read_key metric.estimate)
  if valid '(small|medium|large)' "$size"; then
    echo "$size"
    return
  fi
  merged=$(merged_commit)
  [ -n "$merged" ] || { echo -; return; }
  size=$(git show --end-of-options "$merged^:docs/queue.md" 2>/dev/null | C="$change" awk '
    {
      item = $0
      if (!sub(/^[0-9]+[.] /, "", item) || index(item, "`" ENVIRON["C"] "`") != 1) next
      if (match(item, /estimated (small|medium|large)/)) print substr(item, RSTART + 10, RLENGTH - 10)
      exit
    }')
  echo "${size:--}"
}

# The budget line: the run's total tokens and wall minutes against the
# budgets of its estimate (TOKEN_BUDGETS, MINUTE_BUDGETS), its output tokens
# beside them, for the retrospective to flag an overrun.
budget_line() {
  [ -f "$(state_file)" ] || die "no run state for $change"
  size=$(estimate_of)
  total=$(value metric.total_tokens)
  minutes=$(read_key metric.wall_min)
  actual="actual $total total tokens${minutes:+ in $minutes minutes}, $(out_tokens) output tokens"
  if [ "$size" = "-" ]; then
    echo "no estimate: neither the run state nor a queue item of $change states a size; $actual"
    return
  fi
  limit=$(printf '%s\n' $TOKEN_BUDGETS | sed -n "s/^$size=//p")
  time_limit=$(printf '%s\n' $MINUTE_BUDGETS | sed -n "s/^$size=//p")
  budget="budget $limit total tokens${time_limit:+ and $time_limit minutes}"
  if ! valid '[0-9]+' "$total"; then
    echo "unmeasured: estimated $size, $budget, no total tokens recorded"
  elif [ "$total" -gt "$limit" ] || { [ -n "$time_limit" ] && valid '[0-9]+([.][0-9]+)?' "$minutes" &&
      awk -v m="$minutes" -v l="$time_limit" 'BEGIN { exit !(m > l) }'; }; then
    echo "over: estimated $size, $budget, $actual"
  else
    echo "under: estimated $size, $budget, $actual"
  fi
}

# usage TOKENS MINUTES: add one start's total tokens and wall minutes to the
# run's sums, then print the budget line.
add_usage() {
  valid '[0-9]+' "$1" || die "usage: the total tokens are a whole number, not $1"
  valid '[0-9]+([.][0-9]+)?' "$2" || die "usage: the wall minutes are a number, not $2"
  [ -f "$(state_file)" ] || die "no run state for $change"
  tokens=$(read_key metric.total_tokens)
  minutes=$(read_key metric.wall_min)
  [ -z "$tokens" ] || valid '[0-9]+' "$tokens" || die "usage: the recorded total tokens are not a number: $tokens"
  [ -z "$minutes" ] || valid '[0-9]+([.][0-9]+)?' "$minutes" || die "usage: the recorded wall minutes are not a number: $minutes"
  write_key metric.total_tokens "$(awk -v a="${tokens:-0}" -v b="$1" 'BEGIN { printf "%.0f", a + b }')"
  write_key metric.wall_min "$(awk -v a="${minutes:-0}" -v b="$2" 'BEGIN { printf "%.1f", a + b }')"
  budget_line
}

# The tokens spent so far against the budget, which the checker prints
# after a passing check: the output tokens of the phases the metric line
# stored (every start's, this one's up to the check) against the size's
# output budget, its total-token budget divided by OUTPUT_SHARE, and the
# total tokens earlier starts recorded through usage against the total
# budget. A note for the workflow, never a stop: it exits 0.
spent_line() {
  [ -f "$(state_file)" ] || die "no run state for $change"
  size=$(estimate_of)
  out=$(out_tokens)
  valid '[0-9]+' "$out" || out=0
  total=$(read_key metric.total_tokens)
  valid '[0-9]+' "$total" || total=0
  earlier="$total total tokens recorded by earlier starts"
  if [ "$size" = "-" ]; then
    echo "no estimate: $out output tokens so far; $earlier; neither the run state nor a queue item of $change states a size"
    return
  fi
  limit=$(printf '%s\n' $TOKEN_BUDGETS | sed -n "s/^$size=//p")
  out_limit=$((limit / OUTPUT_SHARE))
  word=under
  if [ "$out" -gt "$out_limit" ] || [ "$total" -gt "$limit" ]; then word=over; fi
  echo "$word: $out output tokens so far, budget $out_limit output tokens for $size ($limit total tokens at $OUTPUT_SHARE per output token); $earlier, budget $limit"
}

history_row() {
  merged=$(merged_commit)
  date=""
  [ -z "$merged" ] || date=$(git log -1 --format=%cs --end-of-options "$merged" -- 2>/dev/null)
  first=""
  for g in $GATES; do
    v=$(first_of "$g")
    [ -z "$v" ] || first="${first:+$first,}$g:$v"
  done
  phases=$(group phase)
  tokens=$(out_tokens)
  if [ "$phases" = "-" ]; then
    phases=$(value metric.phases)
    calls=$(value metric.tool_calls)
  else
    calls=$(keys_under metric.phase. | awk -F'[=/]' '{ n += $3 } END { print n + 0 }')
  fi
  if [ "$(count pushes)" -gt 0 ]; then
    if [ "$(count gates_failed)" -eq 0 ]; then gates=1; else gates=0; fi
    first="${first:+$first,}gates:$gates"
  fi
  review="-"
  security=$(read_key review.periodic-security)
  quality=$(read_key review.periodic-quality)
  if [ -n "$security$quality" ]; then
    review="security=${security%% *} quality=${quality%% *}"
  fi
  printf '%s\t' "$change" "${date:--}" "${merged:--}" "$(value pr)" "$(value metric.rework)" "${first:--}" \
    "$(value metric.ci_min)" "$(group rounds)" "$(group allocs)" "$(group us)" \
    "$tokens" "$calls" "$phases" "$review" "$(estimate_of)" "$(value metric.total_tokens)"
  printf '%s\t' "$(value metric.wall_min)"
  printf '%s\n' "$(group calib)"
}

append_history() {
  names=$(pending_list)
  [ -n "$names" ] || { echo "history: nothing pending"; return 0; }
  [ -f "$metrics_file" ] || printf '%s\n' "$HEADER" > "$metrics_file"
  for change in $names; do
    history_row >> "$metrics_file"
    echo "history: appended $change"
  done
}

# True when the edit of config/default.caratrc in commit $1 adds or removes
# only key bindings, comments, and blank lines; no edit is not keymap-only.
keymap_only() {
  lines=$(git diff --no-ext-diff --no-color -U0 --end-of-options "$1~1" "$1" -- config/default.caratrc 2>/dev/null |
    awk '/^diff / { hunk = 0 } /^@@/ { hunk = 1; next } hunk && /^[-+]/')
  [ -n "$lines" ] || return 1
  [ -z "$(printf '%s\n' "$lines" | grep -v -E '^[-+](keymap[.]|#|[[:space:]]*$)')" ]
}

# The first agent file of commit $1 whose edit adds or removes a tools line
# or a hook line of its frontmatter, the wiring of the guard; nothing when
# none does.
agent_hooks() {
  git diff --no-ext-diff --no-color -U0 --end-of-options "$1~1" "$1" -- .claude/agents 2>/dev/null | awk '
    /^diff / { file = $NF; sub(/^b\//, "", file); next }
    /^(---|\+\+\+) / { next }
    /^[-+](tools:|hooks:|[[:space:]]+(PreToolUse:|- matcher:|matcher:|hooks:|- type:|type:|command:))/ { print file; exit }'
}

# periodic_done RESULT: a periodic security result that counts as a review
# done; a partial or missing one keeps the next review due.
periodic_done() {
  [ "$1" = pass ] || [ "$1" = blocked ]
}

review_due() {
  merged=$(merged_commit)
  [ -n "$merged" ] || die "review-due: $change is not merged (no merged commit hash)"
  paths=$(git diff --name-only --end-of-options "$merged~1" "$merged" -- 2>/dev/null)
  if keymap_only "$merged"; then
    paths=$(printf '%s\n' "$paths" | grep -v -x -E 'config/default[.]caratrc|carat/domain/default_config[.]rb')
  fi
  area=$(printf '%s\n' "$REVIEW_AREAS" | while IFS='=' read -r label pattern; do
    hit=$(printf '%s\n' "$paths" | grep -E -m 1 "$pattern")
    if [ -n "$hit" ]; then echo "$label ($hit)"; break; fi
  done)
  if [ -z "$area" ]; then
    hit=$(agent_hooks "$merged")
    [ -z "$hit" ] || area="guard and gates ($hit, its tools or hooks)"
  fi
  if [ -n "$area" ]; then
    echo "due: the change touched $area"
    return 0
  fi
  rows=0
  [ ! -f "$metrics_file" ] || rows=$(awk -F'\t' 'NR > 1 { n = ($14 ~ /^security=(pass|blocked)( |$)/) ? 0 : n + 1 } END { print n + 0 }' "$metrics_file")
  waiting=0
  reviewed=0
  for name in $(pending_list); do
    security=$(change=$name; read_key review.periodic-security)
    if periodic_done "${security%% *}"; then reviewed=1
    else waiting=$((waiting + 1)); fi
  done
  [ "$reviewed" -eq 0 ] || rows=0
  since=$((rows + waiting))
  if [ "$since" -ge 5 ]; then
    echo "due: $since changes merged since the last periodic review"
    return 0
  fi
  echo "not due: $since of 5 changes merged since the last periodic review, and no sensitive area touched"
  return 1
}

# Whether the queue needs the planner before the change starts: needed
# when the change is not the first item of docs/queue.md, or when another
# merged change without a history row holds a note of a PLAN_NOTES kind
# (a retrospective proposal, an overrun, a periodic finding) that only the
# planner places; otherwise the head item is taken as written, its size
# printed for the run's estimate. It prints one line: a run whose brief is
# only the change name has its agents read the item in docs/queue.md.
plan_needed() {
  head_item=$(sed -n 's/^1[.] //p' docs/queue.md 2>/dev/null | head -1)
  name=$(printf '%s\n' "$head_item" | sed -n 's/^`\([a-z0-9][a-z0-9-]*\)`.*/\1/p')
  if [ "$name" != "$change" ]; then
    echo "needed: $change is not the head of docs/queue.md (${name:-no named item})"
    return 0
  fi
  for other in $(pending_list); do
    [ "$other" != "$change" ] || continue
    n=$(change=$other; grep -c -E "^  \"note[.][0-9]+\": \"($PLAN_NOTES) " "$(state_file)")
    if [ "$n" -gt 0 ]; then
      echo "needed: $other holds $n proposal(s) or finding(s) to place"
      return 0
    fi
  done
  size=$(printf '%s\n' "$head_item" | awk 'match($0, /estimated (small|medium|large)/) { print substr($0, RSTART + 10, RLENGTH - 10) }')
  echo "not needed: $change heads docs/queue.md, estimated ${size:--}, and no pending change holds a proposal or finding"
  return 1
}

# True when COMMIT is 7 to 40 hexadecimal digits naming a commit that is
# an ancestor of HEAD, or of the base (BASE, origin/main), where the merged
# phases' squash commits are.
supported() {
  valid '[0-9a-f]{7,40}' "$1" || return 1
  full=$(git rev-parse --verify -q --end-of-options "$1^{commit}" 2>/dev/null) || return 1
  git merge-base --is-ancestor "$full" HEAD 2>/dev/null && return 0
  [ -n "$base_commit" ] && git merge-base --is-ancestor "$full" "$base_commit" 2>/dev/null
}

# The state as a resume may trust it: one flat object of the lines
# write_key writes, leaving out each phase.*, review.*, and merged record
# whose commit git does not support, any line not in write_key's form (a
# control character, an escape other than \" and \\, a key outside
# [a-z0-9_.-]), and a key already seen, then "untrusted", the keys left out.
trusted_state() {
  file=$(state_file)
  [ -f "$file" ] || die "no run state for $change"
  base_commit=$(git rev-parse --verify -q --end-of-options "${BASE:-origin/main}^{commit}" 2>/dev/null)
  drop=" "
  names=""
  listing=$(C=" $(LC_ALL=C grep -n '[[:cntrl:]]' "$file" | cut -d: -f1 | tr '\n' ' ')" awk '
    $0 == "{" || $0 == "}" { next }
    {
      key = $0; sub(/^  "/, "", key); sub(/".*/, "", key); gsub(/[^a-z0-9_.-]/, "?", key)
      if (key == "") key = "?"
      if (index(ENVIRON["C"], " " NR " ")) { print NR, key, "bad", "-"; next }
      if ($0 !~ /^  "[a-z0-9][a-z0-9_.-]*": "([^"\\]|\\["\\])*",?$/) { print NR, key, "bad", "-"; next }
      if (seen[key]++) { print NR, key, "bad", "-"; next }
      if (key == "untrusted") { print NR, key, "skip", "-"; next }
      if (key !~ /^(phase|review)[.]/ && key != "merged") next
      value = $0; sub(/^  "[^"]*": "/, "", value); sub(/",?$/, "", value)
      if (key ~ /^review[.]/) { split(value, word, " "); value = word[2] }
      gsub(/[^0-9a-zA-Z]/, "?", value)
      print NR, key, "record", (value == "" ? "-" : value)
    }' "$file")
  while read -r n key kind commit; do
    case "$kind" in
      bad) drop="$drop$n "; names="${names:+$names }$key" ;;
      skip) drop="$drop$n " ;;
      record) supported "$commit" || { drop="$drop$n "; names="${names:+$names }$key"; } ;;
    esac
  done <<EOF_LIST
$listing
EOF_LIST
  D="$drop" U="$names" awk '
    $0 == "{" || $0 == "}" { next }
    index(ENVIRON["D"], " " NR " ") == 0 { line = $0; sub(/,$/, "", line); lines[n++] = line }
    END {
      if (ENVIRON["U"] != "") lines[n++] = "  \"untrusted\": \"" ENVIRON["U"] "\""
      print "{"
      for (i = 0; i < n; i++) print lines[i] (i < n - 1 ? "," : "")
      print "}"
    }' "$file"
}

usage() {
  sed -n '/^# Usage:/,/^# Environment:/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

[ $# -ge 1 ] || usage
command=$1
shift
case "$command" in
  status) show_status; exit 0 ;;
  pending) pending_list; exit 0 ;;
  history) append_history; exit 0 ;;
  restore)
    [ $# -eq 1 ] || usage
    restore_branch "$1"
    exit $? ;;
esac
[ $# -ge 1 ] || usage
change=$1
shift
case "$change" in
  ""|*/*|.*|*[[:cntrl:]]*) die "not a change name: $change" ;;
esac

case "$command" in
  init)
    [ $# -eq 1 ] || usage
    mkdir -p "$state_dir"
    if [ -f "$(state_file)" ]; then
      echo "run_state: resuming $change" >&2
    else
      plain "$1" "the branch"
      repo=$(git remote get-url origin 2>/dev/null | sed -E 's#^.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##')
      plain "$repo" "the remote's name"
      printf '{\n  "change": "%s",\n  "branch": "%s",\n  "repo": "%s",\n  "pushes": "0",\n  "ci_fixes": "0"\n}\n' \
        "$(escape "$change")" "$(escape "$1")" "$(escape "$repo")" > "$(state_file)"
    fi
    cat "$(state_file)" ;;
  show)
    [ -f "$(state_file)" ] || die "no run state for $change"
    cat "$(state_file)" ;;
  trusted)
    [ $# -eq 0 ] || usage
    trusted_state ;;
  get)
    [ $# -eq 1 ] || usage
    read_key "$1" ;;
  set)
    [ $# -eq 2 ] || usage
    case "$1" in
      review.*|phase.*|stage.*|gated) die "set: refused: $1 is written only by its own command (review, phase, stage, check, gated)" ;;
      merged|pushed) valid '[0-9a-f]{7,40}' "$2" || die "set: refused: $1 is a commit hash of 7 to 40 hexadecimal digits, not $2" ;;
    esac
    write_key "$1" "$2"
    # The run merged: its backup has no use left.
    [ "$1" != merged ] || drop_backup "$(read_key branch)" set || true ;;
  abandon)
    [ $# -eq 0 ] || usage
    [ -f "$(state_file)" ] || die "no run state for $change"
    branch=$(read_key branch)
    drop_backup "$branch" abandon || exit 1
    echo "abandon: no backup of $branch is left on origin" ;;
  phase)
    [ $# -eq 1 ] || [ $# -eq 2 ] || usage
    one_of "$1" "$PHASES" || die "phase: not a phase: $1 (one of $PHASES)"
    at=$(commit_at "${2:-}") || exit 1
    write_key "phase.$1" "$at" ;;
  review)
    [ $# -eq 3 ] || [ $# -eq 4 ] || usage
    one_of "$1" "$REVIEW_KINDS" || die "review: not a review kind: $1 (one of $REVIEW_KINDS)"
    case "$1:$2" in *:pass|*:blocked|periodic-*:partial|periodic-*:not-run) ;;
      periodic-*) die "review result is pass, blocked, partial, or not-run, not $2" ;;
      *) die "review result is pass or blocked, not $2" ;; esac
    at=$(commit_at "${4:-}") || exit 1
    write_key "review.$1" "$2 $at $3"
    [ "$2" != pass ] || write_key "phase.$1" "$at" ;;
  stage)
    [ $# -ge 2 ] || usage
    plain_key "stage.$1"
    run_stage "$@" ;;
  scope)
    [ $# -ge 1 ] || usage
    fix_scope "$@" ;;
  check)
    [ $# -le 1 ] || usage
    backed=""
    [ $# -eq 0 ] || backed=$(commit_at "$1") || exit 1
    check_wait "$backed" ;;
  check-run)
    [ $# -le 1 ] || usage
    check_run "${1:-}" ;;
  bench)
    [ $# -eq 0 ] || usage
    bench_compare ;;
  gated)
    [ $# -eq 1 ] || usage
    case "$1" in
      clear) gated_clear ;;
      pass) write_key gated "$(git rev-parse HEAD)" ;;
      *) usage ;;
    esac ;;
  push)
    push_branch "${1:-}" ;;
  backup)
    [ $# -eq 0 ] || usage
    backup_branch ;;
  metric)
    [ $# -ge 1 ] || usage
    for pair in "$@"; do record_metric "$pair"; done ;;
  metrics)
    [ $# -eq 1 ] || usage
    import_metrics "$1" ;;
  note)
    [ $# -eq 2 ] || usage
    add_note "$1" "$2" ;;
  budget)
    [ $# -eq 0 ] || usage
    budget_line ;;
  spent)
    [ $# -eq 0 ] || usage
    spent_line ;;
  usage)
    [ $# -eq 2 ] || usage
    add_usage "$1" "$2" ;;
  plan-needed)
    [ $# -eq 0 ] || usage
    plan_needed ;;
  review-due)
    [ $# -eq 0 ] || usage
    review_due ;;
  *)
    usage ;;
esac
