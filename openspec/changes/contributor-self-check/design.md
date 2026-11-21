# Design

## Context

The check runs detached (`check_run`), its stage records written only by the runner, which no agent's `set` may write (`tools/agent_guard.sh` refuses `stage.*`). `check_stages` skips a stage passed at BACKED only when BACKED is HEAD, and carries a stage from BACKED when only tests changed. The workflow passes `phase.check` as BACKED, so a pass at a head the workflow never recorded reruns.

## Decisions

- The contributor may run `check CHANGE` only: no COMMIT, so it can never make a check skip or carry anything; its check runs every stage not scoped or compiled-same.
- The workflow, not the contributor, decides the backed commit. It backs the contributor's head only when the returned `check` line reads `check: every stage passed at H`, H is the returned head and still the head at the Check phase, and `tools/lane_facts.sh` (main's copy, run by the workflow's record start) read `machinery no`. With `tools/`, the `Makefile`, or `test/runner/` changed, the branch's own runner wrote the records, so they back nothing and every stage reruns.
- A claim the run state does not hold costs only the stages: `check_stages` finds no passing record at H and runs them; the checker's verdict is the one recorded. No refusal kind and no restart.
- `run_state.sh check CHANGE COMMIT` accepts `phase.check` or HEAD: the first carries the workflow's recorded pass, the second skips only records the runner wrote at that very commit; any other commit is refused, so no caller can carry records from a commit nobody passed.
- `self_fix`: the WORK field `check_runs` is added to a counter seeded from `metric.self_fix` and written in the metric line, beside `rework`.
- Caps: implement 110 and fix 60 leave room for three check runs (about 18 calls); maxTurns follows the tools-test formula, 110 times 1.5 plus 5, 170.

## Risks

- The skip widens from the workflow's record to a runner record at a contributor's head; the machinery rule and CI cover a branch that edits the runner.
- A longer contributor start; the caps rise by the measured need.
