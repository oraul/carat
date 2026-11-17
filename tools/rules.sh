# The forbidden content of CLAUDE.md's hard rules as patterns, secrets
# included, read by tools/scan_text.sh, the one scanner, which
# tools/gates.sh (the content and pr-body gates), tools/docs_lint.sh, and
# tools/pr_scan.sh run; report, which passes the scanner's output to bad()
# (defined by the sourcing script); and the repository configuration the
# origin gate refuses.

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
# eight characters or more, matched without case. In a configuration file
# (CONFIG_PATH_RE: YAML, TOML, shell, and caratrc), where an unquoted value
# is a literal and not a name as in code, BARE_ASSIGN_RE also refuses such a
# name assigned with =, :, or => an unquoted literal of eight characters or
# more starting with a letter or digit, holding no quote, dollar sign,
# backquote, or parenthesis (so a variable, a substitution, or a call
# passes), and ending at a space or the line's end; or a whole caratrc line
# "scope.name value" whose dotted name ends in one of those words.
KEY_RE='-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY( BLOCK)?-----'
TOKEN_RE='(^|[^A-Za-z0-9])((AKIA|ASIA)[A-Z0-9]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20,}|xox[abeprs]-[A-Za-z0-9-]{10,}|AIza[A-Za-z0-9_-]{35}|sk-[A-Za-z0-9_-]{20,}|[rs]k_live_[A-Za-z0-9]{16,}|npm_[A-Za-z0-9]{36})'
QUOTE="[\"']"
ASSIGN_RE="(password|passwd|secret|token|api_?key)$QUOTE?[[:space:]]*(=|:|=>)[[:space:]]*$QUOTE[^\"'[:space:]]{8,}$QUOTE"
CONFIG_PATH_RE='(^|/)[^/]*caratrc$|\.(ya?ml|toml|sh|bash)$'
BARE_ASSIGN_RE="(password|passwd|secret|token|api_?key)$QUOTE?[[:space:]]*(=|:|=>)[[:space:]]*[A-Za-z0-9][^\"'\$\`()[:space:]]{7,}([[:space:]]|\$)|^[[:space:]]*[A-Za-z0-9_.-]*\.[A-Za-z0-9_-]*(password|passwd|secret|token|api_?key)[[:space:]]+[A-Za-z0-9][^\"'\$\`()[:space:]]{7,}[[:space:]]*\$"

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

# The records-only paths, an extended regular expression without anchors:
# the OpenSpec records, the backlog and the findings files, the planning
# records (the lane queues, goals), the lane metrics histories, and the
# sprints file, which a package step commits
# after the checks and no check but docs-lint reads. Read by settled_at in
# tools/gates.sh (docs/sprints.tsv only by appended rows), TEST_ONLY in
# tools/run_state.sh, and documentation() below.
RECORDS_RE='openspec/|docs/(backlog|queue-feature|queue-backlog|goals)\.md$|docs/findings/[a-z0-9-]+\.md$|docs/(metrics-feature|metrics-backlog|sprints)\.tsv$'

# documentation PATH: true when PATH is documentation no test, build, or
# tool case reads, so CI (tools/ci_scope.sh) and the checker's scope
# (tools/run_state.sh check) skip the compile, test, and bench stages for
# it: a records-only path (RECORDS_RE), a LICENSE file, a Markdown file
# other than docs/actions.md and docs/compatibility.md, which the action
# and ex tests compare with the code, and docs/codebase-map.md, whose
# coverage the lint test checks, or a file under .claude/ other than the
# agents, the workflows, and .claude/settings.json, which make tools-test
# reads.
documentation() {
  ! printf '%s\n' "$1" | grep -q -E "^($RECORDS_RE)" || return 0
  case "$1" in
    docs/actions.md|docs/compatibility.md|docs/codebase-map.md) return 1 ;;
    .claude/agents/*|.claude/workflows/*|.claude/settings.json) return 1 ;;
    .claude/*|*.md|LICENSE|*/LICENSE) return 0 ;;
    *) return 1 ;;
  esac
}

# The paths make tools-test (tools/tools_test.sh) reads from this
# repository: the tools, the agents, workflows, commands, and settings,
# .github/, the Makefile, CLAUDE.md (its Agents rules), and the files
# the generator cases copy (kit).
# tools-test runs, in CI and in the checker, only when a changed path
# matches (a path git quotes keeps its leading quote); a tools_test.sh
# case fails on a path it reads that this misses.
TOOLS_RE='^"?(tools/|[.]claude/(agents|workflows|commands)/|[.]claude/settings[.]json$|[.]github/|Makefile$|carat[.]rb$|carat/adapters/editor_assembly[.]rb$|CLAUDE[.]md$|docs/(codebase-map|actions|compatibility)[.]md$|test/runner/run_all[.]rb$|test/lint[.]rb$|config/(plugins|default)[.]caratrc$)'
