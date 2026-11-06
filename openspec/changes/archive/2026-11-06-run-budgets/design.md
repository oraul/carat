# Design

## Context

The scout pack `tmp/scout/build-and-ci-66bd3e4-20261106T185256Z.md` holds the line references at 66bd3e4. `.claude/workflows/deliver-change.js` measures each phase (`measured`: the output-token difference of `budget.spent()` and the `tool_calls` each agent reports) and checks no limit. The estimate (`estimate`) comes from the planner, the plan-skip line, or the run state. `tools/run_state.sh budget` compares a run's total tokens with `TOKEN_BUDGETS`, but the total arrives only after a start ends, through `/deliver`'s `usage`, so the retrospective budgets the history's last row. The merger reads the pull request and the check runs, waits 30, 60, 120, then 300 seconds, and runs the metric line, the CI record, the gates, the fetch, the subject check, the merged record, `ls-remote`, and the cleanup as separate calls.

## Goals / Non-Goals

Goals: every agent start has a cap scaled by the estimate, stated, recorded when passed, and backed by a hard ceiling; a passing check notes the tokens spent against the budget; a merge whose CI passes first takes at most 10 calls. Non-goals: stopping a run on its budget, a size-scaled hard cap, the pull request footer.

## Decisions

### The caps

`CALL_CAPS` holds the cap of one start at a medium estimate, from the history's per-phase calls (summed over a run's starts): planner 20 (8 to 20 seen), scout 30 per pack (up to 93 for three), implement 90 (27 to 87 at medium), fix 40, package 30 (16 to 28), push 15, checker 20, quality 35, security 35, bench 20, close 25. `CALL_SCALE` multiplies it by 0.5, 1, or 1.5 for small, medium, or large, rounded up; with no estimate (the planner's start, before one exists) the medium figure applies. `FIXED_CAPS` holds the starts whose work does not grow with the change: resume 12, the scout plan 10, record 3, merger 10.

`callCap(kind)` gives the figure and `capLine(kind)` the sentence each prompt ends with: the cap, the estimate it came from, and the instruction to stop at it and return the schema with what is done, naming the cap. `measured(key, fn, cap)` takes the cap (a number, or a function of the result for the merger) and, for each result whose `tool_calls` is above it, notes the overrun and queues `tools/run_state.sh note CHANGE overrun "..."`, built from the key, the two numbers, and the size word only. `overrun` is already a `PLAN_NOTES` kind, so the next planner sees it.

The tool count is self-reported and the stop is the agent's, so the hard ceiling is the platform's `maxTurns` in each agent file, set to the agent's largest cap at a large estimate plus a return margin of 5 turns: contributor 140 (implement), planner 35, scout 50, checker 35, quality-reviewer 58, security-reviewer 58, benchmark 35, retrospective 43, merger 29 (10 calls, 2 for each of the seven waits of 30 minutes, and the margin). Calls share a turn only when they run in parallel, so a start whose capped calls run one per turn would meet a ceiling equal to its cap with no turn left; the margin leaves the turns to commit, back up, and return the schema after the cap stops it. A start that reaches it returns no result, and the workflow stops as for any start without one. `tools/tools_test.sh` checks each file's `maxTurns` against the workflow's tables, so they cannot drift.

The contributor at its cap commits, backs up, marks the tasks done, and returns `stopped` with `call cap N reached: <what remains>`; the run stops with that reason and a resume continues from `tasks.md` with a fresh cap.

Alternative rejected: a PreToolUse hook counting calls per `agent_id` against a size read from the run state. The hook does not know the change, a counter file is state the agents' guard would have to protect, and a miscount refuses every call of a run.

### The budget at the check

`spent CHANGE` prints one line and exits 0 whenever the run state exists:

`under|over: O output tokens so far, budget B output tokens for SIZE (T total tokens at 6 per output token); R total tokens recorded by earlier starts, budget T`

O is the sum of `metric.phase.*`, which the checker's metric line stored just before (every start's phases up to the check); R is `metric.total_tokens`, 0 when none. It is `over:` when O is above B or R above T. Without a size it prints `no estimate:` with O and R. `OUTPUT_SHARE` is 6, beside `TOKEN_BUDGETS`.

The checker runs `sh tools/run_state.sh spent <change>` after a passing check, beside `bench`, and returns the line as `budget`. The workflow accepts it only when it matches the line's shape, notes it (the close and the report read the notes), and on `over:` queues an `overrun` note built from the parsed numbers, never the agent's text. Nothing stops.

### The merger's first green

The workflow already holds the pushed head (`head`, returned by the package or push start) and builds two lines with `mergeLines()`:

- green: `git worktree prune; git worktree remove --force tmp/.merge-gates; METRIC && sh tools/run_state.sh set C ci "green H" && git worktree add -q --detach tmp/.merge-gates origin/main && CHANGE=C RECORDS="..." sh tmp/.merge-gates/tools/gates.sh merge BODY`. The removal stays outside the `&&` chain, since it fails when no earlier worktree stands; everything after it is one chain, so a failed record runs no gate.
- red: `METRIC && sh tools/run_state.sh set C ci "red H"`.

The merger's first-green path is then: read the pull request (1), read the check runs (1), run the green line (1), squash-merge (1), `git fetch -q --prune origin && git log -1 --format=%H%n%B origin/main` (1), and `sh tools/run_state.sh set C merged SHA && git ls-remote --heads origin B && git checkout -q main && git merge -q --ff-only origin/main && git branch -D B` (1): 6 calls, plus 2 per wait. The waits are 180, 240, then 300 seconds: the merger starts after the package start has pushed and opened the pull request, and CI took 2.5 to 6 minutes, so most runs wait once and every recorded one at most twice, 10 calls. The local `HEAD` check moves to the merge gate, which already refuses a `HEAD` that is not the pushed head. `git push origin --delete B` runs only when `ls-remote` printed the branch.

The workflow's merger cap is `10 + 2 × max(0, waits − 2)`, the waits counted from the minutes the merger reports (`waited`), so a longer CI is not an overrun.

## Risks / Trade-offs

- A soft cap the agent ignores is only recorded. The `maxTurns` ceiling bounds the worst case, and the overrun notes reach the planner.
- A first wait of 180 seconds costs up to 3 minutes when CI was already nearly done; it saves 2 to 4 calls, each a model turn, in most runs.
- The output budget is a ratio of the history, not a measurement of this run's input tokens; the final `usage` line stays the record.
- This run's own agents load `origin/main`'s guard and the agent files the session loaded, so the checker of this change may be refused `spent`; the note then reads that the line is missing, and the next run has it.
