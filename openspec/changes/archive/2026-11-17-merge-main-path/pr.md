fix(pipeline): give a merge refused on a moved main one path

## Summary

Gives the delivery workflow's merge loop one path for a merge refused because main moved: it merges main in the lane, reruns the check, reruns the reviews only when the merge changed files of the change, pushes once as a counted main-moved push, and waits for CI and merges again. In #169 CI was green, GitHub refused the merge after #168 merged, and the push of the merged main was refused with no red CI, so the run stopped and cost a second full run; with two lanes merging into one main this recurs.

---

## Changes

- Add a main-moved path to the merge loop of the delivery workflow, started when the merger reports CI green, not merged, and main moved, keeping the first CI result green and stopping on a second refusal in one run
- Add a main-moved push kind to tools/run_state.sh push, at most one a run besides CI fixes, which needs a recorded push without origin/main and a head that holds it, and refuse an unknown push kind instead of ignoring it
- Add a moved command to tools/run_state.sh that says whether the main merge changed a file the change touches since the reviewed commit, so the reviews carry over or run again
- Change the merge gate in tools/gates.sh to count main-moved pushes and refuse a second one
- Change tools/agent_guard.sh so the contributor may push a main-moved push and the checker may run moved
- Add the moved mode to the contributor agent and the main-moved report to the merger agent, a conflict both sides changed the same logic in stopping with its files named
- Add tools-test cases for a moved-main push counted once and merged, the reviews rerun only when the change's files changed, a second main-moved push refused, an unresolvable conflict stopping with its files named, the gate count, and the guard
- Document the main-moved path in README.md, CLAUDE.md, and the run_state.sh entry of docs/codebase-map.md
- Record three review findings in docs/findings/merge-main-path.md, the plan's queue, and the lane's metrics history

---

## Testing

- Run the security review of the committed diff, pass with high 0, medium 0, low 2, none blocking, both Lows recorded in docs/findings/merge-main-path.md
- Run the quality review, pass with 0 blocking and 4 advisories, the review-narrowing one recorded as a finding
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, test-run, bench-budget, tools-test, gates, and metrics at the implemented commit, all pass
- Run the benchmark review, pass with no allocation or round change
- Run make spec-validate after archiving the change, 54 passed and 0 failed

---

## Notes

This run is itself judged by main's workflow and gates, which have no main-moved path yet, so a move of main while it waits to merge would stop it as #169 stopped. The two quality wording advisories on the merger and checker agent files and the duplication advisory on the push kinds in tools/run_state.sh were dropped as minor. Covers the backlog entries A merge refused on a moved main costs a full resume and a CI failure, and A merge that fails on a moved main has no push path. No tools/rules.sh edit.
