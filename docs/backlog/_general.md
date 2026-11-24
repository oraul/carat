# Backlog: entries naming no file

## Spinel's slab release stalls keys on transparent huge pages

- Where: Spinel's runtime, `lib/sp_slab.c` at the pinned `SPINEL_REF`: at the end of a full collection every entirely free slab chunk beyond a small reserve is handed back with `madvise(MADV_DONTNEED)`, and arenas are marked `MADV_HUGEPAGE`, so the next allocation that needs a chunk faults in a fresh huge page.
- Why it matters: on a host whose huge page defragmentation is `madvise` that fault stalls for compaction, and single keys take 8 to 12 ms although the collection itself is under 2 ms; with `SPINEL_SLAB_HUGE=0` the slowest keys of the `make bench` scenarios drop to 1.2 to 2.0 ms (medians of the slowest key are 0.68, 1.67, and 1.46 ms for `l h`, `j`, and typing, against maxima of 2.29, 2.35, and 11.97 ms with huge pages on). The `render-core` target of no key over 2 ms is missed because of it.
- Fix outline: report it upstream to Spinel with the benchmark and the `SPINEL_SLAB_HUGE=0` measurement, asking for released chunks to be kept for a while or for huge pages to be skipped for small heaps; until then, a workaround is to keep released chunks resident (a larger per-worker reserve) if Spinel exposes it, or to document `SPINEL_SLAB_HUGE=0` for interactive use, and bump `SPINEL_REF` in its own change once the runtime changes. Rechecked at f34005bf: still open, `lib/sp_slab.c` still releases with `MADV_DONTNEED` on `MADV_HUGEPAGE` arenas.
- Category: editor
- Added: 2026-11-01

## The pipeline has no replay benchmark

- Where: the pipeline as a whole; its only measures are the per-run rows of `docs/metrics.tsv`. From the user's insights review in the brief of `pipeline-speed-c`.
- Why it matters: a workflow change is judged on the next live runs, whose changes differ, so its effect on tokens and rounds is mixed with the change's own size; a replay of a fixed past change would isolate it, but at about 1M total tokens per replay, near a medium budget each, a self-tuning loop of replays costs more than the runs it would tune.
- Fix outline: once the per-run figures settle, replay one small recorded change at a pinned commit after a workflow change that claims a saving, and compare its total tokens, calls, and rounds with the recorded row; no automatic tuning loop.
- Category: pipeline
- Added: 2026-11-04

## Diagnostic columns are UTF-16 units

- Where: `JsonRpcLanguageGateway#diagnostic_of` at `lsp-diagnostics`: `Diagnostic#col` keeps the server's `character`, counted in UTF-16 units, the protocol's default.
- Why it matters: on a line with characters outside the ASCII range the column differs from the code point column the editor uses, so a jump would land on the wrong character. `diagnostics-display` draws by row only (the sign and the message row), so nothing reads the column yet.
- Fix outline: convert with the line's text when a position is used, or negotiate `utf-32` through `general.positionEncodings`, in the later `definitions` change, whose jumps are the first to read a column, with a row on a line holding a character outside the BMP.
- Category: pipeline
- Added: 2026-11-07

## The diagnostics display leaves out navigation, the full text, and colors

- Where: `diagnostics-display` (`Buffer#set_diagnostics`, `FramePresenter#paint_diagnostic`). Left out of the change by its proposal.
- Why it matters: Neovim users expect `]d` and `[d` to move between diagnostics and a float with the full message of several lines; the signs are drawn in the one `SignColumn` group, not in `DiagnosticSignError` and its siblings, so an error and a hint differ only by glyph; signs keep the icon set in force when they were published until the next publish.
- Fix outline: two motions over the buffer's marks bound in the five modes; a float showing the message; a group per mark in `SignLayer`, compared in `PaintedRows`; signs redrawn when `icons` changes. Each with a table row.
- Category: ide
- Added: 2026-11-07

## An image-viewer plugin is under discussion

