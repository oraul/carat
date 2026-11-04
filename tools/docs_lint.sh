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
#             that exists, unless it holds a placeholder
#   queue     every numbered item of docs/queue.md names a tier T0 to T6 and
#             "estimated small", "estimated medium", or "estimated large"
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
# Raising a budget is a reviewed line of this file. The queue's holds what
# the planner rewrites and every agent may read at a start.
BUDGETS="CLAUDE.md 30720
.claude/agents/*.md 8192
docs/architecture.md 88064
docs/queue.md 17369"

# The documents an agent reads; the generated OpenSpec commands are not ours.
documents() {
  for f in CLAUDE.md README.md docs/*.md .claude/agents/*.md .claude/commands/*.md \
    .github/pull_request_template.md; do
    [ -f "$f" ] && echo "$f"
  done
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
  scan "$(awk -v OFS="$TAB" '{ print FILENAME, $0 }' $(documents))"
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

check_paths() {
  gate=paths
  start=$failed
  # shellcheck disable=SC2046
  spans=$(grep -n -o '`[^` ]*`' $(documents) | tr -d '`' |
    grep -E ':(carat|bin|test|bench|tools|docs|config|openspec|\.claude|\.github)/' |
    grep -v -E ':.*([<>*${}]|NAME|CHANGE|KIND|\.\.\.)')
  dead=$(printf '%s\n' "$spans" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    path=${line#*:*:}
    path=$(printf '%s' "$path" | sed -E 's/:[0-9][0-9,-]*$//')
    [ -e "$path" ] || echo "$line"
  done)
  [ -z "$dead" ] || bad "a backticked path that does not exist; fix the path or drop the backticks:
$dead"
  [ $failed -ne $start ] || ok "$(printf '%s\n' "$spans" | grep -c .) path(s) exist"
}

# The queue items, lines that start with a number and a period: each names
# its tier and its size, as the rubric of docs/goals.md asks.
check_queue() {
  gate=queue
  start=$failed
  [ -f docs/queue.md ] || { ok "no docs/queue.md"; return; }
  items=$(grep -n -E '^[0-9]+[.] ' docs/queue.md)
  untiered=$(printf '%s\n' "$items" | grep . | grep -v -E '(^|[^A-Za-z0-9])T[0-6]([^0-9]|$)' | cut -c1-80)
  unsized=$(printf '%s\n' "$items" | grep . | grep -v -E 'estimated (small|medium|large)' | cut -c1-80)
  [ -z "$untiered" ] || bad "a queue item without a tier T0 to T6:
$untiered"
  [ -z "$unsized" ] || bad "a queue item without \"estimated small\", \"estimated medium\", or \"estimated large\":
$unsized"
  [ $failed -ne $start ] || ok "$(printf '%s\n' "$items" | grep -c .) item(s) with a tier and a size"
}

check_budgets
check_content
check_wraps
check_paths
check_queue
[ "$failed" -eq 0 ]
