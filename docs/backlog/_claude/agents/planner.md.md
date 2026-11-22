# Backlog: .claude/agents/planner.md

## Backlog entries reach the contributor twice

- Where: `.claude/agents/planner.md:25` (`build/plan/backlog.md`) and `.claude/agents/planner.md:28` (plan notes), read at `.claude/agents/contributor.md:48`. Quality advisory of the `backlog-compaction` review.
- Why it matters: a finding to append can arrive both as a plan note and as an entry of `build/plan/backlog.md`, and the contributor can no longer read the backlog to avoid appending it twice.
- Fix outline: the planner writes backlog entries only to `build/plan/backlog.md`, and its plan notes keep the other bookkeeping.
- Also: .claude/agents/contributor.md
- Category: pipeline
- Added: 2026-11-11

### Planner claims docs-lint checks the sprint queue (`sprint-planning` quality advisory)

- Location: `.claude/agents/planner.md:35`, `tools/docs_lint.sh:135` `check_queue`.
- Why it matters: `check_queue` reads only `docs/queue.md`, so `build/plan/queue.md`'s sprint rule is first checked after `groom` copies it in a later package step.
- Fix outline: let `docs_lint` take the queue path (for example `QUEUE=build/plan/queue.md`) and have the planner run it, or reword the sentence.
- Also: tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-11

## records-once quality advisory at .claude/agents/planner.md:28

- Location: .claude/agents/planner.md:28, read by .claude/workflows/deliver-change.js:226 and :951.
- Why: step 7 lists the result fields but not the new optional records field the workflow reads, so the planner has only the schema description to know when to return it.
- Fix outline: add records: skip when the brief excludes history and groom to step 7.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-12

### End the workflow-trim sentence in planner.md with a period

- Location: .claude/agents/planner.md:26 (quality advisory, docs).
- Why: trimming the workflow-trim example left 'which the contributor chooses: A sprint item', a dangling colon before a new sentence.
- Fix: end the sentence with a period.
- Category: pipeline
- Added: 2026-11-14

### Make room in the planner and contributor agent files

- Location: .claude/agents/planner.md:1 and .claude/agents/contributor.md:1 (quality advisory, docs budget).
- Why: planner.md is 8189 of 8192 bytes and contributor.md 6996 of 6999 after the longer hook line, so the next edit to either must trim again.
- Fix: plan a pass moving restated rules to CLAUDE.md pointers before the next agent-file change.
- Also: .claude/agents/contributor.md, CLAUDE.md
- Category: pipeline
- Added: 2026-11-14

## The planner agent does not name the sprint exception marker line

- Location: .claude/agents/planner.md:35
- Why: it still states at most one pipeline item (T0 exempt) with no word on the 'The user-approved exception' line docs-lint now honors and the planner is the one to write.
- Fix: name the marker line and when to write it there.
- Source: quality advisory, brief-only-relay.
- Category: pipeline
- Added: 2026-11-15

### The planner's size check lost the output-only rows caveat
- Location: .claude/agents/planner.md:23
- Why: rows before pipeline-speed hold output tokens only and remain in both lane histories, so a total-token estimate read from them is skewed low; the clause did not fit the file's budget in this change
- Fix: restore the one-clause caveat, making room by pointing to a note elsewhere in the file
- Category: pipeline
- Added: 2026-11-16