- Where: none yet; a proposal under discussion with the user, moved out of `docs/queue.md` when the queue reached its budget, and parked, not scheduled, at `queue-handoff`.
- Why it matters: five formats, block characters from its own decoder, kitty and iTerm2 where available, bounded parsing, a size cap, only base64 or cells sent. GNOME Terminal shows neither protocol, so it needs the plugin's own PNG decoder.
- Fix outline: queue it as a T5 item when the user approves, sized from the plugin rows of `docs/metrics.tsv`.
- Category: pipeline
- Added: 2026-11-09

## The package step adds a backlog entry that already exists

- Where: the contributor's package step; the `palette_add_plugin` entry was recorded twice (folded at 186ddfb). Periodic quality at 186ddfb, blocking, queued in `periodic-blockers-b` (the compaction itself is `backlog-compaction`).
- Why it matters: a repeat hides what is left and double-counts a tidy item.
- Fix outline: have the package step search the backlog for the same file and method before adding an entry.
- Category: pipeline
- Added: 2026-11-10

## The blocking quality finding of the periodic review at 2f54bb5 is unmarked

- Where: the periodic quality review at 2f54bb5 reported 1 blocking and 48 advisory findings (17 of 18 areas covered), but the run state of `implement-contracts-c` keeps its 38 findings as `note.12` to `note.49` without saying which one blocked. Queued in `periodic-blockers-b`.
- Why it matters: a blocking finding has to be fixed in its own change; while it is unmarked, the change cannot show it was fixed.
- Fix outline: find the blocking finding in the review's result, fix it with a test row, and remove its entry; if the result cannot be found, take it from the next periodic review.
- Category: pipeline
- Added: 2026-11-10

## Backlog entries are duplicated

- Where: `docs/backlog.md:209` and 2742 (the `Options#apply` duplication), 899 and 2111 (copies of `EditorState#clamp_col`). Periodic quality at ce6abdb; queue item `backlog-compaction`.
- Why it matters: one entry per finding; duplicates grow the file every planner and reviewer reads.
- Fix outline: fold each pair into one entry listing every location.
- Category: pipeline
- Added: 2026-11-10

## Copies in editing, substitute, and buffer-list code

- Where: the tabstop-or-8 fallback in `dispatcher.rb` line 111, `repeat_last.rb` line 104, `leave_insert.rb` line 69, `insert_tab.rb` line 22, `arrange_view.rb` line 42 (`Options#tab_width` exists); private `clamp` in `operate.rb` line 202 and `repeat_last.rb` line 116 (`EditorState#clamp_col`); `change_selection.rb` line 41 repeating `Operate#change`; dead `tabstop_of` in `extend_visual.rb` line 53; `remember` in `global_command.rb` line 81 and `substitute_lines.rb` line 113; the group append in `replacement.rb` lines 99 and 127; `digits?` in `history_command_handler.rb` line 65 and `buffer_command_handler.rb` line 98; `beside_side_windows?` in `files/quit.rb` line 66; `list_buffers.rb` line 74 asking `shown?` twice; `any_modified?` and `redo_seq` used only by tests. Periodic quality at e49f63d.
- Why it matters: each copy can drift from its original.
- Fix outline: one owner per behavior, dead code removed. Queue items: `editing-counts` (fallbacks, clamps, change, dead code), `substitute-tidy` (remember, group append), `buffer-list-tidy` (digits, shown, unused methods), `slots-tidy` (quit).
- Category: pipeline
- Added: 2026-11-10

## A pin bump has no way to build and bench its base at its own pin

- Where: the benchmark agent's base build and `make toolchain` with `PREFIX`. `spinel-bump` retrospective.
- Why it matters: in #95 the benchmark's documented step failed on main and it built a base toolchain by hand (14 calls, 9,929 tokens), and the contributor rebuilt the old toolchain in a scratch path inside a capped implement start.
- Fix outline: one documented way to build the base at its pin; acceptance: the next pin bump compares base and change with no hand-built toolchain. Queue item: `check-runner-safety`.
- Category: pipeline
- Added: 2026-11-10

