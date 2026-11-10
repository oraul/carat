# Tasks

## 1. The scanner

- [x] 1.1 `tools/scan_text.sh` and `tools/rules.sh`: the one scanner, text and diff modes, the exceptions, masked hits, split URLs, binary notes, and `report`. Tested by the "scan_text:" cases.
- [x] 1.2 `tools/gates.sh` (content, pr-body) and `tools/docs_lint.sh` (content) run the scanner; the content gate lists added names unquoted and refuses an added hook under `.githooks`. Tested by "gates: content refuses an added .env under a path git quotes", "gates: content scans an added line starting with ++", "gates: content notes a binary file and does not read it", "gates: content refuses an added hook under .githooks but commit-msg and pre-commit", and the adjusted docs_lint and secret cases.

## 2. The commit hooks

- [x] 2.1 `.githooks/commit-msg`, `.githooks/pre-commit`, and `make hooks`, run by `make toolchain`. Tested by the "hooks:" cases.
- [x] 2.2 `tools/gates.sh` (origin) and `tools/agent_guard.sh`: `core.hooksPath` allowed only as the absolute path of the main worktree's `.githooks`, planted hooks read from the default directory, no other file in that `.githooks`. Tested by "hooks: a linked worktree runs no hook planted in its own .githooks", "gates: origin in a linked worktree reads the main worktree's .githooks", "gates: origin refuses the relative core.hooksPath .githooks", the matching "guard:" cases, "gates: origin allows core.hooksPath as the tracked .githooks", "gates: origin refuses a hook in .githooks but commit-msg and pre-commit", "gates: origin refuses core.hooksPath other than .githooks", the two "guard:" cases, and "guard: the guard's hooks path and hook names are the gates'".

## 3. The pull request scan

- [x] 3.1 `tools/pr_scan.sh` and `.github/workflows/scan.yml`. Tested by the "pr_scan:" cases and "repository: the scan workflow runs on every pull request edit with read-only contents and no interpolated run line".
- [x] 3.2 `tools/run_state.sh`: the scanner, the pull request scan, and `.githooks/` in the review area `guard and gates`. Tested by "run_state: review-due names the scanner" and "run_state: review-due names the commit hooks".

## 4. Docs and bookkeeping

- [x] 4.1 CLAUDE.md, README.md, `docs/codebase-map.md` area 1, and `.claude/agents/contributor.md` name the new files and `make hooks`.
- [x] 4.2 `docs/backlog.md`: the five fixed entries removed, the binary-file note, and the plan notes' raised-again lines, duplicates, and stale line numbers.
