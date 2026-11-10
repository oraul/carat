# Proposal

## Why

A session-link footer reached the bodies of pull requests 95 to 99 after they were opened, against the hard rule that no URL, email address, or session link appears in GitHub activity. The content and pr-body gates run only before the push and the merge, on the local body file, so nothing checks a commit when it is made or a pull request as it stands, and the content scan has known gaps (a `++ ` line read as a path header, a `.env` under a path git quotes, bare host-and-path forms, whole lines printed). This change is outside the roadmap of `docs/architecture.md` section 12: it is delivery tooling that enforces CLAUDE.md's hard rules.

## What Changes

- Add `tools/scan_text.sh`, the one scanner of forbidden text, with the patterns of `tools/rules.sh`: a URL (any scheme, a host starting with www, or a bare host and path), an email address, a session id, a model name, and a secret; the exceptions are the co-author trailer's address, the Spinel clone address on the Makefile's toolchain line, and an agent's frontmatter tier alias. It reads files or standard input, or a unified diff with `--diff`, and prints each hit as `where:line: kind: text`, a secret by label only and a secret shape or a URL's user and password masked, a URL split where a line wraps at its first line, and a binary file as a note, not read.
- Change the content and pr-body gates of `tools/gates.sh` and the content check of `tools/docs_lint.sh` to run the scanner, which closes the `++ ` gap; list the added names unquoted so a `.env` under a quoted path is refused; refuse an added hook under `.githooks` other than `commit-msg` and `pre-commit`.
- Add `.githooks/commit-msg` and `.githooks/pre-commit`, which scan the message and the staged added lines, and a `make hooks` target that sets `core.hooksPath` to `.githooks`, run by `make toolchain`. The origin gate and `tools/agent_guard.sh` allow that one `core.hooksPath` value, read the default hooks directory for planted hooks, and refuse any other file in `.githooks`.
- Add `.github/workflows/scan.yml`, a job on `pull_request` events opened, edited, reopened, and synchronize with `contents: read` only, which runs `tools/pr_scan.sh` on the title, the body, every commit message, and every commit's added lines, the text passed only through environment variables. A footer added after the pull request opens turns the check red on the edited event, and the merger merges only over green checks.
- Add `.githooks/` and the two new scripts to the review area `guard and gates` of `tools/run_state.sh`.
- Remove the backlog entries this fixes: the `++ ` line, the quoted `.env` path, the whole line printed, the live body ungated, and the session-link footer; note on the binary-file entry that the scanner now notes such a file.

Out of scope: refusing a binary file or a `.gitattributes` change (kept in `content-gate-gaps`), unquoted and merge-resolution secrets, a comparison of the live body with the body file (the scan covers forbidden text; the shape stays the pr-body gate's), and the footer's source, which is the pull request tool outside the repository.

Assumptions:

- The email exception is the trailer's address wherever it appears (the trailer, the commit identity flags, the settings), as the content gate already allowed; a trailer naming another address is refused.
- A bare host and path is a name ending in one of a fixed list of common top-level domains followed by a slash, which matches no tracked file today.
- The workflow pins its checkout action by major tag, as `.github/workflows/ci.yml` does; no concurrency group cancels a run, so an opened run and the edited run that follows both report.
- The squash message is the body file the pr-body gate scans at the merge, so the live pull request scan and that gate together cover it.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/scan_text.sh`, `tools/pr_scan.sh` (new), `tools/rules.sh`, `tools/gates.sh`, `tools/docs_lint.sh`, `tools/agent_guard.sh`, `tools/run_state.sh`, `tools/tools_test.sh`, `.githooks/`, `.github/workflows/scan.yml`, `Makefile`.
- CLAUDE.md: changed, the `hooks` target in Commands and the scanner in the hard rules' gate line.
- README.md: changed, the `make hooks` target and the pull request scan.
- docs/architecture.md: unchanged, section 10 names the gates by script and none of its rules change.
- `docs/codebase-map.md` area 1, `.claude/agents/contributor.md` (run `make hooks` once), and `docs/backlog.md`.
