#!/bin/sh
# The run state of one change in the delivery pipeline, and the one writer
# of it and of the stage logs (.claude/workflows/deliver-change.js).
#
# State: build/pipeline/CHANGE.json, one flat JSON object of string values,
# one key per line, rewritten through a temporary file and a rename:
#   change, branch   the change, its branch, and repo, the GitHub owner/name
#   phase.NAME       the commit the phase finished at
#   stage.NAME       "EXIT SECONDSs COMMIT UTC-TIME" of the last run, with
#                    "carried-from-COMMIT" when check carried it (below)
#   review.KIND      "pass|blocked COMMIT SUMMARY" (security, quality, bench,
#                    and periodic-security and periodic-quality after a merge)
#   pushes, ci_fixes the pushes made and the CI fixes they may answer
#   gates_failed     the push attempts the pre-push gates refused
#   pushed, pr, ci   the last pushed commit, the pull request number, and
#                    "green|red COMMIT"
#   merged           the squash commit on main
#   metric.NAME      one measurement or figure of the run: tools/metrics.sh
#                    names, rework, ci_min, estimate (the plan's size), phase.KEY
#                    ("TOKENS/CALLS" of a phase so far), first.GATE (0 or 1,
#                    its first verdict), extra (fix rounds granted beyond
#                    three), stop (rounds when a start stopped at the
#                    limit, else none), and planned (0 when the planner was
#                    skipped), stored by the workflow, every figure in each
#                    metric line it runs; total_tokens and wall_min, summed
#                    over the starts by usage; older runs stored
#                    first_pass, out_tokens, tool_calls, phases
#   note.N           "KIND TEXT": a retrospective proposal or a finding
# Logs: build/stages/CHANGE/STAGE.log, ending in "EXIT n".
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
#   set CHANGE KEY VALUE        write one value; refuses review.*, phase.*,
#                               and stage.*, which their own commands write,
#                               and a merged or pushed value but a commit hash
# Every write refuses a key outside [a-z0-9_.-] and a key or value holding a
# control character (newline, carriage return, tab, or another), so no write
# adds a line of its own.
#   phase CHANGE NAME [COMMIT]  record the phase (one of PHASES) done at
#                               COMMIT, HEAD when omitted
#   review CHANGE KIND RESULT SUMMARY [COMMIT]
#                               record a review (KIND one of REVIEW_KINDS,
#                               RESULT pass or blocked) at COMMIT, HEAD when
#                               omitted; a pass also records phase.KIND
# The delivery workflow, not its agents, runs phase and review: it builds
# them from the results it received (tools/agent_guard.sh keeps the agents
# off them, and the merge gate compares them with RECORDS).
#   stage CHANGE NAME CMD...    run CMD with its log and record its result
#   check CHANGE [COMMIT]       run the canonical stages (make -s stages) in
#                               order, stop at the first failure, record
#                               phase.check when all pass; a stage record
#                               counts only at COMMIT, the last check the
#                               workflow recorded, or carried from it: skipped
#                               when COMMIT is HEAD, carried to HEAD for a
#                               stage outside TEST_STAGES when only tests
#                               changed since COMMIT
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
#                               the branch with upstream tracking, and count it
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
#                               ..." with the head item's size and exit 1;
#                               when the change is the head, then print
#                               "item: TEXT", the item as written
#   budget CHANGE               print "over:", "within:", "unmeasured:", or
#                               "no estimate:" with the change's estimate, its
#                               budget (TOKEN_BUDGETS, MINUTE_BUDGETS), its
#                               total tokens and wall minutes, and its output
#                               tokens
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
# (build/metrics/current.tsv).
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
# The gates of a history row's first passes, in order, before gates.
GATES="check quality security bench ci"
REVIEW_KINDS="security quality bench periodic-security periodic-quality"
# The total-token budget (input plus output) of each size a queue item is
# estimated at, and the wall-minute budget of the sizes that have one, as
# docs/goals.md gives them.
TOKEN_BUDGETS="small=500000 medium=1200000 large=2500000"
MINUTE_BUDGETS="small=25"
# The note kinds of a pending change that the planner places: retrospective
# proposals, overruns, and periodic review findings.
PLAN_NOTES='retro|overrun|security|quality'
TAB=$(printf '\t')
# Columns 16 and 17 came after estimate, so rates ($5, $6) and review_due
# ($14) read the same columns in every row.
HEADER="change${TAB}date${TAB}merged${TAB}pr${TAB}rework${TAB}first_pass${TAB}ci_min${TAB}rounds${TAB}allocs${TAB}us_per_key${TAB}out_tokens${TAB}tool_calls${TAB}phases${TAB}review${TAB}estimate${TAB}total_tokens${TAB}wall_min"
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

