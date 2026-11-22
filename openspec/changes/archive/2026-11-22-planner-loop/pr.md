chore(pipeline): review the sprint in the planner and carry its records in a delivery

## Summary

Moves the sprint's cross-change quality review into the planner and drops the separate records run, so the next sprint's first delivery carries the sprint's records in its own pull request. A sprint close no longer starts a quality reviewer, a skeptic, or a nested records delivery, which cost extra starts, a second pull request, a CI run, and a merge for bookkeeping alone.

---

## Changes

- Change the planner's sprint mode in sprint-planning.js to review the combined diff for quality itself, keeping the notes it keeps, recording a disputed security finding as disputed and never dropping one, and removing the quality reviewer, skeptic, and records phases with the code only they used
- Add a record mode to the security reviewer that records the sprint's notes under its read profile, and add a hold security-first record so a blocking security finding still holds the next queue
- Add groom CHANGE to any delivery's package step, the first while a sprint plan waits carrying it, with a hold, a single carrier, and a marker kept until main holds the sprint's row, and make history append every lane's rows for that carrier
- Change merge-main to resolve a conflict only in the lane queues with the branch's own lane queue and main's other one, so two lanes keep both edits
- Change the findings gate and docs-lint to follow a branch appending a sprint row, the gate still requiring each removed entry to be filed in the backlog or removed by a plan line groom would accept
- Add effort high to the contributor's agent file beside its model line, and update the planner, quality reviewer, security reviewer, runner, and sprint command texts
- Document the new sprint close in CLAUDE.md, README.md, and docs/codebase-map.md
- Add tools-test cases for a sprint close starting no quality reviewer, skeptic, or records run, a package start running groom when a sprint plan waits, groom's hold and carrier, history across lanes, merge-main's queue resolution, and the contributor's tier and effort

---

## Testing

- Run the fast stages and the rest of make check at the head before the archive: docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics all pass
- Security review of the committed diff at that head passes with no High or Medium finding and two Low findings, none blocking
- Benchmark review at that head passes with no blocking finding
- Run make spec-validate after the archive, 56 items pass
- Run make gates and make docs-lint on the final commit, both pass

---

## Notes

Three Low security findings on the findings gate's carrier allowance are recorded in docs/findings/planner-loop.md and do not block. More follow-ups are recorded there as well: a delivery whose planner ran before the sprint closed can carry an older plan, a carrier that never merges keeps the plan until its marker is removed, and docs/goals.md still names the sprint quality review, left for the user since the planner writes it only when asked. The change edits no file of the feature lane and not tools/rules.sh.
