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

- Where: the find motions `f`, `F`, `t`, and `T` and the sentence scan in `carat/domain/motions.rb` (`line[col, 1]`), `Block#span` in `carat/domain/block.rb`, `Selection.cells` in `carat/domain/selection.rb`, the quote objects and the trailing blanks of `as` in `carat/domain/text_objects.rb`, the join and the indent helpers in `carat/domain/operators.rb`, the indent loops of `carat/use_cases/actions/insert_mode_handler.rb` and `carat/use_cases/move.rb`, the blank test in `carat/use_cases/operate.rb`, and the name scan of `carat/domain/ex_grammar.rb`.
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

## :earlier and :later take no time or write count

- Where: `Carat::UseCases::HistoryCommandHandler#travel` in `carat/use_cases/ex/history_command_handler.rb`, which answers `Not implemented: :earlier 10s` for an argument ending in `s`, `m`, `h`, `d`, or `f`, and `Carat::Domain::UndoTree` in `carat/domain/undo_tree.rb`, which keeps each state's time and write number but no search over them.
- Why it matters: Neovim's `:earlier 10m` and `:later 1f` move through the undo tree by time and by file writes, the quickest way back to the text of an earlier session of work; the `undo-and-registers` change implemented counts of changes only.
- Fix outline: give `UndoTree` a `seq_at_time(time, older)` that returns the last state made at or before (or the first after) a time, and a `seq_at_save(n, older)` over the write numbers, both over the flat arrays the tree already keeps; have the handler convert `Ns`, `Nm`, `Nh`, and `Nd` to seconds from the clock port and call `Undo#to` with the state found, and `Nf` count writes as Neovim does (`:earlier 1f` goes to the last write, or before the first change when there is none); move the tests in `test/editor_undo.rb` from the "Not implemented" message to the states reached.

## The search register holds nothing

- Where: `Carat::Domain::Registers#read` in `carat/domain/registers.rb`, which answers nil for `/`.
- Why it matters: `"/p` and `:registers` should show the last search pattern; search arrives with `search-and-substitute`, roadmap item 6.
- Fix outline: when the search use cases land, store the last pattern in `Registers` (a `search` member like `command_line`), read it for `/`, and add `/` to the order of `RegisterCommandHandler::ORDER`.

## Plugins cannot highlight ranges or add virtual text

- Where: the plugin API in `carat/plugin_api.rb` and the frame presenter in `carat/adapters/frame_presenter.rb`; `syntax-highlighting` gave plugins tokenizers for whole filetypes and `Host#syntax_group`, but no request to color an arbitrary range of a buffer or to show text that is not in it.
- Why it matters: the explorer's marked line, search matches from a finder, diagnostics underlines, and git blame all need a range highlight or virtual text that is not part of the language's tokens; section 9.1 of `docs/architecture.md` lists them.
- Fix outline: add `add_highlight(buffer, row, from_col, to_col, group)` and `clear_highlights(buffer)` per plugin, kept in a per-buffer layer moved by the splice like the sign layers, and painted by the frame presenter after the tokens; a virtual text layer of the same shape after it; bump the API minor.

## Only Ruby has a tokenizer

- Where: `config/plugins.caratrc` lists one tokenizer plugin, `carat/plugins/ruby/`, and `Carat::Domain::Filetype` in `carat/domain/filetype.rb` detects only `ruby`.
- Why it matters: section 8.2 of `docs/architecture.md` names Markdown, JSON, and YAML too; every other file is drawn plain.
- Fix outline: one compiled plugin per language under `carat/plugins/<language>/` with its own tokenizer and state encoding, its extensions added to the `Filetype` tables, listed in `config/plugins.caratrc` and `config/default.caratrc`; the tokenizer test table of `test/plugins_ruby.rb` is the model.

## :set handles only filetype and syntax

- Where: `Carat::UseCases::SetCommandHandler` in `carat/use_cases/ex/set_command_handler.rb`, which answers `Not implemented: :set name` for the options the editor already has and `E518` for the rest; no `:setlocal`, no `:filetype`.
- Why it matters: `:set number`, `:set ts=4`, `:set nowrap`, and the rest of Neovim's option commands are roadmap item 9, `options-and-config`.
- Fix outline: grow the handler into the option table that item brings (names, abbreviations, types, global or local), keeping the `filetype` and `syntax` answers; add `:setlocal` and the `no`, `inv`, `!`, `&`, `+=`, `-=` forms there.

## Themes are fixed in the binary

