# Proposal

## Why

Nothing in the delivery workflow limits what one agent start spends or tells a run it is over its budget before the run ends. The contributor made 154 tool calls in `guard-allowlist` with no cap; `buffer-global` (1,231,942 total tokens) and `pipeline-durability` (1,334,299) passed the medium budget of 1,200,000 and learned of it only at the close, from `/deliver`'s `usage` line; and the merger spends 17 to 28 calls on a pull request whose CI passes at its first run, most of them reads and waits of 30 and 60 seconds against a CI that takes 2.5 to 6 minutes. This is item 1 of `docs/queue.md`, a T1 user request, outside the editor roadmap of `docs/architecture.md` section 12: it changes the delivery workflow, its agents, and its scripts only.

## What Changes

- Tool-call caps: `.claude/workflows/deliver-change.js` gives every agent start a cap on its tool calls, a medium figure per kind of start (`CALL_CAPS`) scaled by the size estimate (half for small, one and a half for large), fixed for the mechanical starts (`FIXED_CAPS`). The prompt states the cap and the agent stops at it; a start that reports more calls than its cap leaves a workflow note and an `overrun` note in the run state, which the planner places. Each agent file sets `maxTurns` to its largest cap at a large estimate plus a return margin of 5 turns, a hard ceiling the platform enforces that still leaves a capped start the turns to return.
- The contributor stops at its cap with its work committed and backed up and returns `stopped` with the question `call cap N reached: ...`, so a resume continues from `tasks.md`.
- Budget at the check: `tools/run_state.sh spent CHANGE` prints `under:`, `over:`, or `no estimate:` with the output tokens spent so far against the size's output budget (the total-token budget divided by `OUTPUT_SHARE`, 6) and the total tokens earlier starts recorded against the total budget, and always exits 0. The checker runs it after a passing check; the workflow notes the line and, on `over:`, records an `overrun` note, never stopping the run.
- The merger's first-green path takes at most 10 tool calls: the workflow hands it the pushed head and two composed lines, the green line (the metric line, the CI record, and main's merge gates in one call) and the red line; the merger verifies and records the merge in one call and cleans up in one more; its waits are 180, then 240, then 300 seconds. The workflow notes a merger that passes 10 calls plus 2 for each wait beyond the second.
- The guard's read profile admits `tools/run_state.sh spent`.
- Plan notes: the `pr-footer` entry joins `docs/backlog.md`; the refused-backup entry gains `leader-layout`'s evidence; the entry on the merger's foreground wait, queued here, leaves the backlog with the harness behavior recorded in `tools/ci_wait.sh` and the merger's file.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches the delivery workflow, its agents, and its scripts, and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `.claude/workflows/deliver-change.js` (caps, the check's budget note, the merger's lines), every agent file under `.claude/agents/` (`maxTurns`; the checker's, the contributor's, and the merger's steps).
- `tools/run_state.sh` (`spent`), `tools/agent_guard.sh` (the read form), `tools/ci_wait.sh` (header), `tools/tools_test.sh`.
- `CLAUDE.md`, `README.md` when they name the commands, `docs/codebase-map.md`, `docs/backlog.md`.

## Out of scope

- A hard cap scaled by the size: the platform's `maxTurns` is fixed per agent file, so the size-scaled cap is the prompt's and the workflow's record; the file's ceiling is the large cap plus the return margin.
- The pull request footer itself (`pr-footer`, item 7), and the refused backup push (kept in the backlog by the user's decision).
- A cap on a whole run's tokens: the budget note informs, as the queue item asks, and never stops.

## Assumptions

- "Capped by the size estimate" is met by a per-start cap the agent is told and the workflow records an overrun of, with `maxTurns` as the platform's hard ceiling at the large figure plus the return margin; the platform has no per-call cap that a script can set.
- The workflow sees only output tokens while it runs (`budget.spent()`); total tokens arrive only after each start, through `usage`. The check's note therefore compares output tokens with an output budget derived from the total budget: the history's 16 rows with both figures have a median of 5.5 total tokens per output token (4.1 to 9.1), rounded up to 6 so the note comes early rather than late.
- "A merge on a CI green first" is read as a merge whose CI passes at its first run; the bound of 10 calls holds when CI finishes within the first two waits (7 minutes after the merger's first read; every recorded CI took 6 minutes or less), and each later wait adds 2 calls.
- The merger's foreground wait of up to 540 seconds has worked in every run since `guard-hardening`: each merge phase of the history is one start of 17 to 28 calls; the backlog entry asking to confirm it is closed here.
