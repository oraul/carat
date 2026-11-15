# Design

## Context

The brief has three parts: two binding design principles in `docs/architecture.md`, a sprint mix of three features and two fixes in the planner's rules, and the user's sprint-6 decision for the waiting plan. Three of the files are at their byte budgets (`BUDGETS` in `tools/docs_lint.sh`): `docs/architecture.md` 87,973 of 88,064, `.claude/agents/planner.md` 8,190 of 8,192, `CLAUDE.md` 30,597 of 30,720.

## Decisions

- Place the principles in section 1, Goals and non-goals, as a third list, since they bind every change as the goals do and the document has no other general section. Each names its source book without a URL and states the rule in one sentence; deep modules cites H2 and M5 of the archived architecture review as its examples.
- Make room in `docs/architecture.md` by removing what the document already says elsewhere, never by raising the budget: the introduction's account of the vendored header and the refusing `ruby` (section 2 holds both), the Buffer paragraph's piece-table sentence (section 13's Text storage row), the PluginHost paragraph's sentence that the finder, explorer, and git signs are plugins (section 9's opening), the benchmark baseline aside and a parenthesis on how `spin test` judges in section 2, and a shorter Ractor non-goal.
- The mix counts the pipeline change, when a sprint has one, as one of the two fixes, since the goals define a pipeline change as workflow, agents, CI, tools, or process docs, all fix kinds by the brief; T0 stays outside both counts.
- The planner cites the mix as `3 features, 2 fixes` in a sprint decision, the evidence line beside its other cited numbers; in `planner.md` the room comes from one of three metric examples, the guard-allowlist output figure (its total kept), and a clause of step 7 that restates the workflow.
- `sprint-planning.js` stays unchanged: it parses only the `review-due` line and never counts a sprint's makeup, so no rule there reads the mix.
- The sprint-6 decision is already in `build/plan/queue.md` (the planner applied it with its decisions); this change edits no file under `build/plan/`, and the package step's `groom` applies it.

## Risks

- The README changes against the brief's wording: the docs gate requires it for an agent file edit and the README states the sprint rule. Named in the proposal and the pull request.
- Nothing enforces the mix: a check in `tools/docs_lint.sh` is out of scope by the brief and left to a later request.
