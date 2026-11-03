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
#                    names, rework, ci_min, phase.KEY ("TOKENS/CALLS" of a
#                    phase so far), and first.GATE (0 or 1, its first
#                    verdict), stored by the workflow as they happen; older
#                    runs stored first_pass, out_tokens, tool_calls, phases
#   note.N           "KIND TEXT": a retrospective proposal or a finding
# Logs: build/stages/CHANGE/STAGE.log, ending in "EXIT n".
#
# History: docs/metrics.tsv, one row per merged change, appended by history
# from the run states that have none yet, so the next change carries the
# rows of the runs before it (columns in HEADER below).
#
# Usage: sh tools/run_state.sh COMMAND ...
#   init CHANGE BRANCH          create the state unless it exists, then show it
#   show CHANGE                 print the state
#   get CHANGE KEY              print one value, empty when absent
#   set CHANGE KEY VALUE        write one value; refuses review.*, phase.*,
#                               and stage.*, which their own commands write
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
#   check CHANGE                run the canonical stages (make -s stages) in
#                               order, skip a stage passed at HEAD, stop at the
#                               first failure, record phase.check when all pass;
#                               a stage outside TEST_STAGES that passed at a
#                               commit since which only tests changed is
#                               carried to HEAD instead of run
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
#   note CHANGE KIND TEXT       record note.N, the next number, as "KIND TEXT"
#   review-due CHANGE           print "due: REASON" and exit 0 when the merged
#                               change touched a sensitive area or five changes
#                               merged since the last periodic review; print
#                               "not due: ..." and exit 1 otherwise
#   pending                     the merged changes with no history row yet
#   history                     append a history row for each pending change;
#                               a gate without a stored first verdict is
#                               left out of its first passes
#   status                      the queue, the running change, the last metrics
#                               row, and the first-pass rates of the history
#
# Environment: RUN_STATE_DIR (build/pipeline), STAGE_DIR (build/stages),
# STAGES (the stage list; make -s stages when unset), MAKE (make),
# METRICS_FILE (docs/metrics.tsv), METRICS_OUT (build/metrics/current.tsv).
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
TAB=$(printf '\t')
HEADER="change${TAB}date${TAB}merged${TAB}pr${TAB}rework${TAB}first_pass${TAB}ci_min${TAB}rounds${TAB}allocs${TAB}us_per_key${TAB}out_tokens${TAB}tool_calls${TAB}phases${TAB}review"
# The areas whose change makes a periodic review of the whole codebase due,
# one "label=path pattern" per line, the first match named.
REVIEW_AREAS='config loading=^(config/|carat/(adapters/rc_config_gateway|ports/config_port|domain/(config|default_config|manifest_check|rc_[a-z_]+))[.]rb$)
file access=^carat/(drivers/disk_files[.]rb|ports/file_port[.]rb|domain/path_(policy|info)[.]rb|use_cases/files/)
plugin boundaries=^carat/(plugin_api[.]rb|plugins/|use_cases/plugins/)
terminal output=^carat/(drivers/ansi_terminal|ports/terminal_port|adapters/(screen_presenter|frame_presenter|painted_rows|sgr_table|key_decoder)|domain/(frame|display_width|utf8|decoded_line))[.]rb$
process spawning=^carat/drivers/'

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

