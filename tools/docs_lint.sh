#!/bin/sh
# The documents' size and quality gate (make docs-lint, a stage of make
# check): the documents an agent reads stay within their byte budgets and
# hold no forbidden content, no hard-wrapped pull request text, and no
# backticked repository path that does not exist. Prints "ok   CHECK" or
# "FAIL CHECK: why" lines and exits 1 when any check failed.
#
# Usage: sh tools/docs_lint.sh [ROOT]   (default: this repository)
#   budgets   each file of BUDGETS is at most its bytes
#   content   no URL, no email address but the trailer's, no session id, no
#             model name but an agent's frontmatter tier alias (tools/rules.sh)
#   wraps     the pull request template and CLAUDE.md's example body have no
#             line that continues the line above it, as GitHub would show it
#   paths     a backticked path under a tracked root names a file or directory
#             that exists, unless it holds a placeholder or is on the lane
#             queue item of the change being checked (DOCS_LINT_CHANGE, else
#             the branch name after its type), which names the paths the
#             change removes
#   queue     every numbered item of the lane queues, docs/queue-feature.md
#             and docs/queue-backlog.md, names a tier T0 to T6 and
#             "estimated small", "estimated medium", or "estimated large";
#             the items under a "## Sprint" heading, up to the next "## "
#             heading, are 0 to 3 in the feature lane and 0 to 2 in the
#             backlog lane, at most one of them saying "pipeline" in its
#             parenthesis without T0, and that one a defect, unless a line
#             of that section begins "The user-approved exception"; both
#             files together within QUEUE_BUDGET
#   required  each file of REQUIRED exists (docs/design.md, the binding look)
#   histories every non-blank row of each lane history, docs/metrics-*.tsv,
#             has as many tab-separated fields as its line 1, the header
set -u

here=$(cd "$(dirname "$0")" && pwd)
root=${1:-$(cd "$here/.." && pwd)}
cd "$root" || exit 2
TAB=$(printf '\t')
failed=0
gate=""

# The forbidden-content patterns and scan, shared with tools/gates.sh.
. "$here/rules.sh"

bad() {
  echo "FAIL $gate: $*"
  failed=$((failed + 1))
}

ok() {
  echo "ok   $gate${1:+: $1}"
}

