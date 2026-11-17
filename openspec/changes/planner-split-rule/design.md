# Design

## Context

The planner's step 3 split only a brief of "more than about four separate fixes". Four-part briefs ran whole and overran (rework-guards, backlog-lane-b; #166 with 4 fixes used 3 of 3 rework rounds, quality first pass 0; the T1 rows of the last 10 backlog rows used 9 rework rounds over 5 changes). The archived `parallel-lanes-b` design drafted CLAUDE.md wording for the lanes, which the user has now approved verbatim. Both files sit at their byte budgets in `tools/docs_lint.sh`: planner.md 8,186 of 8,192, CLAUDE.md 30,711 of 30,720.

## Goals / Non-Goals

Goals: the planner splits a brief of three or more independently testable parts or map areas, sizes one step up after two overruns of comparable rows of its lane, and proposes the split of what a round-limit stop left; CLAUDE.md carries the approved lanes wording; both files stay within their budgets.

Non-goals: any other planner rule, the workflow script, `tools/rules.sh`, `docs/goals.md` (the planner's charter, rewritten only when asked).

## Decisions

- Step 3 keeps its sentences in order, the merge-gate sentence verbatim (a tools test asserts it). The size-up clause follows the estimate it changes; the round-limit clause follows the split it extends, written to `notes`, where the contributor and the next planner read it.
- Bytes for planner.md come from wording that restates or points, never from a rule: the intro and the description repeat "never a tracked file" (the intro keeps it); the two `quality-*` notes (`quality-blocking`, `quality-advisory`, the only such notes in the workflow) are named by their prefix; "(read with `git show`)" and the `tools/docs_lint.sh` pointer are guidance the planner does not need to follow a rule. Result: 8,189 bytes.
- CLAUDE.md takes the draft line for line, the Commands run state bullet included, since the draft names it and was approved verbatim; the file is 30,714 bytes, as the draft said. The split rule would need about 70 more bytes, so it stays in planner.md and README.md alone, as the brief allows.
- README.md, whose planner step describes the size check, states the new rule, so the docs gate's README requirement for an agent-file edit is met by a real update.

## Risks / Trade-offs

- "three or more ... parts or map areas" folds the brief's two clauses into one phrase to fit the budget; read as written it says the same.
- docs/goals.md keeps the older figure until the planner is asked to rewrite it; planner.md is the rule the planner follows.
