# Proposal

## Why

Since the read-back was added, `tools/open_pr.sh wait` records a pull request number only after `gh pr view` shows its head is this repository's and the change's branch. `gh` cannot run in the delivery environment on any route, so every delivery stops at `wait` and none can merge. The merger's step 1 already reads the pull request's head repository and head branch and returns `stale` when they differ from the input's, so the guard against a fork's pull request on the pushed commit is kept there (the user's decision of 2026-11-23).

## What Changes

- `tools/open_pr.sh wait` records the one pull request whose head is the pushed head (or the recorded one among several) again with no `gh`: `head_owned`, its call, its refusals, and the `unread` bookkeeping are removed.
- The header and the comment of `wait` say the merger's step 1 confirms the head repository and branch.
- `tools/tools_test.sh`: the `head_owned` cases (fork, other branch, `gh` failing, no shape, read back from this repository) are replaced by a case where `gh` fails and a lone pull request on the pushed head is recorded, and one proving `wait` ran no `gh`.

Out of scope: `recordNotes` in `sprint-planning.js`, the package step's prose-only edit, the budget line, and the control characters (lane-guard-lows-c). The merger's text is unchanged: step 1 already compares the head repository and branch.

Assumptions: a `gh` that exits 127 on the `PATH` is the same as no `gh` for `wait`, and the test asserts it was never run.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/open_pr.sh`.
- Tests: `tools/tools_test.sh` (the `head_owned` cases removed, two added).
- Docs: `docs/codebase-map.md` and the README already say the merger checks the head repository and branch; unchanged.
- README.md: unchanged, no user-visible behavior or spec changed; it already says the merger merges only a pull request whose head repository and branch are the change's.
- CLAUDE.md: unchanged, it names `wait` only as recording the pull request.
- docs/architecture.md: unchanged, no spec changed.
- No edit of `tools/rules.sh`.
