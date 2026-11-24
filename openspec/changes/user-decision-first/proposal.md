# Proposal

## Why

The user decided on 2026-11-24 that `run-state-backlog-b` was one delivery for all 202 entries, yet the planner applied its size check (a brief of three or more parts is split) and left 102 entries undone in follow-ups. The planner's rubric, its sprint rule, and its size check run before anything the user said, so a user decision is only honored when it happens to agree with them. This change makes the user's decision the first rule.

## What Changes

- Planner agent: a first rule, ahead of the rubric step and the size check, says the brief's USER DECISIONS or the user's recorded request is followed as written (one delivery, no split, a split, the items, their order, a sprint's contents), never split, reordered, or dropped against, and that where the planner would have decided otherwise a decision records that the user's decision overrode its rule, with its number. The size check step now reads "where the user decided nothing". Existing text was shortened to stay in the 8,192-byte budget.
- Delivery workflow: the planner start carries the rule and the brief's USER DECISIONS between the intro and the plan request (`userFirst`), and the plan result is validated: a plan that splits a brief whose USER DECISIONS says one delivery or no split stops the run (`splitAgainstUser`) unless the decision records the override.
- Sprint workflow: the sprint planner start carries the same rule right after its mode line.
- `docs/goals.md`: the rubric opens with the user-decision-first rule; the size check and the sprint rule apply only where the user decided nothing.
- `docs/brief-standard.md`: USER DECISIONS ties to the planner's first rule, and the split-first line is excepted by a one-delivery decision.
- `CLAUDE.md`: the planner bullet names the rule; two sentences of the Stack and Project sections are shortened to stay within its 30,720-byte budget.
- tools-test cases for the agent file, `CLAUDE.md`, both prompts, and the plan validation; the two documents are not pinned, since `TOOLS_RE` does not match them and a `tools/rules.sh` edit goes first, alone (recorded in `docs/findings/user-decision-first.md`).

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `.claude/workflows/deliver-change.js`, `.claude/workflows/sprint-planning.js`.
- Agents and docs: `.claude/agents/planner.md`, `docs/goals.md`, `docs/brief-standard.md`, `CLAUDE.md`.
- Tests: `tools/tools_test.sh`.
- Assumptions: a decision is read as a split by the words split, queue the rest, or deliver the first, unless it names the override; the check applies only to a brief given to the delivery (a resume reads the queue item and has no USER DECISIONS text in its prompt, so the rule alone applies there). `tools/rules.sh` is untouched.
- README.md: unchanged, a process change whose behavior the README does not describe at this level.
- docs/architecture.md: unchanged, no layer, port, or rule moves.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.
- docs/compatibility.md: unchanged, no Neovim command is touched.
- docs/actions.md: unchanged, no action is bound or changed.
