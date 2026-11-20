# Tasks

## 1. Record times

- [x] 1.1 Make `review` in `tools/run_state.sh` write `at.review.KIND` for a periodic kind, `plan-needed` write `at.plan-needed` while the plan is ahead, and `set` refuse an `at.*` key; proved by "run_state: a periodic review records its time", "run_state: set refuses a record time", "run_state: plan-needed records when it read the reviews", and "run_state: a resume past the plan keeps the planner's time" in `tools/tools_test.sh`

## 2. Clearing rules

- [x] 2.1 Make `merged_since` in `tools/run_state.sh` judge a timed review by the planner's time, keeping ancestry for an untimed one; proved by "run_state: plan-needed keeps a failing periodic security review a merge planned before it was recorded followed", "run_state: plan-needed keeps a failing periodic security review a resumed delivery planned before it followed", and "run_state: plan-needed leaves a failing periodic security review a merge planned after it was recorded followed" in `tools/tools_test.sh`
- [x] 2.2 Make `passed_since` in `tools/run_state.sh` take only a later whole-tree pass, by record time and commit; proved by "run_state: plan-needed keeps a failing whole-tree periodic security review a later sprint diff pass followed", "run_state: plan-needed keeps a failing whole-tree periodic security review a whole-tree pass recorded before it followed", and "run_state: plan-needed leaves a failing whole-tree periodic security review a later whole-tree pass superseded" in `tools/tools_test.sh`
- [x] 2.3 Add the case "run_state: plan-needed passes over a passing periodic security review" in `tools/tools_test.sh`

## 3. Sprint report

- [ ] 3.1 Add `sweepLine` to `.claude/workflows/sprint-planning.js` and use it in the report; proved by "sprint: the sweep line names a partial sweep" and "sprint: the sweep line names unrecorded results" in `tools/tools_test.sh`

## 4. Docs

- [ ] 4.1 Update the run state header and the comments of `merged_since`, `passed_since`, and `plan_needed` in `tools/run_state.sh`, the comment above `planReview` in `.claude/workflows/deliver-change.js`, the README pipeline step 1, and the map's `tools/run_state.sh` entry; checked by `make docs-lint` and `make gates`
- [ ] 4.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
