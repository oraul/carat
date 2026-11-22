# Design

## Context

`calibrate(kind, opts)` in `deliver-change.js` returns `session/session` for a contributor start when `criticalRule()` is set or `escalated` is true, and then adds `model: 'inherit'` so the session's model overrides the contributor file's `model:` line. `escalate` returns early in a critical run. The close start's `CALIBRATION` profile is `session/session` and its agent file, `retrospective.md`, has no `model:` line.

## Goals / Non-Goals

**Goals:**

- No contributor start and no close start runs on the session's model.
- The critical rules and escalations stay visible in the run state and the history.

**Non-Goals:**

- Any other kind's tier; removing the critical rules or the escalation triggers.

## Decisions

- `calibrate` reads `CALIBRATION[kind]` only; the `inherit` branch goes, since no profile asks for the session's tier on an agent file any more. The `agent` tier of a kind stays defined by the agent file's `model:` line.
- `escalate` keeps its once-only note and `metric.escalated`, and loses its critical-run guard: the guard existed because a critical run was already on the session's model, which no longer holds. The note text no longer says the contributor moved.
- `criticalRule()` is untouched: it is the label for `metric.critical` and the calibration comparisons.
- `retrospective.md` gets the same `model:` line as `contributor.md`, and tools-test compares the two lines as it does the runner's and the checker's, so the close tier cannot drift from the contributor's.

## Risks / Trade-offs

- A critical change (pipeline guards, security items, large estimates) now runs on the mid tier at high effort; the review phases still run on the session's model. The keep rule decides: the next 5 rows' first passes and rework plus `self_fix` against the last 5 critical rows.
- The close start's records and report now run on the mid tier; the closing report is checked by the same schema as before.
