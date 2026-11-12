# Proposal

## Why

The package step's `sh tools/run_state.sh groom` appends the applied sprint's row to `docs/sprints.tsv`, but `settled_at` in `tools/gates.sh` treats only `openspec/`, `docs/backlog.md`, `docs/queue.md`, `docs/goals.md`, and `docs/metrics.tsv` as records-only paths. A package commit that applies a sprint plan therefore counts as a code change after the reviews, and the security and stages gates refuse it before the push and at the merge: the jump-motions run stopped on exactly this (its package commit dfe20aa). It is outside the roadmap of `docs/architecture.md` section 12: it is delivery process, a blocking pipeline fix (T0) at the user's word.

## What Changes

- `settled_at` in `tools/gates.sh` accepts `docs/sprints.tsv` beside `docs/metrics.tsv`, so the security, stages, and passed gates hold a review or a check recorded before a package commit that writes the sprint row; a code change after the reviewed commit is still refused.
- The header comments of the security gate and of `settled_at` name `docs/sprints.tsv` with the other records.
- A `tools/tools_test.sh` case: the security gate passes after a commit that changes only `docs/sprints.tsv`, and refuses a commit that changes `docs/sprints.tsv` and a code file together.

Out of scope: the other lists of these paths, which refuse nothing a groom write needs: `TEST_ONLY` in `tools/run_state.sh` (the check's stage carry and the fix scope, where a `docs/sprints.tsv` change only costs a full stage run or a whole-branch review) and `documentation()` in `tools/ci_scope.sh` (a records-only change runs CI in full). Adding the path there is an optional extra the user may approve separately. `.claude/workflows/deliver-change.js` holds no path list, and no separate package commit check exists. The waiting sprint plan, the queue, and the metrics rows are not applied here.

Assumptions:

- "The package commit check" of the brief is the pre-push run of the security and stages gates, which both go through `settled_at`; no other check by that name exists.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/gates.sh`, `tools/tools_test.sh`.
- CLAUDE.md: unchanged, its Hard rules and Agents sections name no records-only path list.
- README.md: unchanged, it names no records-only path list.
- docs/architecture.md: unchanged, section 10 names no records-only path list.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.
