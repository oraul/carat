# Proposal

## Why

The contributor's self-check (`self_check` of an implement or fix result) is taken on its word: a start that says `match` while the next check fails a stage (three times this sprint a "gates clean" claim met a failed gates stage) is never compared with that check, so the run state shows no contradiction and the escalation rule of `docs/goals.md`, which moves later contributor starts to the session's model after a self-check mismatch, never fires for it.

## What Changes

- The workflow keeps the self-check of the last implement or fix start until the next check that finishes at the head reads it; any other contributor mode clears it, as a settled round does.
- When that check fails a stage (a refusal counts as the stage `refused`) after a self-check of `match`, the workflow notes it: a report note and a queued closable `note <change> self-check-mismatch "contributor <mode> said match, the check failed at stage <stage>"`, then `escalate('a self-check the check contradicted')`, so the run's later contributor starts take the session's model (once a run, never in a critical run, as before).
- A self-check of `mismatch` (already escalated when returned), a passed check, or no recorded self-check writes no note.
- `docs/goals.md`'s escalation paragraph names the contradicted self-check, noted `self-check-mismatch`, as a trigger; a tools-test case shows the note and `calibrated.contributor` becoming `session/session`, and none when the self-check said mismatch or the check passed.

Out of scope: any check of a "gates clean" phrase in a summary, a self-check carried across a workflow restart (the value lives in the workflow's memory, as the head guard's refusal count does), and `tools/rules.sh`, which this change does not edit.

Roadmap: outside `docs/architecture.md` section 12; a pipeline defect (T1), the rest of `delivery-guards-b` by the split rule, run by the user-approved exception of Sprint 21.

Assumptions: the stage name reaches the queued line only through `safeText`, as the head guard's reported head does; the comparison runs only where the check loop records a check verdict at the head (a check that did not finish or ran at another commit compares nothing and keeps the self-check for the next one).

- README.md: its pipeline paragraph says a self-check the next check contradicts also escalates.
- CLAUDE.md: unchanged, its Agents section names no escalation trigger.
- docs/architecture.md: unchanged, no spec, layer, or port changes.
- docs/codebase-map.md: unchanged, no file added, moved, or removed.

## Capabilities

### New Capabilities

None: pipeline tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `tools/tools_test.sh`, `docs/goals.md`, `README.md`.