## Backlog duplicates found at #96

- Where: `docs/backlog.md:2498`, `:2948`, `:3290` (resize with no subscriber three times, `leave` twice); `:1241` and `:3594` (the group count twice).
- Why it matters: the backlog grows by repetition (397,565 bytes).
- Fix outline: fold each into one entry listing every location. Queue item `backlog-compaction`.
- Category: pipeline
- Added: 2026-11-10

## Three backlog findings are entered twice

- Where: `docs/backlog.md:2255` and `:3702`, `:2580` and `:2742`, `:3468` and `:3690`. Periodic quality.
- Why it matters: one finding per entry.
- Fix outline: fold each pair. Queue item `backlog-compaction`.
- Category: pipeline
- Added: 2026-11-10

## The squash body keeps a superseded security line

- Where: the package and merge steps; retrospective note 13 of `url-email-guard`.
- Why it matters: #100's body reported the first security review after the fix round superseded it.
- Fix outline: none prescribed; accepted when the merger refuses a body whose security line differs from the last recorded review. Queue item `merge-gate-tidy`.
- Category: pipeline
- Added: 2026-11-11

## Small tidy-ups at bd86828 still holds two duplicate clauses

- Where: `docs/backlog.md`, the `Small tidy-ups found at bd86828` entry, its `plugin_events.rb:142` resize clause and its `spec_validate.sh:129` preview clause. Quality advisory of the `backlog-compaction` review.
- Why it matters: both clauses repeat standalone entries, the duplicates the `backlog-compaction` design says move to those entries, as was done for the df4654c entry.
- Fix outline: in the periodic review's backlog step, move both clauses to their standalone entries as Also listed bullets and drop them from the tidy-ups entry.
- Category: plugins
- Added: 2026-11-11

## pr-by-tag quality advisory at tools/pr_tag.sh:131

- Where: tools/pr_tag.sh:131 (removed by pr-on-push). Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: an ls-remote failure in wait becomes empty refs, so a wait that never read origin ends with 'no pull request's head is', naming the wrong cause.
- Fix outline: remember the failure and refuse with 'origin cannot be read' as push does.
- Category: pipeline
- Added: 2026-11-11

## Findings of float-edges at its package step
- Category: design
- Added: 2026-11-14

## Findings of palette-rows (quality advisories)
- Category: design
- Added: 2026-11-14

## Findings of top-rows
- Category: design
- Added: 2026-11-14

## Findings of spinel-compile-time
- Category: code-quality
- Added: 2026-11-14

## Findings of untyped-elephant, non-blocking
- Category: design
- Added: 2026-11-14

## Findings of the sprint-4 review and sweep
- Category: pipeline
- Added: 2026-11-14

## Findings of architecture-review at review
- Category: design
- Added: 2026-11-15

## Findings of the sprint-5 review
- Category: pipeline
- Added: 2026-11-15

## Findings of architecture-tidy's review
- Category: design
- Added: 2026-11-15

## Non-blocking findings of spinel-untyped-bump
- Category: code-quality
- Added: 2026-11-15

## Findings of spinel-warnings
- Category: code-quality
- Added: 2026-11-15

## Findings of the sprint-6 review and sweep
- Category: pipeline
- Added: 2026-11-15

## Findings of the sprint-7 review
- Category: pipeline
- Added: 2026-11-15

## Findings of the sprint-8 review and sweep
- Category: pipeline
- Added: 2026-11-16

## FloatSpec offset bound test finding is folded but unqueued

- Location: docs/backlog.md:6657; carat test float_spec.rb:61
- Why: "FloatSpec writes its offset bound test twice" is folded but unqueued while its sibling from the same delivery (the 83-column scroll_request.rb line) is pulled into windows-buffers-tidy.
- Fix: add the float_spec.rb:61 heading to that item's Backlog list, or say why it waits.
- Category: pipeline
- Added: 2026-11-17

