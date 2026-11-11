#!/bin/sh
# The one scanner of the text CLAUDE.md's hard rules forbid, with the
# patterns of tools/rules.sh: a URL (a scheme followed by ://, a host
# starting with www and a dot, or a bare host and path), an email address,
# a session id, a model name, and a secret. The only exceptions are the
# co-author trailer's address, the Spinel clone address on the Makefile's
# remote add line of the toolchain target, and an agent's frontmatter tier
# alias. Run by the content and pr-body gates (tools/gates.sh), the docs
# lint, and the pull request scan (tools/pr_scan.sh).
#
# Usage: sh tools/scan_text.sh [--diff] [--where NAME] [FILE...]
#   Reads each FILE, or standard input, and prints every hit as
#   "WHERE:LINE: KIND: TEXT", KIND one of url, email, session id, model
#   name, and secret, whose text is never shown (a secret shape inside a
#   shown URL or address is masked too). WHERE is NAME, else the file, else
#   stdin. A URL split where a line wraps is reported at its first line. A
#   file with a NUL byte is not read: "note: WHERE: a binary file, not
#   scanned".
#   --diff: the input is a unified diff (git diff, or git log -p of several
#   commits); only its added lines are scanned, each at its path and new
#   line number, a +++ line read as a path header only before the first
#   hunk of its file, and a binary file's diff noted, not read.
# Exits 1 when anything matched, 2 on a usage error, else 0.
set -u

here=$(cd "$(dirname "$0")" && pwd)
. "$here/rules.sh"
# The co-author trailer's address, the one email allowed.
ADDRESS='noreply@anthropic.com'

usage() {
  sed -n '/^# Usage:/,/^# Exits/p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

diff=0
where=""
while [ $# -gt 0 ]; do
  case "$1" in
    --diff) diff=1; shift ;;
    --where) [ $# -ge 2 ] || usage; where=$2; shift 2 ;;
    --) shift; break ;;
    -?*) usage ;;
    *) break ;;
  esac
done

work=$(mktemp -d "${TMPDIR:-/tmp}/carat-scan.XXXXXX") || exit 2
trap 'rm -rf "$work"' EXIT
: > "$work/rows"
: > "$work/notes"
export URL_RE MODEL_PATH_RE MODEL_LINE_RE

