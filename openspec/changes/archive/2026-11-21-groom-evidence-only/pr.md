fix(run_state): remove backlog entries only with evidence

## Summary

The backlog grooming tool now removes an entry only with evidence that its problem was addressed: it refuses the age-based `stale` kind and the `closed` kind, and a `gone` line must state why the problem no longer applies. The `stale` kind marked 1,322 of 1,772 entries in the withdrawn sprint-24 plan, real bugs included, and `closed` removed an entry whenever a later commit touched a file it named, whether or not that commit fixed it.

---

## Changes

- Change `groom` in tools/run_state.sh to refuse a `stale` or `closed` line of groom.txt by name, so a plan holding one writes nothing and names the line, as any failed proof does.
- Change the `gone` kind to require `gone HEADING -- REASON`, refusing a line with no reason or a blank one before any other proof, while keeping the check that every named path is absent at HEAD.
- Change `backlog-oldest` and backlog-pick's groomed set to read a gone line's heading before its reason, splitting at the last separator so a heading holding one still matches.
- Remove the helpers only `stale` and `closed` used, the whole-backlog scan `PRUNE_ALL_SPRINT` switched on, and its constant; `backlog-oldest` stays for the planner's evidence check of the oldest 50 entries.
- Change the tools-test cases so stale and closed lines are refused, gone lines carry reasons, a gone line without a reason or with a blank one is refused, one whose heading holds the separator is applied, and listed, fixed, merged, and duplicate lines are still accepted.
- Document the evidence kinds and the end of pruning by age in the run_state.sh header, the planner agent's grooming step, the CLAUDE.md Agents Backlog line, README.md pipeline step 11, and the code map entry for tools/run_state.sh.
- Add the user-approved exception line for this change under the Sprint 25 heading of docs/queue-backlog.md, with the plan's queue and the sprint-24-records metrics row.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding
- Run the benchmark review, pass with no blocking finding
- Run the checker's stages (diagnose, docs-lint, dev-build, test-build, test-run, gates, bench-budget, tools-test, metrics), all pass
- Run make spec-validate after archiving, all 55 items pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

No backlog entry is removed by this change; tools/rules.sh and tools/agent_guard.sh are not edited, and docs/architecture.md is unchanged since it names none of the grooming kinds. The change runs first in the backlog lane, outside Sprint 25's three backlog items, by the user-approved exception of 2026-11-21.