run_stage() {
  name=$1
  shift
  dir=$stage_dir/$change
  mkdir -p "$dir"
  log=$dir/$name.log
  start=$(date +%s)
  "$@" > "$log" 2>&1
  status=$?
  secs=$(( $(date +%s) - start ))
  echo "EXIT $status" >> "$log"
  write_key "stage.$name" "$status ${secs}s $(head_commit) $(utc_now)"
  echo "stage $name: exit $status in ${secs}s, log $log"
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
check_stages() {
  stages=${STAGES:-$("$make_cmd" -s --no-print-directory stages)}
  head=$(head_commit)
  backed=$1
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
    run_stage "$s" "$make_cmd" --no-print-directory check-stage "S=$s" ||
      die "check: stage $s failed at $head; read $stage_dir/$change/$s.log"
  done
  # The workflow records phase.check from the checker's result too; the
  # merge's records gate compares this one with it.
  write_key "phase.check" "$head"
  echo "check: every stage passed at $head"
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
  write_key pushed "$(head_commit)"
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
  if [ "$1" = quality-advisory ]; then
    text=$(escape "$2" | sed -E 's/^[0-9a-f]{7,40} //')
    if keys_under note. | T="$text" awk '
        { sub(/^[0-9]+=/, "") }
        sub(/^quality-advisory /, "") { sub(/^[0-9a-f]+ /, ""); if ($0 == ENVIRON["T"]) found = 1 }
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
  minutes=$(value metric.wall_min)
  actual="actual $total total tokens in $minutes minutes, $(out_tokens) output tokens"
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
    echo "within: estimated $size, $budget, $actual"
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
  printf '%s\n' "$(value metric.wall_min)"
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
  [ ! -f "$metrics_file" ] || rows=$(awk -F'\t' 'NR > 1 { n = ($14 == "-" || $14 == "") ? n + 1 : 0 } END { print n + 0 }' "$metrics_file")
  waiting=0
  reviewed=0
  for name in $(pending_list); do
    if [ -n "$(change=$name; read_key review.periodic-security)" ]; then reviewed=1
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
# printed for the run's estimate. When the change heads the queue a second
# line, "item: TEXT", gives the item as written, the brief of a run whose
# brief is only the change name.
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
      printf 'item: %s\n' "$head_item"
      return 0
    fi
  done
  size=$(printf '%s\n' "$head_item" | awk 'match($0, /estimated (small|medium|large)/) { print substr($0, RSTART + 10, RLENGTH - 10) }')
  echo "not needed: $change heads docs/queue.md, estimated ${size:--}, and no pending change holds a proposal or finding"
  printf 'item: %s\n' "$head_item"
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
      review.*|phase.*|stage.*) die "set: refused: $1 is written only by its own command (review, phase, stage, check)" ;;
      merged|pushed) valid '[0-9a-f]{7,40}' "$2" || die "set: refused: $1 is a commit hash of 7 to 40 hexadecimal digits, not $2" ;;
    esac
    write_key "$1" "$2" ;;
  phase)
    [ $# -eq 1 ] || [ $# -eq 2 ] || usage
    one_of "$1" "$PHASES" || die "phase: not a phase: $1 (one of $PHASES)"
    at=$(commit_at "${2:-}") || exit 1
    write_key "phase.$1" "$at" ;;
  review)
    [ $# -eq 3 ] || [ $# -eq 4 ] || usage
    one_of "$1" "$REVIEW_KINDS" || die "review: not a review kind: $1 (one of $REVIEW_KINDS)"
    case "$2" in pass|blocked) ;; *) die "review result is pass or blocked, not $2" ;; esac
    at=$(commit_at "${4:-}") || exit 1
    write_key "review.$1" "$2 $at $3"
    [ "$2" = blocked ] || write_key "phase.$1" "$at" ;;
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
    check_stages "$backed" ;;
  bench)
    [ $# -eq 0 ] || usage
    bench_compare ;;
  push)
    push_branch "${1:-}" ;;
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