# "PATTERN BYTES" lines: every file the pattern matches is at most BYTES.
# Raising a budget is a reviewed line of this file. The contributor's
# leaves room under the agents' for a new mode.
BUDGETS="CLAUDE.md 30720
.claude/agents/*.md 8192
.claude/agents/contributor.md 6999
docs/architecture.md 88064"
# The two lane queues share one budget, what the planner rewrites and every
# agent may read at a start: the one queue's 17,369 bytes before the lanes
# and 600 for the second file's title and opening line.
QUEUE_BUDGET=17969

# The paths a change retired that the backlog files, the documents keeping
# older entries as they were written, may still name: the one queue and
# history the lanes replaced and the one backlog file docs/backlog/ replaced
# (backlog-per-file). Every other document names the lane files.
RETIRED='docs/queue\.md|docs/metrics\.tsv|docs/backlog\.md'
# The retired path a lane queue may still name until the planner rewrites
# it: the one backlog file, which docs/queue-feature.md names while a
# backlog-lane change may not edit the feature lane's files.
RETIRED_QUEUE='docs/backlog\.md'

# The documents every checkout must hold: docs/design.md is the one binding
# description of the look, which CLAUDE.md and docs/architecture.md name.
REQUIRED="docs/design.md"

# The documents an agent reads; the generated OpenSpec commands are not ours.
documents() {
  for f in CLAUDE.md README.md docs/*.md .claude/agents/*.md .claude/commands/*.md \
    .github/pull_request_template.md; do
    [ -f "$f" ] && echo "$f"
  done
  [ ! -d docs/backlog ] || find docs/backlog -type f -name '*.md' | LC_ALL=C sort
}

check_budgets() {
  gate=budgets
  start=$failed
  report=""
  while read -r pattern limit; do
    for f in $pattern; do
      [ -f "$f" ] || continue
      size=$(wc -c < "$f" | tr -d ' ')
      if [ "$size" -gt "$limit" ]; then
        bad "$f is $size bytes, over its budget of $limit"
      else
        report="$report $f=$size"
      fi
    done
  done <<EOF
$BUDGETS
EOF
  [ $failed -ne $start ] || ok "$(echo "$report" | wc -w | tr -d ' ') file(s) within budget"
}

check_content() {
  gate=content
  start=$failed
  # shellcheck disable=SC2046
  report "$(sh "$here/scan_text.sh" $(documents))"
  [ $failed -ne $start ] || ok "$(documents | wc -l | tr -d ' ') document(s)"
}

# wrapped LABEL: the lines of standard input that follow a non-blank line
# without being a bullet, heading, rule, or comment, each after LABEL and
# its line number.
wrapped() {
  awk -v label="$1" '
    $0 != "" && prev != "" && $0 !~ /^(- |#|---|<!--)/ { print label ":" NR ": " $0 }
    { prev = $0 }'
}

# The example body of CLAUDE.md: the fenced block after "### Example".
example() {
  awk '/^### Example$/ { seen = 1; next }
    seen && /^```$/ { if (on) exit; on = 1; next }
    on { print }' CLAUDE.md
}

check_wraps() {
  gate=wraps
  start=$failed
  hits=$(
    [ ! -f .github/pull_request_template.md ] ||
      wrapped .github/pull_request_template.md < .github/pull_request_template.md
    [ ! -f CLAUDE.md ] || example | wrapped "CLAUDE.md example"
  )
  [ -z "$hits" ] || bad "a hard-wrapped line, which GitHub shows broken; write each paragraph and bullet on one line:
$hits"
  [ $failed -ne $start ] || ok "pull request template and example"
}

# The change being checked: DOCS_LINT_CHANGE, else the current branch
# name after its type (the check clone checks out the branch's name).
own_change() {
  name=${DOCS_LINT_CHANGE:-$(git symbolic-ref -q --short HEAD 2>/dev/null)}
  name=${name#*/}
  printf '%s\n' "$name" | grep -x -E '[a-z0-9][a-z0-9-]*'
}

# The FILE:LINE of each lane queue item naming the change being checked,
# whose paths the change itself removes or moves (lint-own-queue-paths).
own_items() {
  name=$(own_change) || return 0
  for q in docs/queue-feature.md docs/queue-backlog.md; do
    [ -f "$q" ] && grep -n -E "^[0-9]+[.] \`$name\`" "$q" | sed "s|^\([0-9]*\):.*|$q:\1|"
  done
}

