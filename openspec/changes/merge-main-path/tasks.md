# Tasks

## 1. Run state and gates

- [ ] 1.1 Add `push --main-moved` to `tools/run_state.sh` (counted as `main_moved`, one a run, a recorded push other than HEAD not holding BASE and a HEAD holding it) and refuse an unknown push kind; proved by "a push of an unknown kind is refused", "a main-moved push needs a head holding the moved main", "a moved-main merge is pushed once as a main-moved push", "a main-moved push is counted", and "a second main-moved push in one run is refused" in `tools/tools_test.sh`
- [ ] 1.2 Add `moved CHANGE COMMIT` to `tools/run_state.sh`; proved by "moved keeps the reviews when the merge changed no file of the change" and "moved reruns the reviews when a file of the change changed"
- [ ] 1.3 Count `main_moved` in `gate_pushes` of `tools/gates.sh`, a missing value 0; proved by "pushes allow one review fix" (0 main-moved), "pushes allow one main-moved push", and "pushes refuse a second main-moved push"
- [ ] 1.4 Allow `push CHANGE --main-moved` to the contributor and `moved` to the read profile in `tools/agent_guard.sh`; proved by "guard: contributor pushes the merge of a moved main", "guard: contributor refuses a push of another kind", and "guard: checker compares the change's files after a main-moved merge"

## 2. Workflow and agents

- [ ] 2.1 Add the main-moved path to the merge loop of `.claude/workflows/deliver-change.js` (`mainMoved`, `carryFrom`, `carried`, `movedTask`, `carryReviews`, MERGE `main_moved`, CHECK `moved`, the `moved` call cap); proved by the "workflow:" cases naming the main-moved path, the counted pushes, the `--main-moved` push, the carried reviews, the moved line, the unresolvable conflict, and first.ci
- [ ] 2.2 Report `main_moved` in `.claude/agents/merger.md` and add the `moved` mode to `.claude/agents/contributor.md` (agent text, no test beyond the contributor size case)

## 3. Docs and checks

- [ ] 3.1 Update `README.md`, `CLAUDE.md`, and `docs/codebase-map.md` (docs only; `make docs-lint` and `make gates`)
- [ ] 3.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