## Backlog holds the already fixed stale insert acceptance figure entry

- Location: docs/backlog.md:6601
- Why: the folded entry "Lane queues state a stale insert acceptance figure" is already fixed by sprint-11-records (both queues now say insert 26.0 at line 3), so the backlog holds a done item.
- Fix: have the next sprint's groom remove it as fixed, or have the planner list such headings in groom.txt when its queues fix them.
- Category: pipeline
- Added: 2026-11-17

## Findings append can duplicate a heading on a retried delivery

- Location: the removed findings file of ux-fixes-a (removed by groom)
- Why: it held the ProcessPort and benchmark-phase entries twice each, appended twice by a retried or resumed delivery, and only the planner hand-listing them as duplicates kept them out of the backlog.
- Fix: make the findings append (or groom when folding) skip a heading already present, with a tools-test case.
- Category: pipeline
- Added: 2026-11-17

## Three folded headings appear twice from the markdown-reading-c double append

- Location: docs/backlog.md:6775
- Why: the headings "Quality fails its first pass on about half the runs", "A resumed run records 0 output tokens for the phases done before the resume", and "A check pass after a fix round costs more than a first pass" were folded twice from the markdown-reading-c findings file's double append, which groom.txt did not list as repeats, so the backlog carries duplicate entries.
- Fix: have the next sprint grooming list the three as repeats so groom drops the second copies.
- Category: pipeline
- Added: 2026-11-17

## Quality advisory on the markdown-reading-c double append is folded twice

- Location: docs/backlog.md:6787 and docs/backlog.md:6790
- Why: the same quality advisory on the markdown-reading-c double append is folded twice in near-identical words, so the backlog holds a duplicate entry.
- Fix: keep one entry at the next grooming.
- Category: code-quality
- Added: 2026-11-17

### The groom appends the benchmark-phase and groom-output entries three times

- Location: docs/backlog.md:7218
- Why: the entries 'The benchmark phase measures records and docs-only runs that build nothing it measures' and 'Groom output needs a hand edit and draws the records runs' quality advisories' are appended verbatim twice (:7200/:7205 and :7218/:7223) and a third time as sprint-12-records retro notes 4 and 5 (:7268 on), the groom double-append the backlog already records (duplication).
- Fix: list the copies at :7218-7227 and :7268 on as duplicates at the next grooming and have groom not append both a groomed.md entry and the folded finding of the same note.
- Category: pipeline
- Added: 2026-11-17

### The groomed.md entries repeat the folded retro notes

- Location: docs/backlog.md:7176
- Why: the groomed.md entries at :7176-7198 (contributor self-check checklist, post-review prose edit, in-run budget line, scout packs, advisory classes) repeat the folded retro notes at :7228-7251 in near-identical words (duplication).
- Fix: keep one of each pair at the next grooming (backlog-dups).
- Category: pipeline
- Added: 2026-11-17

### Folded headings follow the previous entry with no blank line

- Location: docs/backlog.md:7176
- Why: the folded headings at :7176, :7209, and :7218 follow the previous entry with no blank line (format).
- Fix: have folded_backlog put one blank line before every folded heading, as the queued groom entry says.
- Category: pipeline
- Added: 2026-11-17

### Three sprint-12-records findings use level-two headings

- Location: docs/backlog.md:7253
- Why: the three sprint-12-records findings at :7253, :7259, and :7265 use level-two headings while every other entry is level three (format).
- Fix: make them level-three headings and have the findings append keep the entry level.
- Category: pipeline
- Added: 2026-11-17

### A folded entry is already resolved and its Location lines are stale

- Location: docs/backlog.md:7253
- Why: the folded entry on the three doubled headings is already resolved by this groom (groom.txt drops the duplicates), and the Location lines of :7253-7265 (docs/backlog.md:6775, :6787, :6790, :6751, :6765, :6861) point at pre-groom lines that now hold other entries (docs currency).
- Fix: list it as fixed at the next grooming and have findings name a heading instead of a backlog line number.
- Category: code-quality
- Added: 2026-11-17

