# Design

## Context

The planner decides by `docs/goals.md`: tiers, the sprint rule, then the size check. A brief carries the user's decisions on its USER DECISIONS line, but nothing ranks them above those rules, and the delivery workflow never checks the plan against them.

## Goals / Non-Goals

**Goals:**
- The user's decision is the first rule in the planner agent file, `docs/goals.md`, and both planner starts.
- A plan that splits a brief the user decided as one delivery is refused.

**Non-Goals:**
- The sprint size, early close, and extension options.
- Any edit of `tools/rules.sh`.

## Decisions

- The rule is one sentence in each place (agent file, goals, two prompts), because the planner reads the prompt first and the agent file as its standing rules; the delivery prompt adds the brief's USER DECISIONS text when it is not `none`.
- The plan validation is a function over the brief text and the plan result: it fires only when the brief's USER DECISIONS says one delivery or no split, and a decision or note that reads as a split without naming an override stops the run with the decision quoted. Alternative: a new plan schema field for the split; rejected, since the schema is the planner's contract and the free-text decisions already carry the split.
- The agent file stays within its budget by shortening wording, not by raising the budget.

## Security first

The user's decision applies after the planner's security-first step and T0, never ahead of them: a decided order or sprint's contents cannot put a blocking security fix behind other items. Every copy of the rule says so, and tools-test pins the wording.
