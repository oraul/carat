# Backlog

Known items to fix in later changes. A finding that a change does not fix, because it is outside the change's scope or below the confidence the contributor agent acts on, is recorded here with where it is in the code, why it matters, and how to fix it, so that it is not lost and the next change can start from it. Each item is removed by the change that fixes it, through the OpenSpec loop like any other change.

## make types leaves build/carat.rbs that a later spin build warns about

- Where: the `types` target in the `Makefile` writes `build/carat.rbs` with `--emit-rbs`, inside the tree `spin` scans.
- Why it matters: `spinel_rbs_extract` reports a parse failure on the emitted file at every later `spin build`, `spin test`, and `make snapshots`, because of a doubled namespace separator in the class names it writes; the noise hides real warnings and the file has to be deleted by hand. Observed during the Struct change and again during the command grammar change.
- Fix outline: have the `types` target write the file outside the `spin` source tree, or delete it after printing.

## The file tree's cursor drifts when follow expands directories above it

- Where: `Carat::Plugins::Explorer::Plugin#follow` in `carat/plugins/explorer/plugin.rb`, and the plugin API, whose `move_cursor` request moves only the current window's cursor.
- Why it matters: while the tree is open but not current, opening a file in another directory expands that directory and inserts lines above the tree's cursor, which then sits on a different entry than before; Neovim's tree plugins move the tree's cursor to the followed file. `:ExplorerFind` and opening the tree put the cursor right, so only the unfocused case drifts.
- Fix outline: add a request that moves the cursor of a window by number (or of the plugin's scratch window by title) without focusing it, bump the API minor version, and have `follow` put the tree's cursor on the marked row after it refreshes.

## The plugin API cannot read or set the visual selection

- Where: `Carat::PluginApi::Host` and `BufferView` in `carat/plugin_api.rb`, and the requests in `carat/use_cases/plugins/buffer_requests.rb`; `docs/architecture.md` section 9.1 lists reading the selection and setting one among the requests a plugin can make.
- Why it matters: the visual modes keep each window's selection (its anchor, the cursor, and the kind from the mode, plus the last selection for `gv`), but a plugin cannot see it, so a plugin action bound in a visual map (a formatter, a comment toggle, a finder seeded with the selected text) has no way to know what was selected. The `visual-modes` change left the API at 1.1, because the plugin API was outside its scope.
- Fix outline: add the selection to `BufferView` (kind, anchor row and column, cursor row and column, `""` kind outside visual mode) and a `set_selection(kind, from_row, from_col, to_row, to_col)` request validated like `move_cursor`, bump the minor of `PluginApi::VERSION`, and document both in `docs/plugins.md`.

## Motions take the whole editor state and write the last find

- Where: `Carat::Domain::Motions` in `carat/domain/motions.rb`, which receives `EditorState` in every motion and assigns `state.last_find` from `for_command` (about line 177), and `TextObjects`, which receives the state too.
- Why it matters: a motion is meant to be a pure function of the text and the cursor (section 4 of `docs/architecture.md`), but with the whole state it can reach windows, registers, and modes, and the side effect on `last_find` makes it impossible to evaluate a motion speculatively, for a preview, a plugin, or a language service, without changing what `;` and `,` repeat.
- Fix outline: pass the buffer, the cursor, and the viewport (top row and height for `H`, `M`, `L`) as values, return the find to record alongside the `Motion`, and have `Move` and `Operate` store it in `last_find`.

## The ex grammar parses no ranges

- Where: `Carat::Domain::ExGrammar.parse` in `carat/domain/ex_grammar.rb` and `ExCommand` in `carat/domain/ex_command.rb`, which carry a name, a bang, and arguments only.
- Why it matters: section 4 of `docs/architecture.md` gives `ExCommand` a range (`.`, `$`, `%`, a number, a mark, a pattern, and arithmetic, joined by `,` or `;`); without it `:` in visual mode cannot offer `:'<,'>`, and `:10,20d`, `:%s`, and a bare line number are impossible.
- Fix outline: parse the address list in front of the name into a range value with both ends unresolved, resolve it against the buffer and the marks in `ExecuteEx`, and add the `'<` and `'>` marks with the change that brings marks.

## Sentence motions rescan the whole buffer on every use

- Where: `Carat::Domain::Motions.sentence_starts` in `carat/domain/motions.rb` (about line 499), called by `(` and `)` and by the `is` and `as` text objects in `carat/domain/text_objects.rb` (about line 171).
- Why it matters: every use builds the list of sentence starts for the whole buffer, so one `)` takes about 96 ms on 100,000 lines, and a count or a repeated key multiplies it.
- Fix outline: scan outward from the cursor, backward to the start of the current sentence and forward to the start of the next, stopping at a paragraph boundary, and reuse that walker for the text objects.

## Scrolling rewrites every row of the screen

- Where: `Carat::Adapters::FramePresenter` and `ScreenPresenter` in `carat/adapters/`, which draw a full frame and diff it cell by cell, so a one-line scroll changes every text row.
- Why it matters: `j` at the bottom of the window writes about 13 KB per key on a 200-column terminal, where a terminal scroll region would move the rows with a few bytes; on a slow connection that is the visible cost of scrolling.
- Fix outline: belongs to the `render-core` change of the core-quality queue: detect a vertical shift of the window's rows between frames and emit a scroll region with the new rows only.

## The test doubles are compiled into the production binary

- Where: `carat.rb` requires `carat/doubles/*` (the fake terminal, the manual clock, the memory files, the fixed config, and the editor harness), and `bin/carat.rb` requires `carat.rb`.
- Why it matters: the shipped binary carries test code it never runs, which costs size and compile time and lets production code reach a double by mistake without a compile error.
- Fix outline: belongs to the `state-and-ports` change of the core-quality queue, which follows `dependency-injection`: move the doubles out of the library require graph into a file only `test/*.rb` and benchmarks require, and keep `bin/carat.rb` on the drivers.

## Line edits on very large buffers move the rest of the line array

- Where: `Carat::Domain::LineSplice` in `carat/domain/line_splice.rb` and the `lines` array of `Buffer` in `carat/domain/buffer.rb`; a line inserted or deleted goes through Spinel's `insert` or `delete_at`, C loops that move every element after the row.
- Why it matters: at row 50,000 of 100,000 that move is about 400 KB, about 7 us in a tight loop and more when the cache is cold after a frame render, so `ddP` takes 33 to 36 us per key on 100,000 lines (against a 30 us target) and about 150 to 190 us on 1,000,000 lines, of which the per-key baseline is about 17 us.
- Fix outline: keep the lines in a gap buffer (a gap at the last edited row, so repeated edits nearby move nothing) or in chunks of a few thousand lines (an edit moves one chunk), behind the same primitives and `line(row)`, with `lines` materialized only for the few callers that need the whole array; to be considered with or after `render-core`, which also removes the per-key rendering cost.
