# Tasks

## 1. Main's figures stored once per merge

- [x] 1.1 Add `base-figures` and the stored figures, and compare `bench` with them first (`tools/run_state.sh`); prove it in `tools/tools_test.sh`
- [x] 1.2 Change the benchmark agent to build the base only when none are stored (`.claude/agents/benchmark.md`, `checker.md`, the workflow's prompt) and allow `base-figures` in the read profile (`tools/agent_guard.sh`); proved by the guard cases

## 2. No checker when every stage carried

- [x] 2.1 Add `run_state.sh carried` and the runner profile's form; prove it in `tools/tools_test.sh`
- [x] 2.2 Ask for it in the workflow's check round before the checker start and record the check from its result (`carryWanted`, `carriedRun`); prove the helpers and the order in `tools/tools_test.sh`

## 3. Docs

- [x] 3.1 Update README.md and CLAUDE.md, and the header of `tools/run_state.sh`