### One blocking quality round costs a third of a medium budget (merge-record-check retro 8, overrun 6)

- Location: the rework round of the delivery workflow; the checker phase.
- Why: output rose from 129,569 at the first check pass to 210,601 at the second (+81,032, 27.6% of 294,037) for a rename in 3 shell helpers, crossing medium's 200,000 output; check 46,390 output in 12 calls over 2 passes against 2,431 to 6,411 on first-pass rows.
- Fix outline: accepted when over 5 rows with one rework round the round adds at most 40,000 output and check stays under 10,000 per pass. Queued in `check-skip`.
- Category: pipeline
- Added: 2026-11-17

## The folded heading after the merger entry lacks a blank line

- Location: docs/backlog.md:7360 (format).
- Why: the folded heading 'The merger returns pending before its 30-minute CI wait ends' follows the previous entry's Fix line with no blank line; the known groom defect recurs and make docs-lint does not catch it.
- Fix: insert one blank line before it, and let folded_backlog put a blank line before every folded heading, as the queued groom entry says.
- Category: pipeline
- Added: 2026-11-17

### A base defect a contributor names is not recorded
- Location: the contributor's return and the removed findings file of CHANGE; git-signs-transport retro note 7.
- Why: 1 base defect reported (the test file above), 0 recorded.
- Fix: the contributor appends a named pre-existing defect to its findings file; accepted when the next such defect appears there.
- Category: pipeline
- Added: 2026-11-18

### The tab-close-d findings entries drop the file's backticks and periods
- Location: the tab-close-d findings file, line 11 (folded into this file).
- Why: the three late entries drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use, two formats in one file (tab-close-d late finding at 5982df4f5353, quality advisory).
- Fix: backtick the locations and end each Location, Why, and Fix line with a period as the earlier entries do.
- Category: design
- Added: 2026-11-18

### The tab-close-d findings entries break the file's format (tab-close-d late finding)
- Location: the tab-close-d findings file, line 11 (folded into this file).
- Why: the three entries added at packaging drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use, two formats in one file.
- Fix: backtick the locations and end each Location, Why, and Fix line with a period, as above them.
- Category: design
- Added: 2026-11-18

### A tab-close-d findings entry is folded twice into the backlog
- Location: docs/backlog.md:8156, docs/backlog.md:8020
- Why: quality advisory, duplication: "The tab-close-d findings entries break the file's format" at :8156 repeats the entry at :8020 (same finding, Location, Why, and Fix under another heading), which the groom triage missed.
- Fix: list the :8156 heading as a duplicate in the next sprint's groom.txt.
- Category: pipeline
- Added: 2026-11-18

### Two fold format entries are covered by a third
- Location: docs/backlog.md:8066, docs/backlog.md:8072, docs/backlog.md:8171
- Why: quality advisory, duplication: "Fold adds a level-one heading per findings file" (:8066) and "Folded headings lack a blank line before them" (:8072) are covered by "Groom's fold keeps producing format defects" (:8171).
- Fix: groom the two into the :8171 entry at the next grooming.
- Category: code-quality
- Added: 2026-11-18

### The guide-colors retro entries are folded twice into the backlog

- Location: `docs/backlog.md:8396`, `:8401`, `:8406` repeating `:8377`, `:8382`, `:8387`; the `:8361`-area facet-palette and sprint-17-records entries (sprint-18-records quality review, raised twice)
- Why: the three guide-colors retro entries came in twice from facet-palette's findings file, and with the facet-palette and sprint-17-records entries make four near-same notes on advisory-only rounds.
- Fix: list the second copies as duplicate and merge the advisory-only notes into one in the next `groom.txt`.
- Category: pipeline
- Added: 2026-11-19

### Folded backlog entries lack the blank lines around their headings

