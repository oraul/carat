# Proposal

## Why

Five defects of the delivery workflow's records and waits recur on every run (`docs/queue.md` item 1, T1: pipeline defects that corrupt metrics or stall runs). The quality reviewer's advisories are counted and their text is kept nowhere (14 advisories lost in 4 of 4 runs). The merger returns `pending` long before CI ends (merge took 23 to 31% of each run's tool calls for CI runs of 2 to 3 minutes). An agent is started after the package step and after the merge only to run queued `tools/run_state.sh` lines. The last record start's own cost never reaches the run state, so the run state's totals fell 365 and 318 output tokens short of the workflow's. And a change whose queue item the planner removed loses its size estimate, so `budget` prints "no estimate" and the history row carries `-` (8 of the last 10 rows).

## What Changes

- (a) The quality reviewer records each advisory as a `quality-advisory` note at its commit, beside the `quality-blocking` notes; the workflow keeps the advisories of the last quality review (seeding them from those notes on a resume) and hands them to the package step with the non-blocking security findings, which puts them into `docs/backlog.md`. The planner's instructions name the new note kind.
- (b) A new `tools/ci_wait.sh SECONDS` waits in the foreground, 1 to 540 seconds, so the merger's shell call blocks between two reads of the check runs; the merger's schedule is 30, 60, 120, then 300 seconds repeated, until 30 minutes have passed since its first read, and it returns `pending` only after them. The merger reports the minutes it waited, and the workflow notes a `pending` returned before 30 minutes.
- (c) No agent start exists only to run records after the package step or the merge: the package step and the CI and merge phases are queued for the final flush, a resume decides that the package step is done from `pushed` and `pr`, and the figures reach the run state through `metric` lines that the merger and the retrospective run as their first step. Record starts drop from four to two per run (the end of the verification rounds, which the pre-push gates read, and the end of the run), plus one per CI fix.
- (d) Each `metric` line carries every figure of the run (phase totals, first verdicts, rework, CI minutes, estimate) as the workflow holds it at that moment, so the line the retrospective runs makes the run state's `metric.phase` totals equal the totals in the retrospective's prompt, and the history row equals the workflow's totals through the report.
- (e) The planner returns the size it estimated the change at; the workflow stores it as `metric.estimate`; `estimate_of` in `tools/run_state.sh` reads that first and the queue item at the squash commit's parent only for older runs, so `budget` and the history row keep the estimate after the item leaves the queue.
- `tools/tools_test.sh` cases for `ci_wait.sh` and for the stored estimate; `docs/codebase-map.md` area 1, `README.md`, and the agents' files updated.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This changes the delivery pipeline's workflow, agents, and scripts, not the editor's behavior; `skip_specs` is set.

## Impact

- Changed: `.claude/workflows/deliver-change.js`, `.claude/agents/merger.md`, `quality-reviewer.md`, `planner.md`, `retrospective.md`, `tools/run_state.sh`, `tools/tools_test.sh`, `docs/codebase-map.md`, `README.md`. Added: `tools/ci_wait.sh`.
- No file under `carat/`, `bin/`, `test/`, or `bench/` changes; the editor binary and its metrics are unchanged.

Outside the roadmap of `docs/architecture.md` section 12: it serves goal 13 of `docs/goals.md` (the pipeline never forgets and measures itself).

Out of scope: the agent guard, which stays as it is (the main session's decision; `run-state-integrity` just closed a forging path); the scout and check costs (`workflow-cost`, item 6); a record agent for the verification rounds, which stays because the pre-push gates read the reviews it records.

Assumptions recorded instead of asked:

- The last record start's own cost comes after every line that could record it, so no run state can hold it; "the totals agree" is met by building each `metric` line and the summary beside it from the same figures at the same moment, and the history row equals the workflow's totals through the report. A run state whose final record start ran has every other figure.
- A foreground wait through a script is how the merger holds its turn: a background `sleep` ends a subagent's turn, which is why it returned `pending` after a few minutes. The cap of 540 seconds stays under the shell tool's ten-minute limit.
- Advisories go both to the run state (a note, for a resume and the planner's reading of pending runs) and to `docs/backlog.md` (through the package step, which `contributor.md` already asks for), since the run state lives in `build/` and a fresh workspace lacks it.
- `rework=0` is now stored for a run without rework, where `-` was stored before; the history's rework column then reads 0 for such runs.