- Where: `Carat::Domain::Themes` in `carat/domain/themes.rb` holds `carat-dark` and `carat-light`, chosen once at startup by the `option.theme` line; there is no `:colorscheme`, no `:highlight`, and no theme file.
- Why it matters: users expect to pick or tune a color scheme without rebuilding; the user and project configuration files are in place since `caratrc-config`, but they can only name a shipped theme.
- Fix outline: read `theme.<name>.<group>` lines from the configuration files (foreground, background, 16-color values, and attributes as words, applied over a shipped theme), add `:colorscheme name` that rebuilds the screen presenter's SGR table and redraws, and `:highlight Group guifg=... ctermfg=...` for single groups.

## No semantic highlighting from the language server

- Where: the syntax cache in `carat/domain/syntax_cache.rb` holds only a tokenizer's tokens; roadmap item 10, `language-services`, brings `ruby-lsp`.
- Why it matters: a language server knows which names are locals, parameters, methods, and constants, which a line tokenizer can only guess (vim-ruby's heuristics for `/`, `%`, `?`, and `<<` misjudge unusual code).
- Fix outline: once the language gateway exists, request `textDocument/semanticTokens/range` for the visible rows and paint them as a layer over the tokenizer's, invalidated by the same change records.

## Ruby constructs nested deeper than the state encodes

- Where: `Carat::Plugins::Ruby::LineState` in `carat/plugins/ruby/line_state.rb` keeps two string frames, two pending heredocs, a nesting depth of 7, and a brace depth of 3 at the end of a line; `Tokenizer#heredoc_line` ends an interpolation left open in a heredoc body line at the end of that line.
- Why it matters: a third string opened through interpolation and left open across lines, a third heredoc on one line, or a 256th distinct heredoc terminator is highlighted less precisely on the following lines (never wrongly enough to raise).
- Fix outline: when it matters, give the tokenizer a side table of states (an integer per distinct deep stack, interned like the terminators) and keep the integer as an index into it, so any depth fits in the same integer.

## G on a large file tokenizes every row above the end once

- Where: `Carat::UseCases::HighlightView#advance` in `carat/use_cases/syntax/highlight_view.rb`.
- Why it matters: the state of the last row depends on every row above it, so the first `G` on 100,000 lines of Ruby tokenizes all of them, about 68 ms in the benchmark (`make bench` scenario `G-ruby`); later jumps reuse the end states.
- Fix outline: if it matters on larger files, start from a sync point as Vim's `syntax sync minlines` does (tokenize a few hundred rows above the window from state 0 and accept a wrong state in rare cases), or tokenize the rest of the file in the background between keys once the main loop has an idle tick.

## Opening 100,000 plain lines is slower than opening them highlighted

- Where: the `open-plain` and `open-ruby` scenarios of `bench/keys.rb`, which open the same generated 100,000-line Ruby source without and with the ruby plugin.
- Why it matters: in the `syntax-highlighting` measurements the plain open took a median of about 119 ms over eight runs and the highlighted one about 19 ms, while 10,000 lines open in about 2.5 ms either way; the plain time grows faster than the line count, which points at a collection or a growth step during the open that the plugin's startup allocations happen to move out of it, so the open time of large files depends on where the collector runs.
- Fix outline: report the collections and their time during the open in the benchmark (`GC.stat("cycle")` and `GC.total_time` around `assembly.open`), find the allocation that triggers them while splitting the file into lines, and size or reuse that storage so the open stays linear.

## Spinel loses the types of an array destructured inside a method

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); seen in the test helpers `setup` of `test/use_cases_plugins.rb`, `editor` of `test/use_cases_plugin_files.rb`, and `run` of `test/domain_grammar.rb`, which returned `[a, b, ...]` for the caller to destructure (`state, host, keymap, files, ex = setup(...)`).
- Why it matters: at the top level of a program those locals kept their types, but once the `test-build` change moved each test's statements into a method, they became poly: in `test/use_cases_plugins.rb` the generated C did not compile (`expected statement before ')'` at each `state.cursor.row = 1`), and in the other two spinel-doctor reported unresolved calls on poly receivers. A minimal program with three values of three classes kept its types, so the trigger is not yet isolated. The helpers now return an object with typed readers, which is the convention in `CLAUDE.md`; production code has no such destructuring.
- Fix outline: restore the array return of `setup` in `test/use_cases_plugins.rb` and reduce it to a minimal reproduction (five values from a helper, destructured twenty times inside one method, one of them an attribute chain assigned through), report it upstream to Spinel, and drop the convention once a `SPINEL_REF` bump compiles it typed.

