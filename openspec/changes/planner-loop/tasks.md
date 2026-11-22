# Tasks

## 1. Sprint close

- [x] 1.1 Retire the quality reviewer, skeptic, and Records phase from `sprint-planning.js`; the planner returns its quality review and security disputes, recorded by the security reviewer's record mode; proved by "sprint: a sprint close starts no quality reviewer, no skeptic, and no records run" and "sprint: the planner's notes run under the security reviewer's record mode"
- [x] 1.2 Record `hold security-first` and name the hold (`queueHeld`); proved by "sprint: a blocking security finding or the plan's security first holds the next queue", "sprint: the plan's security first is recorded as the hold before the security review", and "guard: runner sets the security-first hold only"

## 2. Carrying delivery

- [x] 2.1 `groom CHANGE` from any package step, with the hold, the carrier, and the marker kept until main holds the row (`tools/run_state.sh`); proved by "run_state: groom holds the plan on a blocking sprint security review", "run_state: groom holds the plan on the plan's security first", "run_state: groom stands down for another carrier", "run_state: groom keeps the marker until main holds the row, naming its carrier", "run_state: groom retires the marker once BASE holds the row"
- [x] 2.2 `history CHANGE` appends every lane's rows when it carries; proved by "run_state: a carrying history appends every lane's rows"
- [x] 2.3 `packagePlan` runs history, groom, then plan-apply (`deliver-change.js`); proved by "workflow: a package start runs groom when a sprint plan waits, after history and before plan-apply" and "run_state: a delivery's package step applies the sprint plan with groom"
- [x] 2.4 `merge-main` keeps both lanes' queue edits; proved by "run_state: merge-main keeps the branch's own lane queue and main's other"
- [x] 2.5 `placed_by_sprint`, `review-due`, `budget`, `plan-needed` without the records change; findings gate and docs-lint by the appended row; proved by "run_state: review-due is not due while a held plan waits", "run_state: plan-needed leaves notes a later sprint plan placed", "gates: findings lets the branch appending groom's sprint row remove entries", "gates: findings refuses a removal beside a forged second sprint row", and "docs_lint: a branch changing docs/sprints.tsv checks both lanes"

## 3. Agents and docs

- [x] 3.1 Planner sprint mode, quality and security reviewer modes, contributor package step, runner, retrospective, `/sprint`; proved by the agents cases
- [x] 3.2 CLAUDE.md, README.md, docs/codebase-map.md; checked by `make docs-lint` and `make gates`
- [x] 3.3 Run `make tools-test`, `make docs-lint`, `make gates`, `make spec-validate`

## 4. Quality review

- [x] 4.1 `tools/run_state.sh` `add_tokens` still keyed a `: skeptic` label no start carries; fixed in place
- [x] 4.2 A delivery whose planner ran before the sprint closed can carry the plan and then apply an older plan directory over its lane queue; recorded in `docs/findings/planner-loop.md`
- [x] 4.3 A carrier that never merges keeps the plan until `build/plan/sprint.carrier` is removed by hand; recorded in `docs/findings/planner-loop.md`
- [x] 4.4 `docs/goals.md` lines 7 and 54 still describe the sprint quality review and the notes starts; recorded in `docs/findings/planner-loop.md`, the file being the planner's to write when asked
- [x] 4.5 The findings gate was skipped for a carrier branch (security Low); it now runs, each removed heading having to stand under `docs/backlog/` at HEAD, be named by a `- Merged:` line there, or be removed by a `groom.txt` line, a security entry only listed or fixed; proved by "gates: findings refuses a carrier's removal that docs/backlog does not hold", "gates: findings refuses a security entry the plan removes as gone", "gates: findings lets the plan remove a plain entry as gone and a security entry as listed", "gates: findings lets the branch appending groom's sprint row remove entries it filed in docs/backlog", "gates: findings lets a carrier's entry merge into another entry of the backlog", "gates: findings refuses a carrier's security entry the backlog no longer holds", and "rules: the security mark is the gates'"