# Rows "FLAG<TAB>WHERE:LINE<TAB>WHERE<TAB>TEXT": l for a line, j for the
# last word of a line joined to the first word of the next, kept only when
# the join is a URL and neither word is.
ROWS='
function emit(path, n, text,    last, first, joined) {
  sub(/\r$/, "", text)
  if (prev_path == path && prev_n == n - 1 && prev_text ~ /[^[:space:]]$/) {
    last = prev_text; sub(/.*[[:space:]]/, "", last)
    first = text; sub(/^[[:space:]]*([#;>*-]+|\/\/)?[[:space:]]*/, "", first); sub(/[[:space:]].*/, "", first)
    joined = last first
    if (first != "" && tolower(joined) ~ url && tolower(last) !~ url && tolower(first) !~ url)
      printf "j\t%s:%d\t%s\t%s\n", path, prev_n, path, joined
  }
  printf "l\t%s:%d\t%s\t%s\n", path, n, path, text
  prev_path = path; prev_n = n; prev_text = text
}
BEGIN { url = ENVIRON["URL_RE"] }
mode == "text" { emit(base, FNR, $0); next }
/^diff --git / { header = 1; path = $0; sub(/^diff --git "?a\/.* "?b\//, "", path); sub(/"$/, "", path); next }
header && /^\+\+\+ / { path = substr($0, 5); sub(/^"/, "", path); sub(/"$/, "", path); sub(/^b\//, "", path); next }
header && (/^Binary files / || /^GIT binary patch/) { print "note: " path ": a binary file, not scanned" > notes; next }
/^@@ / { header = 0; n = $0; sub(/^@@ -[0-9,]* \+/, "", n); sub(/[^0-9].*/, "", n); n += 0; next }
header { next }
/^\+/ { emit(path, n, substr($0, 2)); n++; next }
/^ / { n++ }
'

if [ "$diff" -eq 1 ]; then
  cat "$@" | awk -v mode=diff -v notes="$work/notes" "$ROWS" > "$work/rows" || exit 2
else
  if [ $# -eq 0 ]; then
    cat > "$work/stdin"
    set -- "$work/stdin"
    where=${where:-stdin}
  fi
  for f in "$@"; do
    [ -f "$f" ] || { echo "scan_text: no file $f" >&2; exit 2; }
    name=${where:-$f}
    if [ "$(tr -d '\000' < "$f" | wc -c)" -ne "$(wc -c < "$f")" ]; then
      echo "note: $name: a binary file, not scanned" >> "$work/notes"
      continue
    fi
    awk -v mode=text -v base="$name" -v notes="$work/notes" "$ROWS" "$f" >> "$work/rows" || exit 2
  done
fi

# One text per check: the clone line has no URL, a join row only a URL, a
# URL's user and password no address, an agent's frontmatter tier alias no
# model name.
cut -f2 "$work/rows" > "$work/labels"
awk -v dir="$work" '
  BEGIN { FS = "\t"; line = ENVIRON["MODEL_LINE_RE"]; agents = ENVIRON["MODEL_PATH_RE"] }
  {
    text = $0; sub(/^[^\t]*\t[^\t]*\t[^\t]*\t/, "", text)
    u = text; t = text; m = text
    if ($1 == "j") { t = ""; m = "" }
    a = t; gsub(/:\/\/[^\/@[:space:]]*@/, "://", a)
    if ($3 == "Makefile" && text ~ /git -C .* remote add origin /) u = ""
    if ($3 ~ agents && text ~ line) m = ""
    print u > (dir "/url"); print t > (dir "/text"); print a > (dir "/addr"); print m > (dir "/model")
  }' "$work/rows"

# found KIND FILE PATTERN [GREP-OPTION]: each match as WHERE:LINE: KIND: TEXT.
found() {
  [ -s "$work/$2" ] || return 0
  grep -n -o ${4:+"$4"} -E -e "$3" "$work/$2" | awk -v kind="$1" -v address="$ADDRESS" '
    NR == FNR { label[NR] = $0; next }
    {
      n = $0; sub(/:.*/, "", n); m = $0; sub(/^[0-9]+:/, "", m)
      if (kind == "url") sub(/[.,;:]+$/, "", m)
      if (kind == "model name") { sub(/^[^A-Za-z0-9]+/, "", m); sub(/[^A-Za-z0-9]+$/, "", m) }
      if (kind == "email" && m == address) next
      print label[n] ": " kind ": " m
    }' "$work/labels" -
}

{
  found url url "($URL_RE)[^][:space:]\"'<>()\`[]*" -i
  found email addr "$EMAIL_RE"
  found "session id" addr "$SESSION_RE"
} | sed -E -e "s/$KEY_RE/[secret]/g" -e "s/$TOKEN_RE/\\1[secret]/g" -e 's#(://)[^/@[:space:]]*@#\1[hidden]@#g' > "$work/hits"
found "model name" model "$MODEL_RE" -i >> "$work/hits"
# Only the label: a log, which CI may print, never repeats a secret.
if [ -s "$work/text" ]; then
  { grep -n -E -e "$KEY_RE|$TOKEN_RE" "$work/text"; grep -n -i -E -e "$ASSIGN_RE" "$work/text"; } |
    cut -d: -f1 | sort -n -u | awk '
      NR == FNR { label[NR] = $0; next }
      { print label[$0] ": secret: [not shown]" }' "$work/labels" - >> "$work/hits"
fi

cat "$work/notes" "$work/hits"
[ ! -s "$work/hits" ]
