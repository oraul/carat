# Backlog: docs/queue-feature.md

### Queue entries keep stale line references after their change edits the named code

- Location: docs/queue-feature.md:7 (the `ruby-structure-remove` entry), test/lint.rb (the named-path check)
- Why: the delivery had to unquote the two paths it removes so lint's path check passes, leaving the entry's line references (plugin.rb:86 and :111, tokenizer.rb:820, test/plugins_ruby.rb:145) pointing at code that no longer exists, and a delivery editing its own planner-written queue entry bypasses plan-apply.
- Fix: leave queue entries to plan-apply and have the lint path check skip docs/queue-*.md entries whose change is the branch's own, or drop the stale line numbers from queue entries.
- Also: test/lint.rb, test/plugins_ruby.rb
- Category: pipeline
- Added: 2026-11-17

### The Sprint 17 feature decision still places tab-close-d at place 1
- Location: `docs/queue-feature.md:30`.
- Why: the merge resolution of tab-close-d removed it from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list holds vim-folds-b at 1 and vim-line-commands-c at 2 (tab-close-d late finding at 5982df4f5353, quality advisory).
- Fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2.
- Category: pipeline
- Added: 2026-11-18

## Findings of tab-close-d after its package step

- quality advisory docs/queue-feature.md:30 docs currency: the merge resolution removed tab-close-d from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list now has vim-folds-b at 1 and vim-line-commands-c at 2; fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2
- quality advisory the removed findings file of tab-close-d one clear way: the three new entries drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use; fix: backtick the locations and end each Location, Why, and Fix line with a period as above
- Category: pipeline
- Added: 2026-11-18

### The feature lane queue names the retired docs/backlog.md

- Location: `docs/queue-feature.md:3` ("folded findings are in `docs/backlog.md`"); `RETIRED_QUEUE` in `tools/docs_lint.sh`.
- Why: a backlog-lane change may not edit the feature lane's files, so the line stays and docs-lint allows the retired path in a lane queue; the allowance should not outlive the line.
- Fix: the next feature-lane plan writes `docs/backlog/`; then remove `RETIRED_QUEUE` and its grep from `check_paths`, with its two `docs_lint:` lane-queue cases.
- Also: tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-21

### The lane queues exceed QUEUE_BUDGET on main

- Location: `docs/queue-feature.md` (6,884 bytes) and `docs/queue-backlog.md` (11,413 bytes) at 7f96588, against `QUEUE_BUDGET=17969` in `tools/docs_lint.sh`.
- Why: `make docs-lint` fails its queue check on main itself (18,297 bytes), before and after this change, so every branch's docs-lint stage is red until a plan shortens the queues.
- Fix: the next plan folds or shortens queue text (decisions of merged items first) to fit 17,969 bytes, never dropping a finding.
- Also: docs/queue-backlog.md, tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-21

### The lane queues exceeded their shared budget on main after #277
- Location: `docs/queue-feature.md`, `docs/queue-backlog.md`, budget `tools/docs_lint.sh:62` (QUEUE_BUDGET 17969)
- Why: at 7f96588 the two queues were 18,297 bytes together, so docs-lint fails on main and on every lane branch until one lane trims its queue; backlog-per-file trimmed only backlog-lane text (the merged backlog-records-rule's exception and three of its decisions), leaving the feature queue untouched as its brief requires.
- Fix: have plan-apply or the merger's gate refuse a queue rewrite that leaves both lane queues over the shared budget, so a lane's merge cannot push the other lane over it.
- Also: docs/queue-backlog.md, tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-21

### The feature queue still points at docs/backlog.md after the per-file move
- Location: `docs/queue-feature.md:3` ("folded findings are in `docs/backlog.md`").
- Why: `backlog-per-file` removes `docs/backlog.md` for `docs/backlog/<path>.md` files, and the feature lane's file is outside the backlog lane, so its pointer names a path that no longer exists.
- Fix: the next feature-lane plan or the sprint records change rewrites the line to name `docs/backlog/`.
- Category: pipeline
- Added: 2026-11-21

### A delivery's package step rewrote the feature queue to an older plan (tab-name-parent planner)

- Location: `docs/queue-feature.md` at 69e59b6 (#330, explorer-rows), against 092d282; `build/plan/tab-focus-mark/queue-feature.md`.
- Why: explorer-rows ran with no plan directory of its own, and its squash commit set the feature queue to the tab-focus-mark plan less its own line: `## Sprint 32` became `## Sprint 31`, the full `ui-groups-c` item and Pool 1 to 3 (`sidebar-head-tidy`, `tab-float-mark`, `explorer-look`) and the sprint-32 decisions were lost; only a later planner's diff against history caught it.
- Fix: the backlog lane's `plan-apply-stale` (Pool 17): plan-apply refuses a lane queue from a plan directory not the change's own, or one whose base blob differs from the lane's HEAD; a tools-test case with a stale plan fails before.
- Category: pipeline
- Added: 2026-11-24
