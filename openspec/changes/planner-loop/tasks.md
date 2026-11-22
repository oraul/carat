# Tasks

## 1. Sprint close

- [ ] 1.1 Retire the quality reviewer, skeptic, and Records phase from `sprint-planning.js`; the planner returns its quality review and security disputes, recorded by the security reviewer's record mode; proved by "sprint: a sprint close starts no quality reviewer, no skeptic, and no records run" and "sprint: the planner's notes run under the security reviewer's record mode"
- [ ] 1.2 Record `hold security-first` and name the hold (`queueHeld`); proved by "sprint: a blocking security finding or the plan's security first holds the next queue" and "guard: runner sets the security-first hold only"

## 2. Carrying delivery

- [ ] 2.1 `groom CHANGE` from any package step, with the hold, the carrier, and the marker kept until main holds the row (`tools/run_state.sh`); proved by "run_state: groom holds the plan on a blocking sprint security review", "run_state: groom stands down for another carrier", "run_state: groom keeps the marker until main holds the row"
- [ ] 2.2 `history CHANGE` appends every lane's rows when it carries; proved by "run_state: a carrying history appends every lane's rows"
- [ ] 2.3 `packagePlan` runs history, groom, then plan-apply (`deliver-change.js`); proved by "workflow: a package start runs groom when a sprint plan waits"
- [ ] 2.4 `merge-main` keeps both lanes' queue edits; proved by "run_state: merge-main keeps the branch's own lane queue and main's other"
- [ ] 2.5 `placed_by_sprint`, `review-due`, `budget`, `plan-needed` without the records change; findings gate and docs-lint by the appended row; proved by "run_state: review-due is not due while the carried plan waits" and the gates cases

## 3. Agents and docs

- [ ] 3.1 Planner sprint mode, quality and security reviewer modes, contributor package step, runner, retrospective, `/sprint`; proved by the agents cases
- [ ] 3.2 CLAUDE.md, README.md, docs/codebase-map.md; checked by `make docs-lint` and `make gates`
- [ ] 3.3 Run `make tools-test`, `make docs-lint`, `make gates`, `make spec-validate`
