# Tasks

## 1. Budget at the check

- [x] 1.1 `tools/run_state.sh`: `OUTPUT_SHARE` and the `spent` command. Tested by the `tools/tools_test.sh` cases "run_state: spent passes a run under its budget", "run_state: spent names output tokens over the budget", "run_state: spent names earlier starts over the total budget", "run_state: spent says when no estimate was made", and "run_state: spent never stops a run".
- [x] 1.2 `tools/agent_guard.sh`: the read profile runs `spent`. Tested by "guard: checker notes the tokens spent" and "guard: merger refuses spent".
- [x] 1.3 `.claude/agents/checker.md` and `.claude/workflows/deliver-change.js`: the checker returns the line as `budget`; the workflow notes it and records an `overrun` note on `over:`. Tested by "run_state: the workflow reads the spent line" (the workflow's pattern against the script's output).

## 2. Tool-call caps

- [x] 2.1 `.claude/workflows/deliver-change.js`: `CALL_CAPS`, `CALL_SCALE`, `FIXED_CAPS`, `callCap`, `capLine` in every prompt, and the overrun record in `measured`. Tested by "caps: every kind of start has a cap" and "caps: a larger estimate never lowers a cap"; the script by `node --check` and a run with stub agents.
- [x] 2.2 Every agent file under `.claude/agents/`: `maxTurns` at its largest cap for a large estimate. Tested by "caps: the AGENT file's maxTurns is its large cap" for each agent.
- [x] 2.3 `.claude/agents/contributor.md`: the stop at the cap.

## 3. The merger's first green

- [x] 3.1 `.claude/workflows/deliver-change.js`: `mergeLines()` and the merger's cap by its waits. Tested by "guard: merger runs the green line" (the line as the workflow builds it).
- [x] 3.2 `.claude/agents/merger.md`: the six-call path and the waits of 180, 240, and 300 seconds; `tools/ci_wait.sh` header. Tested by "guard: merger verifies the merge", "guard: merger records the merge and cleans up", "guard: merger records red CI", and "caps: the merger's first green is at most 10 calls".

## 4. Docs and bookkeeping

- [x] 4.1 `CLAUDE.md`, `README.md`, `docs/codebase-map.md` area 1, and the headers of `tools/run_state.sh` and `tools/agent_guard.sh`.
- [x] 4.2 `docs/backlog.md`: the `pr-footer` entry of `build/plan/backlog.md` added; `leader-layout`'s evidence in the refused-backup entry; the foreground-wait entry removed.
- [ ] 4.3 Run `make tools-test`, `make docs-lint`, `make gates`, `make spec-validate`, and `openspec validate run-budgets --strict --no-interactive`.
