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

- Where: `Carat::Domain::Motions` in `carat/domain/motions.rb`, which receives `EditorState` in every motion and records f, F, t, and T in the `LastFind` record `for_command` receives (since `state-and-ports`), and `TextObjects`, which receives the state too.
- Why it matters: a motion is meant to be a pure function of the text and the cursor (section 4 of `docs/architecture.md`), but with the whole state it can reach windows, registers, and modes, and the side effect on `last_find` makes it impossible to evaluate a motion speculatively, for a preview, a plugin, or a language service, without changing what `;` and `,` repeat.
- Fix outline: pass the buffer, the cursor, and the viewport (top row and height for `H`, `M`, `L`) as values, return the find to record alongside the `Motion`, and have `Move` and `Operate` store it in the `LastFind` record they already receive.

## The ex grammar parses no ranges

- Where: `Carat::Domain::ExGrammar.parse` in `carat/domain/ex_grammar.rb` and `ExCommand` in `carat/domain/ex_command.rb`, which carry a name, a bang, and arguments only.
- Why it matters: section 4 of `docs/architecture.md` gives `ExCommand` a range (`.`, `$`, `%`, a number, a mark, a pattern, and arithmetic, joined by `,` or `;`); without it `:` in visual mode cannot offer `:'<,'>`, and `:10,20d`, `:%s`, and a bare line number are impossible.
- Fix outline: parse the address list in front of the name into a range value with both ends unresolved, resolve it against the buffer and the marks in `ExecuteEx`, and add the `'<` and `'>` marks with the change that brings marks.

## Sentence motions rescan the whole buffer on every use

- Where: `Carat::Domain::Motions.sentence_starts` in `carat/domain/motions.rb` (about line 499), called by `(` and `)` and by the `is` and `as` text objects in `carat/domain/text_objects.rb` (about line 171).
- Why it matters: every use builds the list of sentence starts for the whole buffer, so one `)` takes about 96 ms on 100,000 lines, and a count or a repeated key multiplies it.
- Fix outline: scan outward from the cursor, backward to the start of the current sentence and forward to the start of the next, stopping at a paragraph boundary, and reuse that walker for the text objects.

## Line edits on very large buffers move the rest of the line array

- Where: `Carat::Domain::LineSplice` in `carat/domain/line_splice.rb` and the `lines` array of `Buffer` in `carat/domain/buffer.rb`; a line inserted or deleted goes through Spinel's `insert` or `delete_at`, C loops that move every element after the row.
- Why it matters: at row 50,000 of 100,000 that move is about 400 KB, about 7 us in a tight loop and more when the cache is cold after a frame render, so `ddP` takes 33 to 36 us per key on 100,000 lines (against a 30 us target) and about 150 to 190 us on 1,000,000 lines, of which the per-key baseline is about 17 us.
- Fix outline: keep the lines in a gap buffer (a gap at the last edited row, so repeated edits nearby move nothing) or in chunks of a few thousand lines (an edit moves one chunk), behind the same primitives and `line(row)`, with `lines` materialized only for the few callers that need the whole array; to be considered now that `render-core` removed the per-key rendering cost.

## Some per-command character loops still slice one-character strings

- Where: the find motions `f`, `F`, `t`, and `T` and the sentence scan in `carat/domain/motions.rb` (`line[col, 1]`), `Block#span` in `carat/domain/block.rb`, `Selection.cells` in `carat/domain/selection.rb`, the quote objects and the trailing blanks of `as` in `carat/domain/text_objects.rb`, the join and the indent helpers in `carat/domain/operators.rb`, the indent loops of `carat/use_cases/enter_insert.rb` and `carat/use_cases/move.rb`, the blank test in `carat/use_cases/operate.rb`, and the name scan of `carat/domain/ex_grammar.rb`.
- Why it matters: Spinel resolves `line[i, 1]` on a line that is not ASCII from the start of the line, so these loops are quadratic on a long UTF-8 line; `render-core` moved the paint path, `DisplayWidth.column` and `col_at`, the word motions' `Walker`, the word runs of the text objects, `first_nonblank`, and `indent_of` to code points or bytes, but these run once per command, not per frame, and were left as they were.
- Fix outline: walk them with `Utf8.size_at` and `code_at`, or decode the line once with `Utf8.codes`, and compare code points instead of one-character strings; blanks and ASCII punctuation can compare bytes directly, as `Buffer#blanks` does.

## Key handling allocates two dozen objects per key

- Where: the key path outside rendering: the byte slices of `Carat::Adapters::KeyDecoder` in `carat/adapters/key_decoder.rb`, the `Command` the grammar builds, the `Motion` and `Position` values of `carat/domain/motions.rb`, the `Transaction` and `ChangeRecord` the dispatcher and the buffer open for every command in `carat/use_cases/dispatcher.rb` and `carat/domain/buffer.rb`, and the `KeymapMatch` of `Keymap#lookup` in `carat/domain/keymap.rb`.
- Why it matters: after `render-core` a key takes about 14 us and rendering allocates about nine objects, so these allocations set how often Spinel collects; typing spends 3.43 percent of its time in the collector (about six collections per 10,000 typed keys, each marking a live set of 10 to 16 MB) against the 3 percent target.
- Fix outline: decode from an offset into the pending bytes instead of slicing them, reuse one `KeymapMatch` and one `Command` per `HandleKey` (they are read before the next key), return motion targets as two integers instead of a `Position`, and open a transaction only when the command edits, creating it on the first change record; measure with `make bench` and lower the budget of `make bench-budget` to what the cursor and typing scenarios reach.

## Spinel's slab release stalls keys on transparent huge pages

- Where: Spinel's runtime, `lib/sp_slab.c` at the pinned `SPINEL_REF`: at the end of a full collection every entirely free slab chunk beyond a small reserve is handed back with `madvise(MADV_DONTNEED)`, and arenas are marked `MADV_HUGEPAGE`, so the next allocation that needs a chunk faults in a fresh huge page.
- Why it matters: on a host whose huge page defragmentation is `madvise` that fault stalls for compaction, and single keys take 8 to 12 ms although the collection itself is under 2 ms; with `SPINEL_SLAB_HUGE=0` the slowest keys of the `make bench` scenarios drop to 1.2 to 2.0 ms (medians of the slowest key are 0.68, 1.67, and 1.46 ms for `l h`, `j`, and typing, against maxima of 2.29, 2.35, and 11.97 ms with huge pages on). The `render-core` target of no key over 2 ms is missed because of it.
- Fix outline: report it upstream to Spinel with the benchmark and the `SPINEL_SLAB_HUGE=0` measurement, asking for released chunks to be kept for a while or for huge pages to be skipped for small heaps; until then, a workaround is to keep released chunks resident (a larger per-worker reserve) if Spinel exposes it, or to document `SPINEL_SLAB_HUGE=0` for interactive use, and bump `SPINEL_REF` in its own change once the runtime changes.
