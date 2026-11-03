#!/bin/sh
# The run state of one change in the delivery pipeline, and the one writer
# of it and of the stage logs (.claude/workflows/deliver-change.js).
#
# State: build/pipeline/CHANGE.json, one flat JSON object of string values,
# one key per line, rewritten through a temporary file and a rename:
#   change, branch   the change, its branch, and repo, the GitHub owner/name
#   phase.NAME       the commit the phase finished at
#   stage.NAME       "EXIT SECONDSs COMMIT UTC-TIME" of the last run
#   review.KIND      "pass|blocked COMMIT SUMMARY" (security, quality, bench,
#                    and periodic-security and periodic-quality after a merge)
#   pushes, ci_fixes the pushes made and the CI fixes they may answer
#   gates_failed     the push attempts the pre-push gates refused
#   pushed, pr, ci   the last pushed commit, the pull request number, and
#                    "green|red COMMIT"
#   merged           the squash commit on main
#   metric.NAME      one measurement or figure of the run (tools/metrics.sh
#                    names, rework, first_pass, ci_min, out_tokens,
#                    tool_calls, phases)
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
#   set CHANGE KEY VALUE        write one value
#   phase CHANGE NAME           record the phase done at HEAD
#   review CHANGE KIND RESULT SUMMARY
#                               record a review (RESULT pass or blocked) at
#                               HEAD; a pass also records phase.KIND
#   stage CHANGE NAME CMD...    run CMD with its log and record its result
#   check CHANGE                run the canonical stages (make -s stages) in
#                               order, skip a stage passed at HEAD, stop at the
#                               first failure, record phase.check when all pass
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
#   history                     append a history row for each pending change
#   status                      the queue, the running change, the last metrics
#                               row, and the first-pass rates of the history
#
# Environment: RUN_STATE_DIR (build/pipeline), STAGE_DIR (build/stages),
# STAGES (the stage list; make -s stages when unset), MAKE (make),
# METRICS_FILE (docs/metrics.tsv).
set -u

here=$(cd "$(dirname "$0")" && pwd)
state_dir=${RUN_STATE_DIR:-build/pipeline}
stage_dir=${STAGE_DIR:-build/stages}
make_cmd=${MAKE:-make}
metrics_file=${METRICS_FILE:-docs/metrics.tsv}
PHASES="plan implement check quality security bench package ci merge retro report"
TAB=$(printf '\t')
HEADER="change${TAB}date${TAB}merged${TAB}pr${TAB}rework${TAB}first_pass${TAB}ci_min${TAB}rounds${TAB}allocs${TAB}us_per_key${TAB}out_tokens${TAB}tool_calls${TAB}phases${TAB}review"
# The areas whose change makes a periodic review of the whole codebase due,
# one "label=path pattern" per line, the first match named.
REVIEW_AREAS='config loading=^(config/|carat/(adapters/rc_config_gateway|ports/config_port|domain/(config|default_config|manifest_check|rc_[a-z_]+))[.]rb$)
file access=^carat/(drivers/disk_files[.]rb|ports/file_port[.]rb|domain/path_(policy|info)[.]rb|use_cases/files/)
plugin boundaries=^carat/(plugin_api[.]rb|plugins/|use_cases/plugins/)
terminal output=^carat/(drivers/ansi_terminal|ports/terminal_port|adapters/(screen_presenter|frame_presenter|painted_rows|sgr_table|key_decoder))[.]rb$
process spawning=^carat/drivers/'

die() {
  echo "run_state: $*" >&2
  exit 1
}

head_commit() {
  git rev-parse --short=12 HEAD
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

check_stages() {
  stages=${STAGES:-$("$make_cmd" -s --no-print-directory stages)}
  head=$(head_commit)
  for s in $stages; do
    record=$(read_key "stage.$s")
    case "$record" in
      "0 "*)
        if [ "$(echo "$record" | cut -d' ' -f3)" = "$head" ]; then
          echo "stage $s: passed at $head, skipped"
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

# metric.PREFIX.* of the run state as "suffix=value,...", "-" when none.
group() {
  P="metric.$1." awk '
    /^  "/ {
      key = $0; sub(/^  "/, "", key); sub(/".*/, "", key)
      if (index(key, ENVIRON["P"]) != 1) next
      value = $0; sub(/^  "[^"]*": "/, "", value); sub(/",?$/, "", value)
      out = out (out == "" ? "" : ",") substr(key, length(ENVIRON["P"]) + 1) "=" value
    }
    END { print (out == "" ? "-" : out) }' "$(state_file)"
}

value() {
  v=$(read_key "$1")
  echo "${v:--}"
}

history_row() {
  merged=$(read_key merged)
  date=$(git log -1 --format=%cs "$merged" 2>/dev/null)
  first=$(read_key metric.first_pass)
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
    "$(value metric.out_tokens)" "$(value metric.tool_calls)" "$(value metric.phases)"
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
    write_key "$1" "$2" ;;
  phase)
    [ $# -eq 1 ] || usage
    write_key "phase.$1" "$(head_commit)" ;;
  review)
    [ $# -eq 3 ] || usage
    case "$2" in pass|blocked) ;; *) die "review result is pass or blocked, not $2" ;; esac
    write_key "review.$1" "$2 $(head_commit) $3"
    [ "$2" = blocked ] || write_key "phase.$1" "$(head_commit)" ;;
  stage)
    [ $# -ge 2 ] || usage
    run_stage "$@" ;;
  check)
    [ $# -eq 0 ] || usage
    check_stages ;;
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