### backlog-pick dies on an unmatched findings glob
- Location: .claude/agents/planner.md:35 and .claude/workflows/sprint-planning.js:150, with tools/run_state.sh:1760
- Why: the planner and sprint-planning call backlog-pick docs/backlog.md docs/findings/*.md, but groom removes every findings file (tools/run_state.sh:1973), so a sprint whose changes left no findings passes the literal glob and the pick fails with no docs/findings/*.md.
- Fix: have backlog_pick skip an unmatched literal glob argument, or have the callers name only existing files.
- Also: .claude/workflows/sprint-planning.js, tools/run_state.sh
- Category: pipeline
- Added: 2026-11-17

### planner.md says the contributor appends the plan's backlog file
- Location: .claude/agents/planner.md:25
- Why: step 5 says the contributor appends build/plan backlog.md to its findings file, but plan-apply does it (tools/run_state.sh plan_apply) and the CLAUDE.md Backlog bullet says so, so the planner's rules drift from the script.
- Fix: write "which plan-apply appends to the change's findings file", within the 8,192-byte budget.
- Also: tools/run_state.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-17

### Planner and scout resolve the brief's locations twice (ci-trust-gaps retro)
- Location: `.claude/agents/planner.md`, `.claude/agents/scout.md`, `.claude/workflows/deliver-change.js` (the plan and scout phases)
- Why: ci-trust-gaps spent plan 28,293 plus scout 48,985 = 77,278 of 252,190 output tokens (30.6 percent) and 28 of 172 calls, the planner and scout disagreeing on one location (`deliver-change.js:614` against `:618`); tab-close-b 33.7 percent, check-parallel 29.8 percent.
- Fix: one of the two resolves locations and the other reuses its pack; accepted when the next three pipeline-lane rows hold plan plus scout under 20 percent of output tokens with no location re-corrected by the scout.
- Also: .claude/agents/scout.md, .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

### The planner's Already met check counts untracked lane files (vim-case-operators retro 19)
- Location: `.claude/agents/planner.md`, the Already met and size check.
- Why: the planner reported 99 rows and bindings at d7f5de8 that were untracked in the lane worktree, so a 770-line, 33-file change was sized small: 568,067 output tokens against the 83,333 small output budget (6.8 times), overrun notes 13, 14, 15, 16, 18 at every check pass (108,357 to 492,616), 2,564,423 total in 190 min.
- Fix: Already met cites only paths tracked at origin/main; accepted when a tools-test case with an untracked file in the lane is not counted as met.
- Category: pipeline
- Added: 2026-11-20

### A plan's queues exceed the docs-lint queue budget at the package step (review-trust-lows retro note 14)
- Location: `.claude/agents/planner.md` step 5 and `tools/docs_lint.sh:61` (QUEUE_BUDGET 17969); queued as backlog Pool 13 `queue-fit`.
- Why: after plan-apply docs-lint failed with 18,149 lane-queue bytes against 17,969; the contributor trimmed the backlog queue in 88ae4ef and dropped a planner decision line; package took 27 calls, the most of the last 10 backlog rows (range 11 to 24).
- Fix: the plan is checked against the budget with the other lane's current queue before it is returned; accepted when no package step trims a queue after plan-apply and package calls stay at or under 22.
- Also: tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-21

### A split part may deliver no behavior (status-winbar-tabs retro note 6)
- Location: `.claude/agents/planner.md` step 3 (the split rule); status-winbar-tabs (#262) run state notes.
- Why: status-winbar-tabs was split by painter size and the status-bar part it kept already had the Facet look, so the run spent 182,285 output tokens and 136 tool calls on one constant move and tests (plan 21196/13, scout 41011/25), merged as a refactor with skip_specs.
- Fix: every part a split delivers or queues names a frame row or test that fails at the split commit (applied by hand in the status-winbar-tabs-b plan); accepted when the next two split deliveries each change a row their acceptance names.
- Category: pipeline
- Added: 2026-11-21

### The size check runs only in the delivery planner, so an oversized queue item costs a delivery-time split (sprint-close-lows retro note 3)
- Location: `.claude/agents/planner.md` (sprint mode step 2), `docs/goals.md` (size check).
- Why: sprint-close-lows was queued with 10 headings in 3 areas and split at delivery; its plan 35,540/13, 8.8 percent of output tokens, the highest of the last 10 backlog rows (others 7,690 to 20,300).
- Fix: accepted when the sprint queue holds no item over about four headings and no delivery of the next sprint records a Split decision, its plan under 20,300 output tokens.
- Also: docs/goals.md
- Category: pipeline
- Added: 2026-11-22
