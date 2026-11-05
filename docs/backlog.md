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

## :set handles only filetype, syntax, and the search options

- Where: `Carat::UseCases::SetCommandHandler` in `carat/use_cases/ex/set_command_handler.rb`, which handles `filetype`, `syntax`, and the booleans `ignorecase`, `smartcase`, `hlsearch`, and `incsearch` (since `buffer-search`), answers `Not implemented: :set name` for the other options the editor already has and `E518` for the rest; no `:setlocal`, no `:filetype`.
- Why it matters: `:set number`, `:set ts=4`, `:set nowrap`, and the rest of Neovim's option commands are roadmap item 9, `options-and-config`.
- Fix outline: grow the handler into the option table that item brings (names, abbreviations, types, global or local), keeping the `filetype`, `syntax`, and search answers; add `:setlocal` and the `&`, `+=`, `-=` forms there, with `no`, `inv`, `!`, and `?` moved from the search booleans to every boolean.

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

- Where: `.github/workflows/ci.yml` (line 36 `actions/checkout@v4`, and the same at lines 65, 91, 175, and 192, with `actions/cache@v4` and its `restore` and `save` forms). Low finding of the periodic security review at 66fd52b.
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

## Three comments run past their file's wrap width

- Where: the class comment of `carat/use_cases/windows/scroll_window.rb` (line 18, 107 characters) and `carat/use_cases/dispatcher.rb` (line 89), advisories of the periodic quality review at 66fd52b, and the class comment of `carat/doubles/memory_files.rb` (line 10, 104 characters), advisory of the periodic quality review at 389c118.
- Why it matters: style only; the rest of each file wraps comments at the surrounding width.
- Fix outline: rewrap the three comments to the width of the lines around them.

## lh time per key rose 26% at window-navigation-and-scroll

- Where: the `review.bench` record of `window-navigation-and-scroll` (lh median 11.7 to 14.8 microseconds per key, allocations 27.0 unchanged); no code location is known. Advisory of the periodic quality review at 66fd52b.
- Why it matters: goal 3 of `docs/goals.md` watches time per key; a rise reported as not blocking and never measured again may hide a cost of the prefix wait or the `breaks_insert` check.
- Fix outline: run `make bench SCENARIOS=lh` on `main` and on its parent several times on one pinned core; if the rise holds, profile `lh` with `make profile` and fix or record the cause.

## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers

- Where: `DecodedLine.decode` and `FramePresenter#paint_text` (`carat/domain/decoded_line.rb`, `carat/adapters/frame_presenter.rb`); `utf8-input-safety` draws each byte outside a well-formed UTF-8 sequence as one U+FFFD cell.
- Why it matters: Neovim shows such a byte as a four-cell `<xx>` marker, so two lines that differ only in an illegal byte look alike here, and the byte cannot be read from the screen.
- Fix outline: decode an illegal byte to a code that keeps the byte (for example a private marker range), draw it as `<xx>` the way the C1 markers are drawn, measure it as four cells in `DecodedLine`, `DisplayWidth`, and the cursor placement, and add rows to `test/domain_utf8.rb` and `test/adapters_frame_presenter.rb`.

## Carat::Json and String#index on text that is not UTF-8

- Where: `Carat::Json` in `carat/domain/json.rb` (`each_char` at line 346), and every `index` or `rindex` on text that may hold illegal bytes; the pinned Spinel's `index`, `rindex`, and `each_char` group a lead byte with the bytes after it, while `length` and `[i, n]` count each byte (`docs/spinel-notes.md`).
- Why it matters: no path sends buffer text to JSON yet, but the language server change will; a character index from `index` on such text slices the wrong bytes, and JSON needs the text valid (a language server expects UTF-8).
- Fix outline: escape illegal bytes in `Carat::Json` by walking bytes with `Utf8` (as U+FFFD or a documented escape), replace `index` and `rindex` on untrusted text with `byteindex` and `byterindex`, report the disagreement upstream, and add hostile rows to `test/json.rb`.

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

