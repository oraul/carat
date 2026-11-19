# Proposal

## Why

Card rule 1 of the contributor (return `head` from `git rev-parse --short=12 HEAD`) is only an instruction: the workflow takes a done result's `head` unchecked, and two runs this week stopped on a literal "placeholder" head (quality-first-pass, contributor-tier-routing). A head the workflow adopts must be the lane's real one, and a start that broke the rule should move the run to the session's model, as the other escalation triggers do.

## What Changes

- After a contributor start returns done, the workflow reads the lane's head itself, in a start that runs only `git -C tmp/.lane-<change> rev-parse --short=12 HEAD`, and refuses the result when its `head` is not twelve lowercase hex characters (a placeholder, a typed short or full hash) or differs from that output.
- A refused result is noted (`head-refused` in the run state, the report note naming the reason), escalates the run's later contributor starts to the session's model (`escalate('a refused head')`), and is restarted once, told why; a second refusal in the same `contributor()` call stops the run.
- The refusal's queued note carries the reported head only as a sanitized excerpt, so a result cannot inject shell text into the record line.
- When the lane's head cannot be read, the result's well-formed head is taken, with a note; the check compares its own commit with the head anyway.
- `docs/goals.md`'s escalation paragraph names the refused head as a trigger; tools-test cases run the real `contributor()` over a placeholder, a wrong head, a second refusal, an unread lane head, and a hostile head.

Out of scope, by the plan's split: the self-check-mismatch note after the next check and its escalation test (`delivery-guards-c`), and any "gates clean" claim. Also out: the continued start's head assignment, the check, any code under `carat/`, and `tools/rules.sh`.

Roadmap: outside `docs/architecture.md` section 12; a pipeline defect (T1) run by the user-approved exception.

Assumptions: the lane's head is read by a start of the `record` profile (one command, from the repository root), counted under the `record` usage key, since the workflow has no shell of its own; the restart counts as a continued start in the loop.

- README.md: its pipeline paragraph says the workflow refuses a contributor head other than the lane's.
- CLAUDE.md: unchanged, its Agents section names no escalation trigger.
- docs/architecture.md: unchanged, no spec, layer, or port changes.

## Capabilities

### New Capabilities

None: pipeline tooling (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `tools/tools_test.sh`, `docs/goals.md`, `README.md`.
