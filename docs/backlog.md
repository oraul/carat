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

- Where: the class comment of `carat/use_cases/windows/scroll_window.rb` (line 18, 107 characters), advisory of the periodic quality review at 66fd52b, the class comment of `carat/doubles/memory_files.rb` (line 10, 104 characters), advisory of the periodic quality review at 389c118, the class comment of `carat/ports/terminal_port.rb` (line 4, 130 characters), advisory of the periodic quality review at 5b128b5, the class comments of `carat/use_cases/plugins/window_requests.rb` (line 23, 104 characters) and `carat/adapters/frame_presenter.rb` (line 48 at 3a99ddd, 105 characters, the line about one segment per row and window), advisories of the periodic quality review at 3a99ddd, and, quality advisories of `cursor-shapes`, the class comment of `carat/use_cases/ex/set_command_handler.rb` (line 17, 94 characters) the class comment of `carat/domain/frame.rb` (line 15, a short ragged line of 37 characters), and the class comment of `carat/domain/options.rb` (line 21, 77 characters), advisory of the periodic quality review at d5036f4, and the class comment of `carat/domain/buffer_list.rb` (line 15 at 68eb750, which breaks after "The feed" at about 51 characters), advisory of the periodic quality review at 68eb750. The class comment of `carat/use_cases/ex/set_command_handler.rb` (line 16) also still says "The four search options" although it now covers `cursorline`. Line 37 of `carat/use_cases/dispatcher.rb`, once listed here, is the one-line signature of the constructor, not a comment to rewrap (quality advisory of `explorer-folder-toggle`).
- Why it matters: style only; the rest of each file wraps comments at the surrounding width.
- Fix outline: rewrap the nine comments to the width of the lines around them, and say "The boolean options" in the `SetCommandHandler` class comment.

## lh time per key rose 26% at window-navigation-and-scroll

- Where: the `review.bench` record of `window-navigation-and-scroll` (lh median 11.7 to 14.8 microseconds per key, allocations 27.0 unchanged); no code location is known. Advisory of the periodic quality review at 66fd52b.
- Why it matters: goal 3 of `docs/goals.md` watches time per key; a rise reported as not blocking and never measured again may hide a cost of the prefix wait or the `breaks_insert` check.
- Fix outline: run `make bench SCENARIOS=lh` on `main` and on its parent several times on one pinned core; if the rise holds, profile `lh` with `make profile` and fix or record the cause.

## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers

- Where: `DecodedLine.decode` and `FramePresenter#paint_text` (`carat/domain/decoded_line.rb`, `carat/adapters/frame_presenter.rb`); `utf8-input-safety` draws each byte outside a well-formed UTF-8 sequence as one U+FFFD cell.
- Why it matters: Neovim shows such a byte as a four-cell `<xx>` marker, so two lines that differ only in an illegal byte look alike here, and the byte cannot be read from the screen.
- Fix outline: decode an illegal byte to a code that keeps the byte (for example a private marker range), draw it as `<xx>` the way the C1 markers are drawn, measure it as four cells in `DecodedLine`, `DisplayWidth`, and the cursor placement, and add rows to `test/domain_utf8.rb` and `test/adapters_frame_presenter.rb`.

## Options repeats its bounded-number and known-name checks

- Where: `Options#apply` in `carat/domain/options.rb`: the `tabstop` and `shiftwidth` blocks (lines 107 to 120) and the `icons` and `theme` blocks (lines 125 to 136) are each the same check-then-set-or-note shape. Advisory of the periodic quality review at 389c118.
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

- Where: `Filetype.from_name` in `carat/domain/filetype.rb` (line 30) and `FramePresenter#file_name` in `carat/adapters/frame_presenter.rb` (line 660) each copy the byte basename that `PluginApi::Paths.basename` (`carat/plugin_api.rb:315`) gives and `Domain::PathPolicy.last_name` reuses, while `Filetype.base` (line 68) still uses `rindex`; `hold`, `launch`, and `initialize_params` in `carat/adapters/json_rpc_language_gateway.rb` (lines 247, 261, and 274 at eb63fb4) call `File.basename` on a server's command or the working directory. Advisory of the periodic quality review at 6ea61b1, the gateway's of `lsp-diagnostics`' retrospective.
- Why it matters: three copies of one byte walk drift apart, and the `rindex` copy groups a lead byte with what follows on a name that is not UTF-8.
- Fix outline: call `PluginApi::Paths.basename` in all three places.

