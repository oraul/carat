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

### :undo, :redo, :earlier, :later inside :normal do not sync the open transaction
- Location: carat/use_cases/ex/history_command_handler.rb:38 (quality review at 759c2e2, raised as blocking; left unfixed because the user limited the final round to the :g trailing-blank tests, the compatibility row, and the pull request text)
- Why: HistoryHandler commits the transaction :normal holds open before an undo walk and reopens it afterwards, but HistoryCommandHandler does not, so ':normal x:undo<CR>' on a buffer with no earlier history answers 'Already at oldest change' and keeps the x (undo_path is computed before begin_history commits it), and with history every key after it becomes its own undo state because no transaction is reopened.
- Fix: do the close-and-reopen once in WalkHistory (keyed on normal_depth > 0 and an open transaction), which every walk goes through, drop the copy in HistoryHandler, and add table rows for ':normal x:undo<CR>' and ':normal x:undo<CR>xu'.

### GlobalArgs.parse keeps a blank-only check no caller can reach
- Location: carat/domain/global_args.rb:33
- Why: the only caller passes ExCommand#literal, which already has its leading blanks removed, so a blank-only text never arrives and text.strip.empty? acts as text.empty?; the comment states a rule that no test covers. Left in place because removing it would change what a direct call of GlobalArgs.parse with " " returns.
- Fix: keep text.empty? and drop the blank-only clause from the comment, or add a test/domain_global.rb row for a blank-only text.

### The :normal handler requires HandleKey, breaking the innermost-first require order
- Location: carat/use_cases/ex/normal_command_handler.rb:5 and carat.rb:240
- Why: an ex handler now requires ../handle_key, the outer key orchestrator, so carat.rb loads HandleKey and the dispatcher's graph through it ahead of their own lines (329 and 332), and the production require graph is no longer innermost first.
- Fix: list the :normal and :p requires in carat.rb after handle_key, or give the handler a narrow key-feeding collaborator.

### place_cursor's clamp now depends on the mode, without a test
- Location: carat/use_cases/ex/line_command_handler.rb:496
- Why: place_cursor now clamps through EditorState#max_col, which lets the column sit past the end in insert and visual modes, where the old code always clamped as normal mode does (a line command a plugin runs outside normal mode); no test covers the mode dependence.
- Fix: keep the normal-mode clamp (length - 1), or state the mode dependence and test it.

### Header comments run past the wrap width
- Location: carat/use_cases/ex/normal_command_handler.rb:17 and carat/domain/editor_state.rb:16
- Why: the header comment's second line in normal_command_handler.rb and the comment at editor_state.rb:16 run far past the wrap width of the comment around them, which makes them harder to read.
- Fix: rewrap both comments.

## Findings of vim-line-commands-c after its package step

