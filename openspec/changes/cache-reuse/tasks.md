# Tasks

## 1. Main's figures stored once per merge

- [x] 1.1 Add `base-figures` and the stored figures, and compare `bench` with them first (`tools/run_state.sh`); prove it in `tools/tools_test.sh`
- [x] 1.2 Change the benchmark agent to build the base only when none are stored (`.claude/agents/benchmark.md`, `checker.md`, the workflow's prompt) and allow `base-figures` in the read profile (`tools/agent_guard.sh`); proved by the guard cases

## 2. No checker when every stage carried

- [x] 2.1 Add `run_state.sh carried` and the runner profile's form; prove it in `tools/tools_test.sh`
- [x] 2.2 Ask for it in the workflow's check round before the checker start and record the check from its result (`carryWanted`, `carriedRun`); prove the helpers and the order in `tools/tools_test.sh`

## 3. Docs

- [x] 3.1 Update README.md and CLAUDE.md, and the header of `tools/run_state.sh`

## Quality review

- [x] 4.1 The carry reads the stage list from the lane's own Makefile, safe only because it is tried on the contributor's claim, which needs the check's machinery untouched; add the comment to `carried_check`, fixed
- [x] 4.2 Stored figures trust the saving lane's measuring script; recorded in `docs/findings/cache-reuse.md`, recorded
- [x] 4.3 The check round's carry has no end-to-end workflow test; recorded in `docs/findings/cache-reuse.md`, recorded
- [x] 4.4 The release timing of the benchmark runs only for a brief with a time target; recorded in `docs/findings/cache-reuse.md`, recorded
