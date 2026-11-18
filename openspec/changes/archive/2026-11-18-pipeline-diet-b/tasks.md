# Tasks

## 1. Check

- [x] 1.1 `checkLines`, `checkRunTask`, `checkerNeeded`, the `run` fixed cap, and the run and log starts in `rounds` of `.claude/workflows/deliver-change.js`; `.claude/agents/checker.md` modes run and log; proved by "a passing check starts no checker relay", "a failed stage starts the checker to read its log", and "the check lines run spent and bench only after the check"

## 2. Quality

- [x] 2.1 `qualityTask` asks the first pass for every blocking finding; `.claude/agents/quality-reviewer.md` steps 4 and 7; proved by "the quality first pass is asked for every blocking finding"

## 3. Fix in place

- [x] 3.1 `inPlaceRound`, `inPlaceTask`, `fixed_in_place` in the review schemas, the confirmation request, and the hand-over filter; proved by "findings in place ride with the blocking ones", "a round of its own only with a round to spare", "a fix-in-place round runs check, security, and quality again at its head", and "a finding confirmed fixed in place leaves the hand-over"
- [x] 3.2 `combineReviews` merges `fixed_in_place` too and keeps a list only one start returned, so a capped review after a fix-in-place round, continued without the in-place list, keeps the fixes its first start confirmed out of the findings file (the quality finding at e436864e0ca7, `.claude/workflows/deliver-change.js` combineReviews); proved by "a continued review keeps the in-place fixes the first start confirmed"

## 4. Records budget

- [x] 4.1 `add_tokens` keys sprint-planning's starts `sprint`, `budget_line` sets them apart for a records change, the sprint-planning labels, and `.claude/commands/sprint.md`; proved by "tokens keys a sprint review start sprint" and "budget of a records change sets sprint-planning's reviews apart"

## 5. Docs and checks

- [x] 5.1 `docs/goals.md`, CLAUDE.md, README.md
- [x] 5.2 `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate` pass
