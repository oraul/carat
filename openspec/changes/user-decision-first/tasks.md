# Tasks

## 1. The rule and the check

- [x] 1.1 Add the first rule to `.claude/agents/planner.md`, the size check reading "where the user decided nothing", within the 8,192-byte budget
- [x] 1.2 State the rule in `docs/goals.md` before the size check and the sprint rule, and tie `docs/brief-standard.md` to it
- [x] 1.3 Carry the rule and the brief's USER DECISIONS in the delivery planner start, and refuse a split plan against a one-delivery decision
- [x] 1.4 Carry the rule in the sprint planner start
- [x] 1.5 Name the rule in the `CLAUDE.md` planner bullet within its budget

## 2. Tests

- [x] 2.1 tools-test cases failing before: both prompts carry the rule, the delivery's with the USER DECISIONS ahead of the plan request; the agent file states it before the size check and the `CLAUDE.md` planner bullet names it; the plan validation refuses a split and accepts a recorded override, a brief with no decision, and a plan with no split

## 3. Quality review

- [x] 3.1 Review the diff by the quality reviewer's steps and settle each finding
- [x] 3.2 Record the advisory finding of the duplicated rule text and the unpinned documents in `docs/findings/user-decision-first.md`
