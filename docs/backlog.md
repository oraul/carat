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

## Ex ranges resolve no arithmetic, pattern, or other mark

- Where: `Carat::Domain::ExRange.resolve` in `carat/domain/ex_range.rb`, which reads `%`, `.`, `$`, a number, `'<`, and `'>`; `ExGrammar.range_end` already keeps `+`, `-`, `;`, and any `'x` in the range.
- Why it matters: `:.,+3s`, `:/foo/s`, `:'a,'bs`, and a count before `:` (Vim's `.,.+N-1`) answer `Not implemented: range x`, and the visual marks are not moved by later edits, as Vim's marks are.
- Fix outline: resolve `+N` and `-N` after an address or alone, `;` by moving the cursor line to the first address before the second, and `/pat/` and `?pat?` through `Search.find` under a budget; read `'a` to `'z` from the marks change, which also moves the visual marks with the splice.

## ~ in a search pattern ignores the last substitute

- Where: `VimPattern#tilde` in `carat/domain/vim_pattern.rb`, reached from `FindMatch`, `PreviewSearch`, and `LastSearch#recompile` through `VimPattern.compile`.
- Why it matters: `/~` answers `E33: No previous substitute regular expression` even after a substitute, where Vim matches the last replacement string; only a substitute's own pattern reads it. The same path is reached after `:s/a~/x/`: `SubstituteLines#remember` (`carat/use_cases/search/substitute_lines.rb:113`) makes that pattern the last search pattern, so a later `:set ic` (`LastSearch#recompile`) or an empty `//` compiles it without the substitute memory and answers E33 (quality advisory at 127a14f).
- Fix outline: hand the `LastSubstitute` record to the three search call sites and compile with its expanded string, as `SubstituteLines` does through `compile_substitute`, with a row in `test/editor_search.rb` for `/~` and one for `:s/a~/x/` followed by `:set ic` and `//`; until then, `remember` could keep a pattern holding `~` out of `recompile`.

## Sentence motions rescan the whole buffer on every use

- Where: `Carat::Domain::Motions.sentence_starts` in `carat/domain/motions.rb` (line 416 at 7711421), called by `(` and `)` and by the `is` and `as` text objects in `carat/domain/text_objects.rb` (line 150 at 7711421).
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

## Plugins cannot highlight ranges or add virtual text

- Where: the plugin API in `carat/plugin_api.rb` and the frame presenter in `carat/adapters/frame_presenter.rb`; `syntax-highlighting` gave plugins tokenizers for whole filetypes and `Host#syntax_group`, but no request to color an arbitrary range of a buffer or to show text that is not in it.
- Why it matters: the explorer's marked line, search matches from a finder, diagnostics underlines, and git blame all need a range highlight or virtual text that is not part of the language's tokens; section 9.1 of `docs/architecture.md` lists them.
- Fix outline: add `add_highlight(buffer, row, from_col, to_col, group)` and `clear_highlights(buffer)` per plugin, kept in a per-buffer layer moved by the splice like the sign layers, and painted by the frame presenter after the tokens; a virtual text layer of the same shape after it; bump the API minor.

## Only Ruby has a tokenizer

- Where: `config/plugins.caratrc` lists one tokenizer plugin, `carat/plugins/ruby/`, and `Carat::Domain::Filetype` in `carat/domain/filetype.rb` detects only `ruby`.
- Why it matters: section 8.2 of `docs/architecture.md` names Markdown, JSON, and YAML too; every other file is drawn plain.
- Fix outline: one compiled plugin per language under `carat/plugins/<language>/` with its own tokenizer and state encoding, its extensions added to the `Filetype` tables, listed in `config/plugins.caratrc` and `config/default.caratrc`; the tokenizer test table of `test/plugins_ruby.rb` is the model.

## :set handles only filetype, syntax, the search options, and cursorline

- Where: `Carat::UseCases::SetCommandHandler` in `carat/use_cases/ex/set_command_handler.rb`, which handles `filetype`, `syntax`, and the booleans `ignorecase`, `smartcase`, `hlsearch`, and `incsearch` (since `buffer-search`) and `cursorline` (`cul`, since `cursor-shapes`), answers `Not implemented: :set name` for the other options the editor already has and `E518` for the rest; no `:setlocal`, no `:filetype`.
- Why it matters: `:set number`, `:set ts=4`, `:set nowrap`, and the rest of Neovim's option commands are roadmap item 9, `options-and-config`.
- Fix outline: grow the handler into the option table that item brings (names, abbreviations, types, global or local), keeping the `filetype`, `syntax`, and search answers; add `:setlocal` and the `&`, `+=`, `-=` forms there, with `no`, `inv`, `!`, and `?` moved from the booleans to every boolean.

## Themes are chosen only at startup and cannot be tuned

- Where: `Carat::Domain::Themes` in `carat/domain/themes.rb` holds the four palettes since `theme-tokens`, chosen once at startup by the `option.theme` and `option.background` lines; there is no `:colorscheme`, no `:highlight`, no `:set background`, and no theme lines in the configuration.
- Why it matters: users expect to switch or tune a color scheme without restarting or rebuilding; the user and project configuration files can only name a shipped palette.
- Fix outline: read `theme.<name>.<group>` lines from the configuration files (foreground, background, 256-color and 16-color values, and attributes as words, applied over a shipped palette), add `:colorscheme name` and `:set background=` that rebuild the screen presenter's SGR table and redraw, and `:highlight Group guifg=... ctermfg=...` for single groups.

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
- Fix outline: reduce each to a minimal program (a module function with a literal-branch `case` called with a literal; a ternary of `""` and an indexed `to_s` in a two-parameter method; a constant array's `include?` of a reader called on a `Data` value; a guard `return path if slash.nil?` before `path.byteslice(...).to_s`, which answered the path inside the whole program in `PluginApi::Paths.basename` during `utf8-input-safety` though not in a small probe), report them upstream, and recheck them when `SPINEL_REF` is bumped.

## The plugin host keeps many-method classes in use_cases

- Where: `carat/use_cases/plugins/`: `PluginHost` (18 public methods besides `call`), `PluginRegistry` (24), `PluginEntries` (5), `PluginEntry` (5), `PluginEvents` (4), `PluginRouter` (4), `PluginSyntax` (3), and `PendingEvent` (1), which the one-call rule of `test/lint.rb` skips by directory since the `use-case-boundaries` change; the request families (`BufferRequests`, `WindowRequests`, `FileRequests`, `UiRequests`) and `PluginLink` keep their request methods by design, as the adapter of `PluginApi::Host`.
- Why it matters: the rule that a use case exposes only `call` holds for the core, but the host's parts are not use cases at all: they are the infrastructure between compiled plugins and the core, and while they sit in `use_cases` the layer reads as if a use case could have two dozen entry points. The `use-case-boundaries` change decided they move out with the whole host and left the move to this plugin-side part, because it reworks the host's construction, the assembly, and five test programs.
- Fix outline: move `carat/use_cases/plugins/` with `concerns/guarded.rb` and `plugins/boundary.rb` to carat/adapters/plugins/ as `Carat::Adapters`, give the core a port in `carat/ports/` for the calls the use cases make into the host (`observe`, `saved`, `resized`, `answer`, `action`, `command?`, `command`, and the tokenizer calls of `HighlightView`), implemented by the host and handed to `SaveFile`, `HandleKey`, `CancelCommandLine`, `ExecuteCommandLine`, `PluginActionHandler`, `PluginCommandHandler`, and `HighlightView` by the assembly, keep the request families' request methods, update the layer ranks and `docs/architecture.md` sections 3, 5, and 9, and drop the `use_cases/plugins/` exemption from the one-call rule.

## Spinel drops appends to an empty array literal passed to a method

- Where: found in `Config#report` (`carat/domain/config.rb`), whose merge helper first appended to an array the caller created as `[]`; on the pinned Spinel the caller's array stayed empty, while one created as `[0]` kept the appends (`docs/spinel-notes.md`).
- Why it matters: any helper that fills an out-parameter starting empty silently loses its work, and only a test of the result catches it.
- Fix outline: reduce it with `spinel-reduce`, report it upstream with the probe, and when a fixed pin arrives let `merge_runs` append in place again; until then a filling helper returns the array and the caller assigns it.

## Spinel compiles private_constant without enforcing it

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); every `private_constant` line under `carat/use_cases/` since the `use-case-boundaries` change.
- Why it matters: a probe on the pinned compiler compiled `private_constant :NAME` and still let another class read `Owner::NAME`, which CRuby refuses with `NameError`, so the declaration documents the intent but stops nothing. `private` on methods is enforced (a call raises `NoMethodError`). `test/lint.rb` carries the rule instead: every constant of a use case file is listed in a `private_constant`, and no file names `Owner::NAME` of a use case outside its own file.
- Fix outline: reduce it to a minimal program (a class with a private constant read from another class), report it upstream, and when a `SPINEL_REF` bump enforces it, keep the lint rule only as a check that the list is complete.

## Nothing compiles the generators' output on every check

- Where: `tools/new.sh` and its tests in `tools/tools_test.sh`, which check the files each generator writes and the lines it inserts, not that they compile.
- Why it matters: a convention that changes (a base class's constructor, an anchor's neighbor, a lint rule) could leave a generator writing code that no longer compiles or lints, and nothing would say so until an author ran it. The `authoring-kit` change compiled, linted, and tested the output of all five generators by hand in a scratch worktree (59 tests, `spinel-doctor` clean).
- Fix outline: a `make generators-check` target that runs every generator in a temporary worktree, then `make gen-config`, `make lint`, `make test-build`, and `make test-run` there, run by the checker when `tools/new.sh`, `carat.rb`, `EditorAssembly`, the handler bases, or `test/lint.rb` change rather than on every check, since it costs a full analysis of the library.

## CI actions are pinned by tag

- Where: `.github/workflows/ci.yml` (line 36 `actions/checkout@v4`, and the same at lines 65, 91, 175, and 192, with `actions/cache@v4` and its `restore` and `save` forms). Low finding of the periodic security review at 66fd52b; at eb63fb4 the periodic security review found line 24 too, Low (3).
- Why it matters: a tag can be moved to other code, so a compromised action release would run in CI with the repository's token.
- Fix outline: pin each action to a full commit hash with the tag in a comment, and say in `CLAUDE.md` or the Makefile note how the pins are bumped.

## The benchmark reuses one temporary report path

- Where: `bench/run.sh` (line 22, `REPORT=$(mktemp "${TMPDIR:-/tmp}/carat-bench-alloc.XXXXXX")`), deleted after the first scenario and reused by name for the later ones, with no trap, and created before the binary check. Low finding of the periodic security review at 66fd52b.
- Why it matters: on a shared `/tmp` another user can plant a symlink at the freed name, which `SPINEL_ALLOC_REPORT` then writes through.
- Fix outline: create the file with `mktemp` inside each `per_key` call, or make a private `mktemp -d` directory removed by a `trap`, after the binary check.

## A lone prefix of a user binding waits with no time limit

- Where: `HandleKey` in `carat/use_cases/handle_key.rb` (line 165 answers `:waiting` for every `:prefix` in a grammar mode), and `InputController#handle`, which sets no deadline then; `timeoutlen` (`config/default.caratrc` line 28) no longer applies there. Advisory of the periodic quality review at 66fd52b, left by `window-navigation-and-scroll`.
- Why it matters: Neovim waits without a limit only on its built-in multi-key commands and times user mappings out, so a configuration binding such as `<leader>x` with `<leader>` alone bound to nothing never resolves on its own here.
- Fix outline: mark the keymap trie nodes that only configuration-origin (user and project) bindings pass through, and have `HandleKey` answer `:pending` for such a prefix so `timeoutlen` applies, with a row in `test/editor_normal.rb`.

## ScrollHandler sets a base class trait after super

- Where: `ScrollHandler#initialize` in `carat/use_cases/actions/scroll_handler.rb` (line 20 writes `@breaks_insert` after `super(kind: :action, repeat: false)`); `ActionHandler#initialize` (`carat/use_cases/actions/action_handler.rb` line 28) takes only `kind` and `repeat`. Advisory of the periodic quality review at 66fd52b.
- Why it matters: a handler trait set in two ways (the constructor's keywords and a later write) is easy to miss when the base class changes.
- Fix outline: add `breaks_insert:` to `ActionHandler#initialize`, pass it from every subclass, and drop the write; or document the override in `docs/examples.md`.

## Half-page scroll targets have two names

- Where: `ScrollHandler.register` in `carat/use_cases/actions/scroll_handler.rb` (lines 33 and 34: actions `scroll.half_page_down` and `half_page_up`, targets `:half_down` and `:half_up`), `carat/use_cases/windows/scroll_window.rb` (lines 29 and 30), and `carat/use_cases/windows/scroll_request.rb` (line 4). Advisory of the periodic quality review at 66fd52b.
- Why it matters: one thing under two names makes a search for the action miss the code that runs it.
- Fix outline: rename the targets `:half_page_down` and `:half_page_up` in the three files.

## Nine comments break their file's wrap width

- Where: the class comment of `carat/use_cases/windows/scroll_window.rb` (line 18, 107 characters), advisory of the periodic quality review at 66fd52b, the class comment of `carat/doubles/memory_files.rb` (line 10, 104 characters), advisory of the periodic quality review at 389c118, the class comment of `carat/ports/terminal_port.rb` (line 4, 130 characters), advisory of the periodic quality review at 5b128b5, the class comments of `carat/use_cases/plugins/window_requests.rb` (line 23, 104 characters) and `carat/adapters/frame_presenter.rb` (line 48 at 3a99ddd, 105 characters, the line about one segment per row and window), advisories of the periodic quality review at 3a99ddd, and, quality advisories of `cursor-shapes`, the class comment of `carat/use_cases/ex/set_command_handler.rb` (line 17, 94 characters) the class comment of `carat/domain/frame.rb` (line 15, a short ragged line of 37 characters), and the class comment of `carat/domain/options.rb` (line 21, 77 characters), advisory of the periodic quality review at d5036f4, and the class comment of `carat/domain/buffer_list.rb` (line 15 at 68eb750, which breaks after "The feed" at about 51 characters), advisory of the periodic quality review at 68eb750. Line 37 of `carat/use_cases/dispatcher.rb`, once listed here, is the one-line signature of the constructor, not a comment to rewrap (quality advisory of `explorer-folder-toggle`). At 38628bb also `carat/use_cases/handle_key.rb` line 65, `carat/domain/config.rb` line 206, `carat/domain/options.rb` line 17, and `tools/agent_guard.sh` line 31 (periodic quality); also `carat/adapters/json_rpc_language_gateway.rb` line 509 and `carat/domain/language_server.rb` line 166 at b76b722; also `tools/agent_guard.sh` lines 37 to 38 and `carat/use_cases/plugins/buffer_requests.rb` line 49 (periodic quality at 847851d); also, periodic quality at 186ddfb, `carat/use_cases/files/open_file.rb` line 20 (about 140 characters), `carat/use_cases/completion/show_completion.rb` line 25, `carat.rb` lines 2 to 6 (about 91 characters), `carat/adapters/frame_presenter.rb` lines 41, 68, and 81, `carat/adapters/status_bar.rb` line 16 (about 100 characters), `carat/adapters/painted_rows.rb` lines 9 and 16, and `carat/domain/frame.rb` line 31.
- Why it matters: style only; the rest of each file wraps comments at the surrounding width.
- Fix outline: rewrap the nine comments to the width of the lines around them.

## lh time per key rose 26% at window-navigation-and-scroll

- Where: the `review.bench` record of `window-navigation-and-scroll` (lh median 11.7 to 14.8 microseconds per key, allocations 27.0 unchanged); no code location is known. Advisory of the periodic quality review at 66fd52b.
- Why it matters: goal 3 of `docs/goals.md` watches time per key; a rise reported as not blocking and never measured again may hide a cost of the prefix wait or the `breaks_insert` check.
- Fix outline: run `make bench SCENARIOS=lh` on `main` and on its parent several times on one pinned core; if the rise holds, profile `lh` with `make profile` and fix or record the cause.

## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers

- Where: `DecodedLine.decode` and `FramePresenter#paint_text` (`carat/domain/decoded_line.rb`, `carat/adapters/frame_presenter.rb`); `utf8-input-safety` draws each byte outside a well-formed UTF-8 sequence as one U+FFFD cell.
- Why it matters: Neovim shows such a byte as a four-cell `<xx>` marker, so two lines that differ only in an illegal byte look alike here, and the byte cannot be read from the screen.
- Fix outline: decode an illegal byte to a code that keeps the byte (for example a private marker range), draw it as `<xx>` the way the C1 markers are drawn, measure it as four cells in `DecodedLine`, `DisplayWidth`, and the cursor placement, and add rows to `test/domain_utf8.rb` and `test/adapters_frame_presenter.rb`.

## Options repeats its bounded-number and known-name checks

- Where: `Options#apply` in `carat/domain/options.rb`: the `tabstop` and `shiftwidth` blocks (lines 107 to 120) and the `icons` and `theme` blocks (lines 125 to 136) are each the same check-then-set-or-note shape. Advisory of the periodic quality review at 389c118. At 38628bb `keyhints.delay` (line 156) repeated the shape too (periodic quality), and at 7711421 the `breadcrumbs` block (line 221, periodic quality); `layout-slots` shares `Options.range_problem` between it and the three slot sizes, leaving `tabstop`, `shiftwidth`, `icons`, and `theme`.
- Why it matters: a third bounded option copies the block again, and a fix to one copy can miss the other.
- Fix outline: one private helper that takes the line, the value, and the low bound and returns whether to set (or a `width_value?` check both call), and one for a name checked against a known set; the rows of `test/domain_options_config.rb` stay as they are.

## OpenFile asks the port about a path twice

- Where: `OpenFile#call` in `carat/use_cases/files/open_file.rb` line 45, `@files.exist?(path)` and then `ProbePath` through `refusal`. Advisory of the periodic quality review at 389c118.
- Why it matters: `docs/architecture.md` section 5.2 says `ProbePath` is the one place a use case asks the port about a path, and the two answers can disagree on a dangling link.
- Fix outline: take existence from the one `ProbePath` result, deciding the dangling-link case (a new buffer or "is not a file") with a row in `test/editor_cmdline.rb`. Queued as `file-access-tidy`.

## The architecture lists only some of OpenFile's responses

- Where: `docs/architecture.md` section 5.2 (line 171) lists `E37`, `E212`, and `E492` as the responses of the file use cases. Advisory of the periodic quality review at 389c118.
- Why it matters: `OpenFile` also refuses a directory, a non-regular file, and a file over 64 MiB with `E484` and Vim's messages, and the binding document should say so.
- Fix outline: name those responses in that line, making room within the document's budget. Queued as `file-access-tidy`.

## Every test run builds two 64 MiB strings

- Where: `test/editor_cmdline.rb` lines 155 and 156 put a file one byte over and one exactly at `OpenFile`'s 64 MiB limit into `MemoryFiles`, and open the second. Advisory of the periodic quality review at 389c118.
- Why it matters: 128 MiB of strings and a 64 MiB read in every test run cost memory and time for one boundary, and are a suspect for slower CI.
- Fix outline: let `MemoryFiles` report a stat size for a path (as `special` does for the kind) so the over-limit row needs no real string, and keep the exact-limit read check in `test/drivers_disk_files.rb` with its small limit. Queued as `file-access-tidy`.

## DiskFiles#stat makes four system stats per path

- Where: `DiskFiles#stat` in `carat/drivers/disk_files.rb` line 57, `File.size`, `File.mtime`, `File.directory?`, and `File.stat` for one path. Advisory of the periodic quality review at 389c118.
- Why it matters: every open, explorer listing, and plugin stat pays four system calls where one would do, and the answers can come from different moments.
- Fix outline: take the size, mtime, directory, and regular flags from one `File.stat` where the pinned Spinel supports them, else record why in `docs/spinel-notes.md`. Queued as `file-access-tidy`.

## The CI scope script word-splits the changed paths

- Where: `tools/ci_scope.sh` (line 66, the unquoted `for path in $changed`, over `git diff --name-only`). Low (3) finding of the periodic security review at 6ea61b1, and Low (5) finding of the security review of `untrusted-config-limits`; queued in `pipeline-hardening`.
- Why it matters: the loop splits names on spaces and expands glob characters, so a pull request whose changed paths contain them, such as `a.md .claude/x`, can make a change to code read as documentation only and CI skips `spin check`.
- Fix outline: read `git diff --name-only -z` into a `while read` loop with `IFS` unset and `set -f`, quote `"$path"`, and add a `tools/tools_test.sh` case with a spaced path and one with a glob character.

## Three copies of the byte basename

- Where: `Filetype.from_name` in `carat/domain/filetype.rb` (line 30) and `Buffer#name_start` in `carat/domain/buffer.rb` (line 226 at 8d8832f; `FramePresenter#file_name`, once at `frame_presenter.rb` line 660, is gone) each copy the byte basename that `PluginApi::Paths.basename` (`carat/plugin_api.rb:315`) gives and `Domain::PathPolicy.last_name` reuses, while `Filetype.base` (line 68) still uses `rindex`; `hold`, `launch`, and `initialize_params` in `carat/adapters/json_rpc_language_gateway.rb` (lines 247, 261, and 274 at eb63fb4) call `File.basename` on a server's command or the working directory. Advisory of the periodic quality review at 6ea61b1, the gateway's of `lsp-diagnostics`' retrospective.
- Why it matters: three copies of one byte walk drift apart, and the `rindex` copy groups a lead byte with what follows on a name that is not UTF-8.
- Fix outline: call `PluginApi::Paths.basename` in all three places. Folded into `docs-index`.

## Filetype.program_type mixes byte and character indexes

- Where: `Filetype.program_type` in `carat/domain/filetype.rb` (line 75) starts at `program.length` (characters) and reads `getbyte(stop - 1)` and `program[0, stop]`. Advisory of the periodic quality review at 6ea61b1.
- Why it matters: byte and character positions disagree on a non-ASCII program name; harmless today because no such name is in `PROGRAMS`.
- Fix outline: use `bytesize` and `byteslice` throughout.

## code_of decodes UTF-8 inside DisplayWidth

- Where: `DisplayWidth.code_of` in `carat/domain/display_width.rb` (line 54), a decoding helper in the width table. Advisory of the periodic quality review at 6ea61b1; `feedback` deleted its only `Motions` caller, the dead `Motions.keyword?` and `char_class`, with the `display_width` require.
- Why it matters: a decoding helper kept in the width table hides the dependency and invites another copy.
- Fix outline: move it to `Utf8` (for example `Utf8.first_code`) and call it from `DisplayWidth`.

## Visual r over an illegal byte has no test row

- Where: the `:replace` branch of `ascii_recase` in `carat/domain/operators.rb` (line 244, `char * text.length` over text that is not UTF-8), while `~`, `U`, and `u` have rows in `test/editor_registers.rb` (lines 49 to 51). Advisory of the periodic quality review at 6ea61b1.
- Why it matters: an untested branch on hostile text is where the next crash on an illegal byte would hide.
- Fix outline: add a `v$r` row over a line with an illegal byte.

## File operations check containment and act in separate calls

- Where: `carat/use_cases/files/resolve_inside.rb` (line 28, the real-path containment check) and the operations it guards, `call` of `carat/use_cases/files/make_path.rb` (its `mkdir` and `write`), `carat/use_cases/files/rename_path.rb` (its `rename`), and `carat/use_cases/files/delete_path.rb` (its `delete`). Low (2) finding of the periodic security review at 16cdcf7, a recorded non-goal of `plugin-path-containment`.
- Why it matters: a directory of the tree replaced by a link pointing outward between the check and the create, rename, or delete redirects the operation outside the tree root, so the containment holds only against a tree that does not change while the explorer acts on it.
- Fix outline: when the file port gains directory-relative operations, open the resolved directory once and act through its descriptor (`openat`, `renameat`, `unlinkat` with no-follow), with a test row in `test/drivers_disk_files.rb`; until then record in `docs/spinel-notes.md` whether the pinned Spinel exposes them.

## The README's commands table omits six make targets

- Where: `README.md` line 14, the commands table, which has no row for `make clean`, `make pack`, `make spinel-rev`, or `make help` (line 12 now names `make install`), periodic quality advisory at df5a203, nor for `make metrics` or `make metrics-compare`, periodic quality at 3895e21.
- Why it matters: the map's Build and CI rule gives every command a README line, and goal 12 keeps the README current.
- Fix outline: add one row naming the missing targets, or one row per target, checked against `make help`.

## /status and a killed run lose the package, CI, and merge phases

- Where: `.claude/workflows/deliver-change.js` lines 608 to 625, which leave the package, CI, and merge phase lines to the closing start, and the next-phase loop of `show_status` in `tools/run_state.sh` (line 489). Advisory of the quality review of `workflow-records`.
- Why it matters: during the CI wait `/status` prints next phase package although the pull request is open, and a run killed between the merge and the closing start never records package, ci, and merge, so its history row lacks those phases.
- Fix outline: have `status` read `pushed`, `pr`, and `merged` as the resume does when the phase lines are absent, or record each phase as soon as its own record exists; add a `tools/tools_test.sh` case for a run state with `pushed` and `pr` but no package line. Queued in `run-resume`.

## The contributor can edit the agent files of its own run

- Where: the agent files under `.claude/agents/`, whose hook lines name each agent's guard profile and which the contributor's file tools may write. What remains of the periodic security Low (6) at 8c340cd after `guard-allowlist` made every hook run `origin/main`'s guard and refuse on any failure.
- Why it matters: if the harness reads an agent file from the working tree when the workflow starts that agent, an edit on the branch (a hook line removed, a profile widened) applies to the later agents of the same run before any review.
- Fix outline: have the workflow compare `.claude/agents/` and `.claude/settings.json` with `origin/main` before it starts each agent and stop on a difference the brief does not name, or refuse the contributor's edits of them unless a record only the workflow writes names them; add a `tools/tools_test.sh` case. Queued in the backlog-items change of `docs/queue.md` (review triggers).

## The CI scope reads a moved code file by its new path

- Where: the documentation-only test of `tools/ci_scope.sh` (line 62), which uses `git diff --name-only` with rename detection on. Periodic security Low (5) at 8c340cd.
- Why it matters: a pull request that only moves code files to a Markdown or `openspec/` path is listed by the new paths, so CI skips `spin check`, and the push to `main` then skips it as a passed head.
- Fix outline: list the paths without rename detection, together with the fix of the entry "The CI scope script word-splits the changed paths", and add a `tools/tools_test.sh` case. Queued in `ci-hardening`.

## The search budget charges a line's length on ASCII lines too

- Where: `Carat::Domain::Search.match_at` in `carat/domain/search.rb` (line 101), which charges every match tried its line's length as a fixed cost; the risk note at line 50 of the archived design of `buffer-search` and the Search rows of `docs/compatibility.md`. Quality advisory of `buffer-search` at a36858a2bc88.
- Why it matters: `docs/spinel-notes.md` implies the engine finds a code-point position without a scan on ASCII-only text, so the charge is needed only on other lines; as it is, `N` or `?` on a long ASCII line (minified code) with more than about 400 million divided by its length matches before the cursor stops with `E363`, a frame highlights only about 20 million divided by the length matches of such a line, and the design says only non-ASCII lines stop.
- Fix outline: compute `text.ascii_only?` once per line beside its length and charge the fixed cost only when it is false, with a `domain_search` row of a long ASCII line of many matches searched backward; or correct the risk note in the design and `docs/compatibility.md`. Queued in `search-tidy`.

## Match highlighting walks matches left of the scroll and keeps rows painted after the budget stopped

- Where: `FramePresenter#paint_matches` in `carat/adapters/frame_presenter.rb` (line 569) and the back-row store of `paint_row`'s caller (line 382). Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: every match is walked from code point 0, also those left of a horizontal scroll, and a row painted after the frame budget stopped is stored with the search stamp, so it stays unhighlighted until the stamp changes.
- Fix outline: store 0 as the stamp of a row painted under a stopped budget so the next frame retries it, and start the walk from the first match that can reach the left column, with an `adapters_frame_presenter` row for each. Queued in `search-structure`.

## A second caret after the start of a pattern is read as an anchor

- Where: `VimPattern#caret` in `carat/domain/vim_pattern.rb` (line 261), which leaves `@at_start` set. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: `/^^` compiles to two anchors, where Vim reads the second `^` as a literal caret, so the search misses a line starting with `^`.
- Fix outline: clear `@at_start` in `caret` and keep a separate flag so a `*` right after `^` stays literal, with a `domain_vim_pattern` row for `^^` and `^*`. Queued in `search-tidy`.

## The search offset is found by a collection scan that differs from the compiler's

- Where: `VimPattern.pattern_end` in `carat/domain/vim_pattern.rb` (line 105), which skips a collection to the first `]` after `[x`, unlike `collection_end`. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: `/[\]/]` or `/[^]/]` is cut at the inner `/`, so the rest of the collection is taken as a search offset and the pattern searched is not the one typed.
- Fix outline: share `collection_end`'s scan (an escaped `]` and a `]` right after `[` or `[^`) with `pattern_end`, with `domain_vim_pattern` rows for both forms. Queued in `search-tidy`.

## Operate passes the search outcome through an instance variable

- Where: `Operate#search_motion` in `carat/use_cases/operate.rb` (line 131), which sets `@notice` deep in `motion_for` for `call` to read. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: the outcome travels by a side channel in a use case instead of a return value, which is harder to follow and easy to leave stale when another path through `motion_for` is added.
- Fix outline: return the hit's outcome with the operand as a small result value, or have the operator handler run `FindMatch` first and pass the hit in. Queued in `search-structure`.

## REGISTER_ONE_MOTIONS repeats the search action names

- Where: `REGISTER_ONE_MOTIONS` in `carat/use_cases/operate.rb` (line 47), which lists the eight search action names `Domain::Search` already lists. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: a search action added to `Domain::Search` and not to the list would delete within a line without writing register 1, unlike Vim.
- Fix outline: keep the four sentence and paragraph motions in the list and test `Domain::Search.action?(action)` beside it. Queued in `search-structure`.

## The :noh row names a test that has no :noh case

- Where: the `:noh[lsearch]` row of `docs/compatibility.md` (line 262), and task 3.2 of the archived `buffer-search` change, which say `use_cases_ex` proves `:set` and `:noh`; `test/use_cases_ex.rb` has no `:noh` or search-option case. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: the compatibility table is how a reader finds the test of a command, and this one points to a file that does not test it (`editor_search` does).
- Fix outline: drop `use_cases_ex` from the row, or add the `:noh` and search-option cases to `test/use_cases_ex.rb`. Queued in `search-tidy`.

## Visual star and hash search the word, not the selection

- Where: the `keymap.visual *` and `keymap.visual "#"` lines of `config/default.caratrc` (line 213), bound to `search.word_forward` and `search.word_backward`. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: Neovim's default visual `*` and `#` search the selected text, so a user selecting part of a line gets a different search than in Neovim, and the Search rows of `docs/compatibility.md` do not say so.
- Fix outline: list the difference under Search in `docs/compatibility.md` now, and bind the visual keys to a selection search when one is added. Queued in `search-tidy`.

## Incremental search spends the full search budget on every key

- Where: `PreviewSearch#call` in `carat/use_cases/search/preview_search.rb` (line 48), which resets the budget to `Domain::SearchBudget::SEARCH`. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: with `incsearch` on, a costly pattern spends about 1.5 seconds on each key typed at the prompt, so typing stalls key by key.
- Fix outline: give the preview its own smaller `SearchBudget` constant and end the preview without a match when it stops, with a `use_cases_search` row. Queued in `search-tidy`.

## Resuming a pattern prompt resets the mode a second time

- Where: `HandleKey#resume` in `carat/use_cases/handle_key.rb` (line 215), which sets the mode to normal outside visual although `CancelCommandLine` and `ExecuteCommandLine` already restored the prompt's return mode. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88.
- Why it matters: two places decide the mode after the prompt, so a change to the return mode of the prompt has to be made in both or the second one overrides it.
- Fix outline: drop the line and keep the return mode the command line restores, checked by the existing `editor_search` rows. Queued in `search-structure`.

## The pattern-source cut and the prompt prefix are written twice

- Where: `VimPattern.pattern_end(text, forward ? 47 : 63)` with bare byte codes in `carat/use_cases/search/find_match.rb:68` and `carat/use_cases/search/preview_search.rb:37`, and the forward-to-`/`-or-`?` choice at `find_match.rb:159` repeating `SearchPrompt#prefix` (`carat/domain/search_prompt.rb:61`). Periodic quality at 0b17324.
- Why it matters: two use cases decide where a pattern ends and which delimiter a direction uses, with unnamed byte codes, so a fix to one (such as the collection scan of `pattern_end`) can miss the other.
- Fix outline: one domain function for the pattern source with named delimiter constants and one prefix helper, called from both use cases. Queued in `search-tidy`.

## FindMatch re-implements the domain's character classes

- Where: `FindMatch#keyword?` and `#blank?` in `carat/use_cases/search/find_match.rb` (line 129), `keyword?` through the bare class number in `Motions.code_class(code, false) == 2`. Periodic quality at 0b17324.
- Why it matters: the word under the cursor for `*` and `#` is judged by a copy of the classes `Domain::Motions` owns, keyed on an unnamed number, so a change to the classes leaves the search motion behind.
- Fix outline: a code-point predicate in `Domain::Motions` (or a named class constant) called from `FindMatch` and the runs scan. Queued in `search-structure`.

## The local cls is the abbreviation the naming rule forbids

- Where: the local `cls` in `carat/domain/text_objects.rb` (line 86 at 3895e21) and the parameter `cls` of `Runs#add` (`carat/domain/runs.rb:18`). Periodic quality at 0b17324.
- Why it matters: `CLAUDE.md` names `cls` as the counterexample of its naming rule (`char_class`, not `cls`).
- Fix outline: rename both to `char_class`. Queued as a fold of `search-structure`.

## FramePresenter passes the painted row through instance variables

- Where: `@row_of` and `@current` in `carat/adapters/frame_presenter.rb`, set at lines 758 and 788 and read at 1064 by `paint_matches` (at 8d8832f). Periodic quality at 0b17324.
- Why it matters: the row and the window's currency reach `paint_matches` through a side channel, as the entry "Operate passes the search outcome through an instance variable" records for `Operate`, so a call order change paints with a stale row.
- Fix outline: pass the row and the currency to `paint_row` and on to `paint_matches` as arguments and drop the two instance variables. Queued in `search-structure`, with the entry "Match highlighting walks matches left of the scroll and keeps rows painted after the budget stopped".

## The guard does not judge input redirections

- Where: `redirect` in `tools/agent_guard.sh` (line 752), which checks only write targets. Security Low (5) of `guard-allowlist` at 31a93d257317.
- Why it matters: `< /dev/tcp/HOST/PORT` opens an outbound connection from any profile, a path for exfiltration through the hostname or DNS by an agent that text in the tree leads astray.
- Fix outline: refuse a read target under `/dev/tcp/` or `/dev/udp/` (or allow only targets in the project and `/dev/null`), with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## The guard judges relative words after a cd against the project

- Where: the `cd` form in `judge`, `tools/agent_guard.sh` (line 724). Quality advisory of `guard-allowlist` at a979633e8a4d and again at 31a93d257317.
- Why it matters: `cd tmp/.base && mkdir -p tmp/scout/x` passes with DIR `tmp/scout` and writes `tmp/.base/tmp/scout/x`; benign today, since only DIR- or `build/stages`-prefixed paths inside the worktree are reachable, but the guard no longer reads the command as the shell runs it.
- Fix outline: refuse a relative write target after a `cd` other than to the project, or resolve it against the `cd` target, with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## The guard admits date with any argument

- Where: the shared plain tools in `judge`, `tools/agent_guard.sh` (line 710). Quality advisory of `guard-allowlist` at 31a93d257317.
- Why it matters: `date -s 2001-01-01` passes every profile and, run as root, sets the system clock that git and the run state's timestamps read, against an allowlist of what each agent needs (the scout runs only `date -u +FORMAT`).
- Fix outline: admit `date` only with `-u` and a `+FORMAT` word, with a refusal case in `tools/tools_test.sh`. Queued in `guard-lows`.

## The guard decodes the JSON escapes \b and \f to letters

- Where: `field` in `tools/agent_guard.sh` (line 114), whose else branch keeps the escaped character. Quality advisory of `guard-allowlist` at 5af7fd9d9784, 14b18734b96e, and 31a93d257317.
- Why it matters: the guard judges the word `lsb` where bash runs `ls` and a backspace, against the header's "any other one ?"; no blank or operator diverges, since bash reads backspace and form feed as word characters, but the guard should read the command as the shell does.
- Fix outline: decode `\b` and `\f` to `?` like `\u0008` and `\u000c`, with a `tools/tools_test.sh` case for `ls\b#; git push origin x`. Queued in `guard-lows`.

## uniq -f 1 FILE is refused

- Where: `uniq_form` in `tools/agent_guard.sh` (line 668). Quality advisory of `guard-allowlist` at 3efc71ba34f8 and again at 31a93d257317.
- Why it matters: the value of `-f`, `-s`, or `-w` given as a separate word counts as an operand, so a normal read-only form is refused (it fails closed).
- Fix outline: skip the word after `-f`, `-s`, and `-w`, with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## The guard header lists printf without its restriction

- Where: the shared forms of the header of `tools/agent_guard.sh` (line 25). Quality advisory of `guard-allowlist` at 3efc71ba34f8 and again at 31a93d257317.
- Why it matters: `judge` refuses `printf` with a leading option, so the header no longer says what the code allows.
- Fix outline: write `printf (no leading option)` in the header's shared forms. Queued in `guard-lows`.

## The guard and gates review area leaves out the review's own record keepers

- Where: the `guard and gates` pattern of `REVIEW_AREAS` in `tools/run_state.sh` (line 161). Security Low (7) of `pipeline-speed` at b0df2ac092ed.
- Why it matters: the narrowed pattern leaves out `tools/run_state.sh` (whose review, get, trusted, and push records `tools/gates.sh` trusts), `.claude/workflows/deliver-change.js` (which runs the security reviewer and writes the review record), and the security-reviewer and merger agent bodies, so a change that weakens how the review is recorded no longer makes a whole-tree periodic review due.
- Fix outline: add `tools/run_state[.]sh$` and `[.]claude/workflows/` to the pattern, and count an edit of `.claude/agents/security-reviewer.md` or `.claude/agents/merger.md` as due, with a `tools/tools_test.sh` case. Queued in the backlog-items change of `docs/queue.md` (review triggers).

## agent_hooks misses frontmatter keys that widen an agent's authority

- Where: `agent_hooks` in `tools/run_state.sh` (line 701), which counts only `tools` and hook lines as the guard's wiring and reads `git diff` with `2>/dev/null`. Security Low (6) of `pipeline-speed` at b0df2ac092ed, and a quality advisory at 1d187291be30.
- Why it matters: adding `permissionMode:`, `mcpServers:`, `disallowedTools:`, or a list-form tool item to an agent does not make the periodic review due, and a failing `git diff` fails open, so the review is skipped exactly when the agent's authority changes.
- Fix outline: treat any changed line between an agent file's frontmatter delimiters other than `name`, `description`, and `model` as guard and gates, and report the review due when the diff fails, with a `tools/tools_test.sh` case. Queued in the backlog-items change of `docs/queue.md` (review triggers).

## A resumed run can be granted an extra fix round after stopping at the limit

- Where: `stopKind` in `.claude/workflows/deliver-change.js` (line 67), which starts at `none` on every start. Quality advisory of `pipeline-speed` at 1d187291be30.
- Why it matters: the checker's metric line (`figuresFirst`) overwrites a stored `stop=rounds` with `none` before `mayFix` runs, so a start killed after that check makes the next resume grant an extra round to a run that had stopped at the round limit.
- Fix outline: seed `stopKind` from `lastStop` when `rework` is already at `ROUNDS` plus `extra`. Queued in `run-resume`.

## The guard skips a short cluster that names cp's target directory

- Where: `files_form` in `tools/agent_guard.sh` (line 625), which skips any letters-only short cluster. Periodic security Low (7) at 598cf1b.
- Why it matters: `cp -r -tbuild pipeline` passes the contributor profile and copies a project-root `pipeline` directory into `build/pipeline`, overwriting run state records (`stage.*`, `phase.check`, `pushed`) the guard refuses to write directly.
- Fix outline: refuse a cluster holding `t`, `T`, or `S` for `cp` and `mv`, or judge the attached value and every operand placed under it as a write target, with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## The Skill tool has no hook

- Where: the tools of `.claude/agents/security-reviewer.md` (line 4), the other reviewers, and the contributor, whose hooks match only Bash, Edit, and Write. Periodic security Low (4) at 598cf1b.
- Why it matters: an agent led astray can load any listed skill, including one that changes the configuration or runs in a subagent outside its guard.
- Fix outline: a Skill matcher whose check admits only the skills each agent needs, with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## The guard does not read a tilde after = or : as bash expands it

- Where: the lexer of `tools/agent_guard.sh` (line 173), which refuses only a leading `~`. Periodic quality advisory at 598cf1b.
- Why it matters: `cat a=~/x` and `BASE=~ sh tools/gates.sh trailer` pass while bash runs them with the home directory expanded, against the header's claim that a command is read as the shell reads it; harmless today, since no form takes a path value with a tilde.
- Fix outline: refuse an unquoted `~` right after `=` or `:` in a word that starts with an identifier and `=`, with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## The delivered-changes list stops at pull request 46

- Where: the Delivered changes list closing `docs/codebase-map.md`, whose last numbered line is `#46 buffer-search`: lines 623 to 625 list `pipeline-speed`, `pipeline-speed-b`, and `pipeline-speed-c` without their numbers (#48, #49, #51), and #47, #50, and #52 to #82 are missing. Periodic quality advisories at 598cf1b, f31f4e8, d386c74, 3a99ddd, 803fe6e (notes 24 and 25), and 7711421 (note 22).
- Why it matters: the list `CLAUDE.md` names as the record of delivered changes misses thirty-three merged pull requests and cannot be matched to three others.
- Fix outline: number the three lines and add #47, #50, and #52 to #82, with the check `docs-index` asks for: every merged pull request of `docs/metrics.tsv` appears in the list. Queued in `docs-index`.

## Agents leave scratch files in the repository root

- Where: the repository root, where agents left `build_check_out_tmp` and `.err` twice; the briefs under `.claude/agents/` name no place for scratch output, and the push gates of `tools/run_state.sh push` and `tools/gates.sh` do not look at untracked files (the checker and the security reviewer test `git status --porcelain --untracked-files=no`). The user's request in the brief of `pipeline-speed-b`.
- Why it matters: an untracked file outside `build/`, `dist/`, and `tmp/` can be staged by a later `git add` and reach a pull request, and it shows in every `git status` of the next run.
- Fix outline: the agents' briefs send scratch output under `build/` or `tmp/`, and a push gate refuses an untracked file outside the ignored paths, with a `tools/tools_test.sh` case. Queued in `merge-gate-tidy`.

## A test-only fix after a passing quality review gets the whole branch reviewed

- Where: `.claude/workflows/deliver-change.js` line 375, the scope of a fix review. Quality advisory at d820b39 in `pipeline-speed-b`.
- Why it matters: after a passing quality review followed by a bench or CI fix, `blockedAt` is not that commit, so `files` is null and a test-only fix gets the whole branch reviewed again, where the old `priorQuality` offered only the fix diff; the review costs tokens and rounds the fix does not need.
- Fix outline: when the last quality review passed and no blocked files are recorded at it, give the scope command with no files (tests and records only), with a case in the workflow's tests. Queued in `implement-contracts`.

## The merge's stages gate cannot pass a renamed or removed stage

- Where: `tools/gates.sh` line 195, the merge's stages gate, which reads `CHECK_STAGES` from main's Makefile with `sed`, while `tools/run_state.sh check` reads the list with `make -s stages`. Quality advisory at d820b39 in `pipeline-speed-b`; the archived design of `pipeline-speed-b` does not cover the case.
- Why it matters: a change that renames or removes a stage cannot pass its own merge, since main's list names a stage the branch never ran, and the stage list now has two readers that can disagree.
- Fix outline: use one reader of the list for both scripts, and accept a stage main names that the branch's `CHECK_STAGES` dropped when the branch's diff removes it from the Makefile (or record the rename in the run state), with a `tools/tools_test.sh` case. Queued in `merge-gate-tidy`.

## The merge-gates worktree is never removed

- Where: the merge-gates worktree command in `.claude/workflows/deliver-change.js` (about line 476, beside `MERGE_GATES` at line 455), which now prunes first, and step 8 of `.claude/agents/merger.md`. Periodic quality advisory at e20c83c, again at 7711421 (note 23).
- Why it matters: the command removes `tmp/.merge-gates` before adding it but nothing removes it after the merge, so the first run prints a git error into the gate output the merger reads and every later run finds a stale worktree.
- Fix outline: send the remove's error to `/dev/null` and remove the worktree after the merge. Queued in `merge-gate-tidy`.

## A fix review is never scoped for a finding in a dot directory

- Where: `.claude/workflows/deliver-change.js` line 312 and the scope path check of `tools/run_state.sh` line 349. Periodic quality advisory at e20c83c.
- Why it matters: both patterns refuse a leading dot, so a blocking finding in `.claude/` or `.github/`, the files pipeline changes edit, always sends the next quality review to the whole branch.
- Fix outline: admit a leading-dot segment other than `..` in both patterns, keeping the parent-step check, with a `tools/tools_test.sh` scope case for an agent file under `.claude/agents/`. Queued in `implement-contracts`.

## n and N after :s with the i or I flag keep the flag's case

- Where: `SubstituteLines#remember` in `carat/use_cases/search/substitute_lines.rb:116`, which hands `LastSearch` the pattern compiled under the substitute's `i` or `I` flag. Quality advisory at 76ad185.
- Why it matters: after `:s/A/x/i`, `n`, `N`, and hlsearch ignore case where Vim's `n` follows `ignorecase` and `smartcase`, so the next search finds other matches than Vim's.
- Fix outline: compile the search copy with `VimPattern.compile` under the options before `remember`, with a row in `test/editor_substitute.rb` that runs `n` after `:s/A/x/i` with `noignorecase`. Queued in `substitute-tidy`.

## :s with the c or l flag keeps its replacement before refusing

- Where: `SubstituteLines#call` in `carat/use_cases/search/substitute_lines.rb:55`, where `keep_replacement` runs before the `c` and `l` flags are refused at line 60. Quality advisory at 127a14f.
- Why it matters: `:s/a/b/c` answers `Not implemented: :s flag c` but the next `:&` substitutes `b` with the previous pattern, a substitute the user never ran.
- Fix outline: refuse `c` and `l` before keeping the replacement, with a row that runs `:&` after a refused `:s/a/b/c`. Queued in `substitute-tidy`.

## Replacement inserts a group in two copies of the same block

- Where: `Replacement` in `carat/domain/replacement.rb:95` (`\0` to `\9`) and line 123 (`&`). Quality advisories at 76ad185 and 127a14f.
- Why it matters: the five lines that append a group, recased when `\u`, `\l`, `\U`, or `\L` is set and resetting the one-character case unless the group is empty, are repeated, so a fix to one can miss the other.
- Fix outline: extract a private `insert_group(out, group, one, all)` that returns the new `one`, or read `&` as group 0 in the `\0` to `\9` branch, keeping `lh` and `j` at their figures. Queued in `substitute-structure`.

## LastSubstitute holds case and print as integer codes

- Where: `LastSubstitute` in `carat/domain/last_substitute.rb:11`, the members `case_mode` (0 by the options, 1 ignored, 2 matched) and `print` (0 none, 1 the line, 2 with its number). Quality advisory at 76ad185.
- Why it matters: every reader decodes the codes by a comment, and the member `print` shadows `Kernel#print` inside the record.
- Fix outline: hold symbols (`:options`, `:ignore`, `:match`; `:none`, `:line`, `:numbered`), as `Quit#call` takes its way, and rename the member `print_mode`. Queued in `substitute-structure`.

## ExRange keeps a given member no caller reads

- Where: `ExRange` in `carat/domain/ex_range.rb:12`, whose `given` member is set on every path but read only by `test/domain_ex_range.rb`. Quality advisory at 76ad185.
- Why it matters: a dead member costs a slot per range and suggests a behavior that does not exist.
- Fix outline: drop `given` from `ExRange`, its map entry, and the test's columns, or use it where `buffer-global` needs to tell a default range from a given one. Queued in `substitute-structure`.

## SubstituteArgs.parse tests for a leading blank it never receives

- Where: `SubstituteArgs.parse` in `carat/domain/substitute_args.rb:45`, the `first != 32 && first != 9` tests. Quality advisory at 127a14f.
- Why it matters: `ExGrammar` strips the arguments before they reach `parse`, so the tests never decide and read as if a blank delimiter were handled.
- Fix outline: drop the two tests, or say in the method's comment that `parse` accepts unstripped text and add a row that passes it. Queued in `substitute-structure`.

## CI failures are not classified before a fix round

- Where: the CI step of `.claude/workflows/deliver-change.js` and the merger's brief under `.claude/agents/`, where a red CI goes back to the contributor as a fix round whatever its cause. From the user's insights review in the brief of `pipeline-speed-c`.
- Why it matters: a flaky test or an infrastructure failure (a runner, a cache, a network fetch) would cost a contributor round and a push of the one-push budget for a commit that changes nothing. Low value now: CI passed first in 17 of 17 recorded runs, so no round has been lost to it yet.
- Fix outline: have the CI result name its class (flaky, infrastructure, or code) from the failing step and log, retry the first two once without a fix round or a push, and count only a code failure as rework, with a `tools/tools_test.sh` case per class. Queue it when a CI first pass fails for a cause other than code.

## Changes are delivered one at a time in one tree

- Where: `/deliver` and `.claude/workflows/deliver-change.js`, which run one change per checkout. From the user's insights review in the brief of `pipeline-speed-c`.
- Why it matters: parallel delivery in separate git worktrees would cut wall time (`buffer-substitute` took 114.4 minutes) but not tokens, goal 1's first measure, and nearly every feature edits the same files (`config/default.caratrc`, `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, and `docs/queue.md`), so two parallel features would conflict at the merge and each would need its checks again.
- Fix outline: first measure how often two consecutive queue items share no edited file; if enough do, run such pairs in separate worktrees with separate run states and serialize their merges, each rebuilt and checked against the merged `main`.

## The pipeline has no replay benchmark

- Where: the pipeline as a whole; its only measures are the per-run rows of `docs/metrics.tsv`. From the user's insights review in the brief of `pipeline-speed-c`.
- Why it matters: a workflow change is judged on the next live runs, whose changes differ, so its effect on tokens and rounds is mixed with the change's own size; a replay of a fixed past change would isolate it, but at about 1M total tokens per replay, near a medium budget each, a self-tuning loop of replays costs more than the runs it would tune.
- Fix outline: once the per-run figures settle, replay one small recorded change at a pinned commit after a workflow change that claims a saving, and compare its total tokens, calls, and rounds with the recorded row; no automatic tuning loop.

## A compile pass is cached whatever make command ran it

- Where: `tools/run_state.sh` line 352, the compile-stage skip of `check`, and `compiled_set` and `compiled_same`, which key a pass in `build/pipeline/compiled` by the code key and the outputs only. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: a check run outside the workflow with `MAKE=true` records a diagnose pass that never ran diagnose, which CI does not run either, and every later change on that code key skips it, the forged-check case the design names as its risk.
- Fix outline: fold `make_cmd` into the cached line or the key in `compiled_set` and `compiled_same`, so only a pass by the same make command skips, with a `tools/tools_test.sh` case that a pass under `MAKE=true` does not skip a later run under `make`. Queued in `check-skip`.

## A closing start that returns no result stops the run without a reason

- Where: `.claude/workflows/deliver-change.js` line 686, after the closing start. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: the old code stopped with 'the retrospective returned no result'; now a merged run whose closing start returns nothing returns 'No report' with no reason, and a due periodic review is skipped silently.
- Fix outline: when `close` is null, set `stopped` to 'the closing start returned no result' and keep the resume rerunning that start. Queued in `run-resume`.

## The closing fallback can record a note twice

- Where: `.claude/workflows/deliver-change.js` line 695, the fallback flush after a closing start that did not record, and `add_note` in `tools/run_state.sh`, which dedupes only `quality-advisory` notes. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: when the closing start ran part of the record line before a later command failed, the fallback reruns every line, so an extra-round note is recorded twice and the history counts it twice.
- Fix outline: dedupe identical notes of every kind in `add_note`, or push back only the lines after the one that failed, with a `tools/tools_test.sh` case of a note recorded twice. Queued in `run-resume`.

## The closing phases are listed twice with no pointer between them

- Where: `CLOSABLE` in `.claude/workflows/deliver-change.js` line 266 and `CLOSE_PHASES` in `tools/agent_guard.sh` line 92. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: a phase added to one list and not the other is refused by the guard or misrouted by the workflow.
- Fix outline: name `tools/agent_guard.sh` `CLOSE_PHASES` in the comment above `CLOSABLE`, and the workflow's regex in the comment beside `CLOSE_PHASES`. Queued in `run-resume`.

## The run state header omits the compiled-KEY stage suffix

- Where: the `stage.NAME` line of the header of `tools/run_state.sh` (line 9), which names only the `carried-from-COMMIT` suffix. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: `check` now writes a `compiled-KEY` suffix too, and the header is where a reader of a run state learns its format.
- Fix outline: add 'or compiled-KEY when check skipped a compile stage on its code key' to that line. Queued in `run-resume`.

## The guard reads the shown profile name from the environment

- Where: `refuse` and the profile `case` in `tools/agent_guard.sh` (line 101 in the reviewed commit), which set `shown` only for the `close` profile and print `${shown:-$profile}`. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: an inherited `shown` variable misnames the profile in every refusal, so a refused agent is told the wrong profile's rules.
- Fix outline: initialize `shown=$profile` beside `closing=0` and print `$shown` in `refuse`. Queued in `guard-lows`.

## A substitute expands a replacement before charging the budget

- Where: `carat/domain/substitution.rb` line 44, and its comment at line 12, which says each character of replacement text is charged where line 45 charges `piece.bytesize`. Periodic security Low (6) and quality advisory at f31f4e8.
- Why it matters: `:s/.*/&&&&&&&&/`, or a replacement grown by `~` to 1 MiB of `&`, on a long line of an untrusted file (up to 64 MiB) builds replacement bytes times match length in one piece before the budget stops it, which can exhaust memory and lose unsaved buffers, against the comment's output bound.
- Fix outline: charge each group's and literal's bytes as the expansion grows and stop once the budget runs out, with a `test/domain_substitute.rb` row for a large `&` count on a long line, and say bytes in the comment. Queued in `substitute-tidy`.

## SubstituteArgs repeats the ex range number reader and the letter test

- Where: `carat/domain/substitute_args.rb` line 86 (`MAX_COUNT`), repeating `ExRange.line_number` (`carat/domain/ex_range.rb` line 73, `MAX_NUMBER`), and line 46, repeating `ExGrammar.letter?`. Periodic quality advisory at f31f4e8.
- Why it matters: two copies of one limit and one test in one domain drift apart when either changes.
- Fix outline: one capped number reader and one letter predicate in the domain, called from both. Queued in `substitute-structure`.

## dev-build's code key changes with test/ and bench/

- Where: `code_key` in `tools/run_state.sh` (line 156 at f31f4e8), which hashes `test/` and `bench/` for every compile stage. Periodic quality advisory at f31f4e8.
- Why it matters: a test-only commit on main changes the key of `dev-build`, which compiles only `bin/carat.rb`, so the next change compiles again where it could skip.
- Fix outline: a per-stage key that leaves `test/` and `bench/` out of `dev-build`'s, with a `tools/tools_test.sh` case. Queued in `check-skip`.

## The close profile records a phase for any change and commit

- Where: the `close` profile of `tools/agent_guard.sh` (line 538 at f31f4e8) and `phase` in `tools/run_state.sh`. Periodic security Low (3) at f31f4e8.
- Why it matters: the profile records phase plan, implement, package, ci, merge, retro, or report for any change name and commit, so a retrospective steered by text it reads could write `phase.implement` for another queued change and make that change's resumed run skip planning and implementation; no merge gate reads these phases.
- Fix outline: limit the closing records to the run's own change and merged commit, or refuse a plan or implement phase from the close path, with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## Every agent start receives all of CLAUDE.md

- Where: every agent of `.claude/agents/`, the readers that never edit included; the harness injects `CLAUDE.md` (30,534 bytes) into each custom agent's start, and no frontmatter setting of an agent file leaves it out. Found by `agent-inputs`.
- Why it matters: input dominates a run's tokens (1.0M to 1.6M total against 0.24M to 0.40M output), and a run starts about ten agents, the checker, merger, and benchmark reading rules they never apply.
- Fix outline: cut `CLAUDE.md` to the rules every agent needs, moving the rest to the agent files, the map, or the notes, within the 27,648 bytes `docs-currency` set; if the harness gains a setting that leaves it out of an agent, use it for the agents that never edit. Queued in `docs-index` (queue item 29), since `docs-currency` is archived.

## The docs_lint budget comment has a sentence with no subject

- Where: the comment above `BUDGETS` in `tools/docs_lint.sh` (line 40 at 3a4db08), which reads "The queue's holds what the planner rewrites". Quality advisory of `agent-inputs`.
- Why it matters: the sentence drops its noun, so a reader raising or checking the queue's budget has to guess what it bounds.
- Fix outline: write "The queue's budget bounds what the planner rewrites and every agent may read at a start." Queued in `phase-shares`.

## The queue budget test writes its filler twice

- Where: the `queuesize` case of `tools/tools_test.sh` (line 1061 at 3a4db08), whose first `head -c 17369 /dev/zero` is cut again by a second `head -c` that sets the length. Quality advisory of `agent-inputs`.
- Why it matters: the redundant stage makes the one length that matters harder to read and to change with the budget.
- Fix outline: `head -c "$((17369 - $(wc -c < docs/queue.md)))" /dev/zero | tr '\0' x >> docs/queue.md`. Queued in `phase-shares`.

## The scout's step 8 says every Rules line names sections

- Where: step 8 of `.claude/agents/scout.md` (line 38 at 3a4db08); the Rules lines of areas 6, 9, 10, 13, and 16 of `docs/codebase-map.md` name no `CLAUDE.md` or `docs/architecture.md` section. Quality advisory of `agent-inputs`.
- Why it matters: a scout on one of those areas finds no section to point the contributor to and may open the files step 8 tells it not to.
- Fix outline: say "the sections it names, if any", or drop the clause. Queued in `phase-shares`.

## The ex commands a global most often runs besides :s and :d

- Where: `carat/use_cases/ex/` and `docs/compatibility.md` Global; `buffer-global` brought `:g`, `:v`, and `:d` without `:m`, `:t`, `:normal`, and `:p`, which `docs/architecture.md` section 5.2 lists with them.
- Why it matters: `:g/x/m0` (reverse the matching lines), `:g/x/t$` (copy them to the end), and `:g/x/normal Ax` are common globals, and they answer E492 today.
- Fix outline: add each as an `ExHandler` with its use case over `Buffer#set_lines`, registered in Vim's order, with rows in `docs/compatibility.md` and `test/editor_global.rb`; `:m` and `:t` share `ExRange` for their destination address, and `:normal` feeds keys through `HandleKey` inside the global's transaction. Queued in the backlog-items change of `docs/queue.md`.

## :d and :s each compute a count's range

- Where: `DeleteCommandHandler#call` in `carat/use_cases/ex/delete_command_handler.rb` (line 42 at 76fa78b) and `SubstituteLines#call` in `carat/use_cases/search/substitute_lines.rb` (lines 66 to 70). Quality advisory of `buffer-global`.
- Why it matters: both turn a count into a range the same way (the first line becomes the last, the last moves count minus one lines down, clamped to the buffer's last line), so a fix to one, such as Vim's handling of a count past the end, can miss the other.
- Fix outline: one domain helper, for example on `ExRange`'s result, that takes the range, the count, and the line count and returns the new first and last, called by both. Queued in `global-tidy`.

## RegisterCount and SubstituteArgs each read a count

- Where: `RegisterCount.parse` in `carat/domain/register_count.rb` (line 38 at 76fa78b: the digit loop, `MAX_COUNT`, `digit?`, and the blank skipping) and `SubstituteArgs.tail` and `SubstituteArgs.digit?` in `carat/domain/substitute_args.rb`. Quality advisory of `buffer-global`.
- Why it matters: the two readers of an ex count, its cap, and the blanks around it can drift, so `:d 5` and `:s/a/b/ 5` could disagree on what Vim reads the same way.
- Fix outline: share one domain count reader (the count, where it ended, and an error) between `RegisterCount` and `SubstituteArgs`. Queued in `global-tidy`.

## RegisterCount re-encodes the writable register names

- Where: `RegisterCount.writable?` in `carat/domain/register_count.rb` (line 71 at 76fa78b). Quality advisory of `buffer-global`.
- Why it matters: it lists again the names `Registers.valid_name?` and `Registers.read_only?` already define, so a register added there would be refused by `:d x` until this copy is updated.
- Fix outline: return `Registers.valid_name?(c) && !Registers.read_only?(c)`; the digits are already excluded before the call. Queued in `global-tidy`.

## GlobalMarks#active? is used only by its test

- Where: `GlobalMarks#active?` in `carat/domain/global_marks.rb` (line 25 at 76fa78b), called only by `test/domain_global.rb`. Quality advisory of `buffer-global`.
- Why it matters: dead code in the domain reads as behavior the editor relies on, and its test lines check nothing the editor does.
- Fix outline: use it in `shift` (`return unless active?`), which also skips the work on every splice outside a global, or drop it and its test lines. Queued in `global-tidy`.

## No test runs a global after one stopped by a failing command

- Where: the `ensure` of `GlobalCommand#call` in `carat/use_cases/search/global_command.rb` (line 176 at 76fa78b), which resets `@busy` and clears the marks on the early return. Quality advisory of `buffer-global`.
- Why it matters: if Spinel skipped the `ensure` on that return, every later global would answer `E147` as if it ran inside a global, and no test would notice.
- Fix outline: add a row to `test/editor_global.rb` such as `:g/a/foo` followed by `:2g/a/d`, expecting the delete and not `E147`. Queued in `global-tidy`.

## The architecture omits the global marks from the splice

- Where: `docs/architecture.md` section 4.1 (line 146 at 76fa78b), which says every splice moves the sign layers through `LineSplice.shift_marks`. Quality advisory of `buffer-global`.
- Why it matters: the splice now moves the buffer's `GlobalMarks` too, so a reader of the section misses why a global finds its marked lines after an edit moved them.
- Fix outline: name the global marks beside the sign layers in that sentence. Queued in `global-tidy`.

## GlobalArgs restates the delimiter rules DelimitedPattern owns

- Where: the class comment of `GlobalArgs` in `carat/domain/global_args.rb` (line 5 at 76fa78b). Quality advisory of `buffer-global`.
- Why it matters: the comment restates the delimiter rules (any ASCII character but a letter, where the pattern ends) that `DelimitedPattern` now owns, so the prose can drift from the code as the two parsers could before.
- Fix outline: say the pattern and the command are read by `DelimitedPattern` and drop the restated rules; `SubstituteArgs` keeps only the characters it excludes before the call. Queued in `global-tidy`.

## A security review after a quality-only fix reads the whole branch again

- Where: the security review phase of `.claude/workflows/deliver-change.js` after a fix round, which reviews the whole branch whatever the fix touched. Retrospective proposal of `buffer-global`.
- Why it matters: in `buffer-global` a quality-only fix that moved parser code into one domain reader got a second full security review that found 0 again; reviews took 60,085 of 244,038 output tokens (24.6%) and 56 calls over two rounds, and 87,179 of 403,796 (21.6%) in `buffer-substitute` with rework 2.
- Fix outline: after a fix round, the security review covers only the fix diff unless the fix touches an input path (config loading, file access, plugin boundaries, terminal output, process spawning, the entry point, the guard and gates), recorded with its range, with a case in the workflow's tests. Queued in `implement-contracts`.

## check_lost and check_wait re-read the run state and the pid file inline

- Where: `tools/run_state.sh` line 485 (`check_lost` greps and seds the state file, duplicating `keys_under` at line 937) and line 517 (`check_wait` reads the pid file although `read_pid` at line 569 does, and the lost-runner path removes it twice, lines 530 and 533). Quality advisories of `pipeline-durability`.
- Why it matters: two readers of the state file format and the pid file can drift apart, and the double removal hides which branch owns the cleanup.
- Fix outline: take the first `stage.*` entry whose value starts with `running` from `keys_under stage.`; call `read_pid` in `check_wait` and drop the `rm` in its `elif` branch.

## An interrupted stage is recorded at the runner's head, not its start commit

- Where: `tools/run_state.sh` line 476 (`check_signalled` writes the stage record with `$head`, while `run_stage` writes each stage at the commit it started on). Quality advisory of `pipeline-durability`.
- Why it matters: the two writers of a stage record can disagree when HEAD moved between stages, so a killed stage can be attributed to a commit it never ran on.
- Fix outline: keep the stage's `at` in a global beside `running_stage` and write the killed record with it.

## The checker reports a check's outcome both as passed and as a verdict

- Where: `.claude/workflows/deliver-change.js` line 107 (the `CHECK` schema still requires `passed` and offers `failed_stage`, which `rounds()` no longer reads) and step 5 of `.claude/agents/checker.md`. Quality advisory of `pipeline-durability`.
- Why it matters: one fact reported two ways can disagree, and the workflow routes only by the verdict.
- Fix outline: drop `failed_stage` and `passed` from `CHECK` and checker step 5's passed-or-not, keeping `verdict` as the one answer.

## The workflow's verdict parsing has no test case

- Where: `tools/tools_test.sh` line 295 covers the routing only by grepping the `RERUN_WORDS` source line of `.claude/workflows/deliver-change.js`; `checkVerdict`'s parsing (the `run_state:` prefix, a refusal, a verdict at another commit) has no case. Quality advisory of `pipeline-durability`.
- Why it matters: a change to the verdict regexes could misroute a killed or superseded check into a fix round, or a failure into a rerun, without a test failing.
- Fix outline: extract the verdict regexes into a contract the shell test feeds sample verdict lines through.

## The run state's writer has no lock beside the detached check runner

- Where: `tools/run_state.sh` line 280 (`write_key`, a read-modify-rename with no lock, and `drop_key`), written by the detached runner (`check_run`, `run_stage` at a stage's start and end) while the checker's metric line on a rerun and `check_lost` in the waiter also write. Periodic quality advisory at eb0f1be.
- Why it matters: two writers at once can drop each other's key, so the run state forgets a stage record, a metric, or a phase, and a resume or gate acts on a wrong picture.
- Fix outline: take a lock around `write_key` and `drop_key` (a lock directory with retry, or `flock` where present), or have the runner write stage records only to its own file that `check` reads. Queued in `check-runner-safety`.

## A lost check runner leaves its make running while a second one starts

- Where: `tools/run_state.sh` line 530 (`check_lost` records the stage as killed but leaves the stage's make and compilers in the dead runner's process group) and line 517 (the superseded branch starts a new runner when the old one has not stopped after 150 pauses). Periodic quality advisory at eb0f1be.
- Why it matters: two builds write the same `build/` directories at once, so a stage can pass or fail on the other runner's output.
- Fix outline: stop the dead runner's process group in `check_lost`, and refuse or wait instead of starting a second runner while the old one is alive. Queued in `check-runner-safety`.

## A detached check runner outlives a stopped run and shares build/

- Where: `tools/run_state.sh` line 536 (the runner of one change keeps running after its run stops, and a check of another change builds into the same `build/`). Security Low (4) of the periodic review at eb0f1be.
- Why it matters: a stale runner can overwrite another change's build outputs or stage records, so a check passes on code it did not build.
- Fix outline: one check pid file for every change, so a new check stops any live runner, and record the stage as superseded when the tracked tree (git status or a tree hash), not only HEAD, changed while it ran. Queued in `check-runner-safety`.

## The check verdict is read from a log read agents can write

- Where: `tools/run_state.sh` line 439 (the verdict is the last line of `build/stages/CHANGE/check.log`, inside the redirect-writable `build/stages/`). Security Low (3) of the periodic review at eb0f1be.
- Why it matters: a read-profile agent can append a forged pass line so `check` exits 0; the stages gates still need the records, which limits it.
- Fix outline: keep `check.log` and `check.pid` outside `build/stages/`, or derive the verdict from the run state's stage records. Queued in `check-runner-safety`.

## A rollback during :g leaves the global marks on the wrong rows

- Where: `carat/domain/buffer.rb` line 611 at 847851d (`revert_to` undoes records with `LineSplice.apply` and shifts the signs and the syntax cache but not `global_marks`, unlike `splice`'s shift at line 647). Periodic quality advisory at eb0f1be.
- Why it matters: a plugin edit rolled back while a `:g` runs leaves the marks on rows the command never matched, so the global runs its command on the wrong lines.
- Fix outline: shift `global_marks` beside the other two shifts in `revert_to` and add a `test/domain_global.rb` row. Queued in `global-tidy`.

## The secret patterns miss unquoted assignments and unlisted token shapes

- Where: `tools/rules.sh` (`ASSIGN_RE` takes only a quoted literal; `TOKEN_RE` lists the shapes of AWS, GitHub, GitLab, Slack, Google API, `sk-` keys, Stripe live, and npm). Limit accepted by `backup-secret-scan`.
- Why it matters: `password = hunter2hunter2` in a YAML or shell file, or a token of another platform, reaches the backup ref and the branch; the security review still reads the diff before the push, but not before the backup.
- Fix outline: add a shape when a platform the project uses appears, and refuse an unquoted assignment in configuration files only (`*.yml`, `*.toml`, `*.sh`, `.caratrc`), where ordinary code does not assign `token = name`, each with a `tools/tools_test.sh` case. Queued in `content-gate-gaps`.

## The content gate skips files git treats as binary

- Where: `tools/gates.sh` line 126 (`gate_content` reads `git log -p`, which prints no lines for a file with a NUL byte or one `.gitattributes` marks `-diff` or `binary`, and the merge gates run from the branch's checkout, so the branch can set them). Security Low (6) of `backup-secret-scan`; raised to periodic security Medium (7) at b0dd342 (`tools/gates.sh` line 179).
- Why it matters: a committed secret in such a file passes the secret, URL, email, and model checks.
- Fix outline: pass `--text` and `--no-textconv` to the `git log -p` scan, or refuse an added binary file and a `.gitattributes` change setting `diff`, `binary`, or `textconv` unless a reviewer allows it, with a `tools/tools_test.sh` case. Queued in `content-gate-gaps`.

## The URL, email, and session checks print the whole matching line

- Where: `tools/rules.sh` line 34 (`scan` prints each hit's full line for the URL, email, and session checks, while the secret checks print a label only). Security Low (5) of `backup-secret-scan`.
- Why it matters: a credential inside a URL (a token before the host) appears in the gate output, the stage logs, and CI.
- Fix outline: mask whatever matches `KEY_RE`, `TOKEN_RE`, or `ASSIGN_RE` with `[secret]` (a sed replacement) before printing any hit, with a `tools/tools_test.sh` case.

## The close note names the backup when there was none

- Where: `.claude/workflows/deliver-change.js` line 718 (the close note says the backup stays on origin whenever a run stops unmerged, even after the push deleted it or when no backup was made). Quality advisory of `backup-secret-scan`.
- Why it matters: the report sends the user to `abandon` a backup that does not exist.
- Fix outline: also require `state.backup`, the record `backup_branch` writes and `drop_backup` drops. Queued in `backup-records`.

## Recording merged deletes refs on origin from the generic key writer

- Where: `tools/run_state.sh` line 1344 (`set CHANGE merged` pushes a ref deletion to origin, a network side effect hidden in the plain key writer beside the `push` and `abandon` paths). Quality advisory of `backup-secret-scan`.
- Why it matters: a reader of `set` does not expect a push, and a failed deletion surfaces in a step that only records.
- Fix outline: keep `set` a plain write and have the merger call `abandon` (or a `merged` command) explicitly after recording `merged`.

## The backup's kept base and a failed backup deletion have no case

- Where: `tools/tools_test.sh` line 443 (`branch_base` says a later merge of `origin/main` keeps the base, and `drop_backup` reports a failed deletion, but neither path is tested). Quality advisory of `backup-secret-scan`.
- Why it matters: a regression in either path passes `make tools-test`, and a wrong base lets the gates read too much or too little of the branch.
- Fix outline: add a backup after merging a new main commit (the base unchanged) and a `drop_backup` against an unreachable origin (exit 1, the message naming `abandon`).

## drop_backup joins the ref names by unquoted word splitting

- Where: `tools/run_state.sh` line 716 (`$(echo $refs)` outside the line the SC2086 disable covers). Quality advisory of `backup-secret-scan`.
- Why it matters: a glob character in a ref name would expand against the working directory, and the disable comment hides the intent.
- Fix outline: print the names with `printf '%s ' $refs` under the disable, or `tr '\n' ' '`.

## The content gate reads an added line starting with ++ as a path header

- Where: `tools/gates.sh` line 127 (an added line whose text starts with `++ ` shows as `+++ ` in the diff and is taken for a path header, so the content gate never scans it). Periodic security Low (8) at d386c74.
- Why it matters: a secret, URL, email address, or model name on such a line passes the gate into a public branch.
- Fix outline: treat `+++ ` as a header only between a `diff --git` line and the first `@@` hunk line, with a `tools/tools_test.sh` case. Queued in `content-gate-gaps`.

## The .env check misses a path git quotes

- Where: `tools/gates.sh` line 129 (git quotes a path with a non-ASCII or special byte, as `"\303\251/.env"`, so the `.env` match fails on an added `.env` under such a directory). Periodic security Low (7) at d386c74.
- Why it matters: an `.env` file with secrets reaches the branch unrefused.
- Fix outline: list names with `git -c core.quotePath=false` and `-z` (or unquote them) before matching, with a `tools/tools_test.sh` case. Queued in `content-gate-gaps`.

## No case covers a secret only in a merge resolution

- Where: `tools/gates.sh` line 126 (the content gate scans with `-m` so a merge's resolution is read) and `tools/tools_test.sh` lines 1324 to 1351 (every secret case is a linear commit). Periodic quality advisory at d386c74.
- Why it matters: dropping `-m` would let a secret introduced while resolving a merge pass `make tools-test`.
- Fix outline: add a case where the secret appears only in a merge commit's resolution and the gate refuses it. Queued in `content-gate-gaps`.

## abandon reports no backup left when origin is unreachable

- Where: `tools/run_state.sh` line 708 (`drop_backup` ignores a failed `git ls-remote`, the pipeline's status being awk's) and line 1352 (`abandon` then prints that no backup of the branch is left on origin). Periodic quality blocking at d386c74.
- Why it matters: with origin unreachable the record is dropped and the user is told nothing is left, while refs holding unreviewed commits may stay on the public origin.
- Fix outline: take `ls-remote`'s output and status separately; on failure keep the record, return 1, and name `abandon` in the message, with a `tools/tools_test.sh` case against an unreachable origin. Queued in `backup-records`.

## The backup's base record outlives the backup

- Where: `tools/run_state.sh` line 753 (`backup` writes `base` before the gates and the push) and line 718 (`drop_backup` drops only `backup`). Periodic quality advisory at d386c74.
- Why it matters: `base` survives a refused backup, the push, the merge, and `abandon`, naming a ref that no longer exists.
- Fix outline: write `base` after the push succeeds and drop it beside `backup`. Queued in `backup-records`.

## The backup runs the branch's own gates

- Where: `tools/run_state.sh` line 754 (`backup` runs the branch's `tools/gates.sh` and `tools/rules.sh`, which the run may have edited before any review). Periodic security Low (5) at d386c74.
- Why it matters: a weakened secret pattern on the branch lets a secret reach the backup ref unchecked.
- Fix outline: run the backup gates from a worktree of `origin/main`, as the merge gates do, with the base and change passed in. Queued in `backup-records`.

## A refused backup push is retried and protects nothing here

- Where: the backup step of `.claude/workflows/deliver-change.js` and `backup` in `tools/run_state.sh`; this environment's git proxy refuses a push to `refs/backup/` with HTTP 403. Retrospective proposal of `backup-secret-scan`, recorded here by the user's decision rather than queued.
- Why it matters: in `backup-secret-scan` 2 of 2 backup pushes were refused and 0 backup refs reached origin, so the step spent tokens and changed no decision, and the run state holds no backup record to tell the report so; `docs-currency` made 7 more attempts, and 0 of 9 across the two runs reached origin (its retrospective); in `buffer-list` the implement and fix pushes all failed, 0 `refs/backup` refs reached origin, and 7 commits stayed local until the package push (retrospective note 11); in `leader-layout` 2 of 2 backup tries were refused (retrospective note 8), so no backup has reached origin in four runs; in `lsp-diagnostics` 8 attempts over 3 contributor starts were refused and no `refs/backup` ref reached origin (retrospective note 18), and in `diagnostics-display` all 6 implement commits and 3 more tries were refused, no restore being used; the first backup of `partial-results` was refused the same way; in `check-isolation` 3 of 3 backup pushes were refused, and 7 runs' retrospectives have recorded the same proposal. Kept here by the user's earlier decision, which the user may want to revisit; queued in `backup-records`.
- Fix outline: record a refused backup push once in the run state, make no later backup attempt in that run, and have the report say no backup exists, with a `tools/tools_test.sh` case for a refused push.

## Pull requests are created with a session-link footer the settings turn off

- Where: step 4 of the package step in `.claude/agents/contributor.md`, which opens the pull request with the GitHub tools, and its step 5 removal edit; `.claude/settings.json` sets the attribution `pr` empty and `sessionUrl` false. Retrospective proposal of `leader-layout`.
- Why it matters: 10 of 53 run states record a pull request created with a footer holding a session link (pull requests 57 to 60, 64, 73, 76, 77, and 81) despite main's attribution settings, each needing a removal edit; the edit history keeps the link, against the hard rule that no session URL appears in GitHub activity. The footer is added by the pull request tool outside the repository, so no repository change has prevented it.
- Fix outline: a merge-gate acceptance check that refuses a pull request body or squash message holding a session link, beside the package step's immediate removal edit (step 5), each removal reported. The main session concluded at `feedback` that the footer cannot be fixed from the repository (it reached 10 of 53 pull requests with main's attribution settings on), so only the package step's removal remains; the entry stays here, out of the queue, until a repository-side cause is found.

## The roadmap's progress is readable nowhere in one place

- Where: the Status line of `CLAUDE.md` (line 9), which since `docs-currency` points to `docs/architecture.md` section 12, and section 12, which marks only items 4, 5, 7, 8, and 12 as delivered. Quality advisory of `docs-currency` at 19e41a9.
- Why it matters: items 1, 2, 3, 6 (but `:g` and `:v`), 11, and the configuration files of 9 are done too, so an agent planning from section 12 sees less progress than there is, and the short list that said so left `CLAUDE.md`.
- Fix outline: mark each delivered item, and the delivered half of 6, 7, 9, and 12, in section 12, or restore the short item list to the Status line.

## Section 11 names only some of the documents and no agent or CI directory

- Where: the tree of `docs/architecture.md` section 11 (its `docs/` line near line 398), now the stated home of the layout detail `CLAUDE.md` dropped in `docs-currency`. Quality advisory at 13473da.
- Why it matters: its `docs/` line names 4 of the 12 documents, one of them, `plugin-protocol.md`, not yet written, and the tree omits `.claude/`, `.github/`, and `dist/`, so neither file lists where the documents, the agents, and CI live.
- Fix outline: list the documents and the `.claude/`, `.github/`, and `dist/` directories in the tree, or have the Layout section of `CLAUDE.md` point to the map for `docs/`.

## The run_state.sh bullet reads as if it listed every command

- Where: the Commands bullet of `sh tools/run_state.sh` in `CLAUDE.md` (line 231), "every command in the script's header:" followed by seven commands. Quality advisory of `docs-currency` at 13473da.
- Why it matters: a reader takes the seven for the whole set and misses `scope`, `bench`, `usage`, `plan-needed`, and the others the header lists.
- Fix outline: reword it to "a change's run state, every command listed in the script's header; those an agent acts on:" before the list, within the file's budget.

## The explorer's tokenize walks bytes to find an icon column it already knows

- Where: `tokenize` in `carat/plugins/explorer/plugin.rb` (line 143 at `theme-tokens`), which re-decodes the marker's UTF-8 length with a nested ternary and counts spaces to find the icon's column.
- Why it matters: the plugin already knows the column when it builds the line (1 + 2 * depth), so the byte walk is cleverness the task did not need and a second place to change when the line's layout does.
- Fix outline: record the icon column beside the group in `tree_lines` (or take it from `Tree`'s depth) and drop the byte walk.

## The explorer's token table is keyed by whole tree lines

- Where: `tokenize` and the `@line_groups` table in `carat/plugins/explorer/plugin.rb` (lines 139 and 467 at `theme-tokens`), rebuilt by `tree_lines` on every refresh. Periodic quality at 4c65f4e.
- Why it matters: a line's tokens depend on plugin state instead of the line, though every icon the tree draws has its own glyph in each icon set, so the table is state the plugin need not keep.
- Fix outline: build a glyph-to-group table once in `activate` from `host.icon` and `FileIcons::GROUPS`, look up the glyph at the icon column in `tokenize`, and drop `@line_groups` and `tree_lines`, together with the byte-walk entry above it. Queued in `theme-tidy`.

## Themes.palette repeats NAMES as an if chain

- Where: `palette(key)` in `carat/domain/themes.rb` (line 363 at `theme-tokens`).
- Why it matters: a new palette must be added both to `NAMES` and to the chain, and forgetting the chain silently falls back to the default.
- Fix outline: one `PALETTES` hash of name to rows, with `NAMES = PALETTES.keys` and `palette` a lookup with `ONE_DARK` as its fallback.

## from_palette leaves the 256-color background and foreground when the terminal paints

- Where: `from_palette` in `carat/domain/themes.rb` (line 386 at `theme-tokens`).
- Why it matters: without a painted background it clears the 24-bit and 16-color values of `BG` and `FG` but not `indexes256`; it is harmless only because every palette gives -1 there and `SgrTable.color` returns early on a negative color, so a palette giving its own index would paint the background at 256 colors.
- Fix outline: also set `indexes256[BG]` and `indexes256[FG]` to -1.

## The background option's values are bare literals

- Where: `Options#initialize` in `carat/domain/options.rb` (line 45 at `theme-tokens`), `Themes.find` (`"theme"`), and `BACKGROUNDS` in `carat/domain/themes.rb`, while the theme's default is `Themes::DEFAULT`.
- Why it matters: the default and the painted value are spelled in three places, so renaming or adding a value can leave one behind.
- Fix outline: add `Themes::DEFAULT_BACKGROUND` and a `PAINTED` constant and use them in `Options#initialize` and `Themes.find`.

## The screen presenter's first painted row test accepts two outputs

- Where: `test/adapters_screen_presenter.rb` (line 318 at `theme-tokens`), whose assertion joins two expected sequences with `||`.
- Why it matters: the test does not pin what the presenter writes for the first painted row, so a regression to the other sequence passes.
- Fix outline: assert the one exact sequence the snapshot shows.

## The theme test lists the palettes a second time

- Where: `PALETTES` in `test/domain_theme.rb` (line 11 at `theme-tokens`), which repeats `D::Themes::NAMES`.
- Why it matters: a fifth palette would escape the contrast and coverage checks.
- Fix outline: iterate `D::Themes::NAMES`.

## Themes misses a blank line and a comment near known?

- Where: `carat/domain/themes.rb` (line 332 at `theme-tokens`): no blank line between the `LIGHT_PLUS` table and the `known?` comment, and `background?` has no comment unlike its neighbours.
- Why it matters: the file's layout is otherwise consistent, and the missing comment leaves `background?`'s meaning to its body.
- Fix outline: add the blank line and a one-line comment above `background?`.

## The architecture gives the plugin API as 2.0

- Where: the plugin API version sentence of `docs/architecture.md` (line 321 at `theme-tokens`) and its `syntax_group` and `tokenize` bullets near lines 295 to 296, while `carat/plugin_api.rb` (line 12) and `docs/plugins.md` (line 23) give 2.3 at 803fe6e. Periodic quality at 4c65f4e and 803fe6e. Raised again at 38628bb (periodic quality). Queued in `architecture-drift`.
- Why it matters: the binding architecture lists changes only through 1.3 and misses 2.1's file-icon groups in `syntax_group` and tokens and a scratch buffer's syntax named after its plugin, 2.2's `set_segment` and `PluginApi::FileIcons`, and 2.3's floats (`open_float`, `move_float`, `close_float`, `FloatOptions`), so a plugin author reading it targets an older API.
- Fix outline: say 2.3 and add the 2.1, 2.2, and 2.3 additions to the version sentence and to the `syntax_group`, `tokenize`, and window request bullets, within the file's budget.

## Operate and RepeatLast each copy EditorState#clamp_col

- Where: the private `clamp(state, row, col)` in `carat/use_cases/operate.rb` (line 202 at `theme-tokens`) and `carat/use_cases/repeat_last.rb` (line 117), each `EditorState#clamp_col` in `carat/domain/editor_state.rb` (line 94) line for line. Periodic quality at 4c65f4e.
- Why it matters: three copies of one clamp must change together, and a fix to the domain's misses the two use cases.
- Fix outline: call `state.clamp_col(row, col)` at the six call sites and delete both private methods. Listed in the queue's backlog item.

## NO_COLOR leaves syntax, bars, and messages colored

- Where: `TerminalPort#no_color?` (`carat/ports/terminal_port.rb`), read by `EditorAssembly#open` for the start screen's glyphs (`start-screen`) and, through `FramePresenter#plain=` (`carat/adapters/editor_assembly.rb` line 489 at 5e4c140), for the ASCII notification boxes and progress, the plain status bar, and the uncolored documentation floats and pinned split (`quick-docs-styles`); `SgrTable.from_theme` and `ScreenPresenter` color every other cell from the theme.
- Why it matters: the `NO_COLOR` convention asks a program to add no ANSI color at all, so a user who sets it still gets syntax, status line, and message colors.
- Fix outline: a color depth of none in `Domain::ColorDepth` chosen by `AnsiTerminal` when `NO_COLOR` is set, for which `SgrTable.sequence` emits attributes only (bold, reverse, underline), with rows in `test/adapters_screen_presenter.rb` and `docs/compatibility.md`.

## FramePresenter clears the layout twice for the hit-enter prompt and the start screen

- Where: the `if start` block of `carat/adapters/frame_presenter.rb` (line 201 at `start-screen`), which repeats the `if listed` block's `back.layout.clear` and `@back_rows.invalidate` line for line. Quality review of `start-screen`.
- Why it matters: two copies of the full-repaint step must change together, and a fix to one misses the other.
- Fix outline: clear the layout and invalidate the rows once under `if listed || start`, and keep only the two cursor lines under `if listed`.

## InputController calls handle twice in pump and checks animating? twice in tick

- Where: `pump` in `carat/adapters/input_controller.rb` (line 62 at `start-screen`) calls `handle(state, @decoder.feed(bytes))` in two branches, and `tick` (line 96) checks `animating?`, which `due?` checks again. Quality review of `start-screen`.
- Why it matters: the duplicated call and guard are more code to keep in step on the per-key path.
- Fix outline: set `shown = @start_screen.showing`, dismiss, then `return handle(...) || shown`, and drop `tick`'s `animating?` guard.

## StartArt#paint clamps a step no caller passes out of range

- Where: the two clamp lines of `paint` in `carat/domain/start_art.rb` (line 167 at `start-screen`); `StartScreen` only ever holds a step in 0..LAST. Quality review of `start-screen`.
- Why it matters: defensive code no caller needs hides the invariant `StartScreen` keeps.
- Fix outline: drop the two clamp lines.

## StartArt.from_plain bends the from_x naming

- Where: `StartArt.from_plain(bool)` in `carat/domain/start_art.rb` (line 73 at `start-screen`), while the archived change's `design.md` and task 3.1 call it `StartArt.build(plain)`. Quality review of `start-screen`.
- Why it matters: `from_x` names a conversion from an x value, and a flag is not one, so the name misleads and the design record disagrees with the code.
- Fix outline: rename it to `build(plain)` at its call sites and tests.

## No test reads NO_COLOR through AnsiTerminal

- Where: the `NO_COLOR` read in `carat/drivers/ansi_terminal.rb` (line 24 at `start-screen`); the start screen tests set only the `FakeTerminal` writer. Quality review of `start-screen`.
- Why it matters: a regression in the driver's read would show the colored glyphs to a user who set `NO_COLOR` with every test still passing.
- Fix outline: a `test/smoke_editor.rb` session spawned with `NO_COLOR=1` asserting the output holds no U+25E2 and still shows the hints.

## ExtendVisual keeps a private tabstop_of with no caller

- Where: the private `tabstop_of` of `carat/use_cases/visual/extend_visual.rb` (line 53 at `start-screen`), uncalled since #30 split the visual use cases. Periodic quality at 5ac9674.
- Why it matters: dead code a reader must check before trusting the class's tab handling, and a second place a tab rule could drift.
- Fix outline: delete the method.

## DisplayWidth.of_char has no caller

- Where: `DisplayWidth.of_char` in `carat/domain/display_width.rb` (line 37 at `start-screen`), called nowhere in `carat/`, `bin/`, `test/`, or `bench/`, yet named as a key method on the map's `display_width.rb` line. Periodic quality at 5ac9674.
- Why it matters: the map points readers at a method nothing uses, and it can drift from the width rule the callers rely on.
- Fix outline: delete it and drop it from the map's line.

## The architecture's InputController and FramePresenter bullets omit the start screen

- Where: the binding `InputController` and `FramePresenter` bullets of `docs/architecture.md` (lines 247 and 252 at `start-screen`); only the `TerminalPort` row (line 198) was updated. Periodic quality at 5ac9674.
- Why it matters: the controller now shortens its read timeout for the next frame, advances the start screen in `tick`, and dismisses it on a key, and the presenter paints `StartArt` over the current window and repaints every row after it, none of which the binding document says.
- Fix outline: one clause in each bullet, within the file's budget.

## StartArt's LAST restates FRAMES - 1

- Where: `LAST = 5` in `carat/domain/start_art.rb` (line 105 at `start-screen`), which `StartScreen`, `paint`, and `from_plain` rely on beside `FRAMES`. Periodic quality at 5ac9674.
- Why it matters: two constants to keep in step; a frame added to one and not the other paints past the table or never shows the last frame.
- Fix outline: derive `LAST` from `FRAMES`.

## StartArt's LEGEND and PLAIN_GLYPHS spell characters as decimal codes

- Where: `LEGEND` and `PLAIN_GLYPHS` in `carat/domain/start_art.rb` (line 130 at `start-screen`), arrays of byte codes such as 47 and 92, while `GEM` is strings read with `getbyte`. Periodic quality at 5ac9674.
- Why it matters: the legend the `GEM` comment describes cannot be read against the table, so a glyph change is checked by decoding numbers.
- Fix outline: hold both as strings read with `getbyte`, as `GEM` is.

## The gates header says pre-push runs static

- Where: the mode list at the top of `tools/gates.sh` (line 41 at `package-clean`), which says pre-push is static, security, stages. Quality advisory of `package-clean`. At 38628bb the header still omits that `gate_attribution` is left out of the pre-push group (`tools/gates.sh` line 455, periodic quality). Queued in `merge-gate-tidy`.
- Why it matters: static now adds the attribution gate, which pre-push deliberately leaves out (the gates stage runs it), so a reader trusting the header expects a check the push never makes.
- Fix outline: list pre-push as origin, trailer, content, snapshots, docs, scenarios, cases, security, stages, noting attribution runs through the gates stage.

## The spec preview of a failed change is deleted by the next change's

- Where: the loop over `openspec/changes/` in `tools/spec_validate.sh` (line 25 at `package-clean`), which empties `build/spec-preview` for each active change while the header and the failure message promise a failed preview is kept. Quality advisory of `package-clean`.
- Why it matters: with two active changes, the first one's failed preview is gone before anyone reads it, so the message points at a directory holding the wrong change.
- Fix outline: preview each change under `build/spec-preview/<name>`, or stop after the first failure.

## The spec preview copies symbolic links under openspec/

- Where: the copy of `openspec/` in `tools/spec_validate.sh` (line 26 at `explorer-folder-toggle`), with `cp -R`, which keeps symbolic links. Periodic security Low (3) at 3a99ddd.
- Why it matters: the archive run in `build/spec-preview` writes a merged spec through a link a branch commits under `openspec/specs/` to a file outside the preview.
- Fix outline: refuse a symbolic link under `openspec/` before the copy, or copy with links followed, with a `tools/tools_test.sh` case. Batched with the entry "The spec preview of a failed change is deleted by the next change's" in queue item 41.

## The contributor's implement step validates the change twice

- Where: implement steps 2 and 6 of `.claude/agents/contributor.md` (line 34 at `package-clean`), which run `openspec validate <change> --strict` and then `make spec-validate`, whose `validate --all --strict` already covers the change. Quality advisory of `package-clean`.
- Why it matters: two ways to do one check cost a tool call each run and can drift apart.
- Fix outline: keep only `make spec-validate`.

## The attribution gate matches its values anywhere in the settings file

- Where: `gate_attribution` in `tools/gates.sh` (line 336 at `package-clean`), which greps the three values as fixed strings over the whole of `.claude/settings.json`. Quality advisory of `package-clean`.
- Why it matters: a matching `pr` or `sessionUrl` line outside the attribution object passes while the attribution object itself could still allow pull request text or a session link.
- Fix outline: cut the attribution block by its lines (a sed range from the attribution line to its closing brace) and run the greps on that block, with a `tools/tools_test.sh` case of a value outside it.

## TabRequest#counted? and CommandGrammar#operator_pending? have no caller

- Where: `TabRequest#counted?` in `carat/use_cases/windows/tab_request.rb` (line 13 at 5b128b5) and `CommandGrammar#operator_pending?` in `carat/domain/command_grammar.rb` (line 84), called nowhere in `carat/`, `bin/`, `test/`, or `bench/`, yet named as key methods on lines 146 and 340 of `docs/codebase-map.md`. Periodic quality at 5b128b5.
- Why it matters: the map points readers at methods nothing uses, and dead predicates can drift from the state they describe.
- Fix outline: delete both methods and drop them from the two map lines.

## FakeTerminal#input? is called by no test

- Where: `FakeTerminal#input?` in `carat/doubles/fake_terminal.rb` (line 55 at 5b128b5). Periodic quality at 5b128b5.
- Why it matters: dead code in a double a reader must check before trusting what the tests exercise.
- Fix outline: delete it.

## Section 7 of the architecture omits startscreen and reducedmotion

- Where: the flag options of the option scope in section 7 of `docs/architecture.md` (line 236 at 5b128b5), while `config/default.caratrc` (lines 31 and 32), `README.md` (line 66), and `docs/compatibility.md` carry both. Periodic quality at 5b128b5.
- Why it matters: the binding document lists fewer options than the code accepts, so a change planned from it misses two.
- Fix outline: add both to the flag list within the file's budget, beside the start-screen bullets.

## The roadmap asks for a CRuby sample plugin

- Where: roadmap item 13 of `docs/architecture.md` (line 405 at 5b128b5), and line 314, which invites CRuby process plugins. Periodic quality at 5b128b5.
- Why it matters: the hard rules forbid running or testing anything with a CRuby interpreter, so the item cannot be delivered as written.
- Fix outline: make the sample a Spinel-compiled program or a shell script, and say CRuby process plugins are the author's choice, never built or tested here.

## The map's Designs lines omit the last features

- Where: the Designs lines of `docs/codebase-map.md` (line 523 at 3a99ddd and the others): area 16 lacks `explorer-folder-toggle` and `theme-tokens`, areas 3 and 13 lack `theme-tokens`, and areas 13 and 17 lack `start-screen`. Periodic quality at 3a99ddd; `completion-request` added `completion` and `diagnostics-display` to areas 13 and 17 (periodic quality at 5722559); at b76b722 area 5 (line 166) names no design of discoverability, quick-docs, or parameter-info, and area 3 (line 101) omits discoverability and layout-slots. At 31919d9 (periodic quality): `docs/codebase-map.md` line 117 names `show` twice, line 121 lists Messages without E444 and `unsaved_buffer`, Designs lines 279, 383, 389, and 437 miss completion, window, slot, breadcrumbs, `:LspStart`, `:LspRestart`, `:messages`, lsp-diagnostics, and feedback, and `docs/architecture.md` line 137 gives EditorState without the message, its error flag, and the history.
- Why it matters: the Designs line is where a change finds the archived decisions of its area, so a reader of these areas misses why the code looks as it does.
- Fix outline: add each change with the sections that touch the area, drop the second `show`, name the missing entries, and add the message history to the architecture's section 4, within the budgets. Queued in `architecture-drift`; the 31919d9 part in `docs-index`.

## Three explorer test rows spell out the DOCS tree inline

- Where: the rows 'Enter expands a directory', 'l expands it too', and 'h on a file goes to its parent' of `test/editor_explorer.rb` (lines 199, 200, and 224 at 136cc84) repeat the literal of the `DOCS` constant (line 88). Quality advisory of `explorer-folder-toggle`.
- Why it matters: a change to the tree's rendering must be made in four places instead of one, and a missed copy reads as a different expected tree.
- Fix outline: use `DOCS` in the three rows; the snapshot does not change.

## The explorer's Tree takes a positional boolean the keyword rule forbids

- Where: `Tree.new` in `carat/plugins/explorer/plugin.rb` (line 484 at `explorer-folder-toggle`), passing the hidden-files flag positionally, while `test/lint.rb` (line 674) exempts `carat/plugins/` and `carat/plugin_api.rb` from the keyword-constructor check that `CLAUDE.md` states without exception. Periodic quality advisory at 3a99ddd.
- Why it matters: a bare `true` or `false` at the call site reads as nothing, and the rule and its check disagree, so a reader cannot tell whether plugins must follow it.
- Fix outline: give `Tree` keyword arguments (root, the hidden-files flag, the ignore list), and state the plugin exemption, or its absence, in `CLAUDE.md` beside the lint rule.

## Text on the cursor line falls below 4.5:1 in every palette

- Where: the `CURSOR_LINE` role of the four palettes in `carat/domain/themes.rb`, measured by the cursor-line table of `test/domain_theme.rb`, which holds the cursor line to 3:1 as the selection is. At `cursor-shapes`: one_dark's keyword groups at 4.42:1 (24 bits), one_light's constants at 4.27:1 and its green groups at 4.05:1 (256 colors), dark_plus's comments and error groups at 3.99 to 4.43:1, light_plus's numbers at 3.90:1 (256 colors).
- Why it matters: goal 1 asks for readable contrast; the line the user reads most is a little below WCAG AA for normal text in those groups.
- Fix outline: tune each palette's cursor-line color, and its 256-color index (one_light and light_plus round to gray 255 at 256 colors), or the few foregrounds, until the table passes at 4.5:1 for text, then raise the threshold in the test. Queued in `theme-tidy`.

## The default cursor line keeps the terminal's foreground over a dark stripe

- Where: `config/default.caratrc` (line 22 at `cursor-shapes`) turns `cursorline` on with `one_dark` and `option.background terminal`, so in `carat/domain/themes.rb` the lit cells of groups without a foreground keep the terminal's own foreground over the fixed `CURSOR_LINE` stripe (0x2c313c). Quality advisory of `cursor-shapes`.
- Why it matters: on a light terminal, plain text on the cursor line becomes dark on dark and unreadable, and the cursor-line contrast table of `test/domain_theme.rb` checks only `background theme`.
- Fix outline: give lit cells the palette's foreground when the stripe is painted over the terminal's background, with a contrast row for `background terminal`, or ship `cursorline` off until the theme follows the terminal's background. Queued in `theme-tidy`.

## The presenter passes the number's group to paint_row through an instance variable

- Where: `@number_hl` in `carat/adapters/frame_presenter.rb` (line 420 at `cursor-shapes`), set just before the call to `paint_row`, although it is derivable from the layer. Quality advisory of `cursor-shapes`.
- Why it matters: a hidden coupling: any other caller of `paint_row` inherits a stale group.
- Fix outline: pass the group, or the layer, to `paint_row` as a parameter and drop the instance variable and its RBS line. Queued in `search-structure`.

## The boolean options of :set are three parallel switches with a silent default

- Where: `full_boolean`, `set_boolean`, and `on?` in `carat/use_cases/ex/set_command_handler.rb` (line 122 at `cursor-shapes`); `set_boolean` and `on?` fall through to `incsearch` in their `else`. Quality advisory of `cursor-shapes`.
- Why it matters: a fourth boolean option needs an edit in each of the three, and a missed branch silently reads or writes `incsearch`.
- Fix outline: one table of name, abbreviation, and `Options` member read by all three, or an explicit `incsearch` branch with no silent `else`.

## The cursor line doubles the highlight group-id space

- Where: `LIMIT = COUNT * 2` in `carat/domain/highlight.rb` (line 107 at `cursor-shapes`), which doubles every theme array and `SgrTable` entry with it. Quality advisory of `cursor-shapes`.
- Why it matters: a one-off layer: a second overlay such as ColorColumn or CursorColumn would have to multiply the space again.
- Fix outline: when the next overlay arrives, generalize to `id = base + layer * COUNT` with a layer count, or record the limit in the design.

## A 16-color background index is named like a group id in the theme build

- Where: `lit16` in `carat/domain/themes.rb` (line 428 at `cursor-shapes`) holds the `CURSOR_LINE` role's 16-color background index, while `lit` in the same loop is a layered group id. Quality advisory of `cursor-shapes`.
- Why it matters: the names suggest one is the 16-color form of the other.
- Fix outline: rename `lit16` to `line_bg16` beside `line16`. Queued in `theme-tidy`.

## A test helper's comment sits above the wrong method

- Where: `test/editor_search.rb`, the comment of the `editor` helper (lines 8 and 9 at d5036f4) now sits above the `group` helper `cursor-shapes` added, with `def self.editor` at line 16. Advisory of the periodic quality review at d5036f4.
- Why it matters: the two comments read as one comment for `group`, and `editor` has none.
- Fix outline: move the `editor` comment above `def self.editor`. Queued in the backlog item of `docs/queue.md` with the comment-wrap entry.

## BufferList keeps any_modified? and number_of with no production caller

- Where: `any_modified?` (line 115 at cd87445) in `carat/domain/buffer_list.rb`, still named in the map's `buffer_list.rb` line, and `number_of` (line 61), whose only caller is `test/domain_buffer_list.rb` line 169. Quality advisory of `buffer-list`; reworded by the periodic quality review at cd87445.
- Why it matters: `Quit` and `QuitAll` now use `first_unsaved`, so `any_modified?` is dead code, and `number_of` returns a list position that is no longer the buffer number, which misleads a future caller.
- Fix outline: remove both, use `modified_buffer.nil?` in the tests, and drop `any_modified?` from the map. Queued in `docs-index`.

## BufferList#first_unsaved takes a boolean flag argument

- Where: `first_unsaved(hidden_only)` in `carat/domain/buffer_list.rb` (line 124 at `buffer-list`), called by `Quit` and `QuitAll`. Quality advisory of `buffer-list`.
- Why it matters: a flag argument hides two behaviors behind one name; `Quit` reaches it with one file window whose buffer `:quit` already checked, so `first_unsaved(false)` equals `hidden_modified` there.
- Fix outline: have `Quit` call `@buffers.hidden_modified` and drop the parameter, leaving `first_unsaved` for `QuitAll`. Queued as `buffer-list-structure` in `docs/queue.md`.

## BufferCommandHandler#digits? duplicates HistoryCommandHandler.digits?

- Where: `digits?` in `carat/use_cases/ex/buffer_command_handler.rb` (line 98 at `buffer-list`) and `HistoryCommandHandler.digits?` in `carat/use_cases/ex/history_command_handler.rb` (line 65). Quality advisory of `buffer-list`.
- Why it matters: two copies of one check drift apart.
- Fix outline: keep one shared helper and call it from both handlers. Queued as `buffer-list-structure` in `docs/queue.md`.

## A buffer number with leading zeros past nine bytes reads as the largest

- Where: `number_in` in `carat/use_cases/ex/buffer_command_handler.rb` (line 92 at `buffer-list`). Quality advisory of `buffer-list`.
- Why it matters: any argument over 9 bytes maps to `LARGEST`, so `:b 0000000001` reports E86 and `:bn 0000000002` steps a wrong count, unlike Neovim.
- Fix outline: skip leading zeros before the length check, with a table row for each spelling. Queued as `buffer-list-tidy` in `docs/queue.md`.

## BufferRequest's :current target exists only to return no outcome

- Where: `carat/use_cases/buffers/buffer_request.rb` (line 5 at `buffer-list`), `SwitchBuffer` in `carat/use_cases/buffers/switch_buffer.rb` (line 29), and its one producer in `BufferCommandHandler` (line 66). Quality advisory of `buffer-list`.
- Why it matters: a request target with no behavior widens the use case's input for one handler's empty-argument case.
- Fix outline: return `Outcome.none` in `BufferCommandHandler#number` for `:b` without a number and drop `:current` from `BufferRequest` and `SwitchBuffer`. Queued as `buffer-list-tidy` in `docs/queue.md`.

## BufferList#step_from is hard to verify and exposes file_count for it

- Where: `step_from` (line 145 at `buffer-list`) and `file_count` (line 169) in `carat/domain/buffer_list.rb`. Quality advisory of `buffer-list`.
- Why it matters: a modulo shortcut combined with a sentinel-reset loop makes `:bn` and `:bp` with a count hard to check by reading, and `file_count` is public only for it.
- Fix outline: gather the file-buffer indices once and index them modulo their count from the target's position, and make `file_count` private or fold it in, keeping the `test/domain_buffer_list.rb` rows. Since `bars`, `BufferList#tab_row?` and the buffer tabs also count file buffers, so `file_count` stays public or gives way to a shared walk. Queued as `buffer-list-structure` in `docs/queue.md`.

## CloseOtherWindows clears tab.previous a second time

- Where: `tab.previous = -1` in `carat/use_cases/windows/close_other_windows.rb` (line 34 at `buffer-list`). Quality advisory of `buffer-list`.
- Why it matters: `BufferList#close_window` already clears `previous` when it names a closed window, and `previous` never names the current one, so the line reads as a needed step it is not.
- Fix outline: drop the line, or keep it with a comment if it is meant to clear a stale id. Queued as `buffer-list-structure` in `docs/queue.md`.

## :ls and E162 show a newline in a file name as a line break

- Where: `ListBuffers#name_of` in `carat/use_cases/buffers/list_buffers.rb` (line 72 at 68eb750) and `Messages.unsaved_buffer` in `carat/domain/messages.rb` (line 16), whose message the frame presenter splits on line breaks. Periodic security Low (4) at 68eb750.
- Why it matters: a file in an untrusted repository whose name holds a newline, opened from the explorer, forges extra `:ls` lines (a fake buffer number, flags, or line) and extra E162 lines; `Frame#put` already shows other control bytes safely.
- Fix outline: show a buffer name in a message with control characters escaped as the painter does, with a `test/editor_buffers.rb` row for a name holding a newline. Queued as `buffer-list-tidy` in `docs/queue.md`.

## Three window closers still say only a modified buffer stays listed

- Where: the comments of `CloseTab` (`carat/use_cases/windows/close_tab.rb`, lines 8 to 10 at 68eb750), `CloseOtherTabs` (`carat/use_cases/windows/close_other_tabs.rb`, lines 8 and 9), and `WindowRequests#open_in` (`carat/use_cases/plugins/window_requests.rb`, lines 124 and 125). Periodic quality advisory at 68eb750.
- Why it matters: since `buffer-list` every file buffer stays listed until `:bd`, so the comments read as if a clean buffer left the list; `CloseWindow` and `CloseOtherWindows` already say so correctly.
- Fix outline: say the file buffer stays listed, hidden when no other window shows it, as `close_window.rb` does. Queued as `buffer-list-structure` in `docs/queue.md`.

## Five methods walk every window of every tab page

- Where: `shown?` (line 128 at 68eb750), `windows_showing` (line 145), `focus_buffer` (line 164), and the private `modified_in_page` (line 229) in `carat/domain/tab_list.rb`, and `BufferList#close_windows_of` in `carat/domain/buffer_list.rb` (line 308). Periodic quality advisory at 68eb750.
- Why it matters: a change to how windows are enumerated has to land five times.
- Fix outline: answer each question through one walk, for example `shown?` from `windows_showing`, with the `test/` rows unchanged. Queued as `buffer-list-structure` in `docs/queue.md`.

## DeleteBuffer and ListBuffers reach TabList through BufferList

- Where: `DeleteBuffer` (`carat/use_cases/buffers/delete_buffer.rb`, line 31 at 68eb750) and `ListBuffers` (`carat/use_cases/buffers/list_buffers.rb`, lines 56 and 73) use `@buffers.tabs`, while `CloseTab`, `CloseOtherTabs`, and `Quit` take `tabs:` from `EditorAssembly`; `CloseOtherWindows` (`carat/use_cases/windows/close_other_windows.rb:26`) takes the same route, and its `test/adapters_assembly.rb` row checks only the buffer list. Periodic quality advisories at 68eb750 and 847851d.
- Why it matters: two routes to one collaborator leave no one clear way, and `test/adapters_assembly.rb` checks only the injected one.
- Fix outline: inject `tabs:` into the three as their siblings do, with assembly test rows, or document `BufferList#tabs` as the one route. Queued in `buffer-list-tidy` in `docs/queue.md`.

## StatusBar requires the plugin API it does not use

- Where: `require_relative "../plugin_api"` on line 1 of `carat/adapters/status_bar.rb`. Quality advisory of `bars`.
- Why it matters: `StatusBar` names no `PluginApi` constant, so the require is dead and suggests a dependency the adapter does not have.
- Fix outline: drop the require and rebuild with `make dev-build`.

## FramePresenter reaches through TabBar to ask whether the tab row shows

- Where: `@tab_bar.buffers.tab_row?(state.tabs.tab_count)` in `carat/adapters/frame_presenter.rb` (line 157 at `bars`), while `ArrangeView` (`carat/use_cases/arrange_view.rb`, line 37) asks `BufferList#tab_row?` directly. Quality advisory of `bars`, raised twice.
- Why it matters: the presenter reaches through a collaborator, and two routes to one rule can drift apart.
- Fix outline: give `TabBar` a `showing?(tab_count)` predicate and call it once in the presenter, or hand the presenter the buffer list, with the presenter test rows unchanged.

## The [No Name] text is defined in both bars

- Where: `NO_NAME` in `carat/adapters/tab_bar.rb` (line 23 at `bars`) and again in `carat/adapters/status_bar.rb` (line 46); at 7711421 also `carat/adapters/winbar.rb` line 17, `carat/use_cases/buffers/list_buffers.rb` line 20, and `carat/domain/messages.rb` line 16 (periodic quality note 33). Quality advisory of `bars`, raised twice.
- Why it matters: one user-visible text has two owners that can drift apart.
- Fix outline: keep one constant, for example beside `Buffer#display_name`, and reference it from both bars.

## PluginUi keeps each segment in three structures

- Where: the `segments` Hash of `carat/domain/plugin_ui.rb` (lines 12 to 25 and `text_at`, line 61 at `bars`), keyed by the names `owners` already holds in order, beside `priorities`. Quality advisory of `bars`, raised twice.
- Why it matters: the text is read only as `segments[owners[i]]`, so `remove_segment` has to keep three structures in step for one ordered list.
- Fix outline: keep the texts in an array parallel to `owners` and `priorities`, drop the Hash, and update the tests that compare `segments`.

## Four comments of bars break their file's wrap width

- Where: `carat/domain/plugin_ui.rb` (line 7, 92 characters) and `carat/use_cases/plugins/ui_requests.rb` (line 15, 91 characters) run past the width; `carat/adapters/frame_presenter.rb` (line 63) and `carat/domain/highlight.rb` (line 6) end ragged. Quality advisory of `bars`.
- Why it matters: style only; the rest of each file wraps comments at the surrounding width.
- Fix outline: rewrap the four comments to the width of the lines around them, together with the nine-comment entry above.

## The status bar's branch slot has no writer

- Where: `carat/domain/status_slots.rb` (line 8 at `bars`) and the `BRANCH` path of `carat/adapters/status_bar.rb`. Quality advisory of `bars`; `lsp-diagnostics` writes the lsp slot and `diagnostics-display` the diagnostics counts.
- Why it matters: nothing in the code writes the branch, so this code is reachable only from tests until the git change fills it.
- Fix outline: the change that shows the git branch fills `branch`. If it is dropped from the queue, remove the slot and its path with their test rows.

## TabBar#icon_group scans every group name on each frame

- Where: `icon_group` in `carat/adapters/tab_bar.rb` (line 136 at `bars`) calls `Highlight.token_id` over every syntax and icon name each time it draws the selected tab, while the `bars` design says the group is resolved once per name. Quality advisory of `bars`.
- Why it matters: a linear scan per frame for a value that changes only with the buffer's icon, and the design text no longer matches the code.
- Fix outline: resolve the group once per icon name (a small Hash, or an id kept beside `Buffer#icon`), or correct the design text, with the tab bar test rows unchanged.

## The explorer keeps an alias of the file-icon groups

- Where: `GROUPS = Carat::PluginApi::FileIcons::GROUPS` in `carat/plugins/explorer/file_icons.rb` (line 12 at `bars`), and `carat/plugins/explorer/plugin.rb` (line 455) repeating `group_of` as `FileIcons::GROUPS[icon].to_s`. Quality advisory of `bars`.
- Why it matters: an alias kept for one caller and a copy of the API's lookup are two more places to change when the groups do.
- Fix outline: call `PluginApi::FileIcons.group_of` in the explorer, drop the alias, and drop the `Carat::` prefix, which `PluginApi` resolves without.

## Two comments still call the row under a window its status line

- Where: `carat/domain/layout_node.rb` (line 8 at `bars`) describes the row under a column as its status line, and `carat/domain/buffer.rb` (line 145) says `display_name` is what the status line shows. Quality advisory of `bars`.
- Why it matters: since `bars` the row under a window is a separator and the one status bar sits above the message row, so the comments describe a layout that is gone.
- Fix outline: say the separator row, and the name the status bar shows.

## StatusBar names a Symbol state and plugin indexes owners

- Where: the `state` parameter of `lsp_group` in `carat/adapters/status_bar.rb` (line 122 at `bars`), beside methods whose `state` is the `EditorState`, and `@owners` (line 55), which holds plugin indexes while `PluginUi#owners` holds names. Quality advisory of `bars`.
- Why it matters: one name for two kinds of value in one file misleads the reader.
- Fix outline: rename them `lsp_state` and `@plugin_indexes`.

## The leader's write-quit-all copies the ex command's

- Where: `write_quit_all` in `carat/use_cases/actions/file_handler.rb` (line 60 at `leader-layout`) repeats `FileCommandHandler#write_quit_all` in `carat/use_cases/ex/file_command_handler.rb` (line 85) line for line. Quality advisory of `leader-layout`.
- Why it matters: `:wqa` and leader `q w` agree by copy rather than by construction, against `docs/architecture.md` section 5 (shared logic stays a use case the others call), so a fix to one can miss the other.
- Fix outline: extract a `WriteQuitAll` use case over `SaveAll` and `QuitAll`, build it once in `EditorAssembly`, and inject it into both handlers.

## The generated action description passes the length check

- Where: `tools/new.sh` (line 221 at `leader-layout`) writes the placeholder description `TODO: short description`, 23 characters, which the 1-to-32-character check of `test/use_cases_actions.rb` accepts. Quality advisory of `leader-layout`.
- Why it matters: a forgotten description passes every check and ships to the key hints.
- Fix outline: have the test reject a description starting with `TODO`, or generate an empty one so the check fails until it is written.

## The action handler wiring omits the description

- Where: the action handler wiring list of `docs/examples.md` (line 27 at `leader-layout`) does not say that `register` now takes a short description, at most 32 characters, checked by `test/use_cases_actions.rb`. Quality advisory of `leader-layout`.
- Why it matters: an author wiring a handler by hand learns of the description only from a failing test.
- Fix outline: add the description to the wiring sentence for the by-hand path.

## HandleKey#step discards the queue dispatch returns

- Where: `step` in `carat/use_cases/handle_key.rb` (line 172 at `leader-layout`) ignores the queue `dispatch` returns, though `dispatch`'s comment says the caller assigns it; it works only because `call`'s queue starts as the one key. Quality advisory of `leader-layout`.
- Why it matters: the two call sites follow different rules, so a later change to the queue in `step` can silently drop or replay keys.
- Fix outline: assign the result in `step` too, or narrow the comment to the timeout path.

## Two documents count 41 UI highlight groups against the code's 49

- Where: the `Highlight` bullet of `docs/architecture.md` (line 106 at 22a5de0) and the highlight paragraph of `docs/compatibility.md` (line 438), against `SYNTAX_FIRST = 49` in `carat/domain/highlight.rb` (line 63) since `bars` added five `STATUS_MODE` and three `STATUS_LSP` groups. Periodic quality at 22a5de0.
- Why it matters: both documents describe the frame's group ids by a count that no longer matches the code, and the next group added drifts them again.
- Fix outline: say 49 UI groups in both, or name the groups without a count so a new group cannot drift them.

## StatusLineNC is themed but painted by nothing

- Where: `STATUS_NC` in `carat/domain/highlight.rb` (line 18 at 22a5de0), its color in `carat/domain/themes.rb` (line 87), and the message of `test/adapters_screen_presenter.rb` (line 181) saying inactive status lines take it. Periodic quality at 22a5de0.
- Why it matters: `bars` removed the per-window status line, so the group, its theme row, and the test message describe a row that no longer exists.
- Fix outline: keep it as a name-only Neovim group with a comment saying so and reword the test message, or drop the group, its theme row, and the test row.

## run_state.sh became executable in run-budgets

- Where: `tools/run_state.sh`, whose mode changed from 100644 to 100755 in `run-budgets`, unmentioned in its proposal. Quality advisory of `run-budgets`, raised twice.
- Why it matters: it is always run as `sh tools/run_state.sh`, so the mode change is unrelated noise that the next diff of the file carries.
- Fix outline: restore mode 100644 with `git update-index --chmod=-x`.

## spent_line repeats budget_line's budget lookup

- Where: `spent_line` in `tools/run_state.sh` (line 1138 at `run-budgets`) repeats the size-to-budget lookup of `budget_line` (line 1092, `printf TOKEN_BUDGETS | sed`). Quality advisory of `run-budgets`.
- Why it matters: two copies of one table lookup drift when the table's format changes.
- Fix outline: extract one `budget_of SIZE` helper that both call, covered by the existing `tools/tools_test.sh` cases.

## The README says the merger runs the metric line before its work

- Where: `README.md` (line 192 at `run-budgets`). Quality advisory of `run-budgets`, raised twice.
- Why it matters: since `run-budgets` the merger runs the metric line only inside the green and red lines after CI, and not at all on a pending or stale return, so the README misdescribes when the figures are recorded.
- Fix outline: reword the sentence to say the green and red lines record the figures.

## The CI wait's header and the merger's step 2 carry run history

- Where: the header of `tools/ci_wait.sh` (lines 6 to 8 at `run-budgets`) and step 2 of `.claude/agents/merger.md` (line 20), which the merger reads on every start. Quality advisory of `run-budgets`, raised twice.
- Why it matters: they record every run since `guard-hardening` (3,476 to 6,841 output tokens), which goes stale, duplicates the archived design, and costs input tokens on every merger start.
- Fix outline: keep only the 180, 240, 300 schedule and the harness behavior in both, the history in the archived design.

## Three places repeat the estimate test of sizeWord

- Where: `capLine` (line 96 at `run-budgets`) and `overCap` (line 220) in `.claude/workflows/deliver-change.js` repeat the `SIZES.includes(estimate)` test beside `sizeWord` (line 94). Quality advisory of `run-budgets`.
- Why it matters: three copies of one validity test drift when the sizes change.
- Fix outline: one `hasEstimate` helper used by all three.

## A tools test case repeats the spent-over case

- Where: the case 'spent never stops a run' in `tools/tools_test.sh` (line 635 at `run-budgets`) repeats the exit-0 over case at line 629. Quality advisory of `run-budgets`.
- Why it matters: the duplicate adds run time and a second place to update without covering anything more.
- Fix outline: drop the case.

## The security reviewer's not-run order reads reversed

- Where: `.claude/agents/security-reviewer.md` line 33 at `periodic-review-caps`. Quality advisory of `periodic-review-caps`.
- Why it matters: the line says a review without a result is recorded not-run and only then started once more, the reverse of what the periodic workflow does, so an agent following it literally could record not-run before the retry.
- Fix outline: write that a review without a result is started once more, then recorded as not-run, never as passed.

## The periodic review caps design names the wrong owner of the overrun notes

- Where: `openspec/changes/archive/2026-11-06-periodic-review-caps/design.md` line 20, against `.claude/workflows/periodic-review.js` lines 96 to 97 and `.claude/workflows/deliver-change.js`. Quality advisory of `periodic-review-caps`.
- Why it matters: the decision says the periodic result returns the cap and the delivery workflow notes overruns with its `overCap`, but the periodic workflow writes the overrun notes itself and returns `over`, and the delivery workflow only logs them, so the archived record misleads the next change to this code.
- Fix outline: add a note to the next change touching the periodic workflow's caps that corrects the decision (the archived design is not edited), or move the noting into the delivery workflow so the design holds.

## The periodic review's missed check accepts either kind's values

- Where: `missedOf` in `.claude/workflows/periodic-review.js` line 85 at `periodic-review-caps`. Quality advisory of `periodic-review-caps`.
- Why it matters: it accepts the security and the quality values for both results, although the design says the schema keeps the line safe, and it is recomputed four times per run.
- Fix outline: compute `securityMissed` and `qualityMissed` once and drop the filter, or filter by each kind's own values.

## Float offsets are not range-checked at the plugin boundary

- Where: `FloatWindow#shift` and `#place` in `carat/domain/float_window.rb` line 74, `FloatSpec.refusal`, `WindowRequests#move_float` in `carat/use_cases/plugins/window_requests.rb`, and `FramePresenter#paint_floats` in `carat/adapters/frame_presenter.rb` line 450 at `floating-windows`. Security Low (3) of `floating-windows`.
- Why it matters: a row or column offset from `open_float` or `move_float` near the integer maximum could wrap in Spinel's 64-bit arithmetic, so `shift` skips its clamp, the box's right edge wraps negative, the on-screen check passes, and frame cells are read and written far outside the frame. Only compiled-in, trusted plugins supply these offsets today and no `.caratrc` or file text reaches them, so this is defense in depth.
- Fix outline: refuse a row or column whose absolute value is above a bound such as `1 << 20` in `FloatSpec.refusal` and in `move_float`, or clamp the offset in `FloatWindow#place` before adding it to the anchor; also check that the box's right edge is past its left and its bottom past its top in `paint_floats`.

## Four float layer methods are exempt from the predicate rule by name

- Where: `BOOL_COMMANDS` in `test/lint.rb` line 212, and `FloatLayer#add`, `#enter`, `#move`, and `#close_top` in `carat/domain/float_layer.rb` at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: the table is keyed by bare method name, so `add`, `close`, `enter`, and `move` are now exempt from the predicate rule in every file, while the bool results of those four methods are read only by tests (`OpenFloat` checks `full?` first, `WindowRequests` checks the float's tab first).
- Fix outline: make the four return void, update the tests to check the layer's state instead, and drop their entries, keeping `close` and `close_focused`.

## A refused split leaves the focused float

- Where: `SplitWindow` in `carat/use_cases/windows/split_window.rb` line 32, and `open_in_split`, which restores `tab.current` but not the float focus, at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: a split refused with E36 has already called `tab.floats.leave`, so the user loses the float's focus although nothing changed.
- Fix outline: read `tab.layout_window` for the gutter width and call `tab.floats.leave` only after the split succeeds, with a test row for E36 from a float.

## A buffer shown only in a float counts as hidden

- Where: `shown?`, `windows_showing`, and `modified_in_windows` in `carat/domain/tab_list.rb` line 140 at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: they walk only the layout's windows, so after `:e` in a float a file buffer shown only there counts as hidden, which changes what `:q`, `:bd`, and the modified checks answer.
- Fix outline: include each page's float windows in the three walks, or refuse `:e` and `:b` in a float, with a test row either way.

## A disabled plugin's floats stay open

- Where: `PluginRegistry#disable` in `carat/use_cases/plugins/plugin_registry.rb` line 259, and the floats `WindowRequests#open_float` opens for a plugin; the `floating-windows` design (Risks) defers it here. Quality advisory of `floating-windows`.
- Why it matters: a plugin disabled after it raised leaves its floats on the screen, owned by a plugin that can no longer move or close them; only Esc or a close command removes them.
- Fix outline: when a plugin is disabled, close every float it owns in every tab page through the float layer, with a test that a raising plugin's float is gone.

## The float behavior of the close and focus commands has no compatibility row

- Where: `docs/compatibility.md`, for `:q`, `:close`, Ctrl-W c, the Ctrl-W focus commands, and normal-mode Esc in a float, at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: in a float these close or leave only the float, and Esc closing floats is not Neovim's behavior, but no row records either, so the difference is invisible to a reader of the table.
- Fix outline: add rows naming `test/editor_floats.rb` for each, marking Esc as a difference from Neovim.

## :close in a float is not tested

- Where: `test/editor_floats.rb` line 116 at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: the spec requires `:close` in a float to close only the float, but only `:q` and Ctrl-W c are tested, so a regression of `:close` would pass.
- Fix outline: add a `:close` case beside the `:q` and Ctrl-W c cases.

## WindowRequests#in_window keeps a dead local and an unobservable restore

- Where: `in_window` in `carat/use_cases/plugins/window_requests.rb` lines 293 and 304 at `floating-windows`. Quality advisory of `floating-windows`.
- Why it matters: it assigns `state = @state` and never reads it (the block captures `open_file`'s own state), and it restores the float focus although its only caller, `open_file`, then calls `focus_at`, whose `TabPage#focus` leaves the float again, so the restore is never observable.
- Fix outline: delete the dead line, and drop `saved_float` and its `enter`, or document that `in_window` keeps the focus for callers that do not refocus. Queued in `bars-tidy` with the other `floating-windows` notes.

## FloatLayer is a plain class among the mutable records

- Where: `carat/domain/float_layer.rb` line 10 at 803fe6e. Periodic quality advisory.
- Why it matters: `CLAUDE.md` makes mutable records `Struct` subclasses with pinned members; `TabPage`, `TabList`, `LastFind`, and `StatusSlots` follow it, `FloatLayer` does not.
- Fix outline: a `Struct` with `floats` and `focus` pinned, readers and `self.member =` writers, built with keywords in `TabPage`. Queued in `bars-tidy`.

## move_float bypasses the float use cases

- Where: `WindowRequests#move_float` in `carat/use_cases/plugins/window_requests.rb` (line 247 at 803fe6e). Periodic quality advisory.
- Why it matters: `open_float` and `close_float` go through `OpenFloat` and `CloseFloat` as section 5.3 asks of request families, while `move_float` writes the tab page's `FloatLayer` directly and ignores the result of `move`.
- Fix outline: a `MoveFloat` use case beside the other two, or a class comment saying a move is a domain write needing none, with `FloatLayer#move` made void. Queued in `bars-tidy`.

## The architecture names no float

- Where: `docs/architecture.md` at 803fe6e: the Window, Layout, TabPage bullet (line 129), the Frame bullet (line 130), section 5.3 (line 177), and the ArrangeView bullet (line 178). Periodic quality advisory.
- Why it matters: the binding architecture omits `FloatSpec`, `FloatWindow`, `FloatLayer`, `TabPage#window` answering the focused float first, `OpenFloat`, `CloseFloat`, float placement, and the float key.
- Fix outline: add the three entities to section 4, the two use cases and the placement to section 5.3, and the key to the Frame bullet, within the file's budget. Queued in `architecture-drift`.

## A language server that ignores the end of its input outlives the editor

- Where: `ProcessRunner#stop` in `carat/drivers/process_runner.rb` at `lsp-diagnostics`. Periodic security Low (5) at eb63fb4.
- Why it matters: stop closes the child's input after `shutdown` and `exit` and detaches it without a signal, so a server that neither exits on `exit` nor on the end of its input keeps running after the editor ends; ruby-lsp exits on both.
- Fix outline: after closing the input, send `TERM` from the writer thread when the child has not ended within a second, and `KILL` a second later, with a test over a child that ignores its input. Queued in `lsp-client-tidy`.

## didChange sends the whole text of a changed buffer

- Where: `JsonRpcLanguageGateway#sync_buffer` in `carat/adapters/json_rpc_language_gateway.rb` at `lsp-diagnostics`.
- Why it matters: every idle tick after an edit copies and encodes the buffer's whole text, which for a file of megabytes is a visible pause after typing stops.
- Fix outline: send incremental changes built from the buffer's change records since the last version when the server asks for incremental sync, with a gateway test of an edit in the middle of a long file. Fits `completion`, which needs fresh text often.

## Diagnostic columns are UTF-16 units

- Where: `JsonRpcLanguageGateway#diagnostic_of` at `lsp-diagnostics`: `Diagnostic#col` keeps the server's `character`, counted in UTF-16 units, the protocol's default.
- Why it matters: on a line with characters outside the ASCII range the column differs from the code point column the editor uses, so a jump would land on the wrong character. `diagnostics-display` draws by row only (the sign and the message row), so nothing reads the column yet.
- Fix outline: convert with the line's text when a position is used, or negotiate `utf-32` through `general.positionEncodings`, in the later `definitions` change, whose jumps are the first to read a column, with a row on a line holding a character outside the BMP.

## Language servers are told about files outside the trusted root

- Where: `JsonRpcLanguageGateway#sync` and `#poll` in `carat/adapters/json_rpc_language_gateway.rb` (lines 205 and 430 at `lsp-diagnostics`), which decide trust by the working directory only and then send `didOpen`, `didChange`, and `didSave` for every buffer of the server's file type. Security Lows (3) and (4) of `lsp-diagnostics`.
- Why it matters: in a trusted root a user who opens `/tmp/evil/x.rb` hands that file to ruby-lsp, whose RuboCop pass may load the `.rubocop.yml` beside it, and its `require:` entries run code from a directory nobody trusted.
- Fix outline: send document notifications only for buffers whose absolute path is under the working directory or a trusted root; show such a buffer as untrusted until `:LspStart`; add a gateway test with a buffer outside the root.

## ProcessRunner#write answers true after its writer stopped

- Where: `ProcessRunner#write` in `carat/drivers/process_runner.rb` (line 55 at `lsp-diagnostics`): only `stop` clears `@open`, so after the writer thread ends on a broken pipe `write` still answers true. Quality advisory of `lsp-diagnostics`.
- Why it matters: it breaks `ProcessPort#write`'s contract (whether the child still takes input), the outbox grows unread, and the gateway's broken-input path runs only with `FakeProcesses`.
- Fix outline: report the writer's end through a queue the editor thread checks in `write`, or reword the port to whether the handle is open and rely on the reader's `exit` message. Queued in `lsp-client-tidy`.

## The language server client repeats itself and names little of what it uses

- Where: `carat/adapters/json_rpc_language_gateway.rb` at `lsp-diagnostics`: `start` and `restart` (lines 88 and 112 to 118) repeat the no-server message and the Cannot start tail; `hold` (line 228) repeats `launch`'s name computation (line 242); the private `forget(language)` (line 171) shares its name with `LanguageServer#forget(uri)` (line 455) and rescans the list `server_for` just scanned. `LspStartCommandHandler#call` (`carat/use_cases/ex/lsp_start_command_handler.rb` line 24) copies `LspRestartCommandHandler#call`. `Json` has the same plain ASCII byte predicate three times (`ascii_text?` line 234, `plain?` line 413, inlined in `write_string` line 392). Quality advisories of `lsp-diagnostics`.
- Why it matters: duplication and a shared name for two different operations make the next change to one copy miss the other.
- Fix outline: one private helper answering the start message, one `name_of(words)`, `forget` renamed `drop_server` taking the index `start` holds, one `Json` module function for the byte test; keep the two ex handlers separate if section 5 asks one handler per command, else share the argument check and the outcome mapping. Queued in `lsp-client-tidy`.

## The language server client has loose ends

- Where: at `lsp-diagnostics`: `LanguageServer#words` (`carat/domain/language_server.rb` line 11) is stored and never read; `LspRestartCommandHandler.register(table, services)` (`carat/use_cases/ex/lsp_restart_command_handler.rb` line 35) takes its collaborator positionally; `RpcFramer#refuse` (`carat/domain/rpc_framer.rb` line 82) answers false only for `return refuse`, which needs a `BOOL_COMMANDS` entry in `test/lint.rb`; `json_rpc_language_gateway.rb`, `editor_assembly.rb`, `input_controller.rb`, `lsp_restart_command_handler.rb`, and `process_runner.rb` omit `require_relative` lines for files they name. Quality advisories of `lsp-diagnostics`.
- Why it matters: dead code, an odd signature, and a lint exemption that exists for an idiom each mislead the next reader; sibling files require what they name.
- Fix outline: drop `words` or use it for the restart message; `register(table, services:)` with `services: @services` in `EditorAssembly`; make `refuse` void, return false after it, and drop the lint entry; add the missing `require_relative` lines. Queued in `lsp-client-tidy`.

## No test shows a refused language server spawn is not retried

- Where: `test/adapters_language_gateway.rb` line 173 at `lsp-diagnostics`: `FakeProcesses#spawn` records only installed commands, so the missing-command case cannot see a retried spawn, and the refusal kept in `@refused` until `:LspStart` or `:LspRestart` is untested. Quality advisory of `lsp-diagnostics`.
- Why it matters: a regression that retries the spawn on every idle tick, spawning a process four times a second, would pass.
- Fix outline: count attempted spawns in `FakeProcesses` and assert one attempt after two idle ticks. Queued in `lsp-client-tidy`.

## A save while the language server starts is never sent

- Where: `poll` in `carat/adapters/json_rpc_language_gateway.rb` (line 76 at eb63fb4) clears the pending saves on every tick, while `sync_buffer` sends `didSave` only to running servers. Periodic quality at eb63fb4.
- Why it matters: a write while the server is starting or crashed is dropped without a `didSave`, so the server keeps working from the state before the save.
- Fix outline: clear only the saves a running server of the buffer's language was told, with a gateway row for a save during starting. Queued in `lsp-client-tidy`.

## A write to another path is reported to the language server as a save

- Where: `SaveFile` in `carat/use_cases/files/save_file.rb` (line 52 at eb63fb4). Periodic quality at eb63fb4.
- Why it matters: `:w other_path` reports the buffer saved, so `didSave` goes out for a document whose own file was not written.
- Fix outline: report the save only when the written path is the buffer's own, with a row for `:w` to another path. Queued in `lsp-client-tidy`.

## The language server outbox has no bound

- Where: the per-child outbox queue in `carat/drivers/process_runner.rb` (line 58 at eb63fb4). Periodic security Low (5).
- Why it matters: a server that stops reading its input makes every `didOpen` and `didChange` body accumulate in editor memory.
- Fix outline: count the queued bytes per handle and treat the server as crashed past a cap, with a driver test over a child that never reads. Queued in `lsp-client-tidy`.

## Published diagnostics keep any number of URIs

- Where: the `publishDiagnostics` handling of `carat/adapters/json_rpc_language_gateway.rb` (line 1059 at 5e4c140). Periodic security Low (4) at eb63fb4, confirmed again as a periodic security Low (3) at 5e4c140.
- Why it matters: a server publishing for many distinct URIs grows the map without limit.
- Fix outline: keep only the documents the gateway opened, or cap the map and drop the oldest, with a gateway row. Queued in `lsp-client-tidy`.

## The architecture omits the language service start, trusted roots, and the writer thread

- Where: `docs/architecture.md` at eb63fb4: the section 6 port table (line 203), the section 7 Scopes sentence (line 236), and the service threads bullet (line 268); `docs/codebase-map.md` lines 567 and 577. Periodic quality at eb63fb4.
- Why it matters: `LanguageServicePort` declares `start`, which `:LspStart` calls, but the table and the map omit it; the Scopes sentence omits `language.trusted_roots`, its word format, and that only the defaults and the user file set it; the bullet names only the reader thread while the code starts a reader and a writer per child.
- Fix outline: add `start(state)` to the table row and both map lines, `trusted_roots` to the Scopes sentence, and the writer thread to the bullet, within the file's budget. Queued in `architecture-drift`.

## The diagnostics display leaves out navigation, the full text, and colors

- Where: `diagnostics-display` (`Buffer#set_diagnostics`, `FramePresenter#paint_diagnostic`). Left out of the change by its proposal.
- Why it matters: Neovim users expect `]d` and `[d` to move between diagnostics and a float with the full message of several lines; the signs are drawn in the one `SignColumn` group, not in `DiagnosticSignError` and its siblings, so an error and a hint differ only by glyph; signs keep the icon set in force when they were published until the next publish.
- Fix outline: two motions over the buffer's marks bound in the five modes; a float showing the message; a group per mark in `SignLayer`, compared in `PaintedRows`; signs redrawn when `icons` changes. Each with a table row.

## StatusSlots counts an error in a needless branch

- Where: `count_diagnostics` in `carat/domain/status_slots.rb` (line 65 at 38d8c47). Quality advisory at `diagnostics-display`, reported twice.
- Why it matters: `error?` is `severity == 1`, so both arms add one to `counts[severity]`; the branch reads as if errors were counted apart.
- Fix outline: drop the `if` and keep `counts[diagnostic.severity] += 1`.

## The diagnostic highlight group is a public class method of the presenter

- Where: `FramePresenter.diagnostic_group` in `carat/adapters/frame_presenter.rb` (line 956 at 38d8c47), called only by `paint_diagnostic`. Quality advisory at `diagnostics-display`, reported twice.
- Why it matters: the mapping from severity to group is a property of the domain value, kept as public API of an adapter that only its own painter uses.
- Fix outline: move it to `Domain::Diagnostic#group` (or `Highlight.diagnostic_group`) and call it from `paint_diagnostic`; failing that, make it a private instance method beside `paint_diagnostic`.

## The gateway's apply has an unclear name and a needless branch

- Where: `apply(set)` in `carat/adapters/json_rpc_language_gateway.rb` (lines 440 and 453 at 38d8c47). Quality advisory at `diagnostics-display`.
- Why it matters: the name says neither what is applied nor that `set` is the icon set name, and the `list.empty?` branch calls `clear_diagnostics`, which `Buffer#set_diagnostics` already does for an empty list.
- Fix outline: rename it `show_published(icon_set)` at its call sites and call `buffer.set_diagnostics(list, glyphs)` unconditionally.

## ControlText.cleaned is public with a flag argument

- Where: `ControlText.cleaned` in `carat/domain/control_text.rb` (line 28 at 38d8c47), used only by `strip` and `line`; also `RAW_LIMIT` declared between methods (line 27 at 5722559) and the helpers `sequence_end` and `string_end` left public (`without_sequences` is now called by `MarkdownText.rows`, line 34, so it stays public). Quality advisory at `diagnostics-display`, periodic quality at 5722559.
- Why it matters: a public module function taking a bool flag invites callers outside the module to depend on a helper of its two entry points, and the other helpers and the constant's place read as API.
- Fix outline: mark `cleaned`, `sequence_end`, and `string_end` `private_class_method`, and move `RAW_LIMIT` beside `REPLACEMENT` at the top.

## Diagnostic marks moving on undo, redo, and reload have no test

- Where: `shift_signs` in `revert` and `reapply` and the reload path of `carat/domain/buffer.rb` (line 623 at 38d8c47); `test/domain_buffer.rb` covers only `set_lines`. Quality advisory at `diagnostics-display`.
- Why it matters: the marks now move on `u`, `<C-r>`, and reload, but a regression there would draw a sign on the wrong row without a failing test.
- Fix outline: add rows for `u` and `<C-r>` over a line inserted above a marked row and one for reload.

## Buffer requires diagnostic twice

- Where: `require_relative "diagnostic"` in `carat/domain/buffer.rb` (line 15 at 38d8c47). Quality advisory at `diagnostics-display`.
- Why it matters: `diagnostic_list.rb` already requires it, and the line sits apart from the other new require.
- Fix outline: remove the line.

## The published helper's comment in the LSP test is wrapped unevenly

- Where: the comment above `published` in `test/editor_lsp.rb` (line 36 at 38d8c47). Quality advisory at `diagnostics-display`.
- Why it matters: one line runs past 90 columns and the next holds a single word, unlike the rest of the file.
- Fix outline: rewrap it to the file's width.

## The diagnostic severities are mapped in five files

- Where: `carat/domain/diagnostic.rb` (line 8 at fb09c6b) holds the LSP severity numbers 1 to 4, while their meaning is spread over the icon names in `JsonRpcLanguageGateway#apply` (`carat/adapters/json_rpc_language_gateway.rb` line 443), `glyphs[severity - 1]` in `Buffer#set_diagnostics` (`carat/domain/buffer.rb` line 304), `FramePresenter.diagnostic_group` (`carat/adapters/frame_presenter.rb` line 956), the four `paint_count` calls and the group chain of `StatusBar` (`carat/adapters/status_bar.rb` lines 228 to 231 and 281 to 284), and the counts index of `StatusSlots#count_diagnostics`. Periodic quality at fb09c6b.
- Why it matters: a fifth severity or a reordered icon set must be changed in each of the five places, and nothing fails when one is missed.
- Fix outline: named severity constants on `Diagnostic` and one domain table of icon name and highlight group by severity, read by the gateway, the buffer, the presenter, and the bar. Queued in `diagnostics-tidy`.

## The gateway's listed is public

- Where: `listed(uri)` in `carat/adapters/json_rpc_language_gateway.rb` (line 165 at fb09c6b) sits above `private` (line 186), though only `diagnostics(path)` and `apply` call it. Periodic quality at fb09c6b.
- Why it matters: it widens the adapter's public surface with a helper no caller outside the class uses.
- Fix outline: move `listed` below `private`. Queued in `diagnostics-tidy`.

## The diagnostics display is missing from the compatibility table and the architecture

- Where: the `:LspStart` row of `docs/compatibility.md` (line 278 at fb09c6b) and `docs/architecture.md` (line 260). Periodic quality at fb09c6b.
- Why it matters: the row omits that a start after a crash clears the drawn diagnostics (the language-server spec and the `editor_lsp` test 'diagnostics after a crash and a start' require it); no row describes the diagnostic signs over a plugin's sign or the cursor line's message in normal mode, though the `diagnostics-display` pull request says the table documents the display; the architecture still says the gateway returns `Diagnostic` values where `diagnostics(path)` returns a `DiagnosticList`.
- Fix outline: add the clearing to the `:LspStart` row, rows for the signs and the message row with their tests, and name `DiagnosticList` at the architecture line. Queued in `diagnostics-tidy`.

## The ASCII digit test is copied in 12 files

- Where: `carat/domain/register_count.rb` (line 66 at fb09c6b) and the inline `b >= 48 && b <= 57` or private `digit?` of `ex_grammar`, `filetype`, `motions`, `vim_pattern`, `substitute_args`, `json`, `replacement`, `rpc_framer`, `registers`, the language gateway, and the Ruby tokenizer. Periodic quality at fb09c6b; the entry on `RegisterCount` and `SubstituteArgs` covers only two of them.
- Why it matters: twelve copies of one test drift independently, and each reader of a count or number must find its own.
- Fix outline: one domain module function used by the domain and adapter copies, the plugin keeping its own as the plugin rule requires, with `make bench` held on the hot paths. Queued in the backlog item of `docs/queue.md` (`clamp` copies and ASCII digit tests).

## A pull request touching only .claude/ skips tools-test

- Where: `documentation()` in `tools/ci_scope.sh` (line 39 at fb09c6b). Periodic security Low (5) at fb09c6b, found again by the periodic security review at 847851d, Low (5), `tools/ci_scope.sh:39`.
- Why it matters: a pull request changing only agent hook lines, `.claude/settings.json`, or the workflows is classed documentation, so CI skips `make tools-test`, the independent check of the guard hook lines and the attribution.
- Fix outline: class `.claude/agents/`, `.claude/settings.json`, and `.claude/workflows/` as code, with a `tools/tools_test.sh` case. Queued in `ci-hardening`.

## The process runner's reader queues bodies without a bound

- Where: the reader thread in `carat/drivers/process_runner.rb` (line 106 at fb09c6b). Periodic security Low (4) at fb09c6b.
- Why it matters: it queues every framed body of up to `BODY_LIMIT` with no bound while the gateway drains 64 per idle tick, so a flooding language server can exhaust the editor's memory.
- Fix outline: cap the queued bodies or bytes per handle and stop the server with an overflow message past the cap, with a driver row. Queued in `lsp-client-tidy`.

## The workflows repeat the commit pattern

- Where: `.claude/workflows/deliver-change.js` repeats the `COMMIT` pattern (line 368 at 594dd35) inline in `pushedHead` (line 248) and in the head check of a capped start (line 496); `.claude/workflows/periodic-review.js` repeats its `isCommit` (line 58) in `areasLeft` (line 74) and computes `areaSlices(MAP_AREAS, QUALITY_SLICES)` twice (lines 103 and 117). Quality advisories in `partial-results`. At 38628bb `.claude/workflows/periodic-review.js` line 74 still repeats it (periodic quality).
- Why it matters: a change to the accepted commit form or to the slicing has to be made in each copy, and nothing fails when one is missed.
- Fix outline: define `COMMIT` above the helpers and use `COMMIT.test` in both places, use `isCommit` in `areasLeft`, keep the slices in one const, and add `COMMIT` and `isCommit` to the js helper names in `tools/tools_test.sh`.

## A continued fix-round quality review is told to review the whole diff

- Where: `qualityReview` in `.claude/workflows/deliver-change.js` (line 581 at 594dd35) uses `more || scope`, so the continuation replaces the prior-review scope; the sentinel `the whole diff` is produced by `reviewLeft` (line 228) and compared in `reviewMore` (line 592). Quality advisories in `partial-results`.
- Why it matters: a capped or empty fix-round quality review is continued over the whole committed diff instead of the fix diff, spending review tokens the `review-scope` item is meant to save, and the sentinel string has two owners.
- Fix outline: append `more` to `scope` and say the files left are of that scope; name the sentinel once as a constant, or have `reviewLeft` signal a whole-diff rerun separately.

## The review continuations run one after the other

- Where: the loop `for (const k of kinds) got[k] = await continueReview(k, scope, got[k])` in `.claude/workflows/deliver-change.js` (line 627 at 594dd35). Quality advisory in `partial-results`.
- Why it matters: after the parallel first starts, a capped security review waits for the quality continuation to finish, lengthening the round.
- Fix outline: run `continueReview` for each kind with `parallel`.

## The continued security prompt joins its sentence to the last file left

- Where: the continued security prompt in `.claude/workflows/deliver-change.js` (line 586 at 594dd35) appends `Run it, every sub-task inline` right after the last bullet of `reviewMore`. Quality advisory in `partial-results`.
- Why it matters: the last file left reads as that file followed by the sentence, so the reviewer may misread the path.
- Fix outline: start the sentence on its own line.

## The CALL_CAPS comment has a short line

- Where: the comment above `CALL_CAPS` in `.claude/workflows/deliver-change.js` (line 89 at 594dd35) leaves the short line `// margin), so a start` before the paragraph continues. Quality advisory in `partial-results`.
- Why it matters: the comment reads as broken and differs from the file's width.
- Fix outline: rewrap the comment to the file's width.

## The periodic quality slices count a repeated finding twice

- Where: the slice results in `.claude/workflows/periodic-review.js` (lines 94, 115, and 116 at 594dd35) merge blocking and advisory findings with `flatMap`. Quality advisory in `partial-results`.
- Why it matters: a continued start that repeats a finding of its first start counts it twice in the recorded results the planner reads.
- Fix outline: drop duplicates as `combineReviews` in `.claude/workflows/deliver-change.js` does.

## The docs of tools-test and /review lag the workflows

- Where: the `tools-test` help line of the `Makefile` (line 355 at 594dd35) lists the shell tools but not the workflow helpers it now runs with node; `.claude/commands/review.md` (line 8) says the quality reviewer reviews the whole tree; the guard case of `tools/tools_test.sh` (line 1000) still uses `tmp/.review-quality` while the workflow names `tmp/.review-quality-N`. Quality advisories in `partial-results`.
- Why it matters: `make help` and `/review` describe what no longer runs, and the guard case tests a path the workflow no longer uses.
- Fix outline: add the workflows' pure helpers (node) to the help line, say the security reviewer and three quality starts over the code map areas in `review.md`, and use `tmp/.review-quality-1` in the guard case.

## Fuzzy completion matching reuses letters and matches a word of underscores

- Where: `Carat::Domain::FuzzyMatch` in `carat/domain/fuzzy_match.rb` (line 32 at 334d899), where each part's anchor is searched only after the previous part's anchor. Quality advisory in `completion`.
- Why it matters: a later part can reuse letters the previous part already matched, so `fa_a` matches `file_a` with one `a`, and a typed word of only underscores matches every candidate, which fills the popup with noise.
- Fix outline: start the next part's anchor search after the previous part's last matched byte and answer -1 when the pattern has no letters, with a table row for each in `test/domain_fuzzy_match.rb`.

## The completion ranking table checks a copy of the ranking

- Where: `ranked` in `test/domain_fuzzy_match.rb` (line 17 at 334d899) copies the insertion sort of `ShowCompletion#ranked` in `carat/use_cases/completion/show_completion.rb`. Quality advisory in `completion`.
- Why it matters: the ranking table checks the test's copy, not the production order, so a change to `ShowCompletion`'s ranking passes the test unseen.
- Fix outline: move the ranking into the domain (`FuzzyMatch.rank` or `CompletionMenu#rank`), call it from `ShowCompletion`, and point the table at it.

## A multi-key keymap.completion line loads and never fires

- Where: `completion_key?` in `carat/use_cases/handle_key.rb` (line 201 at 334d899) answers only a single-key `:match`, while `Keymap#add_checked` accepts any `keymap.completion` line. Quality advisory in `completion`.
- Why it matters: a multi-key completion binding, or a single key that also starts a longer one, loads with no reported problem and silently does nothing, against the rule that every configuration problem is reported as `file:line: message`.
- Fix outline: report such `keymap.completion` lines as `file:line` problems in `add_checked`, with a configuration test row.

## Completion code style advisories

- Where: `CompletionHandler.register` in `carat/use_cases/actions/completion_handler.rb` (line 45 at 334d899) repeats the five-keyword constructor five times; the `completion` keyword and reader of `HandleKey` in `carat/use_cases/handle_key.rb` (line 60) hold a `Domain::CompletionMenu` that the assembly and every use case call `completion_menu` or `menu`; `row_offset` in `carat/use_cases/completion/show_completion.rb` (line 145) subtracts an unexplained 2 from `screen_rows`; the `paint_float_row` comment in `carat/adapters/frame_presenter.rb` (line 466) still says the text is drawn in NormalFloat though a menu's rows are Pmenu and PmenuSel; the PageDown row of `test/editor_completion.rb` (line 81) asserts only the row and the closed popup. Quality advisories in `completion`.
- Why it matters: the register and reader names differ from the style of their neighbours, the 2 and the comment mislead a reader of the layout and the paint path, and the PageDown row would pass with an empty word at column 0, so it does not show the not-typed branch ran.
- Fix outline: loop over parallel names, variants, and descriptions arrays as `BufferHandler.register` does; rename the keyword and reader to `completion_menu`; name the reserved rows in a private constant or read the free rows from the layout area `ArrangeView` uses; say "its text in float_group's group"; assert the cursor column 2 and `h.completions.asked == 1` in the PageDown row as the cursor-binding row does.

## Completion docs advisories

- Where: `README.md` (line 63 at 334d899), where the raw-mode sentence explaining why Ctrl-S works moved to the end of the completion paragraph; the language-services area of `docs/codebase-map.md` (line 593) names only `test/domain_rpc_framer.rb` for `ControlText`, though `test/domain_fuzzy_match.rb` (line 267 of the map) also holds the `ControlText.plain`, `CompletionItem`, and `CompletionList` tables; the 5.3 bullet of `docs/architecture.md` (line 180) says these use cases answer an unavailable service with an empty response and a message, while completion with no ready source opens nothing and reports nothing. Quality advisories in `completion`.
- Why it matters: the README sentence no longer follows the Ctrl-S sentence it explains, the map hides where the `ControlText.plain` table lives, and the architecture contradicts the completion spec (typing behaves as without completion).
- Fix outline: put the raw-mode sentence back after "Ctrl-S saves ... stay in insert mode." and keep the completion paragraph on its own; name `test/domain_fuzzy_match.rb` for `ControlText.plain` in the language-services line or move those tables to a test named after them; say completion stays silent when its source is not ready, or state the `CompletionPort` route in the 5.1 completion bullet instead.

## tools_test cases grep the workflow source instead of testing behavior

- Where: `tools/tools_test.sh:1741`, also 1694-1696, 1746-1747, 1752-1755, 1762-1763 (periodic quality at 5722559).
- Why it matters: the cases grep exact lines of `deliver-change.js`, `periodic-review.js`, and the agent files, so they pass whatever those lines do and fail on any rewording.
- Fix outline: move each decision (security pass with files left, merge stop without a checked sha, partial periodic record, worktree name) into a pure helper run through js, and drop the source greps.

## Eleven copies inline the tab width Options already answers

- Where: at the `pinned-main` change, `carat/use_cases/leave_insert.rb:69`, `carat/use_cases/insert_tab.rb:22`, `carat/use_cases/repeat_last.rb:104`, `carat/use_cases/arrange_view.rb:40`, `carat/use_cases/dispatcher.rb:112`, `carat/use_cases/visual/extend_visual.rb:54`, and `carat/adapters/frame_presenter.rb:178` (periodic quality at b0dd342, 5722559, cd87445, and b76b722), and in the domain `carat/domain/operators.rb:172`, `251`, and `272` and `carat/domain/display_width.rb:62` (pinned-main advisory, at 847851d).
- Why it matters: `tabstop > 0 ? tabstop : 8` is copied eleven times beside `Options#tab_width` (`carat/domain/options.rb:92` at 847851d), so a rule change misses copies.
- Fix outline: call `options.tab_width` in the eleven places (the domain ones through one shared domain function where no `Options` is at hand) and drop the inline copies.

## ChangeRecord#delta and UndoTree#redo_seq have no production caller

- Where: `carat/domain/change_record.rb:18`, `carat/domain/undo_tree.rb:179` (periodic quality at 5722559).
- Why it matters: dead code read only by `test/domain_edits.rb` and `test/domain_undo_tree.rb`, and the map lists `redo_seq` as API.
- Fix outline: drop both, assert the record's removed and inserted lengths and the redo path in the tests, and remove `redo_seq` from area 9 of the map.

## The explorer queries the current window with focus_window

- Where: `carat/plugins/explorer/plugin.rb:202` (periodic quality at 5722559).
- Why it matters: `host.focus_window(0)` has effects (sets the tab page, re-enters a focused float) but is used as a query.
- Fix outline: a read-only host request for the current window (Host method, PluginLink override, WindowRequests method, minor version bump) or the window in `PluginApi::Command`, called here.

## focus_window enters floats the plugin does not own

- Where: `carat/use_cases/plugins/window_requests.rb:132` (periodic quality at 5722559).
- Why it matters: a plugin can enter the core's completion popup or another plugin's floats, while `move_float` and `close_float` refuse them through `own_float_tab`.
- Fix outline: refuse what `own_float_tab` rejects with `No window N`, with a row in `test/use_cases_plugins.rb`.

## Icons sit in the explorer's map area

- Where: `docs/codebase-map.md:545` (periodic quality at 5722559).
- Why it matters: `carat/domain/icons.rb` and `test/domain_icons.rb` are in area 16, but the explorer never calls `Icons`; its callers are the bars, the gateway's signs, the plugin requests, and the completion kind icons.
- Fix outline: move both entries to area 13 Rendering.

## Map method lists lag the code

- Where: `docs/codebase-map.md:502`, 438, 435, 614 (periodic quality at 5722559); also lines 151, 185 to 188, and 285 at c1b3a12 (periodic quality, docs-index): the `LastChange` bullet omits `split` and `unmeasure`, and the other two lag their files' method lists. At 38628bb also `docs/codebase-map.md` lines 223, 292, and 320 (periodic quality); at b76b722 also PaintedRows, Frame, FakeTerminal, EditorHarness (lines 450 to 638), Layout, TabList, BufferList, and FloatLayer (lines 256 to 355) miss public methods.
- Why it matters: `PluginApi::Paths` omits `absolute`, `StatusSlots` omits `set_lsp` and `label`, `FramePresenter` omits `float_group`, `EditorHarness` omits `completions`; a reader trusting the map misses the methods.
- Fix outline: add the missing names at each line. Queued in `docs-index`.

## Tab with expandtab pads by character column

- Where: `carat/use_cases/insert_tab.rb:23` (periodic quality at 5722559).
- Why it matters: after a tab or a wide character before the cursor the spaces stop short of or past the next tab stop, unlike Vim's virtual-column rule; `test/editor_insert.rb:64` checks only an ASCII line.
- Fix outline: take the display column with `Domain::DisplayWidth.column` and pad to the next multiple of the tab width, with rows after a tab and after a wide character.

## Architecture section 4 names no completion domain object

- Where: `docs/architecture.md:92` (periodic quality at 5722559).
- Why it matters: `CompletionMenu`, `CompletionItem`, `CompletionList`, and `FuzzyMatch` are missing from Entities though section 5.1 names their use cases.
- Fix outline: one section 4 bullet for the four within the file's budget, in the queued `architecture-drift` change.

## A failed completion send leaves the input polling

- Where: `complete` in `carat/adapters/json_rpc_language_gateway.rb` (line 474 at 376d264). Quality advisory in `completion-request`.
- Why it matters: a write failure inside `request` crashes the server and `forget_completion` zeroes `sent_id`, but the returned id is then assigned to `sent_id`, so `waiting?` stays true and the input polls every 0.02 s until `ANSWER_LIMIT`.
- Fix outline: `id = request(...)`, then `ask.sent_id = server.running? ? id : 0`, with a gateway row whose server fails the write.

## The input controller reaches through ShowCompletion for an arrival

- Where: `carat/adapters/input_controller.rb` (line 71 at 376d264), which reads `@show_completion.source.request.arrived`, three objects deep. Quality advisory in `completion-request`, reported twice.
- Why it matters: the adapter depends on the use case's source and its request record, so a change to either breaks the controller.
- Fix outline: inject the shared `Domain::CompletionRequest` (`completions.request` in `EditorAssembly`, checked in `test/adapters_assembly.rb`), or call the show-completion use case unconditionally, since it returns at once when nothing shows or arrived.

## UTF-16 length is computed in the language gateway

- Where: `utf16_length` in `carat/adapters/json_rpc_language_gateway.rb` (line 521 at 376d264); only an ASCII column is tested. Quality advisory in `completion-request`.
- Why it matters: pure encoding math sits in an adapter beside protocol code, and a multibyte or non-BMP character before the cursor sends an untested column.
- Fix outline: move it to `Domain::Utf8` beside the other code-unit helpers, with rows for a multibyte and a non-BMP character in `test/domain_utf8.rb`.

## Completion text edits ignore their range

- Where: `candidate_of` in `carat/adapters/json_rpc_language_gateway.rb` (line 519 at 376d264), which takes `textEdit.newText` and drops the edit's range, while the menu replaces only the word from `FuzzyMatch.word_start`. Quality advisory in `completion-request`; the design leaves range edits out of scope.
- Why it matters: an edit whose range starts before the word, such as ruby-lsp's `@ivar` or `Foo::Bar` constant edits, inserts `@@foo` or `Foo::Foo::Bar`.
- Fix outline: use `newText` only when the edit's range starts at the word's start column (else `insertText`, else the label) now; later carry the range in `CompletionItem` and apply it through the `Buffer` primitives, with gateway and editor rows for both edits.

## An incomplete completion answer is never asked again

- Where: `completed` in `carat/adapters/json_rpc_language_gateway.rb` (line 492 at 376d264), which ignores `isIncomplete` and keeps the first `CompletionList::LIMIT` items, and `answer_for?`, which serves that list to every longer word at the same start. Quality advisory in `completion-request`; the design's non-goal.
- Why it matters: a match outside the first 200 items of an incomplete answer is never offered, however much more of the word is typed.
- Fix outline: record `isIncomplete` in `Domain::CompletionRequest` and ask again when the typed part grows past an incomplete answer, with a gateway row.

## The typed part before the cursor is computed twice

- Where: `carat/adapters/json_rpc_language_gateway.rb` (line 463 at 376d264) repeats `ShowCompletion`'s slice, `word_start`, `byteslice`, and `col - length` (`carat/use_cases/completion/show_completion.rb`, lines 74 to 77), and `carat/use_cases/completion/complete_word.rb` line 47 at 8d8832f is a third copy. Quality advisory in `completion-request` and `word-completion`.
- Why it matters: a change to how the word is found must be made in all three places or the request and the menu disagree on the word.
- Fix outline: one domain helper (for example in `FuzzyMatch`) answering the typed part and its start column before a column, used by both, with a table row.

## Completion-request style and docs advisories

- Where: the `result.is_a?(Hash)` guards of `initialized` in `carat/adapters/json_rpc_language_gateway.rb` (lines 417 and 423 at 376d264); the comment of `complete` in the same file (line 441) and the class comment of `carat/doubles/fixed_completions.rb` (line 10), each with a line past the file's wrap; `until_sent` in `test/adapters_server_completions.rb` (line 263), which returns at once because the first request is already sent; the `LanguageServicePort` row of `docs/architecture.md` (line 204), which omits `start`. Quality advisories in `completion-request`.
- Why it matters: `receive` now crashes the server unless the result is a Hash, so the guards are dead and mislead; the long lines break the files' wrap; the test's wait is a no-op and the `10.times` fallback does the waiting; the architecture row disagrees with the port and the map.
- Fix outline: read `result["serverInfo"]` and `result["capabilities"]` directly; rewrap both comment paragraphs; wait until `count_of` reaches 2 with a bounded helper and drop the no-op call; add `start(state)` to the row.

## A check stage can still write the delivery clone by an absolute path

- Where: `clone_make` in `tools/run_state.sh` (the symbolic links to `tmp/.toolchain` and `tmp/.spinel`), and the benchmark's `make metrics` and `make bench` in the delivery clone (`.claude/agents/benchmark.md`). Residual risk of `check-isolation`, reported again in its delivery review as security Medium (6) and Low (5) at `tools/run_state.sh` line 529, and by the periodic security review at cd87445 as Low (5) at the same line (the toolchain links the check clone shares).
- Why it matters: the check clone separates what a stage writes in its own directory, but a process of the same user can find the delivery clone (the toolchain links, the runner's working directory) and write its `.git`, `build/pipeline`, or the shared Spinel binaries the next check and the contributor run; the benchmark still runs branch code in the delivery clone. The origin gate, the guard's refusals, and the green line's url check are the second line.
- Fix outline: run the stages and the benchmark under an operating-system sandbox (a user namespace or another user) with the delivery clone read-only and a private copy of the toolchain, or check the toolchain's hash before each check and run the benchmark in a check clone, each with a `tools/tools_test.sh` case. Queued in `check-runner-safety`.

## merge-gate-integrity's open quality advisories

- Where: at e368486 on the unpushed commits: `tools/gates.sh` line 436 (the gated failures report under an empty or the `pr-body` gate), line 136 (a hosted origin judged by a denylist while `tools/agent_guard.sh` line 347 and `.claude/workflows/deliver-change.js` line 438 use other forms), line 41 (the origin gate's header line stops mid-phrase); `docs/codebase-map.md` line 50 (the `rules.sh` entry lost its separator). Quality advisories in `merge-gate-integrity`.
- Why it matters: a failed gated write names the wrong gate, one origin rule has three diverging definitions, and two documents misread.
- Fix outline: set the gate name before each gated call, keep one allowlist pattern in `tools/rules.sh` used by all three, and repair both lines. Queued in item 45 of `docs/queue.md`, the batch of backlog items.

## The close start's calibration profile is never recorded

- Where: `.claude/workflows/deliver-change.js` line 924, where `records` takes `metricLine()`, before `calibrate('close', ...)` runs at line 928. Quality advisory in `agent-calibration` (reported at lines 915 and 924 across its rounds).
- Why it matters: the close start's line is the run's last metric line, so `metric.calib.close` never reaches the run state or the history's calibration column, unlike the design's profile recorded for every kind started; the close start's tier and effort cannot be compared against its outcome.
- Fix outline: build the close start's options with `calibrate('close', ...)` before computing `records`, and pass the built options to `agent`, with a `tools/tools_test.sh` case that the close profile is in the record line.

## The calibration reasons miscount the cheap-tier starts

- Where: `docs/goals.md` line 34, the calibration's reasons. Quality advisory in `agent-calibration` (reported at lines 187 and 34 across its rounds).
- Why it matters: the reasons say "the four with an agent file on the cheap tier" after listing six mechanical starts of which only three (checker, benchmark, merger) have an agent file; the fourth cheap start, the scouts, is not in the list, so the rule misreads.
- Fix outline: say "the three with an agent file", or add the scouts to the list of mechanical starts.

## check-isolation's open quality advisories

- Where: `README.md` line 180, the checker sentence; `openspec/changes/archive/2026-11-07-check-isolation/design.md` line 53, the Risks bullet; `passedAt` in `.claude/workflows/deliver-change.js` line 482; the header comment of `tools/agent_guard.sh` lines 28 to 40. Quality advisories in `check-isolation`; its `tools/gates.sh` line 436 and `docs/codebase-map.md` line 50 advisories are those of `merge-gate-integrity` above.
- Why it matters: the README says branch code cannot write the hooks, git configuration, or run states the gates read, while the design and the entry above record that it still can by an absolute path; the archived Risks bullet still calls the clone the longer-term fix it now is; `passedAt` names a phase record's commit `result` and compares `result === head`, which reads as a bug; one header line runs far past the comment's width.
- Fix outline: say "through the paths it is given" in the README as the design does; leave the archived design as the record and point the next design at the absolute-path residual risk; name the parts `first` and `second` or split the phase and review comparisons; rewrap the header comment. Queued in `check-runner-safety`.

## A gate after a failed one prints its ok line

- Where: `tools/gates.sh` line 122 at cd87445: each gate takes `start=$failed` and prints ok unless `failed` changed, while `bad` sets `failed=1`. Periodic quality at cd87445.
- Why it matters: after one gate of a group (pre-push, merge) fails, every later gate prints ok even when it also failed, so the output contradicts itself and hides a second failure.
- Fix outline: count failures in `bad` or keep a per-gate flag, with a `tools/tools_test.sh` case of two failing gates. Queued in `merge-gate-tidy`.

## The completion layer is looked up twice per key and ShowCompletion runs twice per typed character

- Where: `carat/use_cases/handle_key.rb` line 166 at cd87445 (`completion_key?` at line 201, then `complete` at line 208, each allocating `[code]`; `insert_literal` line 313, then `call` line 102). Periodic quality at cd87445, again after 5722559.
- Why it matters: two lookups and two popup refreshes per key on the insert hot path, the line sliced twice.
- Fix outline: look up once and dispatch that match; run ShowCompletion once per key, and ShowCompletionDocs with it, which `completion-docs` added beside it and which also runs twice per typed character (quality advisory in `completion-docs` at `carat/use_cases/completion/show_completion.rb` line 72 at 925d759). Queued in `completion-tidy`.

## The map's area 8 omits the completion popup

- Where: `docs/codebase-map.md` line 236 at cd87445: area 8's What and Flow lines never mention the six popup files (lines 257 to 265), its Designs line (269) omits `completion` and `completion-request`, its Bench line names no completion scenario. Periodic quality at cd87445, again after 5722559.
- Why it matters: a change to the popup finds neither its flow nor its decisions in the map.
- Fix outline: name the popup in What, add one Flow sentence and the two designs, or move the completion files to an area of their own. Queued in `completion-tidy`.

## CompletionMenu cleans every candidate the gateway already cleaned

- Where: `carat/domain/completion_menu.rb` line 57 at cd87445 (`fill` runs `CompletionItem.from_source` over items `json_rpc_language_gateway.rb` line 521 built with it). Periodic quality at cd87445.
- Why it matters: up to 200 items are cleaned twice per new word, two boundaries owning one rule.
- Fix outline: clean at one boundary, the doubles doing the same. Queued in `completion-tidy`.

## CompletionList#add returns a bool nobody reads

- Where: `carat/domain/completion_list.rb` line 21 (`add`), the `add` exemption in `test/lint.rb` line 222, which `BOOL_COMMANDS` gives for `FloatLayer`, and the caller `carat/adapters/json_rpc_language_gateway.rb` line 595, which re-checks `LIMIT` at line 592, at 31919d9. Periodic quality at cd87445 and 847851d. Queue item `completion-tidy`.
- Why it matters: an unread result invites a caller to rely on it and hides behind an exemption whose reason is about floats.
- Fix outline: break on a false `add` and drop the gateway's check, or make `add` return nothing, and word the exemption for what remains.

## CompletionPort carries the server source's request record

- Where: `carat/ports/completion_port.rb` line 29 at cd87445 (`request`), `carat/doubles/fixed_completions.rb` line 50, and `carat/adapters/server_completions.rb` line 23, which builds the shared `Domain::CompletionRequest`. Periodic quality at cd87445; related to the entry on the input controller reaching through ShowCompletion.
- Why it matters: the double carries a record nobody fills, and the one shared record is built inside an adapter instead of once beside the other shared objects.
- Fix outline: build the record once at the composition root, keep it in an assembly reader for its users, and drop it from the port; `completion-docs` deepened it, since `ShowCompletion` (`carat/use_cases/completion/show_completion.rb` line 72 at 925d759) and `InputController` now read `request.docs`, so move the documentation state out of the server record with it. Queued in `completion-tidy`.

## The server completions test copies EditorHarness

- Where: `test/adapters_server_completions.rb` line 17 at cd87445 (the `Rig` class copies `type`, `wait`, and `pump` because `carat/doubles/editor_harness.rb` line 38 hard-wires `FixedCompletions`), and its `CompletionRequest` record table (lines 154 to 173). Periodic quality at cd87445. At c1b3a12 there are three rig copies: `test/adapters_signature.rb` line 17, `test/adapters_hover.rb`, and `test/adapters_server_completions.rb` (periodic quality); at 7711421 four, with `test/editor_breadcrumbs.rb` line 24 (note 34). At 2ccf124 seven test files declare `class Rig`, `test/adapters_pathless_language.rb` line 17 among them (quality advisory in `docs-nil-path`).
- Why it matters: two harnesses drift, and a domain record is tested in an adapter test.
- Fix outline: let the harness take any completion port and drive the test through it; move the record table to a domain test. Queued in `completion-tidy`.

## The pathless sync row starts its window after the file type is set

- Where: `test/adapters_pathless_language.rb` line 88 at 2ccf124: the sync row counts the sent methods only from after `:set filetype=ruby` and two idle ticks. Quality advisory in `docs-nil-path`.
- Why it matters: a didOpen sent for the pathless buffer at the first sync after the file type is set falls outside the window, so the row does not prove on its own that the buffer is never opened (a later didChange would still show it).
- Fix outline: take `from = r.processes.bodies.length` before typing `:new<CR>`, so the window covers every sync of the pathless buffer.

## LspStart and LspRestart handlers are copies

- Where: `carat/use_cases/ex/lsp_start_command_handler.rb` line 25 and `lsp_restart_command_handler.rb` line 65 at cd87445, differing only in `start` or `restart`. Periodic quality at cd87445; the restart half is the entry on `LanguageServer#words`.
- Why it matters: a fix to one command misses the other.
- Fix outline: one handler with a start and a restart variant registered twice, as CompletionHandler does. Queued in `lsp-client-tidy`.

## ProcessRunner compiles only through carat.rb's require order

- Where: `carat/drivers/process_runner.rb` line 1 at cd87445 requires only the process port yet builds `Domain::RpcFramer` and `Domain::ServiceMessage`. Periodic quality at cd87445; `carat/drivers/runtime_queue.rb` also builds `Domain::ServiceMessage` without requiring it, still present at b0dd342.
- Why it matters: requiring the file alone fails, unlike DiskFiles, which requires its domain record.
- Fix outline: require both domain files. Queued in `lsp-client-tidy`.

## The bench scenario list has drifted from the scenarios

- Where: `bench/run.sh` line 69 at cd87445 copies the `SCENARIOS` of `bench/keys.rb` line 104 and omits `lh-float`, `lh-winbar`, and `n` (`file-finder` added `finder` to it). Periodic quality at cd87445, refreshed at 8d8832f; folded into `docs-index`.
- Why it matters: `make bench` never runs area 13's float benchmark or `n`, so a regression there goes unmeasured.
- Fix outline: take the names from the bench binary or one shared list, with a case that every scenario runs. Queued in the backlog items worth a change.

## The completion resolve timeout restarts with every pick

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 562 at 925d759 (558 at d46ecff), which measures the resolve timeout from `docs.due`, which a new pick resets. Quality advisory in `completion-docs`, raised again at d46ecff. At c1b3a12 the cursor's screen row is recomputed at seven sites (periodic note at `carat/use_cases/completion/show_completion.rb` line 167), the hover and signature floats included.
- Why it matters: every new pick during the flight moves `docs.due` forward, so a server that never answers is not cancelled while the selection keeps moving.
- Fix outline: keep the send time (or a deadline) of the request in flight and time it out from that, with a case in `test/adapters_server_completions.rb` that keeps moving the selection. Queued in `completion-docs-tidy`.

## ServerCompletions#documentation records the pick inside a query

- Where: `documentation` in `carat/adapters/server_completions.rb` line 50 at 925d759, which sets `docs.pick` and which `ShowCompletionDocs` calls on every key. Quality advisory in `completion-docs`.
- Why it matters: a command hidden in a reader makes the port's contract misleading and the call order load-bearing.
- Fix outline: split it into a `pick(list, index)` command and a `documentation` query, or name it for both, and update `CompletionPort` and `FixedCompletions`. Queued in `completion-docs-tidy`.

## ShowCompletionDocs recomputes the cursor's screen row

- Where: `carat/use_cases/completion/show_completion_docs.rb` line 88 at 925d759, which computes the row as `ShowCompletion#row_offset` does, and takes `below = popup.row > 0`, and line 102, which computes the column through `DisplayWidth.column` where `ArrangeView#place_floats` uses the line cache. Quality advisory in `completion-docs`, raised again at d46ecff. At c1b3a12 the cursor's screen row is recomputed at seven sites (periodic note at `carat/use_cases/completion/show_completion.rb` line 167), the hover and signature floats included.
- Why it matters: the two copies and the sign convention couple the documentation float to the popup's layout, so a change to one silently misplaces the other.
- Fix outline: derive the documentation float's vertical placement from the popup spec alone (row and height), or share one helper for the cursor's screen cell with `ArrangeView` and `ShowCompletion`. Queued in `completion-docs-tidy`.

## The gateway repeats the markdown size limit as a literal

- Where: `DOCUMENT_LIMIT` in `carat/adapters/json_rpc_language_gateway.rb` line 60 at 925d759 repeats `MarkdownText::RAW_LIMIT` (16_384). Quality advisory in `completion-docs`.
- Why it matters: two literals for one bound drift apart when one is changed.
- Fix outline: use `Domain::MarkdownText::RAW_LIMIT` in the gateway, or say in a comment why the two differ. Queued in `completion-docs-tidy`.

## The architecture's RequestDefinition line was reworded out of scope

- Where: `docs/architecture.md` line 180 at 925d759, reworded by `completion-docs` with no connection to completion documentation. Quality advisory in `completion-docs`.
- Why it matters: an unrelated rewording widens the change and hides what the architecture said before.
- Fix outline: restore the original sentence and keep only the `CompletionPort` and `ShowCompletionDocs` edits. Queued in `completion-docs-tidy`.

## CompletionMenu#chosen repeats the chosen index

- Where: `chosen` in `carat/domain/completion_menu.rb` line 88 at 925d759, which repeats `matches[selected]` beside the new `chosen_index`. Quality advisory in `completion-docs`.
- Why it matters: two spellings of the same choice can drift.
- Fix outline: answer `candidates.at(chosen_index)`. Queued in `completion-docs-tidy`.

## The resolve cases repeat their setup three times

- Where: `test/adapters_server_completions.rb` line 384 at e1a647c: the two cancellation cases repeat the resolve case's setup (a rig with `resolveProvider`, type `ifi`, answer three described items, `<C-n><C-n>`, wait for `completionItem/resolve`). Quality advisory in `completion-docs`.
- Why it matters: a change to the resolve flow has to be made three times in the test.
- Fix outline: extract a helper such as `resolving(r)` returning the rig with a resolve in flight, beside `completing`. Queued in `completion-docs-tidy`.

## Completion resolve state outlives a switch of completion language

- Where: `complete` in `carat/adapters/json_rpc_language_gateway.rb` line 498 at d46ecff, which sets `ask.language` to the new request's server but leaves `@items` and `docs` alone, and `resolve`, `cancel_resolve`, and the answer match (lines 552 to 558), which read `@completion.language`. Low (3) finding of the security review of `completion-docs`, and a quality advisory there.
- Why it matters: after a completion request for a file of another type, a pending pick can send server A's raw completion item to server B as `completionItem/resolve`, the `$/cancelRequest` for A's request id reaches B, and A's real answer is dropped; a minor cross-server leak between servers that can already read the workspace, plus a misrouted cancel.
- Fix outline: record the answer's language in `CompletionDocs` in `completed` and use it for `resolve`, `cancel_resolve`, and the answer match, or call `cancel_resolve` then clear `docs` and `@items` in `complete` before `ask.language` changes; add a case in `test/adapters_server_completions.rb` that completes in two file types with a resolve in flight. Queued in `completion-docs-tidy`.

## A server crash during a resolve has no test

- Where: `forget_completion` in `carat/adapters/json_rpc_language_gateway.rb` line 455 at d46ecff, which now resets `docs.sent_id` and drops the language from `@resolvers`. Quality advisory in `completion-docs`.
- Why it matters: the crash path of the resolve flow can regress, leaving `waiting?` true or sending a resolve to a restarted server, without a test failing.
- Fix outline: in `test/adapters_server_completions.rb`, crash the server while a resolve is in flight and assert `waiting?` is false and no resolve is sent after. Queued in `completion-docs-tidy`.

## The tools test's wait for the runner's stage fails silently

- Where: `tools/tools_test.sh` line 323 at d46ecff, the loop that waits for `stage.slow` to read `running` before superseding the runner. Quality advisory in `completion-docs`.
- Why it matters: after 20 tries the loop falls through, so a slow runner surfaces as an unrelated supersede failure.
- Fix outline: fail with a message naming the stage when `stage.slow` never reads `running`. Queued in `check-runner-safety`.

## The documentation floats copy the widest-row loop

- Where: `carat/use_cases/docs/show_hover.rb` line 84 at 78078ad, a copy of `carat/use_cases/completion/show_completion_docs.rb` line 98 and of `carat/domain/operators.rb` line 139. Quality advisory in `quick-docs`.
- Why it matters: the float width is computed three ways, so a fix for wide or combining characters lands in one float only.
- Fix outline: a `DisplayWidth.widest(rows)` helper used by both floats and the operator, with the hover and completion-docs rows unchanged.

## The K tests are one scripted sequence

- Where: `test/adapters_hover.rb` line 176 at 78078ad. Quality advisory in `quick-docs`.
- Why it matters: CLAUDE.md asks a Neovim command for a table-driven test; the hover contents shapes are covered only along one script, so a new shape or a regression in one is hard to add or see.
- Fix outline: drive the contents shapes (string, markup, language pair, list, null, error) and their expected rows from a table converted with typed helpers.

## Hover paths in the spec or the code have no test

- Where: `test/adapters_hover.rb` line 232 at 78078ad, the cancellation block; `forget_server` (the hover ask) and the `hoverProvider` check in `carat/adapters/json_rpc_language_gateway.rb`, and the float's close in `carat/use_cases/docs/show_hover.rb`. Quality advisory in `quick-docs`.
- Why it matters: `forget_server` (the hover ask) on a crash or stop with a hover in flight, `hoverProvider` given as an object, and the float closing on `:q`, a window switch, or a buffer change can regress without a test failing.
- Fix outline: add those cases beside the cancellation block.

## Plaintext hover text is read as markdown

- Where: the MarkupContent reader in `carat/adapters/json_rpc_language_gateway.rb` line 706 at 78078ad. Quality advisory in `quick-docs`.
- Why it matters: a MarkupContent of kind `plaintext` is passed to `MarkdownText` as markdown, so underscores, asterisks, and backslashes in plain hover text (identifiers such as `snake_case_name`) are taken as markup; the client advertises `plaintext`, so a server may answer with it.
- Fix outline: wrap a `plaintext` value in a fence before `MarkdownText` reads it, with a row in the hover contents table.

## The hover-docs spec and the code place the float differently

- Where: the placement in `carat/use_cases/docs/show_hover.rb` line 76 at 78078ad, and the placement requirement of `openspec/specs/hover-docs/spec.md`. Quality advisory in `quick-docs`.
- Why it matters: the code puts the float above when below lacks the rows and above has more, while the spec says above only when only above has the room; the spec no longer tells a reader what the editor does.
- Fix outline: align the spec wording with the code through a proposal, with a row for each placement.

## CLAUDE.md cites the wrong architecture section for concerns

- Where: the concerns bullet of Coding conventions in `CLAUDE.md` (line 247 at 78078ad) cites `docs/architecture.md` section 5.4, but the concerns rule is the last bullet of section 5.3 (`docs/architecture.md` line 184). Quality advisory in `quick-docs`.
- Why it matters: an agent following the citation reads the wrong section and misses the concerns rule.
- Fix outline: cite section 5.3 in `CLAUDE.md`, or move the concerns bullet under 5.4.

## The architecture's hover sentence reads as a wait for idle

- Where: `docs/architecture.md` line 181 at 78078ad, "sends RequestHover's ask and reads the answer when idle". Quality advisory in `quick-docs`.
- Why it matters: it reads as if the answer waits for idle, while the gateway sends the ask at the next idle tick and reads only the answer to the request in flight.
- Fix outline: reword it to "which sends RequestHover's ask at the next idle tick and reads only its answer".

## The hover poll keeps a return that never fires

- Where: `return if ask.sent == ask.want` in `carat/adapters/json_rpc_language_gateway.rb` line 646 at 41297d6. Quality advisory in `quick-docs`.
- Why it matters: after the in-flight block the equal case has already returned, so the line is dead and suggests a path the poll does not have.
- Fix outline: drop the line, with the hover rows of `test/adapters_hover.rb` unchanged.

## A key resolved by timeoutlen runs no follow tail

- Where: `HandleKey#timeout` in `carat/use_cases/handle_key.rb` (line 122 at 41297d6, line 154 at b76b722) and the comment of `carat/use_cases/discovery/hide_key_hints.rb` line 7. Quality advisories in `quick-docs` and `discoverability`, periodic quality at c1b3a12, b76b722, and 3895e21, which merged the two entries. Queue item `discoverability-tidy`.
- Why it matters: `call` ends with an after-key tail (`ShowCompletion`, `FollowHover`, `FollowDefinition`, `FollowSignature`, `FollowPalette`, `HideKeyHints`, the plugin observe, `ArrangeView`) that `timeout` copies only in part (it skips `FollowDefinition`, `handle_key.rb` line 181 at 8d8832f), so an action resolved by `timeoutlen` leaves the documentation float open away from the cursor until the next key, `palette.open` bound beside a longer user binding (`<leader>p` with `<leader>pf`) opens the `>` prompt with no list until the next key, and the `HideKeyHints` comment says a timeout closes the hints, which it never does.
- Fix outline: one private follow step that both `call` and `timeout` end with, a row in `test/adapters_hover.rb` that moves the cursor through a timed-out prefix, a row in `test/editor_palette.rb` that opens the palette through a timed-out user binding, and a corrected `HideKeyHints` comment.

## The hover placement counts rows with bare numbers

- Where: `below = state.screen_rows - 4 - screen_row` and `above = screen_row - 2` in `ShowHover#open`, `carat/use_cases/docs/show_hover.rb` line 72 at 41297d6. Quality advisory in `quick-docs`.
- Why it matters: the 4 and the 2 are the float's two border rows and the status and command lines, which a reader has to reconstruct, and a change to the bars or the border would miss them.
- Fix outline: name them (a `BORDER` of 2 and the rows the bars take) in private constants, or say so in a comment.

## The hover float above the cursor and a refused pin have no test

- Where: `ShowHover#open`'s `up` branch in `carat/use_cases/docs/show_hover.rb` and `PinHover` in `carat/use_cases/docs/pin_hover.rb`; the tests are `test/adapters_hover.rb` line 176 at 41297d6. Quality advisory in `quick-docs`; the crash with a hover in flight is the entry Hover paths in the spec or the code have no test.
- Why it matters: the float placed above the cursor and a split refused for lack of room, which must keep the float, can regress without a test failing.
- Fix outline: add a case with the cursor on the last screen rows and one pressing the pin key in a window too small to split.

## A pipeline fix rode in the hover pull request

- Where: the `runner_finish` fix in `tools/run_state.sh` line 697 at 41297d6 (commit 13de267, with its `tools/tools_test.sh` case), on `feature/quick-docs`. Two quality advisories in `quick-docs`.
- Why it matters: CLAUDE.md asks one logical change and one type per squash commit; the CI fix the branch needed is a `fix` of the tooling inside a `feat` pull request, so its history is hidden under the hover change. The pull request's Notes name it as that CI fix.
- Fix outline: when a CI fix touches tooling outside the change, deliver it as its own change ahead of the feature, or have the push step name it in the pull request's Notes as this one does.

## The cases gate passes every changed tool script on one added case

- Where: `gate_cases` in `tools/gates.sh` (line 242, the check at line 253 at 4f653d2) and its comment, which say a case per script, and the row in `README.md` line 40 that says a case for every changed tool script. Two quality advisories in `implement-contracts`.
- Why it matters: the gate names the changed scripts one by one, but one added `expect` line for any script satisfies all of them, so a branch changing `gates.sh` and `run_state.sh` passes with only a gates case, and the README and the comment promise more than the gate checks.
- Fix outline: for each changed script require an added `expect` line whose command word is the script's basename, with a case in `tools/tools_test.sh`; or reword the README row and the comment to an added case when a tool script changes.

## The holder check counts every assembly reader type as shared

- Where: the `shared` list in `test/lint.rb` line 946 at 4f653d2, which takes the type of every `EditorAssembly` reader. Two quality advisories in `implement-contracts`.
- Why it matters: generics count too (`config_errors` is `Array[String]`), and a namespaced generic such as `Array[Domain::X]` is cut to `X]`, so a holder reader typed `Array[String]` would be demanded a row in `test/adapters_assembly.rb` as if it were a shared object.
- Fix outline: keep only types with a home class under `carat/` (the `homes` the check already builds), or skip types containing a bracket, with a lint case.

## The holder check matches a reader with no right boundary

- Where: the `.holder.reader` substring match in `test/lint.rb` line 735 at 4f653d2. Quality advisory in `implement-contracts`.
- Why it matters: a reader counts as checked when the assembly test names a longer reader with the same prefix (`.handle_key.command_line` inside `.handle_key.command_line_x`), so a missing holder row can pass.
- Fix outline: require a non-word character (or the end of the line) after the match, with a lint case for the prefix.

## Two lint checks parse constructor keywords with copied slicing

- Where: `holder_problems` in `test/lint.rb` line 719 and `constructor_problem` at line 365 at 4f653d2, both slicing `stripped[15, ...]` after `def initialize(`. Quality advisory in `implement-contracts`.
- Why it matters: the parser is copied with a bare 15, and both read only one-line constructors, so a fix to one misses the other and a wrapped signature is skipped silently.
- Fix outline: one `keyword_names(stripped)` helper both call, the 15 spelled as the prefix's length.

## Two assembly test labels name too few holders

- Where: the labels `the last search, in the searches and the substitute` and `the search history, in the searches and the substitute` in `test/adapters_assembly.rb` lines 103 and 104 at 4f653d2. Two quality advisories in `implement-contracts`.
- Why it matters: the rows now also check the command line, the prompt, and the frame presenter, so the labels mislead a reader of a failure.
- Fix outline: shorten them to `the last search` and `the search history` and rewrite the snapshot with `make snapshots`.

## Parameter info follows a call on one row only

- Where: `FollowSignature` in `carat/use_cases/docs/follow_signature.rb` and `SignatureRequest.open_paren` in `carat/domain/signature_request.rb` (`parameter-info`): the call is the innermost `(` left open before the cursor on its row, scanned as plain bytes.
- Why it matters: a call whose arguments span several rows closes the float at the first line break, and a `(` inside a string or comment can start a follow the server then answers empty.
- Fix outline: keep following across rows while the server answers a signature (stop on an empty answer rather than on a row change), and skip strings and comments with the syntax cache's tokens when the buffer has them, with rows in `test/adapters_signature.rb`.

## The signature request is passed beside the use case that holds it

- Where: the `signature:` keyword of `HandleKey` in `carat/use_cases/handle_key.rb` line 88 and of `InputController` in `carat/adapters/input_controller.rb` line 48 at c59a43d, while the same constructors read the hover request from its use case (`follow_hover.hover`, `show_hover.hover`). Quality advisory in `parameter-info`.
- Why it matters: two ways to reach the same kind of shared request in one constructor, so a reader cannot tell which is the rule; the hover entry above asks the opposite direction for hover, so both should end the same way.
- Fix outline: settle one way for hover and signature together: either drop the `signature:` keywords and read `follow_signature.signature` and `show_signature.signature`, removing their two assembly rows, or pass both requests from `EditorAssembly` as the hover entry proposes.

## The signature float's placement below the cursor is untested

- Where: `ShowSignature` in `carat/use_cases/docs/show_signature.rb` line 66 at c59a43d, which puts the float below the cursor (row 1) when the cursor's screen row is under 3; `test/adapters_signature.rb` has no row for it. Quality advisory in `parameter-info`.
- Why it matters: a regression in the below-the-cursor branch, the one taken on a window's first rows, would pass every test.
- Fix outline: add a row typing `(` on the window's first screen row and assert the bordered float drawn below the cursor.

## The signature gateway's forget and activeSignature paths are untested

- Where: `forget_server` (the signature ask, `forget_signature` before periodic-blockers-a) in `carat/adapters/json_rpc_language_gateway.rb` line 743 (dropping the language and the request in flight on a crash, `:LspStop`, or `:LspRestart`) and the in-range `activeSignature` choice at line 818, at c59a43d. Quality advisory in `parameter-info`.
- Why it matters: a server crash with a signature request in flight, or a server that names a later signature as active, takes a path no test runs, so a stale request or the wrong signature could ship unnoticed.
- Fix outline: add rows to `test/adapters_signature.rb` for a server crashing while a signature request is in flight and for an answer with `activeSignature` 1 of two signatures.

## Roadmap item 10 lost the changes that delivered it

- Where: item 10 of the roadmap in `docs/architecture.md` line 405 at c59a43d, which now reads `Delivered but go-to-definition (map).`. Quality advisory in `parameter-info`.
- Why it matters: the other items keep the changes that delivered them, this one drops `lsp-diagnostics` and `diagnostics-display`, and `(map)` does not say what it points to.
- Fix outline: restore the delivering changes, add `completion`, `quick-docs`, and `parameter-info`, and name go-to-definition as what remains.

## K shows an older request's hover answer at the new anchor

- Where: `hovered` in `carat/adapters/json_rpc_language_gateway.rb` line 674 at b0dd342; `test/adapters_hover.rb` covers only an answer arriving after the cancel. Periodic quality, blocking. Queued in `hover-tidy`.
- Why it matters: K at one position, a cursor move, and K again while the first request is in flight: the first answer drained in the next poll before the cancel is marked arrived, so `ShowHover` shows the old position's documentation at the new anchor and keeps it when the new request times out.
- Fix outline: drop an answer whose request is not the one last asked, as the completion path does for its serial, with a hover row queuing the first answer after the second K and before its idle tick.

## The markdown text comment names only completion items

- Where: the module comment of `carat/domain/markdown_text.rb` line 7 at b0dd342. Periodic quality. Raised again at 38628bb (periodic quality). Queued in `hover-tidy`.
- Why it matters: `ShowHover` reads hover contents through it too, so the comment misleads a reader.
- Fix outline: say a completion item's or a hover answer's documentation.

## The hover request holders are reached through other use cases

- Where: `carat/adapters/input_controller.rb` line 81 reads the shared `HoverRequest` through `show_hover.hover`, and `carat/use_cases/handle_key.rb` line 93 through `follow_hover.hover`, at b0dd342. Periodic quality. Queued in `hover-tidy`.
- Why it matters: the holder rule and `test/adapters_assembly.rb` never see these holders, so a second instance would pass.
- Fix outline: pass the request from `EditorAssembly` to both, with readers checked in the assembly test.

## The completion close use case is shared through a local

- Where: `close_completion` in `carat/adapters/editor_assembly.rb` line 336 at b0dd342, shared by `ShowCompletion` (338), `AcceptCompletion` (344), and `CompletionHandler` (413). Periodic quality, blocking. Queued in `completion-tidy`.
- Why it matters: CLAUDE.md asks everything shared to be kept in an assembly reader so the assembly test checks every holder; only `show_completion.close_completion` is checked.
- Fix outline: keep it in a reader and assert that the other two holders hold that one object.

## The documentation float's keep test and close are copied

- Where: the five-condition keep test in `carat/use_cases/completion/show_completion_docs.rb` line 66 reaching four `CompletionMenu` docs members, and `CloseCompletion#call` (`close_completion.rb` line 24) repeating `ShowCompletionDocs#close`, at b0dd342. Periodic quality. Queued in `completion-docs-tidy`.
- Why it matters: a change to when the float is kept or closed must be made in two places.
- Fix outline: one `CompletionMenu` question for the keep test and one owner of closing the docs float, the `floats.index_of` check kept at the call site.

## CompletionMenu's constructor repeats clear

- Where: `carat/domain/completion_menu.rb` lines 37 to 45 against 96 to 103 at b0dd342. Periodic quality. Queued in `completion-docs-tidy`.
- Why it matters: a new member must be reset in two places.
- Fix outline: set the two lists in the constructor, then call `clear`.

## The CI scope asks the same API twice

- Where: the push branch of `tools/ci_scope.sh` lines 47 and 48 at b0dd342. Periodic quality. Queued in `ci-hardening`. At 38628bb the header also omits `docs/metrics.tsv` (`tools/ci_scope.sh` lines 8 and 95, periodic quality), still at 7711421 (header lines 8 to 12, note 47).
- Why it matters: two calls for one commit's head and number double the rate-limited requests and can disagree.
- Fix outline: one call printing both fields, read once.

## A link planted in the check clone's build directory survives

- Where: `clone_drop` in `tools/run_state.sh` line 566 at b0dd342 copies `build/` into the carry with `cp -RP`. Periodic security Low (5). Queued in `check-runner-safety`.
- Why it matters: a symbolic link a stage plants in `build/` reaches `build/stages/CHANGE/carry` and the next clone, so the clone is isolated by environment only.
- Fix outline: drop links from the carry or refuse them when copying, with a case.

## WalkHistory keeps one walk's counts in instance variables

- Where: `@gone`, `@back`, and `@empty_before` in `carat/use_cases/history/walk_history.rb` lines 32, 80, and 109 at b0dd342. Periodic quality. Queued in `search-tidy`.
- Why it matters: the use case is built once in `EditorAssembly`, so state carries between calls and a nested or interrupted walk reads stale counts, the side channel already listed for `Operate`'s notice.
- Fix outline: return the counts from the step or hold them in a record made per call, passed to the finish.

## Walker depends on Motions through require order

- Where: `carat/domain/walker.rb` line 63 calls `Motions.code_class` without requiring `motions.rb`, which requires `walker.rb`, at b0dd342. Periodic quality. Queued in the backlog item batch beside the ProcessRunner entry.
- Why it matters: a hidden require cycle that works only by load order.
- Fix outline: move the class lookup into `Walker` or `Utf8` and call it there from `Motions`, `TextObjects`, and `FindMatch`.

## Two classes declare a collaborator twice or by hand

- Where: `carat/adapters/rc_config_gateway.rb` line 33 (an `attr_reader` with its type beside a `# @rbs @files` line) and `carat/adapters/input_controller.rb` line 96 (a hand-written `decoder` reader) at b0dd342. Periodic quality. Queued in the backlog item batch.
- Why it matters: the pair #77 removed elsewhere; two declarations can drift.
- Fix outline: drop the `@rbs` line and use `attr_reader :decoder`.

## Keymap exposes helpers and the map misses methods

- Where: `apply`, `bind_text`, and `holder_of` in `carat/domain/keymap.rb` lines 141, 162, and 205 are public with no outside caller; `leader_problem` and `no_actions` are missing from the map's `Keymap` entry; the `CommandGrammar` entry (`docs/codebase-map.md` line 146) omits `digit?`, `digit`, `char`, `wants_pattern?`, and `pattern`; the `Paths` list (line 503) omits `absolute` (`carat/plugin_api.rb` line 356), at b0dd342. Periodic quality. Queued in `docs-index`.
- Why it matters: the map is the entry point for every change; missing methods send a reader to the code.
- Fix outline: make the three instance methods private and name the missing methods in their entries.

## Config predicates note problems and repeat the none word

- Where: `language?` and `binding?` in `carat/domain/config.rb` lines 185 and 210 at b0dd342. Periodic quality. Queued in the backlog item batch.
- Why it matters: a predicate with a side effect breaks the naming rule, and `binding?` repeats `Keymap::NONE` and the action-name check.
- Fix outline: answer only, note at the caller, and name the none word once in a domain constant.

## Vim messages are spelled in several files

- Where: E477 in `delete_command_handler.rb` line 34, `substitute_command_handler.rb` line 37, `global_command_handler.rb` line 35; E488 in five files; E486, E492, E32, E33, E363, E474, E939 in two or more, at b0dd342. Periodic quality. Queued in the backlog item batch.
- Why it matters: `docs/architecture.md` section 5 puts a message several use cases need in `Domain::Messages`; copies drift from Neovim's text.
- Fix outline: constants or builders in `Domain::Messages` called from every site.

## A signature parameter label is marked inside the method name

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 835 at c1b3a12, the string-label branch of the signature marking (periodic quality blocking). Queued in `signature-tidy`.
- Why it matters: ruby-lsp sends string labels, and a parameter whose name occurs in the method name is highlighted inside the name (each(e) marks the e of each), so parameter info points at the wrong text.
- Fix outline: search for the label only after the signature's opening parenthesis and after the previous parameter's match, with no mark when absent, and a `test/adapters_signature.rb` row for each(e).

## A signature request in a buffer without a path re-asks on every key

- Where: `carat/use_cases/docs/request_signature.rb` line 24 at c1b3a12; the gateway's send drops a pathless buffer silently. Queued in `signature-tidy`.
- Why it matters: FollowSignature keeps following a call that is never sent, asking again on every key, while RequestHover refuses such a buffer up front.
- Fix outline: refuse a pathless buffer as RequestHover does, with a row typing ( in an unnamed ruby buffer expecting no active signature.

## The signature trigger tests bare key codes

- Where: `carat/use_cases/handle_key.rb` line 336 at c1b3a12. Queued in `signature-tidy`.
- Why it matters: codes 40 and 44 hide the characters the text already holds.
- Fix outline: compare the text with ( and , directly.

## Scratch floats of plain lines are built seven ways

- Where: `carat/use_cases/completion/show_completion.rb` line 151, `carat/use_cases/completion/show_completion_docs.rb` line 106, `carat/use_cases/docs/show_hover.rb` line 86, `carat/use_cases/docs/show_signature.rb` line 66, `carat/use_cases/plugins/window_requests.rb` line 235, at c1b3a12 (periodic quality), and `carat/use_cases/discovery/show_key_hints.rb` line 137 and `carat/use_cases/discovery/follow_palette.rb` line 124 at d828abb (quality advisories in `discoverability`). Queued in `hover-tidy`.
- Why it matters: each builds the same buffer, owner, window, and float steps, so a change to an owned float must be made seven times.
- Fix outline: one alternate constructor of a float from lines, owner, and spec, used by the seven.

## A long insert copies its typed text on every key

- Where: `carat/domain/last_change.rb` line 117 (add_text) and line 137 (add_action) at c1b3a12 (periodic quality). Queued in `insert-copy`.
- Why it matters: each typed key rebuilds the session's typed string, so a long insert costs quadratic bytes on the typing hot path.
- Fix outline: append to a fresh string started per session and hand the '.' register a copy, with a long-insert case and `insert` held at 35.0.

## The generated config header names spin run, and the write step is copied

- Where: `bin/carat-gen-config.rb` line 39 (the header written into `carat/domain/default_config.rb` line 2) and line 48, copied for the registry at line 57, at c1b3a12 (periodic quality). Queued in item 46, generators.
- Why it matters: the header sends readers to a command CLAUDE.md forbids, and the write-only-when-changed block has two copies.
- Fix outline: name make gen-config and regenerate; one write-if-changed helper for both targets.

## The key decoder repeats the letter finals

- Where: `carat/adapters/key_decoder.rb` line 143 (csi_key) against line 186 (ss3_key) at c1b3a12 (periodic quality). Queued in item 46.
- Why it matters: ten finals are listed twice and can drift.
- Fix outline: csi_key keeps 126 and hands every other final to ss3_key.

## end_visual re-implements clamp_col

- Where: `carat/domain/editor_state.rb` line 120 at c1b3a12 (periodic quality), beside the entry Operate and RepeatLast each copy EditorState#clamp_col. Queued in item 46.
- Why it matters: a third copy of the clamp.
- Fix outline: call clamp_col after the mode is set to normal.

## Public helpers no other file calls

- Where: `carat/domain/last_search.rb` line 111 (touch), `carat/use_cases/actions/action_table.rb` line 96 (handler_at), `carat/domain/buffer.rb` line 185 (detect_filetype, named on the map's buffer line), at c1b3a12 (periodic quality). Queued in item 46. At 38628bb also `ExTable#count` and the public `handler_at` (`carat/use_cases/ex/ex_table.rb` lines 99 and 104, periodic quality).
- Why it matters: dead public surface invites callers that bypass the owner.
- Fix outline: move the three under private and drop detect_filetype from the map line.

## Json.pretty_generate has no production caller

- Where: `carat/domain/json.rb` line 36 at c1b3a12, called only by `test/json.rb` (periodic quality). Queued in item 46, dead methods.
- Why it matters: dead code the map lists as part of the JSON-RPC library.
- Fix outline: remove it and its test row, or record why the library keeps it.

## SaveAll branches twice for one assignment

- Where: `carat/use_cases/files/save_all.rb` line 164 at c1b3a12 (periodic quality). Queued in `file-access-tidy`.
- Why it matters: both branches assign the same result and differ only in the failed flag.
- Fix outline: one assignment and one conditional flag.

## Quit copies the close-other-windows loop

- Where: `carat/use_cases/files/quit.rb` line 82 (close_page) against `carat/use_cases/windows/close_other_windows.rb` line 27, at c1b3a12 (periodic quality). Queued in `buffer-list-tidy`.
- Why it matters: two copies of closing every window of a tab page but one.
- Fix outline: one BufferList method both call.

## The README's parameter-info sentence splits a paragraph

- Where: `README.md` line 64 at c1b3a12 (periodic quality). Queued in `docs-index`.
- Why it matters: the sentence follows the raw-mode Ctrl-S note, separating it from the language-service description.
- Fix outline: move it before the raw-mode sentence.

## The merge record trusts the merger's reply fields

- Where: the merge and CI phase records of `.claude/workflows/deliver-change.js`; in `parameter-info` (#78) the reply swapped the pushed head and the squash commit, so 3 phases were recorded at a commit not on main (retrospective). Queued in `merge-gate-tidy`.
- Why it matters: run state and history rows point at the wrong commits, 1 of the last 4 merges.
- Fix outline: take each commit from the run state or git (the squash commit reachable from main, the CI head equal to the pushed head), with a tools_test case feeding a swapped reply.

## The calibration rule counts CI reds caused outside the change

- Where: the Calibration rule of `docs/goals.md`; the retrospective of `parameter-info` (#78). The plan of `discoverability` dropped `scout-effort-revert` by this reading; the goals text waits for the user.
- Why it matters: low-effort scout rows #74 to #78 passed CI first 3 of 5, both reds a timed runner case (`check-runner-safety`), 5 of 5 counting own-diff reds, rework 7 against 7; the literal rule would revert a move that did no harm.
- Fix outline: count only first-pass reds whose recorded cause is in the change's own diff, with the cause recorded in the run state.

## The palette lists and replays unchecked plugin action names

- Where: `carat/use_cases/discovery/open_palette.rb` line 79, which lists every `plugin.<name>.<action>` of an enabled plugin's manifest, and `carat/use_cases/handle_key.rb` line 269, which replays a chosen name that is not an action name as keys, at d828abb. Security Low findings (confidence 3 and 5) in `discoverability`.
- Why it matters: a compiled-in plugin whose manifest fails `ManifestCheck` can declare an action such as `plugin.explorer.:w ~/.bashrc<CR>`, which is listed because the plugin is enabled, and Enter on it types the keys. No new capability, since a plugin can already bind replays in its manifest defaults, but the palette should only ever dispatch actions.
- Fix outline: build the plugin entries from a registry method returning the enabled plugins' checked action names (only those for which `Domain::Keymap.action_name?` holds), and in `HandleKey` dispatch the palette's chosen name only when `Domain::Keymap.action_name?` holds, never through replay, with a row in `test/editor_palette.rb` for a refused name.

## OpenPalette re-parses plugin action names

- Where: `plugin_of` in `carat/use_cases/discovery/open_palette.rb` line 91 against `PluginRouter` line 36, and the one-line single-use `palette_add_plugin` at line 85, at d828abb. Quality advisories in `discoverability`. Raised again at 38628bb and b76b722 (periodic quality); a second entry for `palette_add_plugin` was folded in here at 186ddfb. Queued in `discoverability-tidy`.
- Why it matters: two parsers of `plugin.<name>.<action>` can drift, and the wrapper adds a hop for one call.
- Fix outline: have `PluginRegistry` return the enabled plugins' action names (the same method the palette entry above needs) and inline `@palette.add` into `add_plugin_actions`.

## KEYHINTS_DELAY is never read

- Where: `carat/domain/options.rb` line 72 at d828abb; `initialize` (line 56) repeats the literal 300. Quality advisory in `discoverability`, raised twice. Raised again at 38628bb (periodic quality). Queued in `discoverability-tidy`.
- Why it matters: a constant beside a duplicated literal invites changing one and not the other.
- Fix outline: use `KEYHINTS_DELAY` in `initialize`, or drop the constant.

## ShowKeyHints copies HideKeyHints' close

- Where: `carat/use_cases/discovery/show_key_hints.rb` line 56 at d828abb. Quality advisory in `discoverability`. Raised again at 38628bb (periodic quality). Queued in `discoverability-tidy`.
- Why it matters: two copies of closing the hints float drift when the float's lifecycle changes.
- Fix outline: have `ShowKeyHints` call `HideKeyHints` instead of holding `close_float`.

## Three discovery comments are stale or break their wrap

- Where: the class comment of `carat/use_cases/discovery/hide_key_hints.rb` (line 8), the class comment of `carat/use_cases/discovery/show_key_hints.rb` (line 23, longer than its neighbors), and the comment at `carat/use_cases/handle_key.rb` line 66 (breaks after "While the"), at d828abb. Quality advisories in `discoverability`. Raised again at 38628bb (periodic quality). Queued in `discoverability-tidy`.
- Why it matters: the first says a binding resolved by `timeoutlen` closes the hints, but `timeout` never calls `HideKeyHints` and the hints never show over a `:pending` key; the others are style only.
- Fix outline: drop the clause from the `HideKeyHints` comment and rewrap the other two to the width of the lines around them.

## Ex command descriptions live apart from their registrations

- Where: the description hash of `carat/use_cases/ex/ex_table.rb` line 20 at d828abb. Quality advisory in `discoverability`. Raised again at 38628bb (periodic quality), which also notes that no test checks every ex command has a description (`ex_table.rb` line 19). Queued in `discoverability-tidy`.
- Why it matters: unlike `ActionTable.register`, which takes the description, each new ex command is edited in two places.
- Fix outline: pass the description to `ExTable#register` from each handler's `register` and drop the hash.

## The palette runs ex commands that need an argument bare

- Where: `carat/use_cases/execute_command_line.rb` line 91 at d828abb. Quality advisory in `discoverability`.
- Why it matters: picking `:edit`, `:buffer`, `:substitute`, or `:set` in the palette runs it without an argument and only reports an error.
- Fix outline: for a command that takes an argument, leave `:name ` on the command line instead of running it, with a row in `test/editor_palette.rb`, or note the behavior in `docs/compatibility.md`.

## A disabled plugin's group names stay in the keymap

- Where: `name_group` in `carat/domain/keymap.rb` line 285 at d828abb. Quality advisory in `discoverability`.
- Why it matters: the group name ignores the line's owner, so `remove_owner` keeps a disabled plugin's group names and a prefix it shared still shows that title over the key hints.
- Fix outline: record the owner with each group name and drop it in `remove_owner`, or refuse `keymap.group` from a plugin, with a row in `test/editor_key_hints.rb`.

## The discovery tests copy their session helper

- Where: `plugin_session` in `test/editor_key_hints.rb` line 27 and in `test/editor_palette.rb` line 21, each repeating its file's `session` but for the plugin list, and the magic slice `row_of(...)[0, 55]` in `test/editor_palette.rb` line 96, at d828abb. Quality advisories in `discoverability`.
- Why it matters: two copies of the same setup drift, and a slice at a counted width breaks silently when a description changes.
- Fix outline: give each `session` a `plugins` argument (`plugins: []` at the existing rows) and drop `plugin_session`; assert `start_with?` on the expected prefix, or compare the whole rstripped row.

## The architecture's group example names a bound prefix

- Where: `docs/architecture.md` line 230 at d828abb, the section 7 example. Quality advisory in `discoverability`.
- Why it matters: the example names `keymap.group <leader>w windows` while the same example binds `keymap.normal <leader>w :w<CR>`, so that prefix is bound and its hints never show, since a bound prefix resolves by `timeoutlen`.
- Fix outline: name a group for an unbound prefix in the example, such as `keymap.group <leader>f files`.

## A plugin prompt opened over the command palette is answered by the palette

- Where: `carat/use_cases/execute_command_line.rb` line 57 and `UiRequests#prompt` in `carat/use_cases/plugins/ui_requests.rb` line 64, at 38628bb (periodic security Low (3)). Queued in `discoverability-tidy`.
- Why it matters: with the palette active, Enter runs the palette's selected entry, an ex command or action matched by the prompt's text, instead of answering the prompt, and the prompt stays open in normal mode.
- Fix outline: refuse a prompt while the palette is active or close the palette first, with a row in `test/editor_palette.rb`.

## Palette resets its members in two places

- Where: `carat/domain/palette.rb` lines 31 and 55 at 38628bb (periodic quality). Queued in `discoverability-tidy`.
- Why it matters: `initialize` and `start` reset the same members, so a new member must be reset twice.
- Fix outline: one private reset called by both.

## The plugin prompt request names a local e

- Where: `carat/use_cases/plugins/ui_requests.rb` line 92 at 38628bb (periodic quality). Queued in `discoverability-tidy`.
- Why it matters: the naming rule forbids unclear abbreviations.
- Fix outline: rename it entry.

## Signature help reads the cursor column as a byte index

- Where: `open_paren` in `carat/domain/signature_request.rb` line 147, and the row at `test/domain_signature_request.rb` line 41, at 38628bb (periodic quality blocking). Queued in `signature-tidy`.
- Why it matters: the column is a character index, so with multibyte text before the `(` the scan starts left of the cursor and signature help never starts; the test row passes a byte column the editor never gives.
- Fix outline: convert the column to its byte offset before scanning, keep one unit, and add rows with multibyte text before the `(` at the character column.

## The gateway times out requests two ways

- Where: `carat/adapters/json_rpc_language_gateway.rb` lines 523 and 604 (completion and resolve cancel at due plus a limit) against 662 and 768 (hover and signature keep a deadline), at 38628bb (periodic quality). Queued in `lsp-client-tidy`.
- Why it matters: the 1,127-line class grows a send, cancel, and answer path per request kind, and the next kind (`breadcrumbs`, `definitions`) adds a third copy.
- Fix outline: one deadline per request record set when sent, and one shared send, cancel, and timeout path.

## The explorer's help restates its keymap

- Where: `HELP` in `carat/plugins/explorer/plugin.rb` line 16 against its keymap at line 541, at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: a changed key leaves the `?` message wrong.
- Fix outline: build the help from the keymap lines once, or let `?` show the key hints.

## Command has methods but no member pins

- Where: `carat/domain/command.rb` line 12, worked around in `Operate#big?` at `carat/use_cases/operate.rb` lines 187 to 189, at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: the unpinned action forces a `.to_s` and a comment at its caller.
- Fix outline: pin each member and drop the workaround.

## LastChange#resumed? changes state

- Where: `carat/domain/last_change.rb` line 175 at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: the predicate resets `next_visual`, starts a recording, and sets `recording`, against the rule that a predicate answers a question.
- Fix outline: a resume step called by `add_text` and `add_action`, and a plain recording check.

## ci" on an empty string fails

- Where: the inner quote object in `carat/domain/text_objects.rb` line 356 at 38628bb (periodic quality). In the backlog items of the queue.
- Why it matters: on `""` Neovim enters insert between the quotes; carat fails, and `docs/compatibility.md` lists no difference.
- Fix outline: return the empty range after the opening quote, with an `editor_text_objects` row.

## A # search history entry is cut at its ?

- Where: `VimPattern.escape` in `carat/domain/vim_pattern.rb` line 111, fed by `FindMatch#word` at `carat/use_cases/search/find_match.rb` line 119, at 38628bb (periodic quality). Queued in `search-tidy`.
- Why it matters: the non-keyword text of `#` or `g#` enters the history with `?` unescaped and, recalled at a `?` prompt, is cut there.
- Fix outline: escape the delimiter of the direction, with an `editor_search` row.

## VimPattern and Search repeat a list and a test

- Where: `carat/domain/vim_pattern.rb` line 22 (the escapes listed twice) and `Search.action?` in `carat/domain/search.rb` line 42 (a prefix test every listed name passes), at 38628bb (periodic quality). Queued in `search-tidy`.
- Why it matters: each restates what the next line already says.
- Fix outline: drop the repeated list and one of the two tests.

## The Makefile's header, compile recipes, and docs-lint help drift

- Where: `Makefile` line 3, the compile recipe at lines 221, 255, and 312, and the docs-lint help at line 359, at 38628bb (periodic quality). Queued in `run-budgets-tidy`.
- Why it matters: the header says every target wraps spin or OpenSpec while seven call spinel; three targets copy one timing recipe; the help omits the queue budget and check.
- Fix outline: correct the header, one recipe for the three, and name the queue budget in the help.

## metrics compare passes a strict metric missing from the run

- Where: `compare` in `tools/metrics.sh` line 86 at 38628bb (periodic quality). Queued in `run-budgets-tidy`.
- Why it matters: only the current names are walked, so an `allocs.*` or `rounds.*` name of the base that the run lacks passes, against the header's rule.
- Fix outline: fail each strict base name not seen, with a `tools/tools_test.sh` case.

## The runner's wait is longer than it says, in two copies

- Where: `runner_finish` in `tools/run_state.sh` line 698 and `check_wait` at line 646, at 38628bb (periodic quality). Queued in `check-runner-safety`.
- Why it matters: the 30-second wait is 150 pauses, 150 seconds where a pause falls back to one second, and the loop is copied.
- Fix outline: one wait helper bounded by elapsed seconds, used by both.

## A run_state.sh paragraph splits its Usage list

- Where: `tools/run_state.sh` lines 63 to 66 at 38628bb (periodic quality, raised twice). Queued in `run-budgets-tidy`.
- Why it matters: the paragraph on refused keys sits between the set and phase entries.
- Fix outline: move it above or below the list.

## The map's palette lines drift from the code

- Where: `docs/codebase-map.md` line 160 (ex commands said to get a key), area 6 (the search description lists), line 189 (`compile_substitute`), and lines 386 and 415 (the palette path in area 12's Flow), at 38628bb (periodic quality). Queued in `docs-index`.
- Why it matters: a reader trusting the map misses the palette's ex command path and the description lists.
- Fix outline: correct line 160, name the lists and the method, and add the palette path to the Flow line.

## A plugin opening a view in an occupied slot releases another plugin's scratch buffer

- Where: `OpenSideWindow#reuse` in `carat/use_cases/windows/open_side_window.rb` line 69 at edaf2c2. Security Low (5) in `layout-slots`.
- Why it matters: the new view takes the slot window and `@buffers.release(old)` takes the other plugin's scratch buffer out of the list when no other window shows it, so plugin A can make plugin B's view, and B's later `set_scratch_lines` and `close_scratch`, fail; this crosses the plugin isolation boundary (availability only, no data or code exposure).
- Fix outline: release the old buffer only when it has the new one's owner; keep another plugin's buffer listed as a view of the slot (or refuse the request with a failure response), with an `editor_slots` test of two plugins sharing a slot.

## close_scratch misses a view its hidden slot keeps

- Where: `close_scratch` in `carat/use_cases/plugins/window_requests.rb` line 115 at edaf2c2. Quality advisory in `layout-slots`.
- Why it matters: it looks only at the layout, so a plugin closing a view that its hidden slot keeps gets `No window shows` and the next toggle brings the view back.
- Fix outline: when a hidden slot keeps the buffer, clear the slot and release the buffer, with a row in `test/editor_plugins.rb`.

## A refused panel still regroups the root row

- Where: `panel_target` in `carat/domain/layout.rb` line 385 at edaf2c2. Quality advisory in `layout-slots`.
- Why it matters: the root row's middle children are grouped into a new row before `attach` checks the room, so a panel refused with E36 still leaves the layout restructured with a nested row.
- Fix outline: check the content's height against the size plus its minimum before grouping, or group only once `attach` would succeed.

## ToggleSlot repeats the leaf close and the kept-slot placement

- Where: the hide branch of `carat/use_cases/windows/toggle_slot.rb` lines 35 to 37, repeating `BufferList#close_window` (`carat/domain/buffer_list.rb` lines 282 to 284), and the kept-slot restore at lines 40 and 48 to 49, repeating `carat/use_cases/windows/open_side_window.rb` lines 35 to 38; the `current` lookup again after `place_slot` at lines 47 and 50, at edaf2c2. Quality advisories in `layout-slots`, raised three times.
- Why it matters: two copies of closing a leaf (layout close, current to the taker's first leaf, previous forgotten) and of placing a kept slot (kept and listed, `place_slot` at its size, `hidden = false`) drift apart; the second `current` lookup is dead, since `attach` and `panel_target` never renumber existing leaves.
- Fix outline: one `TabPage#close_leaf(id)` called by `ToggleSlot` and `BufferList#close_window`, one method that places a kept slot and answers the leaf or -1, called by both use cases, and drop the `current` local and its reassignment.

## The side string is mapped by a nested ternary and dispatched in four places

- Where: `carat/use_cases/plugins/window_requests.rb` lines 319 to 321, and the side dispatch in `TabPage#slot`, `TabPage#slot_at`, `Options#slot_size`, and `ToggleSlot#name_of`, at edaf2c2. Quality advisories in `layout-slots`, raised twice.
- Why it matters: the nested ternary is harder to read than the `if`/`elsif` of `TabPage#slot`, and four copies of the side dispatch drift when a slot is added.
- Fix outline: map the side once with a `case` or a small lookup and keep the per-side dispatch in `TabPage`.

## Layout#fixed_width? has no production caller

- Where: `carat/domain/layout.rb` line 297, called only by `test/domain_layout.rb` line 265 and named in `docs/codebase-map.md`, at edaf2c2. Quality advisory in `layout-slots`, raised twice.
- Why it matters: close, equalize, and fit use `fixed?`, so the wrapper of `fixed?(id, true)` is dead code kept alive by its test.
- Fix outline: drop it, test `fixed?(id, true)` instead, and update the layout line of the map.

## Two open_scratch comments are not rewrapped

- Where: the `open_scratch` comments in `carat/plugin_api.rb` line 480 (111 characters) and `carat/use_cases/plugins/window_requests.rb` line 69, at edaf2c2. Quality advisory in `layout-slots`.
- Why it matters: they break their files' wrap width.
- Fix outline: rewrap both at the file's width.

## Closing a tab page's last window keeps its hidden slots' views

- Where: `close_window` in `carat/domain/buffer_list.rb` line 280, unlike `close_tab` at line 304, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: `:q` or `:close` on the only window of a tab page with a hidden sidebar removes the tab page through `remove_tab` without releasing the slot's views, so the plugin's scratch buffer stays listed and unshown.
- Fix outline: route the single-leaf path through `close_tab` or one shared tab-removal helper that releases kept slot buffers, with an `editor_slots` row closing the tab page by `:q`.

## A disabled plugin's view kept by a hidden slot stays held

- Where: `close_scratch_windows` in `carat/use_cases/plugins/plugin_registry.rb` line 350, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: it walks only layout leaves, so a removed buffer stays held by the slot (`TabList#shown?` still true) until a later toggle clears it.
- Fix outline: in `clean_up` clear each slot of every tab page that keeps one of the plugin's buffers, with a row in `test/use_cases_plugin_hardening.rb`.

## Slot headers mark the shown view by title

- Where: `carat/adapters/frame_presenter.rb` line 717 and `Slot#add_view` in `carat/domain/slot.rb` line 84, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: views are listed and marked by title only, so two plugins opening views with the same title in one slot show one header entry.
- Fix outline: record each view by owner and title, or by buffer, and mark the shown one by identity, with an `editor_slots` row of two plugins sharing a title.

## The presenter and explorer comments omit the slots

- Where: the class comment of `carat/adapters/frame_presenter.rb` line 27 and `carat/plugins/explorer/plugin.rb` line 7, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: the presenter comment lists every frame part but not the slot header rows `paint_headers` adds, and the explorer still calls its tree a fixed-width side window though it opens in a sidebar slot.
- Fix outline: add a sentence on the slot headers and say left or right sidebar slot in the explorer comment.

## The version refusal tests hard-code the host version

- Where: `test/use_cases_plugins.rb` lines 178, 179, 185, and 189, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: four strings name 2.4 and must be edited at every minor bump.
- Fix outline: interpolate `Carat::PluginApi::VERSION` into the expected messages.

## :e! on the current buffer moves the cursor to the top

- Where: `carat/use_cases/files/open_file.rb` line 62, at b76b722. Periodic quality. Queue item `file-access-tidy`.
- Why it matters: `Window#show` puts the cursor at 1,1 and the scroll at the top, where Vim keeps the cursor line when it edits the same file again; no test checks it and `docs/compatibility.md` lists no difference.
- Fix outline: keep the cursor, clamped by the reload, when the listed buffer is the current one, with an `editor_cmdline` row, or document the difference.

## The request records copy waiting? and the language predicate

- Where: `carat/domain/hover_request.rb` line 79, `completion_request.rb` line 94, `completion_docs.rb` line 81, and `signature_request.rb` line 204 under `carat/domain/`, at b76b722. Periodic quality. Queue item `lsp-client-tidy`.
- Why it matters: four records repeat the same serial members, `waiting?`, and the languages predicate, and drift apart.
- Fix outline: fold them into the one request record the entry on the gateway's two timeout paths plans, or a domain concern.

## DiagnosticList and CompletionList are plain classes

- Where: `carat/domain/diagnostic_list.rb` line 260 and `carat/domain/completion_list.rb` line 8, at b76b722. Periodic quality. Queue item `diagnostics-tidy`.
- Why it matters: CLAUDE.md makes mutable lists `Struct` records; the entry on `FloatLayer` is the same case.
- Fix outline: make them `keyword_init` `Struct` records with a pinned items member, or record in `docs/architecture.md` why item lists are behavior classes.

## The architecture's Options and :set lines drift

- Where: `docs/architecture.md` line 113 (the Options bullet) and line 174 (section 5.2), at b76b722. Periodic quality. Queue item `architecture-drift`.
- Why it matters: the bullet lists `wrap` and `clipboard` as members, which are only checked keys of `Options::KINDS`, and omits `theme`, `background`, `syntax_on`, `startscreen`, and `reducedmotion`; section 5.2 lists `setlocal`, which has no handler, and says `:set` handles filetype and syntax only.
- Fix outline: list the members as `carat/domain/options.rb` declares them, the options `:set` handles, and drop `setlocal` until a handler exists.

## The architecture and the queue sit at their byte budgets

- Where: `BUDGETS` in `tools/docs_lint.sh` line 44: `docs/architecture.md` 88,058 of 88,064 bytes, at b76b722. Periodic quality. Queue items `breadcrumbs` and `architecture-drift`.
- Why it matters: the next change adding a sentence to the architecture fails `docs-lint` in its check stage.
- Fix outline: trim history and detail the archived designs already hold to restore working headroom.

## The map's bullets lag Messages, Options, the plugin API, and two tools

- Where: `docs/codebase-map.md` line 119 (Messages without E444 and `unsaved_buffer`), line 94 (Options without `range_problem`, `slot_size`, and the three layout sizes), line 513 (VERSION 2.3, the code 2.4), line 44 (the check entry without `runner_finish`), and line 579 (AnsiTerminal named the only environment reader, while `DiskFiles#home` reads HOME), at b76b722. Periodic quality. Queue item `docs-index`.
- Why it matters: the map is the start of every change and states facts the code contradicts.
- Fix outline: add the names, say 2.4 or name the constant without a number, and say the terminal driver's only environment reads.

## The .PHONY list leaves out metrics

- Where: `Makefile` line 432, at b76b722. Periodic quality. Queue item `run-budgets-tidy`.
- Why it matters: a file or directory named `metrics` at the top would make `make metrics` answer up to date and skip the measurement the check stage records.
- Fix outline: add `metrics` and `metrics-compare` to `.PHONY`.

## LastSearch keeps the pattern twice

- Where: `carat/domain/last_search.rb` line 16, at b76b722. Periodic quality. Queue item `search-tidy`.
- Why it matters: `pattern` always equals `compiled.source`, one fact kept twice.
- Fix outline: drop the member and read `compiled.source` in `any?` and `recompile`.

## Small code findings of the b76b722 periodic review

- Where: `carat/use_cases/operate.rb` line 65 (dispatches on `command.operator` again; yank at lines 174 to 175 sets the cursor by hand); `carat.rb` line 288 (no `require_relative` of `carat/use_cases/actions/search_handler.rb`); `carat/use_cases/actions/motion_handler.rb` line 33 (the register loop over NAMES and DESCRIPTIONS copied 16 times under `carat/use_cases/actions/`); `carat/domain/control_text.rb` line 102 (calls `Utf8` but requires nothing); `carat/domain/filetype.rb` lines 29 and 45 (`from_name` and `from_shebang` answer strings, public helpers only `detect` calls); `carat/domain/syntax_table.rb` line 254 (`size` has no caller); `carat/plugins/ruby/tokenizer.rb` line 15 (says the terminator table only grows, but it stops at `LineState::MAX_TERMINATORS`). Queue item 42.
- Why it matters: a repeated dispatch, a require graph that no longer names every file, a 16-fold copy, a compile that depends on require order, the `from_x` naming rule bent, dead code, and a wrong comment.
- Fix outline: case on the bound operator and use `move_to`; add the require; one `ActionTable` method taking names, handler, and descriptions; `require_relative "utf8"`; rename the Filetype helpers and make them private; drop `size`; say the table grows up to its cap.


## The pinned fetch is matched on the joined arguments

- Where: the `fetch` case of `tools/agent_guard.sh` line 456 at the `pinned-main` change; security Low (5) and a quality advisory of `pinned-main`.
- Why it matters: the rule compares the joined `$*`, so a quoted word can regroup the arguments: `git fetch -q --refmap= 'origin +refs/heads/main:refs/remotes/origin/main'` passes, and git reads the quoted word as a local-path repository and fetches from it, which `local_origin` misses since it checks only origin's URL. The impact is limited (only `FETCH_HEAD` is written, `origin/main` is not updated, and the planted directory must exist first). The rule also admits the fetch without `-q`, a second form the header at line 37 does not name.
- Fix outline: compare by count and position, admitting only the green line's four words: `[ $# -eq 4 ] && [ "$1" = -q ] && [ "$2" = --refmap= ] && [ "$3" = origin ] && [ "$4" = "$MAIN_REFSPEC" ]`, and add `tools/tools_test.sh` cases refusing the quoted regroupings and the form without `-q`.

## The guard's worktree check resolves the common directory on every call

- Where: `worktree` in `tools/agent_guard.sh` line 381 at the `pinned-main` change, called once per `tmp` entry in `metrics_out`'s loop (line 633); quality advisory of `pinned-main`.
- Why it matters: each call spawns `git rev-parse` and a `cd`, so a guard run over many entries repeats the same lookup.
- Fix outline: resolve the common directory once beside `project_real` and reuse it in `worktree`.

## A tools test rebuilds the forged .git file by a round trip

- Where: `tools/tools_test.sh` lines 1261 to 1263 at the `pinned-main` change; quality advisory of `pinned-main`.
- Why it matters: a `cat`, `sed`, and `printf` round trip with a temporary file and `mv` does what one copy does, which makes the case harder to read.
- Fix outline: `rm -rf "$proj/tmp/.planted/.git"`, then `cp "$proj/tmp/.base/.git" "$proj/tmp/.planted/.git"`.

## The mouse is not supported

- Where: the terminal driver and the key decoder; roadmap UI item `mouse`, moved here from `docs/queue.md` by the user's decision at `breadcrumbs`.
- Why it matters: not needed yet; carat never enables mouse reporting, so leaving it out breaks nothing. When it is done, three known risks: Shift-drag must still select text in the terminal, the reporting mode must be restored on every exit path (quit, crash, suspend, a raising plugin), and mouse sequences must be decoded so they never reach the keymap as typed keys.
- Fix outline: clicks, drags, and the wheel acting on windows, bars, and floats as in Neovim, each with a `docs/compatibility.md` row, with a case per exit path restoring the mode, a decoder case that no mouse sequence reaches the keymap, and a key costing nothing more. Not queued until the user asks.

## A hidden slot's window keeps its cursor past a shrunk buffer

- Where: `clamp_cursors` in `carat/domain/tab_list.rb` line 225 at 847851d; reached by `set_scratch_lines` and the explorer's follow while its sidebar is hidden, shown again by `ToggleSlot` or `OpenSideWindow`. Periodic quality at 847851d (the review's one blocking finding, as read by the planner). Queue item `slots-tidy`.
- Why it matters: the window shows again with its cursor and top past the buffer's end, against the invariant area 8's Flow promises.
- Fix outline: clamp the windows kept by hidden slots too, with an `editor_slots` row shrinking a hidden explorer and toggling it back.

## toolchain-clean deletes all of tmp/ and ignores its overrides

- Where: `toolchain-clean` in the `Makefile` line 158, its help line 156, and `README.md` line 20 at 847851d. Periodic quality. Queue item `check-runner-safety`.
- Why it matters: it removes the scout packs and the merge-gates and review worktrees, leaving stale worktree records, yet ignores the `SPINEL_SRC` and `PREFIX` overrides that `docs/architecture.md` section 2 says it removes.
- Fix outline: remove only the two toolchain paths, and say so in the help line and the README row.

## The map's agent_guard.sh bullet omits two helpers

- Where: `docs/codebase-map.md` line 48 at 847851d: no `local_origin` nor `worktree_name`, both added or used by `pinned-main`. Periodic quality. Queue item `docs-index`.
- Why it matters: the bullet names the guard's other helpers, so a reader misses two refusals.
- Fix outline: add `local_origin` to the git clause and `worktree_name` beside `worktree`.

## The map's area 10 Flow names the wrong handlers

- Where: `docs/codebase-map.md` lines 316 and 320 at 847851d. Periodic quality. Queue item `docs-index`.
- Why it matters: `SwapVisualEnds` is `SelectionHandler`'s, `ExtendVisual` is `TextObjectHandler`'s, and the five operators reach their use cases through `OperatorHandler`; the selection line omits `Selection#numbered_delete?`, `as`, and `line_start`, which architecture section 5 names.
- Fix outline: name the handler per use case and add the three methods.

## A plugin's resize event is built with no subscriber

- Where: `resized` in `carat/use_cases/plugins/plugin_events.rb` line 142 at 847851d; `queue` (line 200) skips unwanted events. Periodic quality. Queue item: backlog items, plugin host classes.
- Why it matters: an event is built for nobody on every resize.
- Fix outline: update the last size, then return unless a plugin wants `resize`.

## Two plugin host classes look up an option the same way

- Where: `PluginHost#option` in `carat/use_cases/plugins/plugin_host.rb` line 140 and `UiRequests#option` in `carat/use_cases/plugins/ui_requests.rb` line 91 at 847851d. Periodic quality. Queue item: backlog items, plugin host classes.
- Why it matters: duplication, two places to change.
- Fix outline: one `PluginRegistry` method answering the value or nil, called by both.

## Plugin entries and edits are named e

- Where: `carat/use_cases/plugins/plugin_events.rb` lines 213 and 227, `plugin_host.rb` lines 95 and 141, `buffer_requests.rb` line 61 at 847851d, beside the queued `ui_requests.rb` line 92. Periodic quality. Queue item: backlog items, plugin host classes.
- Why it matters: CLAUDE.md naming forbids unclear abbreviations.
- Fix outline: rename them `entry` and `edit` with the `ui_requests` fix.

## Plugin directory reads skip the tree-root check

- Where: `list_dir` and `stat` in `carat/use_cases/plugins/file_requests.rb` line 34 at 847851d. Periodic security Low (3). Queue item: backlog items, plugin host classes.
- Why it matters: unlike the write requests through `ResolveInside`, a plugin can list and probe directories anywhere.
- Fix outline: pass the root and resolve the read requests inside it, with a refusal row.

## The test rig's fail shadows Kernel#fail

- Where: the private `fail` of `carat/testing.rb` line 74 and `assert_raises` line 38 at 847851d. Periodic quality. Queue item: backlog items.
- Why it matters: `assert_raises` rescues only `StandardError`, so `assert_raises(NotImplementedError)`, the error every port method raises, ends the test program instead of passing.
- Fix outline: rename the helper `record_failure` and rescue `StandardError` and `ScriptError`, with a rig case.

## The explorer's sort downcases both names per comparison

- Where: `sorted` in `carat/plugins/explorer/tree.rb` line 252 at 847851d. Periodic quality. Queue item: backlog items, the explorer.
- Why it matters: about 2n log n strings per listing on every tree build.
- Fix outline: compute each lowercase key once and sort by it.

## A block's top-left column is computed in six places

- Where: `carat/domain/selection_cut.rb` line 30 and `carat/use_cases/visual/` `yank_selection.rb` line 39, `shift_selection.rb` line 22, `change_selection.rb` line 53, `put_over_selection.rb` line 39, `insert_at_selection.rb` line 46 at 847851d. Periodic quality. Queue item: backlog items, copies.
- Why it matters: architecture section 5 moves logic several use cases share into the domain.
- Fix outline: one `Block` method beside `reaching_rows`, called from the six places.

## Buffer#blanks is public with callers only in its file

- Where: `carat/domain/buffer.rb` line 438 at 847851d. Periodic quality. Queue item: backlog items, needless public methods.
- Why it matters: a needless public method widens `Buffer`'s surface.
- Fix outline: move it below `private`.

## The palette's prompt recalls the command history

- Where: `carat/use_cases/recall_history.rb` line 34 at 847851d; `keymap.cmdline` binds `<Up>` and `<Down>` to `cmdline.history_older` and `cmdline.history_newer`. Periodic quality. Queue item `discoverability-tidy`.
- Why it matters: at the palette's prompt they put `:` history into the filter text; the command-palette spec says nothing of history.
- Fix outline: answer nothing or move the selection while the palette is active, with an `editor_palette` row for `<Up>`.

## The docs float repeats the completion popup's row arithmetic

- Where: `carat/use_cases/completion/show_completion_docs.rb` line 88 and `ShowCompletion#row_offset` in `show_completion.rb` line 167 at 847851d. Periodic quality. Queue item `completion-docs-tidy`.
- Why it matters: the unexplained 2 already in the backlog lives in two places.
- Fix outline: one domain helper for the cursor's screen row and the rows free below it, the 2 named.

## A project .caratrc can bind a key to a write or quit

- Where: keymap lines in `carat/domain/config.rb` line 213 at 847851d. Periodic security Low (4). Queue item `project-config-guards`.
- Why it matters: a cloned project can turn an everyday keystroke into `quit.write_all` or `file.save`.
- Fix outline: refuse project keymap lines whose action writes or quits, or read project bindings only under `language.trusted_roots`, with a `file:line` problem row.

## Creating a file follows a link that appears after the probe

- Where: `carat/use_cases/files/make_path.rb` line 47 at 847851d: an existence probe, then `FilePort#write`. Periodic security Low (3). Queue item `file-access-tidy`.
- Why it matters: a file or link appearing between the probe and the write is truncated or followed.
- Fix outline: a create that fails on an existing path or link, used here, with a case.

## The winbar's never, always, and auto policy lives in two layers

- Where: `winbar_after?` in `carat/use_cases/windows/split_window.rb` line 55 and `TabPage#winbar?` in `carat/domain/tab_page.rb` line 61 at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: both compare the same string literals for the mode, so a new mode or rule must change two layers.
- Fix outline: one `TabPage` predicate taking the extra file window count (`winbar?(mode, added)`), called from both, comparing against named constants beside `Options::BREADCRUMBS`.

## A restarted server is never asked again for the same text's symbols

- Where: `forget_server` (the symbol ask, `forget_symbols` before periodic-blockers-a) in `carat/adapters/json_rpc_language_gateway.rb` line 757 at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: it clears the request in flight but keeps `asked_buffer` and `asked_changes`, so after a crash and restart the winbar shows no symbols until an edit or a buffer switch.
- Fix outline: reset the asked text (`asked_changes = -1`) in `forget_server`, with an `editor_breadcrumbs` row for a restart.

## SymbolOutline's comment says characters where the cut is in bytes

- Where: the class comment of `carat/adapters/symbol_outline.rb` line 12 at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: `ControlText.strip` cuts at a byte limit, as the map, `docs/compatibility.md`, and the test say, so the comment misleads.
- Fix outline: say bytes in the comment.

## FramePresenter's class comment breaks its wrap width

- Where: the class comment of `carat/adapters/frame_presenter.rb` line 40 at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: the edit left a three-word line mid-sentence, which reads as a broken paragraph.
- Fix outline: rewrap the paragraph.

## The map misses SymbolRequest methods and the breadcrumbs test

- Where: `docs/codebase-map.md` line 591 and the render and language areas' Tests lines at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: the entry omits `count` and `name_at`, and the Tests lines do not name `test/editor_breadcrumbs.rb` though it covers `winbar.rb`, `symbol_outline.rb`, and `symbol_request.rb`.
- Fix outline: add the two methods to the entry and the test to both areas' Tests lines.

## The palette's name column cuts five shipped action names

- Where: `NAME_WIDTH` in `carat/use_cases/discovery/follow_palette.rb` line 29, at 7711421. Periodic quality. Queue item `discoverability-tidy`.
- Why it matters: 28 cuts `textobject.inner_single_quote`, `textobject.inner_double_quote`, `plugin.explorer.toggle_hidden`, `search.partial_word_backward`, and `motion.big_word_end_backward` to 27 characters.
- Fix outline: size the column from the longest name capped by the float width, with a row showing a 29-character name whole.

## :LspRestart lets a stale symbol answer replace the outline

- Where: `stop` in `carat/adapters/json_rpc_language_gateway.rb` line 227, at 7711421; `crash` (line 439) forgets the symbol request, `stop` does not. Periodic quality. Queue item `breadcrumbs-tidy`.
- Why it matters: a documentSymbol request in flight keeps its id across a restart, so `waiting?` holds until the deadline, the cancel goes to the new server for an id it never issued, and the new server's answer to a reused id is read as the outline.
- Fix outline: forget the symbol request in `stop` beside the other three, with an `editor_breadcrumbs` row for `:LspRestart` with a symbol request in flight.

## The presenter and the arranger each decide which windows get a winbar

- Where: `paint_winbars` in `carat/adapters/frame_presenter.rb` line 723 and `reserve_winbars` in `carat/use_cases/arrange_view.rb` line 89, at 7711421. Periodic quality. Queue item `breadcrumbs-tidy`.
- Why it matters: two rules in two layers (geometry against scratch and height) must stay in step.
- Fix outline: one predicate or a flag set by the arranger that the presenter reads.

## Layout's split and attach copy the inner-split block

- Where: `carat/domain/layout.rb` lines 153 to 168 (`split`) and 351 to 368 (`attach`), at 7711421. Periodic quality. Queue item `breadcrumbs-tidy`.
- Why it matters: allocating the split, copying size and rectangle, replacing the target, and reparenting are written twice.
- Fix outline: one private helper returning the inner id, called by both.

## Quit walks the leaves to count file windows

- Where: `beside_side_windows?` in `carat/use_cases/files/quit.rb` line 66, at 7711421. Periodic quality. Queue item `breadcrumbs-tidy`.
- Why it matters: it repeats `TabPage#file_window_count`.
- Fix outline: call `file_window_count`.

## TabPage#previous? reads the node array directly

- Where: `carat/domain/tab_page.rb` line 103, at 7711421. Periodic quality. Queue item `breadcrumbs-tidy`.
- Why it matters: every other walker uses `layout.node_count`.
- Fix outline: use `node_count`.

## A split from a scratch window has no winbar row

- Where: `winbar_after?` in `carat/use_cases/windows/split_window.rb` line 59, at 7711421; `test/editor_breadcrumbs.rb` splits only file windows. Periodic quality. Queue item `breadcrumbs-tidy`.
- Why it matters: the branch adding no file window for a scratch split is untested.
- Fix outline: rows splitting a slot or plugin window with a count under `auto` and `always`.

## The docs deny or omit the winbar

- Where: `docs/compatibility.md` line 441 (Bars says no winbar, against Breadcrumbs at line 518); `docs/architecture.md` line 257 (the FramePresenter bullet omits the winbar row and its painter), at 7711421. Periodic quality. Queue items `docs-index` and `architecture-drift`.
- Why it matters: two documents contradict the delivered feature.
- Fix outline: drop the denial or point to Breadcrumbs; name the winbar and `Winbar` in the bullet.

## The map omits Layout and search methods other files call

- Where: `docs/codebase-map.md` line 349 (Layout without `leaf_showing`, `leaf_number`, `leaf_count`, `node`, `node_count`, `window_at`), line 189 (VimPattern without `compile_substitute`), line 194 (LastSearch without `any?`, `end_preview`), line 195 (SearchPrompt without `close`, `prefix`), at 7711421. Periodic quality. Queue item `docs-index`.
- Why it matters: callers look up a method the map does not name.
- Fix outline: name them on those lines.

## ExTable keeps unread positions and an uncalled count

- Where: `carat/use_cases/ex/ex_table.rb` lines 16 and 56 (`@index` positions never read), 98 (`count`, no caller), 104 (`handler_at`, public only for `find`), at 7711421. Periodic quality. Queue item 41.
- Why it matters: dead API, and the comment reads the index as a lookup though it only refuses duplicates.
- Fix outline: delete `count`, make `handler_at` private, keep a set of taken names, and say so in the comment.

## Motions repeats its row clamp and paragraph walk

- Where: `carat/domain/motions.rb` line 246 (`line_down` repeats `vertical`'s checks at lines 215 to 222, `to_row` clamps again), lines 540 and 562 (`paragraph_forward` and `paragraph_backward` share one loop), at 7711421. Periodic quality. Queue item `search-tidy`.
- Why it matters: three clamps and two walks to keep in step.
- Fix outline: one private row clamp and one paragraph walker taking the step.

## GlobalCommand#remember repeats SubstituteLines#remember

- Where: `carat/use_cases/search/global_command.rb` line 81 and `carat/use_cases/search/substitute_lines.rb` line 113, at 7711421. Periodic quality. Queue item `substitute-tidy`.
- Why it matters: the same four writes of a used pattern, so a fix to one misses the other.
- Fix outline: one domain function both call.

## Small code findings of the 7711421 periodic review

- Where: `carat/use_cases/search/find_match.rb` line 163 and `substitute_lines.rb` line 143 (E486 as a literal, not a `Search` constant); `carat/use_cases/actions/motion_handler.rb` line 52 (a comment missing words) and `carat/domain/find.rb` line 3 (describes `LastFind`'s role); `carat/domain/vim_pattern.rb` line 23 (three escapes listed twice). Queue item `search-tidy`.
- Why it matters: a message spelled twice and three wrong comments.
- Fix outline: `Search::NOT_FOUND` used by both; reword the two comments; drop the second mention.

## The progress segment bounds its percent twice and follows any server

- Where: `carat/adapters/json_rpc_language_gateway.rb` lines 1037 to 1045 (`set_progress`), against `show` at line 398, and `carat/domain/status_slots.rb` line 63, at 31919d9. Quality advisories of `feedback`; periodic quality at 31919d9. Queue item `messages-tidy`.
- Why it matters: the percent is bounded in three places; and any running server's `$/progress` overwrites the title and label, while `show` follows only the current buffer's server, so a second server's report can relabel the current one's indexing, or be wiped in the same poll and restart the bar's step.
- Fix outline: `server.percent = given if given >= 0` and one clamp; call `set_progress` only for the server `show` follows, or keep the progress per server, with an `editor_messages` row for two servers reporting at once.

## MessageHistory stores levels nothing outside the tests reads

- Where: `carat/domain/message_history.rb` line 8, at the `feedback` change. Quality advisory of `feedback`.
- Why it matters: speculative generality: levels are kept per entry, but only tests read `level_at`, since `:messages` is not colored (`docs/compatibility.md`).
- Fix outline: drop the levels until `:messages` colors its listing, or use them for the listing's groups.

## Search echoes fill the message history

- Where: `carat/domain/editor_state.rb` line 135 (`show`), reached by the `/pattern` echo of `n`, `N`, `*`, and `#`, at the `feedback` change. Quality advisory of `feedback`.
- Why it matters: Neovim does not keep the search echo in `:messages`, so 500 presses of `n` evict every real error, and the deviation is not in the compatibility notes.
- Fix outline: show the search echo through `show_output`, or list the deviation under Messages and notifications in `docs/compatibility.md`, with a row pressing `n` after an error.

## The read timeout cut to a notification's deadline has no test

- Where: `carat/adapters/input_controller.rb` line 152, at the `feedback` change; only the harness pump is exercised. Quality advisory of `feedback`.
- Why it matters: a regression that waits the full timeout leaves a notification on screen past its deadline unnoticed.
- Fix outline: have the terminal double record the timeout of `read_key` and assert it is cut while a notice shows.

## The notice painter's comments and narrow guard

- Where: `carat/adapters/frame_presenter.rb` line 429 (a comment line not wrapped like its block) and line 439 (the `cols < NOTICE_NARROWEST` guard after the widths it makes moot), and `carat/domain/editor_state.rb` line 13 (an unwrapped comment line), at the `feedback` change. Quality advisory of `feedback`.
- Why it matters: style drift and widths computed for nothing on a narrow screen.
- Fix outline: rewrap both comments and move the guard to the top of `add_notice_boxes`.

## Bidi and zero-width format characters reach the terminal raw

- Where: `carat/domain/display_width.rb` line 66 (`control?` and `code_cells`), at 31919d9; reached from buffer text, server text, and names through `carat/adapters/frame_presenter.rb`. Periodic security Medium (5). Queue item `bidi-controls`.
- Why it matters: U+200B to U+200F, U+202A to U+202E, U+2060 to U+2069, U+FEFF, and U+061C count as one cell and are written raw, so a hostile file can reorder the shown code on a bidi-rendering terminal (Trojan Source) or desync columns.
- Fix outline: treat them as controls, shown as a visible placeholder in buffer text and dropped from control-stripped text, with `test/domain_utf8.rb` and `test/editor_screen.rb` rows per source.

## A server's progress title is stored raw and copied per report

- Where: `carat/domain/status_slots.rb` line 60, fed from `carat/adapters/json_rpc_language_gateway.rb` line 1038, at 31919d9. Periodic security Low (3). Queue item `lsp-client-tidy`.
- Why it matters: a `$/progress` begin title up to the 8 MiB body limit is kept whole and joined with every later report's message before it is cut, so a hostile server costs a multi-megabyte copy per report, up to 64 per tick.
- Fix outline: store the title already cut to the progress limit, with a `test/adapters_language_gateway.rb` row for an oversized title.

## :messages drops the two-line unsaved-buffer refusal

- Where: `carat/domain/message_history.rb` line 29 (`add` drops any text holding a line feed), against `Messages.unsaved_buffer` in `carat/domain/messages.rb`, shown by `carat/use_cases/files/quit.rb`, at 31919d9. Periodic quality. Queue item `messages-tidy`.
- Why it matters: E37 with E162 is never kept, against `docs/compatibility.md` Messages and notifications (Error: Kept) and Neovim, whose `:messages` keeps both lines.
- Fix outline: keep each line of a shown message in the history (output-only text stays out), with a `test/editor_messages.rb` row for `:q` over a modified hidden buffer followed by `:messages`.

## The message history is built inside EditorState, not the assembly

- Where: `carat/domain/editor_state.rb` line 42, shared with the notices as `state.history`, at 31919d9. Periodic quality. Queue item `messages-tidy`.
- Why it matters: CLAUDE.md requires everything shared to be built once in `EditorAssembly` and kept in a reader, so `test/adapters_assembly.rb` can check every holder got the one instance.
- Fix outline: build it in `carat/adapters/editor_assembly.rb` with a reader, pass it to both holders, and add the identity row.

## Feedback's naming, wrap, and plugin docs drift

- Where: `carat/adapters/frame_presenter.rb` line 507 (a group id in a local named `text`), `carat/adapters/status_bar.rb` line 16 (a class comment past the wrap width), `docs/plugins.md` line 69 (the `set_segment` row omits the progress segment at 35 and its place before `lsp`), at 31919d9. Periodic quality. Queue item `messages-tidy`.
- Why it matters: a misleading name, style drift, and a plugin author misreading where a segment lands.
- Fix outline: rename the local, rewrap the paragraph, and add the progress to the row's priorities.

## The explorer opens left on any side but right

- Where: `carat/plugins/explorer/plugin.rb` line 516 (`side`), and `carat/use_cases/plugins/window_requests.rb` line 70 (`open_scratch`'s `width`, rows for the bottom panel since 2.4, and a failure text restating `PluginApi::SIDES`), at 31919d9. Periodic quality. Queue item `slots-tidy`.
- Why it matters: `plugin.explorer.side bottom` or a typo silently opens the tree on the left with no problem reported; a parameter named for columns carries rows.
- Fix outline: pass `bottom` through and report an unknown side, with a row; rename the parameter `size` and build the message from the sides list.

## SymbolOutline's comment says characters for a byte cap

- Where: `carat/adapters/symbol_outline.rb` line 12, at 31919d9. Periodic quality. Queue item `breadcrumbs-tidy`.
- Why it matters: the comment says names are cut to `NAME_LIMIT` characters, while the cut caps bytes, as the map says.
- Fix outline: say bytes.

## Options#apply repeats one block four times

- Where: `carat/domain/options.rb` line 172 (tabstop, shiftwidth, `keyhints.delay`, the layout sizes), at 31919d9. Periodic quality. Queue item: backlog items, `:set` checks.
- Why it matters: duplication: each branch computes a problem, assigns when empty, else notes it.
- Fix outline: one private helper taking the problem and the line, answering whether to assign.

## Seven more methods are public with no outside caller

- Where: `Operators.ascii_recase` and `indent_width` (`carat/domain/operators.rb` lines 239 and 271), `Registers#unnamed?` (`carat/domain/registers.rb` line 65), `Buffer#layer_at` (`carat/domain/buffer.rb` line 232), `UndoTree#transaction_at`, `parent_of`, `head_of` (`carat/domain/undo_tree.rb` lines 99, 105, 111), at 31919d9. Periodic quality. Queue item: backlog items, needless public methods.
- Why it matters: needless public surface, called only by tests.
- Fix outline: make them private and test them through their public callers.

## Two style slips of 31919d9

- Where: `test/runner/run_all.rb` line 81 and its dispatch at line 178 (`editor_breadcrumbs` out of alphabetical order); `carat.rb` line 4 (a 90-character header line), at 31919d9. Periodic quality. Queue item: backlog items, the runner's test order and comments off their wrap; fold the second into Nine comments break their file's wrap width.
- Why it matters: every other test keeps alphabetical order; the header breaks its wrap width.
- Fix outline: move both lines to their place; rewrap lines 2 to 6.

## Tooling header, refspec, and compare message drift

- Where: `tools/tools_test.sh` line 2 (the header omits the tool-call caps section at line 1879 and the workflows' js cases); `tools/gates.sh` line 135 and `tools/agent_guard.sh` line 103 (the default fetch refspec defined twice); `tools/metrics.sh` line 105 (compare says the figures grew when a strict metric was only not measured), at 31919d9. Periodic quality. Queue items `run-budgets-tidy` (header, compare) and `merge-gate-tidy` (refspec, with merge-gate-integrity's open quality advisories).
- Why it matters: a header that misleads a reader, one rule in two places, and a failure message naming the wrong cause.
- Fix outline: list both sections in the header; define the refspec once in `tools/rules.sh` for the gates, the guard's copy under an equality case; say "grew or were not measured".

## The live pull request body is not gated

- Where: the `pr-body` gate of `tools/gates.sh` checks the body file in the run state, not the pull request as it stands; retrospective of `feedback` (#83). Queue item `merge-gate-tidy`.
- Why it matters: a session-link footer appeared after the pull request opened at #83 and was removed only because the contributor re-read it; footers reached 10 of 53 earlier pull requests.
- Fix outline: the merge gates compare the live body with the run state's body file and refuse a difference, with a case.

## The planner's backlog text reaches the package unchecked

- Where: the package step of `.claude/workflows/deliver-change.js` copies the planner's backlog text before `make docs-lint` sees it; retrospective of `feedback` (#83). Queue item `phase-shares`.
- Why it matters: one entry named a missing path, failing `docs-lint` and costing the package a separate fix commit.
- Fix outline: check the planner's output for missing paths before the package copies it, with a case in `make tools-test`.

## An image-viewer plugin is under discussion

- Where: none yet; a proposal waiting for the user's decision, moved out of `docs/queue.md` when the queue reached its budget.
- Why it matters: five formats, block characters from its own decoder, kitty and iTerm2 where available, bounded parsing, a size cap, only base64 or cells sent.
- Fix outline: queue it as a T5 item when the user approves, sized from the plugin rows of `docs/metrics.tsv`.

## The palette-pad-crash scenarios drift from their tests

- Where: `openspec/specs/command-palette/spec.md` lines 87 to 92 bind `window.split` while `test/editor_palette.rb` line 141 binds `insert.newline`; `openspec/specs/key-hints/spec.md` line 102 remaps `<leader>xa` while `test/editor_key_hints.rb` line 128 sets a group name for `<leader>xy`, since a project file reads no remap, at 6141633. Quality advisory of `palette-pad-crash`. Queue item `discoverability-tidy`.
- Why it matters: a scenario is meant to describe the setup its test runs; a reader who reproduces the scenario takes a path the test never covers.
- Fix outline: word the palette scenarios after `insert.newline` and the hint scenario after a group name of fifty wide characters whose widest row is 77 of 78 cells, through a proposal.

## cells_of in the palette test returns an array no caller reads whole

- Where: `cells_of` in `test/editor_palette.rb` line 66, at 6141633. Quality advisory of `palette-pad-crash`. Queue item `discoverability-tidy`.
- Why it matters: it computes the row's total cells that no caller reads (only the second value is used) and returns several values in an array, against the test-helper rule of `CLAUDE.md`.
- Fix outline: return only the description's start cell as an Integer and drop the total.

## DisplayWidth.bytes_within is public for one caller

- Where: `DisplayWidth.bytes_within` in `carat/domain/display_width.rb` line 148, called only by `cut` and a test, at 6141633. Quality advisory of `palette-pad-crash`. Queue item: backlog items, needless public methods.
- Why it matters: needless public surface, the same kind as the entry Seven more methods are public with no outside caller.
- Fix outline: move the stray-byte rows of its test to `cut` and make `bytes_within` private to `DisplayWidth`.

## A project .caratrc sets timeoutlen and undolevels without an upper bound

- Where: `carat/domain/options.rb` line 187, at 5e4c140. Periodic security Low (4). Queue item `project-config-guards`.
- Why it matters: a cloned project's `.caratrc` can set either to nine digits, so every pending key sequence waits about eleven days and undo states grow without limit.
- Fix outline: bound both with `range_problem` as `keyhints.delay` is, or refuse them from the project file, with rows in `test/domain_options_config.rb`.

## The project .caratrc is read by path after its link check

- Where: `carat/adapters/rc_config_gateway.rb` line 59 (the stat refusing a link) and line 68 (the read by path), at 5e4c140. Periodic security Low (2). Queue item `project-config-guards`.
- Why it matters: a link swapped in between the stat and the read is followed.
- Fix outline: open once without following links and check the opened file, as `DiskFiles#read` checks regular files, with a case in `test/drivers_disk_files.rb`.

## A none unbinding turns an unbound key into an empty prefix

- Where: `carat/domain/keymap.rb` line 181 (`bind_owned` through `child_for`), at 5e4c140. Periodic quality blocking. Queue item `project-config-guards`.
- Why it matters: `keymap.normal QQ none` makes an unbound `Q` a prefix, so `HandleKey` answers waiting with no deadline and `ShowKeyHints` lists `Q` with no meaning; unbinding a group's last child leaves the group waiting.
- Fix outline: for `none` walk the path with `child?` and stop where it ends, then drop nodes left with no value and no children as `clear_owner` does, with a `test/domain_keymap.rb` row for `QQ none`.

## The backlog has no byte budget

- Where: `docs/backlog.md` (301 KB, 471 entries at 5e4c140, up from 151 KB over 20 changes) and `BUDGETS` in `tools/docs_lint.sh`. Periodic quality. Queue item `docs-index`.
- Why it matters: no agent can read it whole to find fixed entries or avoid recording a finding twice.
- Fix outline: give it a budget in `BUDGETS` and fold its entries per area, removing those no longer true.

## Key hints repeat the grammar-mode test

- Where: `carat/use_cases/discovery/show_key_hints.rb` line 61 and `HandleKey#grammar_mode?` in `carat/use_cases/handle_key.rb` line 195, at 5e4c140. Periodic quality. Queue item `discoverability-tidy`.
- Why it matters: a mode added to one test and not the other shows hints that disagree with the grammar.
- Fix outline: one `Mode.grammar?(mode)` in `carat/domain/mode.rb` called by both.

## The map names EditorState's show twice and lacks Tree readers

- Where: `docs/codebase-map.md` line 117 (a second `show` before `list_message?`) and line 558 (area 16's Tree line without `expanded?`, `root`, `marked`, `count`, `node`), at 5e4c140. Periodic quality. Queue item `docs-index`.
- Why it matters: the map is where every agent starts.
- Fix outline: drop the second `show`; name the readers or say the list is the operations only.

## FramePresenter keeps two dead width wrappers

- Where: `display_col` and `display_width` in `carat/adapters/frame_presenter.rb` line 299, called only by `test/adapters_frame_presenter.rb` line 317, at 5e4c140. Periodic quality. Queue item 38 (dead public methods).
- Why it matters: public surface the paint path never uses.
- Fix outline: delete both and have the test call `DisplayWidth.column(line, line.length, 4)`.

## The window requests comments are stale since the slots change

- Where: `open_file` in `carat/use_cases/plugins/window_requests.rb` line 145 and the class comment, lines 24 to 32, at 5e4c140. Periodic quality. Queue item `slots-tidy`.
- Why it matters: `unfix_size` at line 162 also drops a bottom panel's fixed height, and scratch buffers no longer open only in side windows.
- Fix outline: say the slot window loses its fixed size and rewrap the class comment.

## :registers cuts wide text by characters

- Where: `carat/use_cases/ex/register_command_handler.rb` line 70, at 5e4c140; `test/editor_registers.rb` has no wide-text row. Periodic quality. Queue item `buffer-list-tidy`.
- Why it matters: a register of wide characters runs to twice the screen width, the mistake `palette-pad-crash` fixed in the palette.
- Fix outline: cut with `Domain::DisplayWidth.cut` and count down by `DisplayWidth.text_width`, with a wide-register row.

## Explorer and icon tests pass raw table cells

- Where: `test/editor_explorer.rb` lines 114, 188, 235, 257, 297; `test/plugins_explorer.rb` lines 152 and 162; `test/domain_icons.rb` lines 53 and 89, at 5e4c140. Periodic quality. Queue item 38 (test hygiene).
- Why it matters: the CLAUDE.md typed-table rule; line 137 of the first file already converts.
- Fix outline: convert each cell with `.to_s`, `.to_i`, or `== true` before it reaches the library.

## The explorer keeps a stale followed path after a directory rename

- Where: `finish_rename` in `carat/plugins/explorer/plugin.rb` line 420, against `Tree#moved` in `tree.rb` line 107; the duplicate `tree.mark(@followed)` in `show_tree` line 186, at 5e4c140. Periodic quality. Queue item 38 (explorer).
- Why it matters: renaming the open file's directory leaves the old, missing path marked and revealed until a focus event; the mark has two owners.
- Fix outline: apply the prefix rule to `@followed` or set it from `tree.marked`, drop the duplicate mark, with an `editor_explorer` row.

## Explorer test helpers and icon tables

- Where: `tree_over` in `test/plugins_explorer.rb` line 64 (unused parameter; an assignment inside an argument at 127; a ternary assert at 85); `Icons.table` and `NAMES` in `carat/domain/icons.rb` lines 132 and 13; DisplayWidth rows in `test/domain_icons.rb` lines 78 to 92, at 5e4c140. Periodic quality. Queue item 38.
- Why it matters: a key added to a table without `NAMES` goes untested; tests of one module sit in another's file.
- Fix outline: drop the parameter and split the statements; make `table` private and derive names from the tables; move the rows to `test/domain_display_width.rb`.

## The visual cursor cell ignores documentation styles

- Where: the visual-mode cursor cell in `FramePresenter` (`token_group` over `buffer.syntax_cache.lookup`, `carat/adapters/frame_presenter.rb` near line 692), which reads only the syntax cache, at the `quick-docs-styles` change.
- Why it matters: in the pinned `[docs]` split, the cell under the cursor in visual mode takes the plain text's group instead of its markup group, unlike the cells around it.
- Fix outline: fall back to `buffer.style_at(row, line)` when the cache is inactive and the buffer is styled, as `paint_window` does, with a row in `test/adapters_hover.rb`.

## A fence's short name is never highlighted

- Where: `carat/use_cases/docs/format_docs.rb` line 49, at the `quick-docs-styles` change, where the fence's word goes straight to `PluginSyntax#provider` as a filetype. Quality advisory in `quick-docs-styles`.
- Why it matters: common fences such as `rb` (the parse test itself uses one), `sh`, or `bash` are never highlighted though a plugin tokenizes their filetype.
- Fix outline: resolve a name that is not a filetype through `Filetype`'s extension table before asking for a provider, with a row in `test/adapters_hover.rb`.

## Fenced code paths in the documentation formatter have no test

- Where: `carat/use_cases/docs/format_docs.rb` line 40, at the `quick-docs-styles` change: the path where the tokenizer raises (block left plain, plugin disabled), and the tokenizer state carried across a block's rows and reset per block. Quality advisory in `quick-docs-styles`.
- Why it matters: a regression in either path would show wrong colors or keep a failing plugin enabled, unnoticed.
- Fix outline: add `test/adapters_hover.rb` rows with a raising tokenizer double, and with a fenced Ruby string spanning two lines followed by a second block.

## MarkdownText.rows is public surface only a test calls

- Where: `MarkdownText.rows` in `carat/domain/markdown_text.rb` line 35, called only by `test/domain_markdown_text.rb` since `quick-docs-styles`, production going through `FormatDocs` (parse then wrap). Quality advisory in `quick-docs-styles`; part of the public helpers no other file calls.
- Why it matters: dead public surface invites callers that bypass the owner.
- Fix outline: move it into the test as a typed helper over `wrap(parse(text), width).texts` and drop it from the module.

## Comments name only the cursor-line layer

- Where: the `SgrTable` class comment in `carat/adapters/sgr_table.rb` line 8, `Frame`'s comment in `carat/domain/frame.rb` line 13, and `docs/architecture.md` line 260, at the `quick-docs-styles` change. Quality advisory in `quick-docs-styles`.
- Why it matters: cells and sequences now also carry `Highlight::FLOAT_LAYER`, so the comments mislead a reader adding a layer.
- Fix outline: mention the float layer in all three.

## The MarkdownText comment still says plain rows

- Where: the module comment of `carat/domain/markdown_text.rb` line 10, at the `quick-docs-styles` change. Quality advisory in `quick-docs-styles`.
- Why it matters: `parse` now also keeps markup spans and each fence's language and block number, which the comment does not say.
- Fix outline: add a sentence on `parse`, `wrap`, and the spans they keep.

## Documentation formatting scans every token quad per row

- Where: `tokens_of` in `carat/domain/docs_text.rb` line 111 (per row, from styles) and `copy_spans` at line 83 (per wrapped piece), at the `quick-docs-styles` change. Quality advisory in `quick-docs-styles`.
- Why it matters: formatting costs rows times spans, up to 100 rows times thousands of token quads, on every completion selection change.
- Fix outline: walk the quads once with a cursor, since `wrap` appends them in row order, or keep a per-row start index.

## The documentation formatter's periodic findings

- Where, at df4654c: `carat/domain/markdown_text.rb` line 299 (`inline` drops emphasis markers inside a code span; `test/domain_markdown_text.rb` line 80 asserts the garbled span), line 66 with line 76 and `carat/use_cases/docs/format_docs.rb` line 19 (the two-column fence indent spelled three times), line 202 (`heading?` and `heading_text` repeat a scan), line 35 (`rows` used only by its test, module comment at line 9 and `docs/codebase-map.md` line 602 stale), line 387 (`wrapped` mutates and returns `out`); `carat/domain/docs_text.rb` line 111 and line 83 (rows times quads, the existing scan entry); `carat/domain/buffer.rb` line 85 (`styles` a bare `Array[untyped]` shared by reference from `show_completion_docs.rb` line 111, `show_hover.rb` line 94, `pin_hover.rb` line 57, which also repeat the float buffer build); comment wraps at `show_completion_docs.rb` line 25, `show_hover.rb` line 21, `pin_hover.rb` line 15. Periodic quality, one blocking. Queue item `hover-tidy`.
- Why it matters: `**kwargs` in a code span shows as kwargs; the indent must agree in three places for tokens to land; formatting is quadratic on every selection change.
- Fix outline: keep marker bytes literal inside a code span and fix the row, one `CODE_INDENT`, one heading helper, drop `rows` into the test, a `SyntaxLines` list and one `Buffer.from_docs` (then drop the `styles` line of `UNTYPED_SHARED` in `test/lint.rb`, which exempts it from the shared list rule), rewrap the comments.

## The map and architecture lag plugin API 2.4, FormatDocs, and Config

- Where, at df4654c: `docs/codebase-map.md` line 92 (Config lacks `count`), line 517 (VERSION 2.3, `carat/plugin_api.rb` line 12 is 2.4), line 523 and the area 15 and 16 bullets (PluginHost, Paths, PluginEntries, PluginEntry, Tree methods); `docs/architecture.md` line 181 (5.3 lacks `FormatDocs`, `MarkdownText`, `DocsText`). Periodic quality. Queue item `docs-index`.
- Why it matters: CLAUDE.md keeps both in sync; drift here caused 9 of 47 quality blockers.
- Fix outline: update the bullets and the 5.3 docs line.

## The winbar rule restated in SplitWindow

- Where: `winbar_after?` in `carat/use_cases/windows/split_window.rb` line 55 beside `TabPage#winbar?` (`carat/domain/tab_page.rb` line 61), at df4654c. Periodic quality. Queue item `breadcrumbs-tidy` (the untested scratch split, `test/editor_breadcrumbs.rb` line 188, is already there).
- Why it matters: a breadcrumbs mode change must be made twice.
- Fix outline: one `TabPage` predicate taking the mode and the windows to add.

## The message history name and a doubled clear

- Where: `carat/domain/editor_state.rb` line 20 and `carat/domain/notices.rb` line 76 (`history` holds a `MessageHistory`), `carat/use_cases/handle_key.rb` line 201 (`clear_message` twice per key), at df4654c. Periodic quality. Queue item `messages-tidy`.
- Why it matters: `state.history` reads as the command history; the clear runs twice on every key.
- Fix outline: rename to `message_history`; read the flag, clear once.

## Plugin, grammar, and generator findings at df4654c

- Where: `carat/use_cases/plugins/plugin_router.rb` line 44 (the register string passed uncopied), `carat/domain/manifest_check.rb` line 32 (shapes checked twice, a dead guard at line 145), `carat/use_cases/plugins/plugin_registry.rb` line 175 (`leave` repeats `cause`), `carat/use_cases/plugins/plugin_events.rb` line 142 (a resize event built with no subscriber), `carat/plugins/hello/plugin.rb` line 11 (stale comment, the action spelled beside `GREET`), `carat/plugins/registry.rb` line 2 and the `default_config.rb` header (generator names `spin run`), `test/lint.rb` line 845 (plugins exempt from keyword constructors, unstated in CLAUDE.md), comment wraps at `carat/plugin_api.rb` line 480 and 732, `window_requests.rb` lines 28 and 67, `ui_requests.rb` line 15, `carat/domain/plugin_ui.rb` line 7; `carat/domain/command_grammar.rb` line 138 (`accept` and `accept_visual` repeat a prefix), `carat/adapters/input_controller.rb` line 137 (`next_timeout` ignores `state`). Periodic quality advisories. Queue item 39 (backlog items by domain).
- Why it matters: the router breaks the strings-copied plugin rule; the rest are copies, dead code, and drift.
- Fix outline: `command.register.dup`; one shapes result; pop then set from `cause`; return unless `wanted?("resize")`; reword and key by `GREET`; generator writes `make gen-config`; state the exemption or give `Tree` keywords; rewrap; one shared grammar step; drop the parameter.

## The merger profile may set BASE before the merge gates

- Where: `tools/agent_guard.sh` line 610, at df4654c. Periodic security Low (6). Queue item `guard-lows`.
- Why it matters: `BASE=HEAD` skips the origin ref check and empties the trailer and content scans while the gate still records gated.
- Fix outline: admit `BASE` only for the read profile and have the merge group refuse a base other than `origin/main`, with a `tools/tools_test.sh` case.

## The lint rules of implement-contracts-b rescan and reread

- Where: `test/lint.rb` at the `implement-contracts-b` change: line 1120 reads `File.read(MAP)` again right after `map_problems` read it; line 1139 skips `carat/domain/default_config.rb` in the untyped parameter and shared list rules with no stated reason; line 1145 dedupes the shared list names with `pinned_names.index(name) == j` and rescans every owner per match over parallel arrays; line 1150 rescans `pinned_names` and `pinned_owners` for every assigning line and name. Quality advisories of `implement-contracts-b`.
- Why it matters: the scans are quadratic in names per line and harder to read than the rule they enforce, the map is parsed twice per run, and an unexplained skip invites a wrong copy.
- Fix outline: read the map once into a local passed to both checks; comment that `default_config.rb` is generated, or drop the skip if it holds neither shape; after the pin scan build one Hash from name to its owner paths (or a unique name list and `path + name` owner keys) and test membership in it in both the shared and the owned loops.

## The tools test leaves the MODIFIED scenario and archived attestation paths untested

- Where: `spec_file` in `tools/tools_test.sh` (line 1652 at the `implement-contracts-b` change) has no MODIFIED section, and no case attests a scenario in an archived proposal. Quality advisory of `implement-contracts-b`.
- Why it matters: the MODIFIED branch of `gate_scenarios` and the archive path of the stays attestation in `gate_docs` can break without a failing case.
- Fix outline: add a MODIFIED scenario to `spec_file` and a case whose attestation lives in an archived proposal under `openspec/changes/archive/`.

## Architecture section 10 omits the map method-list lint rule

- Where: `docs/architecture.md` line 343 at the `implement-contracts-b` change, which lists what `test/lint.rb` checks as the code map's coverage only. Quality advisory of `implement-contracts-b`.
- Why it matters: the lint test now also checks the map's method lists, so a reader of section 10 misses why a renamed method fails lint.
- Fix outline: say the code map's coverage and method lists.

## The merge hook leaves the squash title and message unchecked

- Where: `merge_tool` in `tools/agent_guard.sh` line 875 at 3895e21. Periodic security Low (6). Queue item `merge-gate-tidy`.
- Why it matters: the hook checks the method and the expected head only, so a merger steered by branch-controlled CI log text can squash onto main a message holding a URL, a secret, or another trailer the body gate refused.
- Fix outline: refuse a merge whose message differs from the run's body file plus the trailer or whose title is not the pull request title with its number, with a `tools/tools_test.sh` case.

## The docs and scenarios gates split changed path names unquoted

- Where: `gate_docs` in `tools/gates.sh` line 250 (`stays`, nested, reading the caller's `proposals`) and 251 (`for p in $proposals`), and `gate_scenarios` line 279 (`for spec in $deltas`), at 3895e21. Periodic security Low (4) and periodic quality. Queue item `content-gate-gaps`.
- Why it matters: a branch path under `openspec/changes` with a space or a glob character makes the scenarios gate read another spec, skipping a delta's scenarios, or the stays check read another proposal.
- Fix outline: a top-level `stays` function; read names with `git diff --name-only -z` into `while IFS= read -r` loops under `set -f`, each quoted; cases for a spaced and a globbed path.

## The docs gate accepts a self-written unchanged line as proof

- Where: the `unchanged, REASON` attestation of `gate_docs` in `tools/gates.sh`. Retrospective of `implement-contracts-b` (#86). Queue item `implement-contracts-c`.
- Why it matters: #86's one quality blocker was README and help-list drift behind an untrue `README.md unchanged` line the gate accepted; quality first pass 0 there and 17 of 50 overall, doc prose 9 of 47 recorded blockers.
- Fix outline: a case where a branch changes a target's help or a gate list and attests the README unchanged fails the gate; the acceptance is doc-prose blockers at 0 over the next five runs.

## The scenarios gate counts a name found anywhere under test/

- Where: `gate_scenarios` in `tools/gates.sh` line 300 at 3895e21. Periodic quality advisory. Queue item `implement-contracts-c`.
- Why it matters: a scenario passes when its name appears, in any case, as a substring of any file under `test/`, snapshots included, so a short name counts as tested by coincidence.
- Fix outline: match the name only in `.rb` test files and as a whole label or comment.

## The docs gate keeps two overlapping CLAUDE.md checks

- Where: `gate_docs` in `tools/gates.sh` line 236 and the `process_change` check at line 265, at 3895e21. Periodic quality advisory. Queue item `implement-contracts-c`.
- Why it matters: the added-files check takes no proposal escape and the newer one takes the stays escape, so one file can pass one and fail the other, and the header does not say which wins.
- Fix outline: fold the added-files check into `process_change`, or state in the header that additions take no escape.

## The check-pass budget line projects 6 total tokens per output token

- Where: the check-pass budget projection in `tools/run_state.sh`. Retrospective of `implement-contracts-b` (#86). Queue item `phase-shares`.
- Why it matters: total per output token in the last 10 rows is 5.53 to 11.56 (median 7.74, 8 of 10 above 6); all three medium rows went over 1.2M, and #86's check pass said under at 146,753 output while the run ended at 1,998,500 total.
- Fix outline: project from the recorded ratio of comparable rows; the acceptance is the check-pass verdict matching the final over the next three runs.

## A typed count grows without a cap

- Where: `digit` in `carat/domain/command_grammar.rb` line 103 and `take` line 191; `Operators.put` in `carat/domain/operators.rb` line 44; the two `MAX_COUNT` copies in `RegisterCount` and `SubstituteArgs`; at 3895e21. Periodic quality blocking. Queue item `editing-counts`.
- Why it matters: the count is multiplied by the operator count with no limit, so a long count before `p` freezes the editor or exhausts memory, and past 19 digits the 64-bit count wraps.
- Fix outline: cap counts at Vim's 999999999 through one shared constant replacing both `MAX_COUNT` copies; refuse a put past a limit as Neovim's E1240 does; `domain_grammar` and put rows.

## aw and aW take the punctuation after a word

- Where: `carat/domain/text_objects.rb` line 110 at 3895e21. Periodic quality. Queue item `editing-counts`.
- Why it matters: `daw` on `foo` in `foo.bar` or `foo(x)` deletes `foo.` or `foo(`, unlike Neovim and the `docs/compatibility.md` row; no row covers a word before punctuation.
- Fix outline: take the next run only when it is blank, else the blanks before, as the quote and count paths do; `daw` and `yaw` rows before punctuation in `test/editor_text_objects.rb`.

## Put and operator advisories

- Where: `PutOverSelection#repeated` in `carat/use_cases/visual/put_over_selection.rb` line 124 copies the loop of `Operators.put` (`carat/domain/operators.rb` lines 42 to 47); `carat/use_cases/actions/edit_handler.rb` line 50 makes `put_before` the catch-all `else`; `carat/domain/operators.rb` line 4 requires `registers` and `selection`, using neither, and gets `Block` only through them; at 3895e21. Periodic quality. Queue item `editing-counts`.
- Why it matters: two copies of one loop, an unlisted variant silently putting before the cursor, and requires that hide what the file names.
- Fix outline: one repeated-lines function used by both; name `when :put_before` with no catch-all; require `register_entry` and `block`.

## Markup groups widen the plugin API without a version

- Where: `token?` and `token_id` in `carat/domain/highlight.rb` line 163, reached by `Host#syntax_group` (`carat/use_cases/plugins/ui_requests.rb` line 85) and plugin tokens (`carat/use_cases/plugins/plugin_syntax.rb` line 79), at 3895e21; `docs/plugins.md` lines 87 and 116 and `carat/plugin_api.rb` line 713 still say syntax or file-icon groups only. Periodic quality. Queue item `hover-tidy`.
- Why it matters: plugins can now name the six markup groups while `PluginApi::VERSION` stays 2.4 and the docs deny it, an undocumented widening.
- Fix outline: bound both below the first markup group, or document it with a minor bump to 2.5 and a `use_cases_plugin_syntax` row.

## The main loop spins at end of input

- Where: `read_key` in `carat/drivers/ansi_terminal.rb` line 54 and `InputController#pump` in `carat/adapters/input_controller.rb` line 86, at 3895e21. Periodic quality. Queue item 39 (backlog items).
- Why it matters: end of input reads as nil like a timeout, so with stdin closed and no SIGHUP the select returns at once on every pass and the editor spins at full CPU forever.
- Fix outline: record end of input behind a `TerminalPort` predicate (architecture section 6) that `MainLoop#run` stops on, with a `test/drivers_main_loop.rb` row over `FakeTerminal`.

## EditorAssembly names the gateway without requiring it

- Where: `carat/adapters/editor_assembly.rb` line 327 at 3895e21, resolving only through the order of `carat.rb` lines 314 and 322. Periodic quality advisory. Queue item 39 (require orders).
- Why it matters: every other collaborator is required in the file; a reorder of `carat.rb` breaks it.
- Fix outline: add `require_relative "json_rpc_language_gateway"` with the other adapter requires.

## The map lists EditorState#show twice

- Where: `docs/codebase-map.md` line 117 (area 4) at 3895e21. Periodic quality advisory. Queue item `docs-index`.
- Why it matters: the method list is checked by `test/lint.rb`, and a doubled name hides a missing one.
- Fix outline: drop the second `show`.

## Carat::Testing takes a positional constructor with no stated exemption

- Where: `Testing#initialize(name)` in `carat/testing.rb` line 13; `test/lint.rb` line 1000 applies the keyword rule only to layer files, at 3895e21. Periodic quality. Queue item `docs-index`.
- Why it matters: CLAUDE.md names `Carat::Testing` among the classes whose constructors take required keywords, so files outside a layer, plugins included, escape the rule unstated.
- Fix outline: state the exemption beside the keyword rule in CLAUDE.md, or move to `initialize(name:)` across the tests.

## paint_float_row fills the row in both branches

- Where: `carat/adapters/frame_presenter.rb` lines 613 and 617 at 3895e21. Periodic quality advisory. Queue item `bars-tidy`.
- Why it matters: the same fill is written twice under one condition.
- Fix outline: one fill after the text or blank and before `paint_tokens`.

## HandleKey restates KeyHints#showing?

- Where: `carat/use_cases/handle_key.rb` line 131 at 3895e21, `float_id != 0` where `HideKeyHints#call` checks `showing?` again. Periodic quality advisory. Queue item `discoverability-tidy`.
- Why it matters: two spellings of one test drift apart.
- Fix outline: `@hide_key_hints.call(state) if @key_hints.showing?`.

## metrics.sh ignores a failed field read

- Where: `tools/metrics.sh` lines 55 and 57 at 3895e21 (`set --` from `analysis_budget.sh --fields`). Periodic quality advisory. Queue item `run-budgets-tidy`.
- Why it matters: a failure stops on `set -u` with an unclear message and leaves the temporary output file.
- Fix outline: read the fields into a variable with `|| die`, check both, and remove the temporary file on failure.

## The outside-the-root refusal is built four times

- Where: `carat/use_cases/files/resolve_inside.rb` line 41, `delete_path.rb` line 39, `make_path.rb` line 37, and `rename_path.rb` line 42, at 3895e21. Periodic quality. Queue item `file-access-tidy`.
- Why it matters: the wording of one refusal lives in four places.
- Fix outline: one domain function returning the message, called by the four.

## Two ex handlers keep forwarding-only constructors

- Where: `carat/use_cases/ex/messages_command_handler.rb` line 14 and `carat/use_cases/ex/syntax_command_handler.rb` line 14 at 3895e21. Periodic quality. Queue item `messages-tidy`.
- Why it matters: dead code; each only forwards `spec` to `ExHandler#initialize`.
- Fix outline: delete both constructors.

## BufferWords repeats the menu's cap and exposes more than it needs

- Where: `carat/domain/buffer_words.rb` at eb0b1ae: `LIMIT = 200` (line 24) repeats `CompletionList::LIMIT`; `done?` (line 52) is public though only `BufferWords` calls it; `collect` (line 38) on a `Struct` subclass shadows `Enumerable#collect`, which `Struct` includes, with an unrelated signature. Quality advisories in `word-completion`.
- Why it matters: the two caps can drift so the scan keeps more or fewer words than the menu shows; the public `done?` widens the surface the backlog already trims; a reader expecting `Enumerable#collect` meets a different method, and a later caller of the block form gets the wrong one.
- Fix outline: use `CompletionList::LIMIT` in `done?` and `scan_line` and drop the constant; move `done?` under `private` and drop it from its map entry; rename `collect` (for example `gather` or `scan_from`) in `CompleteWord` and the map. Queued in `completion-tidy`.

## BufferWords slices every match before the duplicate check

- Where: `take` in `carat/domain/buffer_words.rb` line 133 at eb0b1ae. Quality advisory in `word-completion`.
- Why it matters: the byteslice of every match is allocated before it is compared with the kept words, so an empty prefix over a large buffer allocates one string per word occurrence up to the byte bound, though few of them are new.
- Fix outline: compare the candidate's bytes against the kept words before slicing, or bound the duplicate case, with a benchmark row for Ctrl-N on an empty prefix over a large buffer. Queued in `completion-tidy`.

## CompleteWord copies ShowCompletion's word-before-cursor step

- Where: `carat/use_cases/completion/complete_word.rb` line 47 at eb0b1ae (head, word start, prefix, column) against `ShowCompletion#refresh` in `carat/use_cases/completion/show_completion.rb` lines 74 to 77. Quality advisory in `word-completion`.
- Why it matters: the two copies decide what the word before the cursor is; a fix to one (a multibyte boundary, a keyword character option) misses the other, and the keyword and server popups then disagree on the prefix.
- Fix outline: one domain step answering a small `Data` record of the prefix, its byte start, and its column, called by both use cases, with their existing rows unchanged. Queued in `completion-tidy`.

## Every completion handler variant holds CompleteWord

- Where: `CompletionHandler` in `carat/use_cases/actions/completion_handler.rb` line 28 at eb0b1ae, whose every popup variant now takes `complete_word` though only the two `keymap.insert` variants (`completion.keyword_next`, `completion.keyword_previous`) use it. Quality advisory in `word-completion`.
- Why it matters: the popup handlers carry a collaborator they never call, widening the handler the backlog already records as repeating its constructor.
- Fix outline: a separate `KeywordCompletionHandler` holding only `CompleteWord` and registering the two keyword actions, wired in `EditorAssembly` with its `docs/actions.md` rows unchanged. Queued in `completion-tidy`.

## Completion docs lag the word-completion change

- Where: the class comment of `carat/use_cases/completion/show_completion.rb` line 25 at eb0b1ae runs past the file's wrap width; the section 5.1 completion list of `docs/architecture.md` line 167 names `CompleteWord` but not the shared `OpenCompletionPopup`. Quality advisories in `word-completion`.
- Why it matters: the long line breaks the file's style, and a reader of section 5.1 cannot find the use case that opens the popup float both completion paths share.
- Fix outline: rewrap the paragraph, and add `OpenCompletionPopup` to the 5.1 list as the popup float `ShowCompletion` and `CompleteWord` share. Queued in `completion-tidy`.

## Keyword completion skips the word right after the cursor on an empty prefix

- Where: `carat/domain/buffer_words.rb` line 64 at 8f486e0, where the scan of the cursor's line starts at `start + 1` and the final `0...start` slice ends before `start`. Quality advisory in `word-completion`.
- Why it matters: with no word before the cursor, the word starting at the cursor column is never offered from that spot, though the completion spec says every word matches with an empty prefix.
- Fix outline: scan from `start` rather than `start + 1` when the prefix is empty (or narrow the spec wording to match Neovim), with a table row for a cursor placed before a word. Queued in `completion-tidy`.

## Typing after Ctrl-P selects the farthest match

- Where: `carat/use_cases/completion/show_completion.rb` line 98 at 8f486e0, which refilters the reversed word list of a Ctrl-P menu and selects row 0. Quality advisory in `word-completion`.
- Why it matters: the Ctrl-P popup selects the nearest match, but after one typed character the selection jumps to the farthest one.
- Fix outline: keep the last row selected when the menu was filled backward, through a direction flag on the menu set by `CompleteWord`, with a row for Ctrl-P followed by a typed character. Queued in `completion-tidy`.

## No test pins that typing with no popup costs nothing more

- Where: `test/editor_word_completion.rb` at 8f486e0 has no row for the spec scenario Typing costs nothing more (no buffer scan and no extra allocation per key with no popup). Quality advisory in `word-completion`.
- Why it matters: a change that scans the buffer on every insert-mode key would pass the suite unseen.
- Fix outline: assert that typing in insert mode with no popup leaves the menu unfilled, or add a bench scenario row that pins the allocations. Queued in `completion-tidy`.

## Only gd adds to the jump list, and the list is one for the editor

- Where: `carat/domain/jump_list.rb` and its one caller that pushes, `VisitTarget` in `carat/use_cases/definitions/visit_target.rb`, from the `definitions` change (out of scope there).
- Why it matters: in Neovim `G`, `gg`, searches, `n`, `%`, marks, `:N`, and buffer switches also add to the jump list, kept per window and listed by `:jumps`, so Ctrl-O after a search or a `G` does nothing in carat.
- Fix outline: push the position left from the jump motions (a jump flag on the motion handlers, pushed by the dispatcher when the cursor moved by more than a line), move the list into `Window` (copied on a split), and add `:jumps`, each with a row in `docs/compatibility.md` and `test/adapters_definitions.rb` or an editor test. Folded into the backlog items worth a change (queue item 37). When the jump motions arrive, move the `jump.older` and `jump.newer` handlers from `DefinitionHandler` (`carat/use_cases/actions/definition_handler.rb` line 52 at fafe59c) to a `JumpHandler`, since the list is not definition-specific (quality advisory in `definitions`).

## Definition target paths keep decoded control bytes

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 789 at fafe59c, `path_of`, which refuses a raw or escaped NUL but keeps a decoded `%0A` or `%1B`. Security Low (5) and quality advisory in `definitions`. Owned by queue item 13, `bidi-controls`.
- Why it matters: a hostile language server can put a newline or ESC into a target path, which reaches the read-only and E484 message text (split into extra message lines by `TextLines.split`), the read-only view's title, the float title, and a pick-list buffer line that then holds a newline, breaking the one-line invariant. `Frame#put_from` replaces every control with U+FFFD, so no escape sequence reaches the terminal.
- Fix outline: in `path_of`, return "" when a decoded byte is below 0x20 or is 0x7F, as a NUL is refused (or pass the path through `Domain::ControlText.strip` before it is stored), with rows in the escapes test of `test/adapters_definitions.rb` for a URI holding `%0A` and `%1B`.

## File URI decoding is hand-rolled inside the language gateway

- Where: `carat/adapters/json_rpc_language_gateway.rb` lines 789 to 850 at fafe59c, `path_of`, `escaped`, and `hex_value`, far from `uri_of`; `test/adapters_definitions.rb` line 338 covers only `%2E` and `%00`. Quality advisories in `definitions`.
- Why it matters: about twenty lines validate UTF-8 by hand (lead size, continuation bytes, overlongs, surrogates, range, `pack("U")`) in an adapter of over 1200 lines, and that multibyte branch has no test, so a regression in it would pass the suite.
- Fix outline: move the decoding into a domain value (a `FileUri` with `path_of` beside the encoding of `uri_of`) tested in a domain test; decode each escape to its byte and refuse unless `out.valid_encoding?`, as `OpenFile` already relies on; add rows for a `%C3%A9` path that opens and an overlong `%C0%AE` and a surrogate `%ED%A0%80` that are skipped.

## The definition answer loop stops before LIMIT targets are kept

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 753 at fafe59c, `defined`, which reads only the first `DefinitionRequest::LIMIT` entries of an answer even when some were skipped as non-file, while `DefinitionRequest#add_target` caps the kept targets again. Quality advisory in `definitions`.
- Why it matters: an answer whose first entries are not files drops file targets that follow, and the cap is held in two places.
- Fix outline: scan a bounded number of entries larger than `LIMIT` (or until `LIMIT` are kept) and keep the one cap in `add_target`, with a row whose first entries are non-file.

## gd inside a focused float works on the float

- Where: `carat/use_cases/definitions/visit_target.rb` lines 70 and 83 at fafe59c, `jump` and `place`, which use `state.window`, the focused float when one is entered, while `RequestDefinition` asks at `state.tab.layout_window`. Quality advisory in `definitions`; the Ctrl-O and Ctrl-I part was fixed in the change, `WalkJumps` doing nothing while a float has the focus.
- Why it matters: `gd` inside an entered hover float pushes the float's scratch buffer onto the jump list and loads the target into the float, since `BufferList#load` shows into `tabs.window`.
- Fix outline: refuse `definition.*` while a float is focused, as `WalkJumps` does, or close the focused float first and work on the layout window, with a row pressing `gd` in an entered hover float.

## A plugin's keymap.pick line is silently ignored

- Where: `carat/domain/keymap.rb` line 181 at fafe59c, `apply`, which checks a `keymap.pick` line on a throwaway keymap whatever its owner, while `pick_from` binds only the configuration's lines. Quality advisory in `definitions`.
- Why it matters: a plugin manifest line `keymap.pick ...` is accepted without a problem and has no effect, so its author gets no report.
- Fix outline: refuse it as "a plugin cannot set keymap.pick" when the owner is not empty, as `keymap.leader` is refused, with a row in `test/domain_keymap.rb`.

## JumpList#step pushes before the bounds check

- Where: `carat/domain/jump_list.rb` line 55 at fafe59c, `step`, whose comment says -1 past either end with nothing moved, but going older from the newest end pushes the position before the check, so Ctrl-O on an empty list adds an entry. Quality advisory in `definitions`.
- Why it matters: the comment misleads the next reader, and a refused Ctrl-O on an empty list leaves an entry Ctrl-I can reach.
- Fix outline: check the target before pushing (an empty list answers -1 at once), or reword the comment, with a row for Ctrl-O on an empty list.

## Definition float and row clamp copy other use cases

- Where: `carat/use_cases/definitions/open_definition_float.rb` line 30 at fafe59c duplicates `ShowHover#open` (`carat/use_cases/docs/show_hover.rb` line 74): the below-or-above placement, height, width, and `FloatSpec`; `carat/use_cases/definitions/walk_jumps.rb` lines 51 to 53 repeat the row clamp of `VisitTarget#place` and `#clamp` (`visit_target.rb` lines 180 and 187). Quality advisories in `definitions`.
- Why it matters: section 5 of `docs/architecture.md` moves logic several use cases share into the domain or one use case; two copies of the cursor-float placement drift apart.
- Fix outline: have `ShowHover` open its float through the one use case (named for what it does, such as `OpenCursorFloat`) or move the placement into a domain helper both call; add `EditorState#clamp_row` beside `clamp_col` and call it from `WalkJumps` and `VisitTarget`.

## HandleKey takes the definition record beside its follower

- Where: `carat/use_cases/handle_key.rb` lines 105 to 129 at fafe59c, which take both `definition:` and `follow_definition:`, where the hover is read as `follow_hover.hover`. Quality advisories in `definitions`.
- Why it matters: the extra keyword duplicates wiring the follower already holds and widens the constructor and `EditorAssembly`'s call.
- Fix outline: set `@definition = follow_definition.definition` and drop the keyword from `HandleKey` and `EditorAssembly`, keeping `test/adapters_assembly.rb`'s shared-instance check.

## Two comments left unwrapped by the definitions change

- Where: `carat/use_cases/files/open_file.rb` line 20 (127 columns) and `carat/use_cases/handle_key.rb` line 63 at fafe59c. Quality advisories in `definitions`.
- Why it matters: the rest of each comment wraps near 72 columns, so the lines read as broken.
- Fix outline: rewrap both paragraphs at the file's width.

## Definition commands lack a table-driven test

- Where: `test/adapters_definitions.rb` line 184 at fafe59c, which the `gd`, Ctrl-O, and Ctrl-I rows of `docs/compatibility.md` point at, a sequence of asserts. Quality advisory in `definitions`.
- Why it matters: CLAUDE.md asks a table-driven test of each Neovim command; the answer shapes (Location, list, LocationLink, escapes, relative, NUL, negative, non-file) fit a table and would be easier to extend.
- Fix outline: a `t.table` of answers to the position or message reached.

## A symlinked working directory opens the edited file read-only

- Where: `carat/use_cases/definitions/visit_target.rb` line 166 at fafe59c, `absolute`, and `inside?` at line 160, which compare against the working directory as given. Quality advisory in `definitions`.
- Why it matters: with a symlinked working directory and a server answering resolved paths, a target in the edited file compares unequal and fails `inside?`, so `gd` opens a read-only duplicate view instead of jumping.
- Fix outline: also compare against the resolved working directory, with a row for a symlinked working directory.

## Map entries miss the definitions change's names

- Where: `docs/codebase-map.md` line 523 at fafe59c, the `path_info.rb` entry, which does not name `refusal` and `BUFFER_LIMIT`, and line 612, the `json_rpc_language_gateway.rb` entry, which does not name `textDocument/definition`. Quality advisory in `definitions`.
- Why it matters: the map is where a change starts; a missing name sends the next reader searching.
- Fix outline: add both to their entries.

## A resume of finished tasks reruns plan and scouts and grants a fourth round

- Where: `.claude/workflows/deliver-change.js`, the resume and round limit. Retrospective, `extra-round`, and `overrun` notes of `definitions`, queued in `run-resume`.
- Why it matters: `definitions` resumed at 73baf73 with 6 of 6 tasks done, spent 117,076 of 474,458 output tokens (24.7%) on plan and scouts, and was granted round 4, which took output from 389,765 to 436,791, past the large budget of 416,666.
- Fix outline: decide which phases a resume repeats (a done, unchanged branch starts at check) and count rounds across starts, stopping at 3, with cases.

## A failed backup is retried by every start and never recorded

- Where: `tools/run_state.sh backup` and the contributor's start. Retrospective of `definitions`, queued in `backup-records`.
- Why it matters: four contributor starts made 11 attempts, all refused by the remote, with no run-state key, leaving 10 or more commits local only until the package push.
- Fix outline: write a run-state key on a failed backup, make at most one attempt per later start when it is set, and name the unbacked commits in the report, with a case.

## The docs and scenarios gates misjudge their inputs

- Where: `tools/gates.sh` line 250 (`gate_docs` defines `stays` inside its body), line 238 against 262 (two overlapping CLAUDE.md checks, one excused cause printing two FAIL lines), line 288 (`gate_scenarios` accepts a name found anywhere under `test/` or in `tools/tools_test.sh` fixtures, or as a substring). Periodic quality at 8d8832f, queued in `content-gate-gaps`.
- Why it matters: a scenario with no proving test passes when a fixture holds its words, and a proposal's excuse line is refused by the older check.
- Fix outline: define helpers at top level; fold the two CLAUDE.md checks into one; match a scenario only as a whole label or comment outside the fixtures, with cases.

## The CI checkout keeps the job token for every later step

- Where: `.github/workflows/ci.yml` line 36, `actions/checkout`. Periodic security Low (4) at 8d8832f, queued in `ci-hardening`.
- Why it matters: every later step runs the pull request's own Makefile and scripts with the read-only token in `.git/config`.
- Fix outline: set `persist-credentials: false`, since `tools/ci_scope.sh` uses the token through `gh`.

## The contributor's pull request tools have no guard hook

- Where: `.claude/agents/contributor.md` line 4, the GitHub create and update pull request tools. Periodic security Low (5) at 8d8832f, queued in `guard-lows`.
- Why it matters: a misled contributor can retarget a pull request's base, close or reopen one, or write a body the pr-body gate sees only at the merge.
- Fix outline: a PreToolUse matcher for those tools running main's guard, admitting only base main, the run state's branch as head, and a body passing pr-body, with a `tools/tools_test.sh` case.

## The pick keymap binds a line refused as an unknown action

- Where: `carat/domain/keymap.rb` line 100, `pick_from`, and `test/domain_keymap.rb` line 194. Periodic quality at 8d8832f, queued in `definitions-tidy`.
- Why it matters: `keymap.pick zq foo.bar` is reported as unknown yet bound, answering Not implemented, against the test's comment.
- Fix outline: bind only the pick lines the action check accepted, and assert `zq` is unbound in the pick keymap.

## The definition column walk copies the gateway's UTF-16 walk

- Where: `carat/use_cases/definitions/visit_target.rb` line 196, `column_of`, against `JsonRpcLanguageGateway#utf16_offset` and `#utf16_length` (lines 1111 and 1157); the cursor-float widest-row loop in `show_completion_docs.rb` line 100 and `show_key_hints.rb` line 128 beside the entry "Definition float and row clamp copy other use cases". Periodic quality at 8d8832f, queued in `definitions-tidy`.
- Why it matters: two UTF-16 walks drift apart on multibyte text; the float loop has four copies.
- Fix outline: one domain UTF-16 helper used by both, with multibyte rows; one owner for the float sizing.

## Docs drift found by the periodic review at 8d8832f

- Where: `docs/codebase-map.md` line 140 (InputController omits ShowDefinition), 150 (HandleKey omits FollowDefinition), 117 (EditorState lists `show` twice), 520 (area 15 says plugin API 2.3, `carat/plugin_api.rb` line 12 is 2.4), 523 and 624 (PathInfo omits `refusal` and `BUFFER_LIMIT`, DefinitionRequest omits `clear_targets`, `target_count`, `LIMIT`, `OWNER`), the buffer.rb line (omits `display_name`, `path_text`, `byte_count`, `signs?`, `transaction_size`; `Buffer#blanks` at `carat/domain/buffer.rb` line 457 public but used only inside); `docs/architecture.md` line 167 (no OpenCompletionPopup), 178 (no OpenFloat, CloseFloat, ListBuffers, SwitchBuffer, DeleteBuffer); `README.md` line 9 and CLAUDE.md Stack name no `node`, which `make doctor` (Makefile line 173) needs for `tools/tools_test.sh` line 2030. Queued in `docs-index`.
- Why it matters: the map and the architecture are where a change starts, and a clone following the README fails its first `make check` stage.
- Fix outline: add the names, drop the duplicate, write 2.4, move `blanks` below `private`, and name `node` or say why it is outside the prerequisites.

## A failed spec preview is deleted by the next change's preview

- Where: `tools/spec_validate.sh` line 129. Periodic quality at 8d8832f, queued in `run-budgets-tidy`.
- Why it matters: the header promises a failed preview is kept for reading, but each active change resets it.
- Fix outline: one preview directory per change, or stop resetting after a failure, with a case.

## Search copies its prompt split and its E486 message

- Where: `carat/use_cases/search/find_match.rb` line 68 against `preview_search.rb` line 106 (the `pattern_end` split on bytes 47 or 63), and line 163 against `substitute_lines.rb` line 143 (the E486 literal). Periodic quality at 8d8832f, queued in `search-tidy`.
- Why it matters: a fix to one split or message misses its copy.
- Fix outline: one domain helper for each, used by both callers.

## Domain motion and text-object structure

- Where: `carat/domain/walker.rb` line 63 calls `Motions.code_class` while `motions.rb` requires `walker.rb` (a cycle held by load order), and line 11's comment omits the bracket objects; `carat/domain/text_objects.rb` line 252 builds a Walker with no require, line 86 and `carat/domain/runs.rb` name a local `cls`; `carat/domain/motions.rb` line 197 and 228 repeat an edge refusal and row clamp, line 579 a dead store; `carat/use_cases/delete_lines.rb` line 28 copies `Operate#delete`'s linewise placement (`operate.rb` line 142, also `global_command.rb` line 150); `carat/domain/operators.rb` lines 172 and 251 copy the effective shift width rule. Periodic quality at 8d8832f, queued in item 37.
- Why it matters: the cycle breaks under a changed require order, and each copied rule drifts.
- Fix outline: move the character classes into one module both require; rename `cls` to `char_class`; one row-clamp helper; an `Options#shift_width` beside `tab_width`.

## Plugin host requests answer shared strings and stale comments

- Where: `carat/use_cases/plugins/ui_requests.rb` line 78 (`icon` answers the shared glyph) and 107 (`run_ex` answers the message uncopied); `window_requests.rb` line 90 (`open_scratch` keeps the plugin's title string); unused requires in `carat/adapters/status_bar.rb` line 1 and `plugin_syntax.rb` line 1, `plugin_events.rb` line 6 requires `buffer_feed` for `BufferNotice`; stale comments at `carat/adapters/sgr_table.rb` line 8, `plugin_syntax.rb` line 69, `ui_requests.rb` line 81; `plugin_registry.rb` line 175 repeats `cause`; `plugin_events.rb` line 142 queues a resize no plugin wants. Periodic quality at 8d8832f, queued in item 37.
- Why it matters: CLAUDE.md copies strings both ways at the plugin API, so a plugin appending to an answer changes the editor's icons or a buffer title.
- Fix outline: copy each answered and stored string, with rows; fix the requires and comments; return early when no plugin wants the event.

## Signature help compares bare key codes

- Where: `carat/use_cases/handle_key.rb` line 364, the literals 40 and 44 for `(` and `,`. Periodic quality at 8d8832f, queued in `signature-tidy`.
- Why it matters: bare codes hide which characters trigger signature help.
- Fix outline: name them as key constants or compare the character.

## Plugin file reads and listings are not contained in a root

- Where: `carat/use_cases/plugins/file_requests.rb` line 71, the `read_file` and `list_files` requests. Security review of `file-finder`, Low (3).
- Why it matters: unlike the make, rename, and delete requests, which check that the path is inside a root, an enabled plugin can read the first 1000 lines of any regular file under 256 KiB the user can read (for example `~/.ssh` keys) and list any directory tree. Every plugin is compiled in and trusted today, so this only hardens the plugin boundary.
- Fix outline: have `read_file` and `list_files` take a root like the mutating requests, resolve the path with `ResolveInside` or `real_path` plus `Paths.inside?` before reading or walking, and have the finder pass its working-directory root, with a refusal row.

## The finder's file cap has no test

- Where: `carat/use_cases/plugins/file_requests.rb` line 64, the `MAX_FILES` cap of `list_files` (`ListTree`'s limit and the `Listed the first N files` message the finder shows). Quality review of `file-finder`.
- Why it matters: the cap and its message can break unnoticed.
- Fix outline: test `ListTree#call` with a small limit in `test/use_cases_plugin_files.rb` and the message at the cap.

## A resize with the finder open is untested

- Where: `carat/plugins/finder/plugin.rb` line 102, which re-lays the floats on a resize and turns the preview on or off at 100 columns. Quality review of `file-finder`.
- Why it matters: the preview's width threshold on a resize has no row.
- Fix outline: add a `test/editor_finder.rb` row that resizes the harness from 80 to 120 columns with the finder open and expects the preview float.

## Plugin keymap errors are recorded by two copies of one loop

- Where: `carat/use_cases/plugins/ui_requests.rb` line 84 and `WindowRequests#open_scratch` in `carat/use_cases/plugins/window_requests.rb` line 94, each recording a keymap error as `plugin NAME: binding ERROR`. Quality review of `file-finder`.
- Why it matters: a change to the message or the parsing has to be made twice.
- Fix outline: one shared helper, for example on `PluginRegistry`, that builds a plugin's keymap from its lines and records the errors, called from both.

## HandleKey reaches the plugin UI through the plugins

- Where: `carat/use_cases/handle_key.rb` line 117, which takes the shared `PluginUi` through `plugins.plugin_ui` instead of a `plugin_ui:` keyword from `EditorAssembly`, and keeps it with no reader. Quality review of `file-finder`.
- Why it matters: unlike `palette:`, `signature:`, and the other shared records, `test/adapters_assembly.rb` cannot check that `HandleKey` holds the one instance.
- Fix outline: pass `plugin_ui:` from `EditorAssembly`, add a reader, and check it in `test/adapters_assembly.rb`.

## The finder re-reads its preview on every key

- Where: `carat/plugins/finder/plugin.rb` line 276, `refresh`, which reads the highlighted file (up to 256 KiB) through `read_file` on every keystroke and highlight move. Quality review of `file-finder`.
- Why it matters: typing a query re-reads the same file when the highlighted path does not change.
- Fix outline: keep the last previewed path, height, and lines, and read again only when the path or the height changed.

## The finder's sort key relies on the host's file cap

- Where: `carat/plugins/finder/matcher.rb` line 25, `INDEX_BITS` 20 (1,048,575 indexes), and `MAX_FILES` of 100,000 in `carat/use_cases/plugins/file_requests.rb` line 20. Quality review of `file-finder`.
- Why it matters: a cap above `INDEX_ROOM` would silently corrupt the packed keys.
- Fix outline: say so beside `INDEX_ROOM`, or skip indexes above `INDEX_ROOM` in `Plugin#filter`.

## Small tidy-ups in the finder and the plugin host

- Where: `carat/plugins/finder/matcher.rb` line 1 requires `plugin_api.rb` but uses nothing from it; `carat/plugins/finder/plugin.rb` line 29, `OPEN`, names one action used once in `on_action` while the manifest and the other branches spell action names as literals; `carat/use_cases/plugins/plugin_host.rb` line 194, `follow_prompt`, dups the text into `prompt_seen` and `PluginRouter#follow_prompt` dups it again. Quality review of `file-finder`.
- Why it matters: a dead require, an inconsistent naming of actions, and a second string copy per prompt key.
- Fix outline: drop the require; drop `OPEN` and compare against the literal (or name every action the same way); dup once, in the router where the value crosses to the plugin.

## The finder's normal-mode Ctrl-P differs from Neovim unsaid

- Where: the File finder section of `docs/compatibility.md` (line 493). Quality review of `file-finder`.
- Why it matters: normal-mode `<C-p>` moves the cursor up a line in Neovim; the finder takes it without saying so.
- Fix outline: note the difference in the section, removable with `keymap.normal <C-p> none`.

## Eight Vim messages are spelled in more than one file

- Where: `KNOWN_REPEATED_MESSAGES` in `test/lint.rb`: E32 (`file_command_handler.rb`, `save_file.rb`), E33 (`vim_pattern.rb`, `substitute_lines.rb`), E474 (`history_command_handler.rb`, `messages_command_handler.rb`), E477 (the delete, global, and substitute command handlers), E484 (`path_info.rb`, `visit_target.rb`, `open_file.rb`), E486 (`find_match.rb`, `substitute_lines.rb`), E488 (`register_count.rb`, `substitute_args.rb`, and the buffer, LspRestart, and LspStart command handlers), E939 (`register_count.rb`, `substitute_lines.rb`). Recorded by `implement-contracts-c`, queued in `messages-tidy`.
- Why it matters: a wording fix can reach one copy and miss the others; lint refuses a new repeat but keeps these listed.
- Fix outline: one `Domain::Messages` constant or function per message, called from every file, and the line removed from `KNOWN_REPEATED_MESSAGES` (lint fails on a listed message that no longer repeats).

## An unknown file action variant writes every buffer and quits

- Where: `carat/use_cases/actions/file_handler.rb` line 37: removing `file.find` turned the case's `else` into the `:write_all` branch. Periodic quality at 186ddfb, blocking, queued in `periodic-blockers-b`.
- Why it matters: a new or misspelled variant registered in `self.register` silently writes every buffer and quits; a latent correctness defect.
- Fix outline: restore `when :write_all then write_quit_all(state)` and let no variant fall through to it, with a row.

## The package step adds a backlog entry that already exists

- Where: the contributor's package step; the `palette_add_plugin` entry was recorded twice (folded at 186ddfb). Periodic quality at 186ddfb, blocking, queued in `periodic-blockers-b` (the compaction itself is `backlog-compaction`).
- Why it matters: a repeat hides what is left and double-counts a tidy item.
- Fix outline: have the package step search the backlog for the same file and method before adding an entry.

## EditorState's class comment is wrapped unevenly

- Where: `carat/domain/editor_state.rb` line 13 (101 columns, lines 14 to 16 short and long in turn). Periodic quality at 186ddfb, blocking, queued in `periodic-blockers-b`.
- Why it matters: the layer's comments wrap at 72 columns.
- Fix outline: rewrap the class comment.

## Security Lows of the periodic review at 186ddfb

- Where: `tools/spec_validate.sh` line 17 runs the unpinned `npx -y @fission-ai/openspec@latest`, Low (5), queued in `ci-hardening`; `JsonRpcLanguageGateway#path_of` (`carat/adapters/json_rpc_language_gateway.rb` line 789) keeps `.` and `..` segments, so `VisitTarget`'s lexical inside check passes a path only `ResolveInside` refuses, Low (4), queued in `bidi-controls`; `list_dir` and `read_file` in `carat/use_cases/plugins/file_requests.rb` (lines 47 and 72) take any path with no root, Low (3), queued in `file-access-tidy`.
- Why it matters: a compromised npm release runs with push credentials; one file gets different titles and keys; a plugin joining an unchecked name reads outside the project.
- Fix outline: pin the version in one `OPENSPEC_VERSION` variable used by CLAUDE.md, the Makefile, and the script; return `PluginApi::Paths.normalize(out)` from `path_of` with a `..` row; take a root and require `Paths.inside?` and `ResolveInside`, with rows.

## Search and prompt findings of the periodic review at 186ddfb

- Where: `carat/use_cases/search/preview_search.rb` line 57 sets the cursor column unclamped (a `$` match stands past the last character); `carat/domain/search_prompt.rb` line 186 `restore` clamps to the line length, not length - 1; `carat/domain/vim_pattern.rb` line 23 lists the escapes t, e, and r twice; `carat/use_cases/search/find_match.rb` line 134 `blank?` repeats `Motions.code_class(code, false) == 0`. Periodic quality at 186ddfb, queued in `search-tidy`.
- Why it matters: two normal-mode cursors off the line, a doubled comment, a repeated class check.
- Fix outline: clamp through `state.clamp_col`, clamp `restore` to length - 1 (0 on an empty line), each with an `editor_search` row; drop the second list; define `blank?` through `code_class`.

## Bar and frame findings of the periodic review at 186ddfb

- Where: `carat/adapters/status_bar.rb` line 1 requires `../plugin_api` and names none of it; `carat/adapters/frame_presenter.rb` line 299 `display_col` and `display_width` are public but used only inside; line 485 `paint_notice_row` draws the rounded border again beside `paint_border_row` (line 654); `NO_NAME` is defined in `status_bar.rb` line 47, `tab_bar.rb` line 23, and `winbar.rb` line 214. Periodic quality at 186ddfb, queued in `bars-tidy`.
- Why it matters: a dead require, a wide public surface, two border painters and three constants to keep in step.
- Fix outline: drop the require; move `display_width` below `private` and drop `display_col` (update the area 13 entry); one border painter with a plain flag; one `[No Name]` on `Domain::Buffer`.

## Docs and spec drift found by the periodic review at 186ddfb

- Where: `openspec/specs/leader-keys/spec.md` line 43 and its scenario at line 49 still say `<leader>ff` shows "Not implemented: file.find"; `docs/codebase-map.md` line 527 (PluginHost omits `follow_prompt`), 617 and 582 (the gateway entry and the area 17 Flow omit the definition request), 465 (DisplayWidth lists the dead `of_char`, omits `code_cells`), 466 (DecodedLine omits `size`), 502 (Keywords omits `value?`), 565 (Tree omits `root`, `marked`, `expanded?`, `count`, `node`). Periodic quality at 186ddfb, queued in `docs-index`.
- Why it matters: a source-of-truth spec contradicts the code, and the map is where a change starts.
- Fix outline: a MODIFIED delta of `leader-keys` saying `<leader>ff` opens the finder, and the names added or dropped.

## Copies and placement found by the periodic review at 186ddfb

- Where: `ListTree#probe` (`carat/use_cases/files/list_tree.rb` line 65) repeats `ProbePath#call` and asks the port itself, against `docs/architecture.md` section 5, queued in `file-access-tidy`; `CompleteWord` (`carat/use_cases/completion/complete_word.rb` line 47) copies the word-before-cursor slice of `show_completion.rb` lines 74 to 77, queued in `completion-tidy`; `Layout#fixed_width?` (`carat/domain/layout.rb` line 299) is used only by its test, queued in `slots-tidy`; `JumpList#step` (`carat/domain/jump_list.rb` line 55) pushes before the range check, so Ctrl-O on an empty list adds an entry, queued in `definitions-tidy`; `Icons::NAMES` (`carat/domain/icons.rb` line 13) is read nowhere and `DecodedLine` and `Cell` (`decoded_line.rb` line 15, `cell.rb` line 274) are never-changed values declared as `Struct`, queued in `theme-tidy`. Periodic quality at 186ddfb.
- Why it matters: two probes and two slices drift; dead surface; a jump that answers nothing moved after adding an entry; records against the Data rule.
- Fix outline: inject the one `probe_path:` into `ListTree` and use `Domain::PathPolicy.inside?`; one domain prefix helper; delete `fixed_width?`; return -1 before the push with a `test/domain_jump_list.rb` row; test `NAMES` against each set or drop it; `Data` subclasses or the Spinel reason in the comment.

## Small findings of the periodic review at 186ddfb

- Where: dead code `TabRequest#counted?` (`carat/use_cases/windows/tab_request.rb` line 13), `UndoTree#undo_seq` and `#redo_seq` (`carat/domain/undo_tree.rb` lines 173 and 179, with the stale comment at 185), the dead store `row = top` (`carat/domain/motions.rb` line 579), `DisplayWidth.of_char` (`display_width.rb` line 133), `DecodedLine#cells` (line 91), `Cell#same?` (line 286); `Config#binding?`'s comment (`carat/domain/config.rb` line 205) omits the leader lines and lines of other word counts it keeps; the finder's `open_path` and `report` (`carat/plugins/finder/plugin.rb` line 314) copy the explorer's (lines 277 and 534); the finder matcher's helpers (`matcher.rb` line 55) are public and `lower(b)` takes a one-letter name; `PluginRouter#answer` (line 77) hands the plugin `prompt_id` uncopied; the explorer's `@followed` (`carat/plugins/explorer/plugin.rb` line 420) stays on the old path after its parent directory is renamed; `Frame::REPLACEMENT` (`frame.rb` line 36) repeats `Utf8::REPLACEMENT`. Periodic quality at 186ddfb, queued in the backlog batches.
- Why it matters: dead surface and map mentions, a misleading comment, two open dispatches, a strings-copied breach, a mark on a path that no longer exists.
- Fix outline: delete the dead code and its map mentions; fix the comment; one `PluginApi` opening helper or an entry per plugin; `private_class_method` where Spinel allows and `byte`; `id.dup`; `@followed = tree.marked` after `tree.moved` with a directory-rename case; `REPLACEMENT = Utf8::REPLACEMENT`.

## The reader shadow check skips classes whose name ends in end

- Where: `shadow_problems` in `test/lint.rb` line 1019 at e0bca07, which skips any `class` or `module` line ending in `end`. Quality advisory in `implement-contracts-c`.
- Why it matters: the skip is meant for one-line bodies, but a class named `Backend`, `Append`, or `Legend` also ends in `end` and is silently never checked; no such class exists today.
- Fix outline: skip only a one-line body (the head holds `;`, as in `; end`), and add a `class Backend` case to the reader shadow self-check.

## Two lint def readers parse the same prefixes separately

- Where: `def_name` in `test/lint.rb` line 998 beside `def_named?` at line 661, and `symbol_names` at line 980 beside `symbol_named?` at line 674, at e0bca07. Quality advisory in `implement-contracts-c`.
- Why it matters: `def_name` repeats the `private`, `protected`, `def`, and `self.` prefix parsing of `def_named?`, and `symbol_names` has its own boundary rules, so a fix to one reader can miss the other and the checks drift.
- Fix outline: build `def_named?` on `def_name` (or one shared prefix helper), and `symbol_named?` on `symbol_names`, so each pair shares one parser.
