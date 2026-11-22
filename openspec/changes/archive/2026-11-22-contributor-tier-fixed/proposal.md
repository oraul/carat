# Proposal

## Why

By the user's decision of 2026-11-22 no contributor start runs on the session's model. Today a critical run (the plan's rule, or a large estimate) and any run that escalated start the contributor on the session's model at the session's effort, and the close start (records, retrospective, report) has no agent file and runs there too. The routing is a cost the user does not want on the contributor or the close.

## What Changes

- `.claude/workflows/deliver-change.js`: `calibrate` gives every contributor start its `CALIBRATION` profile, `agent/high`, whatever `criticalRule()` or `escalated` say, and no longer passes a model override; `escalate` no longer returns early in a critical run and still notes the escalation (`escalation` note, `metric.escalated`); `criticalRule()` stays as the label stored as `metric.critical`; `CALIBRATION.close` becomes `agent/high`.
- `.claude/agents/retrospective.md`: a `model:` line naming the contributor file's tier, so the close start's `agent` tier is that file's.
- `tools/tools_test.sh`: cases for a normal, a critical, a large-estimate, and an escalated contributor start at `agent/high` with no model, the close start at `agent/high` on a file naming the contributor's tier, the security start unchanged, escalation noted once with the profile kept, and a critical run recording its rule and escalation.
- `docs/goals.md`: Critical changes, Escalation, and Calibration (its reasons line and a dated entry naming the user's decision and its keep rule); `README.md`: the pipeline paragraph.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.claude/workflows/deliver-change.js`, `.claude/agents/retrospective.md`, `tools/tools_test.sh`, `docs/goals.md`.
- README.md: changed, the pipeline paragraph named the routing.
- CLAUDE.md: unchanged, it names no tier routing; its Agents section lists the phases only.
- docs/architecture.md: unchanged, it does not describe the delivery agents.
- docs/codebase-map.md: unchanged, it maps no file under `.claude/` and names no routing.
- docs/compatibility.md, docs/actions.md: unchanged, no editor behavior changes.
- `tools/rules.sh`: not edited. `.claude/agents/contributor.md`: not edited (at its byte budget).

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change (T1) by the user's request, the backlog lane's priority, an extra beyond Sprint 29's three by the user's exception, placed in the queue by the plan step.

Minor assumptions: an escalation in a critical run is now noted and recorded (it was skipped because the run was already on the session's model); the keep rule reads the next 5 rows against the last 5 critical rows.

## Out of scope

- The keep-or-revert decision, which the planner makes from the history.
- The planner, quality, and security tiers; `tools/rules.sh`; the feature lane's files; the sprint-planning workflow.
