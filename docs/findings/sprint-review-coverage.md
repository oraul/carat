### The continued quality review's findings do not shape the sprint's queue
- Location: .claude/workflows/sprint-planning.js (the continued quality-reviewer start after the planner's start)
- Why: the quality reviewer's continued start runs after the planner has written the next queue and the groomed findings, so a finding it keeps over the files the planner left is recorded as a quality note of the sprint's run state but cannot be queued or groomed by that planner; it is read by the next sprint's planning only.
- Fix: run the continued review before the planner's queue step, for example by splitting the planner's sprint start into a review start and a planning start, or hand the continued findings to a second short planner start that appends them to the groomed findings.
### The planner file sits at its byte budget
- Location: .claude/agents/planner.md (Sprint mode step 1, step 3, step 5, and the head of Sprint mode), tools/docs_lint.sh BUDGETS
- Why: the file was 3 bytes under its 8,192-byte budget, so adding the not_reviewed sentence meant dropping "a dropped one is not recorded" from step 1 (the PLAN schema description and CLAUDE.md still state it) and shortening three other phrases; the next addition to the file has no room.
- Fix: move the Sprint mode section's prose into a document the planner reads at a sprint start (as docs/contributor-notes.md holds the contributor's), keeping the rules card short, and restore the dropped sentence.
### The continued start's file list is agent text in a prompt
- Location: .claude/workflows/sprint-planning.js (the reviewTaskOf call for the quality continuation)
- Why: the files the planner returned in not_reviewed are joined into the continued start's prompt unfiltered, as the security continuation's are; a file name carrying instructions would reach a reviewer that holds the read guard but can still read the repository.
- Fix: pass each file through pathKey and keep only names matching a path pattern (no spaces or control characters) in both continuations.

### allocs.grep measured 685.3 once on identical sources
- Location: tools/metrics.sh measure, the grep scenario of bench/keys.rb
- Why: the metrics stage of the first check of this change read allocs.grep 685.3 against main's 685.0 though carat/, bench/, and the Makefile equal main's; three reruns of the same binary read 685.0 and the rerun check passed, so the allocation count of the grep scenario varies with load, which would block an unrelated change at random.
- Fix: find what in the grep picker's setup varies (a reader thread's timing, or the stages running beside the metrics stage), make the count exact or have measure take the lowest of a few runs for grep.
none
