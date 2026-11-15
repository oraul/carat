docs: add the design principles and the sprint mix

## Summary

Adds two binding design principles, deep modules and no broken windows, to the architecture document and makes every sprint of five hold three features and two fixes. The architecture stated no design principle, so review findings such as constructors that widen with every feature had no rule to be judged against, and findings outside a change's lines waited behind features because the sprint rule counted only the pipeline slot.

---

## Changes

- Add a Design principles list to section 1 of docs/architecture.md: deep modules, citing the architecture review's H2 and M5 as shallow-module smells, and no broken windows, fixing a defect in the change that finds it or queuing it at once
- Remove or shorten statements in docs/architecture.md that repeat sections 2, 9, and 13, keeping the document within its byte budget
- Change the sprint rule of docs/goals.md so each sprint holds three features and two fixes, the pipeline change counting as a fix and T0 security fixes staying outside the mix
- Change the planner agent's rubric citation and sprint mode to plan the mix and cite it in the decision
- Document the sprint mix in the Agents section of CLAUDE.md and in the README's planner step
- Apply the planner's sprint-6 queue, groom sprint 5, record the previous change's metrics row, and append this change's five review advisories to docs/backlog.md
- Add the archived OpenSpec change with its proposal, design, and tasks, specs skipped since no behavior changes

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and five advisories recorded in the backlog
- Run the checker's fast stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run the benchmark comparison against main's recorded figures, pass
- Run make spec-validate after archiving, 51 passed and 0 failed

---

## Notes

No code, test, configuration, or editor behavior changes. Nothing enforces the three-and-two mix mechanically: make docs-lint still counts only the pipeline items, and a check for the mix was left out of scope. The trimmed architecture text drops the CRuby benchmark baseline aside, which the backlog now records as a follow-up.
