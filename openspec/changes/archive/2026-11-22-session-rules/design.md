# Design

## Context

`CLAUDE.md` is the binding short guide with a 30,720-byte docs-lint budget, 30,705 bytes before this change. `docs/goals.md` has no budget and already holds the delivery decisions with their reasons and dates. The main session's rules lived only in conversation.

## Goals / Non-Goals

Goals: the six rules readable by every session and agent, short in `CLAUDE.md`, with reasons in `docs/goals.md`; agreeing with the Sprints and Agents lines.

Non-goals: tooling that enforces them, a raised budget, a new file.

## Decisions

- A short section in `CLAUDE.md` and the detail in `docs/goals.md`, since the budget leaves no room and the goals file is where a decision with its reason is kept.
- The budget is paid for by deleting restated or example prose, not by raising the line in `tools/docs_lint.sh`, which would be outside the brief.
- Rule 4 cites the `contributor-tier-fixed` move instead of repeating it.
- Rule 6 names `review-due` as the `/sprint` start, matching the Sprints line (the main session starts `/sprint` after every merge, which ends at once until a sprint is due), so the two never contradict.
- Rules 2, 3, and 6 say a resumed run's `tokens` may refuse and a stopped run's total may be unset, and tell the main session to report the figure as unrecorded; they never claim success.

## Risks / Trade-offs

- A rule stated in prose is only as binding as its readers; the tooling side of rule 2 is the queued `plan-brief-amend`.
- `docs/goals.md` matches the instruction-records pattern of the gates, so a security pass is not settled across a later edit of it.
