chore(tools): give each lane its own queue budget and check scratch

## Summary

Gives each lane queue its own byte budget, fits a lane's queue within it before the push, keeps a check's metrics inside its lane, and turns a check refused only because another lane wrote into the main checkout into a rerun rather than a contributor fix round. Most extra contributor starts since #274 came from lane cross-talk: the two queues shared one budget, so one lane's growth failed the other lane's docs-lint, plan-apply added bytes after the check, and a refused check whose stages all passed still started a fix round that changed no code.

---

## Changes

- Change docs-lint to check only the lane being checked against its own budget, QUEUE_BUDGET_FEATURE 6,976 and QUEUE_BUDGET_BACKLOG 10,993 bytes, which sum to the old shared 17,969, so the other lane's queue can never fail it
- Change plan-apply to fit the lane's queue within its budget as it copies it, dropping Decisions bullets from the last until it fits or refusing with the overage, and make push refuse a lane queue over its budget at HEAD
- Change the check and bench to write their metrics files under the change's lane rather than the main checkout's shared build/, and have the benchmark agent run its make targets in the lane
- Change a check whose stages all exited 0 but which saw files outside its clone change to end as escaped when every such path is on an allowlist of lane-written paths, rewriting its stage records as not passing so no later check reuses them, while any other outside write still fails the check
- Change deliver-change.js to rerun an escaped check without starting a contributor fix round
- Add tools-test cases for a lane over its own budget failing only its own docs-lint, plan-apply trimming and refusing, metrics landing under the lane, the escaped verdict and its stage records, and an outside write that is not allowlisted still failing
- Document the per-lane budgets and the escaped verdict in README.md, the code map, and the planner, checker, and benchmark agent files
- Add the Sprint 25 exception line for this change to the backlog queue through the change's plan, and record the history row and the open security findings

---

## Testing

- Run the security review on the committed diff at 17f45308b6bc, passed with no blocking finding (high 0, medium 0, low 1); its non-blocking findings are recorded in docs/findings/lane-isolation.md
- Run the checker's stages at 17f45308b6bc (docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, tools-test, gates, metrics), all exit 0
- Run the benchmark comparison at 17f45308b6bc, passed with no blocking finding
- Run make spec-validate after the archive, 55 passed and 0 failed
- Run make gates and make docs-lint before the push, both pass

---

## Notes

tools/rules.sh is untouched. The feature lane's queue and history are only read for the budget split. Two security findings on the escaped verdict, a write under the main checkout's build/ that the allowlist must keep narrow and an outside write that is detected but never reverted, are recorded in docs/findings/lane-isolation.md for a follow-up.