check_paths() {
  gate=paths
  start=$failed
  # shellcheck disable=SC2046
  spans=$(grep -n -o '`[^` ]*`' $(documents) | tr -d '`' |
    grep -E ':(carat|bin|test|bench|tools|docs|config|openspec|\.claude|\.github)/' |
    grep -v -E ':.*([<>*${}]|NAME|CHANGE|KIND|\.\.\.)' | grep -v -E "^docs/backlog/[^:]*\.md:[0-9]+:($RETIRED)(:[0-9][0-9,-]*)?\$" |
    grep -v -E "^docs/queue-(feature|backlog)\.md:[0-9]+:($RETIRED_QUEUE)\$")
  own=$(own_items)
  dead=$(printf '%s\n' "$spans" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    [ -z "$own" ] || ! printf '%s\n' "$own" | grep -q -x -F "$(printf '%s\n' "$line" | cut -d: -f1-2)" || continue
    path=${line#*:*:}
    path=$(printf '%s' "$path" | sed -E 's/:[0-9][0-9,-]*$//')
    [ -e "$path" ] || echo "$line"
  done)
  [ -z "$dead" ] || bad "a backticked path that does not exist; fix the path or drop the backticks:
$dead"
  [ $failed -ne $start ] || ok "$(printf '%s\n' "$spans" | grep -c .) path(s) exist"
}

# The items of each lane queue, lines that start with a number and a
# period: each names its tier and its size, as the rubric of docs/goals.md
# asks. A lane's sprint holds at most its share of the sprint of 6 (3 + 3,
# the user's decision of 2026-11-17), the feature lane 3 and the backlog
# lane 3; the sprint, both lanes' sprint
# sections together, holds a pipeline item only for a defect, at most one
# (T0 exempt), unless a line beginning "The user-approved exception" in
# either lifts it; both files within QUEUE_BUDGET.
check_queue() {
  gate=queue
  start=$failed
  total=0
  bytes=0
  sprints=""
  marked=""
  for lane in feature:3 backlog:3; do
    file=docs/queue-${lane%%:*}.md
    [ -f "$file" ] && check_lane "$file" "${lane#*:}"
  done
  pipeline=$(printf '%s\n' "$sprints" | sed -n 's/^[^(]*(\([^)]*\)).*/\1/p' | grep -w pipeline | grep -v -w T0)
  others=$(printf '%s\n' "$pipeline" | grep . | grep -c -v -w defect)
  pipeline=$(printf '%s\n' "$pipeline" | grep -c .)
  # A line beginning "The user-approved exception" lifts the pipeline
  # limits for its sprint; an item line begins with its number instead.
  [ -n "$marked" ] || { [ "$pipeline" -le 1 ] && [ "$others" -eq 0 ]; } ||
    bad "the sprint holds $pipeline pipeline items across both lanes, $others of them no defect; at most 1, a defect (T0 exempt), without a line beginning \"The user-approved exception\""
  [ "$bytes" -le "$QUEUE_BUDGET" ] || bad "the lane queues are $bytes bytes together, over their budget of $QUEUE_BUDGET"
  [ $failed -ne $start ] || ok "$total item(s) with a tier and a size"
}

# One lane file: its tiers, sizes, and sprint share; its sprint items and
# exception lines are added to the sprint's for check_queue.
check_lane() {
  bytes=$((bytes + $(wc -c < "$1")))
  items=$(grep -n -E '^[0-9]+[.] ' "$1")
  untiered=$(printf '%s\n' "$items" | grep . | grep -v -E '(^|[^A-Za-z0-9])T[0-6]([^0-9]|$)' | cut -c1-80)
  unsized=$(printf '%s\n' "$items" | grep . | grep -v -E 'estimated (small|medium|large)' | cut -c1-80)
  [ -z "$untiered" ] || bad "a queue item without a tier T0 to T6:
$untiered"
  [ -z "$unsized" ] || bad "a queue item without \"estimated small\", \"estimated medium\", or \"estimated large\":
$unsized"
  # A drained sprint, every item delivered, waits with 0 items for /sprint.
  sprint=$(awk '/^## / { on = /^## Sprint/; next } on && /^[0-9]+[.] /' "$1")
  if grep -q '^## Sprint' "$1"; then
    count=$(printf '%s\n' "$sprint" | grep -c .)
    [ "$count" -le "$2" ] || bad "$1: the sprint holds $count items, not 0 to $2"
    sprints="$sprints
$sprint"
    marked="$marked$(awk '/^## / { on = /^## Sprint/; next } on && /^The user-approved exception/' "$1")"
  fi
  total=$((total + $(printf '%s\n' "$items" | grep -c .)))
}

# Each lane history's rows against its own header (metrics-header-fix):
# closing-loop's two columns were appended under the 22-column header,
# which history now refuses, and a row of another count is named here.
check_histories() {
  gate=histories
  start=$failed
  files=0
  for f in docs/metrics-*.tsv; do
    [ -f "$f" ] || continue
    files=$((files + 1))
    hits=$(awk -F'\t' -v f="$f" 'NR == 1 { n = NF; next }
      NF && NF != n { print f ":" NR ": " NF " fields, the header " n }' "$f")
    [ -z "$hits" ] || bad "a history row whose field count differs from its header's:
$hits"
  done
  [ $failed -ne $start ] || ok "$files file(s)"
}

check_required() {
  gate=required
  start=$failed
  for f in $REQUIRED; do
    [ -f "$f" ] || bad "$f is missing"
  done
  [ $failed -ne $start ] || ok "$(printf '%s\n' $REQUIRED | grep -c .) file(s)"
}

check_budgets
check_required
check_content
check_wraps
check_paths
check_queue
check_histories
[ "$failed" -eq 0 ]
