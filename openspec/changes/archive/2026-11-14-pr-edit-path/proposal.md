# Proposal

## Why

The body mode edits the open pull request with the session's GitHub update tool, while `tools/open_pr.sh` and `.github/workflows/open-pr.yml` say a pull request created or edited over GitHub's API from a session gets a footer its network layer appends; the update tool stays granted to the contributor with no guard hook on it, `README.md` says the opposite of the scripts, a run that pushed but recorded no pull request number reruns the whole package step into the refused second push, and `contributor.md` holds 8,148 of its 8,192 bytes. This change delivers the queue item `pr-edit-path` (sprint 4's pipeline item); it is outside the roadmap of `docs/architecture.md` section 12: it is delivery process.

## What Changes

- open-pr sets an open pull request's title and body to the branch's `pr.md` when they differ (`gh pr edit` from GitHub's runners, read back equal), instead of leaving it alone; a branch with more than one open pull request is refused. So every title or body reaches the pull request from `pr.md` on a branch push, never from a session tool.
- The body mode fixes the body file, rewrites `pr.md` with `tools/open_pr.sh write`, commits it, and pushes it as a CI fix (`tools/run_state.sh push CHANGE --ci-fix`, the merger having recorded the red CI); the workflow keeps the sha that push recorded and the merger waits at it.
- The contributor holds no GitHub tool: `mcp__github__update_pull_request` and `mcp__github__pull_request_read` leave its grant, and its guard hook also matches every `mcp__` tool, which the guard refuses for a profile it does not judge.
- A resume that finds a recorded push but no pull request number starts the contributor in a new `wait` mode, which runs only `tools/open_pr.sh wait` and returns the number, committing and pushing nothing; the package step runs only when nothing was pushed.
- One rule in the four texts (`tools/open_pr.sh`, `.github/workflows/open-pr.yml`, `.claude/agents/contributor.md`, `README.md`): no session creates or edits a pull request with a tool or GitHub's API; open-pr opens it from `pr.md`, or sets an open one's title and body to `pr.md`'s, on the branch push.
- `contributor.md` is cut under 7,000 bytes, a budget `tools/docs_lint.sh` keeps.

Out of scope: the planner's placement of `architecture-review` (the planner's queue, applied at the package step); the merger, CI, and the scan workflow; `docs/backlog.md`, which the package step only appends to.

Assumptions:

- A push of a branch whose open pull request's text a person edited on GitHub resets it to `pr.md`'s: `pr.md` is the one source of the text, and it is the squash body's record.
- The body push counts as a CI fix push (the scan is a CI check that ran red), so the run state's one push plus one per CI fix holds; the change to `pr.md` is records-only (`openspec/`), so the checks and reviews settled before it still hold at the new head.
- After the body push the scan runs once on the synchronize event with the old text and again on the edit with the new; the merger keeps only the latest run of each check name, as it already does.

## Capabilities

### New Capabilities

None: the change is delivery process and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/open_pr.sh`, `.github/workflows/open-pr.yml`, `.claude/agents/contributor.md`, `.claude/workflows/deliver-change.js`, `tools/docs_lint.sh`, `tools/tools_test.sh`, `docs/codebase-map.md`.
- CLAUDE.md: changed, the contributor's pull request path and the `tools/open_pr.sh` command.
- README.md: changed, the package step's pull request rule.
- docs/architecture.md: unchanged, it names no pull request path (section 10 covers the test and check machinery only).
