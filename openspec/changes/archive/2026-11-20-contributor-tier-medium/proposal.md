# Proposal

## Why

The contributor runs on the agent file's mid tier at high effort (`agent/high`, since `contributor-tier-routing`). By the user's tier decision of 2026-11-20 it moves to the mid tier at medium effort, a trial measured against the high-effort rows #233 to #250 (2 of 5 quality first passes, rework 1.8, weighted 2.10M tokens, 114 minutes) and the mid tier at session effort, rows #224 to #229 (1 of 6, rework 2.3, weighted 1.67M, 87 minutes).

## What Changes

- `CALIBRATION` in `.claude/workflows/deliver-change.js` allows a `medium` effort and sets the contributor to `agent/medium`; the metric line's filter and the restart restore accept the new effort. Critical, large-estimate, and escalated contributor starts keep `session/session` as today.
- Tools-test expects `agent/medium` for the contributor and proves a normal start passes the effort `medium` and a critical one the session's model and effort.
- `docs/goals.md` records the trial and its revert rule in Calibration; Critical changes and the README name the medium effort.
- `docs/queue-backlog.md` gains the user-approved exception line under Sprint 23 and drops `contributor-tier-revert` from its Pool item (Pool 7 in today's queue, the brief's Pool 4), `budget-recalibrate` staying.

Out of scope: any code under `carat/`, `tools/rules.sh`, the other kinds' profiles, and every feature-lane file (`docs/queue-feature.md`, `docs/metrics-feature.tsv`).

Roadmap: outside the roadmap of `docs/architecture.md` section 12; a pipeline calibration the user decided.

Assumptions: the brief's Pool 4 is today's Pool 7 item, shared with `budget-recalibrate`, of which only `contributor-tier-revert` goes. The new profile is not live until this change merges, so this run's own contributor starts use the earlier settings (and it is critical by rule b anyway).

- CLAUDE.md: unchanged, its Agents section holds no tier or effort figure; the profile is in docs/goals.md and the README.

## Capabilities

### New Capabilities

None: pipeline tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `tools/tools_test.sh`, `docs/goals.md`, `README.md`, `docs/queue-backlog.md`.
