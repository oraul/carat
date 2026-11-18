### Global :p copies every earlier printed line per match
- Location: carat/use_cases/search/global_command.rb:174
- Why: each :p in a global copies every earlier printed line into a new string, quadratic in the lines printed (:g/./p on a large file).
- Fix: append the printed lines to one mutable string or array and build the Outcome.from_print once after the loop.

### place_cursor clamps by the mode's max_col, not as in normal mode
- Location: carat/use_cases/ex/line_command_handler.rb:57
- Why: place_cursor now clamps through EditorState#max_col, which allows the column past the last character in insert and visual modes, where the old code always clamped as in normal mode (a line command run by a plugin's run_ex in insert mode or a : binding in visual mode); the new comment's '(the end of the line for a wanted column past it, -1)' is garbled.
- Fix: keep the normal-mode clamp or state the mode dependence and reword the comment.

### Doubled comma in the join handler's header comment
- Location: carat/use_cases/ex/join_command_handler.rb:18
- Why: the header comment reads 'what ExRange gives,, a bad count', a typo reported by two review passes (at bd2f7aad933d and 460a4404420f), merged here.
- Fix: drop the extra comma.

### Ragged wiring comment around HandleKey in EditorAssembly
- Location: carat/adapters/editor_assembly.rb:191
- Why: the edited comment reads 'registered afterwards, after HandleKey, which :normal receives, the core ex commands before the', a broken wrap with stacked clauses that leaves a short ragged line, reported by two review passes, merged here.
- Fix: rewrap the paragraph and say HandleKey is built before the ex handlers because :normal receives it.

### :normal runs HandleKey's follow for every key it feeds
- Location: carat/use_cases/ex/normal_command_handler.rb:99
- Why: each key :normal feeds goes through HandleKey#call, whose follow runs the completion, float, palette, and plugin observers and ArrangeView per key, so :%normal on a large buffer pays them for every key of every line.
- Fix: note it as a known cost or give HandleKey a path that defers follow to the end of the :normal.

### The :p row gives its bang refusal as a bare E477
- Location: docs/compatibility.md:1
- Why: the :p row names its bang refusal as a bare E477 while its other errors and the :normal row give the full text.
- Fix: write E477: No ! allowed.

### The squash commits on main drop the pull request description (vim-folds-b retro 8)
- Location: `.claude/agents/merger.md`, `tools/gates.sh` (the `merge` group), `tools/open_pr.sh`
- Why: 5 of 5 squash commits #199 to #203 carry a 3-line body (one shortened Summary sentence, code spans stripped, the trailer) with 0 sections, against 7 of 7 from #192 to #198 at 31 to 36 lines and 4 sections; vim-folds-b's archived pr.md held 33 lines; the trailer, content, and docs gates all passed it, so the history on main loses every change's description, which CLAUDE.md makes the squash body.
- Fix: the merge passes the archived pr.md body, one blank line, and the trailer as the squash message, and a merge whose message differs is refused or reported as a gate FAIL; accepted by a tools-test case and the next 5 merged commits each holding the four sections.

### The merge phase's output tokens do not follow its fixed work (vim-folds-b retro 5, extends merge-output-cap)
- Location: `.claude/agents/merger.md`, `.claude/workflows/deliver-change.js` (merge phase)
- Why: vim-folds-b's first-pass green CI with 2 waits, no main move, and no refusal cost 98,694 output tokens over 10 calls (9,869 per call), 25.6 percent of the run's 385,471 output, after pipeline-diet (#202) capped the merger's calls but not its tokens; last-ten feature merges 4,992 to 60,874 (median about 13,500), backlog about 12,000; the same problem as pipeline-diet retro 7 (39,483 on 10 calls), queued as `merge-output-cap`.
- Fix: merge into `merge-output-cap`; accepted when, over the next 5 runs with a first-pass green CI and no main move, the merge phase stays within twice the twenty-row median of its output and under 10 percent of the run's output, the green line, squash check, and merged record unchanged.

### Scouting stays the costliest phase in tool calls (vim-folds-b retro 6)
- Location: `.claude/agents/scout.md`, `.claude/workflows/deliver-change.js` (scoutTargets)
- Why: 3 fresh packs at 37e72e3 took 44 of vim-folds-b's 139 calls (31.7 percent) and 62,465 output tokens (16.2 percent), the most scout calls in the last ten feature rows (11 to 40), while the packs held Designs 0, Rules 0, Bench 0 against Gaps 7 for 8 entry points and the contributor needed 34 implement calls.
- Fix: no empty pack section for a map area, fewer calls per pack; accepted when over the next 5 feature runs the scout phase stays under 20 percent of the run's tool calls with no rise in implement calls or quality first-pass failures (89/159 now).

### The code map gives the backlog lane's sprint share as 0 to 2
- Location: `docs/codebase-map.md:55`, `tools/docs_lint.sh:183`
- Why: the map's `tools/docs_lint.sh` entry says a `## Sprint` of 0 to 2 items in the backlog lane, while the lint checks `backlog:3` since the 3 + 3 sprint of sprint-17 (`docs/goals.md`), so an agent reading the map plans one backlog item too few.
- Fix: say 0 to 3 in the backlog lane in the map entry; accepted when the entry matches the lane shares `check_queue` reads.

### An undo ex command among the keys :normal feeds does not sync the undo first
- Location: carat/use_cases/ex/history_command_handler.rb:38
- Why: the review fix makes u, Ctrl-R, g-, and g+ under :normal close the open transaction before walking the tree (HistoryHandler), as Vim's u_undo syncs; ':normal x:undo<CR>' still finds the keys before it in the open transaction, so :undo, :redo, :earlier, and :later there say the history ends or walk past the edits, against Neovim.
- Fix: share the sync of HistoryHandler#call (close the open transaction when normal_depth is above 0, reopen it after the walk) with HistoryCommandHandler's :undo, :redo, :earlier, and :later variants, and test ':normal x:undo<CR>'.
