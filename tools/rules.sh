# The forbidden content of CLAUDE.md's hard rules as patterns, secrets
# included, read by tools/scan_text.sh, the one scanner, which
# tools/gates.sh (the content and pr-body gates), tools/docs_lint.sh, the
# commit hooks of .githooks, and tools/pr_scan.sh run; report, which passes
# the scanner's output to bad() (defined by the sourcing script); and the
# repository configuration and hooks the origin gate refuses.

# The patterns are written so that this file does not match them. A URL is
# a scheme followed by ://, a host starting with www and a dot, or a bare
# host and path: a name ending in a common top-level domain, followed by a
# slash.
URL_RE='[a-z][a-z0-9+.-]*://|www[.]|([a-z0-9-]+[.])+(com|org|net|io|ai|dev|app|gov|edu|co|me|info|xyz)/'
EMAIL_RE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
SESSION_RE='session_[A-Za-z0-9]{16,}'
TIERS="hai""ku|son""net|op""us"
MODEL_RE="(^|[^a-z])($TIERS)([^a-z]|$)|clau""de-[0-9a-z.-]*[0-9]|gp""t-[0-9]|gem""ini"
# The one place a model name may appear: an agent's frontmatter line naming
# a short tier alias.
MODEL_PATH_RE='^\.claude/agents/[^/]*\.md$'
MODEL_LINE_RE="^model: ($TIERS|inherit)\$"
# Secrets: a private key block, the token shapes of common clouds and
# platforms (an AWS access key id, GitHub, GitLab, Slack, Google API, an
# sk- key, Stripe live, npm), matched with their case; and a name ending in
# password, passwd, secret, token, or api_key assigned a quoted literal of
# eight characters or more, matched without case.
KEY_RE='-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY( BLOCK)?-----'
TOKEN_RE='(^|[^A-Za-z0-9])((AKIA|ASIA)[A-Z0-9]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20,}|xox[abeprs]-[A-Za-z0-9-]{10,}|AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9_-]{20,}|[rs]k_live_[A-Za-z0-9]{16,}|npm_[A-Za-z0-9]{36})'
QUOTE="[\"']"
ASSIGN_RE="(password|passwd|secret|token|api_?key)$QUOTE?[[:space:]]*(=|:|=>)[[:space:]]*$QUOTE[^\"'[:space:]]{8,}$QUOTE"

# report OUTPUT: each hit line of tools/scan_text.sh's OUTPUT through bad(),
# each note printed. A here-document, not a pipeline, so bad() runs in this
# shell and its failure reaches the exit status.
report() {
  while IFS= read -r line; do
    case "$line" in
      "") ;;
      "note: "*) echo "     $line" ;;
      *) bad "$line" ;;
    esac
  done <<EOF
$1
EOF
}

# Repository configuration keys that run a command or redirect origin or
# the files git reads, matched without case against the names of
# git config --local --name-only --list: the origin gate refuses them, and
# tools/agent_guard.sh holds a copy (a tools/tools_test.sh case keeps the
# two equal), since branch code run by the checks can write .git/config.
RISKY_CONFIG='^(core\.(fsmonitor|hookspath|sshcommand|gitproxy|pager|editor|askpass|alternaterefscommand|worktree)|diff\.external|diff\..+\.(textconv|command)|filter\..+|merge\..+\.driver|sequence\.editor|credential\..+|gpg\..+|uploadpack\..+|url\..+\.(insteadof|pushinsteadof)|remote\.origin\.(pushurl|uploadpack|receivepack|proxy|vcs)|http\..+|protocol\..+|include\..+|includeif\..+|extensions\.worktreeconfig)$'
# The tracked hooks directory make hooks installs, and the only files it
# may hold: hooks that run at a commit, never one that runs on a checkout,
# a merge, or a fetch. The one core.hooksPath allowed is its absolute path
# in the main worktree (the parent of --git-common-dir), never the
# relative name, which git reads from the top of each linked worktree.
# tools/agent_guard.sh holds a copy of both (a tools/tools_test.sh case
# keeps them equal).
HOOKS_PATH='.githooks'
HOOK_FILES_RE='^(commit-msg|pre-commit)$'
