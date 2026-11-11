# Proposal

## Why

The periodic review after #100 raised a blocking Medium (confidence 8): `make hooks`, which `make toolchain` runs, sets `core.hooksPath` to the tracked `.githooks`, so checking out any branch or fork that commits an executable hook there (`post-checkout`, `post-merge`, `reference-transaction`) runs it. The attempt to keep local hooks safely (hooks-path-fix, PR #101) stopped after three fix rounds, each install scheme opening a new hole, and the user decided to remove the local commit hooks entirely. The same review raised a Low (5): the pull request scan runs the pull request's own scanner, so a pull request that edits `tools/scan_text.sh` can pass its own check. This change is outside the roadmap of `docs/architecture.md` section 12: it is delivery tooling that closes a security finding.

## What Changes

- Remove `.githooks/` (`commit-msg`, `pre-commit`), the `make hooks` target, and its call from `make toolchain`, so nothing sets `core.hooksPath`.
- Change the origin gate of `tools/gates.sh` and `tools/agent_guard.sh` to refuse any `core.hooksPath` (a `RISKY_CONFIG` key, with no exemption) and any file but a sample in the common git directory's hooks folder, as before #100; drop `HOOKS_PATH` and `HOOK_FILES_RE` from `tools/rules.sh` and the guard, and the content gate's refusal of an added hook under `.githooks`, which no setting reads any more.
- Change `.github/workflows/scan.yml` to check out the base commit to its own path (`base`, `persist-credentials: false`) beside the pull request (`head`) and run `base/tools/pr_scan.sh` in the head's repository, so the base's scanner reads the head's title, body, commits, and added lines.
- Keep `tools/scan_text.sh`, the push and merge gates, and the pull request scan; the scanner's and `tools/pr_scan.sh`'s comments drop the hooks and name the base checkout.
- Replace the hooks' `tools/tools_test.sh` cases with: a clone after `make toolchain` (a local stand-in for the Spinel sources) has no `core.hooksPath`; the origin gate and the guard refuse any `core.hooksPath`, a tracked `.githooks` included; the scan uses the base's scanner when the head replaces it.
- Update CLAUDE.md (the hard rule's gate line and the Commands line), README.md, `docs/codebase-map.md` area 1, and `.claude/agents/contributor.md` (no `make hooks` step); the plan's backlog entries and queue.

Out of scope: the replace-refs Medium (5) (`GIT_NO_REPLACE_OBJECTS=1` wherever trusted tooling reads `origin/main`, refusing `refs/replace`), recorded in the backlog under `guard-lows`; closing PR #101 and abandoning the hooks-path-fix run, which the main session does; any other commit-time scan.

Assumptions:

- The review area `guard and gates` of `tools/run_state.sh` keeps `[.]githooks/`: a change that adds a file there again still deserves the security review.
- The guard and the gate keep reading the hooks folder of `--git-common-dir`, which no `core.hooksPath` can move once any is refused; the derivation of the main worktree as its parent is gone.
- The base checkout pins `actions/checkout@v4` by major tag, as the rest of the workflows do, and a fetch depth of one; the head checkout keeps the full history the scan reads.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `Makefile`, `.githooks/` (removed), `.github/workflows/scan.yml`, `tools/gates.sh`, `tools/agent_guard.sh`, `tools/rules.sh`, `tools/scan_text.sh`, `tools/pr_scan.sh`, `tools/tools_test.sh`.
- CLAUDE.md: changed, the hard rule's gate line no longer names the commit hooks and the Commands line drops `hooks`.
- README.md: changed, the `make hooks` row removed and the scanner paragraph names no commit hooks.
- docs/architecture.md: unchanged, section 10 names the gates by script and never named the hooks.
- `docs/codebase-map.md` area 1, `.claude/agents/contributor.md`, `docs/backlog.md`, `docs/queue.md`.