## Filetype.program_type mixes byte and character indexes

- Where: `Filetype.program_type` in `carat/domain/filetype.rb` (line 75) starts at `program.length` (characters) and reads `getbyte(stop - 1)` and `program[0, stop]`. Advisory of the periodic quality review at 6ea61b1.
- Why it matters: byte and character positions disagree on a non-ASCII program name; harmless today because no such name is in `PROGRAMS`.
- Fix outline: use `bytesize` and `byteslice` throughout.

## code_of decodes UTF-8 inside DisplayWidth

- Where: `DisplayWidth.code_of` in `carat/domain/display_width.rb` (line 54); `Motions` (`carat/domain/motions.rb` lines 9 and 119) requires `display_width` only to decode a character. Advisory of the periodic quality review at 6ea61b1.
- Why it matters: a decoding helper kept in the width table hides the dependency and invites another copy.
- Fix outline: move it to `Utf8` (for example `Utf8.first_code`) and call it from `DisplayWidth` and `Motions.keyword?`.

## Visual r over an illegal byte has no test row

- Where: the `:replace` branch of `ascii_recase` in `carat/domain/operators.rb` (line 244, `char * text.length` over text that is not UTF-8), while `~`, `U`, and `u` have rows in `test/editor_registers.rb` (lines 49 to 51). Advisory of the periodic quality review at 6ea61b1.
- Why it matters: an untested branch on hostile text is where the next crash on an illegal byte would hide.
- Fix outline: add a `v$r` row over a line with an illegal byte.

## File operations check containment and act in separate calls

- Where: `carat/use_cases/files/resolve_inside.rb` (line 28, the real-path containment check) and the operations it guards, `call` of `carat/use_cases/files/make_path.rb` (its `mkdir` and `write`), `carat/use_cases/files/rename_path.rb` (its `rename`), and `carat/use_cases/files/delete_path.rb` (its `delete`). Low (2) finding of the periodic security review at 16cdcf7, a recorded non-goal of `plugin-path-containment`.
- Why it matters: a directory of the tree replaced by a link pointing outward between the check and the create, rename, or delete redirects the operation outside the tree root, so the containment holds only against a tree that does not change while the explorer acts on it.
- Fix outline: when the file port gains directory-relative operations, open the resolved directory once and act through its descriptor (`openat`, `renameat`, `unlinkat` with no-follow), with a test row in `test/drivers_disk_files.rb`; until then record in `docs/spinel-notes.md` whether the pinned Spinel exposes them.

## The README's commands table omits four make targets

- Where: `README.md` line 14, the commands table, which has no row for `make clean`, `make pack`, `make spinel-rev`, or `make help` (line 12 now names `make install`). Periodic quality advisory at df5a203.
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
- Fix outline: a code-point predicate in `Domain::Motions` (or a named class constant) called from `FindMatch`, `Motions.keyword?`, and the runs scan. Queued in `search-structure`.

## The local cls is the abbreviation the naming rule forbids

- Where: the local `cls` in `carat/domain/text_objects.rb` (line 75) and the parameter `cls` of `Runs#add` (`carat/domain/runs.rb:18`). Periodic quality at 0b17324.
- Why it matters: `CLAUDE.md` names `cls` as the counterexample of its naming rule (`char_class`, not `cls`).
- Fix outline: rename both to `char_class`. Queued as a fold of `search-structure`.

## FramePresenter passes the painted row through instance variables

- Where: `@row_of` and `@current` in `carat/adapters/frame_presenter.rb`, set at lines 356 and 380 and read at 585 by `paint_matches`. Periodic quality at 0b17324.
- Why it matters: the row and the window's currency reach `paint_matches` through a side channel, as the entry "Operate passes the search outcome through an instance variable" records for `Operate`, so a call order change paints with a stale row.
- Fix outline: pass the row and the currency to `paint_row` and on to `paint_matches` as arguments and drop the two instance variables. Queued in `search-structure`, with the entry "Match highlighting walks matches left of the scroll and keeps rows painted after the budget stopped".

## The guard accepts a worktree path by its name alone

