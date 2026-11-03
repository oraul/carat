#!/bin/sh
# The run state of one change in the delivery pipeline, and the one writer
# of it and of the stage logs (.claude/workflows/deliver-change.js).
#
# State: build/pipeline/CHANGE.json, one flat JSON object of string values,
# one key per line, rewritten through a temporary file and a rename:
#   change, branch   the change, its branch, and repo, the GitHub owner/name
#   phase.NAME       the commit the phase finished at
#   stage.NAME       "EXIT SECONDSs COMMIT UTC-TIME" of the last run
#   review.KIND      "pass|blocked COMMIT SUMMARY" (security, quality, bench)
#   pushes, ci_fixes the pushes made and the CI fixes they may answer
#   pushed, pr, ci   the last pushed commit, the pull request number, and
#                    "green|red COMMIT"
#   merged           the squash commit on main
# Logs: build/stages/CHANGE/STAGE.log, ending in "EXIT n".
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
#   status                      the queue, the running change, the last metrics
#
# Environment: RUN_STATE_DIR (build/pipeline), STAGE_DIR (build/stages),
# STAGES (the stage list; make -s stages when unset), MAKE (make).
set -u

here=$(cd "$(dirname "$0")" && pwd)
state_dir=${RUN_STATE_DIR:-build/pipeline}
stage_dir=${STAGE_DIR:-build/stages}
make_cmd=${MAKE:-make}
PHASES="implement check quality security bench package ci merge report"

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
  CHANGE=$change sh "$here/gates.sh" pre-push || die "push: refused: the pre-push gates failed"
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
  if [ -f docs/metrics.tsv ]; then
    echo "== last metrics row (docs/metrics.tsv)"
    tail -1 docs/metrics.tsv
  else
    echo "metrics: none (docs/metrics.tsv does not exist)"
  fi
}

usage() {
  sed -n '/^# Usage:/,/^# Environment:/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

[ $# -ge 1 ] || usage
command=$1
shift
if [ "$command" = "status" ]; then
  show_status
  exit 0
fi
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
  *)
    usage ;;
esac
