# Backlog: carat/use_cases/ex/normal_command_handler.rb

### :normal runs HandleKey's follow for every key it feeds
- Location: carat/use_cases/ex/normal_command_handler.rb:99
- Why: each key :normal feeds goes through HandleKey#call, whose follow runs the completion, float, palette, and plugin observers and ArrangeView per key, so :%normal on a large buffer pays them for every key of every line.
- Fix: note it as a known cost or give HandleKey a path that defers follow to the end of the :normal.
- Category: editor
- Added: 2026-11-18

### The :normal handler requires HandleKey, breaking the innermost-first require order
- Location: carat/use_cases/ex/normal_command_handler.rb:5 and carat.rb:240
- Why: an ex handler now requires ../handle_key, the outer key orchestrator, so carat.rb loads HandleKey and the dispatcher's graph through it ahead of their own lines (329 and 332), and the production require graph is no longer innermost first.
- Fix: list the :normal and :p requires in carat.rb after handle_key, or give the handler a narrow key-feeding collaborator.
- Also: carat.rb
- Category: editor
- Added: 2026-11-18

### Header comments run past the wrap width
- Location: carat/use_cases/ex/normal_command_handler.rb:17 and carat/domain/editor_state.rb:16
- Why: the header comment's second line in normal_command_handler.rb and the comment at editor_state.rb:16 run far past the wrap width of the comment around them, which makes them harder to read.
- Fix: rewrap both comments.
- Also: carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-18

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
- Also: carat/use_cases/ex/line_command_handler.rb, carat/use_cases/ex/print_command_handler.rb, docs/compatibility.md, carat/use_cases/search/global_command.rb, carat/use_cases/handle_key.rb, carat/use_cases/ex/join_command_handler.rb, carat/adapters/editor_assembly.rb, test/adapters_assembly.rb, carat/use_cases/actions/history_handler.rb, CLAUDE.md, docs/spinel-notes.md, carat/domain/global_args.rb, test/domain_global.rb, carat.rb, carat/use_cases/dispatcher.rb, carat/domain/editor_state.rb, docs/architecture.md, test/editor_line_commands.rb, carat/use_cases/ex/history_command_handler.rb
- Category: security
- Added: 2026-11-18

### :normal commits the first buffer with another buffer's cursor (sprint-17 review quality)

- Where: `carat/use_cases/ex/normal_command_handler.rb:71` at 522a0e1.
- Why it matters: when the fed keys switch buffers (Ctrl-^), the original buffer's transaction commits with the other buffer's cursor as its after-cursor, unlike `GlobalCommand#run`, so undo puts the cursor at a position from another file; and keys that switch then enter insert mode (`:normal bix`) leave that buffer's transaction open past the command (`:69`).
- Fix outline: commit with the position from before the loop when the buffer changed, and commit or close whatever transaction the keys left open, with rows for both. Queued in `normal-command-fixes`.
- Category: editor
- Added: 2026-11-18

### :normal leaves the caller's mode, depth, and command order wrong (vim-line-commands-c late findings)

- Where: `carat/use_cases/ex/normal_command_handler.rb:104` (the Esc loop), `:59` (normal_depth), `:51` (E471), `carat/use_cases/ex/history_command_handler.rb:43`, at 522a0e1.
- Why it matters: a plugin's `run_ex` of `:normal` from visual or insert mode ends the user's selection or insert session; a raise escaping the fed keys leaves normal_depth above 0, so every later key joins one transaction never closed; `:9normal` on 5 lines answers E16 where Neovim answers E471; `:undo x` (E474) under `:normal` still splits the undo state.
- Fix outline: end only what the keys left unfinished, reset the depth where the key loop recovers, check the argument before the range, sync only for a valid walk; rows for each. Queued in `normal-command-fixes`.
- Also: carat/use_cases/ex/history_command_handler.rb
- Category: editor
- Added: 2026-11-18

### The :normal E192 stop lives on the handler while its nesting lives in EditorState
- Location: carat/use_cases/ex/normal_command_handler.rb:39
- Why: the E192 stop is held as @stopping on the one handler instance while the nesting it pairs with is EditorState#normal_depth, so one nesting state lives in two homes and a behavior class gains mutable state.
- Fix: pin a normal_stopped bool member beside normal_depth in EditorState and read and clear it there.
- Category: editor
- Added: 2026-11-20
