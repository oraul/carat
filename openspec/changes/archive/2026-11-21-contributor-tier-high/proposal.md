# Proposal

## Why

The contributor runs on the agent file's mid tier at medium effort (`agent/medium`, the trial of `contributor-tier-medium`). By the user's decision of 2026-11-21 the trial ends early after 2 runs: #262 (1.23M total, 1.28M weighted tokens, the day's cheapest) skipped its self-review rule and hand-edited snapshots, costing a fix round, and #265 returned a placeholder head, escalated to the session's model, and paid for both (2.19M). The mid tier at medium effort drops procedural steps late in a run, so the contributor returns to high effort.

## What Changes

- `CALIBRATION` in `.claude/workflows/deliver-change.js` sets the contributor back to `agent/high`; `medium` stays an allowed effort in `PROFILE`. Critical, large-estimate, and escalated contributor starts keep `session/session` as today.
- Tools-test expects `agent/high` for the contributor and proves a normal start passes the effort `high` and a critical or escalated one the session's model and effort; the restart case keeps restoring a medium profile.
- `docs/goals.md` records the trial's end and why in Calibration, and Critical changes and the README name the high effort again.
- `docs/queue-backlog.md` gains the user-approved exception line under Sprint 25.

Out of scope: any code under `carat/`, `tools/rules.sh`, the other kinds' profiles, every feature-lane file (`docs/queue-feature.md`, `docs/metrics-feature.tsv`), and a queue item for `contributor-harness`, which the exception line only names.

Roadmap: outside the roadmap of `docs/architecture.md` section 12; a pipeline calibration the user decided.

Assumptions: the new profile is not live until this change merges, so this run's own contributor starts use the earlier settings (and it is critical by rule b anyway). The exception line goes after the sprint's other exception paragraphs, before its first item.

- CLAUDE.md: unchanged, its Agents section holds no tier or effort figure; the profile is in docs/goals.md and the README.

## Capabilities

### New Capabilities

None: pipeline tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `tools/tools_test.sh`, `docs/goals.md`, `README.md`, `docs/queue-backlog.md`.
