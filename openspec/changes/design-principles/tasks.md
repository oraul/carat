# Tasks

## 1. Principles

- [x] 1.1 `docs/architecture.md`: add the Design principles list to section 1 (deep modules with H2 and M5 cited, no broken windows) and shorten the statements other sections repeat to stay within the budget. Verify with `make docs-lint` (budget) and `make test-one T=test/lint.rb` (map paths).

## 2. Sprint mix

- [ ] 2.1 `docs/goals.md`: add the mix of three features and two fixes, T0 outside it, to the sprint rule. Verify with `make docs-lint`.
- [ ] 2.2 `.claude/agents/planner.md`: the rubric citation of step 2 and sprint mode step 2 state the mix and the decision's evidence `3 features, 2 fixes`, within 8,192 bytes. Verify with `make docs-lint`.
- [ ] 2.3 `CLAUDE.md` Agents Sprints line and the README's planner step state the mix. Verify with `make docs-lint` and `make gates` (docs gate).

## 3. Gates

- [ ] 3.1 Run `make gates` and `make spec-validate` and fix what fails.

## Workflow follow-up

- The package step runs `sh tools/run_state.sh groom design-principles`, applying the waiting sprint-6 plan in `build/plan/` with the user's decision, and archives with `openspec archive design-principles -y --skip-specs`.