## Spinel answers a method's argument for some string returns

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); seen in `carat/domain/rc_value.rb` and `carat/domain/config.rb` during the `caratrc-config` change. `RcValue.expectation(kind)`, written as a `case` whose branches were string literals, answered the kind itself when called with a literal; `RcValue.text(words, kind)`, written as `words.empty? ? "" : words[0].to_s`, answered the kind; and `SCOPES.include?(line.scope)` answered false for a scope the array holds, while the same call through a local answered true.
- Why it matters: each is silent wrong code, not a compile error; only the table tests caught them. The three places are rewritten (guard returns, a local for the first word, a local for the scope), but the same shapes elsewhere could be affected.
- Fix outline: reduce each to a minimal program (a module function with a literal-branch `case` called with a literal; a ternary of `""` and an indexed `to_s` in a two-parameter method; a constant array's `include?` of a reader called on a `Data` value), report them upstream, and recheck them when `SPINEL_REF` is bumped.

## The plugin host keeps many-method classes in use_cases

- Where: `carat/use_cases/plugins/`: `PluginHost` (18 public methods besides `call`), `PluginRegistry` (24), `PluginEntries` (5), `PluginEntry` (5), `PluginEvents` (4), `PluginRouter` (4), `PluginSyntax` (3), and `PendingEvent` (1), which the one-call rule of `test/lint.rb` skips by directory since the `use-case-boundaries` change; the request families (`BufferRequests`, `WindowRequests`, `FileRequests`, `UiRequests`) and `PluginLink` keep their request methods by design, as the adapter of `PluginApi::Host`.
- Why it matters: the rule that a use case exposes only `call` holds for the core, but the host's parts are not use cases at all: they are the infrastructure between compiled plugins and the core, and while they sit in `use_cases` the layer reads as if a use case could have two dozen entry points. The `use-case-boundaries` change decided they move out with the whole host and left the move to this plugin-side part, because it reworks the host's construction, the assembly, and five test programs.
- Fix outline: move `carat/use_cases/plugins/` with `concerns/guarded.rb` and `plugins/boundary.rb` to carat/adapters/plugins/ as `Carat::Adapters`, give the core a port in `carat/ports/` for the calls the use cases make into the host (`observe`, `saved`, `resized`, `answer`, `action`, `command?`, `command`, and the tokenizer calls of `HighlightView`), implemented by the host and handed to `SaveFile`, `HandleKey`, `CancelCommandLine`, `ExecuteCommandLine`, `PluginActionHandler`, `PluginCommandHandler`, and `HighlightView` by the assembly, keep the request families' request methods, update the layer ranks and `docs/architecture.md` sections 3, 5, and 9, and drop the `use_cases/plugins/` exemption from the one-call rule.

## Spinel compiles private_constant without enforcing it

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); every `private_constant` line under `carat/use_cases/` since the `use-case-boundaries` change.
- Why it matters: a probe on the pinned compiler compiled `private_constant :NAME` and still let another class read `Owner::NAME`, which CRuby refuses with `NameError`, so the declaration documents the intent but stops nothing. `private` on methods is enforced (a call raises `NoMethodError`). `test/lint.rb` carries the rule instead: every constant of a use case file is listed in a `private_constant`, and no file names `Owner::NAME` of a use case outside its own file.
- Fix outline: reduce it to a minimal program (a class with a private constant read from another class), report it upstream, and when a `SPINEL_REF` bump enforces it, keep the lint rule only as a check that the list is complete.

## Nothing compiles the generators' output on every check

- Where: `tools/new.sh` and its tests in `tools/tools_test.sh`, which check the files each generator writes and the lines it inserts, not that they compile.
- Why it matters: a convention that changes (a base class's constructor, an anchor's neighbor, a lint rule) could leave a generator writing code that no longer compiles or lints, and nothing would say so until an author ran it. The `authoring-kit` change compiled, linted, and tested the output of all five generators by hand in a scratch worktree (59 tests, `spinel-doctor` clean).
- Fix outline: a `make generators-check` target that runs every generator in a temporary worktree, then `make gen-config`, `make lint`, `make test-build`, and `make test-run` there, run by the checker when `tools/new.sh`, `carat.rb`, `EditorAssembly`, the handler bases, or `test/lint.rb` change rather than on every check, since it costs a full analysis of the library.

## The ci-watcher and the merger read the same pull request state twice

- Where: the CI and merge phases of `.claude/workflows/deliver-change.js`, which start the `ci-watcher` agent and then the `merger` agent, the second rereading the pull request head and the CI state the first just wrote.
- Why it matters: in `authoring-kit` the two took 17 and 11 tool calls, 28 of 272 (10.3%), and 6,305 output tokens for a CI that passed first time in 3.0 minutes with 0 CI fixes. Proposed by that run's retrospective (note 3) and left out of the queue because one green run is the only evidence and the watcher drives the CI-fix rounds, which no run has measured yet.
- Fix outline: once `docs/metrics.tsv` holds several runs with their `ci` and `merge` phase counts, including one with a CI fix, have the merger watch CI itself when the run has no CI fix to make, keeping the watcher only for the fix loop, and compare the two phases' tool calls before and after.
