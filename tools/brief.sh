#!/bin/sh
# The delivery brief of docs/brief-standard.md, built from the change's
# queue item and run state, and the check that refuses an incomplete one.
#   build CHANGE   prints the brief: the header (CHANGE, LANE, BRANCH, BASE),
#                  then WHERE, WHY, OUTCOME, ACCEPTED WHEN, CONSTRAINTS,
#                  OUT OF SCOPE, USER DECISIONS, and RULES, each on a line
#                  of its own. The item is the one numbered line naming the
#                  change in docs/queue-feature.md or docs/queue-backlog.md
#                  (the lane is that queue), cut at its labels: Where, Why,
#                  Outcome (else Fix outline), Accepted when, Constraints,
#                  Out of scope, User decisions, and Backlog (the headings it
#                  covers, appended to OUTCOME). A label an item lacks gets
#                  the standard's default only for CONSTRAINTS, OUT OF SCOPE,
#                  and USER DECISIONS. The branch is the run state's, the
#                  base BASE (default origin/main) at 12 characters. The
#                  brief is checked before it is printed.
#   check [FILE]   reads the brief from FILE (else standard input) and
#                  refuses it, naming each problem, when the header lacks a
#                  field or holds a second CHANGE, a field is missing,
#                  empty, or out of order, WHERE names no path:line, or
#                  ACCEPTED WHEN names no test, snapshot, or case that
#                  fails before.
# Exits 0 for a complete brief, 1 for a refusal, 2 for a usage error.
#
# Usage: sh tools/brief.sh build CHANGE | check [FILE]
set -u

here=$(cd "$(dirname "$0")" && pwd)

die() {
  echo "brief: $*" >&2
  exit 2
}

FIELDS="WHERE WHY OUTCOME ACCEPTED_WHEN CONSTRAINTS OUT_OF_SCOPE USER_DECISIONS RULES"
RULES_TAIL="no agent reads, greps, or opens docs/backlog/ or docs/findings/*.md; a finding this change does not fix is appended to docs/findings/CHANGE.md, none dropped; the pull request is opened by the branch-push Action from pr.md; no URL, address, or model name anywhere; keep to exactly this and name anything extra."

# check_brief: the brief on standard input, one problem per line on standard
# output, nothing when complete.
check_brief() {
  awk '
    BEGIN {
      n = split("WHERE:WHY:OUTCOME:ACCEPTED WHEN:CONSTRAINTS:OUT OF SCOPE:USER DECISIONS:RULES", names, ":")
    }
    /^CHANGE: / && !header { header = 1; head = $0; next }
    /^CHANGE: / { print "a second CHANGE line: one change per brief"; next }
    {
      for (i = 1; i <= n; i++) {
        label = names[i] ":"
        if (index($0, label " ") == 1 || $0 == label) {
          if (seen[i]) { print label " appears twice"; next }
          seen[i] = NR; cur = i
          body[i] = substr($0, length(label) + 2)
          next
        }
      }
      if (cur) body[cur] = body[cur] " " $0
    }
    END {
      if (!header) print "no header line starting CHANGE:"
      else for (k = 1; k <= 4; k++) {
        split("CHANGE LANE BRANCH BASE", hs, " ")
        if (!match(head, hs[k] ": [^ ]")) print "the header lacks " hs[k]
      }
      last = 0
      for (i = 1; i <= n; i++) {
        text = body[i]; gsub(/[ \t]/, "", text)
        if (!seen[i]) { print names[i] " is missing" ; continue }
        if (text == "") print names[i] " is empty"
        if (seen[i] < last) print names[i] " is out of order"
        last = seen[i]
      }
      if (seen[1] && body[1] !~ /[A-Za-z0-9_.\/-]+[.\/][A-Za-z0-9_.\/-]*:[0-9]+/) print "WHERE names no path:line: no WHERE, no start"
      if (seen[4] && !(tolower(body[4]) ~ /(test|snapshot|case)/ && tolower(body[4]) ~ /fail/)) print "ACCEPTED WHEN names no test, snapshot, or case that fails before"
    }'
}

