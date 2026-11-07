# Proposal

## Why

The delivery workflow's model tier and reasoning effort per agent were set by hand and never measured: four agent files carry a cheap-tier `model:` line, five starts pass `effort: 'low'`, and nothing records which profile a start ran on, so the history cannot say whether a profile helped. `docs/metrics.tsv` holds the cost side: plan plus scout take 26 to 37 percent of a run's output tokens on many runs (scout alone above 33,000 output tokens on 18 of the last 22 runs, up to 116,958), the reviews 25 to 47 percent on the newest runs, and the quality review passes first 13 times in 35. The scouts already run on the cheapest tier but at the session's effort, the most expensive mechanical phase left at a default.

This change is outside the roadmap of `docs/architecture.md` section 12: it measures and calibrates the delivery pipeline (`docs/queue.md`, the user's request placed after `merge-gate-integrity`, which the main session re-scoped as `check-isolation` and placed after this change).

## What Changes

- A calibration table in `.claude/workflows/deliver-change.js`, `CALIBRATION`, gives every kind of agent start a profile `TIER/EFFORT`: tier `cheap` (the agent file's `model:` line, the only place a tier is named) or `session`, effort `low` or `session` (none passed). Every start takes its effort from the table.
- The first table keeps every profile the workflow ran with before and moves one kind: the scouts' effort from the session's to low. The security reviewer stays `session/session`.
- Each start's profile is recorded as `metric.calib.KIND` in the run state's metric line, beside the phase's tokens and calls and the gates' first verdicts, and `tools/run_state.sh history` writes a new last column, `calibration`, older rows holding `-`.
- `docs/goals.md` gets a Calibration section: the reasons and figures of the table, and the rule that one kind moves at a time and a move is kept only when first-pass rates and rework do not get worse over the next runs; the security reviewer is never moved.
- `tools/tools_test.sh` checks that every start kind has a profile, that the cheap tier matches the agent files' `model:` lines, that security stays `session/session`, and that the metric line and history carry the profiles.
- Bookkeeping of the plan notes: the stopped `merge-gate-integrity` run's findings at e368486 go to `docs/backlog.md`, and the entries queued in `merge-gate-integrity` are queued in `check-isolation`.

## Capabilities

### New Capabilities

None: the change alters the delivery tooling, not the editor's behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Out of scope

- Moving any second kind (the record start to the cheap tier, which needs an agent file to carry its `model:` line since no model is named outside the frontmatter, or the planner and the reviews): later changes, one at a time, once the history shows the scout move held.
- The periodic review's starts (`.claude/workflows/periodic-review.js`), which keep their profiles and record none.
- The `check-isolation` work itself; its local commits, backup refs, and run state of `merge-gate-integrity` are kept untouched.

## Assumptions

- A tier is named only as `cheap` or `session` in the workflow and the history, since CLAUDE.md allows a model name only on an agent file's `model:` line.
- A restart keeps the profile this start used for a kind it starts again, else the one an earlier start recorded.
- Every `docs/backlog.md` entry queued in `merge-gate-integrity` moves to `check-isolation`, since that item replaces it in the queue.

## Impact

`.claude/workflows/deliver-change.js`, `tools/run_state.sh` (the history header and row), `tools/tools_test.sh`, `docs/metrics.tsv` (one column), `docs/goals.md`, and `docs/backlog.md`.
