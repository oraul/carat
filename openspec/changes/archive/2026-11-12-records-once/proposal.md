# Proposal

## Why

Pull request 111 showed three ways the planning records a package step commits can go wrong. Its package step ran `sh tools/run_state.sh groom` and `history` although its brief excluded both, since nothing lets a brief exclude them; the sprint-1 plan's marker `build/plan/sprint` stayed after `groom` applied it, so any later package step on a branch whose `docs/sprints.tsv` lacks the row (jump-motions' branch held its own copy, commit dfe20aa) applies the same plan again, and `history` likewise appends a row that another branch's package step already appended; and the records-only path list stands in three copies that already differ (`docs/sprints.tsv` only in `settled_at`), while `settled_at` exempts any edit of `docs/sprints.tsv`, so an edit of an earlier row moves the sprint base and shrinks the sprint-end security review (the security Low of 111 at `tools/gates.sh:113`). It is outside the roadmap of `docs/architecture.md` section 12: delivery process, a T0 correction at the user's word, outside the sprint count.

## What Changes

- `groom` applies a sprint plan once: when the marker names a sprint whose row `docs/sprints.tsv` (the working copy or BASE's) already holds, it applies nothing and says so; after applying a plan, or on finding it applied, it retires the marker to `build/plan/sprint.applied`, so the marker no longer triggers it again.
- `history` adds no metrics row a run already has: besides the working `docs/metrics.tsv`, it skips a change whose row BASE's `docs/metrics.tsv` holds or whose run state records that a package step appended its row (`row`, the branch it was appended on), and says so.
- A run-state key `records` with the value `skip` excludes the planning records from a change's package step: `history CHANGE` and `groom CHANGE` then do nothing and say so. The workflow sets it from `input.records` or from the planner's new optional `records` result field, which the planner sets when the brief excludes the planning records, and its package text then tells the contributor to run neither; the contributor's package step passes its change to both commands.
- `tools/rules.sh` names the records-only paths once as `RECORDS_RE` (the OpenSpec records, the backlog, queue, and goals, the metrics history, and the sprints file); `settled_at` in `tools/gates.sh`, `TEST_ONLY` in `tools/run_state.sh`, and `documentation()` in `tools/ci_scope.sh` read it.
- `settled_at` accepts a `docs/sprints.tsv` change only when it appends rows: the file at the commit must be a prefix of the file at HEAD ending in a line break.
- `tools/tools_test.sh` cases for each.

Out of scope: applying, reverting, or regrooming any plan or row now (the planner's notes handle jump-motions' merge of main); removing backlog entries the change fixes (the next sprint grooming does); a guard change, since the contributor profile already admits `history` and `groom` with any words and cannot `set` the new key.

Assumptions:

- "docs/sprints.tsv already holds that sprint's row" and "a row a run already has" include main's copy (BASE, origin/main), so a branch behind main does not repeat a row main has; a plan whose marker was retired stays applied on the branch that applied it, and is lost if that branch never merges, which is the price of applying it once.
- The appended-rows limit applies to `settled_at`, where the finding is; `TEST_ONLY` (the stage carry and the fix scope) and `documentation()` (CI scope) read only the shared path list, as neither shrinks a security review.
- `documentation()` now also counts `docs/sprints.tsv` and lists the records by the shared list; no test reads `docs/sprints.tsv`, so a records-only change skips CI as a metrics-only change did.

## Capabilities

### New Capabilities

None: the change is delivery tooling and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `tools/run_state.sh`, `tools/gates.sh`, `tools/ci_scope.sh`, `tools/rules.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`.
- CLAUDE.md: changed, the Commands section names `history CHANGE` and `groom CHANGE` and the `records` key.
- README.md: changed, the sprint planning step says `groom` applies a plan once.
- docs/architecture.md: unchanged, section 10 names neither `groom`, `history`, nor a records-only path list.
- docs/codebase-map.md: changed, the entries of `tools/rules.sh`, `tools/run_state.sh`, and `tools/ci_scope.sh` name the shared list and the new behavior; no file is added, moved, or removed.
