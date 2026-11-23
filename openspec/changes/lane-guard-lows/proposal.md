# Proposal

## Why

Branch code is untrusted, yet four steps of the delivery tools take decisions from it or from the machine's own configuration: `lane-open` links the shared state into a worktree whose tree the branch controls, `merge-main` runs git with the global configuration and every hook, `set` writes any note key the workflow's own `note` command is meant to write, and `open_pr.sh wait` records a lone pull request on the pushed head without knowing whether a fork opened it. Each is a Low security finding from earlier reviews.

## What Changes

- Change `tools/run_state.sh` `lane_open`: refuse, before linking, a branch that tracks a path of `LANE_LINKS` (a `build/pipeline` of its own), a branch that commits a `tmp` or `build` link (so no link is written through it out of the repository), and an existing lane link pointing anywhere but the main checkout's path.
- Change `merge_main` to run its merge, conflict checkout, add, commit, and abort through `pinned_git`: no global or system configuration, no hook.
- Change `set` to refuse every `note.*` key, which only `note` writes.
- Change `tools/open_pr.sh wait`: the number taken (the lone one, or the recorded one among several) is read back with gh and recorded only when it is not cross-repository and its head branch is the run state's branch; a fork's or another branch's is refused, one gh cannot read is waited for and then refused.
- Add tools-test cases for each (each fails before the change), and change the forged-note setup of the late-finding tests to write the file, since `set` no longer takes note keys.

Split: the brief's other parts (`recordNotes` in `sprint-planning.js`, the `spec_validate.sh` and gateway control characters, the package step's prose-only edit, the budget line) are delivered by follow-up changes `lane-guard-lows-b` and `lane-guard-lows-c`; the disputed shared writable toolchain (`LANE_LINKS`) is closed with a recorded reason in the findings file: one toolchain is the design, and the links are made only by `lane-open`.

Assumptions: `wait` runs where gh is installed and authenticated (the contributor's session); without it, `wait` now refuses instead of recording an unchecked number, as the guarded pull request creation also needs gh.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/run_state.sh`, `tools/open_pr.sh`.
- Tests: `tools/tools_test.sh`.
- README.md: unchanged, no spec or user-facing behavior changed.
- CLAUDE.md: unchanged, the Lanes and Agents text stays true; the tools' own headers carry the refusals.
- docs/architecture.md: unchanged, it does not describe these tools.
- docs/codebase-map.md: unchanged, no file added, moved, or removed.
- No edit of `tools/rules.sh`.