# One line of the state for a key and a value, escaped for JSON.
escape() {
  printf '%s' "$1" | tr '\n\t' '  ' | sed 's/\\/\\\\/g; s/"/\\"/g'
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

check_stages() {
  stages=${STAGES:-$("$make_cmd" -s --no-print-directory stages)}
  head=$(head_commit)
  for s in $stages; do
    record=$(read_key "stage.$s")
    case "$record" in
      "0 "*)
        at=$(echo "$record" | cut -d' ' -f3)
        if [ "$at" = "$head" ]; then
          echo "stage $s: passed at $head, skipped"
          continue
        fi
        # A stage that reads no test program keeps its result across a
        # commit that changes only tests.
        if ! one_of "$s" "$TEST_STAGES" && tests_only_since "$at"; then
          write_key "stage.$s" "0 0s $head $(utc_now) carried-from-$at"
          echo "stage $s: passed at $at, carried to $head (only tests changed since)"
          continue
        fi ;;
    esac
    run_stage "$s" "$make_cmd" --no-print-directory check-stage "S=$s" ||
      die "check: stage $s failed at $head; read $stage_dir/$change/$s.log"
  done
  write_key "phase.check" "$head"
  echo "check: every stage passed at $head"
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

valid() {
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

# The newest merged change without a history row, by its squash commit's
# time; nothing when none is pending.
newest_pending() {
  for name in $(pending_list); do
    merged=$(change=$name; read_key merged)
    printf '%s %s\n' "$(git log -1 --format=%ct "$merged" 2>/dev/null || echo 0)" "$name"
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
  n=$(($(grep -c '^  "note[.]' "$(state_file)") + 1))
  write_key "note.$n" "$1 $2"
}

has_row() {
  [ -f "$metrics_file" ] && awk -F'\t' -v c="$1" 'NR > 1 && $1 == c { found = 1 } END { exit !found }' "$metrics_file"
}

# The merged changes whose run state has no history row, one per line.
pending_list() {
  for file in "$state_dir"/*.json; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .json)
    [ -n "$(change=$name; read_key merged)" ] || continue
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

history_row() {
  merged=$(read_key merged)
  date=$(git log -1 --format=%cs "$merged" 2>/dev/null)
  first=""
  for g in $GATES; do
    v=$(first_of "$g")
    [ -z "$v" ] || first="${first:+$first,}$g:$v"
  done
  phases=$(group phase)
  if [ "$phases" = "-" ]; then
    phases=$(value metric.phases)
    tokens=$(value metric.out_tokens)
    calls=$(value metric.tool_calls)
  else
    tokens=$(keys_under metric.phase. | awk -F'[=/]' '{ n += $2 } END { print n + 0 }')
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
  printf '%s\t' "$change" "${date:--}" "$merged" "$(value pr)" "$(value metric.rework)" "${first:--}" \
    "$(value metric.ci_min)" "$(group rounds)" "$(group allocs)" "$(group us)" \
    "$tokens" "$calls" "$phases"
  printf '%s\n' "$review"
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

review_due() {
  merged=$(read_key merged)
  [ -n "$merged" ] || die "review-due: $change is not merged"
  paths=$(git diff --name-only "$merged~1" "$merged" 2>/dev/null)
  area=$(printf '%s\n' "$REVIEW_AREAS" | while IFS='=' read -r label pattern; do
    hit=$(printf '%s\n' "$paths" | grep -E -m 1 "$pattern")
    if [ -n "$hit" ]; then echo "$label ($hit)"; break; fi
  done)
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
  ""|*/*|.*) die "not a change name: $change" ;;
esac

case "$command" in
  init)
    [ $# -eq 1 ] || usage
    mkdir -p "$state_dir"
    if [ -f "$(state_file)" ]; then
      echo "run_state: resuming $change" >&2
    else
      repo=$(git remote get-url origin 2>/dev/null | sed -E 's#^.*[:/]([^/]+/[^/]+)$#\1#; s#\.git$##')
      printf '{\n  "change": "%s",\n  "branch": "%s",\n  "repo": "%s",\n  "pushes": "0",\n  "ci_fixes": "0"\n}\n' \
        "$(escape "$change")" "$(escape "$1")" "$(escape "$repo")" > "$(state_file)"
    fi
    cat "$(state_file)" ;;
  show)
    [ -f "$(state_file)" ] || die "no run state for $change"
    cat "$(state_file)" ;;
  get)
    [ $# -eq 1 ] || usage
    read_key "$1" ;;
  set)
    [ $# -eq 2 ] || usage
    case "$1" in
      review.*|phase.*|stage.*) die "set: refused: $1 is written only by its own command (review, phase, stage, check)" ;;
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
    run_stage "$@" ;;
  check)
    [ $# -eq 0 ] || usage
    check_stages ;;
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
  review-due)
    [ $# -eq 0 ] || usage
    review_due ;;
  *)
    usage ;;
esac