- Location: `docs/backlog.md:8372`, `:8396`, `:8460` (`:8461` in the second review pass) and most added entries (sprint-18-records quality review, raised twice)
- Why: the entries lack the blank line after the heading and before the next heading, the same format defect groom's fold keeps producing.
- Fix: fold into the existing "Groom's fold keeps producing format defects" entry, or have groom normalize blank lines when folding.
- Category: pipeline
- Added: 2026-11-19

### Findings file holds a fixed entry and a stale duplicate
- Location: the removed findings file of finder-grep, the entries Grep helper duplication with the plugin and No bench scenario for the grep search
- Why: the duplication entry is fixed and the older bench entry (its Why still says it sorts every match) is superseded by the No grep scenario entry, so the file holds a fixed entry and a stale duplicate
- Fix: drop the fixed duplication entry and the older bench entry, keeping the new one (a grooming step, as no agent removes entries during a delivery)
- Category: pipeline
- Added: 2026-11-19

### Closing-loop retro entries folded twice verbatim
- Location: docs/backlog.md:8754 repeats :8709, and :8759 repeats :8714 (the closing-loop retro 10 and 11 entries).
- Why: finder-grep's findings file held them twice, and groom merged near-same notes but not exact repeats, so the backlog carries duplicates.
- Fix: list :8754 and :8759 as repeats in the next groom, and have groom drop an exact heading repeat within one fold.
- Category: code-quality
- Added: 2026-11-20

### Quality first-pass entries removed as fixed before their acceptance was met
- Location: docs/backlog.md:6524 (origin/main :6524 "Quality fails its first pass on about half the runs", :8091 "The contributor returns work the quality review blocks on its first pass").
- Why: the two entries are removed as fixed while their acceptance (7 or 8 first passes of the next 10) is unmet; the sprint-20 quality first pass is 1 of 7.
- Fix: keep one merged entry open until the measure is met, or fold its acceptance into the calibration decision.
- Category: pipeline
- Added: 2026-11-20

### Folded headings follow the previous entry's Fix line with no blank line
- Location: docs/backlog.md:8704, :8709, :8720.
- Why: the defect groom-fold-format already tracks; the folded headings run into the previous entry.
- Fix: groom-fold-format puts a blank line before each folded heading.

none
- Category: design
- Added: 2026-11-20

### Folded Correction entry points at a removed findings file
- Location: docs/backlog.md, the folded 'Correction' entry whose Location names the removed check-runner-safety findings file
- Why: the Location names a file this change removes, so it points at no file
- Fix: point it at the backlog entry '### Shared state a check stage can still write without failing the check'
- Merged: ### Backlog Correction entry names a removed findings file
- Location: docs/backlog.md:9262, the folded Correction entry whose Location names the removed findings file of check-runner-safety, which this change removes.
- Why: the Location points at no file once the findings file is gone.
- Fix: point it at the backlog entry "Shared state a check stage can still write without failing the check".
- Merged: ### Backlog Correction entry location still stale after the fix round
- Location: docs/backlog.md:9262, the folded Correction entry naming the removed findings file of check-runner-safety, still present; the fix commit recorded it here instead of fixing it in the change's own file.
- Why: the Location points at no file.
- Fix: point it at the backlog entry "Shared state a check stage can still write without failing the check" and drop the entry recorded above.
- Category: pipeline
- Added: 2026-11-20

