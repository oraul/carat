# The forbidden content of CLAUDE.md's hard rules as patterns, secrets
# included, and scan, which reports every match in "LABEL<TAB>TEXT" lines
# (a secret by its label only). Sourced by
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
# Secrets: a private key block, the token shapes of common clouds and
# platforms (an AWS access key id, GitHub, GitLab, Slack, Google API, an
# sk- key, Stripe live, npm), matched with their case; and a name ending in
# password, passwd, secret, token, or api_key assigned a quoted literal of
# eight characters or more, matched without case.
KEY_RE='-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY( BLOCK)?-----'
TOKEN_RE='(^|[^A-Za-z0-9])((AKIA|ASIA)[A-Z0-9]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20,}|xox[abeprs]-[A-Za-z0-9-]{10,}|AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9_-]{20,}|[rs]k_live_[A-Za-z0-9]{16,}|npm_[A-Za-z0-9]{36})'
QUOTE="[\"']"
ASSIGN_RE="(password|passwd|secret|token|api_?key)$QUOTE?[[:space:]]*(=|:|=>)[[:space:]]*$QUOTE[^\"'[:space:]]{8,}$QUOTE"

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
  # Only the label: a gate's log, which CI may print, never repeats a secret.
  hits=$({ printf '%s\n' "$lines" | grep -E -e "$KEY_RE|$TOKEN_RE"
    printf '%s\n' "$lines" | grep -i -E -e "$ASSIGN_RE"; } | cut -f1 | sort -u)
  [ -z "$hits" ] || bad "a secret (a private key, a platform token, or a password, secret, token, or API key assigned a literal; the line is not shown) in:
$hits"
}