build_brief() {
  change=$1
  case "$change" in
    ""|*[!a-z0-9-]*|-*) die "not a change name: $change" ;;
  esac
  lane=""
  item=""
  for l in feature backlog; do
    [ -f "docs/queue-$l.md" ] || continue
    item=$(C="$change" awk '
      function finish() { if (on) { print text; on = 0; exit } }
      {
        line = $0
        start = sub(/^[0-9]+[.] /, "", line)
      }
      start { finish(); on = index(line, "`" ENVIRON["C"] "` (") == 1; text = line; next }
      !NF || /^#/ { finish(); next }
      on { l = $0; sub(/^[ \t]+/, "", l); text = text " " l }
      END { finish() }' "docs/queue-$l.md")
    [ -z "$item" ] || { lane=$l; break; }
  done
  [ -n "$item" ] || { echo "brief: refused: no item of docs/queue-feature.md or docs/queue-backlog.md names $change" >&2; exit 1; }
  branch=$(sh "$here/run_state.sh" get "$change" branch 2>/dev/null)
  [ -n "$branch" ] || { echo "brief: refused: $change has no run state with a branch (sh tools/run_state.sh init)" >&2; exit 1; }
  base=$(git rev-parse --short=12 "${BASE:-origin/main}" 2>/dev/null) || die "BASE ${BASE:-origin/main} names no commit"
  brief=$(printf '%s\n' "$item" | R="$RULES_TAIL" awk -v change="$change" -v lane="$lane" -v branch="$branch" -v base="$base" '
    {
      text = $0
      n = split("Where|Why:|Outcome:|Fix outline:|Accepted when|Constraints:|Out of scope:|User decisions:|Backlog:", labels, "|")
      cnt = 0
      for (i = 1; i <= n; i++) {
        p = index(text, labels[i])
        if (p) { cnt++; pos[cnt] = p; lab[cnt] = labels[i] }
      }
      for (i = 2; i <= cnt; i++) {
        p = pos[i]; l = lab[i]; j = i - 1
        while (j >= 1 && pos[j] > p) { pos[j + 1] = pos[j]; lab[j + 1] = lab[j]; j-- }
        pos[j + 1] = p; lab[j + 1] = l
      }
      for (i = 1; i <= cnt; i++) {
        stop = (i < cnt) ? pos[i + 1] : length(text) + 1
        body = substr(text, pos[i] + length(lab[i]), stop - pos[i] - length(lab[i]))
        if (lab[i] == "Where" && body ~ /^[ ]*[(:]/) sub(/^[^:]*: */, "", body)
        sub(/^[ :]+/, "", body); sub(/[ ]+$/, "", body)
        sec[lab[i]] = body
      }
      outcome = ("Outcome:" in sec) ? sec["Outcome:"] : sec["Fix outline:"]
      if (sec["Backlog:"] != "") outcome = outcome (outcome == "" ? "" : " ") "Covers the backlog entries: " sec["Backlog:"]
      cons = sec["Constraints:"]; if (cons == "") cons = "only the repository rules that apply; none added"
      oos = sec["Out of scope:"]; if (oos == "") oos = "anything not named in OUTCOME"
      dec = sec["User decisions:"]; if (dec == "") dec = "none"
      rules = ENVIRON["R"]; gsub(/CHANGE/, change, rules)
      print "CHANGE: " change "   LANE: " lane "   BRANCH: " branch "   BASE: " base
      print "WHERE: " sec["Where"]
      print "WHY: " sec["Why:"]
      print "OUTCOME: " outcome
      print "ACCEPTED WHEN: " sec["Accepted when"]
      print "CONSTRAINTS: " cons
      print "OUT OF SCOPE: " oos
      print "USER DECISIONS: " dec
      print "RULES: " rules
    }')
  problems=$(printf '%s\n' "$brief" | check_brief)
  if [ -n "$problems" ]; then
    printf '%s\n' "$problems" | sed 's/^/brief: refused: /' >&2
    exit 1
  fi
  printf '%s\n' "$brief"
}

[ $# -ge 1 ] || die "usage: sh tools/brief.sh build CHANGE | check [FILE]"
cmd=$1
shift
case "$cmd" in
  build)
    [ $# -eq 1 ] || die "usage: sh tools/brief.sh build CHANGE"
    build_brief "$1" ;;
  check)
    [ $# -le 1 ] || die "usage: sh tools/brief.sh check [FILE]"
    if [ $# -eq 1 ] && [ "$1" != "-" ]; then
      [ -f "$1" ] || die "no such file: $1"
      problems=$(check_brief < "$1")
    else
      problems=$(check_brief)
    fi
    if [ -n "$problems" ]; then
      printf '%s\n' "$problems" | sed 's/^/brief: refused: /'
      exit 1
    fi
    echo "brief: complete" ;;
  *) die "usage: sh tools/brief.sh build CHANGE | check [FILE]" ;;
esac
