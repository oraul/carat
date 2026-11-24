### The goals and brief-standard texts of the user-decision-first rule are not pinned by a tools-test case
- Location: `docs/goals.md` (the rubric's first bullet, the size check and sprint bullets), `docs/brief-standard.md` (the USER DECISIONS label and the split-first line), `tools/rules.sh:98` (`TOOLS_RE`).
- Why: the brief asked for a case that `docs/goals.md` states the rule before the size check, but tools-test refuses to read a path `TOOLS_RE` does not match (`rules: TOOLS_RE matches every repository path tools-test reads`), and `docs/goals.md` and `docs/brief-standard.md` are not in it; a `tools/rules.sh` edit goes first, alone, so it is not part of this change. The planner agent file, the `CLAUDE.md` planner bullet, and both workflow prompts are pinned.
- Fix: a separate small change adds `goals` and `brief-standard` to the `docs/(...)` alternation of `TOOLS_RE`, then a case compares the line order of the user-decision-first bullet, the size check, and the sprint bullet in `docs/goals.md`.
### The user-decision-first rule text is duplicated in the two workflow files
- Location: `.claude/workflows/deliver-change.js` (`USER_FIRST`), `.claude/workflows/sprint-planning.js` (`USER_FIRST`).
- Why: the two constants differ by a few words and can drift; each workflow is a standalone script with no shared module, so the duplication was kept rather than inventing a loader.
- Fix: when the workflows gain a shared helper file, move the one sentence there and have both prompts read it; until then a tools-test case compares the key phrases of both.
- docs/goals.md:21 (and docs/brief-standard.md:18): the user-decision-first wording after the security-first step and T0 is not pinned by tools-test. Why it matters: TOOLS_RE in tools/rules.sh does not match docs/goals.md, so a test reading it fails the rules check, and the rule's text there can drift from the agent file's. Fix outline: land a small change that adds docs/goals.md to TOOLS_RE (the merge gate's rules go first, alone), then pin the sentence with a tools-test case.

### The user-decision-first wording in docs/goals.md is not pinned by tools-test
- Location: docs/goals.md:21, docs/brief-standard.md:18
- Why: TOOLS_RE in tools/rules.sh does not match docs/goals.md, so a tools-test case reading it fails the rules check and the sentence after the security-first step and T0 can drift from the agent file's.
- Fix: land a small change that adds docs/goals.md to TOOLS_RE (an edit of the merge gate's rules goes first, alone), then pin the sentence with a tools-test case.

none