- Where: `worktree` in `tools/agent_guard.sh` (line 329), which admits any `tmp/.NAME` for `git -C`, `cd`, `checkout`, `make -C`, and `worktree remove`. Security Low (6) of `guard-allowlist` at 31a93d257317.
- Why it matters: a `tmp/.NAME` that is not a worktree reaches the project repository through discovery (a read agent's `checkout -f --detach origin/main` would force-detach the main tree), or a bare repository the contributor wrote, whose configuration (`diff.external`, `remote.origin.uploadpack`) runs a command.
- Fix outline: require `tmp/.NAME` to be an existing real directory, not a link, listed in `git worktree list --porcelain` for `-C`, `cd`, `checkout`, `make -C`, and `worktree remove`; for `worktree add`, require only that the path does not exist yet; add a `tools/tools_test.sh` case for each. Queued in `guard-lows`.

## The guard does not judge input redirections

- Where: `redirect` in `tools/agent_guard.sh` (line 752), which checks only write targets. Security Low (5) of `guard-allowlist` at 31a93d257317.
- Why it matters: `< /dev/tcp/HOST/PORT` opens an outbound connection from any profile, a path for exfiltration through the hostname or DNS by an agent that text in the tree leads astray.
- Fix outline: refuse a read target under `/dev/tcp/` or `/dev/udp/` (or allow only targets in the project and `/dev/null`), with a `tools/tools_test.sh` case. Queued in `guard-lows`.

## The guard judges relative words after a cd against the project

- Where: the `cd` form in `judge`, `tools/agent_guard.sh` (line 724). Quality advisory of `guard-allowlist` at a979633e8a4d and again at 31a93d257317.
- Why it matters: `cd tmp/.base && mkdir -p tmp/scout/x` passes with DIR `tmp/scout` and writes `tmp/.base/tmp/scout/x`; benign today, since only DIR- or `build/stages`-prefixed paths inside the worktree are reachable, but the guard no longer reads the command as the shell runs it.
- Fix outline: refuse a relative write target after a `cd` other than to the project, or resolve it against the `cd` target, with a `tools/tools_test.sh` case. Queued in `guard-advisories`.

## The guard admits date with any argument

- Where: the shared plain tools in `judge`, `tools/agent_guard.sh` (line 710). Quality advisory of `guard-allowlist` at 31a93d257317.
- Why it matters: `date -s 2001-01-01` passes every profile and, run as root, sets the system clock that git and the run state's timestamps read, against an allowlist of what each agent needs (the scout runs only `date -u +FORMAT`).
- Fix outline: admit `date` only with `-u` and a `+FORMAT` word, with a refusal case in `tools/tools_test.sh`. Queued in `guard-advisories`.

## The guard decodes the JSON escapes \b and \f to letters

- Where: `field` in `tools/agent_guard.sh` (line 114), whose else branch keeps the escaped character. Quality advisory of `guard-allowlist` at 5af7fd9d9784, 14b18734b96e, and 31a93d257317.
- Why it matters: the guard judges the word `lsb` where bash runs `ls` and a backspace, against the header's "any other one ?"; no blank or operator diverges, since bash reads backspace and form feed as word characters, but the guard should read the command as the shell does.
- Fix outline: decode `\b` and `\f` to `?` like `\u0008` and `\u000c`, with a `tools/tools_test.sh` case for `ls\b#; git push origin x`. Queued in `guard-advisories`.

## uniq -f 1 FILE is refused

- Where: `uniq_form` in `tools/agent_guard.sh` (line 668). Quality advisory of `guard-allowlist` at 3efc71ba34f8 and again at 31a93d257317.
- Why it matters: the value of `-f`, `-s`, or `-w` given as a separate word counts as an operand, so a normal read-only form is refused (it fails closed).
- Fix outline: skip the word after `-f`, `-s`, and `-w`, with a `tools/tools_test.sh` case. Queued in `guard-advisories`.

## The guard header lists printf without its restriction

- Where: the shared forms of the header of `tools/agent_guard.sh` (line 25). Quality advisory of `guard-allowlist` at 3efc71ba34f8 and again at 31a93d257317.
- Why it matters: `judge` refuses `printf` with a leading option, so the header no longer says what the code allows.
- Fix outline: write `printf (no leading option)` in the header's shared forms. Queued in `guard-advisories`.

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
- Fix outline: refuse an unquoted `~` right after `=` or `:` in a word that starts with an identifier and `=`, with a `tools/tools_test.sh` case. Queued in `guard-advisories`.

## The delivered-changes list stops at pull request 46

- Where: the Delivered changes list closing `docs/codebase-map.md`, whose last numbered line is `#46 buffer-search`: lines 623 to 625 list `pipeline-speed`, `pipeline-speed-b`, and `pipeline-speed-c` without their numbers (#48, #49, #51), and #47, #50, and #52 to #67 are missing. Periodic quality advisories at 598cf1b, f31f4e8, d386c74, 3a99ddd, and 803fe6e (notes 24 and 25).
- Why it matters: the list `CLAUDE.md` names as the record of delivered changes misses eighteen merged pull requests and cannot be matched to three others.
- Fix outline: number the three lines and add #47, #50, and #52 to #67, with the check `docs-index` asks for: every merged pull request of `docs/metrics.tsv` appears in the list. Queued in `docs-index`.

## Agents leave scratch files in the repository root

- Where: the repository root, where agents left `build_check_out_tmp` and `.err` twice; the briefs under `.claude/agents/` name no place for scratch output, and the push gates of `tools/run_state.sh push` and `tools/gates.sh` do not look at untracked files (the checker and the security reviewer test `git status --porcelain --untracked-files=no`). The user's request in the brief of `pipeline-speed-b`.
- Why it matters: an untracked file outside `build/`, `dist/`, and `tmp/` can be staged by a later `git add` and reach a pull request, and it shows in every `git status` of the next run.
- Fix outline: the agents' briefs send scratch output under `build/` or `tmp/`, and a push gate refuses an untracked file outside the ignored paths, with a `tools/tools_test.sh` case. Queued in `merge-gate-integrity`.

## A test-only fix after a passing quality review gets the whole branch reviewed

- Where: `.claude/workflows/deliver-change.js` line 375, the scope of a fix review. Quality advisory at d820b39 in `pipeline-speed-b`.
- Why it matters: after a passing quality review followed by a bench or CI fix, `blockedAt` is not that commit, so `files` is null and a test-only fix gets the whole branch reviewed again, where the old `priorQuality` offered only the fix diff; the review costs tokens and rounds the fix does not need.
- Fix outline: when the last quality review passed and no blocked files are recorded at it, give the scope command with no files (tests and records only), with a case in the workflow's tests. Queued in `implement-contracts`.

## The merge's stages gate cannot pass a renamed or removed stage

- Where: `tools/gates.sh` line 195, the merge's stages gate, which reads `CHECK_STAGES` from main's Makefile with `sed`, while `tools/run_state.sh check` reads the list with `make -s stages`. Quality advisory at d820b39 in `pipeline-speed-b`; the archived design of `pipeline-speed-b` does not cover the case.
- Why it matters: a change that renames or removes a stage cannot pass its own merge, since main's list names a stage the branch never ran, and the stage list now has two readers that can disagree.
- Fix outline: use one reader of the list for both scripts, and accept a stage main names that the branch's `CHECK_STAGES` dropped when the branch's diff removes it from the Makefile (or record the rename in the run state), with a `tools/tools_test.sh` case. Queued in `merge-gate-integrity`.

## Branch code can rewrite the origin/main the merge gates trust

- Where: `.claude/workflows/deliver-change.js` line 292, the merge-gates command, and every hook's `origin/main` check. Periodic security Medium (6) at e20c83c.
- Why it matters: make recipes and test programs the checker runs on the branch, outside the guard, can rewrite `refs/remotes/origin/main` or `.git/config`, so the merge-gates worktree of `origin/main` and the hooks' comparisons come from the branch, not from main.
- Fix outline: pin main's commit from the remote at the start of the merge step, verify `origin/main` equals it before `git worktree add`, add the worktree at that hash, run the gates' git with `core.fsmonitor` and `core.hooksPath` neutralized, and longer term run the checks in a clone whose `.git` the stages cannot write. Queued in `merge-gate-integrity`.

## The merge-gates worktree is never removed

- Where: `.claude/workflows/deliver-change.js` line 292 and step 8 of `.claude/agents/merger.md`. Periodic quality advisory at e20c83c.
- Why it matters: the command removes `tmp/.merge-gates` before adding it but nothing removes it after the merge, so the first run prints a git error into the gate output the merger reads and every later run finds a stale worktree.
- Fix outline: send the remove's error to `/dev/null` and remove the worktree after the merge. Queued in `merge-gate-integrity`.

## The guard case for the merge gates leaves out the worktree prune

- Where: `tools/tools_test.sh` line 756. Periodic quality advisory at e20c83c.
- Why it matters: the case omits the leading `git worktree prune;` that `mergeGates` sends, so the exact command the merger is told to run is not the one tested.
- Fix outline: test the full string `mergeGates` builds, prune included. Queued in `merge-gate-integrity`.

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
- Fix outline: initialize `shown=$profile` beside `closing=0` and print `$shown` in `refuse`. Queued in `guard-advisories`.

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

- Where: `carat/domain/buffer.rb` line 512 (`revert_to` undoes records with `LineSplice.apply` and shifts the signs and the syntax cache but not `global_marks`, unlike `splice` at line 548). Periodic quality advisory at eb0f1be.
- Why it matters: a plugin edit rolled back while a `:g` runs leaves the marks on rows the command never matched, so the global runs its command on the wrong lines.
- Fix outline: shift `global_marks` beside the other two shifts in `revert_to` and add a `test/domain_global.rb` row. Queued in `global-tidy`.

## The secret patterns miss unquoted assignments and unlisted token shapes

- Where: `tools/rules.sh` (`ASSIGN_RE` takes only a quoted literal; `TOKEN_RE` lists the shapes of AWS, GitHub, GitLab, Slack, Google API, `sk-` keys, Stripe live, and npm). Limit accepted by `backup-secret-scan`.
- Why it matters: `password = hunter2hunter2` in a YAML or shell file, or a token of another platform, reaches the backup ref and the branch; the security review still reads the diff before the push, but not before the backup.
- Fix outline: add a shape when a platform the project uses appears, and refuse an unquoted assignment in configuration files only (`*.yml`, `*.toml`, `*.sh`, `.caratrc`), where ordinary code does not assign `token = name`, each with a `tools/tools_test.sh` case. Queued in `content-gate-gaps`.

## The content gate skips files git treats as binary

- Where: `tools/gates.sh` line 126 (`gate_content` reads `git log -p`, which prints no lines for a file with a NUL byte or one `.gitattributes` marks `-diff` or `binary`, and the merge gates run from the branch's checkout, so the branch can set them). Security Low (6) of `backup-secret-scan`.
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
- Why it matters: in `backup-secret-scan` 2 of 2 backup pushes were refused and 0 backup refs reached origin, so the step spent tokens and changed no decision, and the run state holds no backup record to tell the report so; `docs-currency` made 7 more attempts, and 0 of 9 across the two runs reached origin (its retrospective); in `buffer-list` the implement and fix pushes all failed, 0 `refs/backup` refs reached origin, and 7 commits stayed local until the package push (retrospective note 11); in `leader-layout` 2 of 2 backup tries were refused (retrospective note 8), so no backup has reached origin in four runs; in `lsp-diagnostics` 8 attempts over 3 contributor starts were refused and no `refs/backup` ref reached origin (retrospective note 18), and in `diagnostics-display` all 6 implement commits and 3 more tries were refused, no restore being used; the first backup of `partial-results` was refused the same way. Kept here by the user's earlier decision, which the user may want to revisit.
- Fix outline: record a refused backup push once in the run state, make no later backup attempt in that run, and have the report say no backup exists, with a `tools/tools_test.sh` case for a refused push.

## Pull requests are created with a session-link footer the settings turn off

- Where: step 4 of the package step in `.claude/agents/contributor.md`, which opens the pull request with the GitHub tools, and its step 5 removal edit; `.claude/settings.json` sets the attribution `pr` empty and `sessionUrl` false. Retrospective proposal of `leader-layout`, queued as `pr-footer`.
- Why it matters: PR 64 was created with a footer holding a session link and needed a removal edit, as were PRs 57 to 60 (4 of 4); PRs 61 to 63 left no record. The edit history keeps the link, against the hard rule that no session URL appears in GitHub activity, and `package-clean`'s acceptance (the next five clean) fails at PR 64.
- Fix outline: create the pull request on a path that sends exactly the body file, record in the run state whether it was created clean, and have the history count clean creations N of M.

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

- Where: the plugin API version sentence of `docs/architecture.md` (line 321 at `theme-tokens`) and its `syntax_group` and `tokenize` bullets near lines 295 to 296, while `carat/plugin_api.rb` (line 12) and `docs/plugins.md` (line 23) give 2.3 at 803fe6e. Periodic quality at 4c65f4e and 803fe6e.
- Why it matters: the binding architecture lists changes only through 1.3 and misses 2.1's file-icon groups in `syntax_group` and tokens and a scratch buffer's syntax named after its plugin, 2.2's `set_segment` and `PluginApi::FileIcons`, and 2.3's floats (`open_float`, `move_float`, `close_float`, `FloatOptions`), so a plugin author reading it targets an older API.
- Fix outline: say 2.3 and add the 2.1, 2.2, and 2.3 additions to the version sentence and to the `syntax_group`, `tokenize`, and window request bullets, within the file's budget. Queued in `docs-index`.

## Operate and RepeatLast each copy EditorState#clamp_col

- Where: the private `clamp(state, row, col)` in `carat/use_cases/operate.rb` (line 202 at `theme-tokens`) and `carat/use_cases/repeat_last.rb` (line 117), each `EditorState#clamp_col` in `carat/domain/editor_state.rb` (line 94) line for line. Periodic quality at 4c65f4e.
- Why it matters: three copies of one clamp must change together, and a fix to the domain's misses the two use cases.
- Fix outline: call `state.clamp_col(row, col)` at the six call sites and delete both private methods. Listed in the queue's backlog item.

## NO_COLOR reaches only the start screen

- Where: `TerminalPort#no_color?` (`carat/ports/terminal_port.rb`), read only by `EditorAssembly#open` for the start screen's glyphs (`start-screen`); `SgrTable.from_theme` and `ScreenPresenter` color every other cell from the theme.
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

- Where: the mode list at the top of `tools/gates.sh` (line 41 at `package-clean`), which says pre-push is static, security, stages. Quality advisory of `package-clean`.
- Why it matters: static now adds the attribution gate, which pre-push deliberately leaves out (the gates stage runs it), so a reader trusting the header expects a check the push never makes.
- Fix outline: list pre-push as trailer, content, snapshots, docs, security, stages, noting attribution runs through the gates stage.

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

- Where: the Designs lines of `docs/codebase-map.md` (line 523 at 3a99ddd and the others): area 16 lacks `explorer-folder-toggle` and `theme-tokens`, areas 3 and 13 lack `theme-tokens`, and areas 13 and 17 lack `start-screen`. Periodic quality at 3a99ddd.
- Why it matters: the Designs line is where a change finds the archived decisions of its area, so a reader of these areas misses why the code looks as it does.
- Fix outline: add each change with the sections that touch the area, within the map's budget. Queued in `architecture-drift`.

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
- Fix outline: tune each palette's cursor-line color, and its 256-color index (one_light and light_plus round to gray 255 at 256 colors), or the few foregrounds, until the table passes at 4.5:1 for text, then raise the threshold in the test. Queued in `cursor-line-contrast`.

## The default cursor line keeps the terminal's foreground over a dark stripe

- Where: `config/default.caratrc` (line 22 at `cursor-shapes`) turns `cursorline` on with `one_dark` and `option.background terminal`, so in `carat/domain/themes.rb` the lit cells of groups without a foreground keep the terminal's own foreground over the fixed `CURSOR_LINE` stripe (0x2c313c). Quality advisory of `cursor-shapes`.
- Why it matters: on a light terminal, plain text on the cursor line becomes dark on dark and unreadable, and the cursor-line contrast table of `test/domain_theme.rb` checks only `background theme`.
- Fix outline: give lit cells the palette's foreground when the stripe is painted over the terminal's background, with a contrast row for `background terminal`, or ship `cursorline` off until the theme follows the terminal's background. Queued in `cursor-line-contrast`.

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
- Fix outline: rename `lit16` to `line_bg16` beside `line16`. Queued in `cursor-line-contrast`.

## A test helper's comment sits above the wrong method

- Where: `test/editor_search.rb`, the comment of the `editor` helper (lines 8 and 9 at d5036f4) now sits above the `group` helper `cursor-shapes` added, with `def self.editor` at line 16. Advisory of the periodic quality review at d5036f4.
- Why it matters: the two comments read as one comment for `group`, and `editor` has none.
- Fix outline: move the `editor` comment above `def self.editor`. Queued in the backlog item of `docs/queue.md` with the comment-wrap entry.

## BufferList keeps any_modified? and number_of with no production caller

- Where: `any_modified?` (line 115 at `buffer-list`) and `number_of` (line 61) in `carat/domain/buffer_list.rb`, both still named in `docs/codebase-map.md`. Quality advisory of `buffer-list`.
- Why it matters: `Quit` and `QuitAll` now use `first_unsaved`, so `any_modified?` is dead code, and `number_of` returns a list position that is no longer the buffer number, which misleads a future caller.
- Fix outline: remove both, use `modified_buffer.nil?` in the tests, and drop them from the map. Queued as `buffer-list-tidy` in `docs/queue.md`.

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

- Where: `DeleteBuffer` (`carat/use_cases/buffers/delete_buffer.rb`, line 31 at 68eb750) and `ListBuffers` (`carat/use_cases/buffers/list_buffers.rb`, lines 56 and 73) use `@buffers.tabs`, while `CloseTab`, `CloseOtherTabs`, and `Quit` take `tabs:` from `EditorAssembly`. Periodic quality advisory at 68eb750.
- Why it matters: two routes to one collaborator leave no one clear way, and `test/adapters_assembly.rb` checks only the injected one.
- Fix outline: inject `tabs:` into both as their siblings do, or document `BufferList#tabs` as the one route. Queued as `buffer-list-structure` in `docs/queue.md`.

## StatusBar requires the plugin API it does not use

- Where: `require_relative "../plugin_api"` on line 1 of `carat/adapters/status_bar.rb`. Quality advisory of `bars`.
- Why it matters: `StatusBar` names no `PluginApi` constant, so the require is dead and suggests a dependency the adapter does not have.
- Fix outline: drop the require and rebuild with `make dev-build`.

## FramePresenter reaches through TabBar to ask whether the tab row shows

- Where: `@tab_bar.buffers.tab_row?(state.tabs.tab_count)` in `carat/adapters/frame_presenter.rb` (line 157 at `bars`), while `ArrangeView` (`carat/use_cases/arrange_view.rb`, line 37) asks `BufferList#tab_row?` directly. Quality advisory of `bars`, raised twice.
- Why it matters: the presenter reaches through a collaborator, and two routes to one rule can drift apart.
- Fix outline: give `TabBar` a `showing?(tab_count)` predicate and call it once in the presenter, or hand the presenter the buffer list, with the presenter test rows unchanged.

## The [No Name] text is defined in both bars

- Where: `NO_NAME` in `carat/adapters/tab_bar.rb` (line 23 at `bars`) and again in `carat/adapters/status_bar.rb` (line 46). Quality advisory of `bars`, raised twice.
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

## The code map's tools_test.sh entry omits the call caps

- Where: the `tools/tools_test.sh` entry of `docs/codebase-map.md` (line 49 at `run-budgets`). Quality advisory of `run-budgets`, raised twice.
- Why it matters: the entry lists what the file covers but not the call-caps section `run-budgets` added (`CALL_CAPS`, `FIXED_CAPS`, `maxTurns`, the merger's call count), so a reader looking for that check is not sent there.
- Fix outline: add the call caps to the entry.

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
- Fix outline: delete the dead line, and drop `saved_float` and its `enter`, or document that `in_window` keeps the focus for callers that do not refocus. Queued in `float-tidy` with the other `floating-windows` notes.

## A float reopened at the same box keeps the old float's text

- Where: `build_float_key` in `carat/adapters/frame_presenter.rb` (line 365 at `floating-windows`) and the `floats` comment of `carat/domain/frame.rb`. Periodic quality blocking at 803fe6e.
- Why it matters: the key holds only the box, the scroll, and the buffer's change counters, so a float closed and replaced by a new one at the same box (fresh scratch buffers both at changes 0 and closed_count 0) gives the same key; with one layout window and the float not entered the rows under it are not repainted and the screen keeps the old text and title. Completion's list is the first consumer that reopens a float at one box.
- Fix outline: add the float's window id to the key (a stride of 9, with the Frame comment), and a test in `test/editor_floats.rb` that closes and reopens a float at the same box with other lines after two redraws and compares the screen with a full repaint. Queued in `completion`.

## Branch code can forge a security pass the resume trusts

- Where: `trusted_state` in `tools/run_state.sh` (line 1295 at 803fe6e). Periodic security Medium (5); found again at eb63fb4 as Medium (6) (`lsp-diagnostics`' retrospective note 21).
- Why it matters: branch code run by `make` in the check phase, before the security review, can write `review.security pass HEAD` into `build/pipeline/CHANGE.json`; a resume accepts it since only the commit is checked, so the security phase is skipped and the merge records carry the forged pass.
- Fix outline: keep review records where branch code cannot write them, or authenticate them with a key only the workflow holds, and rerun the security review on resume rather than trust a file record. Queued in `merge-gate-integrity`.

## The merge tool has no hook

- Where: the tools of `.claude/agents/merger.md` (line 4 at 803fe6e), whose PreToolUse hook matches Bash only. Periodic security Medium (5).
- Why it matters: the merge gate runs only because the merger's instructions say so, so a merger steered by branch-controlled CI log text can merge without it.
- Fix outline: hook the merge tool with a check, from `origin/main`, that `gates.sh merge` left a pass marker at the expected head, and require the spin check by branch protection. Queued in `merge-gate-integrity`.

## FloatLayer is a plain class among the mutable records

- Where: `carat/domain/float_layer.rb` line 10 at 803fe6e. Periodic quality advisory.
- Why it matters: `CLAUDE.md` makes mutable records `Struct` subclasses with pinned members; `TabPage`, `TabList`, `LastFind`, and `StatusSlots` follow it, `FloatLayer` does not.
- Fix outline: a `Struct` with `floats` and `focus` pinned, readers and `self.member =` writers, built with keywords in `TabPage`. Queued in `float-tidy`.

## The Frame comment gives four integers per float

- Where: the `floats` comment of `carat/domain/frame.rb` (line 26 at 803fe6e) against `FLOAT_STRIDE` in `carat/adapters/frame_presenter.rb`. Periodic quality advisory.
- Why it matters: the presenter writes eight integers per float (the box, the window's top and left, the buffer's closed_count and changes), so the comment misleads a reader of the key.
- Fix outline: describe `floats` as the presenter's float key of `FLOAT_STRIDE` integers per float, or name each. Queued in `float-tidy`.

## move_float bypasses the float use cases

- Where: `WindowRequests#move_float` in `carat/use_cases/plugins/window_requests.rb` (line 247 at 803fe6e). Periodic quality advisory.
- Why it matters: `open_float` and `close_float` go through `OpenFloat` and `CloseFloat` as section 5.3 asks of request families, while `move_float` writes the tab page's `FloatLayer` directly and ignores the result of `move`.
- Fix outline: a `MoveFloat` use case beside the other two, or a class comment saying a move is a domain write needing none, with `FloatLayer#move` made void. Queued in `float-tidy`.

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

## A failed initialize marks the language server ready

- Where: the initialize response handling of `carat/adapters/json_rpc_language_gateway.rb` (line 341 at eb63fb4). Periodic quality blocking at eb63fb4.
- Why it matters: an error response to `initialize` takes the ready path, so the server is marked ready, `initialized` and then `didOpen` for every document are sent against the protocol, and the bar shows the server ready instead of failed; no test covers it, and the next language features send requests on that state.
- Fix outline: treat a response carrying an error or no object result as a failed start, shown with the `:LspRestart` hint, with a gateway row for an initialize error. Queued in `completion`.

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

- Where: the `publishDiagnostics` handling of `carat/adapters/json_rpc_language_gateway.rb` (line 415 at eb63fb4). Periodic security Low (4).
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

- Where: `ControlText.cleaned` in `carat/domain/control_text.rb` (line 28 at 38d8c47), used only by `strip` and `line`. Quality advisory at `diagnostics-display`.
- Why it matters: a public module function taking a bool flag invites callers outside the module to depend on a helper of its two entry points.
- Fix outline: mark it `private_class_method :cleaned`.

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

- Where: `documentation()` in `tools/ci_scope.sh` (line 39 at fb09c6b). Periodic security Low (5) at fb09c6b.
- Why it matters: a pull request changing only agent hook lines, `.claude/settings.json`, or the workflows is classed documentation, so CI skips `make tools-test`, the independent check of the guard hook lines and the attribution.
- Fix outline: class `.claude/agents/`, `.claude/settings.json`, and `.claude/workflows/` as code, with a `tools/tools_test.sh` case. Queued in `ci-hardening`.

## The process runner's reader queues bodies without a bound

- Where: the reader thread in `carat/drivers/process_runner.rb` (line 106 at fb09c6b). Periodic security Low (4) at fb09c6b.
- Why it matters: it queues every framed body of up to `BODY_LIMIT` with no bound while the gateway drains 64 per idle tick, so a flooding language server can exhaust the editor's memory.
- Fix outline: cap the queued bodies or bytes per handle and stop the server with an overflow message past the cap, with a driver row. Queued in `lsp-client-tidy`.

## The workflows repeat the commit pattern

- Where: `.claude/workflows/deliver-change.js` repeats the `COMMIT` pattern (line 368 at 594dd35) inline in `pushedHead` (line 248) and in the head check of a capped start (line 496); `.claude/workflows/periodic-review.js` repeats its `isCommit` (line 58) in `areasLeft` (line 74) and computes `areaSlices(MAP_AREAS, QUALITY_SLICES)` twice (lines 103 and 117). Quality advisories in `partial-results`.
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
