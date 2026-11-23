# Proposal

## Why

The sprint close's quality review runs inside the planner's one sprint start, capped at 80 calls, which also does the planning. The files it does not cover were only counted: at the Sprint 29 close that was 46 files not reviewed (docs, tests, specs, and `tools/tools_test.sh`), so the review was recorded partial and those files were never reviewed. The change is the user's request that the review cover the tests too.

## What Changes

- Change `.claude/workflows/sprint-planning.js`: when the planner's review returns files in `not_reviewed`, one more start of the quality reviewer in its new sprint mode reviews exactly those files, and its counts, notes, and files still left merge into the planner's review (`mergeQuality`, the counterpart of `mergeSecurity`); its notes reach the run state through the same record start as the planner's.
- Change the periodic-quality record: it is `partial` while any file is still left after the continued start (also when that start returned no result), never `pass`; the report's Quality line names the coverage (files the first start left, how many the continued start reviewed, those still left).
- Add a Sprint mode section to `.claude/agents/quality-reviewer.md` for the continued start, and have `.claude/agents/planner.md` name every diff file not reviewed in `not_reviewed` at its cap.
- Document it in CLAUDE.md (Agents, Sprints) and README.md (the sprint close paragraph).
- Add tools-test cases that run the whole sprint close with each start answered from a table: a first review leaving test files gets a continued review over them, passes when it covers them, is partial when files remain or the continued start returns nothing, and starts none when nothing was left.

Assumptions: the continued start reads the same detached tip worktree the planner uses; its findings arrive after the planner wrote the queue, so they are recorded as quality notes of the sprint's run state, which the next sprint's planning reads, and do not shape this sprint's queue (recorded in the findings file); `.claude/agents/planner.md` is within 3 bytes of its docs-lint budget, so two of its sentences were shortened to make room.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `.claude/workflows/sprint-planning.js`, `.claude/agents/planner.md`, `.claude/agents/quality-reviewer.md`.
- Tests: `tools/tools_test.sh` (the new cases; the cases that counted the quality-reviewer starts and the planner's wording updated).
- Docs: CLAUDE.md (Agents, Sprints), README.md (the sprint close paragraph).
- docs/architecture.md: unchanged, no spec changed and it does not describe the sprint close's review.
- docs/codebase-map.md: unchanged, no file added, moved, or removed.
- No edit of `tools/rules.sh`.
