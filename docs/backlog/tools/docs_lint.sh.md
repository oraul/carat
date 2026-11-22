# Backlog: tools/docs_lint.sh

## The docs_lint budget comment has a sentence with no subject

- Where: the comment above `BUDGETS` in `tools/docs_lint.sh` (line 40 at 3a4db08), which reads "The queue's holds what the planner rewrites". Quality advisory of `agent-inputs`.
- Why it matters: the sentence drops its noun, so a reader raising or checking the queue's budget has to guess what it bounds.
- Fix outline: write "The queue's budget bounds what the planner rewrites and every agent may read at a start." Queued in `phase-shares`.
- Category: pipeline
- Added: 2026-11-04

## The architecture and the queue sit at their byte budgets

- Where: `BUDGETS` in `tools/docs_lint.sh` line 44: `docs/architecture.md` 88,058 of 88,064 bytes, at b76b722. Periodic quality. Queue items `breadcrumbs` and `architecture-drift`. At ce6abdb (periodic quality) the architecture is 88,063 of 88,064 bytes, so every spec change rewords text it does not change to fit, as #93 did; queue item `docs-index`. Raised again at be4b63a, 88,061 of 88,064 bytes (owner `docs-index`). At 9a92265 `.claude/agents/contributor.md` had 29 bytes left of 8,192 (#99 note 32); `url-email-guard` filled it to 8,192 adding `make hooks`.
- Why it matters: the next change adding a sentence to the architecture fails `docs-lint` in its check stage.
- Fix outline: trim history and detail the archived designs already hold to restore working headroom.
- Raised again at 6a0db20 (periodic quality, note 22): `docs/architecture.md` is 88,061 of 88,064 bytes (`tools/docs_lint.sh:44`). Owner: queue item `docs-index`.
- Also: docs/architecture.md, .claude/agents/contributor.md
- Category: pipeline
- Added: 2026-11-09

## The backlog has no byte budget

