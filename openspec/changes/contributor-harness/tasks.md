# Tasks

## 1. The lane facts script

- [x] 1.1 `tools/lane_facts.sh`: print head, branch, base, pushed, dirty, check, and check_at from git and the check log; refuse a bad name and a missing lane with exit 2.
- [x] 1.2 `tools/tools_test.sh`: the script's lines on a test repository with a lane worktree (clean, dirty, pushed, a check verdict, from the lane and the main checkout) and its refusals.

## 2. The workflow takes the head from git

- [x] 2.1 `.claude/workflows/deliver-change.js`: `laneHead` runs the script and parses head and dirty (`parseLaneFacts`); `headForm` takes a form-only head over a clean lane with a `head-form` note and no escalation or restart; a continued start keeps the lane head.
- [x] 2.2 `tools/tools_test.sh`: a placeholder, short, or upper-case head over a committed lane is taken from git with no escalation; a dirty lane still refuses it; a foreign head still refuses; the existing head-guard cases follow.

## 3. Point agents at the script

- [x] 3.1 The rules card in `.claude/agents/contributor.md` and `CONTRIBUTOR_CARD`, the head restart text, the resume prompt, and the contributor's schema name the `head` line of `tools/lane_facts.sh`.
- [x] 3.2 `tools/agent_guard.sh`: every profile may run `sh tools/lane_facts.sh CHANGE`; `tools/tools_test.sh` proves the form and its refusal.

## 4. Documents

- [x] 4.1 `docs/goals.md` escalation paragraph, `docs/codebase-map.md` area 1, and CLAUDE.md Commands.

## 5. Checks

- [x] 5.1 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`.

## Quality review

- [x] 6.1 `tools/lane_facts.sh`: `dirty` read 0 when `git status` failed, so an unreadable lane passed as committed; it now reads `unknown`, which `parseLaneFacts` keeps as -1, proved by the `lane_facts: a lane git status cannot read reads dirty unknown, never 0` case in `tools/tools_test.sh` (fixed).
- [x] 6.2 `.claude/workflows/deliver-change.js` `headForm`: the empty and non-hex tests were two branches of one rule; folded into one (fixed, the head-form cases unchanged).
- [x] 6.3 `.claude/agents/merger.md` and `.claude/agents/quality-reviewer.md` still copy main's short sha by hand; outside a lane, so recorded in `docs/findings/contributor-harness.md` (recorded).
