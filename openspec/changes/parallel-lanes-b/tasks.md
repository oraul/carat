# Tasks

## 1. Run state and guard

- [x] 1.1 `tools/run_state.sh`: `lane-open`, `lane-close`, `merge-main`, and the header; proved by the `tools/tools_test.sh` cases "lane-open makes the change's worktree under the hidden tmp/", "a lane worktree shares the main checkout's toolchain and compile cache", "a lane's run state lands in the main checkout's build/pipeline", "lane-open run from the lane keeps it on a resume", "lane-open replaces a replaced run's worktree on another branch", "two lanes stand at once", "merge-main merges a moved main", "two lanes' records merge by appended rows only", "merge-main aborts and names a conflict", "lane-close removes the worktree after the merge", and "lane-close leaves the shared toolchain, cache, and run state".
- [x] 1.2 `tools/agent_guard.sh`: the contributor runs `merge-main`, the merger `lane-close`; proved by "guard: contributor merges a moved main into its worktree's branch", "guard: merger refuses merge-main", "guard: merger runs the green line", and "guard: merger records the merge and cleans up".

## 2. Workflow and agents

- [x] 2.1 `.claude/workflows/deliver-change.js`: `laneDir`, `mergeGatesDir`, the resume's `lane-open`, the introduction naming the worktree, `MERGE_MAIN` in implement and fix starts, and the green line in the worktree; proved by "workflow: two concurrent deliveries' merge-gates paths are distinct", "the green line runs the merge gates in the delivery's worktree", "every agent start runs its commands in the change's worktree", and "an implement or fix start first merges a moved main".
- [x] 2.2 `.claude/agents/contributor.md` (push mode's `merge-main`) and `merger.md` (step 7's `lane-close`); the agents' budget cases.

## 3. Docs and checks

- [x] 3.1 README.md and `docs/codebase-map.md` area 1; CLAUDE.md's wording proposed in design.md; `make docs-lint`.
- [x] 3.2 `make tools-test` (seconds against main's), `make gates`, `make spec-validate`.
