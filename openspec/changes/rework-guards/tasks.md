# Tasks

## 1. Review fix on a resume past the push

- [x] 1.1 `tools/run_state.sh` push `--review-fix` (a recorded push other than HEAD, once per run, `review_fixes`); proved by "run_state: a review fix push needs a recorded push other than the head", "run_state: a review fix allows one more push", and "run_state: a second review fix push is refused" in `tools/tools_test.sh`
- [x] 1.2 `tools/gates.sh` `pushes` counts the review fix; proved by "gates: pushes allow one review fix" and "gates: pushes refuse a second review fix"
- [x] 1.3 `.claude/workflows/deliver-change.js`: `resumeFix`, the blocked step in `rounds`, the whole-diff security review in the round, and the `--review-fix` push before the merger; proved by "workflow: a resume past the push with a new blocking quality finding runs one fix round", "workflow: a second review fix round is refused", "workflow: a resume's failed check or benchmark gets no fix round", "workflow: the review fix round pushes once more", "workflow: the review fix round pushes with --review-fix", and "workflow: the review fix round reviews security over the whole diff"

## 2. Merged names

- [x] 2.1 `tools/run_state.sh` init refuses a merged change name on a branch other than main; proved by "run_state: init refuses a change name a run state recorded merged", "run_state: init refuses a change name a lane history row holds", "run_state: init resumes an unmerged run of the name", and "run_state: init at main resumes a merged sprint run state"; the resume prompt's stop proved by "workflow: the resume start stops on a refused init"

## 3. Agent rules and docs

- [x] 3.1 `.claude/agents/contributor.md` self-check and the review-fix push mode, the self-check in the workflow's implement and fix prompts; proved by "contributor: the self-check is in the implement steps" and "workflow: the implement and fix prompts carry the self-check"
- [x] 3.2 `.claude/agents/planner.md` gate-rules rule; proved by "planner: a change editing the merge gate's rules lands that edit first"
- [x] 3.3 CLAUDE.md Agents names the four rules within its budget; proved by "claude: the Agents section names the self-check, the review fix, the gate-rules rule, and the merged-name refusal" and `make docs-lint`
- [x] 3.4 `make gates`, `make spec-validate`, `make tools-test` (seconds not above main's)