- Where: `Filetype.from_name` in `carat/domain/filetype.rb` (line 30) and `FramePresenter#file_name` in `carat/adapters/frame_presenter.rb` (line 660) each copy the byte basename that `PluginApi::Paths.basename` (`carat/plugin_api.rb:315`) gives and `Domain::PathPolicy.last_name` reuses, while `Filetype.base` (line 68) still uses `rindex`. Advisory of the periodic quality review at 6ea61b1.
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

## The README names held-Ctrl forms the window keys do not have

- Where: `README.md` line 5, which says the window commands `s v h j k l w W p c o = q` work with Ctrl held on the second key. Periodic quality advisory at df5a203.
- Why it matters: `W`, `c`, and `=` have no held-Ctrl binding, and `<C-w><C-c>` deliberately cancels as in Vim (`docs/compatibility.md`), so a user following the README presses keys that do nothing or cancel.
- Fix outline: name only the keys that `config/default.caratrc` binds in the held-Ctrl form, with the `<C-w><C-c>` difference left to `docs/compatibility.md`.

## The README's commands table omits four make targets

- Where: `README.md` line 14, the commands table, which has no row for `make clean`, `make pack`, `make spinel-rev`, or `make help` (line 12 now names `make install`). Periodic quality advisory at df5a203.
- Why it matters: the map's Build and CI rule gives every command a README line, and goal 12 keeps the README current.
- Fix outline: add one row naming the missing targets, or one row per target, checked against `make help`.

## CLAUDE.md has under 1,000 bytes of room in its budget

- Where: `CLAUDE.md`, 30,682 of its 30,720-byte budget (99.9%, 38 bytes left) in `tools/docs_lint.sh` (`BUDGETS`) at eb0f1be, after 30,534 in `pipeline-speed-c`. Periodic quality advisory at df5a203, blocking in the periodic quality review at eb0f1be; `docs/architecture.md` is at 88,054 of 88,064 and is handled by `docs-currency` too.
- Why it matters: `CLAUDE.md` requires its Commands and Layout sections to stay in sync with the code, so the next change that must add a line there fails `make docs-lint` and pays for a trim it did not plan.
- Fix outline: the first change that needs room trims `CLAUDE.md` in the same change, moving detail to `docs/codebase-map.md` or the agents' files, rather than raising the budget; accepted when `make docs-lint` passes with `CLAUDE.md` at most 90% of its budget. Queued in `docs-currency`.

## /status and a killed run lose the package, CI, and merge phases

- Where: `.claude/workflows/deliver-change.js` lines 608 to 625, which leave the package, CI, and merge phase lines to the closing start, and the next-phase loop of `show_status` in `tools/run_state.sh` (line 489). Advisory of the quality review of `workflow-records`.
- Why it matters: during the CI wait `/status` prints next phase package although the pull request is open, and a run killed between the merge and the closing start never records package, ci, and merge, so its history row lacks those phases.
- Fix outline: have `status` read `pushed`, `pr`, and `merged` as the resume does when the phase lines are absent, or record each phase as soon as its own record exists; add a `tools/tools_test.sh` case for a run state with `pushed` and `pr` but no package line. Queued in `run-resume`.

## The merger's wait depends on the harness allowing a foreground sleep

- Where: the header of `tools/ci_wait.sh` and step 2 of `.claude/agents/merger.md` (line 20). Advisory of the quality review of `workflow-records`.
- Why it matters: the one-start wait holds only while the agent harness lets a foreground shell call sleep up to 540 seconds; if it refuses or shortens it, the merger falls back to returning pending, the cost of 36 to 58 merge tool calls a run that `workflow-records` set out to remove.
- Fix outline: confirm on the first full run (`guard-hardening`) that the merger used one start with no pending note; record the harness behavior in the header and the merger's file, and if it fails, give the workflow the wait between merger starts instead. Queued in `run-budgets`.

## The contributor can edit the agent files of its own run