- quality advisory carat/use_cases/ex/normal_command_handler.rb:24 MAX_DEPTH 100 exceeds Spinel's 64 exception frames when the recursion goes through a plugin action, each level holding a Guarded rescue, so SystemStackError may come before E192; fix: lower the limit below the frame budget or test the plugin path
- quality advisory carat/use_cases/ex/normal_command_handler.rb:104 the Esc loop runs until the mode is normal whatever mode :normal started in, so a plugin's run_ex of :normal from visual or insert mode ends the user's selection or insert session (LeaveInsert then skips its commit); fix: end only what the keys left unfinished, comparing with the mode at entry
- quality advisory carat/use_cases/ex/line_command_handler.rb:57 place_cursor now clamps by the mode (EditorState#max_col), so :m, :co, :j, : , : and :p run from insert or visual mode (plugin run_ex) leave the cursor at the line length where the old code put it on the last character, untested; fix: keep the normal-mode clamp or add a test of the intended column
- quality advisory carat/use_cases/ex/print_command_handler.rb:34 E749 is given for a buffer of one empty line, where Neovim gives it only for a truly empty buffer and prints a file holding one empty line; fix: list it under Differences from Neovim in docs/compatibility.md
- quality advisory carat/use_cases/search/global_command.rb:174 the :p lines are joined by rebuilding the whole message and a new Outcome per matched line, quadratic on large globals; fix: append to one mutable string and build Outcome.from_print once at the end
- quality advisory carat/use_cases/handle_key.rb:149 each key :normal feeds runs arrange_view, follow, and plugins.observe, O(keys x lines) on ':%normal' or ':g/x/normal'; fix: skip follow while normal_depth 0 and run it once after the handler
- quality advisory carat/use_cases/ex/join_command_handler.rb:18 stray double comma ('what ExRange gives,, a bad count'), and the LineCommandHandler class comment still lists only :d, :m, :co, :t, :j, : , : as its subclasses; fix: drop the comma and add :normal and :p
- quality advisory carat/adapters/editor_assembly.rb:191 the rewrapped comment reads awkwardly ('after HandleKey, which :normal receives, the core ex commands before the'); fix: reflow the sentence
- quality advisory carat/use_cases/ex/normal_command_handler.rb:35 NormalCommandHandler keeps HandleKey in a public reader but test/adapters_assembly.rb gains no check that it holds the one instance; fix: add the holder check there or drop the reader
- quality advisory carat/use_cases/actions/history_handler.rb:44 the undo sync under :normal lives in HistoryHandler, so :undo, :redo, :earlier, :later (HistoryCommandHandler) need a second copy (already recorded in docs/findings); fix: do the close-and-reopen once in WalkHistory (start/finish, keyed on normal_depth), which every walk goes through, and drop it from HistoryHandler
- quality advisory carat/use_cases/ex/normal_command_handler.rb:12 the edited header comment line runs past the file's wrap width; fix: rewrap the paragraph
- quality advisory carat/use_cases/search/global_command.rb:174 each :p in a global copies every earlier printed line into a new string, quadratic in the lines printed; fix: append to one mutable string and build Outcome.from_print once after the loop
- quality advisory carat/use_cases/ex/line_command_handler.rb:455 place_cursor now clamps through EditorState#max_col, which allows the column past the end in insert and visual modes where the old code always clamped as in normal mode (a line command a plugin runs outside normal mode); fix: keep the normal-mode clamp or state the mode dependence in the comment
- quality advisory carat/use_cases/ex/join_command_handler.rb:18 typo: 'what ExRange gives,, a bad count'; fix: drop the extra comma
- quality advisory carat/adapters/editor_assembly.rb:191 the wiring comment's edit leaves a ragged wrap with stacked clauses ('afterwards, after HandleKey, which :normal receives, the core ex commands before the'); fix: rewrap and say HandleKey is built before the ex handlers because :normal receives it
- quality advisory carat/use_cases/ex/normal_command_handler.rb:12 the header comment's second line runs past the file's wrap width; fix: rewrap the paragraph
- quality advisory carat/use_cases/ex/normal_command_handler.rb:33 the new handle_key reader is checked nowhere: test/adapters_assembly.rb does not assert the :normal handler holds the one HandleKey (CLAUDE.md, keyword constructors: readers let the assembly test check every holder); fix: add that assertion or drop the reader
- quality advisory carat/use_cases/ex/normal_command_handler.rb:59 normal_depth is raised and lowered without ensure (Spinel frames), so a raise escaping the fed keys leaves it above 0 and every later key joins one open transaction that LeaveInsert never closes; fix: reset normal_depth to 0 where the key loop recovers from a raise, or record the limit in docs/spinel-notes.md
- quality advisory carat/use_cases/ex/normal_command_handler.rb:99 each fed key runs HandleKey#follow (completion, floats, palette, plugin observers, ArrangeView), so :%normal on a large buffer pays them per key per line; fix: note the cost or defer follow to the end of the :normal
- quality advisory docs/compatibility.md:325 the :p row gives its bang refusal as a bare E477 while its other errors give the full text; fix: write E477: No allowed
- quality advisory carat/domain/global_args.rb:33 dead branch: the only caller of GlobalArgs.parse passes ExCommand#literal, already lstripped, so a blank-only text never arrives and text.strip.empty? equals text.empty?, and the new comment states a rule no test covers; fix: keep text.empty? and drop the blank-only clause from the comment, or add a test/domain_global.rb row for a blank-only text
- security Low (6) carat/use_cases/ex/normal_command_handler.rb:62 A hostile project .caratrc remap can make :normal nest over ranges and hang the editor: for example keymap.normal j :%normal Space j CR runs each line's j again at the next depth. That is about line_count to the power MAX_DEPTH (100) key runs, because HandleKey now saves and restores the remap count for each nested call, the bang sti
- quality advisory carat/use_cases/ex/normal_command_handler.rb:5 layer order: an ex handler now requires ../handle_key, the outer key orchestrator, so carat.rb (line 240) loads HandleKey and the dispatcher's graph through it ahead of their own lines 329 and 332 and the require graph is no longer innermost first; fix: list the :normal and :p requires in carat.rb after handle_key, or give the handler
- quality advisory carat/use_cases/ex/line_command_handler.rb:496 behavior change without its test: place_cursor now clamps through EditorState#max_col, which allows the column past the end in insert and visual modes, where the old code always clamped as in normal mode; fix: keep the normal-mode clamp (length - 1) or state and test the mode dependence
- quality advisory carat/use_cases/ex/join_command_handler.rb:18 typo: the header comment reads 'what ExRange gives,, a bad count'; fix: drop the extra comma
- quality advisory carat/adapters/editor_assembly.rb:191 docs: the wiring comment reads 'registered afterwards, after HandleKey, which :normal receives, the core ex commands before the' with a ragged short line; fix: rewrap and say HandleKey is built before the ex handlers because :normal receives it
- quality advisory carat/use_cases/ex/normal_command_handler.rb:17 style: the header comment's second line and editor_state.rb:16 run far past the wrap width of the surrounding comment; fix: rewrap both comments
- quality advisory carat/use_cases/search/global_command.rb:174 efficiency: each :p in a global copies every earlier printed line into a new string, quadratic in lines printed (:g/./p on a large file); fix: collect the printed lines in one mutable string and build Outcome.from_print once after the loop
- quality advisory carat/use_cases/ex/normal_command_handler.rb:99 efficiency: every key :normal feeds goes through HandleKey#call, whose follow runs the observers and ArrangeView per key, so :%normal on a large buffer pays them per key per line; fix: note it as a known cost or defer follow to the end of the :normal
- quality advisory docs/compatibility.md:1 docs: the :p row gives its bang refusal as a bare E477 while its other errors and the :normal row give full text; fix: write E477: No allowed
- quality advisory docs/findings/vim-line-commands-c.md:56 duplication: the fix round appends entries that repeat earlier ones in the same file (':undo, :redo, :earlier, :later inside :normal' repeats line 51, 'place_cursor's clamp now depends on the mode' repeats line 6), so groom folds the same finding twice; fix: merge each pair into one entry
- quality advisory carat/use_cases/ex/normal_command_handler.rb:69 keys that switch to another buffer and then enter insert mode (:normal bix) leave that buffer transaction open after :normal ends, since LeaveInsert skips its commit under normal_depth and the handler commits only the buffer it opened on, so the undo state closes late with the next key cursor; fix: after the loop, commit the open tra
- quality advisory test/adapters_assembly.rb:126 the one-instance check of the key handler names only the controller, not NormalCommandHandler, which now holds HandleKey in a reader (CLAUDE.md: every holder checked to get the one instance); fix: add the handle_key of the :normal handler (commands.find( normal )) to that strangers list
- quality advisory carat/use_cases/ex/normal_command_handler.rb:51 E471 is checked after the range, so :9normal on a 5-line buffer answers E16 where Neovim (EX_NEEDARG) answers E471 first; fix: check command.args.empty? before lines_of, or name the order in docs/compatibility.md
- quality advisory carat/use_cases/dispatcher.rb:75 transaction_edits is read for every dispatched key though only record uses it, on the hot path; fix: read it inside the if change branch and pass 0 otherwise
- quality advisory carat/use_cases/ex/normal_command_handler.rb:11 the header comment has one line wrapped far past the file width (read literally with its trailing blanks (ExCommand#literal), as keys typed ...), as does carat/domain/editor_state.rb:16; fix: rewrap both paragraphs to the file width
- quality advisory docs/architecture.md:200 docs currency: section 6 still names the Outcome output port as (ok and message), while Outcome now also carries printed, which GlobalCommand#visit reads; fix: name printed and Outcome.from_print in that sentence
- quality advisory docs/findings/vim-line-commands-c.md:51 docs currency: the entries 'An undo ex command among the keys :normal feeds does not sync the undo first' (line 51) and ':undo, :redo, :earlier, :later inside :normal do not sync the open transaction' (line 56) describe what 3ad68de now fixes through UndoSyncing, so the findings file hands the backlog fixed items; fix: drop both entries
- quality advisory test/editor_line_commands.rb:171 the two new undo-command rows sit between the comment naming the scenario A remap per line of a long range and its row, detaching that comment from the row it labels; fix: move the two rows and their comment above the remap comment at line 171
- quality advisory test/editor_line_commands.rb:176 tests beside behavior: only :undo is tested among the undo ex commands that now sync under :normal, while docs/compatibility.md promises it for :redo, :earlier, and :later too; fix: add a row for :redo (or :earlier) among the keys :normal feeds
- quality advisory carat/use_cases/ex/history_command_handler.rb:43 an :undo with a bad argument (E474) under :normal still closes and reopens the open transaction, splitting the keys into two undo states though nothing was undone, unlike Vim, which refuses before syncing; fix: check digits? before synced_walk, or sync only for a valid walk