- Where: `docs/backlog.md` (301 KB, 471 entries at 5e4c140, up from 151 KB over 20 changes; 424,794 bytes at 9a92265) and `BUDGETS` in `tools/docs_lint.sh`. Periodic quality. Queue item `docs-index`. Duplicates for `backlog-compaction` (#99 notes 12 and 33), by their lines at 9a92265: 3976 repeats 3497, 2753 repeats 215, 3857 repeats 2313, 3851 repeats 2028, and the Makefile's timed compile is entered three times (2292, 3433, 3983).
- Why it matters: no agent can read it whole to find fixed entries or avoid recording a finding twice.
- Fix outline: give it a budget in `BUDGETS` and fold its entries per area, removing those no longer true.
- Also: Makefile
- Category: pipeline
- Added: 2026-11-09

### docs_lint header gives the old sprint size (`sprint-planning` quality advisory)

- Location: `tools/docs_lint.sh:19`, against the check at line 151 and the map.
- Why it matters: the header still says the sprint items are 1 to 5 while the check and the map moved to 0 to 5, a drained sprint.
- Fix outline: say 0 to 5, 0 once the sprint's deliveries drained it.
- Category: pipeline
- Added: 2026-11-11

### The contributor budget is enforced twice

- Location: tools/docs_lint.sh:48 and tools/tools_test.sh:2540 (sprint-4 review, quality).
- Why: tools_test checks the size under 7000 and greps docs_lint for the budget line, so the limit lives in two places.
- Fix: keep it only in BUDGETS and drop the tools_test copy.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-14

## docs-lint scans the sprint section twice

- Location: tools/docs_lint.sh:157
- Why: the marker awk repeats the sprint-section scan of line 150's awk.
- Fix: one awk pass, or a shared helper printing the sprint section's lines that both filters read.
- Source: quality advisory, brief-only-relay.
- Category: pipeline
- Added: 2026-11-15

### docs-lint counts beyond-the-sprint items in the sprint cap

- Location: tools/docs_lint.sh:154 (sprint-8 review, quality); queued in `sprint-marker-tidy`.
- Why: run_state.sh leaves marked items out of the five, but docs-lint counts every numbered item, so five items plus one marked fail docs-lint though review-due accepts them.
- Fix: leave items whose parenthesis holds the mark out of the count, with a docs_lint case.
- Category: pipeline
- Added: 2026-11-16

### The docs-lint path check fails a delivery that removes a file its own queue entry names (ruby-structure-remove retro)
- Location: `tools/docs_lint.sh:128` (check_paths), over the delivery's own item in `docs/queue-feature.md`
- Why: ruby-structure-remove's check failed in 5 s on 2 removed paths its own queue item named: first.check 0, 1 rework round (a contributor fix start and a second checker start, check 6,950 output tokens over two passes), and the fix's queue edit was discarded by plan-apply; check first pass 142/144.
- Fix: a delivery deleting a file its own queue entry names passes the check on its first pass with no hand edit of a lane queue; accepted when the next such delivery records first.check 1.
- Also: docs/queue-feature.md
- Category: pipeline
- Added: 2026-11-17

### docs-lint's own queue item skip needs a symbolic branch (pipeline-diet quality)
- Location: tools/docs_lint.sh:134 (own_change)
- Why: own_change reads only a symbolic branch, so a detached checkout (CI's pull_request merge ref) never skips the own queue item; harmless today since plan-apply removes the item before the push, but the comment claims only the check clone.
- Fix: say so in the comment, or fall back to GITHUB_HEAD_REF.
- Category: pipeline
- Added: 2026-11-18

### The backlog-lane sprint size entry repeats the drift entry

- Location: `docs/backlog.md:8361` and `:8520` (`:8521` in the second review pass); `tools/docs_lint.sh:22`, `docs/codebase-map.md:55` (sprint-18-records quality review, raised twice)
- Why: "The code map says the backlog lane's sprint holds 0 to 2 items" repeats part of "Doc comments and map entries drift".
- Fix: merge the two at the next grooming.
- Also: docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-19

### tools/docs_lint.sh:23: the header says the backlog lane Sprint holds 0 (sprint-22 sweep quality)

- Location: `tools/docs_lint.sh:23`
- Why: the header says the backlog lane Sprint holds 0 to 2 items, and docs/codebase-map.md:55 repeats it, while check_queue checks backlog:3 (line 183) since the 3 + 3 sprint
- Fix: say 0 to 3 in each lane in the header and the map entry
- Also: docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-20

### docs_lint and the map say a backlog sprint holds 0 to 2 items (sprint-24 sweep quality)

- Location: `tools/docs_lint.sh:23`, `docs/codebase-map.md:55`
- Why: check_queue allows 3, as CLAUDE.md's three backlog changes ask.
- Fix: say 0 to 3 in both.
- Also: docs/codebase-map.md, CLAUDE.md
- Category: pipeline
- Added: 2026-11-21

### A plan's queue cut that greens a red main docs-lint waits for the package step

- Location: `tools/docs_lint.sh:208` (QUEUE_BUDGET 17,969, both lanes together) and the package step's `plan-apply`; showtabline note 4, backlog-per-file note 2.
- Why: showtabline's check at a3a1729 failed docs-lint on main's queue (18,297 of 17,969 bytes at 7f96588) though its plan cut the queue, first.check=0, rework 1 of 3, check 142,908 of 452,689 output (31.6 percent); backlog-per-file paid a fix round for the same base overrun (branch 18,295 bytes), check 36,159 output over three passes.
- Fix: a change that does not grow the lane queues passes while its base is over budget, and the commit pushing them over is the one refused; accepted when a plan that records a Red main docs-lint decision passes docs-lint at its first check without a fix round.
- Category: pipeline
- Added: 2026-11-21

### drift: the header says a sprint holds 0 to at tools/docs_lint.sh:22 (sprint-26 sweep quality, note 40)

- Location: tools/docs_lint.sh:22
- Why: drift: the header says a sprint holds 0 to 2 items in the backlog lane, but check_queue passes a share of 3 for both lanes (docs_lint.sh:232) and its own comment at :215 says 3, and docs/codebase-map.md area 1 (the docs_lint.sh bullet) repeats 0 to 2
- Fix: say 0 to 3 in each lane in the header and the map
- Also: docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-22