- Where: the agent files under `.claude/agents/`, whose hook lines name each agent's guard profile and which the contributor's file tools may write. What remains of the periodic security Low (6) at 8c340cd after `guard-allowlist` made every hook run `origin/main`'s guard and refuse on any failure.
- Why it matters: if the harness reads an agent file from the working tree when the workflow starts that agent, an edit on the branch (a hook line removed, a profile widened) applies to the later agents of the same run before any review.
- Fix outline: have the workflow compare `.claude/agents/` and `.claude/settings.json` with `origin/main` before it starts each agent and stop on a difference the brief does not name, or refuse the contributor's edits of them unless a record only the workflow writes names them; add a `tools/tools_test.sh` case. Queued in the backlog item of `docs/queue.md` item 19 (review triggers).

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

## The architecture omits three search use cases and the search options of :set

- Where: `docs/architecture.md` section 5.1 (line 167), which names `FindMatch` and `JumpToMatch` but not `OpenSearchPrompt`, `PreviewSearch`, or `RecallHistory`, and line 173, which says `:set` handles filetype and syntax only. Periodic quality at 0b17324.
- Why it matters: the architecture is binding and is where a change starts; a reader of section 5 misses three use cases and the four search options `SetCommandHandler` now takes. The file is at 88,054 of its 88,064-byte budget.
- Fix outline: name the three use cases in 5.1 and drop the "only" clause at 173 (or list the search options), within the budget. Queued in `docs-currency`.

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
- Fix outline: add `tools/run_state[.]sh$` and `[.]claude/workflows/` to the pattern, and count an edit of `.claude/agents/security-reviewer.md` or `.claude/agents/merger.md` as due, with a `tools/tools_test.sh` case. Queued in the backlog item of `docs/queue.md` item 19 (review triggers).

## agent_hooks misses frontmatter keys that widen an agent's authority

- Where: `agent_hooks` in `tools/run_state.sh` (line 701), which counts only `tools` and hook lines as the guard's wiring and reads `git diff` with `2>/dev/null`. Security Low (6) of `pipeline-speed` at b0df2ac092ed, and a quality advisory at 1d187291be30.
- Why it matters: adding `permissionMode:`, `mcpServers:`, `disallowedTools:`, or a list-form tool item to an agent does not make the periodic review due, and a failing `git diff` fails open, so the review is skipped exactly when the agent's authority changes.
- Fix outline: treat any changed line between an agent file's frontmatter delimiters other than `name`, `description`, and `model` as guard and gates, and report the review due when the diff fails, with a `tools/tools_test.sh` case. Queued in the backlog item of `docs/queue.md` item 19 (review triggers).

## A resumed run can be granted an extra fix round after stopping at the limit

- Where: `stopKind` in `.claude/workflows/deliver-change.js` (line 67), which starts at `none` on every start. Quality advisory of `pipeline-speed` at 1d187291be30.
- Why it matters: the checker's metric line (`figuresFirst`) overwrites a stored `stop=rounds` with `none` before `mayFix` runs, so a start killed after that check makes the next resume grant an extra round to a run that had stopped at the round limit.
- Fix outline: seed `stopKind` from `lastStop` when `rework` is already at `ROUNDS` plus `extra`. Queued in `run-resume`.

## Trimming CLAUDE.md for room reworded two Git rules

- Where: the Git workflow rule of `CLAUDE.md` (line 39) and its Pull requests rule (line 113), changed from "unless explicitly asked" to "unless asked". Quality advisory of `pipeline-speed` at 1d187291be30.
- Why it matters: the bytes were taken from rules outside the change's scope, softening their wording.
- Fix outline: restore "explicitly" on both lines and take the bytes from prose that states no rule. Queued in `docs-currency`.

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

