# Proposal

## Why

Every contributor start runs on the agent file's mid tier at the session's effort, critical changes (the guards, the toolchain, the editor's untrusted-input code) included, and a failing run keeps retrying on the same tier. The user asked for the mid tier at high effort by default and for the session's model where the change is critical.

## What Changes

- `CALIBRATION` allows a `high` effort and sets the contributor to `agent/high`; the metric line, the restart restore, and tools-test accept it.
- The planner's result gains `critical` (a rule letter a to e and the path); a critical run, or one estimated large, runs its contributor starts at `session/session`, recorded as `metric.critical`.
- After a self-check mismatch (a new optional `self_check` field of the contributor's result), a non-result, or a second blocking quality round, the run's later contributor starts use the session's model, recorded as an `escalation` note and `metric.escalated`.
- `docs/goals.md` gains Critical changes (the rules and the escalation) and the Calibration note counts the new profile; `planner.md` names the `critical` field.
- Tools-test cases cover the high effort, the critical run, the escalation, and the metric.

Out of scope: any code under `carat/`, and `tools/rules.sh`.

Assumptions: the rule letters follow the brief's (a) to (e); a large estimate is rule e, applied by the workflow itself. The routing is not live until this change merges, so its own run used the earlier settings.

- CLAUDE.md: unchanged, its Agents section holds no tier or effort figure; the routing is in docs/goals.md and the README.

## Capabilities

### New Capabilities

None: pipeline tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `.claude/agents/planner.md`, `docs/goals.md`, `tools/tools_test.sh`.