### Duplicate file finder path sanitizing entries after the fold
- Location: docs/backlog.md, 'File finder rows and preview title show the listed path unsanitized', beside '### The file finder shows paths as the file lists them', the security Low bullet restating it, and two quality advisories about lines of the removed finder-grep-preview findings file
- Why: the fold kept near-same entries and two advisories about removed lines, so the backlog repeats itself
- Fix: merge the unsanitized-path entry and the security Low bullet into '### The file finder shows paths as the file lists them' keeping the security Low (5) rating and the U+202E test outline, and drop the two advisories about the removed findings file
- Merged: ### Backlog finder path entries duplicated after the fold
- Location: docs/backlog.md:9364, "File finder rows and preview title show the listed path unsanitized", beside its near-same "The file finder shows paths as the file lists them" (9359), restated by the security Low bullet at 9370, with two quality advisories at 9371-9372 about lines of the removed findings/finder-grep-preview.md.
- Why: one problem is listed three times and two advisories cite a file that no longer exists.
- Fix: merge 9364 and 9370 into 9359 keeping the security Low (5) rating and the U+202E test outline, and drop 9371-9372.
- Merged: ### Backlog finder path duplication still present after the fix round
- Location: docs/backlog.md:9359-9372, the file finder unsanitized-path entries and the two advisories about the removed findings/finder-grep-preview.md; the fix commit recorded it here instead of fixing it.
- Why: the same problem stays listed three times beside advisories citing a removed file.
- Fix: merge 9364 and 9370 into 9359 keeping the security Low (5) rating and the U+202E test outline, drop 9371-9372, and drop the entry recorded above.
- Category: security
- Added: 2026-11-20

### The second groom-stale-prune finding lacks a blank line and names an absolute path

- Location: the removed findings file of groom-stale-prune, the second entry (reported by two quality review passes, unchanged between them).
- Why: it has no blank line after its heading, unlike the first entry and the other findings files, and it names the absolute checkout path of build/metrics/current.tsv, which ties the note to one machine.
- Fix: in the grooming that folds this file in, add the blank line after the heading and name the path relative to the main checkout (build/metrics/current.tsv).
- Category: design
- Added: 2026-11-21

### backlog.md repeats of earlier review-trust-lows-b headings

- Location: the three review-trust-lows-b headings folded at the end of docs/backlog.md repeat earlier entries.
- Why it matters: repeats inflate the backlog and the next grooming.
- Fix outline: merge each into its earlier heading in the next grooming, or have groom merge an exact-heading repeat.
- Category: design
- Added: 2026-11-21

### sprint-24-records repeats entry names no headings

- Location: the removed findings file of sprint-24-records, the repeats entry names only the three headings at the end of docs/backlog.md, not which headings they are nor the earlier entries they repeat (the review-trust-lows-b headings folded at the end of docs/backlog.md repeat the entries near lines 3905, 4026, and 4564).
- Why it matters: the next grooming must rediscover the three headings and their earlier twins before merging them.
- Fix outline: in the next grooming, list each folded review-trust-lows-b heading beside the earlier heading it repeats, and merge each pair.
- Category: pipeline
- Added: 2026-11-21

### Backlog entries resolved by tabs-only-dot
- Location: the backlog entries "The ascii gem and the ascii modified mark are both `*`" and "tab_boundary? takes a digit after a gem as a tab boundary"
- Why: this change removes ASCII_GEM and tab_boundary?, so both entries are fixed
- Fix: groom removes both as fixed by tabs-only-dot
- Category: design
- Added: 2026-11-21

### Backlog entries resolved by tabs-only-dot remain listed
- Location: the backlog entries 'The ascii gem and the ascii modified mark are both *' and 'tab_boundary? takes a digit after a gem'
- Why: ASCII_GEM and tab_boundary? were removed by this change, so both entries are stale.
- Fix: groom removes both as fixed by tabs-only-dot.
- Category: design
- Added: 2026-11-21

### Findings file for tabs-only-dot repeats the scenario-title entry
- Location: the removed findings file of tabs-only-dot, the earlier entry about the scenario keeping a name that no longer fits and the later 'The MODIFIED scenario title still says gem'
- Why: two entries share the location and fix; the proposed new title, spec path, and test line are folded into the entry above.
- Fix: groom keeps one entry and drops the other as a repeat.
- Category: code-quality
- Added: 2026-11-21

### The state file is written through a link and without a lock
- Location: carat/use_cases/files/save_recent_files.rb
- Why: `FilePort#write` follows a symbolic link at the state file and two editors ending together leave the later one's list. The file is in the user's own home and holds a convenience list, so neither loses anything that matters.
- Fix: write a temporary file and rename it over the state file, and merge the file's current paths with the list at save.
- Category: design
- Added: 2026-11-23