- Where: the Delivered changes list closing `docs/codebase-map.md` (line 605), which ends at `#46 buffer-search`. Periodic quality advisories at 598cf1b and f31f4e8.
- Why it matters: the list `CLAUDE.md` names as the record of delivered changes misses every merged pull request from 47 to 54.
- Fix outline: add the lines for `#47` to `#54`, with the check `docs-index` asks for: every merged pull request of `docs/metrics.tsv` appears in the list. Queued in `docs-index`.

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
- Fix outline: cut `CLAUDE.md` to the rules every agent needs, moving the rest to the agent files, the map, or the notes, within the 27,648 bytes `docs-currency` sets; if the harness gains a setting that leaves it out of an agent, use it for the agents that never edit. Queued in `docs-currency`.

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
- Fix outline: add each as an `ExHandler` with its use case over `Buffer#set_lines`, registered in Vim's order, with rows in `docs/compatibility.md` and `test/editor_global.rb`; `:m` and `:t` share `ExRange` for their destination address, and `:normal` feeds keys through `HandleKey` inside the global's transaction. Queued in the backlog items of docs/queue.md item 27.

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

## CLAUDE.md says restore checks out the backup

- Where: the `sh tools/run_state.sh` bullet of the Commands section of `CLAUDE.md`, while `restore_branch` only creates the branch and the resume step checks it out. Quality advisory of `pipeline-durability`.
- Why it matters: an agent reading it expects the tree to be switched and may act on the wrong branch.
- Fix outline: say that `restore BRANCH` recreates the branch from its backup when the branch is gone.

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

## Section 5.1 names a Substitute use case and omits DeleteLines

- Where: `docs/architecture.md` line 167 names `Substitute`, while the class is `SubstituteLines` in `carat/use_cases/search/substitute_lines.rb`, and omits `DeleteLines`, added for `:d`. Periodic quality advisory at eb0f1be.
- Why it matters: the architecture is binding and is where a change starts; a reader looks for a class that does not exist and misses one that does.
- Fix outline: rename it to `SubstituteLines` and add `DeleteLines` within the budget `docs-currency` frees. Queued in `docs-currency`.

## The secret patterns miss unquoted assignments and unlisted token shapes

- Where: `tools/rules.sh` (`ASSIGN_RE` takes only a quoted literal; `TOKEN_RE` lists the shapes of AWS, GitHub, GitLab, Slack, Google API, `sk-` keys, Stripe live, and npm). Limit accepted by `backup-secret-scan`.
- Why it matters: `password = hunter2hunter2` in a YAML or shell file, or a token of another platform, reaches the backup ref and the branch; the security review still reads the diff before the push, but not before the backup.
- Fix outline: add a shape when a platform the project uses appears, and refuse an unquoted assignment in configuration files only (`*.yml`, `*.toml`, `*.sh`, `.caratrc`), where ordinary code does not assign `token = name`, each with a `tools/tools_test.sh` case.

## The content gate skips files git treats as binary

- Where: `tools/gates.sh` line 126 (`gate_content` reads `git log -p`, which prints no lines for a file with a NUL byte or one `.gitattributes` marks `-diff` or `binary`, and the merge gates run from the branch's checkout, so the branch can set them). Security Low (6) of `backup-secret-scan`.
- Why it matters: a committed secret in such a file passes the secret, URL, email, and model checks.
- Fix outline: pass `--text` and `--no-textconv` to the `git log -p` scan, or refuse an added binary file and a `.gitattributes` change setting `diff`, `binary`, or `textconv` unless a reviewer allows it, with a `tools/tools_test.sh` case.

## The URL, email, and session checks print the whole matching line

- Where: `tools/rules.sh` line 34 (`scan` prints each hit's full line for the URL, email, and session checks, while the secret checks print a label only). Security Low (5) of `backup-secret-scan`.
- Why it matters: a credential inside a URL (a token before the host) appears in the gate output, the stage logs, and CI.
- Fix outline: mask whatever matches `KEY_RE`, `TOKEN_RE`, or `ASSIGN_RE` with `[secret]` (a sed replacement) before printing any hit, with a `tools/tools_test.sh` case.

## The close note names the backup when there was none

- Where: `.claude/workflows/deliver-change.js` line 718 (the close note says the backup stays on origin whenever a run stops unmerged, even after the push deleted it or when no backup was made). Quality advisory of `backup-secret-scan`.
- Why it matters: the report sends the user to `abandon` a backup that does not exist.
- Fix outline: also require `state.backup`, the record `backup_branch` writes and `drop_backup` drops.

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
