### An advisory-only round counts as rework and reruns every review (vim-folds-c retro 3, near-same to the pool's rework-review-repeat)
- Location: .claude/workflows/deliver-change.js, the round settling after a quality-advisory fix; docs/queue-backlog.md Pool `rework-review-repeat`
- Why: vim-folds-c recorded rework 1 with every first pass 1; the round fixing 2 quality advisories reran the check and both reviews, 30,104 plus 41,657 = 71,761 output (24.5% of 292,577), the second security pass finding 0; 6 of the last 20 lane rows record rework 1 or 2 with every gate first.
- Fix: fold into `rework-review-repeat`; accepted when, over the next 3 runs whose only round fixes advisories without a behavior change, metric.rework stays 0 and that round's check plus reviews output is under half of the first pass's.

### The merge phase spends output its work does not need on a green first CI (vim-folds-c retro 4, near-same to the pool's merge-output-cap)
- Location: .claude/agents/merger.md and the merge phase of .claude/workflows/deliver-change.js; docs/queue-backlog.md Pool `merge-output-cap`
- Why: vim-folds-c merge 32,655 output in 13 calls (11.2% of 292,577) with CI green in 9.6 min, 0 fixes, and 6 wait calls; the last 10 feature-lane merges have a median of 11,294 output (6,047 to 38,220).
- Fix: fold into `merge-output-cap`; accepted when, over the next 3 runs with a green first CI and no fix, merge output stays under 12,000 and CI-wait calls at most 4.

### The message row still shows the visual mode indicators the pill already shows
- Location: carat/adapters/frame_presenter.rb, `paint_message`, the VISUAL, VISUAL_LINE, and VISUAL_BLOCK branches; openspec/specs/visual-mode/spec.md, the requirement of the message row's visual indicator
- Why: the brief drops `-- INSERT --` because the status bar's pill shows the mode; `-- VISUAL --`, `-- VISUAL LINE --`, and `-- VISUAL BLOCK --` repeat the pill the same way and stay unstyled in `Normal`, so the row is inconsistent between insert and visual mode.
- Fix: drop the three branches, change the visual-mode and screen-rendering requirements and the tests of editor_visual and adapters_frame_presenter (the keys of a pending count stay at the right edge), or paint them in `ModeMsg` if they are kept.

### Nothing produces a warning or information level, a -- More -- pager, or a match count
- Location: carat/domain/editor_state.rb, `show` (one bool, `message_error`); carat/adapters/frame_presenter.rb, `paint_message_text`
- Why: the Facet message styling names a yellow warning icon, a bold blue `-- More --`, and a dim match count; message-styling themes `WarningMsg` and `MoreMsg` but no code paints them, and every non-error message is drawn as information.
- Fix: give `EditorState#show` a level (error, warning, information) with a producer for the warning icon, add a pager that draws `-- More --` in `MoreMsg` for a listing taller than the screen, and paint the `search-count` text in `MsgDim` at the right edge of the row.
