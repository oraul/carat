# Proposal

## Why

The user asked for two binding design principles, in their words "deep interface means deep modules" and "no broken windows", and for sprints that plan the fixes those principles create. `docs/architecture.md` states no design principle today, so the architecture review's H2 (each asynchronous language feature widens two constructors) and M5 (the assembly grows with every feature) have no rule to be judged against, and a finding outside a change's lines waits in the pool behind features, since the sprint rule of `docs/goals.md` counts only the pipeline slot.

## What Changes

- Add a Design principles list to section 1 of `docs/architecture.md`: deep modules, as in John Ousterhout's A Philosophy of Software Design (an interface much simpler than the work it hides; a constructor or interface that widens with every feature is a shallow-module smell, H2 and M5 cited), and no broken windows, as in The Pragmatic Programmer (a defect, shortcut, or rule break found is fixed in the change that finds it when it is in that change's lines, or else queued at once). The document stays within its 88,064-byte budget by removing statements another section of it already makes.
- Add the sprint mix to the sprint rule of `docs/goals.md`, the user's decision of 2026-11-15: each sprint of five holds three features and two fixes (a bug fix or a tidy-up of review findings, docs, or tooling, the pipeline change among them); T0 security fixes stay outside the mix and always go first.
- Write the mix into `.claude/agents/planner.md` where it reads the sprint rule: step 2's rubric citation and sprint mode step 2, with the evidence its decision cites (`3 features, 2 fixes`), within the agents' 8,192-byte budget.
- Update the Sprints line of `CLAUDE.md`'s Agents section and the planner step of the README's delivery section, which both state the sprint rule.
- The user's sprint-6 decision (design-principles, architecture-tidy, winbar-outline, carat-palette-b, ux-pass; markdown-reading-a and brief-only-relay to sprint 7) is already in the waiting plan `build/plan/queue.md`; the package step applies it with `sh tools/run_state.sh groom design-principles`, with no other reordering.

No code, test, configuration, or behavior changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior of the editor changes, so `skip_specs` is set.

## Impact

- `docs/architecture.md`: section 1 gains the principles; four sentences that repeat sections 2, 9, and 13 are shortened or removed to keep the budget.
- `docs/goals.md`: the sprint rule.
- `.claude/agents/planner.md`: the rubric citation and sprint mode step 2.
- CLAUDE.md: changed, the Agents Sprints line (a process change).
- README.md: changed, one clause. The brief asked for it unchanged, but `tools/gates.sh` (`gate_docs`) refuses an edit under `.claude/agents/` without a README change, with no proposal escape, and the README's planner step states the sprint rule this change extends, so it would otherwise go stale.
- `.claude/workflows/sprint-planning.js`: unchanged, it does not count a sprint's composition (it parses only the `review-due` line).

Outside the roadmap of `docs/architecture.md` section 12: a process change the user requested, sprint 6's first item and its pipeline slot.

## Out of scope

- A `make docs-lint` check that counts three features and two fixes: `tools/docs_lint.sh` counts only the pipeline items, and a new check would go beyond the brief.
- Any reordering of the queue beyond the user's sprint-6 decision, and any code change for H2 or M5.
- Reading `docs/backlog.md`.
