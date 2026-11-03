# The forbidden content of CLAUDE.md's hard rules as patterns, and scan,
# which reports every match in "LABEL<TAB>TEXT" lines. Sourced by
# tools/gates.sh (the content and pr-body gates) and tools/docs_lint.sh;
# the sourcing script defines bad(), which prints a failure and records it,
# and TAB.

# The patterns are written so that this file does not match them.
URL_RE='[a-z][a-z0-9+.-]*://|www\.|claude[.]ai/'
EMAIL_RE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
SESSION_RE='session_[A-Za-z0-9]{16,}'
TIERS="hai""ku|son""net|op""us"
MODEL_RE="(^|[^a-z])($TIERS)([^a-z]|$)|clau""de-[0-9a-z.-]*[0-9]|gp""t-[0-9]|gem""ini"
# The one place a model name may appear: an agent's frontmatter line naming
# a short tier alias.
MODEL_LINE_RE="^\.claude/agents/[^/]*\.md${TAB}model: ($TIERS|inherit)\$"

# Lines "LABEL<TAB>TEXT" in the argument; reports every forbidden match.
# An argument, not standard input: the last command of a pipeline runs in a
# subshell, where a failure would not reach the exit status.
scan() {
  lines=$1
  hits=$(printf '%s\n' "$lines" | grep -i -E "$URL_RE" |
    grep -v -E "^Makefile${TAB}.*git -C .* remote add origin ")
  [ -z "$hits" ] || bad "a URL (only the toolchain target's clone address may hold one):
$hits"
  hits=$(printf '%s\n' "$lines" | sed 's/noreply@anthropic\.com//g' | grep -E "$EMAIL_RE")
  [ -z "$hits" ] || bad "an email address (only the trailer's is allowed):
$hits"
  hits=$(printf '%s\n' "$lines" | grep -E "$SESSION_RE")
  [ -z "$hits" ] || bad "a session id:
$hits"
  hits=$(printf '%s\n' "$lines" | grep -i -E "$MODEL_RE" | grep -v -E "$MODEL_LINE_RE")
  [ -z "$hits" ] || bad "a model name (only an agent's frontmatter tier alias is allowed):
$hits"
}
