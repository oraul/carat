# Backlog

Known items to fix in later changes. A finding that a change does not fix, because it is outside the change's scope or below the confidence the contributor agent acts on, is recorded here with where it is in the code, why it matters, and how to fix it, so that it is not lost and the next change can start from it. During a delivery entries are only appended, at the end of the file, and a change works from the entries its queue item names, found by a grep rather than by reading the file; the periodic review merges duplicates, removes the entries that are fixed or name gone code, and turns entries into queue items.

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

## Sentence motions rescan the whole buffer on every use

- Where: `Carat::Domain::Motions.sentence_starts` in `carat/domain/motions.rb` (line 416 at 7711421), called by `(` and `)` and by the `is` and `as` text objects in `carat/domain/text_objects.rb` (line 150 at 7711421). Raised again at ce6abdb (`motions.rb:398`, `sentence_starts`, on every `(`, `)`, `is`, or `as`; periodic quality), queue item `editing-counts`: scan from the paragraph before the cursor to the one after, or cache the starts by the buffer's change count.
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
- Fix outline: report it upstream to Spinel with the benchmark and the `SPINEL_SLAB_HUGE=0` measurement, asking for released chunks to be kept for a while or for huge pages to be skipped for small heaps; until then, a workaround is to keep released chunks resident (a larger per-worker reserve) if Spinel exposes it, or to document `SPINEL_SLAB_HUGE=0` for interactive use, and bump `SPINEL_REF` in its own change once the runtime changes. Rechecked at f34005bf: still open, `lib/sp_slab.c` still releases with `MADV_DONTNEED` on `MADV_HUGEPAGE` arenas.

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

## Spinel f34005bf miscompiles versioned entries and case constants

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`), new between 001419ff and f34005bf: the version entries of `src/call_plan.c` (#9898) and the constant readers of `case`/`when`; worked around in `carat/use_cases/plugins/plugin_entry.rb` (`attach`), `carat/domain/mode.rb` (`visual_kind`), `Host#icon` and `Host#stat` in `carat/plugin_api.rb`, and `FilePort#stat` in `carat/ports/file_port.rb`.
- Why it matters: without the workarounds the release build does not compile (an entry's parameter typed from the argument's class, not the dispatched signature), charwise visual selections read as none (a `when` on a constant whose name another scope defines with another type folds to false), and `make diagnose` reports unresolved readers (an entry's return joins a raising base's `nil`); `docs/spinel-notes.md`, Known miscompilations, has the mechanism.
- Fix outline: report each upstream with its reduced probe (the `when` probe: two modules defining `VISUAL` as a Symbol and an Integer, a `case` on the Symbol), then drop the workarounds in the bump that carries the fix. The `when` defect bisects to Spinel ade8cfe2; the versioned-entry defects have no reduced probe yet (a one-file probe of the plugin shape compiles at both pins), so the report names the carat build that shows them. `PluginEntry#attach(host)` (`carat/use_cases/plugins/plugin_entry.rb:51`) is a one-value setter not named `link=`, kept only because the Struct writer does not upcast (quality advisory at spinel-bump): the bump that clears this entry drops it for `self.link=`.

## Spinel loses the types of an array destructured inside a method

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); seen in the test helpers `setup` of `test/use_cases_plugins.rb`, `editor` of `test/use_cases_plugin_files.rb`, and `run` of `test/domain_grammar.rb`, which returned `[a, b, ...]` for the caller to destructure (`state, host, keymap, files, ex = setup(...)`).
- Why it matters: at the top level of a program those locals kept their types, but once the `test-build` change moved each test's statements into a method, they became poly: in `test/use_cases_plugins.rb` the generated C did not compile (`expected statement before ')'` at each `state.cursor.row = 1`), and in the other two spinel-doctor reported unresolved calls on poly receivers. A minimal program with three values of three classes kept its types, so the trigger is not yet isolated. The helpers now return an object with typed readers, which is the convention in `CLAUDE.md`; production code has no such destructuring.
- Fix outline: restore the array return of `setup` in `test/use_cases_plugins.rb` and reduce it to a minimal reproduction (five values from a helper, destructured twenty times inside one method, one of them an attribute chain assigned through), report it upstream to Spinel, and drop the convention once a `SPINEL_REF` bump compiles it typed. Rechecked at f34005bf: the reduced probe keeps its types at both 001419ff and f34005bf, so only reverting a helper decides it.

## Spinel answers a method's argument for some string returns

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); seen in `carat/domain/rc_value.rb` and `carat/domain/config.rb` during the `caratrc-config` change. `RcValue.expectation(kind)`, written as a `case` whose branches were string literals, answered the kind itself when called with a literal; `RcValue.text(words, kind)`, written as `words.empty? ? "" : words[0].to_s`, answered the kind; and `SCOPES.include?(line.scope)` answered false for a scope the array holds, while the same call through a local answered true.
- Why it matters: each is silent wrong code, not a compile error; only the table tests caught them. The three places are rewritten (guard returns, a local for the first word, a local for the scope), but the same shapes elsewhere could be affected.
- Fix outline: reduce each to a minimal program (a module function with a literal-branch `case` called with a literal; a ternary of `""` and an indexed `to_s` in a two-parameter method; a constant array's `include?` of a reader called on a `Data` value; a guard `return path if slash.nil?` before `path.byteslice(...).to_s`, which answered the path inside the whole program in `PluginApi::Paths.basename` during `utf8-input-safety` though not in a small probe), report them upstream, and recheck them when `SPINEL_REF` is bumped. Rechecked at f34005bf: the four reduced shapes answer correctly at both pins, so only reverting the rewritten places decides it.

## The plugin host keeps many-method classes in use_cases

- Where: `carat/use_cases/plugins/`: `PluginHost` (18 public methods besides `call`), `PluginRegistry` (24), `PluginEntries` (5), `PluginEntry` (5), `PluginEvents` (4), `PluginRouter` (4), `PluginSyntax` (3), and `PendingEvent` (1), which the one-call rule of `test/lint.rb` skips by directory since the `use-case-boundaries` change; the request families (`BufferRequests`, `WindowRequests`, `FileRequests`, `UiRequests`) and `PluginLink` keep their request methods by design, as the adapter of `PluginApi::Host`.
- Why it matters: the rule that a use case exposes only `call` holds for the core, but the host's parts are not use cases at all: they are the infrastructure between compiled plugins and the core, and while they sit in `use_cases` the layer reads as if a use case could have two dozen entry points. The `use-case-boundaries` change decided they move out with the whole host and left the move to this plugin-side part, because it reworks the host's construction, the assembly, and five test programs.
- Fix outline: move `carat/use_cases/plugins/` with `concerns/guarded.rb` and `plugins/boundary.rb` to carat/adapters/plugins/ as `Carat::Adapters`, give the core a port in `carat/ports/` for the calls the use cases make into the host (`observe`, `saved`, `resized`, `answer`, `action`, `command?`, `command`, and the tokenizer calls of `HighlightView`), implemented by the host and handed to `SaveFile`, `HandleKey`, `CancelCommandLine`, `ExecuteCommandLine`, `PluginActionHandler`, `PluginCommandHandler`, and `HighlightView` by the assembly, keep the request families' request methods, update the layer ranks and `docs/architecture.md` sections 3, 5, and 9, and drop the `use_cases/plugins/` exemption from the one-call rule.

## Spinel drops appends to an empty array literal passed to a method

- Where: found in `Config#report` (`carat/domain/config.rb`), whose merge helper first appended to an array the caller created as `[]`; on the pinned Spinel the caller's array stayed empty, while one created as `[0]` kept the appends (`docs/spinel-notes.md`).
- Why it matters: any helper that fills an out-parameter starting empty silently loses its work, and only a test of the result catches it.
- Fix outline: reduce it with `spinel-reduce`, report it upstream with the probe, and when a fixed pin arrives let `merge_runs` append in place again; until then a filling helper returns the array and the caller assigns it. Rechecked at f34005bf: a reduced `merge_runs` keeps the appends at both pins, so only reverting `Config#report` decides it.

## Spinel compiles private_constant without enforcing it

- Where: the pinned Spinel (`SPINEL_REF` in the `Makefile`); every `private_constant` line under `carat/use_cases/` since the `use-case-boundaries` change.
- Why it matters: a probe on the pinned compiler compiled `private_constant :NAME` and still let another class read `Owner::NAME`, which CRuby refuses with `NameError`, so the declaration documents the intent but stops nothing. `private` on methods is enforced (a call raises `NoMethodError`). `test/lint.rb` carries the rule instead: every constant of a use case file is listed in a `private_constant`, and no file names `Owner::NAME` of a use case outside its own file.
- Fix outline: reduce it to a minimal program (a class with a private constant read from another class), report it upstream, and when a `SPINEL_REF` bump enforces it, keep the lint rule only as a check that the list is complete. Rechecked at f34005bf: still open, the probe still reads `Owner::NAME` from another class.

## Nothing compiles the generators' output on every check

- Where: `tools/new.sh` and its tests in `tools/tools_test.sh`, which check the files each generator writes and the lines it inserts, not that they compile.
- Why it matters: a convention that changes (a base class's constructor, an anchor's neighbor, a lint rule) could leave a generator writing code that no longer compiles or lints, and nothing would say so until an author ran it. The `authoring-kit` change compiled, linted, and tested the output of all five generators by hand in a scratch worktree (59 tests, `spinel-doctor` clean).
- Fix outline: a `make generators-check` target that runs every generator in a temporary worktree, then `make gen-config`, `make lint`, `make test-build`, and `make test-run` there, run by the checker when `tools/new.sh`, `carat.rb`, `EditorAssembly`, the handler bases, or `test/lint.rb` change rather than on every check, since it costs a full analysis of the library. The same holds for `tools/spinel/gen_respond_to_tables.rb`, the Ruby 4 port of Spinel's header generator (quality advisory at spinel-bump): no check compiles it, so a later pin that breaks it is found only at the next bump; compile it in `make tools-test` or in the same target.

## CI actions are pinned by tag

- Where: `.github/workflows/ci.yml` (line 36 `actions/checkout@v4`, and the same at lines 65, 91, 175, and 192, with `actions/cache@v4` and its `restore` and `save` forms). Low finding of the periodic security review at 66fd52b; at eb63fb4 the periodic security review found line 24 too, Low (3). Raised again at bff9a02 (#96): periodic security Low (6) at `.github/workflows/ci.yml:36`; queue item `ci-hardening`.
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

## lh time per key rose 26% at window-navigation-and-scroll

- Where: the `review.bench` record of `window-navigation-and-scroll` (lh median 11.7 to 14.8 microseconds per key, allocations 27.0 unchanged); no code location is known. Advisory of the periodic quality review at 66fd52b.
- Why it matters: goal 3 of `docs/goals.md` watches time per key; a rise reported as not blocking and never measured again may hide a cost of the prefix wait or the `breaks_insert` check.
- Fix outline: run `make bench SCENARIOS=lh` on `main` and on its parent several times on one pinned core; if the rise holds, profile `lh` with `make profile` and fix or record the cause.

## Illegal bytes are drawn as U+FFFD, not as hexadecimal markers

- Where: `DecodedLine.decode` and `FramePresenter#paint_text` (`carat/domain/decoded_line.rb`, `carat/adapters/frame_presenter.rb`); `utf8-input-safety` draws each byte outside a well-formed UTF-8 sequence as one U+FFFD cell.
- Why it matters: Neovim shows such a byte as a four-cell `<xx>` marker, so two lines that differ only in an illegal byte look alike here, and the byte cannot be read from the screen.
- Fix outline: decode an illegal byte to a code that keeps the byte (for example a private marker range), draw it as `<xx>` the way the C1 markers are drawn, measure it as four cells in `DecodedLine`, `DisplayWidth`, and the cursor placement, and add rows to `test/domain_utf8.rb` and `test/adapters_frame_presenter.rb`.

## Options repeats its bounded-number and known-name checks

- Where: `Options#apply` in `carat/domain/options.rb`: the `tabstop` and `shiftwidth` blocks (lines 107 to 120) and the `icons` and `theme` blocks (lines 125 to 136) are each the same check-then-set-or-note shape. Advisory of the periodic quality review at 389c118. At 38628bb `keyhints.delay` (line 156) repeated the shape too (periodic quality), and at 7711421 the `breadcrumbs` block (line 221, periodic quality); `layout-slots` shares `Options.range_problem` between it and the three slot sizes, leaving `tabstop`, `shiftwidth`, `icons`, and `theme`. Raised again at be4b63a (now six copies).
- Why it matters: a third bounded option copies the block again, and a fix to one copy can miss the other.
- Fix outline: one private helper that takes the line, the value, and the low bound and returns whether to set (or a `width_value?` check both call), and one for a name checked against a known set; the rows of `test/domain_options_config.rb` stay as they are.
- Raised again as "Options#apply repeats one block four times": Where: `carat/domain/options.rb` line 172 (tabstop, shiftwidth, `keyhints.delay`, the layout sizes), at 31919d9. Periodic quality. Queue item: backlog items, `:set` checks. Why it matters: duplication: each branch computes a problem, assigns when empty, else notes it. Fix outline: one private helper taking the problem and the line, answering whether to assign.

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

- Where: the `:replace` branch of `ascii_recase` in `carat/domain/operators.rb` (line 243, `char * text.length` over text that is not UTF-8), while `~`, `U`, and `u` have rows in `test/editor_registers.rb` (lines 49 to 51). Advisory of the periodic quality review at 6ea61b1.
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

## Operate passes the search outcome through an instance variable

- Where: `Operate#search_motion` in `carat/use_cases/operate.rb` (line 131), which sets `@notice` deep in `motion_for` for `call` to read. Quality advisory of `buffer-search` at 2b54295641e0 and again at a36858a2bc88. Raised again at 9a92265 (#99): the same side channel in `walk_history.rb` line 32.
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

## FindMatch re-implements the domain's character classes

- Where: `FindMatch#keyword?` and `#blank?` in `carat/use_cases/search/find_match.rb` (line 129), `keyword?` through the bare class number in `Motions.code_class(code, false) == 2`. Periodic quality at 0b17324. Raised again at ce6abdb (`find_match.rb:134`, `blank?`; periodic quality), queue item `editing-counts`.
- Why it matters: the word under the cursor for `*` and `#` is judged by a copy of the classes `Domain::Motions` owns, keyed on an unnamed number, so a change to the classes leaves the search motion behind.
- Fix outline: a code-point predicate in `Domain::Motions` (or a named class constant) called from `FindMatch` and the runs scan. Queued in `search-structure`.

## The local cls is the abbreviation the naming rule forbids

- Where: the local `cls` in `carat/domain/text_objects.rb` (line 86 at 3895e21) and the parameter `cls` of `Runs#add` (`carat/domain/runs.rb:18`). Periodic quality at 0b17324. Raised again at ce6abdb (periodic quality), queue item `editing-counts`. Raised again at be4b63a (owner `editing-counts`).
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

- Where: `.claude/workflows/deliver-change.js` line 695, the fallback flush after a closing start that did not record, and `add_note` in `tools/run_state.sh`, which dedupes only `quality-advisory` notes. Quality advisory at e8c5b43 in `pipeline-speed-c`. Raised again at ce6abdb (`tools/run_state.sh:1103`; periodic quality): a restarted periodic start records its findings twice; the same bare-text comparison for the quality and security kinds, queue item `run-budgets-tidy`.
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

## The content gate skips files git treats as binary

- Where: `tools/gates.sh` line 126 (`gate_content` reads `git log -p`, which prints no lines for a file with a NUL byte or one `.gitattributes` marks `-diff` or `binary`, and the merge gates run from the branch's checkout, so the branch can set them). Security Low (6) of `backup-secret-scan`; raised to periodic security Medium (7) at b0dd342 (`tools/gates.sh` line 179). Since `url-email-guard`, `tools/scan_text.sh` prints a `note:` line naming such a file in the content gate's output ("a binary file, not scanned"), but does not refuse it; the refusal stays here.
- Why it matters: a committed secret in such a file passes the secret, URL, email, and model checks.
- Fix outline: pass `--text` and `--no-textconv` to the `git log -p` scan, or refuse an added binary file and a `.gitattributes` change setting `diff`, `binary`, or `textconv` unless a reviewer allows it, with a `tools/tools_test.sh` case. Queued in `content-gate-gaps`.

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
- Raised again at 6a0db20 (periodic quality, note 19).

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
- Fix outline: build a glyph-to-group table once in `activate` from `host.icon` and `FileIcons::GROUPS`, look up the glyph at the icon column in `tokenize`, and drop `@line_groups` and `tree_lines`, together with the byte-walk entry above it. Queued in `carat-palette`.

## The background option's values are bare literals

- Where: `Options#initialize` in `carat/domain/options.rb` (line 45 at `theme-tokens`), `Themes.find` (`"theme"`), and `BACKGROUNDS` in `carat/domain/themes.rb`, while the theme's default is `Themes::DEFAULT`.
- Why it matters: the default and the painted value are spelled in three places, so renaming or adding a value can leave one behind.
- Fix outline: add `Themes::DEFAULT_BACKGROUND` and a `PAINTED` constant and use them in `Options#initialize` and `Themes.find`.

## The screen presenter's first painted row test accepts two outputs

- Where: `test/adapters_screen_presenter.rb` (line 318 at `theme-tokens`), whose assertion joins two expected sequences with `||`.
- Why it matters: the test does not pin what the presenter writes for the first painted row, so a regression to the other sequence passes.
- Fix outline: assert the one exact sequence the snapshot shows.

## The architecture gives the plugin API as 2.0

- Where: the plugin API version sentence of `docs/architecture.md` (line 321 at `theme-tokens`) and its `syntax_group` and `tokenize` bullets near lines 295 to 296, while `carat/plugin_api.rb` (line 12) and `docs/plugins.md` (line 23) give 2.3 at 803fe6e. Periodic quality at 4c65f4e and 803fe6e. Raised again at 38628bb (periodic quality). Queued in `architecture-drift`.
- Why it matters: the binding architecture lists changes only through 1.3 and misses 2.1's file-icon groups in `syntax_group` and tokens and a scratch buffer's syntax named after its plugin, 2.2's `set_segment` and `PluginApi::FileIcons`, and 2.3's floats (`open_float`, `move_float`, `close_float`, `FloatOptions`), so a plugin author reading it targets an older API.
- Fix outline: say 2.3 and add the 2.1, 2.2, and 2.3 additions to the version sentence and to the `syntax_group`, `tokenize`, and window request bullets, within the file's budget.

## Operate and RepeatLast each copy EditorState#clamp_col

- Where: the private `clamp(state, row, col)` in `carat/use_cases/operate.rb` (line 202 at `theme-tokens`) and `carat/use_cases/repeat_last.rb` (line 117), each `EditorState#clamp_col` in `carat/domain/editor_state.rb` (line 97) line for line. Periodic quality at 4c65f4e. Raised again at ce6abdb (`operate.rb:202`, `repeat_last.rb:116`; periodic quality), queue item `editing-counts`.
- Why it matters: three copies of one clamp must change together, and a fix to the domain's misses the two use cases.
- Fix outline: call `state.clamp_col(row, col)` at the six call sites and delete both private methods. Listed in the queue's backlog item.
- Raised again as "end_visual re-implements clamp_col": Where: `carat/domain/editor_state.rb` line 120 at c1b3a12 (periodic quality), beside the entry Operate and RepeatLast each copy EditorState#clamp_col. Queued in item 46. Why it matters: a third copy of the clamp. Fix outline: call clamp_col after the mode is set to normal.

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

- Where: the loop over `openspec/changes/` in `tools/spec_validate.sh` (line 25 at `package-clean`), which empties `build/spec-preview` for each active change while the header and the failure message promise a failed preview is kept. Quality advisory of `package-clean`. Raised again at be4b63a, a duplicate of the failed spec preview entry (owner `backlog-compaction`).
- Why it matters: with two active changes, the first one's failed preview is gone before anyone reads it, so the message points at a directory holding the wrong change.
- Fix outline: preview each change under `build/spec-preview/<name>`, or stop after the first failure.
- Raised again as "A failed spec preview is deleted by the next change's preview": Where: `tools/spec_validate.sh` line 129. Periodic quality at 8d8832f, queued in `run-budgets-tidy`. Raised again at be4b63a, a duplicate of the spec preview entry (owner `backlog-compaction`). Why it matters: the header promises a failed preview is kept for reading, but each active change resets it. Fix outline: one preview directory per change, or stop resetting after a failure, with a case.

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

## Five methods walk every window of every tab page

- Where: `shown?` (line 128 at 68eb750), `windows_showing` (line 145), `focus_buffer` (line 164), and the private `modified_in_page` (line 229) in `carat/domain/tab_list.rb`, and `BufferList#close_windows_of` in `carat/domain/buffer_list.rb` (line 308). Periodic quality advisory at 68eb750.
- Why it matters: a change to how windows are enumerated has to land five times.
- Fix outline: answer each question through one walk, for example `shown?` from `windows_showing`, with the `test/` rows unchanged. Queued as `buffer-list-structure` in `docs/queue.md`.

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
- Raised again as "HandleKey drops the queue dispatch returns": Where: `carat/use_cases/handle_key.rb:247` (`step`) and :272 (`complete`), against dispatch's contract at :278-280. Periodic quality at bd86828. Why it matters: the contract exists because the pinned Spinel can lose appends to the caller's array; `step` relies on in-place mutation anyway. Fix outline: honor the contract or drop it, with a test that fails without the fix. Queue item `spinel-workarounds`.

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

## The periodic review caps design names the wrong owner of the overrun notes

- Where: `openspec/changes/archive/2026-11-06-periodic-review-caps/design.md` line 20, against `.claude/workflows/periodic-review.js` lines 96 to 97 and `.claude/workflows/deliver-change.js`. Quality advisory of `periodic-review-caps`.
- Why it matters: the decision says the periodic result returns the cap and the delivery workflow notes overruns with its `overCap`, but the periodic workflow writes the overrun notes itself and returns `over`, and the delivery workflow only logs them, so the archived record misleads the next change to this code.
- Fix outline: add a note to the next change touching the periodic workflow's caps that corrects the decision (the archived design is not edited), or move the noting into the delivery workflow so the design holds.

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
- Fix outline: delete the dead line, and drop `saved_float` and its `enter`, or document that `in_window` keeps the focus for callers that do not refocus. Queued in `float-placement` with the other `floating-windows` notes.

## FloatLayer is a plain class among the mutable records

- Where: `carat/domain/float_layer.rb` line 10 at 803fe6e. Periodic quality advisory.
- Why it matters: `CLAUDE.md` makes mutable records `Struct` subclasses with pinned members; `TabPage`, `TabList`, `LastFind`, and `StatusSlots` follow it, `FloatLayer` does not.
- Fix outline: a `Struct` with `floats` and `focus` pinned, readers and `self.member =` writers, built with keywords in `TabPage`. Queued in `float-placement`.

## move_float bypasses the float use cases

- Where: `WindowRequests#move_float` in `carat/use_cases/plugins/window_requests.rb` (line 247 at 803fe6e). Periodic quality advisory.
- Why it matters: `open_float` and `close_float` go through `OpenFloat` and `CloseFloat` as section 5.3 asks of request families, while `move_float` writes the tab page's `FloatLayer` directly and ignores the result of `move`.
- Fix outline: a `MoveFloat` use case beside the other two, or a class comment saying a move is a domain write needing none, with `FloatLayer#move` made void. Queued in `float-placement`.

## The architecture names no float

- Where: `docs/architecture.md` at 803fe6e: the Window, Layout, TabPage bullet (line 129), the Frame bullet (line 130), section 5.3 (line 177), and the ArrangeView bullet (line 178). Periodic quality advisory.
- Why it matters: the binding architecture omits `FloatSpec`, `FloatWindow`, `FloatLayer`, `TabPage#window` answering the focused float first, `OpenFloat`, `CloseFloat`, float placement, and the float key.
- Fix outline: add the three entities to section 4, the two use cases and the placement to section 5.3, and the key to the Frame bullet, within the file's budget. Queued in `architecture-drift`.

## A language server that ignores the end of its input outlives the editor

- Where: `ProcessRunner#stop` in `carat/drivers/process_runner.rb` at `lsp-diagnostics`. Periodic security Low (5) at eb63fb4.
- Why it matters: stop closes the child's input after `shutdown` and `exit` and detaches it without a signal, so a server that neither exits on `exit` nor on the end of its input keeps running after the editor ends; ruby-lsp exits on both.
- Fix outline: after closing the input, send `TERM` from the writer thread when the child has not ended within a second, and `KILL` a second later, with a test over a child that ignores its input. Queued in `lsp-client-tidy`.

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

## Icons sit in the explorer's map area

- Where: `docs/codebase-map.md:545` (periodic quality at 5722559).
- Why it matters: `carat/domain/icons.rb` and `test/domain_icons.rb` are in area 16, but the explorer never calls `Icons`; its callers are the bars, the gateway's signs, the plugin requests, and the completion kind icons.
- Fix outline: move both entries to area 13 Rendering.

## Map method lists lag the code

- Where: `docs/codebase-map.md:502`, 438, 435, 614 (periodic quality at 5722559); also lines 151, 185 to 188, and 285 at c1b3a12 (periodic quality, docs-index): the `LastChange` bullet omits `split` and `unmeasure`, and the other two lag their files' method lists. At 38628bb also `docs/codebase-map.md` lines 223, 292, and 320 (periodic quality); at b76b722 also PaintedRows, Frame, FakeTerminal, EditorHarness (lines 450 to 638), Layout, TabList, BufferList, and FloatLayer (lines 256 to 355) miss public methods.
- Why it matters: `PluginApi::Paths` omits `absolute`, `StatusSlots` omits `set_lsp` and `label`, `FramePresenter` omits `float_group`, `EditorHarness` omits `completions`; a reader trusting the map misses the methods.
- Fix outline: add the missing names at each line. Queued in `docs-index`.

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

- Where: `clone_make` in `tools/run_state.sh` (the symbolic links to `tmp/.toolchain` and `tmp/.spinel`), and the benchmark's `make metrics` and `make bench` in the delivery clone (`.claude/agents/benchmark.md`). Residual risk of `check-isolation`, reported again in its delivery review as security Medium (6) and Low (5) at `tools/run_state.sh` line 529, and by the periodic security review at cd87445 as Low (5) at the same line (the toolchain links the check clone shares). Raised again at bff9a02 (#96): the check clone links the writable toolchain, periodic security Low (4) at `tools/run_state.sh:529`; queue item `check-runner-safety`.
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
- Raised again as "The palette bench scenario is not in the default list": Where: `bench/run.sh` line 69, the default scenario list, against `bench/keys.rb` line 145 (`palette`), named in the discovery area's Bench line since `float-frame`. Quality advisory of `float-frame`. Why it matters: `make bench` without `SCENARIOS` never measures the palette, so a regression in its refiltering goes unseen. Fix outline: add `palette` to the default list if it is meant to run by default, or say in the map why it is opt-in. Queue item `run-budgets-tidy`.

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

- Where: `forget_server` (the signature ask, `forget_signature` before periodic-blockers-a; line 526 at d73f03f) in `carat/adapters/json_rpc_language_gateway.rb` (dropping the language and the request in flight on a crash, `:LspStop`, or `:LspRestart`) and the in-range `activeSignature` choice at line 818, at c59a43d. Quality advisory in `parameter-info`.
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

## The hover request holders are reached through other use cases

- Where: `carat/adapters/input_controller.rb` line 81 reads the shared `HoverRequest` through `show_hover.hover`, and `carat/use_cases/handle_key.rb` line 93 through `follow_hover.hover`, at b0dd342. Periodic quality. Queued in `hover-tidy`.
- Why it matters: the holder rule and `test/adapters_assembly.rb` never see these holders, so a second instance would pass.
- Fix outline: pass the request from `EditorAssembly` to both, with readers checked in the assembly test.

## The completion close use case is shared through a local

- Where: `close_completion` in `carat/adapters/editor_assembly.rb` line 336 at b0dd342, shared by `ShowCompletion` (338), `AcceptCompletion` (344), and `CompletionHandler` (413). Periodic quality, blocking. Queued in `completion-tidy`. Raised again at ce6abdb (periodic quality), with `open_popup` (`editor_assembly.rb:429`, beside `close_completion` at 398) shared the same way: assembly readers for both, asserted per holder in `test/adapters_assembly.rb`.
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
- Raised again as "ci_scope asks for the same pull request twice": Where: `tools/ci_scope.sh:50` and `:51`. Periodic quality. Raised again at be4b63a (owner `check-skip`). Why it matters: two calls for the head and the number can disagree. Fix outline: one call printing both fields. Queue item `ci-hardening`.
- Raised again as "The CI scope fetches one answer twice": Where: `tools/ci_scope.sh:50-51` (two calls fetch the same commit's pull request). Periodic quality at bd86828. Why it matters: CI time and API calls. Fix outline: one call read into both values. Queue item `ci-time`.

## A link planted in the check clone's build directory survives

- Where: `clone_drop` in `tools/run_state.sh` line 566 at b0dd342 copies `build/` into the carry with `cp -RP`. Periodic security Low (5). Queued in `check-runner-safety`.
- Why it matters: a symbolic link a stage plants in `build/` reaches `build/stages/CHANGE/carry` and the next clone, so the clone is isolated by environment only.
- Fix outline: drop links from the carry or refuse them when copying, with a case.

## WalkHistory keeps one walk's counts in instance variables

- Where: `@gone`, `@back`, and `@empty_before` in `carat/use_cases/history/walk_history.rb` lines 32, 80, and 109 at b0dd342. Periodic quality. Queued in `editing-counts`. Raised again at ce6abdb (line 32; periodic quality): a returned tally value.
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

- Where: `apply`, `bind_text`, and `holder_of` in `carat/domain/keymap.rb` lines 141, 162, and 205 are public with no outside caller; `leader_problem` and `no_actions` are missing from the map's `Keymap` entry; the `CommandGrammar` entry (`docs/codebase-map.md` line 146) omits `digit?`, `digit`, `char`, `wants_pattern?`, and `pattern`; the `Paths` list (line 503) omits `absolute` (`carat/plugin_api.rb` line 356), at b0dd342. Periodic quality. Queued in `docs-index`. Raised again at ce6abdb (periodic quality, `keymap.rb` 173 `apply` and 242 `holder_of` copying `node_at`), adding `bind` at 223 with no caller and `name_group` at 314 copying `bind_text`'s checks at 200: remove `bind` and its map mention, a private `keys_problem`; queue item: the backlog batches. Raised again at be4b63a.
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
- Raised again as "Eight Vim messages are spelled in more than one file": Where: `KNOWN_REPEATED_MESSAGES` in `test/lint.rb`: E32 (`file_command_handler.rb`, `save_file.rb`), E33 (`vim_pattern.rb`, `substitute_lines.rb`), E474 (`history_command_handler.rb`, `messages_command_handler.rb`), E477 (the delete, global, and substitute command handlers), E484 (`path_info.rb`, `visit_target.rb`, `open_file.rb`), E486 (`find_match.rb`, `substitute_lines.rb`), E488 (`register_count.rb`, `substitute_args.rb`, and the buffer, LspRestart, and LspStart command handlers), E939 (`register_count.rb`, `substitute_lines.rb`). Recorded by `implement-contracts-c`, queued in `messages-tidy`. Why it matters: a wording fix can reach one copy and miss the others; lint refuses a new repeat but keeps these listed. Fix outline: one `Domain::Messages` constant or function per message, called from every file, and the line removed from `KNOWN_REPEATED_MESSAGES` (lint fails on a listed message that no longer repeats).

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

- Where: the merge and CI phase records of `.claude/workflows/deliver-change.js`; in `parameter-info` (#78) the reply swapped the pushed head and the squash commit, so 3 phases were recorded at a commit not on main (retrospective). Queued in `merge-gate-tidy`. Raised again at 9a92265 (#99 retro note 6).
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

- Where: `plugin_of` in `carat/use_cases/discovery/open_palette.rb` line 91 against `PluginRouter` line 36, and the one-line single-use `palette_add_plugin` at line 85, at d828abb. Quality advisories in `discoverability`. Raised again at 38628bb and b76b722 (periodic quality); a second entry for `palette_add_plugin` was folded in here at 186ddfb. Queued in `menu-hints`.
- Why it matters: two parsers of `plugin.<name>.<action>` can drift, and the wrapper adds a hop for one call.
- Fix outline: have `PluginRegistry` return the enabled plugins' action names (the same method the palette entry above needs) and inline `@palette.add` into `add_plugin_actions`.

## Three discovery comments are stale or break their wrap

- Where: the class comment of `carat/use_cases/discovery/hide_key_hints.rb` (line 8), the class comment of `carat/use_cases/discovery/show_key_hints.rb` (line 23, longer than its neighbors), and the comment at `carat/use_cases/handle_key.rb` line 66 (breaks after "While the"), at d828abb. Quality advisories in `discoverability`. Raised again at 38628bb (periodic quality). Queued in `menu-hints`.
- Why it matters: the first says a binding resolved by `timeoutlen` closes the hints, but `timeout` never calls `HideKeyHints` and the hints never show over a `:pending` key; the others are style only.
- Fix outline: drop the clause from the `HideKeyHints` comment and rewrap the other two to the width of the lines around them.

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

- Where: `carat/domain/palette.rb` lines 31 and 55 at 38628bb (periodic quality). Queued in `menu-hints`.
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
- Raised again at 6a0db20 (periodic quality, note 24): also `ci(` on `()` at `carat/domain/text_objects.rb:307`. Owner: queue item `editing-counts`.

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
- Raised again at 6a0db20 (periodic quality, note 45): `Makefile:238`, `:272`, `:329`. Owner: queue item `run-budgets-tidy`.
- Raised again as "The Makefile repeats its timed compile and misdescribes gates": Where: `Makefile:241`, `:275`, `:332`, `:383`. Periodic quality advisory. Fix outline: one `define timed_compile`; describe static as the gates that need no run state, here and in CLAUDE.md. Queue item `check-skip`.

## metrics compare passes a strict metric missing from the run

- Where: `compare` in `tools/metrics.sh` line 86 at 38628bb (periodic quality). Queued in `run-budgets-tidy`. Raised again at be4b63a, notes 23 and 43 (owner `run-budgets-tidy`).
- Why it matters: only the current names are walked, so an `allocs.*` or `rounds.*` name of the base that the run lacks passes, against the header's rule.
- Fix outline: fail each strict base name not seen, with a `tools/tools_test.sh` case.
- Raised again at 6a0db20 (periodic quality, note 47): `tools/metrics.sh:86`. Owner: queue item `run-budgets-tidy`.

## The runner's wait is longer than it says, in two copies

- Where: `runner_finish` in `tools/run_state.sh` line 698 and `check_wait` at line 646, at 38628bb (periodic quality). Queued in `check-runner-safety`.
- Why it matters: the 30-second wait is 150 pauses, 150 seconds where a pause falls back to one second, and the loop is copied.
- Fix outline: one wait helper bounded by elapsed seconds, used by both.

## A run_state.sh paragraph splits its Usage list

- Where: `tools/run_state.sh` lines 63 to 66 at 38628bb (periodic quality, raised twice). Queued in `run-budgets-tidy`.
- Why it matters: the paragraph on refused keys sits between the set and phase entries.
- Fix outline: move it above or below the list.
- Raised again as "The run_state header splits its usage list": Where: `tools/run_state.sh:71`. Periodic quality. Why it matters: the refusal paragraph sits inside the list the usage prints. Fix outline: move it after the list. Queue item `run-budgets-tidy`.

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

- Where: the hide branch of `carat/use_cases/windows/toggle_slot.rb` lines 35 to 37, repeating `BufferList#close_window` (`carat/domain/buffer_list.rb` lines 282 to 284), and the kept-slot restore at lines 40 and 48 to 49, repeating `carat/use_cases/windows/open_side_window.rb` lines 35 to 38; the `current` lookup again after `place_slot` at lines 47 and 50, at edaf2c2. Quality advisories in `layout-slots`, raised three times. Raised again at ce6abdb (`toggle_slot.rb:30` against `buffer_list.rb:282` and `open_side_window.rb:27`; periodic quality), queue item `slots-tidy`: a `TabPage#remove_leaf(id)` and one re-show step.
- Why it matters: two copies of closing a leaf (layout close, current to the taker's first leaf, previous forgotten) and of placing a kept slot (kept and listed, `place_slot` at its size, `hidden = false`) drift apart; the second `current` lookup is dead, since `attach` and `panel_target` never renumber existing leaves.
- Fix outline: one `TabPage#close_leaf(id)` called by `ToggleSlot` and `BufferList#close_window`, one method that places a kept slot and answers the leaf or -1, called by both use cases, and drop the `current` local and its reassignment.

## The side string is mapped by a nested ternary and dispatched in four places

- Where: `carat/use_cases/plugins/window_requests.rb` lines 319 to 321, and the side dispatch in `TabPage#slot`, `TabPage#slot_at`, `Options#slot_size`, and `ToggleSlot#name_of`, at edaf2c2. Quality advisories in `layout-slots`, raised twice.
- Why it matters: the nested ternary is harder to read than the `if`/`elsif` of `TabPage#slot`, and four copies of the side dispatch drift when a slot is added.
- Fix outline: map the side once with a `case` or a small lookup and keep the per-side dispatch in `TabPage`.

## Layout#fixed_width? has no production caller

- Where: `carat/domain/layout.rb` line 297, called only by `test/domain_layout.rb` line 265 and named in `docs/codebase-map.md`, at edaf2c2. Quality advisory in `layout-slots`, raised twice. Raised again at ce6abdb (line 299; periodic quality), queue item `slots-tidy`.
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

- Where: `docs/architecture.md` line 113 (the Options bullet) and line 174 (section 5.2), at b76b722. Periodic quality. Queue item `architecture-drift`. Raised again at be4b63a (owner `docs-index`).
- Why it matters: the bullet lists `wrap` and `clipboard` as members, which are only checked keys of `Options::KINDS`, and omits `theme`, `background`, `syntax_on`, `startscreen`, and `reducedmotion`; section 5.2 lists `setlocal`, which has no handler, and says `:set` handles filetype and syntax only.
- Fix outline: list the members as `carat/domain/options.rb` declares them, the options `:set` handles, and drop `setlocal` until a handler exists.

## The architecture and the queue sit at their byte budgets

- Where: `BUDGETS` in `tools/docs_lint.sh` line 44: `docs/architecture.md` 88,058 of 88,064 bytes, at b76b722. Periodic quality. Queue items `breadcrumbs` and `architecture-drift`. At ce6abdb (periodic quality) the architecture is 88,063 of 88,064 bytes, so every spec change rewords text it does not change to fit, as #93 did; queue item `docs-index`. Raised again at be4b63a, 88,061 of 88,064 bytes (owner `docs-index`). At 9a92265 `.claude/agents/contributor.md` had 29 bytes left of 8,192 (#99 note 32); `url-email-guard` filled it to 8,192 adding `make hooks`.
- Why it matters: the next change adding a sentence to the architecture fails `docs-lint` in its check stage.
- Fix outline: trim history and detail the archived designs already hold to restore working headroom.
- Raised again at 6a0db20 (periodic quality, note 22): `docs/architecture.md` is 88,061 of 88,064 bytes (`tools/docs_lint.sh:44`). Owner: queue item `docs-index`.

## The map's bullets lag Messages, Options, the plugin API, and two tools

- Where: `docs/codebase-map.md` line 119 (Messages without E444 and `unsaved_buffer`), line 94 (Options without `range_problem`, `slot_size`, and the three layout sizes), line 513 (VERSION 2.3, the code 2.4), line 44 (the check entry without `runner_finish`), and line 579 (AnsiTerminal named the only environment reader, while `DiskFiles#home` reads HOME), at b76b722. Periodic quality. Queue item `docs-index`. Raised again at ce6abdb (periodic quality): line 94 also omits `guide_code`, `guide_char?`, and the indentguides members.
- Why it matters: the map is the start of every change and states facts the code contradicts.
- Fix outline: add the names, say 2.4 or name the constant without a number, and say the terminal driver's only environment reads.

## The .PHONY list leaves out metrics

- Where: `Makefile` line 432, at b76b722. Periodic quality. Queue item `run-budgets-tidy`. Raised again at ce6abdb, `metrics-compare` missing too (periodic quality). Raised again at be4b63a (owner `check-skip`).
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
- Also listed in "Plugin, grammar, and generator findings at df4654c" (periodic quality): `carat/use_cases/plugins/plugin_events.rb` line 142 (a resize event built with no subscriber); fix: return unless `wanted?("resize")`.

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

- Where: `carat/domain/selection_cut.rb` line 25 and `carat/use_cases/visual/` `yank_selection.rb` line 32, `shift_selection.rb` line 17, `change_selection.rb` line 44, `put_over_selection.rb` line 39, `insert_at_selection.rb` line 40 at 9a92265. Periodic quality. Queue item: backlog items, copies.
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

- Where: keymap lines in `carat/domain/config.rb` line 213 at 847851d. Periodic security Low (4). Queue item `project-config-guards`. Raised again at bff9a02 (#96): project `.caratrc` binds keys to writing actions, periodic security Low (5) at `carat/domain/config.rb:211`.
- Why it matters: a cloned project can turn an everyday keystroke into `quit.write_all` or `file.save`.
- Fix outline: refuse project keymap lines whose action writes or quits, or read project bindings only under `language.trusted_roots`, with a `file:line` problem row.

## Creating a file follows a link that appears after the probe

- Where: `carat/use_cases/files/make_path.rb` line 47 at 847851d: an existence probe, then `FilePort#write`. Periodic security Low (3). Queue item `file-access-tidy`.
- Why it matters: a file or link appearing between the probe and the write is truncated or followed.
- Fix outline: a create that fails on an existing path or link, used here, with a case.

## A restarted server is never asked again for the same text's symbols

- Where: `forget_server` (the symbol ask, `forget_symbols` before periodic-blockers-a; line 526 at d73f03f) in `carat/adapters/json_rpc_language_gateway.rb`; quality advisory of `breadcrumbs`.
- Why it matters: it clears the request in flight but keeps `asked_buffer` and `asked_changes`, so after a crash and restart the winbar shows no symbols until an edit or a buffer switch.
- Fix outline: reset the asked text (`asked_changes = -1`) in `forget_server`, with an `editor_breadcrumbs` row for a restart.

## FramePresenter's class comment breaks its wrap width

- Where: the class comment of `carat/adapters/frame_presenter.rb` line 40 at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: the edit left a three-word line mid-sentence, which reads as a broken paragraph.
- Fix outline: rewrap the paragraph.

## The map misses SymbolRequest methods and the breadcrumbs test

- Where: `docs/codebase-map.md` line 591 and the render and language areas' Tests lines at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: the entry omits `count` and `name_at`, and the Tests lines do not name `test/editor_breadcrumbs.rb` though it covers `winbar.rb`, `symbol_outline.rb`, and `symbol_request.rb`.
- Fix outline: add the two methods to the entry and the test to both areas' Tests lines.

## Layout's split and attach copy the inner-split block

- Where: `carat/domain/layout.rb` lines 153 to 168 (`split`) and 351 to 368 (`attach`), at 7711421. Periodic quality. Queue item `top-rows`.
- Why it matters: allocating the split, copying size and rectangle, replacing the target, and reparenting are written twice.
- Fix outline: one private helper returning the inner id, called by both.

## Quit walks the leaves to count file windows

- Where: `beside_side_windows?` in `carat/use_cases/files/quit.rb` line 66, at 7711421. Periodic quality. Queue item `top-rows`.
- Why it matters: it repeats `TabPage#file_window_count`.
- Fix outline: call `file_window_count`.

## TabPage#previous? reads the node array directly

- Where: `carat/domain/tab_page.rb` line 103, at 7711421. Periodic quality. Queue item `top-rows`.
- Why it matters: every other walker uses `layout.node_count`.
- Fix outline: use `node_count`.

## The docs deny or omit the winbar

- Where: `docs/compatibility.md` line 441 (Bars says no winbar, against Breadcrumbs at line 518); `docs/architecture.md` line 257 (the FramePresenter bullet omits the winbar row and its painter), at 7711421. Periodic quality. Queue items `docs-index` and `architecture-drift`.
- Why it matters: two documents contradict the delivered feature.
- Fix outline: drop the denial or point to Breadcrumbs; name the winbar and `Winbar` in the bullet.

## The map omits Layout and search methods other files call

- Where: `docs/codebase-map.md` line 349 (Layout without `leaf_showing`, `leaf_number`, `leaf_count`, `node`, `node_count`, `window_at`), line 189 (VimPattern without `compile_substitute`), line 194 (LastSearch without `any?`, `end_preview`), line 195 (SearchPrompt without `close`, `prefix`), at 7711421. Periodic quality. Queue item `docs-index`. Raised again at ce6abdb (periodic quality): `Layout#leaf_number`, `leaf_count`, and `window_at` are still missing.
- Why it matters: callers look up a method the map does not name.
- Fix outline: name them on those lines.

## ExTable keeps unread positions and an uncalled count

- Where: `carat/use_cases/ex/ex_table.rb` lines 16 and 56 (`@index` positions never read), 98 (`count`, no caller), 104 (`handler_at`, public only for `find`), at 7711421. Periodic quality. Queue item 41.
- Why it matters: dead API, and the comment reads the index as a lookup though it only refuses duplicates.
- Fix outline: delete `count`, make `handler_at` private, keep a set of taken names, and say so in the comment.

## Motions repeats its row clamp and paragraph walk

- Where: `carat/domain/motions.rb` line 246 (`line_down` repeats `vertical`'s checks at lines 215 to 222, `to_row` clamps again), lines 540 and 562 (`paragraph_forward` and `paragraph_backward` share one loop), at 7711421. Periodic quality. Queue item `editing-counts`. Raised again at ce6abdb (`motions.rb:228`, `line_down`, and 544, the paragraph loops; periodic quality): a `step_row` helper.
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

## Seven more methods are public with no outside caller

- Where: `Operators.ascii_recase` and `indent_width` (`carat/domain/operators.rb` lines 239 and 271), `Registers#unnamed?` (`carat/domain/registers.rb` line 65), `Buffer#layer_at` (`carat/domain/buffer.rb` line 232), `UndoTree#transaction_at`, `parent_of`, `head_of` (`carat/domain/undo_tree.rb` lines 99, 105, 111), at 31919d9. Periodic quality. Queue item: backlog items, needless public methods. Raised again at ce6abdb (periodic quality): `UndoTree#parent_of` and `transaction_at` have no production caller, queue item `editing-counts`.
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

## The planner's backlog text reaches the package unchecked

- Where: the package step of `.claude/workflows/deliver-change.js` copies the planner's backlog text before `make docs-lint` sees it; retrospective of `feedback` (#83). Queue item `phase-shares`.
- Why it matters: one entry named a missing path, failing `docs-lint` and costing the package a separate fix commit.
- Fix outline: check the planner's output for missing paths before the package copies it, with a case in `make tools-test`.

## An image-viewer plugin is under discussion

- Where: none yet; a proposal under discussion with the user, moved out of `docs/queue.md` when the queue reached its budget, and parked, not scheduled, at `queue-handoff`.
- Why it matters: five formats, block characters from its own decoder, kitty and iTerm2 where available, bounded parsing, a size cap, only base64 or cells sent. GNOME Terminal shows neither protocol, so it needs the plugin's own PNG decoder.
- Fix outline: queue it as a T5 item when the user approves, sized from the plugin rows of `docs/metrics.tsv`.

## The palette-pad-crash scenarios drift from their tests

- Where: `openspec/specs/command-palette/spec.md` lines 87 to 92 bind `window.split` while `test/editor_palette.rb` line 141 binds `insert.newline`; `openspec/specs/key-hints/spec.md` line 102 remaps `<leader>xa` while `test/editor_key_hints.rb` line 128 sets a group name for `<leader>xy`, since a project file reads no remap, at 6141633. Quality advisory of `palette-pad-crash`. Queue item `menu-hints`.
- Why it matters: a scenario is meant to describe the setup its test runs; a reader who reproduces the scenario takes a path the test never covers.
- Fix outline: word the palette scenarios after `insert.newline` and the hint scenario after a group name of fifty wide characters whose widest row is 77 of 78 cells, through a proposal.

## cells_of in the palette test returns an array no caller reads whole

- Where: `cells_of` in `test/editor_palette.rb` line 66, at 6141633. Quality advisory of `palette-pad-crash`. Queue item `menu-hints`.
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

## The backlog has no byte budget

- Where: `docs/backlog.md` (301 KB, 471 entries at 5e4c140, up from 151 KB over 20 changes; 424,794 bytes at 9a92265) and `BUDGETS` in `tools/docs_lint.sh`. Periodic quality. Queue item `docs-index`. Duplicates for `backlog-compaction` (#99 notes 12 and 33), by their lines at 9a92265: 3976 repeats 3497, 2753 repeats 215, 3857 repeats 2313, 3851 repeats 2028, and the Makefile's timed compile is entered three times (2292, 3433, 3983).
- Why it matters: no agent can read it whole to find fixed entries or avoid recording a finding twice.
- Fix outline: give it a budget in `BUDGETS` and fold its entries per area, removing those no longer true.

## The map names EditorState's show twice and lacks Tree readers

- Where: `docs/codebase-map.md` line 117 (a second `show` before `list_message?`) and line 558 (area 16's Tree line without `expanded?`, `root`, `marked`, `count`, `node`), at 5e4c140. Periodic quality. Queue item `docs-index`.
- Why it matters: the map is where every agent starts.
- Fix outline: drop the second `show`; name the readers or say the list is the operations only.
- Raised again as "The map lists EditorState#show twice": Where: `docs/codebase-map.md` line 117 (area 4) at 3895e21. Periodic quality advisory. Queue item `docs-index`. Why it matters: the method list is checked by `test/lint.rb`, and a doubled name hides a missing one. Fix outline: drop the second `show`.

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

## Comments name only the cursor-line layer

- Where: the `SgrTable` class comment in `carat/adapters/sgr_table.rb` line 8, `Frame`'s comment in `carat/domain/frame.rb` line 13, and `docs/architecture.md` line 260, at the `quick-docs-styles` change. Quality advisory in `quick-docs-styles`.
- Why it matters: cells and sequences now also carry `Highlight::FLOAT_LAYER`, so the comments mislead a reader adding a layer.
- Fix outline: mention the float layer in all three.

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

## The message history name and a doubled clear

- Where: `carat/domain/editor_state.rb` line 20 and `carat/domain/notices.rb` line 76 (`history` holds a `MessageHistory`), `carat/use_cases/handle_key.rb` line 201 (`clear_message` twice per key), at df4654c. Periodic quality. Queue item `messages-tidy`.
- Why it matters: `state.history` reads as the command history; the clear runs twice on every key.
- Fix outline: rename to `message_history`; read the flag, clear once.

## Plugin, grammar, and generator findings at df4654c

- Where: `carat/use_cases/plugins/plugin_router.rb` line 44 (the register string passed uncopied), `carat/domain/manifest_check.rb` line 32 (shapes checked twice, a dead guard at line 145), `carat/use_cases/plugins/plugin_registry.rb` line 175 (`leave` repeats `cause`), `carat/plugins/hello/plugin.rb` line 11 (stale comment, the action spelled beside `GREET`), `carat/plugins/registry.rb` line 2 and the `default_config.rb` header (generator names `spin run`), `test/lint.rb` line 845 (plugins exempt from keyword constructors, unstated in CLAUDE.md), comment wraps at `carat/plugin_api.rb` line 480 and 732, `window_requests.rb` lines 28 and 67, `ui_requests.rb` line 15, `carat/domain/plugin_ui.rb` line 7; `carat/domain/command_grammar.rb` line 138 (`accept` and `accept_visual` repeat a prefix), `carat/adapters/input_controller.rb` line 137 (`next_timeout` ignores `state`). Periodic quality advisories. Queue item 39 (backlog items by domain). Raised again at ce6abdb (periodic quality): `accept_visual` (`command_grammar.rb:163`), queue item `editing-counts`: one shared grammar opening.
- Why it matters: the router breaks the strings-copied plugin rule; the rest are copies, dead code, and drift.
- Fix outline: `command.register.dup`; one shapes result; pop then set from `cause`; reword and key by `GREET`; generator writes `make gen-config`; state the exemption or give `Tree` keywords; rewrap; one shared grammar step; drop the parameter.

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

- Where: `digit` in `carat/domain/command_grammar.rb` line 103 and `take` line 191; `Operators.put` in `carat/domain/operators.rb` line 44; the two `MAX_COUNT` copies in `RegisterCount` and `SubstituteArgs`; at 3895e21. Periodic quality blocking. Queue item `editing-counts`. Raised again at 9a92265 (#99 note 35), which adds `carat/use_cases/visual/put_over_selection.rb` line 124.
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

## Carat::Testing takes a positional constructor with no stated exemption

- Where: `Testing#initialize(name)` in `carat/testing.rb` line 13; `test/lint.rb` line 1000 applies the keyword rule only to layer files, at 3895e21. Periodic quality. Queue item `docs-index`.
- Why it matters: CLAUDE.md names `Carat::Testing` among the classes whose constructors take required keywords, so files outside a layer, plugins included, escape the rule unstated.
- Fix outline: state the exemption beside the keyword rule in CLAUDE.md, or move to `initialize(name:)` across the tests.

## metrics.sh ignores a failed field read

- Where: `tools/metrics.sh` lines 55 and 57 at 3895e21 (`set --` from `analysis_budget.sh --fields`). Periodic quality advisory. Queue item `run-budgets-tidy`.
- Why it matters: a failure stops on `set -u` with an unclear message and leaves the temporary output file.
- Fix outline: read the fields into a variable with `|| die`, check both, and remove the temporary file on failure.

## The outside-the-root refusal is built four times

- Where: `carat/use_cases/files/resolve_inside.rb` line 41, `delete_path.rb` line 39, `make_path.rb` line 37, and `rename_path.rb` line 42, at 3895e21. Periodic quality. Queue item `file-access-tidy`. Raised again at ce6abdb (periodic quality): lint's repeated-message rule sees only E-numbered messages, so the four drift unseen.
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

- Where: `carat/use_cases/completion/complete_word.rb` line 47 at eb0b1ae (head, word start, prefix, column) against `ShowCompletion#refresh` in `carat/use_cases/completion/show_completion.rb` lines 74 to 77. Quality advisory in `word-completion`. Raised again at ce6abdb (`show_completion.rb:74`, `complete_word.rb:47`; periodic quality): one domain prefix helper for both.
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

## Definition target paths keep decoded control bytes

- Where: `carat/adapters/json_rpc_language_gateway.rb` line 789 at fafe59c, `path_of`, which refuses a raw or escaped NUL but keeps a decoded `%0A` or `%1B`. Security Low (5) and quality advisory in `definitions`. Owned by queue item 13, `bidi-controls`. Raised again at bff9a02 (#96): decoded C0 and C1 bytes, periodic security Low (4) at `carat/adapters/json_rpc_language_gateway.rb:789`; queue item `bidi-controls`.
- Why it matters: a hostile language server can put a newline or ESC into a target path, which reaches the read-only and E484 message text (split into extra message lines by `TextLines.split`), the buffer path shown in the tab label and the status line (an outside target now opens as a read-only file buffer since `gd-ghost-tab`), the float title, and a pick-list buffer line that then holds a newline, breaking the one-line invariant. `Frame#put_from` replaces every control with U+FFFD, so no escape sequence reaches the terminal.
- Fix outline: in `path_of`, return "" when a decoded byte is below 0x20 or is 0x7F, as a NUL is refused (or pass the path through `Domain::ControlText.strip` before it is stored), with rows in the escapes test of `test/adapters_definitions.rb` for a URI holding `%0A` and `%1B`.

## File URI decoding is hand-rolled inside the language gateway

- Where: `carat/adapters/json_rpc_language_gateway.rb` lines 789 to 850 at fafe59c, `path_of`, `escaped`, and `hex_value`, far from `uri_of`; `test/adapters_definitions.rb` line 338 covers only `%2E` and `%00`. Quality advisories in `definitions`.
- Why it matters: about twenty lines validate UTF-8 by hand (lead size, continuation bytes, overlongs, surrogates, range, `pack("U")`) in an adapter of over 1200 lines, and that multibyte branch has no test, so a regression in it would pass the suite.
- Fix outline: move the decoding into a domain value (a `FileUri` with `path_of` beside the encoding of `uri_of`) tested in a domain test; decode each escape to its byte and refuse unless `out.valid_encoding?`, as `OpenFile` already relies on; add rows for a `%C3%A9` path that opens and an overlong `%C0%AE` and a surrogate `%ED%A0%80` that are skipped.

## The definition ask copies the hover ask in the gateway

- Where: `send_definition` (line 690) and `send_hover` (line 837) in `carat/adapters/json_rpc_language_gateway.rb` at d73f03f, which still differ only by their record, its offer predicate, and the method name; `Domain::DefinitionRequest` repeats `HoverRequest`'s anchor, serial, deadline, and languages fields. The cancel, forget, position-params, and running-server steps are shared since `periodic-blockers-a`. Quality advisories in `definitions` and `periodic-blockers-a`.
- Why it matters: a fix to the replace-or-overdue check or the field writes of one send (such as the stale-answer defect queued in `hover-tidy`) has to be made in both. One private helper over both records is not possible as they stand: Spinel types a parameter once for the whole program (`docs/spinel-notes.md`, Signatures and inference), so a record parameter taking both would be `untyped` and widen every call on it.
- Fix outline: a shared anchored-ask record in the domain that `HoverRequest` and `DefinitionRequest` both hold, so one private send in the gateway takes that record and the method name, with the hover and definition request rows unchanged.

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

- Where: `tools/run_state.sh backup` and the contributor's start. Retrospective of `definitions`, queued in `backup-records`. Raised again at bff9a02 (#96): the backup failed on every try; queue item `backup-records`.
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

## Search copies its prompt split and its E486 message

- Where: `carat/use_cases/search/find_match.rb` line 68 against `preview_search.rb` line 106 (the `pattern_end` split on bytes 47 or 63), and line 163 against `substitute_lines.rb` line 143 (the E486 literal). Periodic quality at 8d8832f, queued in `editing-counts`. Raised again at ce6abdb (`find_match.rb:68`, code points 47 and 63; periodic quality).
- Why it matters: a fix to one split or message misses its copy.
- Fix outline: one domain helper for each, used by both callers.

## Domain motion and text-object structure

- Where: `carat/domain/walker.rb` line 63 calls `Motions.code_class` while `motions.rb` requires `walker.rb` (a cycle held by load order), and line 11's comment omits the bracket objects; `carat/domain/text_objects.rb` line 252 builds a Walker with no require, line 86 and `carat/domain/runs.rb` name a local `cls`; `carat/domain/motions.rb` line 197 and 228 repeat an edge refusal and row clamp, line 579 a dead store; `carat/use_cases/delete_lines.rb` line 28 copies `Operate#delete`'s linewise placement (`operate.rb` line 142, also `global_command.rb` line 150); `carat/domain/operators.rb` lines 172 and 251 copy the effective shift width rule. Periodic quality at 8d8832f, queued in item 37. Raised again at ce6abdb (`walker.rb:63` and `text_objects.rb:252`, the require cycle; periodic quality), queue item `editing-counts`: move `code_class` into a module the four files require.
- Why it matters: the cycle breaks under a changed require order, and each copied rule drifts.
- Fix outline: move the character classes into one module both require; rename `cls` to `char_class`; one row-clamp helper; an `Options#shift_width` beside `tab_width`.

## Plugin host requests answer shared strings and stale comments

- Where: `carat/use_cases/plugins/ui_requests.rb` line 78 (`icon` answers the shared glyph) and 107 (`run_ex` answers the message uncopied); `window_requests.rb` line 90 (`open_scratch` keeps the plugin's title string); unused requires in `carat/adapters/status_bar.rb` line 1 and `plugin_syntax.rb` line 1, `plugin_events.rb` line 6 requires `buffer_feed` for `BufferNotice`; stale comments at `carat/adapters/sgr_table.rb` line 8, `plugin_syntax.rb` line 69, `ui_requests.rb` line 81; `plugin_registry.rb` line 175 repeats `cause`; `plugin_events.rb` line 142 queues a resize no plugin wants. Periodic quality at 8d8832f, queued in item 37.
- Why it matters: CLAUDE.md copies strings both ways at the plugin API, so a plugin appending to an answer changes the editor's icons or a buffer title.
- Fix outline: copy each answered and stored string, with rows; fix the requires and comments; return early when no plugin wants the event.

## Signature help compares bare key codes

- Where: `carat/use_cases/handle_key.rb` line 364, the literals 40 and 44 for `(` and `,`. Periodic quality at 8d8832f, queued in `signature-tidy`. Raised again at ce6abdb (line 379; periodic quality): a private constant beside `MAX_REPLAYS`, membership tested there.
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

- Where: `carat/adapters/status_bar.rb` line 1 requires `../plugin_api` and names none of it; `carat/adapters/frame_presenter.rb` line 299 `display_col` and `display_width` are public but used only inside; `NO_NAME` is defined in `status_bar.rb` line 47, `tab_bar.rb` line 23, and `winbar.rb` line 214. Periodic quality at 186ddfb, queued in `bars-tidy`, the `NO_NAME` triplicate in `top-rows` (the notice border folded into `float-frame`, which drew both boxes through one painter).
- Why it matters: a dead require, a wide public surface, and three constants to keep in step.
- Fix outline: drop the require; move `display_width` below `private` and drop `display_col` (update the area 13 entry); one `[No Name]` on `Domain::Buffer`.

## Docs and spec drift found by the periodic review at 186ddfb

- Where: `openspec/specs/leader-keys/spec.md` line 43 and its scenario at line 49 still say `<leader>ff` shows "Not implemented: file.find"; `docs/codebase-map.md` line 527 (PluginHost omits `follow_prompt`), 617 and 582 (the gateway entry and the area 17 Flow omit the definition request), 465 (DisplayWidth lists the dead `of_char`, omits `code_cells`), 466 (DecodedLine omits `size`), 502 (Keywords omits `value?`), 565 (Tree omits `root`, `marked`, `expanded?`, `count`, `node`). Periodic quality at 186ddfb, queued in `docs-index`.
- Why it matters: a source-of-truth spec contradicts the code, and the map is where a change starts.
- Fix outline: a MODIFIED delta of `leader-keys` saying `<leader>ff` opens the finder, and the names added or dropped.

## Copies and placement found by the periodic review at 186ddfb

- Where: `ListTree#probe` (`carat/use_cases/files/list_tree.rb` line 65) repeats `ProbePath#call` and asks the port itself, against `docs/architecture.md` section 5, queued in `periodic-blockers-b`; `CompleteWord` (`carat/use_cases/completion/complete_word.rb` line 47) copies the word-before-cursor slice of `show_completion.rb` lines 74 to 77, queued in `completion-tidy`; `Layout#fixed_width?` (`carat/domain/layout.rb` line 299) is used only by its test, queued in `slots-tidy`; `JumpList#step` (`carat/domain/jump_list.rb` line 55) pushes before the range check, so Ctrl-O on an empty list adds an entry, queued in `definitions-tidy`; `Icons::NAMES` (`carat/domain/icons.rb` line 13) is read nowhere and `DecodedLine` and `Cell` (`decoded_line.rb` line 15, `cell.rb` line 274) are never-changed values declared as `Struct`, queued in `carat-palette`. Periodic quality at 186ddfb. Raised again at ce6abdb (periodic quality): `ListTree#probe` (`list_tree.rb:67`) as a blocker; the `CompleteWord` copy (`complete_word.rb:47`) and `Layout#fixed_width?` (`layout.rb:299`).
- Why it matters: two probes and two slices drift; dead surface; a jump that answers nothing moved after adding an entry; records against the Data rule.
- Fix outline: inject the one `probe_path:` into `ListTree` and use `Domain::PathPolicy.inside?`; one domain prefix helper; delete `fixed_width?`; return -1 before the push with a `test/domain_jump_list.rb` row; test `NAMES` against each set or drop it; `Data` subclasses or the Spinel reason in the comment.

## Small findings of the periodic review at 186ddfb

- Where: dead code `TabRequest#counted?` (`carat/use_cases/windows/tab_request.rb` line 13), `UndoTree#undo_seq` and `#redo_seq` (`carat/domain/undo_tree.rb` lines 173 and 179, with the stale comment at 185), the dead store `row = top` (`carat/domain/motions.rb` line 579), `DisplayWidth.of_char` (`display_width.rb` line 133), `DecodedLine#cells` (line 91), `Cell#same?` (line 286); `Config#binding?`'s comment (`carat/domain/config.rb` line 205) omits the leader lines and lines of other word counts it keeps; the finder's `open_path` and `report` (`carat/plugins/finder/plugin.rb` line 314) copy the explorer's (lines 277 and 534); the finder matcher's helpers (`matcher.rb` line 55) are public and `lower(b)` takes a one-letter name; `PluginRouter#answer` (line 77) hands the plugin `prompt_id` uncopied; the explorer's `@followed` (`carat/plugins/explorer/plugin.rb` line 420) stays on the old path after its parent directory is renamed; `Frame::REPLACEMENT` (`frame.rb` line 36) repeats `Utf8::REPLACEMENT`. Periodic quality at 186ddfb, queued in the backlog batches. Raised again at ce6abdb (periodic quality): the `UndoTree` readers and the stale comment at 185, queue item `editing-counts`.
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

## The blocking quality finding of the periodic review at 2f54bb5 is unmarked

- Where: the periodic quality review at 2f54bb5 reported 1 blocking and 48 advisory findings (17 of 18 areas covered), but the run state of `implement-contracts-c` keeps its 38 findings as `note.12` to `note.49` without saying which one blocked. Queued in `periodic-blockers-b`.
- Why it matters: a blocking finding has to be fixed in its own change; while it is unmarked, the change cannot show it was fixed.
- Fix outline: find the blocking finding in the review's result, fix it with a test row, and remove its entry; if the result cannot be found, take it from the next periodic review.

## The contributor may rewrite the agent files later starts load

- Where: `tools/agent_guard.sh` line 330 at 2f54bb5: the contributor's guard allows writes under `.claude/agents`, `.claude/workflows`, and `.claude/settings.json`, which later starts load from the branch's working tree. Periodic security at 2f54bb5, Medium (4). Queued in `guard-lows`.
- Why it matters: a misled contributor could drop a later agent's guard hook for the rest of the run.
- Fix outline: refuse contributor writes there unless the plan names the file, or load agent hooks from main, with a refusal case in `tools/tools_test.sh`.

## Tooling copies and help gaps found by the periodic review at 2f54bb5

- Where: the timed development compile recipe copied in `dev-build`, `test-build`, and `bench-budget` (`Makefile` lines 221, 255, 312); the `make help` variables line omits `ALLOC_BUDGET`, `SCENARIOS`, `ANALYSIS_ROOTS`, `ANALYSIS_ROUNDS`, `ANALYSIS_MS`, `BASE_METRICS`, `S`, and the generator variables (line 430); the `usage` function in `tools/run_state.sh` (line 1460) shares its name with the `usage` command, and `push` (line 1555) has no argument-count check; `docs/codebase-map.md` line 48 leaves `sort_form` and `uniq_form` out of the guard's form list. Periodic quality at 2f54bb5. Queued in `run-budgets-tidy` and `docs-index`.
- Why it matters: three copies drift, and `make help` and the map fail to name what CLAUDE.md says they name.
- Fix outline: one `define` macro for the recipe; every variable a target reads in the help line; rename the function `print_usage` and refuse a second `push` argument; name both forms in the map.

## The docs still name spin test as the snapshot judge

- Where: the harness comment in `carat/testing.rb` line 4 and `docs/architecture.md` lines 396 and 421 at 2f54bb5. Periodic quality at 2f54bb5. Queued in `docs-index`.
- Why it matters: the hard rules forbid running `spin test`; `tools/run_tests.sh` compares the snapshots, so the docs point at the wrong tool.
- Fix outline: name `tools/run_tests.sh` and `make test` in the three places.

## Test helpers return tuples and misname table rows

- Where: `windows` in `carat/doubles/editor_harness.rb` line 189 returns seven-field arrays that 13 test call sites index by position (`test/editor_cmdline.rb` line 194, `test/editor_leader.rb` line 57); the table blocks of `test/plugins_finder_matcher.rb` lines 39 and 51 name their parameter `row` though `Testing#table` yields its input. Periodic quality at 2f54bb5. Queued in the bench and test hygiene batch.
- Why it matters: positional indexes break the rule that a helper returning several values returns an object with typed readers, and the wrong name misleads the reader.
- Fix outline: a small `Data` value with named readers read by name in the tests; rename the parameter `input`.

## The action registration loop is copied five times

- Where: the `NAMES` and `DESCRIPTIONS` registration loop in `carat/use_cases/actions/motion_handler.rb` line 32 (twice), `search_handler.rb` (twice), and `text_object_handler.rb` (once), at 2f54bb5; `"Not implemented: "` is spelled in `dispatcher.rb` line 61, `find_match.rb` line 53, `selection_handler.rb` line 48, and `vim_pattern.rb` lines 274 and 460. Periodic quality at 2f54bb5. Queued in the backlog batches and `messages-tidy`. Raised again at be4b63a (now thirteen loops).
- Why it matters: a change to registration or to the refusal wording reaches one copy and misses the others, which the E-number lint cannot see.
- Fix outline: one `ActionTable` method registering a names list with its descriptions; one `Domain::Messages` function for the refusal prefix called from the four files.
- Raised again as "Action registration loops are copied five times": Where: `carat/use_cases/actions/motion_handler.rb:34` and `:41`, `text_object_handler.rb:35`, `search_handler.rb:35` and `:42`. Periodic quality. Raised again at be4b63a (now thirteen loops). Why it matters: five copies of one loop. Fix outline: one `ActionTable` method registering names and descriptions. Backlog batches (editing and keymap copies).

## listed_for recomputes the target's absolute path per buffer

- Where: `listed_for` in `carat/use_cases/definitions/visit_target.rb` line 142 at 75fa4fd, which calls `absolute(path)`, a join and a normalize, on every iteration of its loop over the listed buffers. Quality advisory in `periodic-blockers-a`.
- Why it matters: the target path does not change inside the loop, so each listed buffer costs one more join and normalize, and the allocations grow with the buffer list on every `gd` and peek.
- Fix outline: compute the target's absolute path once before the loop and compare each buffer's path against it.

## The completion send slices the cursor-prefix line twice

- Where: `complete` in `carat/adapters/json_rpc_language_gateway.rb` line 583 at 75fa4fd, which already holds the line up to the cursor, while `position_params` slices the line again. Quality advisory in `periodic-blockers-a`. Raised again at ce6abdb (lines 576 and 1024; periodic quality), queue item `lsp-client-tidy`.
- Why it matters: one more string is allocated per completion send, on the typing path.
- Fix outline: let `position_params` take the prefix line (or the column computed from it) when the caller has it, or accept the one string and drop this entry.

## cancel_request's comment names the running server

- Where: the comment of `cancel_request` in `carat/adapters/json_rpc_language_gateway.rb` line 1003 at 75fa4fd, which says the running server though the method looks up `server_for`, now beside `running_server`. Quality advisory in `periodic-blockers-a`. Raised again at ce6abdb (periodic quality), queue item `lsp-client-tidy`.
- Why it matters: the comment points the reader at `running_server`, the other lookup, so a later change could pick the wrong one.
- Fix outline: say the language's server in the comment.
- Raised again as "cancel_request's comment names the running server but asks any": Where: `carat/adapters/json_rpc_language_gateway.rb:1006`. Why it matters: the comment and the lookup (`server_for` beside `running_server`) disagree. Fix outline: call `running_server` or reword the comment. Queue item `lsp-client-tidy`.

## IndentGuides keeps a magic stamp shift, a doubled guard, and a misleading helper name

- Where, at 6cb3c55: `carat/adapters/indent_guides.rb` line 62 (the settings stamp shifts by the unnamed 16_384 and folds in `@tabstop`, which `build_key` already puts in the geometry key), line 106 (`paint` checks `@code == 0` and `i >= @rows` although its only caller, `carat/adapters/frame_presenter.rb` line 785, passes -1 unless the row is guided and inside the buffer), line 132 (private `indent_of(line)` returns a display width while `Buffer#indent_of(row)` returns the whitespace string); `test/adapters_indent_guides.rb` line 150 (the glyph case `default` sets `indentguides = true`, which `state_for` already does). Quality advisories in `indent-guides`.
- Why it matters: the unnamed shift and the doubled tabstop make the stamp harder to check against `INDENT_CAP` and `SCOPE_SHIFT`; two guards for one condition can drift apart; one method name with two meanings misleads a reader of either file; the dead branch suggests the default case differs from the others.
- Fix outline: name the shift as a constant beside `INDENT_CAP` and `SCOPE_SHIFT` and drop `@tabstop` from the stamp; keep one guard, either dropping it from `paint` or setting `@guide_row` to the row whenever it is guided; rename the helper `indent_width`; drop the assignment and leave `default` with no branch.

## The indent-guides docs claim an untested start screen and reword untouched sentences

- Where, at 6cb3c55: the Windows row of `docs/compatibility.md` line 537, which credits `adapters_indent_guides` with the start screen showing no guide though no case draws the start screen; `docs/architecture.md` lines 113 and 257, which reword sentences the change does not touch (the Nerd Font glyph clause, reading the state, the two preallocated frames). Quality advisories in `indent-guides`.
- Why it matters: a compatibility row naming a test that does not prove it hides a gap, and rewording unrelated sentences widens a change's scope and its review.
- Fix outline: add a start-screen case to the guides table or drop the start screen from the row's claim; restore the untouched wording and keep only the additions that name `indentguides`, `IndentGuides`, and the guides in the row record.

## A security review stays current after later instruction-file commits

- Where: `tools/gates.sh:112` (`settled_at`). Periodic security Low (3) at ce6abdb; queue item `content-gate-gaps`. Raised again at 9a92265 (#99): the path list of `tools/gates.sh` line 112 is copied as `TEST_ONLY` in `tools/run_state.sh` line 201, so a fix must change both.
- Why it matters: commits after the review that change `openspec/`, `docs/queue.md`, `docs/backlog.md`, or `docs/goals.md` keep the review current, though agents read those paths as instructions, so text added there reaches later agents unreviewed.
- Fix outline: narrow the exemption to the archive move, the specs synced from the reviewed change, and `docs/metrics.tsv`, or have the reviewer re-read those paths; a `tools/tools_test.sh` case.

## The finder's open with no file window replaces the explorer's tree

- Where: `carat/plugins/finder/plugin.rb:319` against `carat/plugins/explorer/plugin.rb:284`. Periodic quality at ce6abdb; queue item `finder-grep`.
- Why it matters: `open_path` passes `editing_window` 0, which resolves to the current window, so with only the tree shown the file replaces the tree's scratch buffer; the open-by-how dispatch is copied in both plugins and untested.
- Fix outline: handle target 0 as the explorer does, with a `test/editor_finder.rb` row; consider one shared plugin API helper.

## Two shipped options are accepted and dropped, and Config settings are untyped

- Where: `carat/domain/options.rb:78` (`option.wrap`, `option.clipboard`, set at `config/default.caratrc` lines 23 and 26); `carat/domain/config.rb:27`. Periodic quality at ce6abdb; queue item `project-config-guards`, the type in the batches.
- Why it matters: a user's value for either option is dropped with no note; `settings` is `Array[untyped]` though it holds only `RcLine` values.
- Fix outline: note both as not implemented in `apply` or drop them from `KINDS` and the shipped file, with a `test/domain_options_config.rb` row; type `settings` as `Array[RcLine]` or state the compiler's reason.

## The linewise change and its cursor are written in four places

- Where: `carat/use_cases/visual/change_selection.rb:40`, `delete_lines.rb:24`, `selection_cut.rb:22`, and `carat/use_cases/operate.rb:143` and 157. Periodic quality at ce6abdb, the part of its editing-copies finding no other entry names; queue item `editing-counts`.
- Why it matters: one rule spelled in four places drifts.
- Fix outline: `Operators` helpers for the linewise change and its cursor, called by all four.

## CloseOtherWindows reaches the tabs through the buffer list

- Where: `carat/use_cases/windows/close_other_windows.rb:62` (`@buffers.tabs`). Periodic quality at ce6abdb, the part of its window-copies finding no other entry names; queue item `slots-tidy`.
- Why it matters: a second path to the one tab list escapes `test/adapters_assembly.rb`.
- Fix outline: inject `tabs:` and assert it in `test/adapters_assembly.rb`.

## Map entries miss names of indent-guides and older changes

- Where: `docs/codebase-map.md:325` (Selection: `numbered_delete?`, `as`, `line_start`), 144, 148, and 196 (Keymap, CommandGrammar, LastSearch), 299 (UndoTree), and area 11 (`FloatSpec#cursor_anchored?`, `FloatWindow#id`). Periodic quality at ce6abdb; the Options and Layout gaps are folded into their map entries; queue item `docs-index`.
- Why it matters: the map is kept current and agents plan from it.
- Fix outline: add each name to its line.

## The benchmark's plugins column holds an option toggle

- Where: `bench/keys.rb:255` (`noguides` in the plugins column). Periodic quality at ce6abdb; queue item: the backlog batches.
- Why it matters: the plugins column mixes an option toggle with plugin sets, so a reader of the results misreads it.
- Fix outline: a setup or options column.

## The view reserves its top rows twice

- Where: `carat/use_cases/arrange_view.rb:46` and 63 (`reserve_headers`, `reserve_winbars`). Periodic quality at ce6abdb; queue item `bars-tidy`.
- Why it matters: one give-the-first-row step written twice.
- Fix outline: one `Window` method both call.

## Backlog entries are duplicated

- Where: `docs/backlog.md:209` and 2742 (the `Options#apply` duplication), 899 and 2111 (copies of `EditorState#clamp_col`). Periodic quality at ce6abdb; queue item `backlog-compaction`.
- Why it matters: one entry per finding; duplicates grow the file every planner and reviewer reads.
- Fix outline: fold each pair into one entry listing every location.

## No test pins the port bases that answer failure values

- Where: `Host#stat` (`carat/plugin_api.rb:622`), `Host#icon` (`carat/plugin_api.rb:630`), and `FilePort#stat` (`carat/ports/file_port.rb:45`), changed by `spinel-bump` from raising to answering a missing or failed value as the f34005bf workaround. Quality advisory at spinel-bump.
- Why it matters: nothing asserts the new base answers, so the workaround is invisible to a reader of the tests and could be reverted, or kept past the fix, by accident.
- Fix outline: add an assertion that a bare base answers missing or failed (or a lint exemption list naming the three methods), removed deliberately in the bump that clears the f34005bf entry.

## The overridden-method RBS form is used for Regexp and MatchData methods

- Where: `carat/domain/search.rb:106` and `carat/domain/replacement.rb:87,152`, which use `# @rbs` parameter lines with the return in prose on methods that override nothing, because `MatchData` cannot be pinned; `CLAUDE.md` (inline RBS) and `docs/spinel-notes.md:39` reserve that form for overrides. Quality advisory at spinel-bump. Raised again at be4b63a.
- Why it matters: the documented rule and the code disagree, so the next reader either "fixes" the signature into one Spinel cannot analyze or copies the form where it is not needed.
- Fix outline: extend `docs/spinel-notes.md` line 22 or 39 to say a method taking or returning `Regexp` or `MatchData` gets parameter lines and its return in prose.

## gen_respond_to_tables.rb repeats work and types its rows loosely

- Where: `tools/spinel/gen_respond_to_tables.rb:95` (three `if`s map array names to arrays inside the family loop), line 101 (a second `uniq` after `family_names` already dedups), and lines 111, 138, and 156 (rows typed `Array[untyped]` where `Array[Row]` holds). Quality advisory at spinel-bump.
- Why it matters: the port is read at every Spinel bump; the repeated lookups and loose types make it harder to compare with upstream and hide a wrong row from the analysis.
- Fix outline: build one name-to-array hash before the loop, drop the second `uniq`, and type the rows `Array[Row]`.

## A blank line splits the Known miscompilations list in the Spinel notes

- Where: `docs/spinel-notes.md:482`, before the two items `spinel-bump` added for f34005bf. Quality advisory at spinel-bump.
- Why it matters: Markdown renders the two new items as a separate list, so they read as apart from the Known miscompilations section.
- Fix outline: remove the blank line.

## Operate dispatches with case on constants the pinned Spinel may fold

- Where: `carat/use_cases/operate.rb` line 65, `case`/`when` on `Domain::OperatorKind::DELETE` and `::INDENT`, String constants whose bare names are Integer constants elsewhere (`Key::DELETE`, `RcParser::DELETE`, `FormatDocs::INDENT`). Periodic quality blocking at e49f63d. Raised again at 9a92265 (#99 note 34).
- Why it matters: `docs/spinel-notes.md` (Known miscompilations, f34005bf) says the pinned Spinel folds this shape to false; it passes only by how the name resolves today, so a rename elsewhere silently breaks delete or indent.
- Fix outline: dispatch with `==` guards as `Mode.visual_kind` does, citing the note, with a row per operator kind. Queue item: `periodic-blockers-b`.

## The left and right window keys ignore the gutter and display columns

- Where: `neighbour` in `carat/domain/layout.rb` line 250 takes the cursor column as `window.col + cursor.col - window.left`. Periodic quality at e49f63d.
- Why it matters: it mixes a code point index with the display-column scroll and leaves out the gutter, so `<C-w>j` and `<C-w>k` beside vertical splits pick the wrong window with numbers, signs, tabs, or wide characters, unlike Neovim.
- Fix outline: pass the gutter width and the cursor's display column into the neighbour search, with a row over a numbered window. Queue item: `slots-tidy`.

## A raise while leaving the screen skips stopping the language servers

- Where: the `ensure` in `bin/carat.rb` line 41 runs `screen_presenter.leave` then `services.stop`. Periodic quality at e49f63d.
- Why it matters: a raise in `leave` leaves server processes running after the editor exits.
- Fix outline: stop the services even when leaving raises, with a case. Queue item: `lsp-client-tidy`.

## Stale places in the Makefile, CLAUDE.md, the rules script, and carat.rb

- Where: `Makefile` line 19 (the `SPINEL_REF` comment sends the header regeneration to the toolchain target, not `spinel-header`); `CLAUDE.md` line 21 and `tools/rules.sh` line 34 (the allowed URL is in the shared Spinel checkout recipe, not the toolchain target); the CLAUDE.md buffer text bullet (`LeaveInsert` opens no transaction, it closes the insert session the dispatcher left open); `carat.rb` line 332 (`carat/adapters/indent_guides.rb` missing from the production require graph). Periodic quality at e49f63d.
- Why it matters: each sends a reader to the wrong place, and the require graph header says every file is pulled in once.
- Fix outline: correct each sentence and add the require. Queue item: `docs-index`.

## The code map is behind the code

- Where: `docs/codebase-map.md` line 584 (area 17 Flow says every port method raises, but `FilePort#stat` answers a value); lines 523 and 532 (`Paths` omits `absolute`, `PluginEntry` omits `attach` and `full_command`). Periodic quality at e49f63d.
- Why it matters: agents start from the map and the architecture.
- Fix outline: update each sentence and list. Queue item: `docs-index`.

## Records and values miss pins or say why not

- Where: `carat/domain/search_pattern.rb` line 10 (the regexp pin dropped with no comment); `carat/domain/find.rb` line 4 and `command.rb`, `ex_command.rb`, `key_notation.rb`, `keymap_match.rb`, `position.rb`, `range.rb` (no member pins); `carat/domain/history.rb` line 23 (`super()` without keywords, uncommented); `carat/domain/transaction.rb` line 297 (`merged?` rewrites the last record, a command named as a predicate). Periodic quality at e49f63d.
- Why it matters: against the inline RBS and naming rules of CLAUDE.md, and a reader cannot tell an omission from a Spinel workaround.
- Fix outline: add the pins or a one-line comment citing `docs/spinel-notes.md`, and rename `merged?` or list it in `BOOL_COMMANDS`. Queue item: Backlog batches.

## Requires out of step with the constants a file names

- Where: `carat/domain/operators.rb` line 6 (requires `selection`, unused; `registers` where it uses `RegisterEntry`); `last_change.rb`, `reselect_visual.rb`, `toggle_slot.rb`, `completion_handler.rb`, `show_completion.rb` (unused requires); `carat/domain/layout.rb`, `window.rb`, `slot.rb`, `tab_page.rb`, `layout_node.rb` (build constants they never require). Periodic quality at e49f63d.
- Why it matters: they compile only by the load order of `carat.rb`.
- Fix outline: require what each file names and drop the rest, `make diagnose` confirming. Queue item: Backlog batches.

## Comments that read as changelogs or break the wrap width

- Where: `carat/domain/range.rb` line 3; `carat/use_cases/handle_key.rb` lines 65 and 71 to 72; `carat/domain/editor_state.rb` lines 13 and 15; `carat/domain/highlight.rb` lines 5 to 13; `carat/use_cases/files/open_file.rb` line 20. Periodic quality at e49f63d. Raised again at be4b63a, also handle_key.rb:71, :315, :379.
- Why it matters: ragged or historical comments mislead a reader.
- Fix outline: describe what the class holds now and rewrap each block to its file's width. Queue item: Backlog batches.

## Copies in editing, substitute, and buffer-list code

- Where: the tabstop-or-8 fallback in `dispatcher.rb` line 111, `repeat_last.rb` line 104, `leave_insert.rb` line 69, `insert_tab.rb` line 22, `arrange_view.rb` line 42 (`Options#tab_width` exists); private `clamp` in `operate.rb` line 202 and `repeat_last.rb` line 116 (`EditorState#clamp_col`); `change_selection.rb` line 41 repeating `Operate#change`; dead `tabstop_of` in `extend_visual.rb` line 53; `remember` in `global_command.rb` line 81 and `substitute_lines.rb` line 113; the group append in `replacement.rb` lines 99 and 127; `digits?` in `history_command_handler.rb` line 65 and `buffer_command_handler.rb` line 98; `beside_side_windows?` in `files/quit.rb` line 66; `list_buffers.rb` line 74 asking `shown?` twice; `any_modified?` and `redo_seq` used only by tests. Periodic quality at e49f63d.
- Why it matters: each copy can drift from its original.
- Fix outline: one owner per behavior, dead code removed. Queue items: `editing-counts` (fallbacks, clamps, change, dead code), `substitute-tidy` (remember, group append), `buffer-list-tidy` (digits, shown, unused methods), `slots-tidy` (quit).

## The explorer tree takes positional arguments under a silent lint exemption

- Where: `Tree#initialize` in `carat/plugins/explorer/tree.rb` line 23; the plugins exemption in `test/lint.rb` line 1185. Periodic quality at e49f63d.
- Why it matters: CLAUDE.md requires keyword constructors and states no plugin exemption.
- Fix outline: keyword arguments at the constructor and its callers, then drop or document the exemption. Queue item: Backlog batches.

## A pin bump has no way to build and bench its base at its own pin

- Where: the benchmark agent's base build and `make toolchain` with `PREFIX`. `spinel-bump` retrospective.
- Why it matters: in #95 the benchmark's documented step failed on main and it built a base toolchain by hand (14 calls, 9,929 tokens), and the contributor rebuilt the old toolchain in a scratch path inside a capped implement start.
- Fix outline: one documented way to build the base at its pin; acceptance: the next pin bump compares base and change with no hand-built toolchain. Queue item: `check-runner-safety`.

## DefinitionRequest's OWNER comment names a view it no longer makes

- Where: `carat/domain/definition_request.rb` line 34, the comment on `OWNER`. Quality advisory in `gd-ghost-tab`.
- Why it matters: it still says the owner holds the read-only views of files outside the project, but since `gd-ghost-tab` an outside target opens as a read-only file buffer, so a reader looks for scratch views that no longer exist.
- Fix outline: say the owner holds the scratch buffers of the peek float and the pick list.

## Two class comments of the definitions change are wrapped unevenly

- Where: `carat/use_cases/definitions/visit_target.rb` line 28 (line 29 stops at 45 columns) and `carat/use_cases/buffers/list_buffers.rb` line 16 (runs to 88 columns against the 72 to 75 of its block). Quality advisory in `gd-ghost-tab`.
- Why it matters: the ragged block reads as an unfinished edit and breaks the file's wrap width, as in the comments entry above.
- Fix outline: rewrap both class comments evenly at the width of their block.

## An edited read-only gd target's unsaved-work errors have no test

- Where: `test/adapters_definitions.rb` line 406, the read-only target rows. Quality advisory in `gd-ghost-tab`.
- Why it matters: since `gd-ghost-tab` an edited read-only buffer counts as unsaved work (E37 on `gd`, Ctrl-O, `:e`, and `:b` away from it, E162 on quit), which the old scratch view never raised, so a regression in that behavior would pass the suite.
- Fix outline: after `x` in the read-only buffer, assert that `:bp` reports E37, `:q` reports E162, and `:e!` clears the modified flag.

## No test covers :wa over a modified read-only buffer and a writable one

- Where: the definitions spec requirement on read-only targets (`openspec/specs/definitions/spec.md`) says `:wa` and `:wqa` still write the other modified buffers, and `test/adapters_definitions.rb` has no row for it. Quality advisory in `gd-ghost-tab`.
- Why it matters: a `:wa` that stops at the first E45 would leave the user's writable edits unsaved without a failing test.
- Fix outline: add a scenario and a row that modifies `a.rb` and the read-only target, runs `:wa`, and asserts `a.rb` is written while E45 is reported for the read-only one.

## Nothing proves the read-only gd target is synced with the language server

- Where: `test/adapters_definitions.rb` line 433. Quality advisory in `gd-ghost-tab`.
- Why it matters: the `gd-ghost-tab` proposal opens the read-only buffer to the server (didOpen) so `gd` follows on from it, but no test asserts the didOpen or a `gd` from inside it, so losing the sync would pass the suite.
- Fix outline: assert the fake server received didOpen for `/gems/c.rb` and that `gd` from that buffer visits a target.

## Key codes matched with case/when beside same-named String and Symbol constants

- Where: `carat/domain/key_notation.rb:143` and `:150`, `carat/adapters/key_decoder.rb:60` and `:61` (`Key::DELETE`, `Key::INSERT`).
- Why it matters: the shape `docs/spinel-notes.md` (Known miscompilations) says the pinned Spinel may fold to false; only the table tests in `test/domain_keys.rb` and `test/adapters_key_decoder.rb` keep it working. Periodic quality, blocking shape.
- Fix outline: rewrite both lookups as `==` guard returns, as `Mode.visual_kind` does. Queue item `periodic-blockers-b`.

## A feed notice builds an event no plugin subscribes to

- Where: `carat/use_cases/plugins/plugin_events.rb:188` (`enqueue`).
- Why it matters: every closed transaction builds an Event, a PendingEvent, and two string copies though no shipped plugin subscribes, against the comment's promise; `ddp` and `dot-ciw` pay it.
- Fix outline: return early unless the event is wanted, keeping the open and close bookkeeping; confirm with `make bench`. Queue item `insert-copy`.

## Ex commands that take no argument ignore one

- Where: `carat/use_cases/ex/tab_command_handler.rb:38` (`:tabn 3`), `file_command_handler.rb:41` and `:45` (`:q x`, `:qa x`), `window_command_handler.rb` (`:close x`, `:only x`), `history_command_handler.rb:44` and `:45` (`:redo x`, `:undolist x`).
- Why it matters: Neovim refuses with E488; `:tabn N` acts though `docs/compatibility.md:446` says it is not implemented.
- Fix outline: one ExHandler helper answering E488 as LspStart does, Not implemented for `:tabn N`, table rows in `use_cases_ex`. Queue item `buffer-list-tidy`.

## The read-only marker shows only on the first gd

- Where: `carat/use_cases/files/open_file.rb:40` and `:62` against `carat/use_cases/definitions/visit_target.rb:98` and `:109`; `docs/compatibility.md:264` and `:317` omit E382 and E45 for `:w`, `:wq`, `:x`, `:wa`.
- Why it matters: `:e` and `:e!` of a read-only buffer drop Vim's `[readonly]`; the write refusals differ from Vim unsaid.
- Fix outline: append the marker in both messages with rows in `adapters_definitions`; add E382 and E45 to the rows and one sentence to the differences. Queue item `definitions-tidy`.

## VisitTarget keeps a dead parameter and a copied read

- Where: `carat/use_cases/definitions/visit_target.rb:93` (`view` never reads `state`) and `:101` against `:116` (probe, refusal, read, and E484 twice).
- Why it matters: dead code and one rule kept in two places.
- Fix outline: drop the parameter; one private helper reading a target within a limit. Queue item `definitions-tidy`.

## The explorer spells its keys twice

- Where: `carat/plugins/explorer/plugin.rb:16` (`HELP`) against `:541` (its keymap).
- Why it matters: a changed key drifts from the help; the tree keymap takes no configuration line, unlike manifest bindings.
- Fix outline: build the help from the keymap lines and record in `docs/plugins.md` whether a scratch keymap takes configuration. Backlog batch: editing and keymap copies.

## Docs drift at #96

- Where: `carat/plugin_api.rb:448` (Host comment says every method raises, stale since `stat` and `icon` answer values); `docs/codebase-map.md:89`, `:93`, `:197` omit `Config#count`, three `RcParser` helpers, and `LastSearch#touch`; CLAUDE.md and `docs/codebase-map.md:649` state the override rule without the `-> void` exception `docs/spinel-notes.md:39` allows.
- Why it matters: readers and agents follow stale rules and an incomplete map.
- Fix outline: correct the comment, add the names, state the exception. Queue item `docs-index`.

## Backlog duplicates found at #96

- Where: `docs/backlog.md:2498`, `:2948`, `:3290` (resize with no subscriber three times, `leave` twice); `:1241` and `:3594` (the group count twice).
- Why it matters: the backlog grows by repetition (397,565 bytes).
- Fix outline: fold each into one entry listing every location. Queue item `backlog-compaction`.

## A comment block runs to 115 columns

- Where: `carat/use_cases/windows/scroll_window.rb:18`.
- Why it matters: the comment-wrap rule of the block (72 to 75).
- Fix outline: rewrap. Backlog batch: comment wraps.

## A styled float row reads its line and decoded tokens twice

- Where: `carat/adapters/frame_presenter.rb` line 639, `paint_float_row`, which calls `buffer.line(row)` and `@cache.fetch` once for `paint_text` and again for `paint_tokens` on a styled row. Quality advisory of `float-frame`.
- Why it matters: duplicated work per row in the presenter's hot path, which the `float-frame` proposal set out to tidy.
- Fix outline: fetch the line and its decoded form once into locals before the branch and reuse them for the tokens; confirm with `make bench`. Queue item `float-placement`.

## The docs float lands under a shifted completion popup

- Where: `carat/use_cases/completion/show_completion_docs.rb:107`. Periodic quality.
- Why it matters: with the cursor near the right edge the docs float is partly hidden beneath the popup.
- Fix outline: clamp the popup box as `place` does before choosing the side, with a right-edge row in `test/editor_completion.rb`. Queue item `completion-docs-tidy`.

## The gd peek and finder preview show code unhighlighted

- Where: `carat/use_cases/definitions/visit_target.rb:132`; `carat/use_cases/syntax/highlight_view.rb:43`; `carat/adapters/frame_presenter.rb:647`. Periodic quality.
- Why it matters: the peek's filetype is set but nothing reads it, so the peek is plain.
- Fix outline: highlight floats' visible rows and paint their tokens, with a row in `test/adapters_definitions.rb`, or drop the assignment. Queue item `definitions-tidy`.

## The language gateway is one 1373-line class

- Where: `carat/adapters/json_rpc_language_gateway.rb:1`. Periodic quality.
- Why it matters: 80 methods and every request kind in one class, which every new request grows.
- Fix outline: one sender and reader per request kind over a small shared collaborator built in `EditorAssembly`. Queue item `lsp-client-tidy`.

## Sentence motions rescan the starts linearly

- Where: `carat/domain/motions.rb:468` and `:500`. Periodic quality. Raised again at be4b63a (owner `editing-counts`).
- Why it matters: they duplicate `SentenceStarts#index_at` and rebuild a Position.
- Fix outline: `next_after` and `last_before` on `SentenceStarts`. Queue item `editing-counts`.

## Vertical motions clamp the row twice

- Where: `carat/domain/motions.rb:197`, `:210`, `:228`. Periodic quality.
- Why it matters: the same edge check and clamp in two methods and again in `to_row`.
- Fix outline: one clamped-row helper. Queue item `editing-counts`.

## text_objects reaches Walker without requiring it

- Where: `carat/domain/text_objects.rb:252` and `:7`. Periodic quality.
- Why it matters: the require rule; it works only through `motions.rb`.
- Fix outline: require walker beside runs. Queue item `editing-counts`.

## The E486 message is built inline

- Where: `carat/use_cases/search/find_match.rb:163`. Periodic quality.
- Why it matters: every other search message is a `Domain::Search` constant.
- Fix outline: a not-found prefix constant. Queue item `search-tidy`.

## Backlog entries name queue items that are gone

- Where: `docs/backlog.md:2273` and 33 others (architecture-drift 8, global-tidy 8, search-structure 8, substitute-structure 5, diagnostics-tidy 4, pipeline-hardening 1); 15 under the archived implement-contracts items (`test/lint.rb:1287`). Periodic quality.
- Why it matters: those findings have no live owner.
- Fix outline: requeue each under a live item or drop the reference, and have `tools/docs_lint.sh` check every named owner is queued. Queue item `backlog-compaction`.

## Three backlog findings are entered twice

- Where: `docs/backlog.md:2255` and `:3702`, `:2580` and `:2742`, `:3468` and `:3690`. Periodic quality.
- Why it matters: one finding per entry.
- Fix outline: fold each pair. Queue item `backlog-compaction`.

## A backlog entry names a loop that is gone

- Where: `docs/backlog.md:55`, naming `carat/use_cases/move.rb`. Periodic quality.
- Why it matters: the file has no loop now.
- Fix outline: drop `move.rb` from the Where line. Queue item `backlog-compaction`.

## The start screen check calls handle in both branches

- Where: `carat/adapters/input_controller.rb:128`. Periodic quality.
- Why it matters: duplicated call.
- Fix outline: dismiss when shown, then one handle call. Backlog batches (dead code).

## Two comments are unwrapped or incomplete

- Where: `carat/use_cases/completion/show_completion_docs.rb:25` (119 columns); `carat/use_cases/files/save_all.rb:8` (omits E45 for a modified read-only buffer). Periodic quality.
- Why it matters: comment wraps and currency.
- Fix outline: rewrap the first, add the read-only case to the second. Backlog batches (comment wraps).

## Test helpers are copied across files

- Where: `test/editor_floats.rb:30`; the `strings` helper in `test/domain_buffer.rb`, `test/domain_edits.rb`, `test/domain_global.rb`, `test/editor_floats.rb`. Periodic quality.
- Why it matters: two bodies for one helper.
- Fix outline: build the editor from `configured`, one `strings` helper in `Carat::Testing`. Backlog batches (test hygiene).

## The replace-jump tests leave three paths unchecked

- Where: `test/adapters_definitions.rb:516` and `:519`, `test/adapters_tab_bar.rb:96`, against `docs/compatibility.md:288` and `carat/adapters/tab_bar.rb:76`. Quality advisory of `jump-replace-tab`. Raised again at be4b63a (owner moved from `jump-list` to `buffer-list-tidy`).
- Why it matters: no row runs `:bd` after a replace jump to prove `BufferList#replacement_for` skips the unlisted buffer; no tab-bar row has an unlisted current buffer (the `anchor = first if anchor < 0 || current.tabless?` fallback) or unlisted buffers beside tab-page numbers; and the other `jump_case` rows read tabs through `tab_names`, which re-applies `Buffer#tabless?` instead of reading the painted row, while one block repeats the setup of the back-and-forth row to read it.
- Fix outline: a `jump_case` row running `:bd` with a second tabbed buffer; rows with current 0 and with pages 2 in the unlisted table; `r.frame.row_text(0)` in `jump_case`'s output and the separate block dropped. Queue item `buffer-list-tidy`.

## The tab-bar test's unlisted fixture reads ambiguously

- Where: `test/adapters_tab_bar.rb:31` and `:65`. Quality advisory of `jump-replace-tab`.
- Why it matters: the setup strips `*` then `~` but tests both flags with `start_with?` on the raw name, so `~*a.txt` or `*~a.txt` would build a buffer other than the one written; the `unlisted` comment reads as if three paths were listed twice.
- Fix outline: read each prefix once into a flag, or document the one allowed order; reword the comment to "The paths f0.txt to f9.txt with f0.txt, f3.txt, and f9.txt left unlisted by a jump: seven tabs." Backlog batches (test hygiene).

## Three comments edited by jump-replace-tab break the wrap width

- Where: `carat/use_cases/buffers/list_buffers.rb:12`, `carat/adapters/tab_bar.rb:15`, `carat/domain/buffer.rb:62`. Quality advisory of `jump-replace-tab`.
- Why it matters: the edited lines run past the files' 72-column wrap.
- Fix outline: rewrap the paragraphs. Backlog batches (comment wraps).

## A buffer a jump left unlisted turns modified yet stays hidden

- Where: `carat/use_cases/files/delete_path.rb:64` (`mark_deleted`), `carat/use_cases/plugins/buffer_requests.rb:127`, against `carat/use_cases/buffers/list_buffers.rb:66`. Periodic quality.
- Why it matters: the buffer is hidden from the tab row, `:ls`, and `:ls +`, while `:wa` silently writes the deleted file back and `:q` refuses on a buffer the user cannot see.
- Fix outline: a buffer is listed again when it becomes modified, as Neovim's text edits set `buflisted`, with an editor row. Queue item `periodic-blockers-b`.

## BufferList's comments and hand_tab's guards predate unlisted buffers

- Where: `carat/domain/buffer_list.rb:8`, `:59`, `:65`, `:77`, `:279`; `docs/architecture.md:132`. Periodic quality.
- Why it matters: the comments call every buffer held listed; `hand_tab`'s three guards and its reorder have no domain row, and its modified guard is unreachable behind E37.
- Fix outline: reword the comments and the architecture entry; a table row per guard and for a target before and after the buffer left; state the modified guard as an invariant or drop it. Queue item `buffer-list-tidy`.

## VisitTarget's comment omits jumptab and scans the list three times

- Where: `carat/use_cases/definitions/visit_target.rb:27` and `:83`. Periodic quality advisory.
- Why it matters: the class comment never mentions `option.jumptab replace`; `listed_for` runs up to three times a jump (see the existing `listed_for` entry).
- Fix outline: one comment sentence; pass the held buffer into `view` and `open_path`. Queue item `definitions-tidy`.

## :set jumptab answers E518 while :set breadcrumbs answers Not implemented

- Where: `carat/use_cases/ex/set_command_handler.rb:27`. Periodic quality advisory.
- Why it matters: `PENDING` copies `Options::KINDS` by hand and misses jumptab, indentguides, keyhints.delay, and layout.
- Fix outline: derive the names from `Options::KINDS` plus the abbreviations, with a row for `:set jumptab`. Backlog batches (config checks).

## KeyNotation branches on a Symbol constant the notes call miscompiled

- Where: `carat/domain/key_notation.rb:150`; `test/domain_keys.rb`. Periodic quality.
- Why it matters: `when Key::INSERT` has the shape `docs/spinel-notes.md` says folds to false, and no row formats `<Insert>` or `<Unknown>`.
- Fix outline: format rows for both; if they fail, guard returns as `Mode.visual_kind`. Queue item `spinel-workarounds`.

## The map misses the definition follow-ups, Paths names, and PluginEntry#attach

- Where: `docs/codebase-map.md:141`, `:151`, `:526`, `:535`. Periodic quality advisory.
- Why it matters: the pump and HandleKey lines omit ShowDefinition and FollowDefinition; Paths omits `absolute` and `segments`.
- Fix outline: add the names. Queue item `docs-index`.

## carat.rb misses two production files

- Where: `carat.rb:2`; `carat/domain/border_style.rb`, `carat/use_cases/actions/search_handler.rb`. Periodic quality. Raised again at 9a92265 (#99): `carat/adapters/indent_guides.rb` is missing too, making three.
- Why it matters: the header promises every file once; both are reached only transitively.
- Fix outline: add both in layer order; `test/lint.rb` checks every production file is required. Queue item `docs-index`.

## Search and pattern code keeps magic numbers and a literal message

- Where: `carat/use_cases/search/find_match.rb:68`, `:163`; `preview_search.rb:37`; `carat/domain/vim_pattern.rb:641`; `carat/domain/walker.rb:63`. Periodic quality.
- Why it matters: the delimiter is `47 : 63` twice, E486 is the only literal search message, `collection_end`'s comment names the wrong byte, and `Walker` calls `Motions.code_class` without requiring it.
- Fix outline: a delimiter method, `Search::NOT_FOUND`, a reworded comment, one shared class-table module. Queue item `search-tidy`.

## InputController hand-writes a reader and repeats a call

- Where: `carat/adapters/input_controller.rb:128`, `:137`. Periodic quality advisory.
- Fix outline: `attr_reader :decoder #: KeyDecoder`; dismiss first, then one `handle`. Backlog batches (copies).

## Config pins its settings as untyped

- Where: `carat/domain/config.rb:27`; `carat/domain/search_pattern.rb:9`. Periodic quality advisory.
- Fix outline: `Array[RcLine]` or a comment naming the Spinel limit; a comment for the dropped Regexp signature. Backlog batches (RBS pins).

## gate_records reads its review commit unchecked

- Where: `tools/gates.sh:436`. Periodic quality.
- Why it matters: every other gate checks a run-state commit as hex and passes `--end-of-options`.
- Fix outline: the same check as `gate_stages`. Queue item `content-gate-gaps`.

## VisitTarget pushes a cross-file jump that enter already recorded

- Where: `carat/use_cases/definitions/visit_target.rb:87`, against `BufferList#enter` reached through `OpenFile` or `view`. Quality advisory of `jump-list`.
- Why it matters: for a jump to another file `enter` already pushed the same entry, so this push only re-appends it, and after a reused startup buffer it records an entry under the id the target took.
- Fix outline: push explicitly only in the same-file case and leave cross-file jumps to `enter`, with a row asserting one entry per cross-file `gd`. Queue item `definitions-tidy`.

## Every window allocates a jump list, floats and splits included

- Where: `carat/domain/window.rb:39`; the float windows of the completion popup, hover, signature, key hints, and palette, built per show; the split's `Window.new` followed by `copy_from`. Quality advisory of `jump-list`.
- Why it matters: each window now allocates a `JumpList` and three arrays, so every float shown and every split allocates them, and a split builds them in `Window.new` and then dups them again in `copy_from`.
- Fix outline: check the figures with `make bench` and `make metrics-compare`; if they grow, give float windows no list of their own or copy the list in the split's constructor. Queue item `run-budgets-tidy`.

## first_file and last_file are one scan written twice

- Where: `carat/domain/buffer_list.rb:131`; `carat/use_cases/buffers/switch_buffer.rb:36`. Quality advisory of `jump-list`.
- Why it matters: two copies of one scan, and `SwitchBuffer#call` re-tests the target in a ternary inside the `elsif` that already chose it.
- Fix outline: one `BufferList` method taking the direction, or separate `:first` and `:last` branches in `SwitchBuffer`. Queue item `buffer-list-tidy`.

## No row reaches the E85 branch of :bfirst and :blast

- Where: `carat/use_cases/buffers/switch_buffer.rb:37`, against `docs/compatibility.md:292`. Quality advisory of `jump-list`.
- Why it matters: the compatibility rows promise E85 for a list without file buffers, but no test runs that branch, so a regression there goes unseen.
- Fix outline: a row in `test/editor_buffers.rb` running `:bfirst` and `:blast` with only a scratch buffer, and with no file buffer, listed. Queue item `buffer-list-tidy`.

## The content gates drop the scanner's exit status

- Where: `report()` in `tools/gates.sh:189` (also 197 and 491) and `tools/docs_lint.sh:79`. Quality advisory of `url-email-guard`.
- Why it matters: `report()` reads only the scanner's output, so a scanner error (exit 2 from `mktemp`, `awk`, or a missing file) leaves the content, pr-body, and docs content checks printing ok, while `tools/pr_scan.sh` does check the status.
- Fix outline: keep the scanner's status (run it into a variable, not through `sort` in a pipeline) and call `bad()` when it is 2, with a `tools/tools_test.sh` case. Queue item `content-gate-gaps`.

## The content gate's header comment has a doubled close

- Where: `tools/gates.sh:13`. Quality advisory of `url-email-guard`.
- Why it matters: the header reads `a literal password or token); (tools/scan_text.sh); no commit adds`, a doubled close from the inserted line, which misreads.
- Fix outline: write `a literal password or token), through tools/scan_text.sh; no commit adds`. Queue item: backlog batches (comment wraps).

## The record phase is a separate agent start

- Where: the record start of `.claude/workflows/deliver-change.js`; retrospective note 7 of `jump-list`.
- Why it matters: it runs one queued shell line for 641 to 1,170 output tokens and 1 or 2 calls in each of the last 10 rows, while the close start already runs a record line of the same kind.
- Fix outline: none prescribed; accepted when 3 runs have no record phase and `show` lists the same keys. Queue item `phase-shares`.

## Keymap repeats its key checks and trie walk

- Where: `carat/domain/keymap.rb:314` (`name_group` repeats `bind_text`'s checks at 200 to 203; `holder_of` 242, `node_at` 269, `lookup` 290 each walk the trie). Periodic quality at 9a92265.
- Why it matters: three copies of one walk drift apart when a key form is added.
- Fix outline: one private key parser and one private walk used by all. Queue item: backlog batches (copies).

## Docs drift found at 9a92265

- Where: `docs/codebase-map.md:118` (EditorState names `show` twice); `docs/codebase-map.md:443` (area 12 claims every ex spelling, but no buffer-list command row is in `test/use_cases_ex.rb`); `docs/architecture.md:326` (plugin API 2.0 against 2.5 in `carat/plugin_api.rb:12` and `docs/plugins.md:23`); `carat.rb:2` (says `bin/*.rb` require only it, while `bin/carat-gen-config.rb:11` requires two files directly). Periodic quality.
- Why it matters: agents plan from these documents.
- Fix outline: correct each, or add the spelling rows. Queue item `docs-index`.

## BufferList's comments call its unlisted buffers listed, and the unsaved rule has ten copies

- Where: `carat/domain/buffer_list.rb:8` (class comment, `for_path`, `with_id`, and map area 8 say listed buffers, though `hand_tab` leaves unlisted ones in it; OpenFile names the result listed); `modified? && !scratch?` at `walk_jumps.rb:37`, `visit_target.rb:80`, `quit.rb:42` and `:51`, `save_all.rb:31`, `switch_buffer.rb:43`, `list_buffers.rb:88`, `window_requests.rb:163`, `buffer_list.rb:108` and `:233`. Periodic quality at 9a92265.
- Why it matters: callers read a list as listed buffers only; the rule changes in one place and not the others.
- Fix outline: reword to buffers listed or not, and one Buffer predicate with a domain row. Queue item `buffer-list-tidy`.

## Ex and visual code copy domain helpers

- Where: `carat/use_cases/ex/buffer_command_handler.rb:101` (`digits?` repeats the public `HistoryCommandHandler.digits?` at `history_command_handler.rb:65`); `carat/use_cases/ex/register_command_handler.rb:61` (repeats `RegisterEntry#lines` at `register_entry.rb:42`); `carat/use_cases/visual/put_over_selection.rb:124` (repeats the linewise count loop of `Operators.put` at `operators.rb:42`). Periodic quality at 9a92265.
- Why it matters: copies drift; the put copy also carries the uncapped count.
- Fix outline: one domain helper each. Queue items `editing-counts` (the put copy) and backlog batches (copies).

## Visual operations compute what their selection kind never uses

- Where: `carat/use_cases/visual/put_over_selection.rb:38` (block, top column, and range for every kind); `carat/use_cases/visual/recase_selection.rb:23` (`Selection#span` rebuilds the block per row). Periodic quality at 9a92265.
- Why it matters: line scans per row of a large selection.
- Fix outline: compute each only for its kind, the block once per call. Queue item: backlog batches (dead code).

## Jump list tidy at 9a92265

- Where: `test/domain_jump_list.rb:78` (a Ctrl-I row labeled Ctrl-O); `carat/domain/jump_list.rb:37` (`push` loops though one entry per line exists, and `length_after_push` at :95 repeats the scan); `carat/domain/jump_list.rb:4` (comment wrapped at 37 against 72 columns); `carat/use_cases/definitions/walk_jumps.rb:42` (a gone buffer's entry is dropped and the key does nothing, where Neovim steps on, unstated in `docs/compatibility.md:70`). Periodic quality.
- Why it matters: a mislabeled row and a behavior gap with no compatibility note.
- Fix outline: relabel, one line-index helper, rewrap, and step past dropped entries or record the difference. Queue item `definitions-tidy`.

## The analysis budget warns on every build and passes a non-numeric rounds value

- Where: `Makefile:78` (22 to 26 s and `ANALYSIS_MS` 45000, also `docs/architecture.md` line 346, against 39.0 s and 92.3 s at #95); `tools/analysis_budget.sh:67` (the rounds test errors and passes on a non-number). Periodic quality at 9a92265.
- Why it matters: a warning on every build carries no signal, and a broken figure passes.
- Fix outline: refresh the threshold per root, and refuse a non-numeric value with a case. Queue item `run-budgets-tidy`.

## Periodic review slices cut the map areas by count

- Where: `areaSlices` in `.claude/workflows/periodic-review.js:67`. Periodic quality at 9a92265.
- Why it matters: slice 1 puts area 1 (about 8,850 lines and a 425 KB backlog) with five more areas under one 53-call cap, so the guard, the tools test, and most of the gates go unread.
- Fix outline: weight slices by size or give area 1 its own. Queue item `review-scope`.

## The range scan of commit messages and added lines has two copies

- Where: `tools/pr_scan.sh:44-50` and `gate_content` in `tools/gates.sh:186-198`. Quality advisory of `url-email-guard`.
- Why it matters: both scan a range's commit messages and added lines with `tools/scan_text.sh`, so a rule change in one leaves the other behind (one clear way to do each thing).
- Fix outline: move the range scan into one function in `tools/rules.sh`, say `scan_range BASE HEAD`, that both call. Queue item `content-gate-gaps`.

## Trusted tooling reads origin/main through replace refs

- Where: every read of `origin/main` by trusted tooling (the origin gate in `tools/gates.sh`, `tools/agent_guard.sh`, and the run state's base reads). Security Medium (5) of the `hooks-path-fix` review, not fixed by `remove-commit-hooks`.
- Why it matters: a `refs/replace/` ref in the clone makes git return other objects for `origin/main`, so a check that trusts main's content can be shown content main never held.
- Fix outline: set `GIT_NO_REPLACE_OBJECTS=1` wherever trusted tooling reads `origin/main`, and refuse `refs/replace` in the origin gate and the guard, each with a `tools/tools_test.sh` case. Queue item `guard-lows`.

## A path written two ways opens a second buffer of one file

- Where: `carat/use_cases/files/open_file.rb:39` (`BufferList#for_path` by the literal path, `BufferList#add` dedupes by identity), against `VisitTarget#listed_for`, `WindowRequests#same_path?`, and `DeletePath`, which compare normalized absolute paths. Periodic quality blocking at bd86828.
- Why it matters: `:e ./a.txt` or `:e` of the absolute path beside a listed `a.txt` makes a second writable buffer of one file, where Neovim reuses one; `:wa` then writes one over the other.
- Fix outline: one lookup rule for every caller, with editor rows for `:e ./a.txt` and the absolute path. Queue item `periodic-blockers-b`.

## Float borders keep their colors under NO_COLOR

- Where: `carat/adapters/frame_presenter.rb:691` (`paint_border_row`, `paint_title` at 705) against the notification boxes at 504 and 508. Periodic quality at bd86828.
- Why it matters: the floating-windows spec says the two boxes share a border, yet under NO_COLOR they differ.
- Fix outline: one rule for both, or the reason recorded, with an `editor_floats` NO_COLOR row. Queue item `float-placement`.

## OpenTab copies a focused float's jumps and leaves it focused

- Where: `carat/use_cases/windows/open_tab.rb:31` (`state.window` is the focused float), unlike `SplitWindow`. Periodic quality at bd86828.
- Why it matters: the new tab page starts with a float's jump list and the float stays focused.
- Fix outline: leave the float first or copy from the layout window, with a row. Queue item `definition-tab`.

## The scanner and gates miss statuses and paths found at bd86828

- Where: `tools/scan_text.sh:83` (`--diff` keeps only awk's status, so a missing FILE scans clean); `tools/gates.sh:282` (the docs gate's process files omit `tools/rules.sh`, `tools/scan_text.sh`, `tools/pr_scan.sh`, `.github/workflows/`). Periodic quality.
- Why it matters: a scanner error reads as clean, and a process change escapes its CLAUDE.md check.
- Fix outline: a nonzero status for a missing file and the paths added to the docs gate, each with a `tools_test` case. Queue item `content-gate-gaps`.

## The ex digit readers are four, and one is uncapped

- Where: `carat/use_cases/ex/history_command_handler.rb:43` and :75 (`:undo N`, `:earlier N`, `:later N` feed `args.to_i` unbounded), beside `ExRange.line_number`, `RegisterCount`, and `BufferCommandHandler#number_in`/`digits?` (buffer_command_handler.rb:101). Periodic quality at bd86828.
- Why it matters: a 20-digit count reaches the history walk, the overflow `number_in` exists to prevent.
- Fix outline: one bounded digit reader for all four, with rows for a 20-digit `:undo` and `:earlier`. Queue item `editing-counts`.

## BufferList decides reuse twice, and :e and :x ignore the scratch rule

- Where: `carat/domain/buffer_list.rb:303` (`enter` repeats `load`'s reuse test at 283); `carat/use_cases/ex/file_command_handler.rb:95` (`:e` refuses an edited scratch buffer with E37) and :77 (`:x` tries to write it). Periodic quality at bd86828.
- Why it matters: two reuse rules can drift; the nine copies of `modified? && !scratch?` are how two sites missed it.
- Fix outline: one reuse decision and one unsaved predicate at every site, with a `test/editor_cmdline.rb` row for `:e` from an edited scratch window. Queue item `buffer-list-tidy`.

## Docs drift found at bd86828

- Where: `Makefile:385` and :389 (the tools-test help omits the scanner and the pull request scan; docs-lint omits secrets); `README.md:15` (no `make spinel-rev` row); `docs/codebase-map.md:331`, 360, 421 (Selection, Layout, ExTable methods missing; `HistoryCommandHandler.digits?` listed public). Periodic quality.
- Why it matters: agents plan from these documents.
- Fix outline: correct each. Queue item `docs-index`.

## The periodic slices put area 1 under one cap

- Where: `.claude/workflows/periodic-review.js:67` (`areaSlices` splits by area count; area 1 holds about 6,700 lines). Periodic quality at bd86828.
- Why it matters: the slice holding area 1 caps and the review ends partial by design.
- Fix outline: none prescribed; superseded if the council reviews diffs. Queue item `periodic-council`.

## drop_key repeats write_key's rewrite

- Where: `tools/run_state.sh:309`. Periodic quality at bd86828.
- Why it matters: two copies of the locked rewrite of the state file.
- Fix outline: one rewrite helper, or gone with the Ruby port. Queue item `harness-ruby`.

## Small tidy-ups found at bd86828

- Where: dead code at `tools/gates.sh:79` and `tools/docs_lint.sh:23` (`TAB`), `carat/domain/options.rb:93` (`KEYHINTS_DELAY`), `carat/use_cases/ex/ex_table.rb:56` (`@index` never read); stale comments at `tools/docs_lint.sh:12` and :27, `carat/use_cases/plugins/ui_requests.rb:112`; the variable `report` shadowing the function at `tools/docs_lint.sh:67`; per-call tallies in instance variables at `carat/use_cases/history/walk_history.rb:32`; `carat/use_cases/repeat_last.rb:49` resets `replaying` without `ensure`; `carat/use_cases/plugins/plugin_host.rb:78` builds a second `ResolveInside` outside `EditorAssembly`; `carat/use_cases/plugins/plugin_events.rb:142` queues an unwanted resize event; `carat/domain/syntax_cache.rb:159` repeats `start_of`; `tools/spec_validate.sh:129` erases the first failed preview. Periodic quality.
- Why it matters: each is a second way to do one thing, a rule of CLAUDE.md, or a lost diagnostic.
- Fix outline: fix each in the batch of its domain, with a row where behavior changes. Queue item: backlog batches.

## A superseded red CI is handled as a real red

- Where: the merger's CI handling in `.claude/workflows/deliver-change.js`; retrospective note 11 of `url-email-guard`.
- Why it matters: #100's first text job failed on a footer removed 12 s later and its rerun passed, yet the run spent a contributor start with no commit and a full review round (reviews 37.7% of output).
- Fix outline: none prescribed; accepted when a stale red resolves without a contributor start or a rework count, in a case. Queue item `merge-gate-tidy`.

## The squash body keeps a superseded security line

- Where: the package and merge steps; retrospective note 13 of `url-email-guard`.
- Why it matters: #100's body reported the first security review after the fix round superseded it.
- Fix outline: none prescribed; accepted when the merger refuses a body whose security line differs from the last recorded review. Queue item `merge-gate-tidy`.

## A re-review rereads commits that touch no reviewed code

- Where: the review rounds of `.claude/workflows/deliver-change.js`; retrospective note 12 of `url-email-guard`.
- Why it matters: #100's second round reviewed only packaging commits and re-rated an unchanged Medium (7) to (8), a round of rework.
- Fix outline: none prescribed; accepted when over 5 runs no round comes from a re-rating on unchanged lines. Queue item `review-scope`.

## A pull request can still run its own scan workflow

- Where: `.github/workflows/scan.yml:21` and the README's description of the pull request scan. Security Low (4) of the `remove-commit-hooks` review, raised again as Low (7) after its package step.
- Why it matters: a `pull_request` run uses the pull request's own workflow file, so a pull request that edits `scan.yml` back to `sh tools/pr_scan.sh` runs its own, possibly weakened, scanner and passes, contrary to the claim that a pull request cannot weaken its own check; the comment's promise holds for edits to `tools/*.sh` only. Not a regression: before that change the check was wholly under the pull request's control.
- Fix outline: have the merge gate (`tools/gates.sh` pre-merge, its content check) run the scanner from `origin/main`, copied with `git show origin/main:tools/scan_text.sh` into a temporary directory, or have the merger refuse a pull request that changes `.github/workflows/scan.yml`, `tools/scan_text.sh`, `tools/rules.sh`, or `tools/pr_scan.sh` without explicit review, with a `tools/tools_test.sh` case; either way narrow the `scan.yml` comment and the README to what the base checkout guarantees.

## Leftovers of the commit hooks in the tools tests and the map

- Where: `tools/tools_test.sh:1754` (the case `pr_scan: the base's scanner reads a head that replaces the scanner` runs `$here/pr_scan.sh`, which already used the scanner beside it, so it passes without the change and proves nothing about `scan.yml`'s base checkout; the grep case after it does); `tools/tools_test.sh:846` (the review-due case still says it names the commit hooks and touches `.githooks/pre-commit`); `tools/tools_test.sh:1696` (about 20 lines build a stand-in Spinel repository and run the full `make toolchain` target to show `core.hooksPath` stays unset, which the grep case at 1718 already proves); `docs/codebase-map.md:48` (two parentheticals run together: `(a copy of rules.sh's) (core.hooksPath among them)`). Quality advisories of the `remove-commit-hooks` review.
- Why it matters: the case name describes hooks that no longer exist, the stand-in repository is speculative generality that costs test time, and the map line reads unlike its neighbor.
- Fix outline: rename the pr_scan case to state the contract it guards (`pr_scan.sh` reads the scanner beside itself, never the checkout's) or drop it; rename the review-due case to say it names a re-added `.githooks` file (or drop `[.]githooks/` from `REVIEW_AREAS` and the case); keep only the grep case at 1718 and remove the fakespinel and tooled setup and its case; merge the map's parentheticals into `(a copy of rules.sh's, core.hooksPath among them)`, as the `gates.sh` line above reads.

## Small tidy-ups at bd86828 still holds two duplicate clauses

- Where: `docs/backlog.md`, the `Small tidy-ups found at bd86828` entry, its `plugin_events.rb:142` resize clause and its `spec_validate.sh:129` preview clause. Quality advisory of the `backlog-compaction` review.
- Why it matters: both clauses repeat standalone entries, the duplicates the `backlog-compaction` design says move to those entries, as was done for the df4654c entry.
- Fix outline: in the periodic review's backlog step, move both clauses to their standalone entries as Also listed bullets and drop them from the tidy-ups entry.

## Backlog entries reach the contributor twice

- Where: `.claude/agents/planner.md:25` (`build/plan/backlog.md`) and `.claude/agents/planner.md:28` (plan notes), read at `.claude/agents/contributor.md:48`. Quality advisory of the `backlog-compaction` review.
- Why it matters: a finding to append can arrive both as a plan note and as an entry of `build/plan/backlog.md`, and the contributor can no longer read the backlog to avoid appending it twice.
- Fix outline: the planner writes backlog entries only to `build/plan/backlog.md`, and its plan notes keep the other bookkeeping.

## The backlog append names no entry shape and no route

- Where: `.claude/agents/contributor.md:48` (package step 2) and `.claude/agents/planner.md:25` (`build/plan/backlog.md`). Quality advisories of the `backlog-compaction` review.
- Why it matters: the contributor must append entries to a file it may not read for their shape, and `tools/agent_guard.sh` refuses here-documents, so neither the entry form nor a working append route is stated.
- Fix outline: state the shape (a blank line, a `## ` title, then `- Where:`, `- Why it matters:`, and `- Fix outline:` bullets) and the route (write the entries to a `tmp/` file with the Write tool, then `cat` it `>> docs/backlog.md`) in `contributor.md`, and the same shape in `planner.md` for `build/plan/backlog.md`.

## The docs credit the periodic review with backlog edits it never makes

- Where: `CLAUDE.md:208` and `README.md:192`. Quality advisory of the `backlog-compaction` review.
- Why it matters: both say the periodic review merges duplicate entries and clears fixed ones, but the periodic reviewers never edit and `/review` fixes nothing, so until `periodic-council` lands nothing does.
- Fix outline: say the periodic quality review reports duplicates and fixed entries and the backlog step of `periodic-council` applies them.

## The implement step does not say to grep the named backlog entries

- Where: `.claude/agents/contributor.md:34` (implement step 1); `openspec/changes/archive/2026-11-11-backlog-compaction/tasks.md` task 2.4 marks `contributor.md` done for it. Quality advisories of the `backlog-compaction` review.
- Why it matters: the positive rule reaches the contributor only through `CLAUDE.md:208`; the agent file states only the package step's never read it whole.
- Fix outline: add to implement step 1 "when your queue item names backlog entries, Grep `docs/backlog.md` for those entries only".

## The review command credits the planner with the backlog append

- Where: `.claude/commands/review.md:10`. Quality advisory of the `backlog-compaction` review.
- Why it matters: "puts ... the others in the queue or appended to the backlog" mixes two constructions and credits the planner with an append the contributor does from `build/plan/backlog.md`.
- Fix outline: write "puts ... the others in the queue or in `build/plan/backlog.md`, which the package step appends to the backlog".

## A submodule's own git config runs a command past the guard

- Where: `tools/agent_guard.sh:854` and the origin gate `tools/gates.sh:136` read only the superproject's `.git/config` and hooks. Periodic security Medium (6) at d0d783c.
- Why it matters: a populated submodule's configuration under the common git directory's `modules` folder runs a command on `git status` (`core.fsmonitor`, verified with git 2.43).
- Fix outline: refuse while the `modules` folder holds anything, or scan every `modules/*/config` with `RISKY_CONFIG` and every `modules/*/hooks`, in both scripts, with `tools/tools_test.sh` cases. Queue item `guard-lows`.

## RISKY_CONFIG omits command-bearing keys

- Where: `tools/rules.sh:51` and its copy in the guard. Periodic security Low (4) at d0d783c.
- Why it matters: `submodule.NAME.update`, `submodule.recurse`, `pager.CMD`, and `trailer.TOKEN.cmd` or `command` can run a command and pass the check.
- Fix outline: add submodule, pager, and trailer key patterns to both copies, with a `tools/tools_test.sh` case per key. Queue item `guard-lows`.

## The toolchain checkout's git config is unchecked

- Where: `Makefile:145` (`spinel_checkout` runs git in `tmp/.spinel`), linked writable into check clones at `tools/run_state.sh:529`. Periodic security Low (4) at d0d783c.
- Why it matters: a stage can plant `core.fsmonitor` in `tmp/.spinel/.git/config` that the next `make toolchain` or `spinel-header` runs.
- Fix outline: run its git with `GIT_CONFIG_GLOBAL=/dev/null` and refuse a `RISKY_CONFIG` key in that config, or stop linking `tmp/.spinel` into the check clone. Queue item `check-runner-safety`.

## A key-sequence mapping value loads unchecked

- Where: `carat/domain/keymap.rb:185` stores a non-action value unparsed; `carat/use_cases/handle_key.rb:353` replays it with `KeyNotation.parse(sequence, "")`. Periodic quality at d0d783c, the review's one blocking finding (the run state does not mark which; this one breaks CLAUDE.md Stack's `file:line` rule).
- Why it matters: `keymap.normal <leader>s <leader>w` and any value with an unknown `<Name>` load with no `file:line` problem and fail only when pressed, as Bad mapping.
- Fix outline: parse a non-action value with the leader when the line is applied, report its error on the line, and store the expanded sequence, with `test/editor_leader.rb` rows for `<leader>` in a replay and for an unknown name. Queue item `periodic-blockers-b`.

## Ctrl-N and Ctrl-P scan unlisted buffers

- Where: `carat/domain/buffer_words.rb:45` skips only scratch buffers, against its class comment (line 11). Periodic quality advisory at d0d783c.
- Why it matters: Neovim's 'complete' `b` scans only listed buffers; words from buffers a jump left unlisted leak into completion.
- Fix outline: skip buffers that are not listed, with a `test/editor_word_completion.rb` row after a replace jump. Queue item `buffer-list-tidy`.

## :bd N deletes a buffer a jump left unlisted

- Where: `carat/use_cases/buffers/delete_buffer.rb:29`, against the class comment (line 16). Periodic quality advisory at d0d783c.
- Why it matters: the comment promises E516 for a number of no listed file buffer, as Neovim answers.
- Fix outline: refuse an unlisted target with E516 when a number is given, with a `test/editor_buffers.rb` row after a replace jump. Queue item `buffer-list-tidy`.

## :tabnew from a float copies the float's jump list

- Where: `carat/use_cases/windows/open_tab.rb:220` copies `state.window.jumps`. Periodic quality advisory at d0d783c.
- Why it matters: while a float has the focus that list is empty, so the new tab page loses the layout window's jumps.
- Fix outline: copy the layout window's jumps, with a `test/editor_jumps.rb` row opening a tab from an entered float. Queue item `definitions-tidy`.

## The jump-tab hand-over is written twice

- Where: `carat/use_cases/definitions/walk_jumps.rb:51` and `carat/use_cases/definitions/visit_target.rb:82`. Periodic quality advisory at d0d783c.
- Why it matters: both read `tabless?` before the open, open, then hand the tab when `option.jumptab` says so; two copies of one rule drift.
- Fix outline: one shared place both use cases call, with the existing replace and keep rows unchanged. Queue item `definitions-tidy`.

## Docs drift: option list, UI group count, a doubled map entry, run-together parentheticals

- Where: `docs/architecture.md:241` omits `jumptab`, `indentguides.char`, `startscreen`, and `reducedmotion`, which `carat/domain/options.rb:82` accepts; `docs/codebase-map.md:493` and `docs/architecture.md:106` say 49 UI groups and `docs/compatibility.md:510` says 41, while `carat/domain/highlight.rb:66-69` has 52; `docs/codebase-map.md:120` lists `EditorState#show` twice; `docs/codebase-map.md:48` runs two parentheticals together. Periodic quality and #102 package advisories at d0d783c.
- Why it matters: the docs an agent reads disagree with the code.
- Fix outline: name the options (or point at `docs/compatibility.md`) within the byte budget, say 52 in the three docs, drop the second `show`, merge the parentheticals. Queue item `docs-index`.

## Two comments rewrapped unevenly

- Where: `carat/domain/highlight.rb:3` (lines 6-7 and 12-13 stop at 37 to 50 columns) and `carat/use_cases/ex/set_command_handler.rb:17` (about 95 columns). Periodic quality advisories at d0d783c.
- Why it matters: comment blocks wrap at 72 columns elsewhere.
- Fix outline: rewrap both paragraphs. Queue item: backlog batches, comment wraps.

## A backlog entry still names a fixed JumpList#step defect

- Where: the `docs/backlog.md` entry that says `JumpList#step` pushes before the range check (line 3367 at d0d783c); `carat/domain/jump_list.rb:59-60` now returns early and `test/domain_jump_list.rb:78` pins it. Periodic quality advisory at d0d783c.
- Why it matters: a stale clause sends a later change after a fixed defect.
- Fix outline: drop that clause from the entry's fix outline, in the periodic review's backlog step. Queue item `periodic-council`.

## delivery-speed quality advisory at tools/run_state.sh:406

- Where: `tools/run_state.sh:406`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: main_stages is a one-time migration shim: once this change merges every origin/main defines FAST_STAGES, so the function and its two tools_test cases are dead code.
- Fix outline: remove them in the next tooling change.

## delivery-speed quality advisory at docs/codebase-map.md:46

- Where: `docs/codebase-map.md:46`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the set entry now reads a commit hash;, phase with its parenthesis never closed after drop_backup was removed.
- Fix outline: write commit hash), phase.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:796

- Where: `.claude/workflows/deliver-change.js:796`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: reRaised matches file:line only, so a new correctness bug a fix round introduces at the line of an earlier advisory is silently demoted.
- Fix outline: demote only when the blocking text without its commit equals the earlier advisory's text, or also compare the reason.

## delivery-speed quality advisory at .claude/agents/merger.md:24

- Where: `.claude/agents/merger.md:24`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: checks has two formats, name, status, conclusion for every run and name: status, conclusion for pending, while staleRed splits on commas only.
- Fix outline: one format for every result.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:97

- Where: `.claude/workflows/deliver-change.js:97`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the CALL_CAPS comment still says a capped start can commit, back up, and return the schema.
- Fix outline: drop back up.

## delivery-speed quality advisory at tools/gates.sh:489

- Where: `tools/gates.sh:489`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the session-line pattern refuses any word session followed by a colon anywhere in a line, such as a Notes sentence about the next session:, a false refusal of a valid body.
- Fix outline: anchor it to a line start, as in ^ *(claude-)?session([ _-]?(id.

## delivery-speed quality advisory at .github/workflows/ci.yml:26

- Where: `.github/workflows/ci.yml:26`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the comment says every other stage runs only here, but docs-lint, dev-build, test-build, test-run, bench-budget, and metrics run in the checker too, and the line was left unwrapped.
- Fix outline: say CI runs every stage but diagnose and gates, rewrapped.

## delivery-speed quality advisory at tools/tools_test.sh:1992

- Where: `tools/tools_test.sh:1992`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: sed s/^None$/None/ body.md is a no-op substitution used as a copy.
- Fix outline: cp body.md session.md.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:344

- Where: `.claude/workflows/deliver-change.js:344`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: settledRecords repeats the commit pattern /^[0-9a-f]{7,40}$/ that COMMIT already holds.
- Fix outline: use COMMIT.test.

## delivery-speed quality advisory at Makefile:398

- Where: `Makefile:398`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the check help still calls CHECK_STAGES everything a push needs, while a push now needs FAST_STAGES and CI runs the rest.
- Fix outline: call it every stage, the checker's and CI's.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:795

- Where: `.claude/workflows/deliver-change.js:795`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: reRaised demotes any blocking quality finding whose file:line equals an earlier advisory, by location alone, in any round and whatever the finding says, so a new correctness bug on a line that once carried a style advisory merges with only a note, and line numbers shift between commits.
- Fix outline: demote only in a narrowed fix round and compare the finding text as well as file:line.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:1089

- Where: `.claude/workflows/deliver-change.js:1089`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: a closing start that does not record now loses its phase lines and metric line with only a note, so a merged run history row can lack its package, ci, and merge figures.
- Fix outline: keep one record start for the refused close, or say in the report which figures are missing.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:481

- Where: `.claude/workflows/deliver-change.js:481`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: dead code: 'if (!command) return true' cannot run, since flush returns earlier unless a non-closable line is pending.
- Fix outline: drop it.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:1015

- Where: `.claude/workflows/deliver-change.js:1015`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: a superseded red reuses the pending wait counter, so the merger's next prompt says CI was still running, and the body mode is measured under the package key (line 610).
- Fix outline: a separate counter and prompt for a superseded red, and its own usage key for body.

## delivery-speed quality advisory at .claude/workflows/deliver-change.js:1073

- Where: `.claude/workflows/deliver-change.js:1073`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: on a resume past the push the reviews rerun over the whole diff with an empty handed set, so recordLate at the close turns every advisory the package step already appended into late-finding notes that history appends to docs/backlog.md again.
- Fix outline: record late findings only from a start that ran the package step or a CI fix, or dedupe against the backlog text in append_history.

## delivery-speed quality advisory at tools/run_state.sh:1217

- Where: `tools/run_state.sh:1217`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: late findings are appended as one heading of bare bullets, not the Where, Why it matters, Fix outline entry shape the rest of docs/backlog.md and CLAUDE.md use.
- Fix outline: write one entry per finding in that shape, or document the grouped form in the backlog header.

## delivery-speed quality advisory at tools/gates.sh:35

- Where: `tools/gates.sh:35`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the header still says the stages gate requires every canonical stage from CHECK_STAGES, while stage_list now reads FAST_STAGES first.
- Fix outline: say FAST_STAGES, else CHECK_STAGES.

## delivery-speed quality advisory at .claude/agents/checker.md:3

- Where: `.claude/agents/checker.md:3`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the description still says the checker runs the canonical stage list.
- Fix outline: say the fast stages (FAST_STAGES).

## pr-by-tag quality advisory at .github/workflows/open-pr.yml:40

- Where: `.github/workflows/open-pr.yml:40`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: the comment says a branch cannot weaken the checks of its own title and body, but the workflow file and the tools/pr_tag.sh that calls main's gates are the tagged commit's, so a branch can skip them.
- Fix outline: reword it to say main's gates sit beside the scan workflow's base-commit scanner, as design.md Risks already admits.

## pr-by-tag quality advisory at .claude/agents/contributor.md:22

- Where: `.claude/agents/contributor.md:22`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: 'tools/agent_guard.sh refuses both' now follows the two allowed pushes and reads as if the guard refused them.
- Fix outline: say the guard refuses recording a phase or review and any other push.

## pr-by-tag quality advisory at tools/run_state.sh:716

- Where: `tools/run_state.sh:716`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: CHECK_BIN repeats the Makefile's DEV_BIN path and the run_state.sh entry of docs/codebase-map.md does not name it.
- Fix outline: name CHECK_BIN beside in_clone in the map entry, its comment naming DEV_BIN as the one source.

## pr-by-tag quality advisory at tools/agent_guard.sh:588

- Where: `tools/agent_guard.sh:588`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: the contributor keeps the permission tools/run_state.sh set CHANGE pr N (header line 66, test 'contributor pushes and opens the pull request'), though pr_tag.sh wait now records the number and the agent must never record a pull request another way.
- Fix outline: drop contributor:pr and the header's set CHANGE pr N, and the set from that guard test.

## pr-by-tag quality advisory at tools/pr_tag.sh:131

- Where: tools/pr_tag.sh:131 (removed by pr-on-push). Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: an ls-remote failure in wait becomes empty refs, so a wait that never read origin ends with 'no pull request's head is', naming the wrong cause.
- Fix outline: remember the failure and refuse with 'origin cannot be read' as push does.

## pr-on-push security Low at tools/open_pr.sh:118

- Where: `tools/open_pr.sh:118`. Delivery review of `pr-on-push` (security Low, confidence 4) at a2d4b6c.
- Why it matters: wait records any pull request whose head equals the pushed sha (the largest number), so someone watching the repository could open a fork pull request at that sha before open-pr runs; the run would record it and the merger would squash it with their title as main's subject (the merged code is still the reviewed commit, because the merger passes the pushed sha as the expected head).
- Fix outline: in wait, keep only pull requests whose head is in this repository and whose head branch is the delivery's branch (gh pr list --head BRANCH with headRefOid equal to the pushed sha and isCrossRepository false), or use the number open-pr reports.

## pr-on-push security Low at .github/workflows/open-pr.yml:39

- Where: `.github/workflows/open-pr.yml:39`. Delivery review of `pr-on-push` (security Low, confidence 3) at a2d4b6c.
- Why it matters: the new PR_TOKEN (a token of the user's) is only as safe as the AI environment's deployment-branch rule, a repository setting outside the diff; without it any branch push could add a workflow naming environment: AI and read the token.
- Fix outline: confirm the AI environment allows only main as its deployment branch, and make PR_TOKEN a fine-grained token scoped to this repository with only the pull-request permission it needs.

## pr-on-push quality advisory at tools/open_pr.sh:43

- Where: `tools/open_pr.sh:43`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: BRANCH_RE takes no dot or nested slash while branch-push.yml fires on every type/** push, so a push of release/1.2.0 (the example in CLAUDE.md) turns open-pr red.
- Fix outline: have read print nothing to open and exit 0 for a branch it does not take, or narrow the branch-push filter to match.

## pr-on-push quality advisory at tools/open_pr.sh:112

- Where: `tools/open_pr.sh:112`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: WAIT_STEP=0 passes the [0-9]{1,3} check and waited never grows, so wait polls origin forever.
- Fix outline: match [1-9][0-9]{0,2}.

## pr-on-push quality advisory at tools/open_pr.sh:180

- Where: `tools/open_pr.sh:180`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: the read-back looks the pull request up by branch name (gh pr view "$branch") instead of the URL gh pr create printed, so a branch with an earlier pull request can compare the wrong one.
- Fix outline: keep the create output and pass that URL to both gh pr view calls.

## pr-on-push quality advisory at tools/tools_test.sh:558

- Where: `tools/tools_test.sh:558`. Delivery review of `pr-on-push` (quality advisory) at e873e89.
- Why it matters: the open_pr cases prove no refusal of a branch with two new pr.md files, of a title with forbidden text at gate, or of a bad WAIT_STEP.
- Fix outline: add one expect case for each.

## pr-on-push quality advisory at tools/open_pr.sh:126

- Where: `tools/open_pr.sh:126`. Delivery review of `pr-on-push` (quality advisory) at a2d4b6c.
- Why it matters: wait counts only its sleeps toward SECONDS, not the up to 55 git ls-remote reads of origin, so a slow origin pushes the 540 s poll past the 600000 ms Bash timeout contributor.md:51 now sets and the tool kills it before its refuse message.
- Fix outline: stop on a deadline from date +%s, or lower MAX_WAIT to leave the reads room.

## pr-on-push quality advisory at .claude/agents/contributor.md:35

- Where: `.claude/agents/contributor.md:35`. Delivery review of `pr-on-push` (quality advisory) at a2d4b6c.
- Why it matters: the fix commit for the wait timeout also rewords unrelated lines (step 2 drops 'for the archive', step 3 'fill in' to 'add', step 6 drops 'The workflow records the phase from your result.', the Context paragraph), so one commit mixes the fix with edits no finding asked for.
- Fix outline: keep a fix commit to its finding, or say in the body why the lines moved (docs-lint budget).

### Check clone's binary path not named in the map (late `pr-by-tag` quality advisory)

- Location: `tools/run_state.sh` `CHECK_BIN` (beside `in_clone`), and the `run_state.sh` entry of `docs/codebase-map.md`.
- Why it matters: `CHECK_BIN` repeats the Makefile's `DEV_BIN` path, so a change to one leaves the detached check running a stale or missing binary, and the map entry does not name it, so a reader cannot find it.
- Fix outline: name `CHECK_BIN` beside `in_clone` in the map entry and let its comment name `DEV_BIN` as the one source; a tools-test case fails when the two paths differ.

### Contributor keeps a pull request number permission (late `pr-by-tag` quality advisory)

- Location: `tools/agent_guard.sh` contributor rule allowing `tools/run_state.sh set CHANGE pr N`, the `tools/run_state.sh` header line naming it, and the guard test "contributor pushes and opens the pull request".
- Why it matters: once the delivery records the number of the pull request GitHub Actions opened, a contributor that may still write `pr` can record a number of a pull request it did not open, and the merger would act on it.
- Fix outline: drop the contributor's `pr` permission and the header line once the wait step records the number, and turn the guard test into a refusal case; keep any bootstrap path the workflow itself needs.

### Sprint security continuation drops differently spelled unreviewed files (`sprint-planning` security Low (5))

- Location: `.claude/workflows/sprint-planning.js:97` `mergeSecurity`.
- Why it matters: it keeps only the continuation's `not_reviewed` entries that exactly match the first start's free-form file names, so a differently spelled path (for example `./tools/run_state.sh`) is dropped and the sprint security review records pass with that file never reviewed.
- Fix outline: fail closed: use `again.not_reviewed` unchanged, or normalize both lists against `git diff --name-only BASE TIP` before intersecting, or constrain the SECURITY schema's `not_reviewed` items to an enum of the combined diff's files as `periodic-review.js` does with its areas.

### Groom's listed check matches any archive name suffix (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1358`, the archive check `openspec/changes/archive/*-WORD`.
- Why it matters: it matches any archived change whose name ends in -WORD, so `listed review` passes on `periodic-review`.
- Fix outline: match the date prefix exactly, `archive/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-WORD`.

### Groom lets every copy of a duplicated finding go (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1373`.
- Why it matters: duplicate lines naming every heading at one location each pass, since `backlog_dups` reads the unmodified file, so all copies of a finding can be removed with no `groomed.md` entry; and `grep -F '$at: '` matches a location as a substring of a longer one.
- Fix outline: refuse a `groom.txt` that removes every heading at a location unless `groomed.md` names it, and compare the location field exactly with awk.

### Stale review-due comment in the periodic review (`sprint-planning` quality advisory)

- Location: `.claude/workflows/periodic-review.js:122`.
- Why it matters: the comment says a partial review keeps the next one due, but `review-due` now counts sprints only, so a reader is misled about when the review runs again.
- Fix outline: drop the review-due clause or state the new rule.

### Rerun of /sprint duplicates the skeptic's notes (`sprint-planning` quality advisory)

- Location: `.claude/workflows/sprint-planning.js:116`.
- Why it matters: a rerun after a partial failure re-inits sprint-N (resume) and the skeptic records every kept finding again, duplicating the notes the planner reads.
- Fix outline: skip the review phases when `review.periodic-security` of sprint-N is already recorded at the same head, or clear its notes first.

### Two result helpers with different argument types (`sprint-planning` quality advisory)

- Location: `.claude/workflows/sprint-planning.js:129` `result(blocked, missed)`, beside the result helper of `.claude/workflows/periodic-review.js`.
- Why it matters: it duplicates the periodic review's helper with a different argument type (a count against an array), so the two drift apart and a caller passing the other shape gets a wrong status.
- Fix outline: share one shape, both taking the `not_reviewed` list.

### plan-needed treats an unreviewed sprint plan as waiting (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1423` `plan_needed`, the planner's keep rule (`.claude/agents/planner.md:25`), and the package brief.
- Why it matters: they treat any marker as a waiting plan through `sprint_waiting` without `sprint_reviewed`, so while `groom` holds an unreviewed plan deliveries take `build/plan/queue.md`'s head and the planner-not-run package path removes the item from `docs/queue.md`, where it is not, leaving the delivered change at the head of `build/plan/queue.md`.
- Fix outline: one helper (`sprint_waiting` and `sprint_reviewed`) used by `review_due`, `groom`, and `plan_needed`.

### Planner claims docs-lint checks the sprint queue (`sprint-planning` quality advisory)

- Location: `.claude/agents/planner.md:35`, `tools/docs_lint.sh:135` `check_queue`.
- Why it matters: `check_queue` reads only `docs/queue.md`, so `build/plan/queue.md`'s sprint rule is first checked after `groom` copies it in a later package step.
- Fix outline: let `docs_lint` take the queue path (for example `QUEUE=build/plan/queue.md`) and have the planner run it, or reword the sentence.

### docs_lint header gives the old sprint size (`sprint-planning` quality advisory)

- Location: `tools/docs_lint.sh:19`, against the check at line 151 and the map.
- Why it matters: the header still says the sprint items are 1 to 5 while the check and the map moved to 0 to 5, a drained sprint.
- Fix outline: say 0 to 5, 0 once the sprint's deliveries drained it.

### Sprint after a sixth merge reviews a change twice (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1255` `sprint_names` and the due line, `sprint_row` (line 1324).
- Why it matters: when /sprint runs after a sixth merge, `sprint_names` and the due line list every change since the last sprint and the combined diff runs to `origin/main`, but `sprint_row` closes the sprint at its fifth row, so the sixth change is reviewed in this sprint and counted again in the next.
- Fix outline: cut `sprint_names` at `SPRINT_SIZE` and end the combined diff at the fifth change's merged commit.

### Usage header splits review-due's description (`ci-time` quality advisory)

- Location: `tools/run_state.sh:137`.
- Why it matters: the ci-stages and tokens usage lines are inserted inside review-due's description, splitting it in the header that usage prints.
- Fix outline: move the two entries after the end of review-due's block.

### Stale comment on who runs ci-stages (`ci-time` quality advisory)

- Location: `tools/run_state.sh:1184`.
- Why it matters: the comment says the merger's green and red lines run ci-stages, but the workflow queues it for the record or closing start and the merger's lines never run it.
- Fix outline: say the record or closing start runs it after CI finished.

### ci-stages may drop every step on fractional seconds (`ci-time` quality advisory)

- Location: `tools/run_state.sh:1194`.
- Why it matters: the awk keeps only whole seconds, so if gh's fromdateiso8601 returns fractional seconds for GitHub's millisecond step timestamps every step is dropped and nothing is recorded; the fake gh never runs the jq.
- Fix outline: floor the difference in the jq, or accept a decimal and round in awk.

### ci-stages step name can exceed 32 characters (`ci-time` quality advisory)

- Location: `tools/run_state.sh:1197`.
- Why it matters: a step name longer than 32 characters with no underscore in its first 33 stays 33 characters, against the documented limit of 32.
- Fix outline: fall back to substr(name, 1, 32) when the sub removes nothing.

### ci_scope.sh lost its executable bit (`ci-time` quality advisory)

- Location: `tools/ci_scope.sh:1`.
- Why it matters: the file mode goes from 100755 to 100644, which the change does not mention.
- Fix outline: restore the executable bit, or name the change in a proposal.

### ci-stages queued on every green or red return (`ci-time` quality advisory)

- Location: `.claude/workflows/deliver-change.js:1029`.
- Why it matters: ci-stages is queued on every green or red return, the stale reds that loop again included, so the same line can run several times.
- Fix outline: queue it beside verdict('ci', ...) after the stale-red and pending checks.

### ci_scope.sh fallbacks have no tools test (`ci-time` quality advisory)

- Location: `tools/tools_test.sh:173`.
- Why it matters: the new fallbacks of `tools/ci_scope.sh` (no PR or HEAD_SHA, a green head that cannot be fetched, the GREEN_LOOKUPS limit) have no case.
- Fix outline: add an expect case for each, run=true.

### Redundant parameter defaults in ci_scope.sh (`ci-time` quality advisory)

- Location: `tools/ci_scope.sh:85` and `tools/ci_scope.sh:92`.
- Why it matters: the `${PR:-}` and `${HEAD_SHA:-}` defaults are redundant after the guard at line 82.
- Fix outline: use `$PR` and `$HEAD_SHA`.

## The records-only path list is kept by hand in three places

- Source: quality review of sprints-gate, advisory.
- Location: tools/gates.sh:113 (`settled_at`), tools/run_state.sh:223 (`TEST_ONLY`), tools/ci_scope.sh:45 (`documentation()`).
- Why: one clear way: the records-only path list now differs between `settled_at` (with docs/sprints.tsv) and `TEST_ONLY` and `documentation()` (without it), three hand-kept copies of one list that drift, so a groom write is not treated alike by the gates, the stage carry, the fix scope, and CI.
- Fix: name the planning-records pattern once and use it in all three, or add docs/sprints.tsv to `TEST_ONLY` and `ci_scope` in a follow-up.

### staleRed trusts the merger's order of check runs (`delivery-speed` quality advisory)

- Location: `.claude/workflows/deliver-change.js:301` (`staleRed`) and `.claude/agents/merger.md:24`. Re-entered by the sprint-1 grooming from the second copy of the repeated heading at that line, whose first copy (a comma inside a check name) stays.
- Why it matters: staleRed relies on the merger listing check runs oldest first while GitHub lists them newest first; a misordered list starts a needless fix round or asks again up to WAITS times.
- Fix outline: have the merger return only the latest run per name, or a completion time to sort on, with a tools-test case for each order.

### The sprint quality review gets no continuation at its cap (`sprint-1` review quality)

- Location: `.claude/workflows/sprint-planning.js:123`.
- Why it matters: the security review gets a continued start over the files it left at its cap, the quality review none, so a capped quality review is recorded partial and never covered in that run.
- Fix outline: give quality the same one continuation, or say in the header why it gets none. Queue item `sprint-tidy`.

### The sprint workflow copies the periodic review's caps (`sprint-1` review quality)

- Location: `.claude/workflows/sprint-planning.js:22` (CALLS, FINDING, capLine, the cap 53) against `.claude/workflows/periodic-review.js:17` to `:28` and `:54` (PERIODIC_CAP); the comment at line 71 says they must stay equal.
- Why it matters: workflow scripts cannot import one another, so the copies drift silently.
- Fix outline: a tools-test check that the copies match. Queue item `sprint-tidy`.

### The branch types are written in three places (`sprint-1` review quality)

- Location: `tools/open_pr.sh:43` (BRANCH_RE), `tools/agent_guard.sh:101` (BRANCH), `.github/workflows/branch-push.yml:10` (branches).
- Why it matters: adding a type to one list silently breaks the open-pr path.
- Fix outline: a tools-test check that the three lists match, or one derived from another. Queue item `open-pr-tidy`.

### The merge phase names the branch head, not the squash commit (`ci-time` retrospective)

- Location: the closing input of `.claude/workflows/deliver-change.js` and the `phase.merge` line it records.
- Why it matters: #110 passed the branch head 2e6c64184f00 as merged while the squash on main is 8df063e271c8, so `phase.merge` and the closing gates' BASE name the head; `phase.merge` differs from `merged` in 11 of 74 run states.
- Fix outline: the closing input, `phase.merge`, and `merged` all name the commit on origin/main's first-parent line, with a tools-test case where the merger returns the head. Queue item `merge-gate-integrity`.

### A delivery whose item heads the queue still plans the whole pool (`ci-time` retrospective)

- Location: the plan phase of `.claude/workflows/deliver-change.js` and `plan-needed` in `tools/run_state.sh`.
- Why it matters: #110's item was already decided and estimated, yet 7 of the plan's 8 decisions were about other items: plan 29,632 of 176,620 output tokens (16.8%), plan plus scouts 28.4% at rework 0; plan 4.5% to 23.3% of output over the last 10 rows.
- Fix outline: a delivery whose item heads the queue with an estimate starts no planner, or plan stays under 5% of output over three runs. Queue item `sprint-tidy`.

## records-once quality advisory at tools/run_state.sh:233

- Location: tools/run_state.sh:233, with the stage carry at line 475 and the quality fix scope at line 818.
- Why: TEST_ONLY now admits docs/sprints.tsv, which changes the stage carry and the quality fix scope, but no tools-test case covers a sprints.tsv-only commit in either.
- Fix outline: add an expect that a docs/sprints.tsv-only commit carries a compile stage and is left out of the fix scope.

## records-once quality advisory at tools/run_state.sh:1586

- Location: tools/run_state.sh:1586 and the dispatch at line 1697.
- Why: records_excluded repeats the change-name case of the dispatch, two copies that can drift.
- Fix outline: one change_name helper that both call.

## records-once quality advisory at .claude/agents/planner.md:28

- Location: .claude/agents/planner.md:28, read by .claude/workflows/deliver-change.js:226 and :951.
- Why: step 7 lists the result fields but not the new optional records field the workflow reads, so the planner has only the schema description to know when to return it.
- Fix outline: add records: skip when the brief excludes history and groom to step 7.

## records-once quality advisory at .claude/workflows/deliver-change.js:999

- Location: .claude/workflows/deliver-change.js:999, against tools/rules.sh:52 (RECORDS_RE) and the README.
- Why: the planning records means two sets: RECORDS_RE and the README count the queue and goals among them, while records=skip excludes only history and groom and the package step still applies the planner queue.
- Fix outline: say history and groom (or the metrics and sprint rows) wherever records=skip is described, in the workflow text, the run_state.sh header, CLAUDE.md, and the README.

## records-once quality advisory at .claude/workflows/deliver-change.js:961

- Location: .claude/workflows/deliver-change.js:961 and tools/tools_test.sh.
- Why: excludeRecords and the package text it selects have no js case in tools/tools_test.sh; only the run_state.sh side is tested.
- Fix outline: move the package-text choice into a pure helper and add a js case for records skip and apply.

## records-once quality advisory at tools/tools_test.sh:1564

- Location: tools/tools_test.sh:1564, the rules: the records-only list is named once case.
- Why: the case packs two greps, a sed, and comma-joined printf output into one sh -c line that is hard to read and to diagnose on failure.
- Fix outline: two plain expects, one that grep -l of the literal path list over tools/*.sh names only rules.sh and one per reader that it names RECORDS_RE.

## records-once quality advisory at tools/ci_scope.sh:8

- Location: tools/ci_scope.sh:8 and line 46.
- Why: the header still describes skippable documentation as Markdown and openspec/.claude files, not the shared RECORDS_RE list (docs/metrics.tsv, docs/sprints.tsv), and line 46 writes the records test as a double negation (! grep || return 0).
- Fix outline: name RECORDS_RE in the header and write printf | grep -q -E ... && return 0.

## Findings of sprints-gate after its package step

- security Low (3) tools/gates.sh:113 settled_at exempts any edit to docs/sprints.tsv, not only an appended row, so after the review a commit could rewrite the last sprint row's 'last' column. That moves sprint_base in tools/run_state.sh sprint_state and shrinks the combined diff the sprint-end security review covers. Each change keeps its own security review, and the PR scan still reads the edit.; 

### BufferList#enter duplicates the jump guard of Window#record_jump (`jump-motions` quality advisory)

- Location: `carat/domain/buffer_list.rb:315` (`enter`).
- Why it matters: enter pushes old.id, row, and col itself behind an 'unless old.id == 0' guard that the new Window#record_jump already holds, so the two jump-recording paths can drift apart.
- Fix outline: replace the push with 'current.record_jump unless target.id == 0 && reusable?(old)', keeping the editor_jumps cases green.

### Ctrl-^ shows a scratch alternate buffer that N Ctrl-^ and :b N refuse (`jump-motions` quality advisory)

- Location: `carat/use_cases/buffers/switch_buffer.rb:37`.
- Why it matters: load records a scratch buffer's id as the alternate, so Ctrl-^ shows a scratch buffer while 'N Ctrl-^' and ':b N' refuse the same buffer with E86, an inconsistency between paths to one buffer.
- Fix outline: skip scratch buffers when load sets the alternate, or refuse a scratch alternate in SwitchBuffer as :number does, with an editor_jumps case.

## carat/use_cases/buffers/switch_buffer.rb:37 Ctrl-^ shows a scratch alternate that N Ctrl-^ and :b N refuse (jump-motions, quality advisory)

- Location: carat/use_cases/buffers/switch_buffer.rb:37
- Why: load records a scratch buffer's id as the alternate, so Ctrl-^ shows it, while 'N Ctrl-^' and ':b N' refuse a scratch buffer with E86, an inconsistent answer for the same buffer.
- Fix outline: skip scratch buffers when load sets the alternate, or refuse a scratch alternate in SwitchBuffer as :number does.

## carat/use_cases/ex/file_command_handler.rb:98 the ex handler resolves the alternate buffer itself (jump-motions, quality advisory)

- Location: carat/use_cases/ex/file_command_handler.rb:98
- Why: architecture section 5 has use cases orchestrate entities, but the ex handler now takes the BufferList and resolves the alternate buffer and its E194 and E499 refusals itself, beside SwitchBuffer's own alternate lookup.
- Fix outline: let OpenFile, or a small domain helper on BufferList returning the alternate path or the error, resolve '#', keeping the handler a forwarder.

## tab-keys quality advisory at carat/use_cases/ex/tab_command_handler.rb:101

- Why: duplication, architecture section 5 (logic several use cases share moves into the domain): digits? is the third copy, beside BufferCommandHandler#digits? and HistoryCommandHandler.digits?.
- Fix: move one digits? into a domain helper and call it from the three ex handlers.

## tab-keys quality advisory at carat/use_cases/ex/tab_command_handler.rb:71

- Why: the magic args.bytesize <= 9 is repeated at :82 and mirrors BufferCommandHandler#number_in's own 9-digit cut.
- Fix: one shared number-argument helper (or a named constant) that both handlers use.

## tab-keys quality advisory at carat/use_cases/ex/tab_command_handler.rb:45

- Why: duplication: a sixth inline "E488: Trailing characters" literal while this change moved E475 into Messages.invalid_argument.
- Fix: add Domain::Messages.trailing_characters(text) and use it here and in the other ex handlers.

## tab-keys quality advisory at carat/use_cases/actions/tab_handler.rb:514

- Why: cleverness: the tabline flag is derived from the array position (tabline: i > 2), which breaks silently when a name is added or reordered.
- Fix: a parallel tablines array beside names and targets, or register the two tabline actions on their own lines.

## tab-keys quality advisory at docs/codebase-map.md:125

- Why: map currency: the messages.rb entry does not name the new E16 and invalid_argument, and the buffer_request.rb entry at :383 does not list the new :tab target.
- Fix: add them to both entries.

## tab-keys quality advisory at carat/domain/tab_list.rb:213

- Why: test gap: focus_buffer now records a visit (the :q and :qa refusal moving to another tab page), but no test shows g<Tab> going back after it.
- Fix: add an editor_tabs row such as :tabe b.txt<CR>x<C-PageDown>:qa<CR>g<Tab> checking the tab page returned to.

## Findings of float-edges at its package step

### Quality advisory: text_room border parameter is always true (carat/domain/float_window.rb:46)

- Location: carat/domain/float_window.rb:46
- Why: speculative generality; text_room's border parameter is true at every production caller (palette, hover, signature, definition, key hints), only the test passes false.
- Fix: drop the parameter, text_room(cols, style), or pass the spec's border from the caller.

### Quality advisory: drawn helper and resizable Rig copied across float tests (test/adapters_hover.rb:216)

- Location: test/adapters_hover.rb:216, copies in test/adapters_signature.rb:197 and test/adapters_definitions.rb:285
- Why: duplication and test conventions; the drawn helper and the resizable Rig (@rows, @cols, resize) are copied verbatim, and drawn returns a mixed Array[untyped] instead of an object with typed readers.
- Fix: move one drawn helper returning a small record with typed readers into the shared test support and reuse it.

### Quality advisory: unguarded hover float lookup (test/adapters_hover.rb:383)

- Location: test/adapters_hover.rb:383
- Why: floats.at(floats.index_of(...)) has no guard for a missing float, unlike test/adapters_definitions.rb:592, so a missing hover float indexes -1 instead of failing clearly.
- Fix: guard with at < 0 ? [] : drawn(...) as the definitions test does.

### Quality advisory: finder FRAME literal ignores winborder (carat/plugins/finder/plugin.rb:32)

- Location: carat/plugins/finder/plugin.rb:32
- Why: FRAME = 4 restates FloatWindow.frame_width(1) as a literal, so under winborder none the finder keeps a 3-column right margin and a 2-column gap.
- Fix: expose the frame width through PluginApi in float-placement and derive the finder's sizes from it.

### Quality advisory: place computes frame_width twice (carat/domain/float_window.rb:80)

- Location: carat/domain/float_window.rb:80
- Why: place computes FloatWindow.frame_width(edge) twice beside side = edge + PAD.
- Fix: compute frame = FloatWindow.frame_width(edge) once and use it for the width cut and the shift.

### Quality advisory: unused resize helper in definitions and signature rigs (test/adapters_definitions.rb:39)

- Location: test/adapters_definitions.rb:39 and test/adapters_signature.rb:39
- Why: dead code; the resize helper and the @rows/@cols state are unused there, only adapters_hover calls resize.
- Fix: drop them from those two rigs.

### Quality advisory: drawn helper duplicated in three tests (test/adapters_hover.rb:215)

- Location: test/adapters_hover.rb:215, copies in test/adapters_definitions.rb:284 and test/adapters_signature.rb:196
- Why: duplication; the same drawn helper is copied into three test files.
- Fix: keep one shared helper in the test support or the rig the three share.

### Quality advisory: README says finder boxes share an edge under every border (README.md:58)

- Location: README.md:58
- Why: docs currency; it says the finder's list and preview boxes share an edge, but under option.winborder none they stand two columns apart.
- Fix: say they share an edge under a drawn border and keep a gap under none.

### Quality advisory: sized_session repeats session (test/editor_key_hints.rb:65)

- Location: test/editor_key_hints.rb:65
- Why: duplication; sized_session repeats session (line 11) but for the cols and the wait count.
- Fix: give session a cols parameter (the existing callers passing 80) and drop sized_session.

## offset_refusal reassigns bad and compares abs (float-placement, quality advisory)

- Where: `carat/domain/float_spec.rb:57`, `offset_refusal`.
- Why it matters: simplicity: it picks the bad value by reassigning bad and compares row.abs, which is clever and overflows at the minimum integer.
- Fix outline: check each bound directly (row < -OFFSET_MAX or row > OFFSET_MAX, then col) and return the message for the first out of range.

## PluginLink#float_frame's refusal branch is untested (float-placement, quality advisory)

- Where: `carat/use_cases/plugins/plugin_link.rb:276`.
- Why it matters: tests beside behavior: the refusal branch (a disabled plugin answering FloatFrame.failure) is untested; `test/editor_floats.rb` calls WindowRequests#float_frame directly.
- Fix outline: add an assertion through the link for an enabled and a disabled plugin.

## WindowRequests#float_frame takes a name it never reads (float-placement, quality advisory)

- Where: `carat/use_cases/plugins/window_requests.rb:260`.
- Why it matters: dead parameter: float_frame takes name and never reads it.
- Fix outline: drop it from WindowRequests#float_frame and its PluginLink call, or say in the comment that it keeps the request family's shape.

## The frame presenter's class comment wraps unevenly (float-placement, quality advisory)

- Where: `carat/adapters/frame_presenter.rb:90`.
- Why it matters: style: the class comment line ending "in FloatTitle. The notifications follow at the top right in the same" runs past the file's wrap width while the next lines break short.
- Fix outline: rewrap the paragraph.

## The key hints keep two column guards that disagree (float-placement, quality advisory)

- Where: `carat/use_cases/discovery/show_key_hints.rb:125`.
- Why it matters: duplication: the state.screen_cols < 6 guard and the new limit < 1 check express one rule, and the old one now disagrees with text_room (it refuses a 5-column none screen whose limit is 1, and only limit < 1 protects rounded at 6).
- Fix outline: drop state.screen_cols < 6 from line 125 and keep return if limit < 1 as the single column guard.

## OpenSpec runs unpinned beside the push credentials (sprint-2 sweep security Medium (4))

- Where: `tools/spec_validate.sh:17` runs `npx -y` of the latest OpenSpec release in the spec-validate stage, as the contributor profile and CLAUDE.md do. Periodic security at 8b9bf6a. Pool item `guard-lows`.
- Why it matters: a hijacked or malicious release runs with the delivery session's git push credentials.
- Fix outline: pin one exact version in one place (a Makefile variable) used by the stage, the docs, and the guard's allowlist, with a tools case refusing an unpinned call.

## history and groom skip on records of a branch that never merges (sprint-2 sweep)

- Where: `history` in `tools/run_state.sh:1372` skips a change whose run state records a row on any branch; `groom` retires the sprint marker clone-wide. Periodic quality at 8b9bf6a, raised twice.
- Why it matters: a package-step branch that never merges (a run stopped after three red CI rounds) loses its metrics row, its late findings, or the whole sprint plan for good.
- Fix outline: skip only when the recorded row is on the current base, and retire the marker only once the sprint row reaches the base, with a tools case for a stopped run. Pool item `sprint-tidy`.

## A plugin's tab page switch skips TabList#visit (sprint-2 review)

- Where: `carat/use_cases/plugins/window_requests.rb:132` (the float branch of focus_window) and `focus_at` at line 281 (focus_window, open_file, open_in_split) assign the tab index directly. Sprint-2 review at 8b9bf6a.
- Why it matters: the last tab page is not updated, so `g<Tab>` goes to the wrong tab page after the finder or explorer focuses a window in another tab page, unlike Vim.
- Fix outline: switch through `TabList#visit`, with a row where a plugin focuses a window in another tab page and `g<Tab>` returns. Pool item `definitions-tidy`.

## The % motion repeats the text objects' bracket walk (sprint-2 sweep)

- Where: `match_pair` and `pair_kind` in `carat/domain/motions.rb:630` against `find_opener` and `find_closer` in `carat/domain/text_objects.rb:251` and `:268`. Periodic quality at 8b9bf6a, raised twice.
- Why it matters: two nested bracket walks in two forms (bytes against Walker) can drift apart.
- Fix outline: one bracket matcher in Motions, which TextObjects already requires, used by `%` and the pair objects, with the existing rows held.

## Docs drift found at 8b9bf6a

- Where: `docs/codebase-map.md` line 161 (BufferHandler omits `buffer.alternate`), 125 (Messages omits E16, E444, invalid_argument, unsaved_buffer), 121 (show twice), 47 (a stray `;,`), 364 (FloatWindow omits frame_width and text_room), 464 (StatusSlots omits set_lsp and label), 331 and 303 (Selection and LastChange methods); `README.md:5` lacks `%` and `<C-^>`; `docs/architecture.md:126` lacks `%` and `{count}%`. Sprint-2 review and sweep.
- Why it matters: the map and README lag jump-motions, tab-keys, and float-edges.
- Fix outline: update those lines. Pool item `docs-index`.

## Tooling headers and double negatives found at 8b9bf6a

- Where: `tools/rules.sh:1` header omits RECORDS_RE; `tools/ci_scope.sh:45` and the groom dispatch in `tools/run_state.sh:1691` write `! cmd || return`. Sprint-2 review and sweep.
- Why it matters: the header no longer names what three scripts source it for, and the double negatives read backwards.
- Fix outline: name RECORDS_RE in the header and write both as plain `if` tests.

## Small code findings of the sprint-2 review and sweep at 8b9bf6a

- Where: `carat/use_cases/actions/tab_handler.rb:47` ties the tabline flag to a name's position (`i > 2`); `carat/domain/tab_list.rb:86` next_tab returns a bool no caller reads (a BOOL_COMMANDS entry kept for it); `carat/plugins/finder/plugin.rb:153` no_paths misnamed and the OPEN literal repeated at 79 and 87; `carat/use_cases/discovery/follow_palette.rb:103` trims the colon twice; `carat/domain/command_grammar.rb:139` accept and accept_visual share a start; `carat/domain/runs.rb:18` names a parameter cls; `carat/domain/buffer.rb:387` repeats initialize's empty line; `carat/domain/transaction.rb:297` merged? changes state; comments past the wrap in `carat/use_cases/handle_key.rb:65`, `carat/use_cases/discovery/show_key_hints.rb:23`, `carat/use_cases/completion/show_completion.rb:25`, `carat/use_cases/completion/show_completion_docs.rb:146`.
- Why it matters: copies, unclear names, and dead returns the naming and wrap rules forbid.
- Fix outline: a tablines array, a void next_tab, the renames, one private helper per copy, and the rewraps, each in its domain's batch.

## menu-hints quality advisory at carat/use_cases/discovery/show_key_hints.rb:112

Location: `carat/use_cases/discovery/show_key_hints.rb:112`. Why: `segment` passes the empty literal `heads = []` to `collect_heads`, which appends Strings to it, the open pitfall of `docs/spinel-notes.md` where an empty literal is typed `Array[Integer]` and a callee's appends may be dropped. Fix outline: have `collect_heads` return the array it fills and the caller assign the result, as `Config#merge_runs` does.

## menu-hints quality advisory at carat/domain/keymap_node.rb:76

Location: `carat/domain/keymap_node.rb:76`. Why: dead code; `ShowKeyHints` no longer shows `+N`, so `KeymapNode#binding_count` has no production caller left (only `test/domain_keymap.rb:262` and the map entry at `docs/codebase-map.md:149`). Fix outline: remove the method, its assertion, and its map mention.

## menu-hints quality advisory at carat/use_cases/discovery/hide_key_hints.rb:7

Location: `carat/use_cases/discovery/hide_key_hints.rb:7`. Why: docs currency; the class comment says `HandleKey` calls it only while the hints show, but `ShowKeyHints#call` now calls it unconditionally before every show. Fix outline: name both callers and say it does nothing while no hints show.

## menu-hints quality advisory at carat/domain/float_window.rb:16

Location: `carat/domain/float_window.rb:16`. Why: docs currency; the `centered` member's comment names the palette as the centered float, and the key hints panel now sets `centered` too. Fix outline: name the palette and the key hints.

## menu-hints quality advisory at carat/use_cases/discovery/show_key_hints.rb:131

Location: `carat/use_cases/discovery/show_key_hints.rb:131`. Why: a prefix of plugin actions (`plugin.NAME.ACTION`) always reads `plugin`, even for one plugin's actions, which names the mechanism and not what the keys do. Fix outline: for a plugin action take the segment after `plugin.`, or state the choice in the key-hints spec.

## menu-hints quality advisory at carat/use_cases/handle_key.rb:145

Location: `carat/use_cases/handle_key.rb:145`. Why: one way to do each thing; `HandleKey` still guards with `@key_hints.showing?` before `HideKeyHints#call`, which checks `showing?` itself, while `ShowKeyHints` now calls it with no guard. Fix outline: call `@hide_key_hints.call(state)` without the guard, so the check lives only in `HideKeyHints`.

## Findings of palette-rows (quality advisories)

### carat/domain/fuzzy_match.rb:48 positions duplicates the score walk

Duplication: positions repeats score's part loop and follow's inner walk byte for byte, so the two can drift apart. Fix: one private walk that fills an optional positions list and returns the runs, score and positions both calling it.

### carat/use_cases/discovery/follow_palette.rb:177 styles re-derives the palette row layout

Duplication: styles re-derives the layout rows already built (room at 159 and 180, the name cut again, the description column's start from the padding arithmetic). Fix: build each row's tokens in the rows loop from the cells it just padded, or share one column helper.

### carat/use_cases/discovery/follow_palette.rb:235 private code point count in a use case

Duplication: char_count re-implements the code point count Domain::MarkdownText.char_count and Domain::Utf8.size_at already give, in a use case. Fix: add a prefix count to Domain::Utf8 (or call MarkdownText.char_count on the byteslice) and drop the private copy.

### carat/domain/buffer.rb:58 styles comment names only the documentation buffer

Docs currency: the styles comment (and FramePresenter#paint_float_row's at carat/adapters/frame_presenter.rb:628) still say styles belong to a documentation buffer, while the palette's menu buffer now carries them. Fix: say a styled float's rows (documentation or palette menu).

### openspec/specs/command-palette/spec.md:9 wide-key scenarios name another action than the test

Spec and test drift (cited at the change's delta spec, now synced into the main spec): the scenarios A key of wide characters and A key with combining marks bind window.split, but test/editor_palette.rb:250 binds insert.newline. Fix: make the scenarios name insert.newline (or the test bind window.split).

### carat/use_cases/discovery/follow_palette.rb:193 ex command colon skip in mark untested

Test gap: the skip path of mark for an ex command's leading colon (a match on :write, offset by one character) has no test. Fix: add an editor_palette case typing an ex name and checking the marked cells start after the colon.

### carat/use_cases/discovery/follow_palette.rb:94 score and field repeat one comparison

Simplicity: score and field each repeat the a >= b comparison. Fix: one if a >= b branch setting both.

### docs/codebase-map.md:170 editor_palette test description is stale

Docs currency: the Tests line still describes test/editor_palette.rb as opening, filtering, selection, and running, without the row layout and match marking it now covers. Fix: add the columns, caret keys, and match groups to that description.

### test/editor_palette.rb:131 wide_session duplicates plugin_session

Duplication: wide_session repeats plugin_session line for line except the plugin it passes. Fix: give plugin_session the plugin as a parameter and call it with Wide.new and Carat::Plugins::Hello::Plugin.new.

### carat/domain/fuzzy_match.rb:69 positions matches multibyte queries by byte

Correctness, pre-existing and outside this change's fix: positions compares bytes, so a multibyte query's continuation bytes can match inside another character and FollowPalette#mark then paints that character ("日" on "本語日" matches E6 in 本 and 97 A5 in 日, marking both). Fix: step the word by whole characters (Domain::Utf8.size_at) and compare each query character's bytes as a unit, with a FuzzyMatch test of such a word.

## Findings of top-rows

### Quality: the winbar row of the compatibility table names the old separator, docs/compatibility.md:587

- Why: docs currency; the winbar row still says the symbols are joined by ` > `, while the winbar now joins them with ` › `.
- Fix: say ` › `, and ` > ` under `option.icons ascii`.

### Quality: the tab bar's modified-mark fallback cannot trigger, carat/adapters/tab_bar.rb:137

- Why: speculative generality; the `mark(set)` fallback to the ASCII mark cannot trigger, since every shipped set's modified glyph is one cell and the sets are constants, yet it measures the glyph for each modified tab on every frame.
- Fix: drop the fallback and add a test that each set's modified glyph measures one cell, or test the fallback through a wide glyph.

### Quality: the modified-mark width table does not prove the change, test/adapters_tab_bar.rb:105

- Why: the table passes unchanged on main's code because every shipped mark is already one cell, it compares `String#index` character offsets rather than cell columns, and its labels nerd, unicode, and ascii do not name the scenario in the snapshot.
- Fix: label the rows `<set>: the modified mark keeps the tab's width` and compare the cell column of b.txt's first cell.

### Quality: the slot header's shown view shares the accent without a word in the docs, carat/adapters/frame_presenter.rb:916

- Why: undocumented side effect; the slot header row's shown view also uses `TabLineSel` and so becomes the bold blue block, but the proposal, design, and README list only the tabs, the tab-page numbers, and the winbar as sharing the accent.
- Fix: name the slot header in the design and README, or confirm it is intended.

## spinel-rebump quality advisory at carat/domain/ex_range.rb:46

Tests beside every behavior change: the new `Utf8.boundary` calls in `ExRange` and `MarkdownText` (`carat/domain/markdown_text.rb:53` and `:277`) have no test row, so dropping one brings the `IndexError` back unseen on text that is not UTF-8. Fix outline: add a row each, an ex range with a 0x80 after a comma and a markdown body with a 0x80 after a newline and after a `](`.

## spinel-rebump quality advisory at carat/domain/rpc_framer.rb:68

Tests beside every behavior change: only the header-line loop (line 106) is tested; the `read_header` search from `@start` on a continuation byte, the one in the language-server reader thread, has no row, so a regression there would raise in the reader thread unseen. Fix outline: add a framer row whose second frame's header starts with 0x80 right after the first body.

## spinel-rebump quality advisory at carat/use_cases/plugins/file_requests.rb:4

Match the existing style: the domain require is wedged between the `../files` use-case requires instead of grouped with the inner-layer requires, which hides the layer order the requires otherwise show. Fix outline: move it up beside `plugin_api` and `ports/file_port`.

## spinel-rebump quality advisory at carat/domain/utf8.rb:54

One clear way to do each thing: the boundary rule is applied by hand at seven `byteindex` call sites and only `docs/spinel-notes.md` states it, so the next `byteindex` with an offset can bring the `IndexError` back. Fix outline: a `test/lint.rb` rule refusing a `byteindex` or `byterindex` call with an offset argument not wrapped in `Utf8.boundary` (exempting the inlined copy in `PluginApi::Paths.segments`).

- quality advisory (carat-palette) test/adapters_screen_presenter.rb:337 spec drift: the unmodified scenario 'The theme paints' (openspec/specs/color-themes/spec.md:105) names one_dark and \e[0;38;5;249;48;5;236m, but its test now draws the default carat-dark and asserts 252;234, so after archive the scenario is proved by no test. Fix: add 'option.theme one_dark' to the harness config and keep the one_dark sequence, or modify the scenario to carat-dark in a delta.
- quality advisory (carat-palette) test/adapters_screen_presenter.rb:358 spec drift: the 'Status line' scenario (openspec/specs/color-themes/spec.md:68) names carat-dark, which was one_dark's alias and is now its own palette, while its test row still draws one_dark. Fix: draw the row with carat-dark and its StatusLine colors, or modify the scenario to one_dark in a delta.
- quality advisory (carat-palette) docs/compatibility.md:517 docs accuracy: the corrected sentence lists the thirty syntax, thirteen file-icon, and six markup groups after '56 UI groups:', as if they were among the 56, which are Neovim's 41, the status bar's eight, the two indent guides, FloatTitle, and four popup menu groups. Fix: say '56 UI groups (Neovim's 41, then ...), plus thirty syntax, thirteen file-icon, and six markup groups'.
- quality advisory (carat-palette) carat/domain/themes.rb:460 duplication: with the alias table gone, canonical repeats known?'s NAMES.include? test. Fix: write it as 'known?(name) ? name : DEFAULT' or fold it into find.
## Palette tokens shift on a description that is not UTF-8

- Where: `char_count` in `carat/use_cases/discovery/follow_palette.rb:240`. Sprint-3 quality review.
- Why it matters: `char_count` counts every byte that is not a continuation byte, while the frame decodes token columns with `Utf8`, which counts a lone continuation byte or a broken sequence as one replacement character each, so a plugin description holding such bytes shifts its `PmenuMatch` and `PmenuExtra` tokens by one or more columns.
- Fix outline: count characters the way the decoder does (one shared count beside `Utf8.size_at`), with a palette test whose description is not UTF-8. Queue item `palette-tidy`.

## Cursor-anchored floats lose two columns to the centered-float margin

- Where: `text_room` in `carat/domain/float_window.rb:54`, called by `ShowHover`, `ShowSignature`, and `OpenDefinitionFloat`. Sprint-3 quality review.
- Why it matters: `text_room` always subtracts twice the margin, but cursor-anchored floats get no margin from `place`, so they come out two columns narrower than the screen allows, against the comment "Every float sized to the screen asks this".
- Fix outline: size by the float's anchor, or document that cursor floats give up the two columns, with a hover row at the screen's width. Queue item `hover-tidy`.

## The Spinel boundary guards in ExRange and MarkdownText have no test

- Where: `carat/domain/ex_range.rb:46`, `carat/domain/markdown_text.rb:53` and `:277`. Sprint-3 quality review of `spinel-rebump`.
- Why it matters: under the pinned Spinel a `byteindex` from a continuation byte raises `IndexError` without the `Utf8.boundary` guard; `RpcFramer`, `TextLines`, `VimPattern`, `Paths`, and `read_file` each got a regression row, these three did not, so removing a guard passes the suite.
- Fix outline: rows in `test/domain_ex_range.rb` (a range such as `1,` then a continuation byte) and `test/domain_markdown_text.rb` (a continuation byte after a newline and inside a link target). Queue item `spinel-workarounds`.

## Nothing enforces Utf8.boundary on an offset byteindex

- Where: `carat/domain/utf8.rb:54`; `carat/plugin_api.rb:347` repeats the loop inline. Sprint-3 quality review of `spinel-rebump`.
- Why it matters: a new `byteindex(needle, offset)` call that skips `Utf8.boundary` raises under the pinned Spinel on a continuation byte, and only memory keeps the rule.
- Fix outline: a `test/lint.rb` rule refusing a `byteindex` with an offset argument outside `Utf8.boundary`, the `plugin_api.rb` copy allowed. Queue item `spinel-workarounds`.

### Restrict the open-pr edit path to same-repository pull requests (security Low, confidence 4)

- Where: `tools/open_pr.sh:190`
- Why it matters: the new edit path picks the open pull request by bare branch name, and `gh pr list --head` matches the ref name for any owner, so a fork's pull request with the same head ref name opened before open-pr runs gets pr.md's title and body written onto it with PR_TOKEN instead of the delivery's own being opened. It needs a trusted push and only changes pull request text; the reviewed code and the merge gates are unaffected.
- Fix outline: have `gh pr list` return `number` and `isCrossRepository`, keep only same-repository pull requests (refuse when there are none or more than one), then call `gh pr view` and `gh pr edit` with that number instead of the branch name.

### One title and body equality helper in open_pr.sh (quality advisory)

- Where: `tools/open_pr.sh:186`
- Why it matters: the title and body equality test is written twice, in the early exit and in the read-back loop, so the two can drift.
- Fix outline: one `same_text DIR` helper used by both.

### Drop the duplicated contributor size test (quality advisory)

- Where: `tools/tools_test.sh:2499`
- Why it matters: the contributor size test repeats the new docs_lint budget and greps its literal line, so a budget change must be made twice.
- Fix outline: rely on the docs-lint budget and drop the test, or keep only the size check.

### Read the scan red right after a body push as pending (quality advisory)

- Where: `.claude/workflows/deliver-change.js:1094` and `.claude/workflows/deliver-change.js:1102`
- Why it matters: after the body push the merger can read the synchronize scan red before open-pr edits the text and reruns scan (spin skips a records-only diff, so checks finish fast); with bodyFixed set that red becomes a fix round.
- Fix outline: have body mode poll until the pull request text equals pr.md, or read a body-only red right after a body fix as pending once.

### One settlePackage helper for the wait and package branches (quality advisory)

- Where: `.claude/workflows/deliver-change.js:1018`
- Why it matters: the wait and package branches repeat the same pr, stop, and phaseDone tail, and the step is named merge when the run already stopped.
- Fix outline: one `settlePackage(done)` helper for both branches and a skip step word for a stopped run.

## Findings of spinel-compile-time

### docs/spinel-notes.md:47: the compile-time check of a Spinel bump has no place in the bump procedure

The new rule that a bump past 2440954d1 is checked for compile time is not in the bump procedure: the SPINEL_REF comment (Makefile:16) and the CLAUDE.md Commands toolchain bullet still say only after make check passes, nothing measures compile seconds (analysis-budget only warns on analysis ms), and Makefile:79 still cites 22 to 26 s of analysis against the 47.2 s and 106.7 s spinel-compile-time measured. Why: the next bump can reintroduce the regression unnoticed. Fix: name the compile-time comparison (test-build and diagnose seconds) in the SPINEL_REF comment and the CLAUDE.md toolchain bullet, or record test-build seconds as a metric, and refresh Makefile:79.
- Merged: ### docs/spinel-notes.md:47: the Spinel regression bullet mixes terms, stale advice, and dated figures
- Location: docs/spinel-notes.md:47 and the comment at carat/testing.rb:52 (merged at the sprint-11 grooming from four quality advisories on the one bullet).
- Why: the bullet calls the rebuilt structure both the position map and the load record; it still advises an element reader (Array[untyped], Integer) -> T although a bare reader given an untyped argument narrows nothing; it records 125 runner rebuilds at 93d7883b without saying why the bump was accepted against the old pin's 39; and it names a pin ("stays at its parent 6af548c9") and grows a dated figure per bump, so every bump makes it false (the pin is c0502112 since #151).
- Fix outline: rewrite the bullet once: one term, load record, as SP_TIMING names it (also in carat/testing.rb:52); the reader must narrow with is_a?(Array) as Carat::Json.element does; keep the rule (no [] on an untyped receiver; read through Testing#cell, Testing#cases, Carat::Json.field, element, reach) and the current figures only, saying compile time (test-build 169 s, diagnose 219 s) met the target; "6af548c9, its parent, is the newest commit without it"; leave the pin to SPINEL_REF and the history to the archived changes.

### docs/spinel-notes.md:55: the open notes were not rechecked at the new pin 6af548c9

The header (line 3) says open notes are rechecked when the pin is bumped, but this pin move leaves lines 15-16 and 48-61 at Rechecked at f34005bf or new at f34005bf, and the f34005bf workarounds cited in docs/architecture.md:197, carat/domain/mode.rb:58, carat/ports/file_port.rb:41, and carat/plugin_api.rb:657 are not said to hold at 6af548c9. Why: a note that no longer holds keeps a workaround alive or hides a pitfall. Fix: recheck the open notes at 6af548c9 in a follow-up and update their Rechecked lines.

### docs/spinel-notes.md:21: the byteindex IndexError rule describes a commit after the pin without a recheck marker

The file's opening says each note holds at the pinned compiler, but the byteindex IndexError rule now describes 84aa303b1, after the pin 6af548c9, with no recheck marker like the other notes about other commits. Why: a reader takes it as true at the pin, which it is not. Fix: mark it as not at the pin and rechecked when a bump passes 84aa303b1, the reason Utf8.boundary is kept.

## Findings of untyped-elephant, non-blocking

### Rename the private element reader list in carat/testing.rb:83

- Location: carat/testing.rb:83 (quality advisory, naming).
- Why: the private element reader `list` reads as a collection constructor and shares its name with `FilePort#list`, which `DiskFiles` and `MemoryFiles` implement, the shared-name shape `docs/spinel-notes.md` warns can leave calls unresolved.
- Fix: rename it after what it returns, for example `array_cell`, beside `cell`.

### Split the golden table-test sentence in docs/examples.md:55

- Location: docs/examples.md:55 (quality advisory, docs clarity).
- Why: the inserted clause about `t.cases` when every input is an array literal, so the block indexes a typed array, turns the golden table-test sentence into a run-on list.
- Fix: move `cases` into its own sentence after the one describing `t.table`.

### Stop glob expansion of changed paths in tools/ci_scope.sh:95

- Location: tools/ci_scope.sh:95 and tools/ci_scope.sh:119, the loops over `$changed` and `$since` (security Low, confidence 4, existing code).
- Why: the unquoted path lists get word splitting and wildcard expansion, so a fork pull request can add a code file named like a wildcard (for example `docs/[a-z]*`) that expands to existing documentation; the scope step then answers run=false and the required spin check passes without running the tests.
- Fix: run `set -f` before the loops (or read `git diff --name-only -z` and handle each NUL-separated path), and add a tools-test case with a wildcard path asserting run=true.

### Read changed paths without splitting in tools/ci_scope.sh:96

- Location: tools/ci_scope.sh:96, `for path in $changed` (quality advisory, pre-existing in the touched script).
- Why: a path with glob characters (`notes[.]md` beside `notes.md`) expands against the checkout and a path with spaces splits, which can count a code file as documentation and skip the tests.
- Fix: `set -f` before the loops, or read the paths with `while IFS= read -r path`.

### Exercise the head tree and check-run filters in tools/tools_test.sh:172

- Location: tools/tools_test.sh:172, the ci_scope error cases (quality advisory, tests).
- Why: the new cases fail only the number query or every query (where head fails first), so the hex filter on head_tree and the digits filter on passed in the push branch are never exercised.
- Fix: add `err_scope tree.sha` and `err_scope check-runs` expectations asserting run=true.

### Query the commit's pull request once in tools/ci_scope.sh:76

- Location: tools/ci_scope.sh:76 (quality advisory, duplication).
- Why: the same endpoint `repos/$REPO/commits/$SHA/pulls` is called twice for head.sha and number, doubling the request and letting the two answers disagree.
- Fix: one call with `--jq '.[0] | "\(.head.sha) \(.number)"'`, split and validated once.

### Keep the case pattern for the sha test in tools/ci_scope.sh:107

- Location: tools/ci_scope.sh:107 (quality advisory, simplicity).
- Why: `[ -n "$(hex "$sha")" ]` replaces an in-process case test with a command substitution per listed sha only to test a pattern.
- Fix: keep the case pattern there, or give the filters a predicate form for checks that need no value.

### Make each ci_scope expectation stand alone in tools/tools_test.sh:170

- Location: tools/tools_test.sh:170 (quality advisory, test independence).
- Why: `well_formed` reads `$work/scope-out` left by the preceding `err_scope` expectation, so each pair depends on its order.
- Fix: have one helper run `err_scope` and then check the file, so each expectation stands alone.

### Drop the extra blank line in tools/tools_test.sh:188

- Location: tools/tools_test.sh:188 (quality advisory, style).
- Why: the added ci_scope block ends with a blank line before the existing one, leaving two blank lines before the green_pr comment where the file uses one.
- Fix: drop the extra blank line at 188.

### Define merge_hook once in the guard hook tests

- Location: tools/tools_test.sh:1575 (quality advisory, duplication; also reported at 1562 against an earlier revision).
- Why: the merge-hook case inlines a copy of merge_hook (defined at 1647) with its own GIT_CONFIG_COUNT env instead of answered, so the two copies can drift.
- Fix: define merge_hook once above the hook cases, wrapped in answered, and call it from the merge-hook case.

### Stop hardcoding the hook count in the main-resolution check

- Location: tools/tools_test.sh:1538 (quality advisory, brittle check; also reported at 1534).
- Why: the check that every hook line resolves main the same way hardcodes ^10 1$, so adding an agent or a hook fails it with no drift.
- Fix: assert only that the unique count is 1 and that the line count equals the number of command: lines under .claude/agents.

### End the workflow-trim sentence in planner.md with a period

- Location: .claude/agents/planner.md:26 (quality advisory, docs).
- Why: trimming the workflow-trim example left 'which the contributor chooses: A sprint item', a dangling colon before a new sentence.
- Fix: end the sentence with a period.

### Make room in the planner and contributor agent files

- Location: .claude/agents/planner.md:1 and .claude/agents/contributor.md:1 (quality advisory, docs budget).
- Why: planner.md is 8189 of 8192 bytes and contributor.md 6996 of 6999 after the longer hook line, so the next edit to either must trim again.
- Fix: plan a pass moving restated rules to CLAUDE.md pointers before the next agent-file change.

### Restore the dropped contributor instructions or correct the guard-ref-pin proposal

- Location: .claude/agents/contributor.md:18 (quality advisory, docs; also reported at 26).
- Why: the trim drops instructions ('Every change goes through OpenSpec, however small'; 'For Ruby code, docs/examples.md and docs/spinel-notes.md first'; why no session edits a pull request with a tool) while the proposal says no instruction of either agent changes; CLAUDE.md still covers them.
- Fix: keep a short pointer to docs/examples.md and docs/spinel-notes.md, or correct the proposal's claim.

### Reword the superseded task 1.1 of guard-ref-pin

- Location: openspec/changes/archive/2026-11-14-guard-ref-pin/tasks.md:5 (quality advisory, docs currency).
- Why: task 1.1 still describes the superseded design (config-free git ls-remote, a local fetch without writing a ref, the guard read at that commit), which task 1.3 replaced, so the archived change contradicts the hook lines.
- Fix: reword 1.1 to the temporary-repository fetch, or mark it superseded by 1.3.

### Check the hook runs before the empty TMPDIR assertion

- Location: tools/tools_test.sh:1597 (quality advisory, vacuous test).
- Why: the two hook runs before it discard their status and output, so if the hook failed before mktemp, or mktemp ignored TMPDIR, the empty directory still passes.
- Fix: wrap the two runs in expect with their 0 and 2 statuses, or assert the directory was used.

### Remove the hooks' temporary repository on interruption

- Location: .claude/agents/checker.md:12 and every agent hook line (quality advisory, cleanup on interruption).
- Why: the temporary repository is removed only on the normal path, with no trap, so a hook killed during its fetch of about a second leaves a directory under TMPDIR on every such call.
- Fix: add trap 'rm -rf "$d"' EXIT after mktemp if the byte budgets allow, or accept it and say so in the design's Risks.

## Findings of the sprint-4 review and sweep

### carat/domain/utf8.rb:49: the byteindex guard comment cites the wrong Spinel commit

- Location: carat/domain/utf8.rb:49, carat/plugin_api.rb:345, docs/spinel-notes.md:21 (spinel-rebump and spinel-compile-time quality advisories, merged by the sprint-4 grooming).
- Why: the comments date the `byteindex` refusal of a continuation offset to 6b43fe94 and describe it as current, while 84aa303b1 introduced it and the pinned 6af548c9 does not raise, so a reader bisecting starts wrong or takes the guard for dead code.
- Fix: say Spinel refuses it from 84aa303b1, after the pin, and the guard is kept for that bump, in all three places.

### Fork pull requests sharing the branch name block open_pr.sh (security Low (5))

- Location: tools/open_pr.sh:180 (sprint-4 review and sweep, security Low (5)).
- Why: `gh pr list --head` counts fork pull requests with the predictable head name while view and edit by branch resolve only the same-repository head, so any user can make the count wrong (open refused) or have the title and body edit target the wrong one with PR_TOKEN.
- Fix: count only same-repository heads, resolve one number, pass it to view and edit; a tools_test case with a cross-repository stand-in.

### The check clone shares a writable toolchain (security Low (5))

- Location: tools/run_state.sh:571 (sprint-4 sweep, security Low (5)).
- Why: the check clone symlinks tmp/.toolchain and tmp/.spinel of the delivery clone, so a stage running branch code can overwrite the spinel binaries, persisting into later checks and agent make runs.
- Fix: make the toolchain read-only after install, or verify a checksum of tmp/.toolchain/bin before each stage.

### CI runs the branch's own scope script (security Low (6))

- Location: .github/workflows/ci.yml:58 (sprint-4 sweep, security Low (6)).
- Why: the scope step runs the pull request's tools/ci_scope.sh, so a branch can answer run=false and turn the spin check green without tests.
- Fix: run main's ci_scope.sh from a base checkout, as scan.yml does with its scanner.

### Sentence motions loop once per count past the last sentence

- Location: carat/domain/motions.rb:488 and :520 (sprint-4 sweep, quality blocking).
- Why: sentence_forward and sentence_backward rescan every start once per remaining count, O(count x starts), so `999999999)` freezes the editor where word motions stop at the buffer edge.
- Fix: stop when no start is found and resume from the last one; a large-count row in test/editor_motions.rb.

### The body-fix path can read a stale scan run

- Location: .claude/workflows/deliver-change.js:1102 (sprint-4 review, quality).
- Why: the body mode pushes pr.md as a CI fix whose scan run reads the old body and goes red before open-pr edits the body, so a merger reading checks in that window returns red with bodyFixed true and the run falls into a fix round.
- Fix: wait until the open pull request's title and body equal pr.md's before returning, or have the merger ignore a scan run older than the last edit.

### The wait and package blocks repeat three lines

- Location: .claude/workflows/deliver-change.js:1015 (lines 1018-1020 and 1030-1032; sprint-4 review, quality).
- Why: packagedPr, the no pull request stop, and phaseDone package are written twice.
- Fix: one helper taking the contributor result.

### Testing#cases accepts a row whose input is no array literal

- Location: carat/testing.rb:66 (sprint-4 review, quality).
- Why: such a row compiles with the wrong typing and no warning.
- Fix: test/lint.rb flags a `t.cases` row whose second element is not an array literal.

### The contributor budget is enforced twice

- Location: tools/docs_lint.sh:48 and tools/tools_test.sh:2540 (sprint-4 review, quality).
- Why: tools_test checks the size under 7000 and greps docs_lint for the budget line, so the limit lives in two places.
- Fix: keep it only in BUDGETS and drop the tools_test copy.

### The contributor's test and recording rule lost a word

- Location: .claude/agents/contributor.md:22 (sprint-4 review, quality).
- Why: the condensed sentence drops "disable" and the note that agent_guard.sh refuses both, and reads as if a phase or review may be recorded through `run_state.sh push`.
- Fix: restore "disable" and split the test rule and the recording rule into two sentences.

### The timeout path's magic numbers and dead clear

- Location: carat/use_cases/handle_key.rb:378 and :224 (sprint-4 sweep, quality advisory).
- Why: `code == 40 || code == 44` spells ( and , as numbers; clear_message inside the list_message? branch repeats the unconditional call at :227.
- Fix: named constants; drop the inner call.

### The tabstop fallback is re-spelled beside Options#tab_width

- Location: dispatcher.rb:112, leave_insert.rb:69, repeat_last.rb:104, visual/extend_visual.rb:54, arrange_view.rb:43, insert_tab.rb:22 under carat/use_cases/, and carat/domain/operators.rb:172, 251, 272 (sprint-4 sweep, quality advisory).
- Why: `tabstop > 0 ? tabstop : 8` repeats Options#tab_width (options.rb:130), and Options already refuses a tabstop below 1, so the fallback is dead.
- Fix: call options.tab_width, and one shift width helper for the operators.

### ActionTable#register drops a duplicate silently

- Location: carat/use_cases/actions/action_table.rb:34 (sprint-4 sweep, quality advisory).
- Why: register returns false for a known name and all 68 callers ignore it, so a second registration vanishes.
- Fix: raise or note a startup problem; a test in test/use_cases_actions.rb.

### accept_visual repeats accept's preamble

- Location: carat/domain/command_grammar.rb:163 and :138 (sprint-4 sweep, quality advisory).
- Why: the want check, remember, and search branch are copied.
- Fix: a shared private preamble returning the early result.

### The key decoder repeats final-byte cases and loses a key after invalid UTF-8

- Location: carat/adapters/key_decoder.rb:148 and :212 (sprint-4 sweep, quality advisory).
- Why: csi_key copies ss3_key's ten cases; a lead byte followed by a non-continuation (C3 41) consumes the whole length, losing the ASCII key.
- Fix: csi_key handles 126 and passes the rest to ss3_key; on an invalid sequence emit U+FFFD for the lead byte alone.

### InputController calls handle twice

- Location: carat/adapters/input_controller.rb:128 (sprint-4 sweep, quality advisory).
- Why: the start-screen branch and the fall-through each call handle(state, @decoder.feed(bytes)).
- Fix: dismiss the start screen if showing, then one handle call.

### Operate and RepeatLast copy EditorState#clamp_col

- Location: carat/use_cases/operate.rb:204, carat/use_cases/repeat_last.rb:116, carat/domain/editor_state.rb:97 (sprint-4 sweep, quality).
- Why: two private clamps duplicate clamp_col.
- Fix: call state.clamp_col and delete both.

### gen-config repeats its write-if-changed block

- Location: bin/carat-gen-config.rb:87 and :96 (sprint-4 sweep, quality advisory).
- Why: the block is written twice.
- Fix: one write_if_changed(path, text, summary).

### The development compile is copied in three targets

- Location: Makefile:245, :279, :336 (sprint-4 sweep, quality advisory).
- Why: dev-build, test-build, and bench-budget repeat SP_TIMING, the timing filter, the failure message, and UNIT_SUMMARY.
- Fix: one define dev_compile called by the three.

### toolchain-clean removes all of tmp

- Location: Makefile:182 (sprint-4 sweep, quality advisory).
- Why: `rm -rf tmp` also deletes linked worktrees and tmp/scout, leaving stale worktree records, against its help text.
- Fix: remove SPINEL_SRC and PREFIX only, or run git worktree prune after.

### make help and tool headers drift from the code

- Location: Makefile:454 and :379, tools/tools_test.sh:2-12, tools/docs_lint.sh:19, tools/gates.sh:36 and :62, tools/run_state.sh:137 (sprint-4 sweep, quality advisory).
- Why: help omits ten variables and three tested scripts; docs_lint says 1 to 5 sprint items where it accepts 0 to 5; gates omits FAST_STAGES; run_state's usage splits the review-due entry around ci-stages and tokens.
- Fix: correct each text.

### open_pr.sh's wait step, double read, and branch pattern

- Location: tools/open_pr.sh:121, :82, :45 (sprint-4 sweep, quality).
- Why: WAIT_STEP=0 passes its check and wait polls forever; two gh pr view calls read title and body; BRANCH_RE copies agent_guard.sh:101 with no equality case.
- Fix: require a step from 1; one view call; a tools_test equality case.

### The gates split file lists on spaces

- Location: tools/gates.sh:224 and :299 (sprint-4 sweep, quality advisory).
- Why: the snapshots and scenarios loops split paths on spaces, so the scenarios gate skips a delta spec whose path holds one and fails open.
- Fix: read paths line by line as gate_content does.

### metrics compare ignores a missing figure

- Location: tools/metrics.sh:86 and :55 (sprint-4 sweep, quality).
- Why: compare walks only CURRENT, so a base scenario with no current line passes; line 55 splits fields unquoted, so a ? field globs.
- Fix: fail each strict base name not seen; read the fields with read.

### make bench skips four scenarios

- Location: bench/run.sh:69, bench/keys.rb:118, 119, 143, 145 (sprint-4 sweep, quality).
- Why: the default list is a hand copy that left out lh-float, lh-winbar, n, and palette, though the header says every scenario runs.
- Fix: loop over the names build/bench/keys prints, or add the four.

### spec_validate removes a failed preview

- Location: tools/spec_validate.sh:25 (sprint-4 sweep, quality).
- Why: the header promises a failed preview is kept, but the next active change's run removes build/spec-preview.
- Fix: preview each change under its own directory, or stop removing after a failure.

### Periodic quality slices split areas by count

- Location: .claude/workflows/periodic-review.js:65 (sprint-4 sweep, quality).
- Why: slice 1 holds area 1, about 10,000 lines, which one start cannot read; the sweep left areas 1, 13, 14, 15 unreviewed (covered 14/18).
- Fix: weight slices by line count, or split area 1 in the map.

### The sprint report misreads the sweep

- Location: .claude/workflows/sprint-planning.js:179 (sprint-4 sweep, quality).
- Why: the Sweep line says did not run whenever the security start did not run, though quality slices may have recorded, and never reports quality advisories or unreviewed areas.
- Fix: report the sweep's security and quality separately.

### ListTree copies ProbePath and spells inside? another way

- Location: carat/use_cases/files/list_tree.rb:67 and :98 (sprint-4 sweep, quality).
- Why: probe repeats ProbePath#call, the map's one place asking the port about a path; ListTree calls PluginApi::Paths.inside? where the others use Domain::PathPolicy.inside?.
- Fix: inject probe_path; use one spelling.

### The outside-root message is built in four places

- Location: carat/use_cases/files/resolve_inside.rb:41, make_path.rb:37, rename_path.rb:42, delete_path.rb:39 (sprint-4 sweep, quality).
- Why: four copies of 'Outside the tree root: ' can drift.
- Fix: one PathPolicy method taking cwd and path.

### Test tables pass unconverted values

- Location: test/domain_selection.rb:47 and 49, test/editor_operators.rb:145-147, test/editor_insert.rb:40-42, test/editor_completion.rb:71 (sprint-4 sweep, quality).
- Why: table inputs reach the library unconverted, against the typed-helper rule.
- Fix: convert with .to_s, .to_i, or ints first.

### EditorHarness#windows returns tuples

- Location: carat/doubles/editor_harness.rb:190, 13 call sites such as test/editor_leader.rb:57 and test/editor_tabs.rb:247 (sprint-4 sweep, quality).
- Why: a seven-element array indexed by position, against the typed-readers rule.
- Fix: a small Data value with named readers.

### The map's areas 8, 13, and 15 drift from the code

- Location: docs/codebase-map.md:251, :231, :420, :529, :464, :47, :121 (sprint-4 sweep, quality).
- Why: area 8 omits completion; Registers.unnamed?, ExHandler#ranged?, Paths.absolute, StatusSlots#set_lsp unnamed; the run_state bullet has an unclosed parenthesis; the editor_state bullet names show twice.
- Fix: correct each line.

### Dead display helpers

- Location: carat/domain/display_width.rb:37, carat/adapters/frame_presenter.rb:316 and :321, carat/domain/frame.rb:62 (sprint-4 sweep, quality).
- Why: DisplayWidth.of_char has no caller; display_col and display_width serve one test; Frame#index serves one test while every method inlines it; the map lists them.
- Fix: delete them, move the tests to DisplayWidth.column, update the map (code_cells in of_char's place).

### Frame, status bar, and screen presenter repeats

- Location: carat/domain/frame.rb:36, carat/adapters/status_bar.rb:1 and :47, carat/adapters/screen_presenter.rb:193 (sprint-4 sweep, quality).
- Why: Frame::REPLACEMENT repeats Utf8::REPLACEMENT; an unused plugin_api require; NO_NAME defined in four files (also tab_bar.rb:22, winbar.rb:18, list_buffers.rb:20); two loops inline same_cell?.
- Fix: one constant each, drop the require, call same_cell? unless a bench shows a cost.

### FramePresenter#call is 116 lines

- Location: carat/adapters/frame_presenter.rb:200 (sprint-4 sweep, quality).
- Why: one method sizes, keys floats, draws chrome, the start screen, dirty marks, and places the cursor.
- Fix: move the float-key block (226-239) and the chrome dirtiness loop (289-298) into private methods.

### Plugin docs, SyntaxCache, and comment layout

- Location: docs/plugins.md:70, carat/domain/syntax_cache.rb:42, carat/use_cases/plugins/buffer_requests.rb:49 (sprint-4 sweep, quality).
- Why: the segment priority list omits progress 35; SyntaxCache calls super() then assigns, unlike LineCache; comments mis-indented or past the wrap width (also window_requests.rb:69, status_bar.rb:16, tab_bar.rb:15, frame.rb:15 and :31).
- Fix: add the priority, pass members to super by keyword, rewrap.

### Filetype cuts names by hand and slices by character

- Location: carat/domain/filetype.rb:29 and :81 (sprint-4 sweep, quality).
- Why: from_name repeats Paths.basename and FileIcons.file_type; program_type slices by character with a byte count.
- Fix: Paths.basename and one extension helper; byteslice.

### The language gateway's copies and relative URIs

- Location: carat/adapters/json_rpc_language_gateway.rb:267, :837, :232, :1328 (sprint-4 sweep, quality).
- Why: listed is public for two private callers; send_hover and the cancels copy send_definition; restart copies start's tail; uri_of keeps ./ segments, so one file syncs under two URIs.
- Fix: make listed private; one sender and canceller if Spinel types them; one launch helper; build the URI from PluginApi::Paths.absolute with a test.

### Plugin host strings, focus, and parameters

- Location: carat/use_cases/plugins/plugin_router.rb:77, window_requests.rb:303, plugin_host.rb:189 (sprint-4 sweep, quality).
- Why: answer passes prompt_id uncopied; in_window restores focus only after the block returns, so a raise leaves it moved; follow_prompt takes the state the host keeps.
- Fix: id.dup; restore in ensure; drop the parameter.

### The finder copies the explorer and the explorer loses a followed file

- Location: carat/plugins/finder/plugin.rb:321, 336, 177 and carat/plugins/explorer/plugin.rb:420 (sprint-4 sweep, quality).
- Why: open_path, report, and ignored repeat the explorer's; finish_rename moves @followed only on an exact match, so a file inside a renamed directory keeps its old path.
- Fix: add the shared helpers to PluginApi; rewrite @followed on a path-plus-slash prefix with a test.

## Quality: the merger's hook refuses guard-pin-no-url's own green line until the guard lands

- Location: `.claude/workflows/deliver-change.js:551` (the green line now runs `git hash-object --stdin`) and `tools/agent_guard.sh:549` (the merger's `git hash-object --stdin` allowance, which lands on main only with guard-pin-no-url).
- Why it matters: quality advisory. The merger's hook runs origin main's guard, which refuses `git hash-object`, so the merger's hook refuses guard-pin-no-url's own green line and the run cannot merge it; the design names this bootstrap risk without a plan, and any later change that widens what the green line runs meets the same ordering problem.
- Fix outline: land a green-line command's guard allowance in its own change before the change that runs it, or state in that change's `pr.md` Notes that its one merge is done by the user; for guard-pin-no-url the merge is the user's.

## Quality: byte-trimmed agent prose reads as bare commands the guard refuses

- Location: `.claude/agents/contributor.md:37` (`diagnose-one T=path`, `lint`, `docs-lint`), `.claude/agents/contributor.md:39` (`spec-validate`), and `.claude/agents/planner.md:20` (`then its show <name>`).
- Why it matters: quality advisory. Trimming bytes to stay within the `docs_lint.sh` budgets left target names without their `make`, which read as commands the guard refuses, and left the planner's sentence without its subject; one clear way to do each thing.
- Fix outline: write `make gates spec-validate` at contributor.md:39 and `make test-one T=..., diagnose-one T=..., lint, docs-lint` as one make list at :37, and `then sh tools/run_state.sh show <name>` or `then show <name> of it` in planner.md, making room by pointing to the notes rather than raising a budget.

- untyped-gateway, quality advisory, carat/domain/json.rb:72: duplication: digits? hand-rolls a fourth byte loop beside Parser#digit? (:354, same file) and HistoryCommandHandler.digits? (a one-line regex). Why: four ways to test digits drift apart. Fix: make it text.match?(/\A[0-9]+\z/) as HistoryCommandHandler does, or reuse Parser's digit? instead of the literals 48 and 57.
- untyped-gateway, quality advisory, carat/domain/json.rb:62: object_field and array_element are public although the design's risk mitigation says object_field is called only from field, which verified the Hash. Why: any other caller passes Spinel an unverified Hash. Fix: say in their comment they are reached only through field and element (the codebase has no private_class_method), or fold each [] into a typed local inside field and element.
- untyped-gateway, quality advisory, test/json.rb:71: the check J.field(J.field(read, "a"), "b").is_a?(Hash) ? 1 : nil asks whether an Array is a Hash. Why: it proves nothing about the readers, under a label promising a member of another kind of value is nil. Fix: replace it with J.field(J.reach(read, "a.b"), "c") expecting nil.
- untyped-gateway, quality advisory, docs/spinel-notes.md:47: the same baseline of 1,181 rebuilds is given as 131 s of code generation (untyped-elephant) and then as 152 s (this change), measured on different machines without saying so. Why: a reader compares seconds that are not comparable. Fix: name the machine dependence beside the new seconds or give only the rebuild counts.

## Quality: the ascii icon set is tested three times in carat/adapters/frame_presenter.rb:266

- Location: carat/adapters/frame_presenter.rb:266, beside :217 and :859 (found reviewing carat-glyphs).
- Why: options.icons == "ascii" is evaluated at :217 for the border, again at :266 for the separators and winbars, and once per window at :859 in paint_window, so the one decision is duplicated and repeated per window.
- Fix: compute ascii once at the top of call, reuse it for the border, and pick both separator glyphs there (or keep the row glyph in the one place call already chooses the column glyph).

## Quality: the icon set name "ascii" is a string literal in four places, carat/adapters/status_bar.rb:254

- Location: carat/adapters/status_bar.rb:254, carat/adapters/frame_presenter.rb:217, :266, and :859, beside carat/adapters/options.rb:156 (found reviewing carat-glyphs).
- Why: the set name is compared as a string literal at each site, so a rename or a new set has to find them all.
- Fix: add an Options#ascii_icons? predicate (or an Icons::ASCII_SET constant) and use it at each site so the set name lives in one place.

### Language-service asks have no port (architecture-review H1)

Location: `carat/domain/hover_request.rb`, `definition_request.rb`, `signature_request.rb`, `symbol_request.rb`, `completion_request.rb`; `carat/adapters/editor_assembly.rb` (the `hover`, `definition`, `symbols`, `signature` readers); `docs/architecture.md` section 5.3. Why: completion goes through `CompletionPort` while hover, definition, signature help, and document symbols go through mutable domain records the use cases and `JsonRpcLanguageGateway` both write, two mechanisms for one job; the records hold protocol bookkeeping (request in flight, deadline, serial), so the domain carries adapter state and a second backend or double must mimic the mutations. Fix outline: one `LanguageAskPort` (ask by kind and anchor, answer by kind, `waiting?`) or the `CompletionPort` shape per ask; domain records keep the anchor and answer, the gateway the ids and deadlines; one double for every ask.

### Asynchronous language features have no extension point (architecture-review H2)

Location: `carat/adapters/input_controller.rb:62` (constructor takes `show_completion`, `show_hover`, `show_definition`, `show_signature`, `signature`); `carat/use_cases/handle_key.rb:92-105` (`follow_hover`, `follow_definition`, `follow_signature`, `follow_palette`). Why: each new feature of this kind (references, rename) widens two constructors, the assembly, and the idle and after-key paths by hand, and the order answers are shown or floats followed is implicit. Fix outline: an ordered list of idle steps (`call(state)` answering whether it showed something) and one of after-key followers, filled by each feature's `register` like the action table, so `InputController` and `HandleKey` walk a list.

### Two file-name classifiers (architecture-review R2)

Location: `carat/domain/filetype.rb:8-11` (`EXTENSIONS`, `NAMES`) and `carat/plugin_api.rb:424-481` (`FileIcons::NAMES`, `file_type`). Why: both map a name or extension to a kind (`rb` to `ruby` in each), so a new language is added twice and the two can disagree. Fix outline: one table in `carat/plugin_api.rb` (rank 0) that `Filetype` reads, the icon-only names apart, or `FileIcons` taking the filetype the host already detected.

### The language gateway is one class of 1,373 lines (architecture-review M1)

Location: `carat/adapters/json_rpc_language_gateway.rb`. Why: lifecycle, document sync, diagnostics, progress, and five request kinds share one class, so every language feature edits it, and `docs/architecture.md` section 9.3 expects the plugin gateway to reuse framing and process handling that are woven into the language protocol. Fix outline: extract a JSON-RPC session (ids, pending requests, cancellation, framing over `ProcessPort`) and one small class per request kind, before `plugin-protocol` (roadmap item 13).

### The frame presenter still paints floats, menus, and messages itself (architecture-review M2)

Location: `carat/adapters/frame_presenter.rb` (1,274 lines); `TabBar`, `StatusBar`, `Winbar`, `IndentGuides`, and `PaintedRows` were split out already. Why: floats, the completion menu, the message area, notifications, and the diagnostic line are painted inline, so each new overlay grows the file. Fix outline: move float and menu painting and the message rows into painters on the pattern of `StatusBar`, the presenter keeping the frame swap and the window rows.

### The plugin API file mixes four concerns (architecture-review M3)

Location: `carat/plugin_api.rb` (888 lines): request and response values, the `Host` and `Plugin` bases, `Paths`, and `FileIcons`. Why: it is the one file a plugin author reads, and the API reference is buried among path functions and an icon table. Fix outline: keep `carat/plugin_api.rb` as the one file a plugin requires, requiring one file per concern from a `plugin_api` directory beside it (values, host, plugin, paths, file icons), and widen the lint's plugin rule to that directory.

### Floats have no place in the architecture (architecture-review M4)

Location: `docs/architecture.md` sections 4, 5.3, and 8.2; the code has `Domain::FloatWindow`, `Domain::CompletionMenu`, `UseCases::OpenFloat` and `CloseFloat`, `Highlight::FLOAT_LAYER`, and plugin API 2.3 and 2.6. Why: floats carry documentation, definitions, signature help, the finder, the key hints, and the palette, yet the architecture mentions them only in passing, so where a new overlay belongs is not written down. Fix outline: a short paragraph on floats in section 4 (record, group layer, plugin ownership) and section 8.2 (painting order), within the budget by pointing to the map for lists.

### The assembly grows with every feature (architecture-review M5)

Location: `carat/adapters/editor_assembly.rb` (582 lines), whose `initialize` builds every record and use case. Why: it is the one wiring place by design, but one long constructor makes a feature's wiring hard to find and review. Fix outline: group construction into a private method per feature (language services, discovery, plugins), keeping the readers and the one-instance rule `test/adapters_assembly.rb` checks.

## Findings of architecture-review at review

### docs/architecture.md:29 the Makefile statement is still contradicted by the Makefile

- Where: docs/architecture.md:29, and the section 11 tree line that repeats it.
- Why: the toolchain target runs git and builds Spinel with make, and doctor and no-cruby run inline shell, so not every target calls spin, spinel, OpenSpec, or a tools/ script as the corrected sentence says.
- Fix: name the toolchain build among what the targets run, or say most targets call those and the toolchain recipe fetches and builds Spinel.

### docs/architecture.md:174 the ex command list still omits registered commands

- Where: docs/architecture.md:174.
- Why: the list the design calls corrected leaves out wqa and xa among the file commands, and vnew, bf, and bl among the buffer and window commands, which ExTable DESCRIPTIONS names.
- Fix: add them, or say the list is a sample and point to docs/compatibility.md for the full set.

### docs/architecture.md:180 the (planned) markers do not cite their roadmap item

- Where: docs/architecture.md:180, 374, 379, and 392.
- Why: the change's design (design.md:20) says planned pieces are marked (planned) with the roadmap item where there is one, but no marker cites its item: FormatBuffer and git_signs are item 14, the plugin gateway and plugin-protocol.md item 13.
- Fix: append the item number to each marker, or drop that clause from the design.

### docs/codebase-map.md:599 the corrected environment sentence reads ambiguously

- Where: docs/codebase-map.md:599.
- Why: the sentence reads 'the environment reads but the HOME of DiskFiles#home', which is hard to parse.
- Fix: write 'the only environment reads besides the HOME that DiskFiles#home reads'.

### docs/architecture.md:271 the one-shot runner is marked as future twice

- Where: docs/architecture.md:271, and the layout line at docs/architecture.md:379.
- Why: 'will run ... (planned)' marks the one-shot runner as future twice, and the edited layout line now sits one column right of the tree's description column.
- Fix: drop 'will' to match the other (planned) markers and realign the column.

## Findings of design-principles at review

- Quality, docs currency, docs/goals.md:27: the T0 scope is inconsistent; goals keeps only T0 security fixes outside the sprint mix while CLAUDE.md:206 (T0 exempt from both) and .claude/agents/planner.md:35 (T0 exempt) exempt every T0 item, a red main or a crash too, so a T0 crash fix counts in the mix by one text and not by the other. Fix: say "T0 items stay outside the mix and always go first" in docs/goals.md:27, or narrow the other two to security.
- Quality, docs accuracy, .claude/agents/planner.md:35: "three features and two fixes, ... a decision citing 3 features, 2 fixes, ...; make docs-lint checks it" reads as if docs-lint checks the mix, but tools/docs_lint.sh:152 counts only pipeline items and nothing enforces the mix (the change's design.md Risks). Fix: write "make docs-lint checks the pipeline count, not the mix".
- Quality, wording, .claude/agents/planner.md:22: "at most one fix a pipeline change" is ungrammatical and ambiguous, as if a pipeline change had to be a fix. Fix: "three features and two fixes, a pipeline change, at most one, counting as a fix, T0 exempt".
- Quality, rule gap, docs/goals.md:27: the fixed mix of three features and two fixes, and the planner's sprint mode at .claude/agents/planner.md:35, has no rule for a pool with fewer than three ready features, beside the older "when no feature is ready, the next non-feature item runs". Fix: add one clause, "with fewer features ready, fixes fill the slots and a decision says so".
- Quality, accuracy, openspec/changes/archive/2026-11-15-design-principles/proposal.md:29: Impact says four sentences repeating sections 2, 9, and 13 are shortened or removed, but the diff trims six places in docs/architecture.md, and the dropped CRuby 4.0.4 benchmark baseline aside (formerly docs/architecture.md:32) and the Ractor note on Spinel's thread list (formerly line 23) are stated nowhere else. Fix: record in docs/architecture.md, or in a follow-up change's notes, that the baseline aside was dropped content, and restore the Ractor fact if it is still needed.

## Findings of the sprint-5 review

### The origin pin is checked two ways in the hooks and the green line

- Location: `.claude/workflows/deliver-change.js:542` (`originCheck`) against the hook lines under `.claude/agents/` (sprint-5 quality review).
- Why it matters: the hooks hash `config --local remote.origin.url` with `.git` stripped against 3 ids, while `originCheck` hashes `remote get-url` against 6 ids (the 3 plus their `.git` forms), so the recipe and the id list live in two shapes in 11 places.
- Fix outline: strip a trailing `.git` in `originCheck` too, keep only the three ids, and say in the `tools/agent_guard.sh` header that both read the address the same way. Queue item `hook-one-place`.

### The language gateway's and SymbolOutline's untyped reads have no item

- Location: `carat/domain/json.rb:53` (`Json.field`, `element`, `reach`), `carat/adapters/json_rpc_language_gateway.rb`, `carat/adapters/symbol_outline.rb`, `docs/spinel-notes.md:47` (sprint-5 quality review).
- Why it matters: the typed readers serve the language-server tests (about 68 calls, 1,181 to 779 rebuilds), but the gateway's 210 untyped reads and SymbolOutline's 18 stay, as the Spinel notes list them.
- Fix outline: move the gateway's and SymbolOutline's reads onto the readers, accepted with a lower `SP_TIMING` rebuild count at the pin. Queue item `spinel-workarounds`.

## Findings of architecture-tidy's review

### docs/examples.md:31 golden ex-command paragraph omits the palette description (quality, docs currency)

- Where: docs/examples.md:31 and its wiring list at docs/examples.md:33.
- Why: task 2.3 of architecture-tidy is done, but the golden ex-command paragraph and its wiring still describe register(table) without the palette description the registration now carries, nor the generator's TODO placeholder that must be replaced by hand.
- Fix: say SyntaxCommandHandler registers itself with its description in self.register(table), and add the description to the wiring list as a by-hand step.

### openspec/specs/config-files/spec.md:27 quoting scenario uses a refused formatter key (quality, spec drift)

- Where: openspec/specs/config-files/spec.md:27, scenario A quoted word, and its row at test/domain_rc_parser.rb:42.
- Why: the scenario still uses a language.ruby.formatter line, which Config now refuses as not supported yet, so the main spec illustrates quoting with a setting it rejects.
- Fix: add a MODIFIED scenario to a delta spec using a still-read key such as language.ruby.lsp ruby-lsp "--config my file.yml", and change the matching row at test/domain_rc_parser.rb:42.

### tools/new.sh:280 generated TODO description placeholder passes the description check (quality)

- Where: tools/new.sh:280 for an ex command, tools/new.sh:221 for an action, and the check at test/use_cases_actions.rb:190.
- Why: the generated placeholder TODO: short description is 23 characters, so the 1-to-32 length check passes an ex command or action that still ships the placeholder in the palette, weakening the rule that the test fails on an ex command without a description.
- Fix: make both description checks also reject text starting with TODO.

### tools/new.sh:275 hand-reflowed template comment (quality, style)

- Where: tools/new.sh:275.
- Why: the template comment was reflowed by hand, leaving the short line a handler that runs a use case takes it as a before a wrapped remainder.
- Fix: rewrap the three lines to the file's width.

## winbar_with? on TabPage reads no tab state

- Location: carat/domain/tab_page.rb:68
- Source: quality advisory, winbar-outline
- Why: winbar_with? reads no TabPage state, the breadcrumbs rule being a function of the mode and a count only, so SplitWindow fetches a tab just to ask it.
- Fix outline: move the rule beside the mode it compares (Options, for example Options#winbars_with?(count)) and keep TabPage#winbar? as the caller passing file_window_count.

## Window#winbar reads as the Winbar adapter rather than a flag

- Location: carat/domain/window.rb:23
- Source: quality advisory, winbar-outline
- Why: the bool member winbar reads as the Winbar adapter rather than a flag (Window#winbar beside FramePresenter#winbar, which is the adapter).
- Fix outline: name it after what it records, for example winbar_shown, in the record, ArrangeView, FramePresenter, the test, and the map.

## Scratch split under breadcrumbs auto is untested

- Location: test/editor_breadcrumbs.rb:209
- Source: quality advisory, winbar-outline
- Why: the requirement says a scratch split gets exactly the counted rows under every breadcrumbs mode and the design names the auto case beside two file windows as fixed, but only always is tested.
- Fix outline: add a row with option.breadcrumbs auto and two file windows splitting 5<C-w>s from the scratch window, expecting 5 text rows and no winbar.

## Non-blocking findings of spinel-untyped-bump

### carat/adapters/json_rpc_language_gateway.rb:469 receive reads the same fields in many branches

- Quality advisory, duplication: receive reads Json.field(value, "id") in seven branches of its elsif chain and Json.field(value, "result") in six.
- Fix: read id = Json.field(value, "id") once after name and compare each branch against it.

### carat/adapters/json_rpc_language_gateway.rb:1065 signed reads each bound twice

- Quality advisory, duplication: signed reads Json.element(part, 0) and Json.element(part, 1) twice each.
- Fix: read the two bounds into locals once and test is_a?(Integer) on them.

### carat/doubles/fake_processes.rb:69 methods_sent reads the method field twice

- Quality advisory, duplication: methods_sent reads Json.field(value, "method") twice in one expression.
- Fix: name = Json.field(value, "method"), then name.is_a?(String) ? name.to_s : "result".

### test/editor_grammar.rb:47 untyped table values reach Cursor#move_to

- Quality advisory, typed table values and duplication (corrects the earlier note, which named editor_operators): the same move_to(Carat::Json.element(input[1], 0), Carat::Json.element(input[1], 1)) line, rewritten in 15 test files, still hands untyped table values to Cursor#move_to.
- Fix: convert with .to_i as the typed-table rule says (test/editor_registers.rb already does), ideally through one shared helper.

### test/domain_grammar.rb:15 two forms of reading a table element

- Quality advisory, one clear way: DomainGrammarTest wraps Carat::Json.element as at while about thirty other test files call Carat::Json.element inline, and the tests use a JSON reader as a general untyped-array reader.
- Fix: pick one form, either a named element reader in Carat::Testing used by every test or the inline call everywhere with at dropped.

## Header claimed regenerated in the archived spinel-untyped-bump-b (openspec/changes/archive/2026-11-15-spinel-untyped-bump-b/proposal.md:11)

- Location: openspec/changes/archive/2026-11-15-spinel-untyped-bump-b/proposal.md:11, also its :29 Impact, design.md:7, and tasks.md:6.
- Why: quality advisory, docs currency: they say the vendored header tools/spinel/spinel_rt_responds_generated.h is regenerated and changed, but commit 7d6e154 leaves it byte for byte the 6af548c9 one and the diff has no header change.
- Fix outline: say the header was regenerated at 93d7883b and came out unchanged, and drop it from Impact (in the next note that cites the pin, since the archive records the change as it was).

## Findings of spinel-warnings

### Makefile:317 the Spinel warning recipe is repeated in every compile target

- Where: Makefile:317, and the build, test-one, bench, types, and gen-config targets, with near copies in dev-build, test-build, and bench-budget.
- Why: the same capture-stderr, keep-status, copy-back, fail-on-status, check recipe is copied target by target, so a fix to one copy drifts from the others (quality advisory, duplication).
- Fix: one script mode, for example sh tools/spinel_warnings.sh run LABEL LOG -- CMD..., keeping the status and the check in one place.

### Makefile:248 make build no longer streams the standard error of spin build

- Where: Makefile:248, the build target.
- Why: make build now holds all of spin build's standard error until it exits, so Spinel and cc errors of the minute-long release build no longer stream and an interrupted build shows none (quality advisory, behavior).
- Fix: tee standard error into BUILD_LOG while keeping spin's status.

### tools/spinel_warnings.sh:42 the wrapper's temporary file has no trap

- Where: tools/spinel_warnings.sh:42.
- Why: the wrapper's mktemp file has no trap, so an interrupted or killed diagnose compile leaves carat-spinel.XXXXXX files in TMPDIR (quality advisory, shell hygiene).
- Fix: trap 'rm -f "$err"' EXIT INT TERM after mktemp.

### tools/tools_test.sh:2926 the wrapper status case never sees a failing status

- Where: tools/tools_test.sh:2926, the case named 'the wrapper keeps spinel's status'.
- Why: it only runs a stub that exits 0, so a wrapper that lost a failing status (spinel-doctor then reading a missing .c) would still pass (quality advisory, tests).
- Fix: add a stub run exiting non-zero and expect that status, plus diagnose-one and dev-build pass cases.

### openspec/changes/archive/2026-11-15-spinel-warnings/proposal.md:1 the change mixed fixes with a build change

- Where: openspec/changes/archive/2026-11-15-spinel-warnings/proposal.md:1 (proposal.md of spinel-warnings before its archive).
- Why: the branch mixes fixes (the test/lint.rb require, the tab_request and utf8 warnings) with a build change (every target fails on a warning), needing both fix and build types in one squash commit (quality advisory, one logical change per pull request).
- Fix: name the fixes as the enabling part of the build change in the pull request text, or split the lint and warning fixes out next time.

### Makefile:87 BUILD_BINS lists the binaries by hand

- Where: Makefile:87.
- Why: BUILD_BINS spells out build/bin/carat-gen-config beside GEN_CONFIG_BIN and lists the binaries by hand while spin build compiles every bin/*.rb, so a new bin/*.rb that warns keeps its binary and a second make build passes silently (quality advisory, duplication and drift).
- Fix: BUILD_BINS ?= $(patsubst bin/%.rb,build/bin/%,$(wildcard bin/*.rb)) and GEN_CONFIG_BIN built from it or the reverse.

### docs/codebase-map.md:51 the tools_test.sh entry omits the Spinel warning cases

- Where: docs/codebase-map.md:51, the tools/tools_test.sh entry.
- Why: the entry lists what it tests but not the new Spinel warning cases on the build targets with a stub toolchain (stub_make), which its header and make help now name (quality advisory, docs currency).
- Fix: add 'the Spinel warning check on the build targets with a stub toolchain (stub_make)' to the entry.

## Findings of the sprint-6 review and sweep

### Security: the check clone links the toolchain back into the delivery clone (sprint-6 sweep, Medium (6))

- Location: tools/run_state.sh:571 (sprint-6 sweep at 4958dc6bd923, security Medium (6); raised before as Low (5)). Queue item `check-runner-safety`.
- Why: the check clone links tmp/.toolchain and tmp/.spinel back into the delivery clone, so a stage running branch code writes through the link (build/pipeline, .git, the toolchain binaries) and the clone isolates nothing.
- Fix outline: give the clone its own read-only toolchain copy, or put the toolchain bin on PATH outside the clone, and run the read profile's make targets in the check clone too.

### A crash then :LspStart never asks the new server for the outline

- Location: carat/adapters/json_rpc_language_gateway.rb:537 (`forget_server`, called from the crash at :451 and from stop; start at :188). Sprint-6 review, quality. Queue item `gateway-split-a`.
- Why: `forget_server` clears the symbol request's sent id but keeps the text last asked (`SymbolRequest#asked?`), so after a crash with a symbol request in flight the new server is never asked for the unchanged text and the outline stays stale; winbar-outline fixed only the restart path.
- Fix outline: forget the symbol request in `forget_server` when its language matches, drop the separate forget from restart, and add a `test/editor_breadcrumbs.rb` case for a crash then `:LspStart`.

### send_symbols decides the winbar apart from ArrangeView

- Location: carat/adapters/json_rpc_language_gateway.rb:931 (`send_symbols` reads `TabPage#winbar?`). Sprint-6 review, quality. Queue item `gateway-split-a`.
- Why: `ArrangeView#reserve_winbars` is the one place that decides (`Window#winbar`), so symbols are asked for a one-row layout window or a scratch buffer that shows no winbar.
- Fix outline: return unless the layout window's winbar flag is set.

### markdown_of reads the value field twice

- Location: carat/adapters/json_rpc_language_gateway.rb:910 and :911. Sprint-6 review, quality advisory. Queue item `gateway-split-a`.
- Why: duplication: `Json.field(part, "value")` is read twice.
- Fix outline: read it once into a local, then check its class and convert it.

### test/lint.rb helpers return arrays to destructure

- Location: test/lint.rb:255 (`expected_declaration` returns namespaces and base) and :862 (`typed_readers` returns name and type pairs), read back through `Carat::Json.element` at 283, 874, 892, 893, 1290, 1298 to 1300. Sprint-6 review, quality advisory. Queue item `spinel-workarounds`.
- Why: the tests rule asks a helper returning several values to return an object with typed readers.
- Fix outline: small typed records (a declaration with namespaces and base, a reader with name and type) and drop those element reads.

### The unsupported language setting scenario names a file its test does not parse

- Location: openspec/specs/config-files/spec.md:233 (scenario "A language setting not supported yet") against test/domain_rc_parser.rb:100. Sprint-6 review, quality advisory. Queue item `tools-docs-tidy`.
- Why: the scenario expects the user file's label while the test parses a trusted `.caratrc` and checks `.caratrc:1`, so the scenario is not proven as written.
- Fix outline: give the test the user file's label, or word the scenario by the trusted file.

### Keymap#bind has no caller

- Location: carat/domain/keymap.rb:223; docs/codebase-map.md area 5. Sprint-6 sweep, quality. Queue item `input-core-tidy`.
- Why: dead code the map still lists; only `bind_owned` and `bind_text` are used.
- Fix outline: remove the method and its map mention.

### Range's comment is stale and its RBS block is missing

- Location: carat/domain/range.rb:4. Sprint-6 sweep, quality. Queue item `input-core-tidy`.
- Why: the comment says only the exclusive charwise kind is used while text objects and Selection build linewise, blockwise, and inclusive ranges, and the record lacks the `# @rbs` instance variable block every other Data record carries.
- Fix outline: rewrite the comment and add the block.

### A broken key sequence drops a bound shorter prefix

- Location: carat/use_cases/handle_key.rb:253, the timeout comment at :166. Sprint-6 sweep, quality. Queue item `input-core-tidy`.
- Why: when pending keys stop matching, or time out at a prefix, every pending key is dropped even when a shorter prefix is bound (with `a` bound beside `abc`, typing `abx` loses the `a` action), where Vim fires the longest bound prefix and replays the rest.
- Fix outline: dispatch the longest bound prefix and push the remaining keys back on the queue, with a table test in test/editor_leader.rb.

### Generated config headers tell the reader to run spin directly

- Location: bin/carat-gen-config.rb:32; the headers of carat/domain/default_config.rb:2 and carat/plugins/registry.rb:2 (through carat/domain/registry_source.rb:57); docs/architecture.md:222. Sprint-6 sweep, quality. Queue item `tools-docs-tidy`.
- Why: `make gen-config` is the one documented way, with tools/noruby first on the PATH.
- Fix outline: say make gen-config in both renderers and the architecture, then regenerate.

### RcLine splits the key at a literal byte

- Location: carat/domain/rc_line.rb:224. Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: magic number 46 where `RcParser::DOT` names it.
- Fix outline: require rc_parser and use the constant.

### RegistrySource walks the plugin entry lines twice

- Location: carat/domain/registry_source.rb:27 and :40. Sprint-6 sweep, quality advisory. Queue item `plugin-host-tidy`.
- Why: duplication: `column` and `names` repeat the same walk.
- Fix outline: one private entries reader both map.

### accept_visual repeats the prelude of accept

- Location: carat/domain/command_grammar.rb:158 against :134 to :143. Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: duplication: the want check, remember, and search prelude are copied line for line.
- Fix outline: one private prelude returning the early result or nil, called by both.

### History counts are unbounded and digits? is written four times

- Location: carat/use_cases/ex/history_command_handler.rb:44 and :77; `digits?` at buffer_command_handler.rb:102, tab_command_handler.rb:102, history_command_handler.rb:67, carat/domain/json.rb:72. Sprint-6 sweep, quality. Queue item `ex-handlers-tidy`.
- Why: `:undo N`, `:earlier N`, and `:later N` convert an unbounded run of digits while the buffer and tab handlers hold theirs to 9 bytes for Spinel's Integer.
- Fix outline: one domain predicate with the 9-digit bound the three handlers share, with a test for a long count.

### Requires never named in their files

- Location: carat/use_cases/visual/extend_visual.rb:6 (display_width), carat/domain/last_change.rb (position, display_width), carat/domain/operators.rb (registers, selection). Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: dead requires hide the real dependency graph.
- Fix outline: drop them and confirm with make test-build.

### The BufferRequest map entry omits two targets

- Location: docs/codebase-map.md:383 and :161. Sprint-6 sweep, quality advisory. Queue item `tools-docs-tidy`.
- Why: SwitchBuffer also takes the tab and alternate targets (buffer_request.rb, tab_handler.rb:36, buffer_handler.rb:43) and line 161 omits buffer.alternate.
- Fix outline: list both targets and the action.

### Reloading the current buffer resets the cursor

- Location: carat/use_cases/files/open_file.rb:62, the class comment at :20. Sprint-6 sweep, quality. Queue item `file-access-tidy`.
- Why: `:e` and `:e!` on the current buffer call `window.show`, putting the cursor at the top and forgetting the last selection, though the comment says the cursors are kept and Vim keeps the cursor line.
- Fix outline: skip show for the current buffer and clamp the cursor, or state the reset in the spec; rewrap the comment.

### :new file and :vnew file drop their argument

- Location: carat/use_cases/ex/window_command_handler.rb:33. Sprint-6 sweep, quality. Queue item `ex-handlers-tidy`.
- Why: Vim edits the named file in the new window; carat opens an empty one silently.
- Fix outline: pass the argument, fresh only when it is empty, or answer E488, with a test.

### Not implemented is a success in one handler and a failure in another

- Location: carat/use_cases/ex/history_command_handler.rb:78 against buffer_command_handler.rb:69 and :88. Sprint-6 sweep, quality advisory. Queue item `ex-handlers-tidy`.
- Why: the same answer is shown with two outcomes.
- Fix outline: one form for every unimplemented argument.

### PluginRouter spells the registry's refusal texts again

- Location: carat/use_cases/plugins/plugin_router.rb:40 against PluginRegistry#refusal (plugin_registry.rb:100). Sprint-6 sweep, quality advisory. Queue item `plugin-host-tidy`.
- Why: duplication of the no-plugin and disabled texts.
- Fix outline: use the registry's refusal and fail when it is not empty.

### Palette#start repeats initialize's resets

- Location: carat/domain/palette.rb:58; CommandGrammar#initialize and #reset at command_grammar.rb:37 to :53 alike. Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: a new member has to be reset in two places.
- Fix outline: initialize calls start, then sets the two members start keeps.

### The examples' action kinds omit :search

- Location: docs/examples.md:25. Sprint-6 sweep, quality advisory. Queue item `tools-docs-tidy`.
- Why: SearchHandler registers the search kind and CommandGrammar reads it.
- Fix outline: add it to the list with what it reads.

### The CommandGrammar and ActionTable map bullets omit public methods

- Location: docs/codebase-map.md:152 and :157. Sprint-6 sweep, quality advisory. Queue item `tools-docs-tidy`.
- Why: HandleKey calls pattern, wants_pattern?, char, digit?, and digit, and the table's count and handler_at are public, none listed.
- Fix outline: list them.

### ci_scope asks the same pull request query twice

- Location: tools/ci_scope.sh:78. Sprint-6 sweep, quality advisory. Queue item `ci-scope-quoting`.
- Why: two identical gh api calls read the head sha and the number.
- Fix outline: one call printing both, split with read.

### make snapshots ignores a crashing test

- Location: Makefile:303. Sprint-6 sweep, quality. Queue item `tools-docs-tidy`.
- Why: the runner's exit status per test is ignored, so a crash's output becomes its snapshot with only a manual diff review before a commit.
- Fix outline: note each nonzero exit and exit 1 after the loop.

### make types leaves build/carat.rbs that breaks every later compile

- Location: Makefile types target, build/carat.rbs read by spin --rbs
- Why: after make types, every later Spinel compile reads the stale build/carat.rbs and fails until the file is deleted
- Fix: write the types output outside the path spin reads, or delete it at the end of the target, with a tools_test case

### Backlog entry for the stale build/carat.rbs drifts from the entry format (docs/backlog.md:5701)

- Location: docs/backlog.md:5701, the entry the mit-license change added.
- Why: it uses '- Fix:' where entries use '- Fix outline:', and its Location gives no line and unquoted paths, against the entry format CLAUDE.md asks for (location, why, fix outline). Found by the quality review of mit-license (advisory).
- Fix outline: at sprint grooming, change it to '- Location: Makefile:405 (types), build/carat.rbs read by spin --rbs.' and '- Fix outline: ...'.

### Spinel's MIT notice does not travel with the vendored generated header (README.md:212)

- Location: README.md:212, the credit line, and tools/spinel/spinel_rt_responds_generated.h.
- Why: the MIT condition asks that Spinel's copyright and permission notice go with copies of substantial portions; the credit line names the license without carrying that notice for the vendored header. Found by the quality review of mit-license (advisory).
- Fix outline: in a later item, put Spinel's copyright line and MIT notice in a comment at the top of the tools/spinel/ files, or record in the design why the generated method-name tables need none.

### Themes.find hand-rolls a linear search
- Location: carat/domain/themes.rb:470
- Why: find hand-rolls a linear search and recomputes DEFAULT's index on every call, where Array#index already serves this under carat/ (plugin_ui.rb:84); quality advisory (simplicity) from carat-palette-b.
- Fix: index = NAMES.index(name), falling back to NAMES.index(DEFAULT) when nil, and drop the while loop.

### The theme test's BG and FG 256-color row proves nothing new
- Location: test/domain_theme.rb:453
- Why: every shipped palette already gives -1 as the BG and FG 256-color index, so this row passed before the change and no test fails if the indexes256[BG]/[FG] clearing at carat/domain/themes.rb:510-511 is removed; quality advisory from carat-palette-b.
- Fix: add a row that calls D::Themes.from_palette with a small palette giving FG and BG a 256 index and asserts fg256/bg256(H::NORMAL) are -1 when not painted.

### The theme palette lookup row misses a reordered PALETTES
- Location: test/domain_theme.rb:376
- Why: the lookup row checks only that the lengths match and no two palettes are equal, so a reordered PALETTES (ONE_DARK and ONE_LIGHT swapped, say) still passes and draws another palette for a name, which the proposal says this row prevents; quality advisory from carat-palette-b.
- Fix: assert each name's find(name, "theme").bg(H::NORMAL) against a table of each palette's BG color.

### First-use hints wait for the start screen's logo animation

- Location: `carat/domain/start_art.rb:67` (the hints), `carat/adapters/input_controller.rb:150` (the animation).
- Why: for about 0.6 s the first screen shows a single dot and no hint, the one thing a first-time user needs (ux-pass review finding 1). Reproduction: start `carat` with no file and read the screen within 100 ms, `openspec/changes/archive/*-ux-pass/screens/start-early.txt` against `start-late.txt` and `first-start.txt`.
- Fix: draw the name and the three hint lines in the first frame and animate only the logo.

### The Ctrl-C hint says abandon all changes when nothing is modified

- Location: `carat/use_cases/actions/message_handler.rb:10`.
- Why: on a pristine `[No Name]` buffer the hint tells the user to `:q!` and abandon all changes, spells the name `Carat` where carat writes `carat` everywhere else, copies Neovim's sentence, and clears the start screen (ux-pass review finding 2). Reproduction: start with no file, `<C-c>`, `openspec/changes/archive/*-ux-pass/screens/first-quit-hint.txt`.
- Fix: name `:q` when no buffer is modified and `:q!` only when one is, in carat's own words with a lowercase name, and keep the start screen under the message.

### The explorer's help is one message line cut at the terminal's width

- Location: `carat/plugins/explorer/plugin.rb:16` and `:249`.
- Why: `?` prints every key on the message row and loses the end at 80 columns (`... d delet`), so `R`, `H`, `-`, `C`, and `q` are never shown (ux-pass review finding 4). Reproduction: start in an empty folder, `<Space>e`, `?`, `openspec/changes/archive/*-ux-pass/screens/empty-explorer-help.txt`.
- Fix: show the help as a bordered float like the key-hint menu, one key per row, closed by `<Esc>`, `q`, or `?`.

### Insert mode is shown twice, in the pill and on the message row

- Location: `carat/adapters/frame_presenter.rb:1255`.
- Why: the status bar's `INSERT` pill and `-- INSERT --` on the message row say the same thing and take the message row while typing (ux-pass review finding 6). Reproduction: start on a file, `i`, `openspec/changes/archive/*-ux-pass/screens/time-insert-char.txt`, rows 23 and 24.
- Fix: drop the message-row mode text while the status bar shows the mode pill, or add a `showmode` option defaulting to off.

### The key-hint menu names its entries three ways

- Location: `config/default.caratrc:200` to `:205` (the group names), the action descriptions shown for single keys (the explorer's toggle in `carat/plugins/explorer/plugin.rb`), `carat/domain/key_hints.rb`.
- Why: under `<Space>` entries read as a long sentence (`Open the file tree, focus it, or close it when it is focused`), lowercase group names (`files`, `windows`), and title case (`Command palette`), in an order neither alphabetical nor the configuration's (ux-pass review finding 7). Reproduction: start on a file, `<Space>`, wait one second, `openspec/changes/archive/*-ux-pass/screens/msg-leader-menu.txt`.
- Fix: a short sentence-case label for every entry, groups included (a hint label beside the long description), sorted by key.

### The completion popup is the only float without a border

- Location: `carat/adapters/frame_presenter.rb:661` (borders only for an edged float), the completion float.
- Why: hover, the finder, the palette, and the key-hint menu share a rounded `#6c7286` border with a bold title; the completion popup has neither, and no rule says when a float is borderless (ux-pass review finding 8). Reproduction: start on a Ruby file with a language server, `8G`, `o`, `gre`, `openspec/changes/archive/*-ux-pass/screens/float-completion-lsp.txt` against `float-hover.txt`.
- Fix: decide the rule (every float bordered, or inline lists near the cursor borderless), record it in `docs/architecture.md` with the float style, and make the completion popup follow it.

### The palette and the finder frame their prompt and title differently

- Location: `carat/adapters/frame_presenter.rb:107` (`PALETTE_PROMPT = ">"`), `carat/use_cases/discovery/follow_palette.rb:36` (`TITLE`), `carat/plugins/finder/plugin.rb:22` (`PROMPT = "> "`).
- Why: the finder's prompt is `> ` and its title counts (`Files 0/5`), the palette's prompt is `>` with no space and its title `Commands` has no count, two floats of one kind a few keys apart (ux-pass review finding 9). Reproduction: start on a file, `<Space>p`, `wri`, `openspec/changes/archive/*-ux-pass/screens/float-palette-filter.txt` against `empty-finder-nomatch.txt`.
- Fix: one prompt and one title form, `> ` and `Name shown/total`, for both.

### The leader buffer list prints Vim's :ls line

- Location: the `buffer.list` action, `docs/actions.md:168` (`List the buffers as :ls does`).
- Why: `<Space>bb` prints `1 %a   "greet.rb"   line 3` on the message row, Vim's format with nothing to pick, while the buffer list is first in the user's UI order of `docs/goals.md` (ux-pass review finding 11). Reproduction: start on a file, `<Space>bb`, `openspec/changes/archive/*-ux-pass/screens/float-buffers.txt`.
- Fix: bind `<leader>bb` to a buffer picker float in the finder's style, `:ls` keeping Vim's output; a behavior change for planning to decide.

### The ux-pass start timings have no saved evidence

- Location: `openspec/changes/archive/2026-11-15-ux-pass/design.md:52`.
- Why: the two start rows of the timing table (6.5 to 10 ms, 632 ms; 7 to 10 ms, 8 ms, 260 to 520 ms with the server) cite no recorded run: first-start, first-file, and empty-new-file record first byte none and settled none, and `timings.txt` has only `start greet.rb settled 10.8 ms`; quality advisory from ux-pass.
- Fix: add the start runs to `timings.txt` or drop the figures that were not recorded.

### The ux-pass screen headers name only the last keys written

- Location: `openspec/changes/archive/2026-11-15-ux-pass/design.md:19`, `openspec/changes/archive/2026-11-15-ux-pass/tasks.md:5`.
- Why: a screen header names only the last keys sent (`empty-explorer-help` says `keys: ?`, not `<Space>e` then `?`) and the start screens leave the keys empty with times none, so the claim that each header names its keys does not hold alone; quality advisory from ux-pass.
- Fix: write the full key sequence from the named start in each header, or say in the design that the screen list carries it.

### The ux-pass finding 6 reproduction names the wrong file

- Location: `openspec/changes/archive/2026-11-15-ux-pass/design.md:66`.
- Why: finding 6's reproduction starts on `notes.txt`, but its evidence `time-insert-char` is `greet.rb` with the canned server (row 23 shows `greet.rb` and `fake-lsp`), so following it does not reproduce the screen; quality advisory from ux-pass.
- Fix: name `greet.rb` and the keys the screen records in the reproduction and in the backlog entry of finding 6.

### The ux-pass finding 11 entry names only the doc row

- Location: `carat/use_cases/actions/buffer_handler.rb:50` (the handler), the finding 11 entry of `docs/backlog.md`, and `openspec/changes/archive/2026-11-15-ux-pass/design.md:71`.
- Why: the entry's location names only the `docs/actions.md` row, not the handler that implements the action, so the fix starts with a search; quality advisory from ux-pass.
- Fix: add `carat/use_cases/actions/buffer_handler.rb:50` to the finding 11 entry's location.

### revert_to leaves restored rows unmarked for :g

- Location: `carat/domain/buffer.rb:656` (`revert_to`), `GlobalMarks#shift`, and the global spec's revert requirement.
- Why: `revert_to` moves the global marks back, but rows the reverted edit had deleted come back unmarked because `GlobalMarks#shift` inserts unmarked rows, so the comment's "return to how they were" and the global spec's requirement overclaim and `:g` skips those lines; quality advisory from core-correctness.
- Fix: keep the removed rows' flags with the change record and restore them on revert, or narrow the comment and the requirement to inserted rows, with a test row that reverts a deletion of a marked line.

### Keymap unbind descends the trie twice

- Location: `carat/domain/keymap.rb:359` (`unbind`).
- Why: `unbind` re-walks the trie from the root for every depth it prunes, a second descent duplicating the first; quality advisory from core-correctness.
- Fix: collect the visited nodes in an array while descending and prune from it deepest first.

### Timeout follow-ups beyond hover have no test

- Location: `carat/use_cases/handle_key.rb:198` (the timeout path) and `test/editor_leader.rb`.
- Why: the timeout now also runs the completion, definition, and palette follow-ups, but only the hover follow-up has a test, so a regression in the others would pass; quality advisory from core-correctness.
- Fix: add a timeout row in which a resolved binding closes or refreshes the completion menu or the palette.

## The resume brief misses the planner's queue when the planner runs

- Location: .claude/workflows/deliver-change.js:967
- Why: resumeBrief is computed from plan-needed's line before the planner runs; on 'needed: c is not the head of docs/queue.md' the planner writes build/plan/queue.md, yet a change-name-only brief now names docs/queue.md alone (the old one named both), so an item the planner adds or rewrites there is missed.
- Fix: name build/plan/queue.md as well when the planner runs, or build the brief after the plan phase.
- Source: quality advisory, brief-only-relay.

## The docs-lint line-start marker case does not prove the line-start rule

- Location: tools/tools_test.sh:1829
- Why: the case 'a marker not at a line start does not count' rewrites the marker to 'An exception', which a substring match would not find either, so the line-start rule stays unproven.
- Fix: put the marker mid-line (for example 'Note: The user-approved exception ...') and expect the failure.
- Source: quality advisory, brief-only-relay.

## CLAUDE.md lost a rule and misstates the start inputs to fit its budget

- Location: CLAUDE.md:204
- Why: the edit drops the rule 'Tasks of one domain may share a change' and rewords open-pr's role, unrelated to the brief, to fit the 30720-byte budget (now 30718), and 'every start given only the brief' misstates that starts also get packs, findings, and logs.
- Fix: restore the rule, say 'every start given the brief', and make room elsewhere.
- Source: quality advisory, brief-only-relay.

## The planner agent does not name the sprint exception marker line

- Location: .claude/agents/planner.md:35
- Why: it still states at most one pipeline item (T0 exempt) with no word on the 'The user-approved exception' line docs-lint now honors and the planner is the one to write.
- Fix: name the marker line and when to write it there.
- Source: quality advisory, brief-only-relay.

## docs-lint scans the sprint section twice

- Location: tools/docs_lint.sh:157
- Why: the marker awk repeats the sprint-section scan of line 150's awk.
- Fix: one awk pass, or a shared helper printing the sprint section's lines that both filters read.
- Source: quality advisory, brief-only-relay.

## Static grep counts in tools_test prove text, not behavior

- Location: tools/tools_test.sh:2718
- Why: the static cases counting the word args and the agentType: contributor call site prove text, not behavior, and break on any new mention or call site.
- Fix: keep the startInput and contributorTask behavior cases and drop or narrow the grep counts.
- Source: quality advisory, brief-only-relay.

## Findings of the sprint-7 review

### Spinel warnings print twice in each guarded compile target

- Location: Makefile:254, and the build, dev-build, test-build, test-one, bench, bench-budget, types, and gen-config targets (sprint-7 review, quality, shell output).
- Why: each guarded target echoes its whole log to standard error, then tools/spinel_warnings.sh check prints the same warning lines again, so every Spinel warning shows twice and a reader counts it twice.
- Fix outline: leave the warning lines out of the echoed log, or have check print only its summary line. Queue item `tools-docs-tidy`.

### The architecture's section 10 omits the Spinel warning gate

- Location: docs/architecture.md:351, the diagnose bullet of section 10 (sprint-7 review, quality, docs currency).
- Why: section 10 describes make diagnose and the build machinery but not that a Spinel warning now fails every compile target, nor that diagnose runs Spinel through tools/spinel_warnings.sh because spinel-doctor --quiet hides warnings; only docs/spinel-notes.md says it, and the architecture is binding.
- Fix outline: one sentence in the diagnose bullet of section 10. Queue item `tools-docs-tidy`.

### test-one cannot compile test/domain_global.rb alone

- Location: test/domain_global.rb, its standalone compile failing at carat/use_cases/history/list_undo.rb:27 and carat/use_cases/history/walk_history.rb:168 (a finding the core-correctness contributor handed over that never reached the backlog; its retrospective).
- Why: make test-one T=test/domain_global.rb does not compile though the whole runner passes, so the global command's tests cannot be checked alone; 1 of 4 handed findings of core-correctness was lost.
- Fix outline: reproduce with make test-one, name the typing the standalone program loses at those two lines, and type it or record the pitfall in docs/spinel-notes.md, accepted when the standalone compile passes. Queue item `tools-docs-tidy`.

### Path-scope helpers split the stage-list comments in run_state.sh

- Location: tools/run_state.sh:461
- Why: scope_paths and out_of_scope were inserted between the comment blocks of check_stages and main_stages (lines 451-460) and main_stages, so those comments now sit above scope_paths and main_stages has none.
- Fix: move the two helpers and their comments above line 451, leaving the main_stages comment directly above main_stages.

### Tests-only carry runs before the path scope in run_state.sh

- Location: tools/run_state.sh:503
- Why: the tests-only carry runs before the path scope, so a stage recorded scoped (never run) on a documentation-only commit is carried as carried-from after a later tests-only fix: dev-build is carried without building the binary test-run's smoke test uses, a false failure in that rare path.
- Fix: skip the carry for a record ending in scoped (let out_of_scope decide), with a tools_test.sh case.

### ci_scope.sh answer comment overruns its wrap and omits the tools line

- Location: tools/ci_scope.sh:31
- Why: the answer comment line runs far past the file's 72-column wrap and the next line still says GITHUB_OUTPUT keeps one run= and one reason= line, not the new tools= line.
- Fix: rewrap it and name the three lines.

### Records-only case labels ci_scope under RECORDS_RE

- Location: tools/tools_test.sh:1862
- Why: the records-only case now counts ci_scope by its documentation call yet still prints it under the label RECORDS_RE, which ci_scope.sh no longer names.
- Fix: drop ci_scope from that list (documentation is in rules.sh, already counted) or label the readers by what they call.

### The ci-stages secs filter is never run by a test

- Location: tools/run_state.sh:1250
- Why: the fake gh at tools/tools_test.sh:902 prints precomputed seconds, so the timestamp parsing of the new jq secs filter (and gojq's tonumber of a leading-dot string such as .44, whose error the // swallows into 0) is unproved (quality advisory, ci-time-tidy-b).
- Fix: capture only the digits and use ("0." + .f | tonumber), and add a case that feeds a jobs JSON through the same filter.

### The compile cache key is written three times across the CI workflows

- Location: .github/workflows/main.yml:52
- Why: the key expression is written twice in main.yml (probe and restore) and again in ci.yml, so a drift silently makes the probe never hit (every push compiles) or pull requests miss main's units (quality advisory, ci-time-tidy-b).
- Fix: compute the key once in a step output used by both steps, and add a tools_test case that the key text in ci.yml equals main.yml's.

### The check steps of main.yml are copied from ci.yml

- Location: .github/workflows/main.yml:95
- Why: the check steps (doctor, no-cruby, docs-lint, tools, config-current, test) are copied from ci.yml, so a check added to one workflow is easily missed in the other (quality advisory, ci-time-tidy-b).
- Fix: a tools_test case that every check step name of main.yml exists in ci.yml with the same run line, or a composite action both jobs use.

### The README and CLAUDE.md still say CI runs every other stage on the pull request

- Location: README.md:189, CLAUDE.md:231
- Why: the checker paragraph says CI runs the rest of CHECK_STAGES on the pull request, and CLAUDE.md that the Makefile records why CI leaves out two, but build now runs only on a push to main (quality advisory, ci-time-tidy-b).
- Fix: say the pull request runs the rest but the release build, which main.yml runs after the merge, and name the third stage in CLAUDE.md.

### The Makefile comment on the CI stages reads unclearly

- Location: Makefile:122
- Why: the comment 'Every other stage runs once, in CI, on every pull request, but build on main.' reads unclearly (quality advisory, ci-time-tidy-b).
- Fix: '... on every pull request, except build, which runs on a push to main (.github/workflows/main.yml).'

### An orphan line in the ci_scope.sh Environment comment

- Location: tools/ci_scope.sh:31
- Why: the Environment comment leaves an orphan line '# a pull request' after the CACHED insertion (quality advisory, ci-time-tidy-b).
- Fix: reflow the paragraph.

### The main workflow's compile probe ignores the measurement tool

- Location: .github/workflows/main.yml:47
- Why: the probe keys only on Ruby sources, so an equal-tree push that changes only tools/metrics.sh or the Makefile's budgets skips main's measurement and pull requests keep comparing with one made by the old tool; the design names build flags only (quality advisory, ci-time-tidy-b).
- Fix: add hashFiles of Makefile and tools/metrics.sh to the compile cache key in both workflows, or probe the measurement entry separately.

### A redundant ref test in the main workflow's Keep and Save steps

- Location: .github/workflows/main.yml:151
- Why: the Keep and Save steps test github.ref == 'refs/heads/main' beside github.event_name == 'push', which the main-only push trigger already implies (quality advisory, ci-time-tidy-b).
- Fix: drop the ref test.

### The scout step's README line says the area plan's figures are apart

- Location: README.md:187
- Why: the scout step says the area plan's figures are recorded apart from the scouts', but tools/run_state.sh tokens still keys the plan start under the workflow phase Scout, so metric.weighted.scout mixes both (design.md of scout-focus says so).
- Fix: say only phase.areas is apart, or run the area plan under its own phase.

### scoutPrompt joins blank locations

- Location: .claude/workflows/deliver-change.js:184
- Why: scoutPrompt joins every location, blank ones included, while scoutTargets keeps an area for one non-blank location, so a prompt can read 'Locations: , x'.
- Fix: have scoutTargets return the areas with their trimmed non-blank locations and join those.

### Scout tools_test cases grep the workflow source text

- Location: tools/tools_test.sh:2790
- Why: 'no scout start without a needed area' and 'the area plan is measured apart' grep the workflow's source text, so a reformatting breaks them and a logic change can pass.
- Fix: drop the source-text greps, since the scoutTargets cases already prove the behavior, or test the phase through a stubbed measured.

### scout-focus proposal omits the pack-currency rule

- Location: openspec/changes/archive/2026-11-16-scout-focus/proposal.md:10
- Why: What Changes and the Cases bullet (line 13) omit the fix round's rule that a pack is current only when its Locations: line covers every location, which design.md and tasks.md 1.4 and 2.2 carry.
- Fix: add a What Changes bullet for PACK_CURRENT and scout.md step 3 and name its cases in the Cases bullet.

### PACK_CURRENT and scout.md step 3 apply different currency rules

- Location: .claude/workflows/deliver-change.js:176
- Why: the comment says scout.md step 3 applies the same rule as PACK_CURRENT, but step 3 (.claude/agents/scout.md:35) also requires the same question while PACK_CURRENT ignores it, so the plan reuses a pack the scout itself would not.
- Fix: drop 'and question' from step 3 or add the question to PACK_CURRENT, keeping one rule.

### Pack-currency tools_test cases match prose by regex

- Location: tools/tools_test.sh:2795
- Why: the pack-currency cases (2795, 2797, 2798) match the prose of PACK_CURRENT, the workflow source, and scout.md by regex, so a rewording breaks them and they prove no behavior, the pattern of the advisory at tools/tools_test.sh:2790.
- Fix: keep one case that PACK_CURRENT reaches the area-plan prompt through a stubbed agent, or accept them as wording guards and say so in a comment.

### merged_on_main repeats supported
- Location: tools/run_state.sh:1121
- Why: quality advisory: merged_on_main repeats supported (tools/run_state.sh:1735) line for line, differing only in the base it reads.
- Fix: one helper taking the base, supported calling it after its shape check.

### unmerged_list duplicates pending_list's loop
- Location: tools/run_state.sh:1143 and tools/run_state.sh:1146
- Why: quality advisory: unmerged_list repeats pending_list's loop (state files, merged_commit, has_row) with only the merged_on_main test inverted, and append_history walks the run states twice.
- Fix: one loop that classifies each run once, pending_list and unmerged_list filtering its output, or pending_list taking a mode argument or printing never-merged runs to stderr.

### Planner does not know the beyond-the-sprint marker
- Location: tools/run_state.sh:287, .claude/agents/planner.md:25, docs/goals.md
- Why: quality advisory: the proposal says the planner writes the beyond-the-sprint marker, yet neither planner.md step 5 nor docs/goals.md names it, so only a hand edit of docs/queue.md ever marks an item and review-due's exception rule depends on memory.
- Fix: name EXCEPTION_MARK's words in planner.md's item parenthesis rule beside the pipeline-limit line, and in the sprint rule of docs/goals.md, for a change the user approves beyond the five.

### ToggleReading's call takes a Command it never reads
- Location: carat/use_cases/docs/toggle_reading.rb:39
- Why: a use case's call takes the state and its operation's inputs, but call(state, command) never reads the Command (quality advisory, markdown-reading-a)
- Fix: make it call(state), as PinHover, and have DocsHandler pass only the state

### DocsHandler names its variant action
- Location: carat/use_cases/actions/docs_handler.rb:20
- Why: the handler's variant is named @action/action: where the sibling handlers (BufferHandler) name it @variant/variant:, and 'action' already means the dotted action name (quality advisory, markdown-reading-a)
- Fix: rename it to variant

### The markdown-reading spec has no scenario for a closed source
- Location: test/use_cases_toggle_reading.rb:83
- Why: tests beside behavior: the new test cites scenario 'Toggling back to the source', but the delta spec has no scenario for the closed-source refusal (quality advisory, markdown-reading-a)
- Fix: add a scenario 'The source file was closed' (THEN the message 'The Markdown file is closed' shows and the view stays) to openspec/specs/markdown-reading/spec.md through a proposal and cite it in the test comment


### The finder lists hidden .ruby-lsp files the explorer hides
- Location: carat/plugins/finder/plugin.rb
- Why: a ruby-lsp project shows .ruby-lsp/Gemfile and .gitignore first in Ctrl-P while plugin.explorer.show_hidden false hides them
- Fix: apply the explorer's hidden and ignore rules to the finder's file list

## Findings of the sprint-8 review and sweep

### The main workflow skips the release build on a build-input-only equal-tree merge

- Location: .github/workflows/main.yml:47, tools/ci_scope.sh:45, .github/workflows/main.yml:155 (sprint-8 review, quality blocking, and security Low (5)); queued as `ci-workflow-tidy`.
- Why: the compile gate reads a lookup-only probe keyed on the .rb sources only, so an equal-tree squash merge that changes only the Makefile, tools/metrics.sh, bench/, spin.toml, or config/ skips the release build, its smoke test, and main's measurement; pull requests never build the release binary, so a broken `make build` merges unbuilt, where every push to main built it before sprint 8.
- Fix: in the equal-tree branch still list the squash commit's paths and compile when one is a build input; a tools-test case for a Makefile-only equal-tree push with cached units.

### rules.sh documentation() comment disagrees with TOOLS_RE on .claude/commands

- Location: tools/rules.sh:70 against :86 (sprint-8 review, quality); queued in `ci-scope-quoting`.
- Why: the comment says it is true only for paths no case reads, yet it is true for .claude/commands/*, which tools-test reads; only the separate TOOLS_RE check keeps tools-test running.
- Fix: return 1 for .claude/commands/* too, or say tools-test is decided by TOOLS_RE alone.

### Three path classifiers decide which stages run

- Location: tools/run_state.sh:233 TEST_ONLY, :242 NOT_COMPILED, :475 documentation plus TOOLS_RE (sprint-8 review, quality); queued in `ci-scope-quoting`.
- Why: three overlapping classifiers for one decision drift apart.
- Fix: derive TEST_ONLY and NOT_COMPILED from the rules.sh classifiers, or record why each differs.

### A docs/architecture.md-only change skips the tests that read it

- Location: tools/rules.sh:73, test/lint.rb:772 and :1285 (sprint-8 sweep, quality, correctness); queued in `ci-scope-quoting`.
- Why: documentation() counts docs/architecture.md as documentation, but lint compares its section 6 port table with the ports, so such a change skips the test stage in CI and the checker and can merge a table the next code change fails on.
- Fix: return 1 for docs/architecture.md beside docs/actions.md, with a tools-test expect case.

### ci_scope.sh splits path lists on blanks

- Location: tools/ci_scope.sh:99 and :123 (sprint-8 sweep, quality); queued in `ci-scope-quoting`.
- Why: `for path in $changed` splits and globs, so a path with a space is judged piece by piece and can skip the checks.
- Fix: read the lists line by line with `while IFS= read -r path`, or set -f and a newline IFS around the loops.

### ci_scope.sh fetches one pull request twice

- Location: tools/ci_scope.sh:80 (sprint-8 sweep, quality); queued in `ci-scope-quoting`.
- Why: two identical gh api calls on the commit's pulls fetch the head sha and the number separately.
- Fix: one call whose jq prints both fields, split with read.

### ci_scope.sh answer comment overruns its wrap

- Location: tools/ci_scope.sh:42 and :30 (sprint-8 review, quality); queued in `ci-scope-quoting`.
- Why: the answer line runs to 110 columns and the Environment comment breaks mid-sentence.
- Fix: rewrap both comment blocks.

### The sprint exception membership test is written three times

- Location: tools/run_state.sh:1494, :1582, :1624 (sprint-8 review, quality); queued in `sprint-marker-tidy`.
- Why: the same index(" list ", " name ") trick in sprint_state, sprint_row, and groom.
- Fix: filter the counted names once in sprint_state and pass them, or one helper.

### EXCEPTION_MARK names clash with the user-approved exception

- Location: tools/run_state.sh:289, :1507 (sprint-8 review, quality); queued in `sprint-marker-tidy`.
- Why: EXCEPTION_MARK, exception_item, and sprint_exceptions mean beyond the sprint while the user-approved exception of tools/docs_lint.sh:157 only lifts the pipeline limit, so a comment has to warn about the clash.
- Fix: rename to BEYOND_SPRINT_MARK, beyond_sprint_item, sprint_beyond.

### docs-lint counts beyond-the-sprint items in the sprint cap

- Location: tools/docs_lint.sh:154 (sprint-8 review, quality); queued in `sprint-marker-tidy`.
- Why: run_state.sh leaves marked items out of the five, but docs-lint counts every numbered item, so five items plus one marked fail docs-lint though review-due accepts them.
- Fix: leave items whose parenthesis holds the mark out of the count, with a docs_lint case.

### CLAUDE.md's Sprints bullet omits the beyond-the-sprint mark

- Location: CLAUDE.md:213, README.md:196 (sprint-8 review, quality); queued in `hook-one-place`.
- Why: the bullet says the sprint closes at the fifth merge review-due counts and never names the mark it now leaves out; only README.md and run_state.sh name it.
- Fix: add the mark to the Sprints bullet and to planner.md.

### Sprint-8 tools_test cases grep scout and workflow prose

- Location: tools/tools_test.sh:2833, :2836, :2840, :2936 (sprint-8 review, quality); queued in `prose-grep-cases`.
- Why: the cases grep scout.md steps and contributorTask text; they break on rewording and prove no behavior.
- Fix: fold into `prose-grep-cases`, keeping the js-evaluated helper cases.

### The merge gate and resume trust review records branch code can write

- Location: tools/gates.sh:415, tools/run_state.sh:610 (sprint-8 sweep, security Medium (6)); queued in `gate-object-pin`.
- Why: gate_passed and the resume read run-state review records that executed branch code can write, and the check clone links back into the project through tmp/.toolchain.
- Fix: keep review records where branch code cannot write them (a workflow-held key, a signed record, or check runs the workflow posts), verify them in the gate and the resume, and drop the link back.

### A pull request's own scan.yml runs its scan

- Location: .github/workflows/scan.yml:13 (sprint-8 sweep, security Low (7)); queued in `ci-hardening`.
- Why: the pull_request event runs the pull request's copy of scan.yml, so a pull request editing it passes its own scan despite the base scanner.
- Fix: run the scan from the base's workflow reading the head only as data, or have the merge gate refuse a scan.yml change without the user's approval.

### Actions pinned to mutable tags beside a token

- Location: .github/workflows/open-pr.yml:45, ci.yml, main.yml (sprint-8 sweep, security Low (5)); queued in `ci-hardening`.
- Why: actions/checkout is pinned to the v4 tag in the job that later reads PR_TOKEN.
- Fix: pin every action to a full commit hash.

### The tab width fallback is copied in ten places

- Location: carat/use_cases/dispatcher.rb:112, arrange_view.rb:43, repeat_last.rb:104, insert_tab.rb:25, leave_insert.rb:69, adapters/frame_presenter.rb:216, domain/operators.rb:172, :251, :272, display_width.rb:57 (sprint-8 sweep, quality); queued in `editing-dedup-a`.
- Why: `tabstop > 0 ? tabstop : 8` repeats Options#tab_width (carat/domain/options.rb:131), on the per-key path too, and Options already keeps tabstop at 1 or more.
- Fix: call options.tab_width, passing the width into the domain helpers.

### Editing helpers repeat existing ones

- Location: carat/use_cases/operate.rb:204 and repeat_last.rb:117 (clamp repeats EditorState#clamp_col), carat/domain/operators.rb:271 (indent_width repeats DisplayWidth.column; the shift step written at :172 and :251), carat/use_cases/visual/put_over_selection.rb:126 (repeated duplicates Operators.put's loop at operators.rb:42) (sprint-8 sweep, quality); queued in `editing-dedup-a`.
- Why: four private copies of logic the domain already holds.
- Fix: call state.clamp_col, DisplayWidth.column, one shift-width helper, and one Operators function for repeated lines.

### Small core code nits from the sweep

- Location: carat/domain/walker.rb:63 (calls Motions.code_class without requiring motions.rb, a cycle hidden by load order), carat/domain/runs.rb:18 and text_objects.rb:86 (`cls`), carat/use_cases/handle_key.rb:384 and search/find_match.rb:68 (bare key codes 40, 44, 47, 63), carat/adapters/input_controller.rb:128 (both branches call handle), carat/use_cases/completion/show_completion.rb:96 (`[0]` then clear), carat/domain/range.rb:4 (stale comment), carat/domain/buffer.rb:472 (blanks public) (sprint-8 sweep, quality); queued in `editing-dedup-b`.
- Why: a hidden require cycle, a named abbreviation, magic numbers, duplication, an idiom against the codebase, a false comment, and needless public surface.
- Fix: a small CharClass module the three callers require; `char_class`; named Domain::Key constants; one handle call; `Array.new(0, 0)`; drop the sentence; move blanks below private.

### Buffer#line reads the last line for a negative row

- Location: carat/domain/buffer.rb:406 (sprint-8 sweep, quality); queued in `core-correctness-b`.
- Why: the method says it gives an empty string outside the buffer but `lines[-1]` answers a negative row; every caller guards today.
- Fix: return "" when row < 0, with a domain_buffer test row.

### A count grows without bound

- Location: carat/domain/command_grammar.rb:97 (sprint-8 sweep, quality); queued in `core-correctness-b`.
- Why: digit grows count without a cap and take multiplies the operator count, so a long digit run passes Vim's 999999999 and the 64-bit range, and a huge count can stall an insert repeat.
- Fix: clamp the count and the product at 999_999_999, with a test in test/domain_grammar.rb.

### The language gateway holds a URI codec, UTF-16 walkers, and missing requires

- Location: carat/adapters/json_rpc_language_gateway.rb:774 and :1328 (URI codec), :1089 and :1135 with carat/use_cases/definitions/visit_target.rb:204 (three UTF-16 walkers), :1 and carat/drivers/process_runner.rb:1 and carat/use_cases/plugins/plugin_registry.rb:1 (names constants they do not require) (sprint-8 sweep, quality); queued in `gateway-split-a`.
- Why: the 1,374-line gateway keeps conversions no protocol state needs, three copies of one walk, and compiles alone only through carat.rb's order.
- Fix: Domain modules for the file URI and UTF-16 with table tests, the gateway and VisitTarget calling them; add the require_relative lines.

### The gateway repeats its request send, cancel, and start paths

- Location: carat/adapters/json_rpc_language_gateway.rb:691 and :838 (send_definition and send_hover alike), :594, :665, :719, :865, :945, :998 (six cancels), :222 (restart repeats start), :268 (listed public), :208 (waiting? comment) (sprint-8 sweep, quality); queued in `gateway-split-b`.
- Why: 22 duplicated lines, six copies of one cancel, a repeated start tail, and public surface only the class calls.
- Fix: one cursor-request send and cancel path, one private start tail, listed below private, the comment completed.

### PluginHost builds what EditorAssembly should share

- Location: carat/use_cases/plugins/plugin_host.rb:73 and :78, carat/adapters/editor_assembly.rb:431 (sprint-8 sweep, quality, found twice); queued in `plugin-host-tidy`.
- Why: PluginHost builds its own ResolveInside, MakePath, RenamePath, DeletePath, ListTree, registry, router, events, and families, so test/adapters_assembly.rb cannot check they share one instance.
- Fix: build them in the assembly, pass them in, and extend the one-instance check.

### Plugin host code repeats itself and breaks two record rules

- Location: carat/use_cases/plugins/window_requests.rb:95 with ui_requests.rb:82 (binding errors loop), window_requests.rb:179 (split save and restore beside in_window at :303), buffer_requests.rb:144 with window_requests.rb:344, :347 (cursor_on), plugin_events.rb:205 (detail uncopied), pending_event.rb:9 (Struct never mutated), plugin_registry.rb:175 (recomputes cause), ui_requests.rb:123 and 4 more files (`e` for an entry), carat/plugins/explorer/plugin.rb:194, :331, :404, :422 and :160 (cursor_to and toggle) (sprint-8 sweep, quality); queued in `plugin-host-tidy`.
- Why: duplicated helpers, a string crossing the plugin boundary uncopied, a Data value written as a Struct, and an unclear abbreviation.
- Fix: one record_bindings, splits through in_window, one cursor helper, `detail.dup`, a Data subclass, `= cause`, `entry`, and a private cursor_to with toggle calling focus.

### ShowHover repeats the definition float's placement

- Location: carat/use_cases/docs/show_hover.rb:74, carat/use_cases/definitions/open_definition_float.rb:29 (sprint-8 sweep, quality, found twice); queued in `hover-tidy`.
- Why: the below-or-above room, height clamp, width loop, and bordered FloatSpec are copied line for line.
- Fix: one cursor-float use case taking the built buffer, both callers using it.

### The map omits public methods in several areas

- Location: docs/codebase-map.md:232 (Registers, Selection, ExTable, Layout, BufferList), :99 (Options), :153 (CommandGrammar), :530 and :536 (PluginApi::Paths, PluginHost, PluginRegistry) (sprint-8 sweep, quality); queued in `architecture-docs`.
- Why: entries miss methods callers use, so the map misleads a scout.
- Fix: bring the method lists in line with the code.

### Testing's comment names spin test as the snapshot runner

- Location: carat/testing.rb:4, docs/architecture.md:425 (sprint-8 sweep, quality); queued in `architecture-docs`.
- Why: both say spin test diffs the output against the snapshot, while tools/run_tests.sh compares it and spin test is never run.
- Fix: name tools/run_tests.sh in both places.

### The close start returned a placeholder with no tool calls
- Location: .claude/workflows/deliver-change.js, the close (retrospective) start of markdown-reading-a (#146), run state notes 8 and 9
- Why: twice in one run the retrospective start returned a placeholder after no tool calls, so the main session ran its record line by hand and corrected the merger's squash commit (67562e699059 stored for 67562e69905c); the run's last records depend on that start
- Fix: refuse a close result made with no tool calls and restart it once, or record the run's last lines without the model; accepted when a stubbed placeholder close is refused by a case and the record line still lands

### Code map entries lack the git-signs-status-a methods
- Location: docs/codebase-map.md:547, 608, 617, 629
- Why: the map is not current: file_requests.rb lacks run_program, process_port.rb and process_runner.rb lack capture, fake_processes.rb lacks script, capture, and captured.
- Fix: add them to the four entries.

### plugins.md names the wrong run_program message for non-UTF-8 output
- Location: docs/plugins.md:79
- Why: the run_program row says it fails with "cannot run git" for non-UTF-8 output, but the message is "git answered bytes that are not UTF-8".
- Fix: name both messages.

### ProcessRunner#capture override lacks its return in prose
- Location: carat/drivers/process_runner.rb:76
- Why: capture overrides the port with only a `# @rbs argv:` line and no return in prose, against the inline RBS rule for overrides.
- Fix: add a comment stating it answers the output or nil.

### run_program lives in the FileRequests family
- Location: carat/use_cases/plugins/file_requests.rb:23
- Why: running a program lives in FileRequests, a family named for files, so its name and doc no longer say what it holds.
- Fix: move run_program into its own ProgramRequests family, or rename the family at the sprint-end review.

### run_program path test rewrites the message before comparing
- Location: test/use_cases_plugins.rb:389
- Why: the assertion rewrites the message with .sub("/usr/bin/git", "./git") before comparing, which hides what is asserted.
- Fix: assert the literal "/usr/bin/git: the program must be a name on the PATH".

### Process runner deadline test waits the full two seconds
- Location: test/drivers_process_runner.rb:60
- Why: the deadline test waits the full 2-second CAPTURE_SECONDS on every make test run.
- Fix: accept it knowingly, or let the driver take the deadline as a constructor keyword so the test passes a short one.

### git_signs tests counts.length == 2 twice
- Location: carat/plugins/git_signs/plugin.rb:76
- Why: the same condition is tested twice.
- Fix: return early with the branch text when counts.length != 2, then read both counts.

### capture now times out on exactly 64 KiB with stdout held open
- Location: carat/drivers/process_runner.rb:110
- Why: the loop waits for a byte past CAPTURE_LIMIT or the end, so a program printing exactly 65,536 bytes and holding stdout open (a background child) now times out to nil where it answered before.
- Fix: keep the < loop and trim an incomplete trailing sequence of the kept 64 KiB with the Domain::Utf8 character-size logic instead of reading past the limit.

### ProcessRunner class comment describes the old capture loop
- Location: carat/drivers/process_runner.rb:15
- Why: the class comment still says capture reads until CAPTURE_LIMIT bytes are kept, while collect now reads past the limit and cuts before a character.
- Fix: reword the class comment to match collect's.

### cut_point carries a guard that cannot fail and belongs in Domain::Utf8
- Location: carat/drivers/process_runner.rb:131
- Why: the at > 0 guard can never fail (at starts at CAPTURE_LIMIT and drops at most 3), and a backward UTF-8 boundary belongs beside Domain::Utf8.boundary.
- Fix: drop the guard and move cut_point to Domain::Utf8 as the backward counterpart of boundary.

### git_signs activation test does not assert the startup activation
- Location: test/editor_git_signs.rb:70
- Why: the scenario calls plugins.activate_all a second time on an editor the harness already activated before git was installed, a state bin/carat never reaches, so the startup activation itself is not asserted.
- Fix: let EditorHarness take a processes double prepared before construction (or a with_plugins variant) and assert the first activation.

### git_signs split assertion cannot tell whether the split refreshed
- Location: test/editor_git_signs.rb:61
- Why: the assertion 'a split keeps the branch' runs while git still answers main, so it cannot tell whether the split refreshed.
- Fix: drop it, or script another branch before the window split if the split's refresh matters.

### plugin-host spec lacks a scenario for cutting before a character
- Location: openspec/specs/plugin-host/spec.md (from the archived change git-signs-status-a, delta spec line 4)
- Why: the requirement cuts before a character the limit would split, but no scenario names that and the test at test/drivers_process_runner.rb:62 names none.
- Fix: add a scenario such as 'Long output is cut before a character' and label the driver test with it.

### merged_since clears a periodic security finding on a merge planned before it

- Location: tools/run_state.sh:1726
- Why: security Low (4). merged_since clears a failing periodic security review on any later merge, including one whose delivery started before the review was recorded; a delivery planned (or plan-skipped) before a /review records a blocking finding merges afterwards, so plan-needed treats the finding as seen by a planner and later queue-head deliveries skip the security-first stop. A gap in the new trigger, not a regression.
- Fix: count only a merge whose planner start came after the review was recorded, for example by storing the review run's name or time in the merged run's state when its planner or plan-needed saw it and having merged_since require that marker instead of commit ancestry alone, or keep the trigger until a planner start records that it read the review run.

### merged_since reads only the last metrics row's merged commit

- Location: tools/run_state.sh:1729
- Why: quality advisory. Metrics rows follow run-state order, not merge order, so a later merge in an earlier row is missed and the planner keeps running; the pending loop also adds a subprocess per state file.
- Fix: since every commit on main is a squash merge, test that origin/main descends from COMMIT and differs from it.

### No case for a passing periodic security review in plan-needed

- Location: tools/tools_test.sh:1321
- Why: quality advisory. No case shows that a passing periodic security review, or a partial one with blocking=0, leaves plan-needed not needed, the filter of tools/run_state.sh:1767-1770.
- Fix: add a pass "... blocking=0" case expecting ^not needed.

### sprint_state picks an exception past the fifth counted row

- Location: tools/run_state.sh:1502
- Why: quality advisory. sprint_state picks the exception from every name merged since the last sprint while sprint_row (tools/run_state.sh:1599) now ends at the fifth counted row, so review-due names an exception (x1 in tools/tools_test.sh:1178) that the groomed row leaves out and that then spends the next sprint's one exemption, x2 counted.
- Fix: pick sprint_exceptions only among the names before the SPRINT_SIZE-th counted one, so review-due, groom, and the row read the same window.

### A resumed delivery clears a periodic security review unseen

- Location: tools/run_state.sh:1723
- Why: quality advisory. merged_since clears a failing periodic security review at any later merge on the premise that the merging change's planner saw it, but a delivery resumed past its plan phase (phase.plan or phase.implement recorded before the review) skips the planner and still clears it unseen; the review-coverage design names this risk.
- Fix: clear only on a merged change whose run state records phase.plan after the review was recorded, or keep the record until a later periodic security review passes.

### plan_needed lists run states differently from pending_list

- Location: tools/run_state.sh:1753
- Why: quality advisory. plan_needed lists run states with ls piped to sed and grep while pending_list (tools/run_state.sh:1142) globs the state directory's json files; one clear way to do each thing.
- Fix: loop over the state directory's json files with basename and a case on REVIEW_RUNS as pending_list does.

### Unwrapped comment lines in run_state.sh

- Location: tools/run_state.sh:1726
- Why: quality advisory. Comment lines are left unwrapped beside wrapped ones (also tools/run_state.sh:1747), against the file's comment style.
- Fix: rewrap both comments at the width of the surrounding lines.

### merged_since decides planned after the review from commit ancestry, not from when the review was recorded
- Location: tools/run_state.sh:1731 (security Low, confidence 4, review-coverage-b)
- Why: when /review runs at the same time as a delivery, a planner that never saw a failing periodic security review can clear it: the review reads origin/main at X, another change merges to X', and a delivery started at X' runs its planner before the review is recorded; its phase.plan strictly descends from X, so its merge clears the review and the blocking finding never reaches the planner's security-first stop.
- Fix: record in the delivery's run state which failing review run plan-needed handed to the planner (for example metric.plan_review=RUN at REVIEWED_COMMIT, written when planReview(planLine) is non-empty) and let merged_since clear a review only when a merged, planned change recorded that same run and commit; alternatively compare the review record's write time with the time phase.plan was written, not their commits.

### passed_since lets a diff-only sprint security review supersede a failing whole-tree periodic security review
- Location: tools/run_state.sh:1760 (security Medium, confidence 6, review-coverage-b)
- Why: a /review whole-tree sweep fails at commit C with a blocking finding in untouched code; deliveries planned before C merge and close the sprint; the sprint-N combined-diff review passes at a later tip without reading the flagged file; passed_since then treats the failing review as superseded and plan-needed stops putting it in front of the planner's security-first stop although the finding was never fixed. REVIEW_RUNS ('^(review|sprint)-[0-9]') matches sprint-N, while the function's comment says whole-tree. Narrow path; the sprint-mode planner may still see the run in pending.
- Fix: in passed_since accept only whole-tree records: skip any record whose summary begins with 'diff' (sprint-N runs, as sprint-planning.js line 162 writes them), or restrict the run names to review-* and sprint-N-sweep; add a tools_test case where a later 'pass COMMIT diff ... blocking=0' record leaves the failing review in force.

### planned_commits re-implements the run-state key parsing of read_key
- Location: tools/run_state.sh:1752 (quality advisory, review-coverage-b)
- Why: duplication: the run-state JSON format gets a second parser that can drift from read_key.
- Fix: reuse read_key or one shared multi-key reader so the run-state format has one parser.

### plan_needed and merged_since comments run past the comment wrap
- Location: tools/run_state.sh:1780 and tools/run_state.sh:1729 (quality advisory, review-coverage-b)
- Why: a line of the plan_needed comment ('overrun, a periodic finding) that only the planner places; otherwise the head item ...') runs past the block's wrap, and the merged_since comment appends 'A COMMIT git does not know is never merged since.' past it.
- Fix: rewrap both comments.

### plan_needed lists review runs by parsing ls output
- Location: tools/run_state.sh:1786 (quality advisory, review-coverage-b)
- Why: parsing ls output is fragile shell.
- Fix: iterate "$state_dir"/*.json with a glob, strip the suffix, and match REVIEW_RUNS with case or grep on the name.

### plan-needed wording says no change merged since though a merge planned before the review no longer counts
- Location: tools/run_state.sh:1798, .claude/workflows/deliver-change.js:977, README.md pipeline step 1 (quality advisory, review-coverage-b)
- Why: the plan-needed line 'and no change merged since', the planReview comment ('no merge since'), and the README step ('failed with no change merged since whose planner ran after it') misstate or garble the rule now that a merge planned before the review does not count.
- Fix: say 'no change planned after it has merged since' in all three.

### passed_since lets a sprint-N diff pass supersede a whole-tree review contrary to its comment
- Location: tools/run_state.sh:1763 (quality advisory, review-coverage-b)
- Why: passed_since lists every REVIEW_RUNS run, so a sprint-N run's periodic-security pass, which reviewed only the sprint's combined diff, supersedes a failing whole-tree review, though its comment says a later whole-tree review supersedes it.
- Fix: list only review-DATE runs there, or say in the comment and proposal that a sprint-diff pass counts.

### Review-run listing and reviewed-commit resolution are repeated
- Location: tools/run_state.sh:1763 and tools/run_state.sh:1818 (quality advisory, review-coverage-b)
- Why: the review-run listing (ls state_dir, sed, grep REVIEW_RUNS) is repeated, and merged_since and passed_since each validate and rev-parse the same reviewed commit.
- Fix: extract a review_runs helper and resolve the reviewed commit once in plan_needed, passing the full commit to both.

### plan-needed needed line omits the later passing review condition
- Location: tools/run_state.sh:1828 (quality advisory, review-coverage-b)
- Why: the needed line still says 'and no change merged since' though passed_since now also has to fail.
- Fix: say 'no change planned and merged since nor a later periodic security review passed' and adjust the tools_test expectations.

### run_state.sh header plan-needed line and plan_needed comment have over-long lines
- Location: tools/run_state.sh:187, tools/run_state.sh:1807, tools/run_state.sh:1812 (quality advisory, review-coverage-b)
- Why: comment wrapping: over-long lines and a broken wrap.
- Fix: rewrap both to the file's comment width.

### history_rows walks the whole rev-list on every call
- Location: tools/run_state.sh history_rows
- Why: groom calls it twice and status once, each walking HEAD and BASE
- Fix: compute it once per command and pass the rows

### A resume past the push cannot answer a new blocking review
- Location: .claude/workflows/deliver-change.js resume past the push (the blocked-on-resume stop) and tools/run_state.sh push
- Why: twice (review-coverage, backlog-lane-a) a resumed quality review raised new blocking findings at the pushed head and the run could only stop, costing a redelivery
- Fix: let a resume past the push run one fix round whose push counts as a review fix, or demote a resumed review to the findings the last pass did not already settle

### lane_of misses a queue item that estimate_of and exception_item find
- Location: tools/run_state.sh:1187 lane_of, estimate_of (1301), exception_item (1617)
- Why: each parses the queue item "N. `NAME`" with its own awk and lane_of alone requires "` (" after the name, so an item like "`git-panel` plugin (" gets an estimate but no lane and falls back to the feature lane
- Fix: one queue_item COMMIT NAME helper all three read, with a tools-test case for an item whose name is followed by a word

### authoring-kit sits in the backlog lane against the migration rule
- Location: docs/metrics-backlog.tsv:4
- Why: its merged commit e375e4cfa5cf is held by no ref, and the proposal sends a row without a known commit to the feature lane, which lane authoring-kit prints, so the history and the lane disagree
- Fix: move the row to docs/metrics-feature.tsv, or state the exception in the archived design

### metrics_files breaks on a METRICS_PREFIX holding a space
- Location: tools/run_state.sh:236 metrics_files and every for f in $metrics_files
- Why: the space-joined list is split unquoted, so a prefix with a space breaks history, status, and bench where the quoted METRICS_FILE did not
- Fix: loop over the lane names and quote "$metrics_prefix-$l.tsv"

### No plan-needed case heads the feature lane
- Location: tools/tools_test.sh:1360
- Why: every plan-needed case puts the head in docs/queue-backlog.md, so nothing proves a change heading docs/queue-feature.md is taken as written
- Fix: add an expect with the change as item 1 of docs/queue-feature.md printing not needed: NAME heads docs/queue-feature.md

### The planner's size check lost the output-only rows caveat
- Location: .claude/agents/planner.md:23
- Why: rows before pipeline-speed hold output tokens only and remain in both lane histories, so a total-token estimate read from them is skewed low; the clause did not fit the file's budget in this change
- Fix: restore the one-clause caveat, making room by pointing to a note elsewhere in the file


### Relative PATH entries let git_signs run a project's ./git

- Location: carat/drivers/process_runner.rb:98, carat/use_cases/plugins/file_requests.rb:139 (sprint-9 review, security Low (5)); queued in `process-capture-hardening`.
- Why it matters: run_program looks the program up on the PATH and the no-slash check does not stop a relative or empty PATH entry (".", "::", a trailing ":"); git_signs is on by default and runs git when it activates, so opening carat in a checkout shipping an executable ./git runs it with no user action.
- Fix outline: resolve argv[0] against only the absolute PATH directories, spawn the absolute path found, refuse when none is found; a driver test with PATH=".:..." and a planted program in the working directory.

### capture leaves a child past the output limit running

- Location: carat/drivers/process_runner.rb:87 (sprint-9 review, quality); queued in `process-capture-hardening`.
- Why it matters: capture kills the child only on timeout; when the output passes CAPTURE_LIMIT it closes the pipe and detaches, so a child ignoring SIGPIPE runs on with no deadline.
- Fix outline: kill the child unless collect read the output to its end; a case with a SIGPIPE-ignoring child.

### Review runs and full commits are looked up in several places of run_state.sh

- Location: tools/run_state.sh:1763 and :1818 (sprint-9 review, quality); queued in `sprint-marker-tidy`.
- Why it matters: passed_since and plan_needed repeat the review-run listing (ls of the state directory, sed, grep REVIEW_RUNS), and merged_since, passed_since, and supported repeat the valid check plus git rev-parse --verify of a full commit, so a fix lands in one copy only.
- Fix outline: add review_runs and full_commit helpers and call them from each place.

### The core Branch slot row of docs/compatibility.md contradicts the git_signs segment

- Location: carat/domain/status_slots.rb:18, carat/adapters/status_bar.rb:164 and :241, docs/compatibility.md:466 and :468 (sprint-9 review, quality); queued in `ui-code-tidy` beside "## The status bar's branch slot has no writer".
- Why it matters: only tests fill the core branch slot while git_signs draws the branch as its own segment at the same priority 40, yet the compatibility row says the core slot shows it.
- Fix outline: remove the slot from StatusSlots and StatusBar and fold the row into the git_signs row, or have the plugin fill the core slot.

### backlog-pick dies on an unmatched findings glob
- Location: .claude/agents/planner.md:35 and .claude/workflows/sprint-planning.js:150, with tools/run_state.sh:1760
- Why: the planner and sprint-planning call backlog-pick docs/backlog.md docs/findings/*.md, but groom removes every findings file (tools/run_state.sh:1973), so a sprint whose changes left no findings passes the literal glob and the pick fails with no docs/findings/*.md.
- Fix: have backlog_pick skip an unmatched literal glob argument, or have the callers name only existing files.

### backlog-pick tries each backticked path twice
- Location: tools/run_state.sh:1831
- Why: candidates re-adds every backticked pathlike token in the bare-word pass after stripping the backticks, so each one is looked up twice, wasted work on every entry.
- Fix: run the bare-word pass over the Location with the backticked spans removed instead of only the backticks.

### Top-level docs findings never reach a batch
- Location: tools/run_state.sh:1757
- Why: entries at README.md, CLAUDE.md, and docs/ paths are always unmapped since docs/codebase-map.md names no numbered area for them, so docs findings never reach a backlog-lane batch and only a planner decision mentions them.
- Fix: map the top-level docs in an area of docs/codebase-map.md, or batch unmapped entries as their own docs item.

### No case pins a bare directory word known only by its files
- Location: tools/run_state.sh:1821
- Why: a bare backticked directory word the map does not name itself but that holds mapped paths (`tools` with only tools/a.sh mapped) prints unmapped, while the same directory with a slash is placed by dir_area; the header documents the asymmetry but no tools_test case pins it.
- Fix: in named_file accept a word for which dir_area of the word with a slash is non-empty and the tree holds it, with a tools_test case, or add a case pinning the unmapped result.

### The contributor's list of the other agents' phases drops the benchmark
- Location: .claude/agents/contributor.md:14
- Why: the benchmark still runs as its own phase, so the list misleads a reader of the agent; the fix did not fit the file's budget without a trim after the reviews
- Fix: restore benchmark to the list, trimming six bytes elsewhere in the file


### open-pr pins its actions by tag beside PR_TOKEN (security Low, confidence 6)
- Location: .github/workflows/open-pr.yml:46
- Why: actions/checkout and actions/cache are pinned by tag in the job that holds PR_TOKEN, so a moved tag would run foreign code beside the token
- Fix: pin every action to a full commit sha with the tag in a comment

### Incremental sync misses a reload that only changes the line ending
- Location: carat/adapters/json_rpc_language_gateway.rb:1356
- Why: an :e! reload that only changes the line ending (OpenFile sets line_ending, open_file.rb:60) leaves the stored lines equal, so under sync kind 2 nothing is sent and the server keeps the old terminators, mixed after later ranged edits (positions stay right).
- Fix: store the line ending sent beside the remembered texts and replace the whole document when it changed.

### No replayed incremental sync row over a CRLF buffer
- Location: test/adapters_language_gateway.rb:112
- Why: no replayed row covers a CRLF buffer under sync kind 2, though the design relies on ranges joined with the buffer's own ending staying right.
- Fix: add a replayed row over a CRLF file to the sync kind 2 table.

### Documentation floats draw tables with no test or spec saying so

- Location: carat/use_cases/docs/format_docs.rb:38, test/adapters_hover.rb, README.md, openspec/specs/markdown-reading/spec.md
- Why: parse now draws tables at the width for the K and completion documentation floats too, but the spec and README name only the reading view and no hover test shows a table, so the float behavior is unproven.
- Fix: say in the README sentence on the floats and in the spec that documentation floats draw tables the same way, and add one float row with a table to test/adapters_hover.rb.

### MarkdownText.split_cells copies each cell a character at a time

- Location: carat/domain/markdown_text.rb:219
- Why: each cell is built by one byteslice per character, an allocation per byte on every table row parsed for the reading view and the floats.
- Fix: track the cell's start byte and byteslice the whole run at each unescaped pipe.


### Lane worktree trusts a branch-controlled build/pipeline
- Location: tools/run_state.sh:2347 (lane_open), the green line of .claude/workflows/deliver-change.js
- Why: security Medium (5): a branch that force-adds build/pipeline, as a directory or a symlink, stops lane-open from linking the lane to the main checkout's run state, so the merge gates running inside the lane read branch-controlled stage records, push counts, and body file instead of the workflow's own records.
- Fix: in lane_open refuse when git -C "$dir" ls-files lists anything under a LANE_LINKS path, or when "$dir/$l" exists but is not a symlink to "$top/$l"; pass gates.sh merge an absolute RUN_STATE_DIR and STAGE_DIR of the main checkout and read the body file from its absolute path.

### Merger's lane-close and contributor's merge-main accept any change name
- Location: tools/agent_guard.sh:600-601
- Why: security Low (4): the merger profile admits run_state.sh lane-close with any arguments, unlike push and set beside it, so a misled or prompt-injected merger could force-remove another running delivery's worktree and lose its uncommitted work; merge-main is admitted the same way.
- Fix: require [ $# -eq 2 ] and matches "$2" "$CHANGE_NAME" for both, as contributor:push does, with one refusing guard case each in tools/tools_test.sh.

### merge_main runs git merge with global configuration and hooks
- Location: tools/run_state.sh:2391 (merge_main)
- Why: security Low (3): a plain git merge reads global and system configuration and runs hooks, both writable by branch code the checks run, which is why the fetches and the merge-gates worktree use pinned git.
- Fix: run the merge through pinned_git (GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1, -c core.hooksPath=/dev/null), keeping the core.attributesFile and identity -c options.

### merge_main hides a merge failure that is not a conflict
- Location: tools/run_state.sh:2397 (merge_main)
- Why: correctness: git merge's output goes to /dev/null, so a failure that is not a conflict (an untracked file it would overwrite, a missing ref) reports conflicts with no file named, and the silent git merge --abort then fails.
- Fix: keep git's stderr and print it when no file is unmerged, aborting only when a merge is in progress.

### Concurrent lanes race on the shared origin/main ref lock
- Location: tools/run_state.sh:2388 (merge_main) and the green line's fetch
- Why: correctness: two lanes share one .git and both fetch +refs/heads/main:refs/remotes/origin/main, so concurrent deliveries can fail on the ref lock.
- Fix: retry the fetch once on failure, or fetch into a per-lane ref such as refs/lanes/<change>/main.

### lane_open and lane_close remove a worktree by different steps
- Location: tools/run_state.sh:2332 (lane_open), :2366 (lane_close)
- Why: correctness: lane_open removes a replaced run's worktree directly while lane_close removes the toolchain links first so no removal can reach their targets; the two paths can diverge in safety.
- Fix: share one lane_remove helper (links first, then git worktree remove --force) from both.

### MERGE_MAIN tells a continuation start to merge over a dirty tree
- Location: .claude/workflows/deliver-change.js:702, tools/run_state.sh:2385
- Why: correctness: every implement and fix start is told to run merge-main first, but merge_main dies on a dirty tracked tree, so a continuation over uncommitted work exits 1 before it starts.
- Fix: say to run it when the tracked tree is clean, else after the next commit.

### Lane and merge-main refusals have no tools-test case
- Location: tools/tools_test.sh:1593; tools/run_state.sh:2330, :2365, :2383-2385
- Why: missing test: no case covers lane-open or lane-close over a non-worktree tmp/.lane-CHANGE, nor merge-main on a detached HEAD, on main, or with a dirty tracked tree.
- Fix: add one refusing expect case each.

### The sprint's records change merges past a blocking sprint security finding
- Location: .claude/workflows/sprint-planning.js:196
- Why: security Low (4): the records change sprint-N-records is delivered even when the sprint plan returns security_first or the sprint's combined-diff review found blocking findings; it skips the planner (plan_needed returns not needed for a records change and checks only periodic security reviews), so the security-first stop never runs for it, weakening the rule that blocking security fixes go first. A process-gate gap, not directly exploitable: the change writes only docs records and gets its own security review.
- Fix: deliver the records change only when `!(plan.security_first || []).length && !blocking.length` holds at line 196, otherwise report that it waits for the security fix; or have plan_needed treat a blocking sprint-N security review record as needing the planner.

### The not-due parseDue case uses review-due's old text
- Location: tools/tools_test.sh:3442
- Why: missing test: the case feeds parseDue 'for the next package step', which review_due no longer prints (now 'for its records change, sprint-N-records'), so the case no longer tracks the real output and a regression in parsing the new line goes unseen.
- Fix: use review_due's current not-due line in the fixture, or capture it from review_due itself.

### lane_of prints the shell's error for a missing queue file
- Location: tools/run_state.sh:1264
- Why: correctness: `item_named < "docs/queue-$l.md" 2>/dev/null` opens the input before stderr is redirected, so a missing queue file still prints the shell's error into the command's output.
- Fix: put 2>/dev/null before the input redirection, or test -f the queue first.

### The one review fix round a run counts only pushed rounds
- Location: .claude/workflows/deliver-change.js:966 and 978 (resumeFix), tools/run_state.sh push (writes review_fixes)
- Why: review_fixes is written only by the push, so a round that began and stopped unpushed lets a later start begin another, against the proposal's rule that a second round, in the same start or a later one, is refused.
- Fix: Record the round in the run state when it begins (a review_fix_round key) and count it in resumeFix.

### The review fix push result is ignored
- Location: .claude/workflows/deliver-change.js:1156 and 1172
- Why: The result of the review fix contributor('push') is not checked, so a refused or failed push surfaces only as the pushedHead mismatch stop and its reason is lost.
- Fix: If the push start returns false, keep the stop the contributor set or set stopped with the push's reason, as the CI fix path at line 1217 breaks.

### A review fix round turns off review narrowing for the rest of the start
- Location: .claude/workflows/deliver-change.js:798 (priorSecurity)
- Why: Performance: once reviewFixRounds is above zero, every later CI fix round after the review fix push re-reviews the whole branch diff, costing tokens and time.
- Fix: Drop narrowing only for the review fix round's own reviews, for example remember the head the round began at and narrow from passes after it.

### A resume pushes an unpushed CI fix as the review fix
- Location: .claude/workflows/deliver-change.js:909 (resumePush)
- Why: resumePush pushes any head past the recorded push as the review fix, so an unpushed CI fix commit, from a start stopped between the CI fix commit and its --ci-fix push, is pushed with --review-fix: ci_fixes is not counted and the run's one review fix is spent, so a later blocking review on resume is refused.
- Fix: Push with --ci-fix when CI is recorded red and keep --review-fix for a blocked review only, or name the case in the comment and the README.

### push --review-fix does not check that a review blocked
- Location: tools/run_state.sh:931 (push, the --review-fix case)
- Why: The review fix push checks only that the recorded push differs from HEAD, not that a review blocked, so any caller gets one extra push beyond the push-once rule.
- Fix: Require a blocked review.quality or review.security record at the pushed head before allowing the --review-fix push, with a tools_test case refusing it otherwise.

### SELF_CHECK repeats the contributor's implement step 5
- Location: .claude/workflows/deliver-change.js:684 (SELF_CHECK), .claude/agents/contributor.md implement step 5
- Why: Every implement and fix prompt carries the same rule twice, and the two texts can drift apart.
- Fix: Keep the rule in the agent file and have the prompt point to step 5, or drop step 5's copy.

### CLAUDE.md sits 9 bytes under its docs budget
- Location: CLAUDE.md:1 (tools/docs_lint.sh budget of 30720 bytes)
- Why: CLAUDE.md is 30711 of its 30720 bytes after rework-guards trimmed unrelated lines (the hotfix and release branch examples, the Stack PATH note) to fit, so the next addition fails docs-lint.
- Fix: Move detail to the notes docs CLAUDE.md already points to rather than trimming more examples.

### The init usage line still says it refuses any merged run
- Location: tools/run_state.sh:59 (header usage of init)
- Why: Docs currency: the usage line says init refuses a CHANGE with merged recorded, but init now resumes a merged run without phase.retro.
- Fix: Say it refuses a merged run the close recorded (phase.retro) or one with a lane history row.

### The archived proposal omits init's merged-run exception
- Location: openspec/changes/archive/2026-11-16-rework-guards/proposal.md:12
- Why: Docs currency: the proposal says init refuses any run state with merged set, while the design and the code resume a merged run the close has not closed.
- Fix: Add that exception to the proposal's sentence.

### Task 1.3 names a test no case carries
- Location: openspec/changes/archive/2026-11-16-rework-guards/tasks.md:7
- Why: Task 1.3 names the test "workflow: the review fix round pushes once more", which no tools_test.sh case carries; the push is proved by "workflow: a passed resume pushes a head past the recorded push as the review fix".
- Fix: Name the existing test in the task.

### Lane-open follows a committed tmp or build symlink out of the repository (sprint-10 security Low (5))
- Location: tools/run_state.sh:2350 (lane_open, parallel-lanes-b)
- Why: .gitignore ignores tmp/ and build/ only as directories, so a branch may commit a symlink named tmp or build, and lane-open's mkdir -p and ln -s then create the toolchain, cache, pipeline, stages, and plan links in any directory it names, outside the repository root. Queued in lane-guards.
- Fix: refuse a lane whose tmp or build path, or any parent of a link target, is a symlink, or a branch that tracks anything under tmp/ or build/.

### Two lanes share one writable toolchain and compile cache (sprint-10 security Low (3), disputed)
- Location: tools/run_state.sh:2312 (LANE_LINKS, parallel-lanes-b)
- Why: branch code run by one lane's checks can tamper with the binary or cache entries the other lane builds and benchmarks with. Disputed by the skeptic: the checks already run as the same user with write access to those paths by absolute path, and serial deliveries shared them; running at once adds timing, not capability.
- Fix: link the toolchain read-only for the lanes or check its hash before each check; give each lane its own compile cache or key entries by a content hash checked on read.

### history writes late findings to a findings file the records change folded
- Location: tools/run_state.sh:1708 (history), groom at tools/run_state.sh:2072
- Why: a merged change's late findings go to docs/findings/<that change>.md, which a sprint records change may have folded and deleted on main; a lane branch cut before it then hits a modify/delete conflict at its squash merge, or brings back folded entries, and merge-main's union driver settles neither. Queued in lane-records.
- Fix: append late findings to the packaging change's own findings file under its "Findings of X after its package step" heading.

### MarkdownText cell_lines repeats the wrap's cut-finding loop
- Location: carat/domain/markdown_text.rb:414 and :794
- Why: cell_lines repeats the cut at the last space or on a character boundary that wrap writes out with spans and columns, two copies to keep in step.
- Fix: pull out the shared cut-finding loop, or say in a comment why the two stay apart.

### A pipe line right after a table is drawn as a table row
- Location: carat/domain/markdown_text.rb:177
- Why: table rows go on through any line holding a pipe, so a heading, list item, quote, or fence line with a pipe directly after a table is drawn as a row, while GFM ends the table where another block starts. Folded into markdown-reading-c.
- Fix: also stop at a line that opens a block (#, >, a list marker, a fence), with a test.

### The gateway test's synced helper repeats in_dir and ready_with
- Location: test/adapters_language_gateway.rb:67 and :23
- Why: synced repeats in_dir with another file text, then ready_with's open and initialize steps.
- Fix: give in_dir a text parameter and build synced from it plus ready_with's steps.

### Deleting an empty charwise range marks the buffer modified
- Location: carat/domain/buffer.rb:504 (Buffer#delete)
- Why: d0 at column 0, d^ on the first non-blank, or c0 at column 0 splices an identical line, so the buffer shows modified, :q refuses with E37, a no-op undo state is pushed, and plugins and the language server get a change notice; Neovim changes nothing. Folded into core-correctness-b.
- Fix: return early for an empty one-row range (or skip it in Operate), with a d0-at-column-0 row asserting modified? stays false.

### A counted aw starting on blanks takes the wrong span
- Location: carat/domain/text_objects.rb:116 (count loop 121-129)
- Why: 2aw on "  foo bar baz" takes blanks, foo, and the next blank instead of Vim's blanks, foo, blank, bar. Folded into core-correctness-b.
- Fix: step (blank, word) pairs when the cursor started on a blank, with a d2aw-from-blanks row in test/editor_text_objects.rb.

### The typed count has no cap and MAX_COUNT is written twice
- Location: carat/domain/command_grammar.rb:98; carat/domain/register_count.rb:15; carat/domain/substitute_args.rb:27
- Why: CommandGrammar#digit accumulates with no cap, so a long count overflows Integer, while RegisterCount and SubstituteArgs stop at a duplicated 1_000_000_000. Folded into input-core-tidy.
- Fix: one domain count limit applied in digit too, with a grammar test.

### HandleKey's step and complete drop the queue dispatch returns
- Location: carat/use_cases/handle_key.rb:252, :277 (dispatch 281-286)
- Why: dispatch says the caller assigns its returned queue because of the open Spinel pitfall on appends to a passed empty array; a remap reached in timeout's step loop, whose queue began as a [] literal, may lose its keys. Folded into input-core-tidy.
- Fix: keep the replay queue in one instance field cleared per call and timeout.

### Key::CTRL_H is unused
- Location: carat/domain/key.rb:14
- Why: dead code, referenced nowhere in carat/, bin/, or test/. Folded into input-core-tidy.
- Fix: remove it.

### csi_key repeats ss3_key's final-byte cases
- Location: carat/adapters/key_decoder.rb:148 and 193-206
- Why: ten final-byte cases copied word for word. Folded into input-core-tidy.
- Fix: handle 126 in csi_key and answer ss3_key(final) for the rest.

### The docs gate holds two rules for one agent-file case
- Location: tools/gates.sh:260-263 and 286-290
- Why: an added or removed agent, command, or workflow file needs a CLAUDE.md change without the proposal escape at 260, while 286-290 accepts "- CLAUDE.md: unchanged, REASON" for every change of the same files. Folded into tools-docs-tidy.
- Fix: drop the process part of 260-263 and let process_change decide, keeping target_change for the README check.

### groom documents CHANGE as optional though it dies without one
- Location: tools/run_state.sh:2014, the header, and the dispatch at :2504
- Why: drift: groom with no CHANGE always dies while a sprint plan waits. Folded into lane-records.
- Fix: make CHANGE required in the header, the usage, and the dispatch.

### UndoTree#undo_seq and #redo_seq have no production caller
- Location: carat/domain/undo_tree.rb:173, :179
- Why: only tests call them and the map lists them as API (area 8). Folded into architecture-docs.
- Fix: drop them and assert through undo_path and redo_path, updating the map.

### SaveAll#call never reads its state parameter
- Location: carat/use_cases/files/save_all.rb:24
- Why: an unused parameter every caller must supply. Folded into ex-handlers-tidy.
- Fix: drop it and update FileCommandHandler and the map.

### RegisterCommandHandler compares entry kinds by hand
- Location: carat/use_cases/ex/register_command_handler.rb:112
- Why: compares kind with :linewise and :blockwise though RegisterEntry has linewise? and blockwise?. Folded into ex-handlers-tidy.
- Fix: use the predicates.

### UTF-16 counts by lead byte desynchronize incremental sync on invalid UTF-8
- Location: carat/adapters/json_rpc_language_gateway.rb:1146 (utf16_length), :1100 (utf16_offset), :1385 (ranged_change); carat/use_cases/definitions/visit_target.rb:204
- Why: a stray 0x80-0xBF byte counts 0 units and a lone 0xF0-0xFF byte 2, while Carat::Json sends each illegal byte as one U+FFFD (1 unit), so in a file that is not valid UTF-8 each ranged didChange after such a byte corrupts the server's copy of the line. Queued in lsp-sync-fixes.
- Fix: one domain helper walking Utf8.size_at and code_at, 2 units only above 0xFFFF, used by the gateway and VisitTarget, with a replayed sync row over a line holding 0xB0 and 0xFC.

### The map and architecture lag the plugin API, ProcessPort, StatusSlots, and DisplayWidth
- Location: docs/codebase-map.md:531, :547, :608, :617, :465, :476; docs/architecture.md:330, :275
- Why: VERSION 2.6 where carat/plugin_api.rb:12 is 2.7; FileRequests omits run_program; Paths omits absolute and segments; ProcessPort and ProcessRunner omit capture and section 6/7 still plans Open3.capture3; StatusSlots omits set_lsp and label; DisplayWidth omits code_cells. Folded into architecture-docs.
- Fix: name each in its entry and describe capture in the architecture.

### PluginApi::FileIcons.group_of has no caller
- Location: carat/plugin_api.rb:478; carat/plugins/explorer/file_icons.rb:12, plugin.rb:451-455
- Why: the explorer reads GROUPS through its own alias while the map calls group_of shared. Folded into architecture-docs.
- Fix: have Explorer#icon_groups call group_of and drop the alias, or remove group_of.

### Command#args? and Edit#insertion? have no caller
- Location: carat/plugin_api.rb:125, :142
- Why: no plugin, host code, or test calls them. Folded into architecture-docs.
- Fix: cover them in test/use_cases_plugins.rb as API, or remove them with a minor version note.

### send_change repeats remember and the didChange envelope per sync kind
- Location: carat/adapters/json_rpc_language_gateway.rb:1335
- Why: kinds 1 and 2 repeat remember and the notify, and the kinds are bare literals. Queued in lsp-sync-fixes.
- Fix: compute the content change by a named kind, then remember and notify once.

### MarkdownText.parse finds a line end inline beside line_end
- Location: carat/domain/markdown_text.rb:75 and :192
- Why: two copies of one byteindex lookup.
- Fix: call line_end in parse.

### metrics.sh compare passes a base key the current run lacks
- Location: tools/metrics.sh:86
- Why: compare reads only CURRENT's names, so an allocs.* or rounds.* key in BASE that CURRENT lacks passes, though the header says a value not measured fails. Folded into tools-docs-tidy.
- Fix: print FAIL in END for each strict base key never seen in CURRENT.

### lane_open checks the branch with a line-wise grep and a third copy of the pattern
- Location: tools/run_state.sh:2323; tools/open_pr.sh:45; tools/agent_guard.sh:117
- Why: grep -c over printf passes a multi-line value whose first line matches, and the branch pattern is copied instead of the valid helper. Queued in lane-guards.
- Fix: valid "$BRANCH_RE" "$branch" with BRANCH_RE defined once in tools/rules.sh, in its own small change first since rules.sh holds merge-gate rules.

### plan_apply's comment says no common record though it writes docs/goals.md
- Location: tools/run_state.sh:1317
- Why: two lanes applying goals.md conflict at merge-main. Folded into lane-records.
- Fix: correct the comment and apply goals.md only in the sprint records change, or name it as the one shared write.

### The search delimiter bytes are written twice
- Location: carat/use_cases/search/find_match.rb:68; carat/use_cases/search/preview_search.rb:37
- Why: 47 and 63 for / and ? repeated. Folded into editing-dedup-a.
- Fix: one domain helper used by both.

### Character classes are bare numbers
- Location: carat/use_cases/search/find_match.rb:130; Motions.code_class, Walker.char_class, TextObjects.runs
- Why: 0, 1, 2 compared by hand and blank? re-derives class 0. Folded into editing-dedup-a.
- Fix: named constants BLANK, OTHER, KEYWORD in Motions, keyword? and blank? built on them.

### Twenty handler files copy the NAMES and DESCRIPTIONS loop
- Location: carat/use_cases/actions/motion_handler.rb:76, text_object_handler.rb, search_handler.rb, and about 20 more
- Why: one registration loop copied per kind. Folded into editing-dedup-a.
- Fix: ActionTable#register_all(names, handler, descriptions).

### Paragraph motions never answer nil
- Location: carat/domain/motions.rb:542
- Why: paragraph_forward and paragraph_backward return a position even when the cursor already stands there, against the module contract sentence_forward keeps. Folded into core-correctness-b.
- Fix: return nil when the target equals the cursor.

### MotionHandler's class comment is garbled
- Location: carat/use_cases/actions/motion_handler.rb:10
- Why: "in a visual mode a motion moves the cursor end of the selection" misreads.
- Fix: "in a visual mode a motion moves the cursor, the moving end of the selection".

### A range alone past the last line gives E16
- Location: carat/domain/ex_range.rb:51
- Why: :99 on five lines is refused, but Neovim and docs/compatibility.md move to the last line, E16 only before a command. Folded into core-correctness-b.
- Fix: clamp the last address in ExecuteEx#go_to, with a row in test/editor_cmdline.rb.

### clamp_cursors skips a hidden slot's kept window
- Location: carat/domain/tab_list.rb:252
- Why: a plugin view buffer shortened while its slot is hidden keeps a cursor past its last line until shown again. Folded into core-correctness-b.
- Fix: also walk each page's kept slot windows, with a case in test/editor_slots.rb.

### GlobalCommand#remember repeats SubstituteLines
- Location: carat/use_cases/search/global_command.rb:81; carat/use_cases/search/substitute_lines.rb:113
- Why: the pattern into LastSubstitute and LastSearch, the / register, and the history written twice. Folded into editing-dedup-a.
- Fix: one shared helper both call.

### revert_to repeats splice's row shifting
- Location: carat/domain/buffer.rb:653 and 687-689
- Why: a new per-line layer must be added in two places. Folded into editing-dedup-a.
- Fix: a private shift_rows(row, removed, inserted) used by both.

### StatusBar requires plugin_api without using it
- Location: carat/adapters/status_bar.rb:1
- Why: the only adapter requiring it, naming no PluginApi constant. Folded into ui-code-tidy.
- Fix: remove the require.

### Four display methods are dead code
- Location: carat/domain/decoded_line.rb:91 (cells); carat/adapters/painted_rows.rb:107 (syntax_at); carat/domain/frame.rb:129 (clear); carat/plugins/explorer/tree.rb:38 (marked)
- Why: nothing calls them. Folded into ui-code-tidy.
- Fix: remove them.

### FramePresenter compares the float key twice in a row
- Location: carat/adapters/frame_presenter.rb:236
- Why: same_ints?(@float_key, back.floats) runs twice. Folded into ui-code-tidy.
- Fix: compute it once into a local.

### A notice box covers the whole row on narrow screens
- Location: carat/adapters/frame_presenter.rb:460
- Why: the comment says half the screen, but NOTICE_MIN_WIDTH overrides it below 40 columns and from 8 to 21 columns the box clamps to left 0 across the row. Folded into ui-code-tidy.
- Fix: cap the width at cols - 2, or correct the comment and the map.

### Cell is a Struct though never changed
- Location: carat/domain/cell.rb:8
- Why: an immutable value view, which CLAUDE.md makes a Data subclass. Folded into ui-code-tidy.
- Fix: make it a Data subclass of code, width, hl.

### sprint-10-records proposal miscounts the sprint's changes (quality advisory)

- Location: openspec/changes/archive/2026-11-16-sprint-10-records/proposal.md:5 (written as openspec/changes/sprint-10-records/proposal.md:5)
- Why: it says sprint 10 closed with its five changes merged, while the sprint-10 row of docs/sprints.tsv records size 6 with six changes, so the archived record disagrees with the sprints file.
- Fix: say six changes, backlog-lane-split being the user-approved place beyond the five.

### Lane queues state a stale insert acceptance figure (quality advisory)

- Location: docs/queue-backlog.md:3 and docs/queue-feature.md:3
- Why: both lane queues accept with insert 32.0 held, but every metrics row since #153 records insert=26.0, so a regression of six allocations passes the stated acceptance.
- Fix: have the planner write the current figures (insert 26.0) or point to metrics-compare instead of numbers.

### Records change steps outside groom to fix the queues and docs-lint (quality advisory)

- Location: openspec/changes/archive/2026-11-16-sprint-10-records/design.md:13 (written as openspec/changes/sprint-10-records/design.md:13)
- Why: one clear way: the records change hand-copied the delivery plan's feature queue over groom's copy (the sprint plan still named the merged git-signs-trust) and hand-edited a folded entry and an ignored plan file so docs-lint passes, steps outside groom.
- Fix: make groom prefer build/plan/CHANGE/queue-*.md when present (or plan-apply copy both lanes for a records change) and refuse or de-backtick a nonexistent path while folding, with tools-test cases.


### A change touching no carat/, bench/, or test/ file still runs the benchmark phase
- Location: .claude/workflows/deliver-change.js, the benchmark phase (sprint-10-records retro note 4)
- Why: the records-only sprint-10-records spent 4,848 output tokens and 6 calls on the benchmark (9.3% of 52,240 output tokens, 7% of 86 calls) plus a base and a change build, while its check scoped the metrics stage out; bench first pass 117 of 118 over the history, allocations and rounds unchanged on every key.
- Fix: skip the benchmark phase, recording the skip, when the committed diff touches no file under carat/, bench/, test/, or the Makefile; accepted when the next records change shows a recorded skip and no skipped change later shows an allocation or rounds difference.

### The ProcessPort row still names capture(argv)
- Location: docs/architecture.md:213
- Why: the port takes capture(argv, environment) since #160, so the binding architecture table misstates the port.
- Fix: name the environment argument in the row.

### The windows-tabs-tidy artifacts and a comment describe a close_window clear that never shipped
- Location: openspec/changes/archive/2026-11-17-windows-tabs-tidy/tasks.md:13, design.md ('The previous window never names the current one'), carat/use_cases/windows/close_other_windows.rb:10, carat/domain/buffer_list.rb:369
- Why: task 3.1 (marked done) and the design describe a BufferList#close_window clear of tab.previous when it equals the new current window and a test 'closing into the previous window clears it', neither in the diff (buffer_list.rb:369 unchanged), so <C-w>s<C-w>c still leaves previous == current and the new comment 'the window kept is never the previous' is false; the design also gives the integer minimum as -4_611_686_018_427_387_903 - 1 where the test uses -2^63.
- Fix: implement the close_window clear with its editor_windows row, or correct the comment to the shipped behavior and record the design's integer minimum as -2^63.

### FloatSpec writes its offset bound test twice
- Location: carat/domain/float_spec.rb:61
- Why: duplication: the bound test 'x >= -OFFSET_MAX && x <= OFFSET_MAX' is written twice (lines 61-62), where the design names one outside?(value) helper.
- Fix: add the class predicate outside?(value) and call it for row and bad.

### BRANCH and COUNTS repeat git_signs' safety arguments

- Location: carat/plugins/git_signs/plugin.rb:27, :28. Sprint-11 review, quality advisory.
- Why: both repeat the same four safety words (-c protocol.ext.allow=never -c core.fsmonitor=false), so a third git command, such as the diff capture of git-signs-status-b, could leave them out.
- Fix outline: build both from one safety prefix constant, as test/editor_git_signs.rb already holds SAFE.

### PluginHost decides run_program trust once at activation

- Location: carat/use_cases/plugins/plugin_host.rb:110. Sprint-11 review, security Low (3).
- Why: the trust flag comes from TrustedRoots.cover? in activate_all and never again; no attack today since the editor has no chdir, but a later :cd or configuration reload changing the working directory or the roots would keep the old decision and could run git in an untrusted directory.
- Fix outline: decide trust at each run_program call, or again wherever the working directory or the roots change, with a test changing the roots after activation.

### The incremental-sync text diff lives in the 1438-line gateway

- Location: carat/adapters/json_rpc_language_gateway.rb:1331 (ranged_change, shared_head, shared_tail, continuation?, content_change). Sprint-11 review, quality advisory, architecture layers 3 and 5.
- Why: a pure text-diff algorithm sits inside a 1438-line adapter, tested only end to end.
- Fix outline: move the diff into a Domain module (for example a line delta between the sent lines and the buffer's) with its own table test, keeping only the JSON shaping in the gateway.

### The gateway repeats the UTF-8 continuation-byte test

- Location: carat/adapters/json_rpc_language_gateway.rb:1377, inlined again at :1074 and :1119. Sprint-11 review, quality advisory.
- Why: the & 0xC0 == 0x80 test is written three times beside Domain::Utf8 (boundary, size_at), which holds the same knowledge.
- Fix outline: add a Utf8 continuation predicate and use it at all three places.

### Three comments wrap past 72 columns in file_requests.rb and the gateway

- Location: carat/use_cases/plugins/file_requests.rb:25 (94 columns) and :131 (breaks after "copied, so the"); carat/adapters/json_rpc_language_gateway.rb:33 (94 columns). Sprint-11 review, quality advisory.
- Why: the files' 72-column wrap, restored elsewhere in sprint-11, is broken again.
- Fix outline: rewrap the three paragraphs.

### checks-and-pr-lows security Low (4): run_state set still writes any note key
- Location: tools/run_state.sh:1675
- Why: the late-finding stamp is public once the run merges and `set` still writes any note.N key, so code running after the merge with write access to build/pipeline (for example the next change's branch code run by a check, if the run-state directory is reachable from there) can forge `set CHANGE note.N "late-finding MERGED text"`, which passes late_findings and lands in docs/findings and then the backlog the planner reads; LATE_TEXT_RE keeps the text to plain characters, 400 at most.
- Fix: make `set` refuse note.* keys so only add_note writes notes, as it already refuses review.*, phase.* and stage.*; optionally record which start wrote each note or check that note keys are numbered in sequence.

### checks-and-pr-lows security Low (3): open_pr wait records a lone matching pull request of unknown origin
- Location: tools/open_pr.sh:135
- Why: if a fork opens a pull request on the pushed commit before open-pr opens ours (a race the attacker has to automate), that fork's number is recorded with nothing earlier to compare it against, and the merger would read and squash-merge a pull request whose title the attacker controls.
- Fix: have open-pr publish the number it opened where wait can read it (the workflow log, a commit status, or an artifact), or have the merger check that the pull request's head repository is this repository before merging.

### checks-and-pr-lows security Low (5): a planted held-finding note is relabeled as a merged-stamped late finding
- Location: .claude/workflows/deliver-change.js:471
- Why: branch code a check runs can call `sh tools/run_state.sh note CHANGE held-finding TEXT`, since add_note accepts any lowercase kind before the merge; on a resume seed reads it back through heldFindings and the merged close records it with `note late-finding`, stamped with the real squash commit, so it passes the history stamp check and lands in docs/findings/CHANGE.md, bypassing the provenance stamp; the text stays within noteText and 400 characters, and a planted quality-advisory reaches the findings file the same way (design.md, Risks, records this tradeoff).
- Fix: keep held findings where branch code cannot write them, for example notes carrying a token the workflow holds (the reviewed HEAD plus a per-start nonce) checked by heldFindings, or add_note refusing held-finding outside the close profile; at minimum have heldFindings keep only texts shaped like a recorded security Low or quality-advisory note.

### checks-and-pr-lows security Low (4): unpushed-finding notes accepted from any run-state writer before the merge
- Location: .claude/workflows/deliver-change.js:515
- Why: branch code a check runs could plant an unpushed-finding note that an unpushed resume's seed hands to the package step, which appends it to docs/findings/CHANGE.md; the text is held to noteText's shell-safe shape and reaches only the reviewed PR diff, the reach design.md line 36 accepts for held-finding and quality-advisory notes, but that accepted-risk paragraph does not name the new kind.
- Fix: add unpushed-finding to the accepted-risk decision in design.md beside held-finding, or have seed accept an unpushed-finding note only when the run state also records a close phase or stop marker written by the workflow at a commit.

### checks-and-pr-lows test gap: the unstamped forged late-finding note is overwritten before it is checked
- Location: tools/tools_test.sh:986
- Why: the unstamped forged note.7 is overwritten by the following `state note history overrun`, numbered by the note count plus one (7), so the without-a-stamp case of late_findings is never exercised.
- Fix: set the forged notes after the overrun note or at numbers above the next note number.

### checks-and-pr-lows correctness: open_pr wait can replace a recorded pull request number
- Location: tools/open_pr.sh:135
- Why: a single number on the pushed head is taken even when the run state already records a different pr, so a later push can overwrite the branch's pull request number with another one, a fork's included.
- Fix: when pr is recorded, accept only that number and keep waiting otherwise.

### git_signs detects a timed-out capture by matching a message suffix spelled twice
- Location: carat/plugins/git_signs/plugin.rb (TIMEOUT, the timeout check in run) and carat/use_cases/plugins/file_requests.rb (the run_program failure message)
- Why: the plugin recognizes a timeout only by the suffix "ran past 2 seconds", which file_requests.rb writes again as a literal that also restates ProcessRunner::CAPTURE_SECONDS, so rewording the message or changing the deadline silently disables the back-off and every later event stalls again.
- Fix: name the suffix once as a PluginApi constant that run_program builds its message from and the plugin matches, deriving the seconds from the one deadline constant.

### git_signs buffer_close drop has no test
- Location: carat/plugins/git_signs/plugin.rb (the buffer_close subscription and drop), test/editor_git_signs.rb
- Why: forgetting a closed buffer's HEAD text and clearing its signs is new behavior with no test, so a regression that keeps stale text or leaks held texts would pass the suite.
- Fix: add an editor_git_signs case that closes a buffer and checks that a reopen at the same HEAD key captures the text again.

### git_signs keeps old signs when a buffer's relative path becomes empty
- Location: carat/plugins/git_signs/plugin.rb (focus and save return early on an empty relative_path)
- Why: a buffer renamed to a path outside the working directory (for example under an explorer root elsewhere) keeps its previous signs and held HEAD text, against the rule that a buffer outside the working directory shows no sign.
- Fix: call drop(buffer) when relative_path is empty, with an editor_git_signs case covering the rename.

### git_signs head_key is empty in a linked worktree or a repository subdirectory
- Location: carat/plugins/git_signs/plugin.rb (head_key)
- Why: when .git is a file (a git worktree) or the working directory is below the repository root, the key is always empty, so every focus runs three git commands, and one timed-out capture stops git for the whole session because the empty key never changes.
- Fix: follow the gitdir: line of a .git file and search upward for the repository root, or record the limit in docs/compatibility.md and the git-status spec and let a timeout back off for a bounded time instead of until a key change.

### A phase's recorded output differs from its agent starts' output
- Location: `.claude/workflows/deliver-change.js` phase accounting, `metric.phases` (markdown-reading-c retro note 18).
- Why: phase.check recorded 150,693 output and 27 calls (37.9% of 397,894) while its three checker starts summed 5,213; git-signs-status-b check 57,747 and checks-and-pr-lows 38,907 against 2,029 to 6,432 earlier, so `check-skip` and share-based proposals judge a number the checker did not spend.
- Fix: accepted when, for the next three runs, each phase's recorded output is within 10% of the summed output of its agent starts.

### The package step appends the planner's findings twice
- Location: the package step's findings append, `tools/run_state.sh` plan-apply (markdown-reading-c retro note 19).
- Why: 14 lines of the markdown-reading-c findings file (since folded here) repeated (commit 1fc49d8), raised by 2 quality advisories in a run with quality first pass 0 and rework 3.
- Fix: accepted when a tools-test case runs the append twice on one change and the second leaves the file unchanged.

### A merge refused on a moved main costs a full resume and a CI failure
- Location: `.claude/workflows/deliver-change.js` merge and resume path (markdown-reading-c retro note 20).
- Why: CI green at the first push in 7 min, yet first.ci 0; merge 39,463 output in 24 calls (ci_wait_calls 10), and the resume re-ran 3 checker, 3 quality, 3 security starts.
- Fix: accepted when the next merge refused for a moved main records first.ci 1 on a green CI and reaches the merge with no new checker or review start unless merging main changed files under carat/ or tools/.

### plan-apply and history write into whatever checkout runs them
- Location: `tools/run_state.sh:1707` append_history, plan-apply (planner-split-rule retro note 5).
- Why: the package step ran both from the main checkout, edited main's backlog queue and history while another lane ran, keyed a row to main; package 10,276 output in 21 calls against a median of 14 over the last 10 backlog rows.
- Fix: accepted when both refuse, non-zero with the tree unchanged, outside the change's lane worktree (a tools-test case), and the next package phase stays within 15 calls.

### CLAUDE.md and planner.md have no bytes left for review fixes
- Location: `CLAUDE.md`, `.claude/agents/planner.md` against docs-lint's limits (planner-split-rule retro note 6).
- Why: CLAUDE.md 30,714 of 30,720 bytes, planner.md 8,189 of 8,192; the split rule left out of CLAUDE.md and 2 of 4 quality advisories deferred for want of bytes.
- Fix: free space by removing repetition, limits unchanged; accepted when the next change touching them lands planner-split-rule quality advisories 3 and 4 and the split rule with docs-lint passing.

### The merge start passes its cap on a first-pass green CI
- Location: merger start, `CALL_CAPS` in `.claude/workflows/deliver-change.js`; pool item `merge-gate-integrity` (planner-split-rule retro note 7).
- Why: merge 18,979 output in 14 calls (13.2%) with first.ci 1; 5 of the last 8 medium backlog rows at 14 calls against a cap of 12; merge output 17,462 to 30,050 in 4 runs against 4,045 to 6,438 in 9 of the last 10 feature rows.
- Fix: fold into `merge-gate-integrity`; accepted when five medium runs in a row merge within cap, no overrun note, under 6,000 output on a first-pass green CI.

### A check pass after a fix round costs more than a first pass
- Location: `.claude/workflows/deliver-change.js` check phase; backlog pool item `check-skip` (git-signs-status-b retro note 9).
- Why: git-signs-status-b's check took 57,747 output tokens in 11 calls (16.8% of 342,779) over 2 passes that both passed; the last 20 lane rows ran 1,970 to 24,171; check first pass 121/123.
- Fix: fold into `check-skip`; accepted when the next three feature runs keep check at or under 6,000 output tokens per pass with first.check still 1.

### A resumed run records 0 output tokens for the phases done before the resume
- Location: `.claude/workflows/deliver-change.js` resume path, `metric.phases` and the history row (git-signs-status-b retro note 10).
- Why: git-signs-status-b recorded plan=0/10, areas=0/2, scout=0/14 against plan 10,124 to 25,457 and scout 18,002 to 64,257 output in the last 10 feature rows, so its output total and the check-pass budget line undercount.
- Fix: accepted when a resumed run's carried phases show their recorded tokens or are marked carried in the phases and the history row, never 0 beside non-zero calls.

### No hover test shows a flowed paragraph, and the README names the flow only for the reading view
- Location: test/adapters_hover.rb, README.md:69
- Why: MarkdownText.parse is shared, so the paragraph and quote flow and the hanging prefix also reach the hover and completion floats, but no test proves it there and the README states it only for the reading view.
- Fix: add a two-line paragraph case to test/adapters_hover.rb and say in the README's floats sentence that paragraphs and quotes flow there too.
### A merge that fails on a moved main has no push path
- Location: tools/run_state.sh push_branch and .claude/workflows/deliver-change.js merge loop
- Why: a green pull request behind a moved, conflicting main stopped the run, since push --ci-fix needs a red CI
- Fix: let the merge loop run merge-main and push it as a main-moved push, counted once

## Findings of markdown-reading-c after its package step

- quality advisory docs/findings/markdown-reading-c.md:29 the package commit 1fc49d8 appended the three git-signs-status-b retro entries (check pass cost, resumed run 0 tokens, quality first pass) a second time, lines 1-14 already holding them, and left no blank line before :15 and :29; fix: drop the second copy at :29-42 and put one blank line between entries
- quality advisory carat/domain/docs_text.rb:63 simple and elegant: last_line= stores an alias that parse then grows in place (markdown_text.rb:108-118, the flowing and flowing_row state), cleverness the flow does not need, and the archived tasks.md 1.1 names a DocsText#extend_last that does not exist; fix: one DocsText#append_to_last(text) that replaces the last row with the joined string, dropping
- quality advisory carat/domain/markdown_text.rb:920 under the ascii set a text row starting with ' ' (a literal pipe line or a narrow table's source) is read as a quote bar prefix, so hang now repeats ' ' on every continuation row of a plain line; fix: take the hanging prefix from the parsed row kind (record the prefix length per row in DocsText at parse) rather than re-reading the text, with an as
- quality advisory docs/findings/markdown-reading-c.md:29 docs currency: the three pipeline findings of lines 1-14 (check pass cost, resumed-run tokens, quality first pass) are appended a second time; fix: drop lines 29-42
- quality advisory carat/domain/markdown_text.rb:108 tests beside every behavior change: the -2 path also stops a narrow table's header from joining a paragraph line right before it (key -1 while source), but only the wide table has that case (test line 248); fix: add a test/domain_markdown_text.rb case at width 15 of 'text' directly followed by a narrow table, expecting 'text' its own row
- quality advisory carat/domain/markdown_text.rb:82 naming: the bool local source says nothing of what it tracks (inside the lines of a table too narrow to draw); fix: rename it narrow_table

### The goals rubric still splits only a brief of more than about four fixes
- Location: docs/goals.md:24
- Why: the planner decides by the goals rubric (planner.md step 2), which still splits only a brief of more than about four separate fixes, contradicting planner.md step 3's split at three or more independently testable parts or map areas, so the planner can read two thresholds.
- Fix: rewrite goals.md line 24 to the three-part or three-area threshold when the planner is next asked for goals, or point it at planner.md step 3.

### planner.md says the contributor appends the plan's backlog file
- Location: .claude/agents/planner.md:25
- Why: step 5 says the contributor appends build/plan backlog.md to its findings file, but plan-apply does it (tools/run_state.sh plan_apply) and the CLAUDE.md Backlog bullet says so, so the planner's rules drift from the script.
- Fix: write "which plan-apply appends to the change's findings file", within the 8,192-byte budget.

### The CLAUDE.md planner bullet names only build/plan/CHANGE/
- Location: CLAUDE.md:205
- Why: the planner bullet says the planner writes into build/plan/CHANGE/, but its sprint mode and /plan write to build/plan/ (planner.md:25, sprint-planning.js:9), so the bullet misplaces the sprint plan.
- Fix: "into build/plan/ (CHANGE/ in a delivery)" when the bytes allow, with the user's approval, since the wording was approved verbatim.

## Folded windows-tabs-tidy close_window finding is in neither lane queue

- Location: docs/backlog.md:6647 (the folded windows-tabs-tidy finding); carat/use_cases/windows/close_other_windows.rb:10
- Why: the close_window clear of tab.previous never shipped and the comment at close_other_windows.rb:10 is false, yet the finding is in neither lane queue while groom removed the old entry "CloseOtherWindows clears tab.previous a second time" as fixed by windows-tabs-tidy, so the gap can sit unseen.
- Fix: have the planner add it to the windows-buffers-tidy item (close_other_windows.rb:10, buffer_list.rb:369) or queue it alone.

## FloatSpec offset bound test finding is folded but unqueued

- Location: docs/backlog.md:6657; carat test float_spec.rb:61
- Why: "FloatSpec writes its offset bound test twice" is folded but unqueued while its sibling from the same delivery (the 83-column scroll_request.rb line) is pulled into windows-buffers-tidy.
- Fix: add the float_spec.rb:61 heading to that item's Backlog list, or say why it waits.

## Backlog holds the already fixed stale insert acceptance figure entry

- Location: docs/backlog.md:6601
- Why: the folded entry "Lane queues state a stale insert acceptance figure" is already fixed by sprint-11-records (both queues now say insert 26.0 at line 3), so the backlog holds a done item.
- Fix: have the next sprint's groom remove it as fixed, or have the planner list such headings in groom.txt when its queues fix them.

## Groom folds a findings file without a trailing newline as is

- Location: docs/backlog.md:6640 (two folded findings run together with no blank line) and docs/backlog.md:6612 (a double blank line); tools/run_state.sh groom
- Why: groom concatenates a findings file that lacks a trailing newline as is, so entries run together or gain extra blank lines.
- Fix: make groom end each folded file with exactly one blank line, with a tools-test case.

## sprint-11-records proposal miscounts the removed groom headings

- Location: openspec/changes/archive/2026-11-17-sprint-11-records/proposal.md:9
- Why: it says groom removes the 22 headings of build/plan/groom.txt from docs/backlog.md, but only 20 are removed there; the last two duplicates were repeated copies inside docs/findings/ux-fixes-a.md.
- Fix: say 20 headings from docs/backlog.md and 2 duplicate copies in the ux-fixes-a findings file.

## ux-fixes-a history row records no CI minutes

- Location: docs/metrics-feature.tsv:42
- Why: the ux-fixes-a row records ci_min as - though its CI ran green and its ci_stages are recorded, because build/pipeline/ux-fixes-a.json has no metric.ci_min, leaving a hole in the CI-minutes history.
- Fix: have the merge phase always record ci_min (or history derive it from ci_stages) and backfill this row.

## Findings append can duplicate a heading on a retried delivery

- Location: docs/findings/ux-fixes-a.md:1 (removed by groom)
- Why: it held the ProcessPort and benchmark-phase entries twice each, appended twice by a retried or resumed delivery, and only the planner hand-listing them as duplicates kept them out of the backlog.
- Fix: make the findings append (or groom when folding) skip a heading already present, with a tools-test case.


### The workflow trusts an agent-reported head without git
- Location: .claude/workflows/deliver-change.js:776
- Why: a fabricated sha sharing a 7-character prefix stopped a passing run at check and made record lines fail.
- Fix: resolve each reported head with git rev-parse in the lane and stop on a mismatch.

### The :e and :w messages still print a newline in a file name as a line break
- Location: carat/use_cases/files/open_file.rb:42, :63, :64; carat/use_cases/files/save_file.rb:56
- Why: these messages still put a raw path in quotes, so a file name holding a newline forges message lines the way `:ls` and E162 did before windows-buffers-tidy; no entry tracked them once the proposal left them out of scope.
- Fix: pass the path through Domain::ControlText.caret in those messages, with an editor test of a newline name for each.
### git_signs counts stay stale after a fetch

- Location: carat/plugins/git_signs/plugin.rb:127 (sprint-12 review, quality).
- Why: the focus fast path skips the COUNTS run, but a git fetch moves refs/remotes and FETCH_HEAD, which head_key does not read, so ahead and behind counts stay stale until the next open or save, where before sprint 12 every focus refreshed them.
- Fix outline: add the upstream ref's or FETCH_HEAD's stamp to head_key, or state the trade-off in openspec/specs/git-status/spec.md.

### git_signs shows no signs for a file committed empty

- Location: carat/plugins/git_signs/plugin.rb:149 (sprint-12 review, quality).
- Why: an empty blob and a file not in HEAD both come back empty from run(), and show_signs returns on no head lines, so an edited file committed empty shows no signs although LineDiff marks it all added.
- Fix outline: record whether cat-file succeeded beside the held text and pass an empty HEAD as zero lines, with a test/editor_git_signs.rb row.

### messages.rb names ControlText without requiring it

- Location: carat/domain/messages.rb:18 (sprint-12 review and sweep, quality).
- Why: unsaved_buffer calls ControlText.caret with no require_relative of control_text, the only file under carat/ doing so; it compiles only through the order of carat.rb.
- Fix outline: add require_relative "control_text" at the top of messages.rb.

### toolchain-clean deletes every lane worktree under tmp

- Location: Makefile:203; docs/architecture.md:33; README.md:21 (sweep, quality, blocking).
- Why: toolchain-clean runs rm -rf tmp, which also deletes each stopped delivery's worktree tmp/.lane-CHANGE (uncommitted work kept for its resume), tmp/.merge-gates, the review worktrees, and tmp/scout, leaving dangling worktree records; it ignores the SPINEL_SRC and PREFIX overrides the architecture says it honors.
- Fix outline: remove only "$(SPINEL_SRC)" and "$(PREFIX)", and say so in its help line and README.md:21.

### CI checkout keeps GITHUB_TOKEN while pull request targets run

- Location: .github/workflows/ci.yml:36 (sweep, security Low (6)).
- Why: the checkout keeps GITHUB_TOKEN in .git/config while the pull request's own make targets run.
- Fix outline: persist-credentials: false on the checkout; the scope step already reads through GH_TOKEN.

### Workflow actions are pinned by movable tags

- Location: .github/workflows/open-pr.yml:48 and every workflow (sweep, security Low (5)).
- Why: actions/checkout and actions/cache are pinned by the tag v4, here in the job of environment AI that holds PR_TOKEN.
- Fix outline: pin every action to a full commit hash.

### An untrusted project .caratrc may bind keys to destructive actions

- Location: carat/domain/config.rb:236 (sweep, security Low (4)).
- Why: a project .caratrc may bind any key in any mode to any action, such as quit.write_all or buffer.delete, so a cloned repository can turn common keys into writes or discards.
- Fix outline: read project keymap lines only under language.trusted_roots, or allow only non-destructive actions there.

### ci_scope.sh splits changed paths at whitespace

- Location: tools/ci_scope.sh:98, :118 (sweep, quality).
- Why: for path in $changed and $since are unquoted, so a path is split and its globs expanded; a path whose pieces each look like documentation skips the CI checks (fails open).
- Fix outline: set -f and a newline IFS around both loops, or while IFS= read -r path.

### spec_validate.sh deletes the failed preview it promises to keep

- Location: tools/spec_validate.sh:60, :70 (sweep, quality).
- Why: each preview starts with rm -rf "$preview", deleting an earlier change's failed preview, though the header says it is kept in build/spec-preview.
- Fix outline: preview each change in build/spec-preview/NAME, or stop at the first failure.

### The generated config header says spin run carat-gen-config

- Location: bin/carat-gen-config.rb:118, carat/domain/default_config.rb:2, docs/architecture.md:222 (sweep, quality).
- Why: spin run skips the Spinel-warnings check make gen-config adds, against the CLAUDE.md Commands rule.
- Fix outline: say make gen-config in all three.

### TrustedRoots#cover? repeats under?'s absolute check

- Location: carat/domain/trusted_roots.rb:19, :35 (sweep, quality).
- Why: cover? checks cwd is absolute while under? already checks every word.
- Fix outline: drop the check from cover?.

### Six sites recompute Options#tab_width

- Location: carat/use_cases/dispatcher.rb:112, leave_insert.rb:69, repeat_last.rb:104, arrange_view.rb:43, insert_tab.rb:25, carat/adapters/frame_presenter.rb:216 (sweep, quality, three notes).
- Why: each spells tabstop > 0 ? tabstop : 8, a copy of Options#tab_width (carat/domain/options.rb:131).
- Fix outline: call options.tab_width at each site.

### text_objects.rb names a local cls

- Location: carat/domain/text_objects.rb:86 (sweep, quality).
- Why: cls is the abbreviation the CLAUDE.md naming rule forbids.
- Fix outline: rename it char_class.

### Keymap#holder_of repeats node_at's walk

- Location: carat/domain/keymap.rb:246, :273 (sweep, quality).
- Why: holder_of copies the trie walk of node_at.
- Fix outline: node = node_at(mode, codes), then the owner or "".

### KeyDecoder#csi_key repeats ss3_key's finals

- Location: carat/adapters/key_decoder.rb:148 (sweep, quality).
- Why: csi_key repeats the letter finals A to D, H, F, P to S of ss3_key.
- Fix outline: keep the 126 tilde branch and send the rest to ss3_key(final).

### EditorAssembly names the loaded config value

- Location: carat/adapters/editor_assembly.rb:325 (sweep, quality).
- Why: the loaded Domain::Config is named value across about 175 lines.
- Fix outline: rename it loaded_config.

### end_visual rewrites clamp_col

- Location: carat/domain/editor_state.rb:122, :97, comment lines 13 and 15 (sweep, quality).
- Why: end_visual writes clamp_col out again, and two comment lines pass the wrap.
- Fix outline: c.col = clamp_col(c.row, c.col) and rewrap.

### HandleKey clears a message twice and uses bare codes

- Location: carat/use_cases/handle_key.rb:230, :384 (sweep, quality).
- Why: the list_message? branch clears a message line 233 clears anyway; :384 uses the bare codes 40 and 44 for ( and ,.
- Fix outline: drop the first clear and name the two codes.

### Walker and Motions require each other through code_class

- Location: carat/domain/walker.rb:63, carat/use_cases/find_match.rb:134 (sweep, quality).
- Why: Walker calls Motions.code_class while motions.rb requires walker.rb, a hidden circular dependency; find_match.rb copies blank?.
- Fix outline: move code_class and blank? into a small character-class module both require.

### The Messages map entry lists half its messages

- Location: docs/codebase-map.md:127 (sweep, quality).
- Why: it omits E16, E444, unsaved_buffer, and invalid_argument.
- Fix outline: list them all.

### tools_test pins whole prose sentences

- Location: tools/tools_test.sh:3493 (sweep, quality).
- Why: the planner and lanes cases grep -F whole sentences of planner.md and CLAUDE.md, so any rewording fails tools-test.
- Fix outline: pin each rule's key terms.

### Operate and RepeatLast copy clamp_col

- Location: carat/use_cases/operate.rb:204, repeat_last.rb:116 (sweep, quality).
- Why: both private clamp methods copy EditorState#clamp_col line for line.
- Fix outline: call state.clamp_col(row, col) and delete both.

### Operators repeats the indent step fallback

- Location: carat/domain/operators.rb:172, :251, :272 (sweep, quality).
- Why: shift_block and shift repeat the shiftwidth-else-tabstop-else-8 step and indent_width the tab fallback.
- Fix outline: one private step_width(shiftwidth, tabstop), or an Options reader passed in.

### RegisterCommandHandler re-implements RegisterEntry#lines

- Location: carat/use_cases/ex/register_command_handler.rb:61, :58 (sweep, quality).
- Why: TextLines.split with an empty fallback copies RegisterEntry#lines; :58 compares kind where linewise? and blockwise? exist.
- Fix outline: parts = entry.lines and the predicates.

### Three ex handlers spell digits? apart

- Location: carat/use_cases/ex/tab_command_handler.rb:102, buffer_command_handler.rb:102, history_command_handler.rb:67 (sweep, quality).
- Why: three copies of one check.
- Fix outline: one domain predicate the three call.

### GlobalCommand and SubstituteLines repeat remember

- Location: carat/use_cases/search/global_command.rb:81, substitute_lines.rb:113 (sweep, quality).
- Why: both make the same four writes: last substitute pattern, last search, the / register, the history.
- Fix outline: one shared helper both call.

### The cursor's screen row is spelled in eight places

- Location: carat/use_cases/arrange_view.rb:108, :109, show_completion_docs.rb:92, :106, open_completion_popup.rb:75, carat/domain/layout.rb:247, show_signature.rb:66, show_hover.rb:77, open_definition_float.rb:32, frame_presenter.rb:735 (sweep, quality).
- Why: window.row + cursor.row - window.top is written out eight times, the column twice.
- Fix outline: Window#cursor_screen_row and a cursor_screen_col reader used by every site.

### PutOverSelection repeats Operators.put's count loop

- Location: carat/use_cases/visual/put_over_selection.rb:124, carat/domain/operators.rb:42 (sweep, quality).
- Why: repeated copies the linewise count loop.
- Fix outline: one Operators.repeated(lines, count).

### The BufferRequest and SwitchBuffer map entries drift

- Location: docs/codebase-map.md:385, :387 (sweep, quality).
- Why: buffer_request.rb:3 also has :tab and :alternate; switch_buffer.rb:9 handles Ctrl-^ and E23, all unlisted.
- Fix outline: add both targets, Ctrl-^, and E23.

### Selection#as is unclear and the map omits three methods

- Location: carat/domain/selection.rb:84, docs/codebase-map.md:333 (sweep, quality).
- Why: as names a copy with another kind; the entry omits numbered_delete?, as, and line_start.
- Fix outline: rename it with_kind and list the three.

### The docs give PluginApi 2.6 against the code's 2.7

- Location: docs/codebase-map.md:532, docs/architecture.md:330, carat/plugin_api.rb:12 (sweep, quality, two notes).
- Why: the map and section 9 say 2.6; the code and docs/plugins.md:23 say 2.7; the map's Paths list omits absolute.
- Fix outline: say 2.7 in both and add absolute.

### make bench without SCENARIOS skips four scenarios

- Location: bench/run.sh:69, bench/keys.rb (sweep, quality).
- Why: run.sh copies bench/keys.rb's SCENARIOS and lacks lh-float, lh-winbar, n, and palette.
- Fix outline: let bench/keys.rb print its names for run.sh, or add the four.

### PluginHost builds its own ResolveInside

- Location: carat/use_cases/plugins/plugin_host.rb:80, carat/adapters/editor_assembly.rb:433 (sweep, quality).
- Why: two instances against the one-shared-instance rule.
- Fix outline: pass the assembly's resolve_inside as a keyword and assert it in test/adapters_assembly.rb.

### The gateway's six cancel wrappers share one body

- Location: carat/adapters/json_rpc_language_gateway.rb:601, :672, :726, :872, :952, :1005 (sweep, quality).
- Why: each is cancel_request then sent_id = 0.
- Fix outline: cancel_request returns 0 and the call sites assign it.

### Explorer Tree has a positional constructor

- Location: carat/plugins/explorer/tree.rb:23, plugin.rb:484 (sweep, quality).
- Why: the one plugin behavior class without keywords, which lint misses since it exempts plugins (test/lint.rb:1188).
- Fix outline: initialize(root:, show_hidden:, ignore:) with its signature.

### bench NullTerminal breaks the double naming rule

- Location: bench/keys.rb:30 (sweep, quality).
- Why: a double not starting with Fake, Memory, Manual, or Fixed.
- Fix outline: rename it FakeCountingTerminal.

### gates.sh's header misstates the stages source

- Location: tools/gates.sh:39, :355 (sweep, quality).
- Why: the header says CHECK_STAGES while stage_list reads FAST_STAGES first.
- Fix outline: say STAGES, else FAST_STAGES, else CHECK_STAGES.

### carat.rb misses three files

- Location: carat.rb:2 (sweep, quality).
- Why: indent_guides.rb, border_style.rb, and search_handler.rb are reached only through other files, though the header says every file is pulled in here.
- Fix outline: add each to its layer section.

### Scanner errors pass the text gates

- Location: tools/open_pr.sh:76, tools/gates.sh:208, :520, tools/docs_lint.sh:95, tools/scan_text.sh:82, :90 (sweep, quality).
- Why: the callers judge only the scanner's output, so an exit 2 with no output passes; --diff mode with a missing FILE scans nothing.
- Fix outline: fail on an exit other than 0 or 1, as pr_scan.sh does, and check each --diff FILE exists.

### metrics.sh compare passes a base name never measured

- Location: tools/metrics.sh:85, :17 (sweep, quality).
- Why: compare walks only the current file, so a strict base allocs or rounds name missing from the current run passes, against the header.
- Fix outline: mark names seen and fail every unseen strict base name in END.

### The branch pattern and the trailer are spelled three times each

- Location: tools/run_state.sh:2347, :2420, tools/open_pr.sh:47, tools/agent_guard.sh:117, tools/gates.sh:78, tools/scan_text.sh:29 (sweep, quality, two notes).
- Why: three copies of BRANCH_RE and of the co-author trailer can drift.
- Fix outline: one BRANCH_RE and one TRAILER in tools/rules.sh, a tools_test equality case for the guard copy (a merge-gate rules edit, landed alone).

### ci_scope.sh repeats its API calls

- Location: tools/ci_scope.sh:80, :81, :84, :117 (sweep, quality).
- Why: the commits pulls call runs twice and the spin check-runs query twice.
- Fix outline: one call printing both fields and a spin_passed helper.

### rules.sh documentation comment misstates tools-test scope

- Location: tools/rules.sh:62, tools/ci_scope.sh:9 (sweep, quality).
- Why: documentation() is said to be read by no tool case, yet TOOLS_RE (:88) scopes tools-test on CLAUDE.md and .claude/commands.
- Fix outline: say no test or build reads them, tools-test scoped by TOOLS_RE.

### The tools-test help line omits four scripts

- Location: Makefile:433 (sweep, quality).
- Why: it leaves out open_pr.sh, scan_text.sh, pr_scan.sh, and rules.sh.
- Fix outline: name them, or say every script under tools/.

### gate_pushes passes a non-numeric count

- Location: tools/gates.sh:397 (sweep, quality).
- Why: -gt on a non-numeric pushes, ci_fixes, or review_fixes errors and the gate prints ok.
- Fix outline: refuse a value that is not digits.

### gen_respond_to_tables types Row arrays as untyped

- Location: tools/spinel/gen_respond_to_tables.rb:114, :141, :159 (sweep, quality).
- Why: Array[untyped] where every element is a Row.
- Fix outline: Array[Row].

### Nothing checks the vendored Spinel header against its generator

- Location: tools/spinel/gen_respond_to_tables.rb, docs/codebase-map.md:78 (sweep, quality).
- Why: a drift shows only at the next SPINEL_REF bump.
- Fix outline: a tools-test case or a CI step on a SPINEL_REF change running make spinel-header and diffing the header.

### The ruby plugin copies Filetype's tables and misses shebang files

- Location: carat/plugins/ruby/plugin.rb:24, carat/domain/filetype.rb:8 (sweep, quality).
- Why: EXTENSIONS and NAMES copy the domain's; a Ruby script found by its shebang or :set ft=ruby never gets the structure check's sign.
- Fix outline: carry the buffer's filetype in PluginApi::Event (minor API bump), drop the copies, add a shebang case.

### The Visual cursor cell loses a documentation buffer's markup

- Location: carat/adapters/frame_presenter.rb:742, :826 (sweep, quality).
- Why: place_cursor reads the group from syntax_cache.lookup while paint_window paints a styled buffer from style_at, so the cursor cell shows Normal.
- Fix outline: one private helper choosing the entry as paint_window does.

### FramePresenter exposes test-only wrappers

- Location: carat/adapters/frame_presenter.rb:318, :1235, docs/codebase-map.md:462 (sweep, quality).
- Why: public display_col and display_width wrap DisplayWidth.column for one test; diagnostic_group is a public class method under private.
- Fix outline: test DisplayWidth.column directly, make them private, update the map entry.

### SyntaxCache#lookup recomputes start_of

- Location: carat/domain/syntax_cache.rb:159, :83 (sweep, quality).
- Why: row == 0 ? 0 : ends[row - 1] copies start_of.
- Fix outline: start = start_of(row).

### Three bars define [No Name]

- Location: carat/adapters/status_bar.rb:47, tab_bar.rb:22, winbar.rb:18 (sweep, quality).
- Why: three copies of one constant.
- Fix outline: one domain constant the three read.

### DecodedLine and Cell are immutable Structs

- Location: carat/domain/decoded_line.rb:15, carat/domain/cell.rb:8 (sweep, quality).
- Why: documented as never changed after built, yet Structs, while CLAUDE.md makes immutable values Data subclasses.
- Fix outline: make them Data, or record why the hot path needs a Struct.

### The ruby tokenizer declares constants among private methods

- Location: carat/plugins/ruby/tokenizer.rb:805, :877 (sweep, quality).
- Why: JUMPS and OPERATOR_NAMES sit apart from the constant block at :25 to :31.
- Fix outline: move both to the top block.

### Replace mode shows no mode message

- Location: carat/adapters/frame_presenter.rb:1256 (sweep, quality, Neovim compatibility).
- Why: paint_message shows -- INSERT -- and the visual modes but nothing in Replace, where Neovim prints -- REPLACE --.
- Fix outline: add the branch with a frame presenter test and a docs/compatibility.md note.

### StatusSlots#set_lsp reports a change on every empty-name call

- Location: carat/domain/status_slots.rb:47 (sweep, quality).
- Why: it stores :none for an empty name but compares the given state, so each call answers changed and asks for a redraw.
- Fix outline: normalize the state before the comparison.

### Area 13 map entries omit LineCache#size and two StatusSlots methods

- Location: docs/codebase-map.md:478, :466 (sweep, quality).
- Why: size (line_cache.rb:50), set_lsp and label (status_slots.rb:45, :86) are unlisted.
- Fix outline: list them.

### Class comments in the UI adapters are ragged

- Location: carat/adapters/frame_presenter.rb:43, :90, status_bar.rb:16, set_command_handler.rb:17, highlight.rb:6, frame.rb:15, :31 (sweep, quality).
- Why: later edits left them past or short of the 72-column wrap.
- Fix outline: rewrap them.

### The merge phase's output on a green first-pass CI varies fivefold
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js` (palette-narrow note 3, check-parallel note 8).
- Why: palette-narrow's merge took 69,031 of 304,750 output tokens (22.7%) in 11 calls with ci:1 and 4 CI wait calls; check-parallel's 22,685 in 11 calls; of the last 20 lane rows 19 passed CI first, 6 of them over 10,000 (up to 39,463) against a median near 7,100.
- Fix: make one CI wait and one merge cost about the same each run; accepted when the merge phase stays under 8,000 output tokens in 4 of the next 5 runs whose CI passes first.

### The checker's start costs as much as a fix round on a first-pass check
- Location: the check phase of `.claude/workflows/deliver-change.js`, `.claude/agents/checker.md` (palette-narrow note 4).
- Why: palette-narrow's check took 40,656 of 304,750 output tokens (13.3%) in 8 calls for a pass at the first try, while check first pass is 130 of 132 changes and 6 of the last 10 feature rows' check phase ran under 6,200.
- Fix: remove or merge the checker start so a passing check costs little; accepted when a first-pass check costs under 6,000 output tokens in 4 of the next 5 runs and a failing stage still returns to the contributor.

### The check-pass budget step returns nothing or reads under (same proposal as budget-prediction)
- Location: the check-pass budget step of `.claude/workflows/deliver-change.js` (palette-narrow note 4, check-parallel note 9).
- Why: check-parallel's step printed no spent line; palette-narrow's read under at 178,345 because it counted no phase from check on, which then added 126,405 (41%); the projection assumes 6 total tokens per output token while the last ten backlog rows ran 3.5 to 59.
- Fix: drop the step or fold it into the close budget line; accepted when over the next 5 runs every budget step prints an under: or over: line, or the close line is the only one.

### Quality advisories the package step drops as style (same proposal as review-demotion)
- Location: `.claude/agents/quality-reviewer.md` (check-parallel note 10).
- Why: check-parallel dropped 4 of 7 advisories as style-only, 1 fixed, 2 appended; sprint-security dropped 3 of 6; reviews 26,694 output (11.1%) and 26 of 133 calls; quality first pass 67/131.
- Fix: the reviewer does not report a class the contributor then drops unchanged; accepted when over the next 5 runs the package step drops none of the advisories reported.

### A stage's branch code can forge its pass record through the runner's job files (security Medium, confidence 6)
- Location: tools/run_state.sh:637 (stages_reap and the jobs directory beside the check clone)
- Why: a stage runs the branch's own code in the check clone, and the runner's job files sit in ../jobs/ beside it; the code can overwrite ../jobs/NAME.start with a PID the runner did not start plus the current commit and write 0 to ../jobs/NAME.status, so stages_reap records stage.NAME as passed at HEAD for its own stage or any stage running beside it, and gate_stages in tools/gates.sh accepts it, weakening the clone isolation the README promises; before this change the exit status came straight from `wait`. Not blocking since a deliberate stage could already reach the run state through the tmp/.toolchain symlink.
- Fix: keep each job's PID, start second, and commit in runner shell variables, take the exit status from `wait PID` on the runner's own child (poll with `kill -0`, then `wait`), or keep status files in a runner-owned mktemp -d outside the clone's parent, and trust only a PID the runner launched.

### A failing stage's log excerpt reaches the terminal unfiltered (security Low, confidence 4)
- Location: tools/run_state.sh:778
- Why: the last 20 lines of a failing stage's log go to the check's stdout and check.log as they are; branch code controls that log, so terminal escape sequences such as OSC 52 clipboard writes or title changes reach whoever runs the check or cats check.log.
- Fix: strip control characters from the excerpt before printing it, for example through `LC_ALL=C tr -d '\000-\010\013-\037\177'` ahead of the sed prefix, or print it with `cat -v`.

### stages_stop does not record a passed compile stage as compiled
- Location: tools/run_state.sh:666
- Why: a compile stage that passed while the check was stopping is recorded through stage_end but compiled_set is never called, so the next check compiles it again, costing minutes of a stage the cache already holds.
- Fix: share one record-a-passed-stage step (stage_end, then compiled_set for COMPILE_STAGES) between stages_reap and stages_stop.

### A lost runner's stage jobs keep running, and its test waits them out with a fixed sleep
- Location: tools/tools_test.sh:558, check_lost in tools/run_state.sh
- Why: the fixed `sleep 3` is timing-fragile and shows that check_lost leaves a hard-killed runner's stage jobs running, writing into the stage logs the next check reuses.
- Fix: have check_lost stop the lost runner's process group (setsid makes its pid the group id) and drop the sleep from the test.
### The contributor self-check and the quality reviewer share no blocking checklist
- Location: `.claude/agents/contributor.md` (self-check), `.claude/agents/quality-reviewer.md` (blocking rule)
- Why: quality fails its first pass most often, 66 of 130 changes against check 128/130 and security 125/130; 5 of the last 11 feature rows quality:0; lsp-container-b's fix round (SIGPIPE ending carat on stop) cost implement 153,294 of 264,142 output (58.0%) and put the run over its 200,000 output budget at 229,659 (retro note 11).
- Fix: one blocking checklist both read, or drop the self-check items that never caught a blocker; accepted when the feature lane's quality first pass over the next 10 rows reaches 8 of 10 with implement output no higher than its current median. Queued in `review-demotion`.

### A post-review prose edit in the package step refuses the push
- Location: the package step of `.claude/workflows/deliver-change.js` and the check and security records it invalidates
- Why: in lsp-container-b a docs-only wording fix (`docs/architecture.md:275`, Open3) invalidated the recorded check and security review, the push was refused, the edit reverted and the stale sentence left on main; package 21 of 210 tool calls (10.0%) (retro note 12).
- Fix: settle the advisories the package step may fix before the last review, or let pure prose edits of docs keep the records; accepted when no package step over the next 10 runs has a refused push from a post-review prose edit. Queued in `check-skip`.

### The in-run budget line prices total tokens at 6 per output token
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`
- Why: sprint-12-records spent 36,282 output against 2,147,268 total (59 per output), 4.3x over small's 500,000, while 6 per output predicted 217,692; the last ten backlog rows ran 3.5 to 59 per output; windows-tabs-tidy 1,433,283 and windows-buffers-tidy 1,373,899 were over 1,200,000 at 4.8 and 10.7; sprint-security's line said under at 131,132 output (lsp-container-b note 13, sprint-security note 8).
- Fix: derive the multiplier from the lane history or drop the in-run total estimate; accepted when the line, replayed over the last ten rows of both lanes, says over for every row whose final total exceeded its budget. Queued in `budget-prediction`.

### Scout packs whose facts the contributor redoes
- Location: the scout phase of `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md`
- Why: in sprint-security the scout took 34,911 of 181,413 output (19.2%) and 19 of 126 calls, its pack found the brief's lines stale and the contributor re-checked them at the same commit; backlog rows' scout share 18.4% to 40.1% (sprint-security note 7).
- Fix: start a scout only where its facts change a decision, or let the contributor take the pack as read; accepted when over the next five runs that start a scout its output stays under 10% of the run's with no drop in the quality first-pass rate. Queued in `scout-value`.

### The quality reviewer reports advisory classes the package step drops
- Location: `.claude/agents/quality-reviewer.md` (advisory classes)
- Why: of sprint-security's 6 advisories, 3 naming or duplication ones (RAN, the repeated prompts, the findingLine format) were dropped, changing no decision; the reviews phase took 15,732 output and 28 of 126 calls (22.2%) (sprint-security note 9).
- Fix: stop reporting the classes the package step drops by rule; accepted when over the next five runs the package step drops no advisory class the reviewer reported, with blocking findings unchanged. Queued in `review-demotion`.

### The benchmark phase measures records and docs-only runs that build nothing it measures
- Location: `.claude/workflows/deliver-change.js` (the benchmark phase's start condition)
- Why: sprint-12-records bench took 6,460 of 36,282 output tokens (17.8%) and 10 of 79 tool calls, stopped at its cap; over the three sprint records runs bench took 15,099 of 127,367 output tokens (11.9%) and 23 of 222 calls, each finding allocations and rounds equal to main (bench first pass 3 of 3), so its result changed no decision (sprint-12-records retro note 4).
- Fix: record the bench phase as skipped, with its reason and 0 tool calls, on a run touching no file under `carat/`, `bin/`, `bench/`, or the Makefile; accepted when the next records or docs-only run shows it skipped and a change touching those paths is still measured.

### Groom output needs a hand edit and draws the records runs' quality advisories
- Location: `tools/run_state.sh` (`groom`, `folded_backlog` near :1851)
- Why: sprint-12-records hand-edited `docs/backlog.md:6714` after groom because docs-lint refused a backticked path to a findings file groom had just removed (sprint-10-records the same, 2 of the last 3 records runs); all 3 of its 3 quality advisories were groom output (headings folded twice from a double append at :6775 and :6787; no blank line before folded headings at :6751, :6765, :6861); reviews took 9,975 of 36,282 output tokens (27.5%) (sprint-12-records retro note 5).
- Fix: accepted when a tools-test case shows groom leaving no backticked path to a removed findings file, no repeated folded heading, and a blank line before each folded heading, and the next records run applies groom with no hand edit and no advisory on groom output.
### The language server stop signals TERM before the writer sends the queued shutdown
- Location: carat/drivers/process_runner.rb:81
- Why: `stop` sends TERM on the editor thread before the writer thread has written the shutdown and exit requests the gateway queues, so the graceful language server shutdown is usually skipped and the server ends without flushing its state.
- Fix: have the writer drain signal and detach after it closes the child's input (the pid still unreaped), keeping the immediate TERM only where nothing may wait, or say in the `ProcessPort` comment that shutdown is best effort.

### The stalled server test does not prove the blocked write path and sleeps 0.7 s
- Location: test/drivers_process_runner.rb:91
- Why: the stalled case relies on `sleep 0.2` for the writer thread to block in `write` before `stop`; when it has not, the write fails at once on the closed pipe and the case still passes without exercising the blocked write, and its three sleeps add 0.7 s to every test run.
- Fix: stop only after a second write returns while the first is pending (or poll until the outbox is drained into the pipe), and drop the sleep before `stop_cat`, which the next spawn does not need.
### The contributor's self-check and the quality reviewer use different blocking checklists (lsp-container-b retro note 11)
- Location: `.claude/agents/contributor.md` self-check, `.claude/agents/quality-reviewer.md` blocking rules
- Why: quality failed its first pass in lsp-container-b (SIGPIPE ending carat on stop), quality:0 in 5 of the last 11 feature rows and 66 of 130 over all changes against check 128/130 and security 125/130; the fix round cost implement 153,294 of 264,142 output (58.0%) and took the run over its 200,000 output budget (229,659). Adds evidence to "### Quality fails its first pass on about half the runs".
- Fix: one blocking checklist both read, or drop the self-check items that never caught a blocker; accepted when the feature lane's quality first pass over the next 10 rows reaches 8 of 10 with implement output no higher than its current median.

### A post-review prose edit in the package step refuses the push (lsp-container-b retro note 12)
- Location: the package step of `.claude/workflows/deliver-change.js`, the review-currency check of `tools/run_state.sh push`
- Why: a docs-only wording fix of `docs/architecture.md:275` invalidated the recorded check and security review, 1 refused push, the edit reverted and the stale Open3 sentence left on main; package 21 of 210 tool calls (10.0%).
- Fix: settle the advisories the package step may fix before the last review, or exempt pure prose edits from invalidating it; accepted when no package step over the next 10 runs has a refused push from a post-review prose edit.

### The in-run budget line prices total tokens at 6 per output token (lsp-container-b retro note 13, sprint-security retro note 8)
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`
- Why: the last ten backlog rows ran 3.5 to 59 total per output; sprint-12-records 36,282 output projected 217,692 against 2,147,268 actual (over small 500,000 by 4.3x), windows-tabs-tidy 1,433,283 and windows-buffers-tidy 1,373,899 over 1,200,000 at 4.8 and 10.7, sprint-security's line said under at 131,132 output. Folds into `budget-prediction`.
- Fix: derive the multiplier from the lane history or drop the in-run total estimate; accepted when the line, replayed over the last ten rows of both lanes, says over for every row whose final total exceeded its size budget.

### The scout's pack is redone by the contributor (sprint-security retro note 7)
- Location: the scout phase of `.claude/workflows/deliver-change.js`, `.claude/agents/scout.md`
- Why: sprint-security scout 34,911 of 181,413 output (19.2%) and 19 of 126 calls, its pack found the brief's lines stale and the contributor re-checked them; backlog rows scout share 18.4% to 40.1% over five runs. Folds into `scout-value`.
- Fix: accepted when, over the next five runs that start a scout, scout output stays under 10% of the run's output with no drop in the quality first-pass rate.

### The quality reviewer reports advisory classes the package step always drops (sprint-security retro note 9)
- Location: `.claude/agents/quality-reviewer.md` advisory rules, the package step's advisory triage
- Why: 3 of sprint-security's 6 advisories (naming, repeated prompts, a duplicated format) were dropped as changing no decision; reviews 15,732 output and 28 of 126 calls (22.2%).
- Fix: accepted when over the next five runs the package step drops no advisory class the reviewer reported, the reviewer no longer reporting that class, with first-pass blocking findings unchanged.

## Three folded headings appear twice from the markdown-reading-c double append

- Location: docs/backlog.md:6775
- Why: the headings "Quality fails its first pass on about half the runs", "A resumed run records 0 output tokens for the phases done before the resume", and "A check pass after a fix round costs more than a first pass" were folded twice from the markdown-reading-c findings file's double append, which groom.txt did not list as repeats, so the backlog carries duplicate entries.
- Fix: have the next sprint grooming list the three as repeats so groom drops the second copies.

## Quality advisory on the markdown-reading-c double append is folded twice

- Location: docs/backlog.md:6787 and docs/backlog.md:6790
- Why: the same quality advisory on the markdown-reading-c double append is folded twice in near-identical words, so the backlog holds a duplicate entry.
- Fix: keep one entry at the next grooming.

## Folded backlog headings follow the previous entry with no blank line

- Location: docs/backlog.md:6751, docs/backlog.md:6765, docs/backlog.md:6861; tools/run_state.sh:1851 (folded_backlog)
- Why: findings entries are appended without a separator and folded_backlog keeps them as written, so the folded headings at those lines sit directly under the previous entry with no blank line, breaking the backlog's format.
- Fix: have the findings append or folded_backlog put one blank line before every heading.

### The benchmark phase measures records and docs-only runs (sprint-12-records retro note 4)
- Location: `.claude/workflows/deliver-change.js` benchmark phase; sprint-12-records run state note.4.
- Why: bench took 6,460 of 36,282 output tokens (17.8%) and 10 of 79 calls on sprint-12-records, 15,099 of 127,367 (11.9%) and 23 of 222 calls over the three sprint-records runs, and found allocations and rounds equal to main 3 of 3, never changing a decision.
- Fix: skip the bench phase with its reason when the change touches no file under carat/, bin/, bench/, or the Makefile; accepted when a records run records bench skipped with 0 calls and a carat/ change is still measured.

### groom output needs a hand edit after each records run (sprint-12-records retro note 5)
- Location: `tools/run_state.sh` groom and folded_backlog (about :1851); sprint-12-records run state note.5.
- Why: 2 of the last 3 records runs hand-edited docs/backlog.md after groom (a backticked path to a findings file groom deleted, docs-lint refusing it), and all 3 of sprint-12-records' quality advisories were groom output (headings folded twice from a double append, no blank line before folded headings); reviews took 9,975 of 36,282 output (27.5%).
- Fix: groom leaves no backticked path to a removed findings file, no repeated folded heading, and a blank line before each folded heading; accepted when a tools-test case shows all three and the next records run applies groom with no hand edit.

### The skeptic's disputed-note command double-quotes the finding text (`sprint-security` security Low (4))
- Location: .claude/agents/quality-reviewer.md:41
- Why: the skeptic is told to record a disputed security finding as a double-quoted shell argument, so `$(...)` or backticks in the finding text, which can echo attacker-controlled diff content, would be expanded when the skeptic runs the note command; the shape existed before, and sprint-security narrows it to disputed findings only.
- Fix: have the skeptic single-quote the note text (escape ' as '\'' and turn control characters into spaces), as the workflow's shellWord does, or have the workflow build the disputed-note commands itself from a structured disputed list in the skeptic's result.

### A security finding both reviewers missed may go unrecorded (`sprint-security` quality advisory)
- Location: .claude/agents/quality-reviewer.md:41
- Why: "Record what both missed the same way" now follows the disputed-only form, so a security finding both missed may be noted with a disputed: prefix or not at all.
- Fix: say a missed finding is noted as note CHANGE security "FINDING" (quality as in Periodic mode step 4).

### A /sprint rerun records every security finding again (`sprint-security` quality advisory)
- Location: .claude/workflows/sprint-planning.js:196
- Why: the Notes step runs on every /sprint run and init resumes sprint-N, so a rerun after an incomplete review (partial, a sweep hold, a capped skeptic, now more frequent) appends every security finding again and the planner reads duplicates.
- Fix: skip a note whose text the run state already holds.

### The report's not-recorded suffix and new Sweep line have no test (`sprint-security` quality advisory)
- Location: .claude/workflows/sprint-planning.js:267
- Why: the Security line's "its findings were not recorded" suffix and the Sweep line's new text have no tools_test case, so a regression in what the report says goes unnoticed.
- Fix: pass noted to securityLine so the existing tools_test case covers the suffix, and add a case for the Sweep line.

### lone_file_window? is evaluated once per window instead of once per tab page

- Location: carat/domain/buffer_list.rb:423
- Why: `lone_file_window?(tabs.tab_at(t))` runs for every window of the inner loop though it depends only on the tab page, so the walk repeats a per-tab-page test once per window (performance).
- Fix: compute it once per tab page before the window loop and reuse the value inside it.

### The E36 branch of open_file_window has no test

- Location: carat/use_cases/plugins/window_requests.rb:287
- Why: the branch that returns E36 for `close_scratch` on the editor's last window, replacing the old E444, is never exercised, so its message and the state it leaves are unproven (missing test).
- Fix: add a row closing a lone scratch window with no room for a split, or drop the branch if it cannot happen.
### The merge phase output on a green first-pass CI varies fivefold (check-parallel retro note 8)
- Location: .claude/workflows/deliver-change.js, the merge phase; queued in `merge-gate-integrity`
- Why: check-parallel's merge spent 22,685 of 239,451 output (9.5%) in 11 calls with 4 CI wait calls on a first-pass CI; of the last 20 lane rows 19 passed CI first, 6 of them above 10,000 merge output and the other 13 at 4,347 to 7,747.
- Fix: one CI wait and one merge per green run; accepted when over the next five runs whose CI passes first the merge phase stays under 8,000 output tokens.

### The check-pass budget step changes no decision (check-parallel retro note 9)
- Location: .claude/workflows/deliver-change.js, the budget step at the check pass; queued in `budget-prediction`
- Why: check-parallel printed "no spent line returned" at its check pass; the projection assumes 6 total tokens per output token while the last ten backlog rows ran 3.5 to 59.
- Fix: remove the step or fold it into the close budget line; accepted when over the next five runs every budget step prints an under: or over: line, or the close line is the only one.

### Quality advisories the package step drops as style (check-parallel retro note 10)
- Location: .claude/agents/quality-reviewer.md, the advisory classes; queued in `review-demotion`
- Why: check-parallel's package dropped 4 of 7 advisories as style, sprint-security 3 of 6; reviews 26,694 output (11.1%) and 26 of 133 calls; quality first pass 67/131.
- Fix: the reviewer stops reporting the classes the contributor drops unchanged; accepted when over the next five runs the package step drops none of the advisories reported.
### A check stage can fake a sibling stage's pass through the job files (sprint-13 security Medium (6))
- Location: tools/run_state.sh:639 (check-parallel, sprint-13 review).
- Why: the job files sit in ../jobs beside the check clone, writable by stage code; a stage's test writing 0 to ../jobs/SIBLING.status, or rewriting SIBLING.start, while the sibling runs makes stages_reap record it (for example diagnose) passed at HEAD, and gate_stages accepts that record; before check-parallel the status came from wait. Not blocking: a hostile stage could already reach the run state through the tmp/.toolchain symlink.
- Fix: take each exit status only from wait on a PID the runner itself started (poll with kill -0), or keep the status files in a runner-owned mktemp -d outside the clone's parent; accepted when a tools-test stage writing a sibling's status file cannot turn the sibling into a pass. Queue item `check-runner-safety`.

### The failing stage's log excerpt reaches the terminal unfiltered (sprint-13 security Low (4))
- Location: tools/run_state.sh:778 (check-parallel, sprint-13 review).
- Why: tail -n 20 of a log the branch code controls goes to the check's stdout and check.log as is, so test output can carry OSC 52 clipboard writes or title and terminal-state sequences to whoever runs the check or reads check.log.
- Fix: strip control characters before the prefix (LC_ALL=C tr -d of 000-010, 013-037, 177) or print through cat -v; accepted when a tools-test excerpt holding an escape prints none. Queue item `check-runner-safety`.

### jobs_refusal has two arms for one message and runs twice (sprint-13 quality)
- Location: tools/run_state.sh:569, :762, :969.
- Why: two case arms print the same message, the empty-string pattern never matches as CHECK_JOBS defaults to 3, and check_wait (:969) and check_stages (:762) both run it, the second after the queued stages' compiled records were reset.
- Fix: one pattern such as *[!0-9]*|0|0[0-9]*, checked once before the loop. Queue item `check-runner-safety`.

### The skeptic records a disputed security finding as a double-quoted shell argument (sprint-13 security Low (4))
- Location: .claude/agents/quality-reviewer.md:41 (sprint-security).
- Why: $(...) or backticks in the finding text, which can echo diff content, expand when the skeptic runs the note command; the workflow's own Notes step single-quotes with shellWord, this path does not.
- Fix: the skeptic returns a structured disputed list and the workflow builds the note commands with shellWord; accepted when a tools-test finding holding $(...) is recorded literally. Queue item `sprint-security-b`.

### The Notes phase hands reviewer text to a general agent with Bash (sprint-13 security Low (3))
- Location: .claude/workflows/sprint-planning.js:198 (sprint-security).
- Why: shellWord protects the shell, but finding text echoed from the diff can still act as a prompt injection on the notes agent.
- Fix: write the findings to a file under build/ and run one fixed command that reads them (a run_state.sh note-file subcommand), or start the notes agent limited to Bash and the guard hook; accepted when the notes prompt holds no finding text. Queue item `sprint-security-b`.

### A rerun /sprint after a partial review records its notes twice (sprint-13 quality)
- Location: .claude/workflows/sprint-planning.js:197; tools/run_state.sh:1375 (add_note).
- Why: add_note drops repeats only for quality-advisory and init resumes the run state, so a partial review (missed above 0), which forces /sprint again, records the same security and quality notes a second time and the backlog fold gets duplicates.
- Fix: skip Notes and the skeptic on a partial review, or have add_note drop a security or quality note already recorded; accepted when a tools-test rerun leaves one copy. Queue item `sprint-security-b`.

### lone_file_window? reads only the tab page yet lives on BufferList (sprint-13 quality)
- Location: carat/domain/buffer_list.rb:475, :423; carat/use_cases/files/quit.rb:87.
- Why: lone_file_window?(page) reads only file_window_count and layout.leaf_count, Quit#beside_side_windows? restates the rule with its own loop, and :423 evaluates it per window though it depends only on the tab page.
- Fix: TabPage#lone_file_window? called by Quit, DeleteBuffer, and close_windows_of, once per tab page. Queue item `windows-buffers-walk`.

### open_file_window repeats SplitWindow with another minimum width (sprint-13 quality)
- Location: carat/use_cases/plugins/window_requests.rb:283, :291; carat/use_cases/windows/split_window.rb:36; plugin_registry.rb:360.
- Why: it repeats floats.leave, layout.split, E36, adopt, focus, load, passing a minimum width of 1 where SplitWindow passes gutter width + 1, while the registry handles the same last-plugin-window case with an in-place show and unfix_size: two ways to do one thing; file_at(1) restates first_file.
- Fix: one shared path for both cases, and first_file. Queue item `windows-buffers-walk`.

### close_scratch's E36 refusal has no test (sprint-13 quality)
- Location: carat/use_cases/plugins/window_requests.rb:287.
- Why: closing a lone scratch window with no room for the file window answers E36 untested, unlike the other close_scratch scenarios (test/editor_plugins.rb, test/editor_explorer.rb).
- Fix: a row closing a lone tree in a window too small to split, expecting E36. Queue item `windows-buffers-walk`.

### BufferList#withdraw saves a cursor no one reads (sprint-13 quality)
- Location: carat/domain/buffer_list.rb:449.
- Why: remember(window) runs on target just before it leaves the list, and neither alternate_of nor a reopen reaches a removed buffer: a dead write.
- Fix: drop the remember call, keep show plus restore. Queue item `windows-buffers-walk`.

### FollowPalette#pad keeps a ternary ljust makes unneeded (sprint-13 quality)
- Location: carat/use_cases/discovery/follow_palette.rb:306.
- Why: ljust returns a copy when the width is not larger than the length (sp_str_ljust returns sp_str_dup), so the ternary adds nothing.
- Fix: cell.ljust(cell.length + width - used). Queue item `ui-code-tidy`.

### The architecture names no one-shot ProcessRunner path (sprint-13 quality)
- Location: docs/architecture.md:275, :431; carat/drivers/process_runner.rb:93.
- Why: the rewritten line names only the language server path and a planned Open3.capture3 formatter, and the table only Open3, while ProcessRunner#capture already runs short commands with spawn and no shell.
- Fix: name capture as the one-shot path; Open3 stays planned only for a tool needing stdin_data. Queue item `architecture-docs`.

### A doubled blank line before check_wait (sprint-13 quality)
- Location: tools/run_state.sh:962.
- Why: a second blank line was added before the check_wait comment.
- Fix: remove it. Queue item `tools-docs-tidy`.

### The sprint and parallel-check tests grep source lines and sleep fixed seconds (sprint-13 quality)
- Location: tools/tools_test.sh:3701, :472, :558.
- Why: the sprint tests grep exact lines of sprint-planning.js (const reviewed, const swept, const plan), so reformatting breaks them, and the parallel-check tests depend on 1 s and 4 s stage timings (sleep 3) and may flake on a loaded CI.
- Fix: test through exported helpers with js as the securityLine test does, and wait on the job status files or run state records. Queue item `prose-grep-cases`.

### MarkdownText.parse runs the marker scan twice per line
- Location: carat/domain/markdown_text.rb:114 (parse calling flow_key, then marker_end at line 123 or block at line 133)
- Why: each line's quote markers are scanned once in flow_key and again in marker_end or block, a repeated byte walk per row on reading views of up to 262,144 bytes, though the shared scanner was meant to read a line once.
- Fix: compute markers(line) once in parse and pass the packed scan to flow_key and block, marker_end becoming marker_stop(scan).
### The merger returns pending before its 30-minute CI wait ends (lsp-container-c retro)
- Location: `.claude/agents/merger.md` step 2; `.claude/workflows/deliver-change.js` merge phase
- Why: lsp-container-c's merger returned pending after 3 and then 0 of 30 minutes while CI was in progress, so the workflow started it three times on a CI that passed first time: merge took 30 of 119 calls (25.2%) and 12,961 output tokens, against a median of 12 merge calls over the last 10 feature rows. For `merge-gate-integrity`.
- Fix: the merger waits the full 30 minutes on a queued or running check before returning pending; accepted when over the next 5 runs no note reports an early pending return and merge stays at or under 15 calls on a first-pass green CI.

### Quality advisories still dropped at the package step (lsp-container-c retro)
- Location: `.claude/agents/contributor.md` package step 2
- Why: 3 of 3 lsp-container-c advisories (`carat/domain/config.rb:219`, `carat/domain/trusted_roots.rb:48`, `docs/codebase-map.md:100`) went only into the pull request Notes, now 14 of 23 dropped over the last 4 rows with advisories; quality first pass 71/136. For `review-demotion`.
- Fix: remove the contributor's judgment of which advisories to keep; accepted when over the next 5 runs every advisory is fixed or in the change's findings file, 0 dropped.

### Scout and areas starts repeat what the planner and contributor establish (lsp-container-c retro)
- Location: `.claude/workflows/deliver-change.js` areas and scout phases
- Why: lsp-container-c's scout and areas cost 41,568 of 220,432 output (18.9%) and 24 of 119 calls (20.2%) for an implement of 27 calls, the planner having named the check site and the contributor re-verifying both scout findings; lsp-container 25.9%, lsp-container-b 15.3% of output. For `scout-value`.
- Fix: skip or shrink the scouts when the brief names its locations; accepted when over the next 5 runs scout and areas stay under 10% of output, implement calls at or under the last-10 feature median (38), first passes not lower.

### squash_commit falls back to HEAD, so a branch commit can pass merged_at (security Low (4))
- Location: tools/run_state.sh:1560
- Why: squash_commit falls back to HEAD and merged_on_main also accepts an ancestor of HEAD, so while origin/main has no commit whose subject ends with the pull request number, a branch commit with that subject passes merged_at; an agent could record merged at an unmerged branch commit, which would skew the history rows and the sprint base the sprint-end security review starts from.
- Fix: have squash_commit and merged_at search only BASE (origin/main), with no fallback to HEAD, so a merged value must be the squash commit on main itself; this also removes the fallback loop that can never yield an accepted commit.

### groom_row trusts history rows the branch can append after review (security Low (3))
- Location: tools/gates.sh:131
- Why: groom_row compares the appended sprints row with sprint_row, which reads the lane history rows from the working tree; those are records-only paths a branch can append to after review, so a forged history row plus a matching sprints row still passes settled_at and moves the sprint base, which groom_row is meant to prevent.
- Fix: compute the expected row from the history files at the reviewed COMMIT plus only the history row this change's own package step adds, or check that the history rows appended since COMMIT are this change's single row before trusting them.

### groom_row reads the shared sprint marker, refusing a records row merged from main (quality, behavior cost)
- Location: tools/gates.sh:128
- Why: groom_row reads the marker in the shared build/plan, so a lane that merged main's records-only sprint row after its reviews has it refused once the planner writes the next sprint's marker, and a review re-runs needlessly.
- Fix: accept a sprint row already on BASE (brought by a merge from main), or name the cost in the design's Risks.

### The groom appends the benchmark-phase and groom-output entries three times

- Location: docs/backlog.md:7218
- Why: the entries 'The benchmark phase measures records and docs-only runs that build nothing it measures' and 'Groom output needs a hand edit and draws the records runs' quality advisories' are appended verbatim twice (:7200/:7205 and :7218/:7223) and a third time as sprint-12-records retro notes 4 and 5 (:7268 on), the groom double-append the backlog already records (duplication).
- Fix: list the copies at :7218-7227 and :7268 on as duplicates at the next grooming and have groom not append both a groomed.md entry and the folded finding of the same note.

### The groomed.md entries repeat the folded retro notes

- Location: docs/backlog.md:7176
- Why: the groomed.md entries at :7176-7198 (contributor self-check checklist, post-review prose edit, in-run budget line, scout packs, advisory classes) repeat the folded retro notes at :7228-7251 in near-identical words (duplication).
- Fix: keep one of each pair at the next grooming (backlog-dups).

### Folded headings follow the previous entry with no blank line

- Location: docs/backlog.md:7176
- Why: the folded headings at :7176, :7209, and :7218 follow the previous entry with no blank line (format).
- Fix: have folded_backlog put one blank line before every folded heading, as the queued groom entry says.

### Three sprint-12-records findings use level-two headings

- Location: docs/backlog.md:7253
- Why: the three sprint-12-records findings at :7253, :7259, and :7265 use level-two headings while every other entry is level three (format).
- Fix: make them level-three headings and have the findings append keep the entry level.

### A folded entry is already resolved and its Location lines are stale

- Location: docs/backlog.md:7253
- Why: the folded entry on the three doubled headings is already resolved by this groom (groom.txt drops the duplicates), and the Location lines of :7253-7265 (docs/backlog.md:6775, :6787, :6790, :6751, :6765, :6861) point at pre-groom lines that now hold other entries (docs currency).
- Fix: list it as fixed at the next grooming and have findings name a heading instead of a backlog line number.

### The package step applies review advisories to reviewed files and the push is refused (markdown-reading-d retro)
- Location: `.claude/agents/contributor.md` package step; `.claude/workflows/deliver-change.js` package phase
- Why: markdown-reading-d's packaging contributor applied an advisory that reworded a reviewed comment and its code map line, the pre-push gates refused the push twice (gates_failed 2), and both files were put back in new commits, still claiming one marker scan; package took 22 calls against a last-10 feature median of 15.5, 3 of 3 advisories the cause. For `review-demotion`.
- Fix: an advisory whose fix touches a reviewed file goes to the findings file or a fix round, never a package edit; accepted when over the next 5 deliveries with advisories no package-phase push is refused (gates_failed 0).

### The checker agent costs far more than the verdict of run_state.sh check (markdown-reading-d retro)
- Location: `.claude/agents/checker.md`; `.claude/workflows/deliver-change.js` check phase
- Why: markdown-reading-d's check took 35,360 output tokens in 4 calls, 13.0% of the run's 272,795 output, for a verdict the script gives; first-pass check 136 of 138; ux-fixes-a 22,463 and palette-narrow 40,656 also over 20,000 on a first pass against a last-10 median of 6,425. For `check-skip`.
- Fix: run the check script from the workflow without an agent, or cap the agent; accepted when over the next 5 deliveries a first-pass check costs at most 5,000 output tokens and 4 calls, the stage records and first.check unchanged.

### groom_row compares newline-stripped rows and trusts untracked inputs (sprint-14 review security Low (3) and quality)

- Location: tools/gates.sh:131 to :134.
- Why: groom_row derives the expected sprint row from the untracked build/plan/sprint marker and the working tree's history rows, so a branch appending matching history rows can add a sprints.tsv row the records-only gate accepts and move the sprint base (security Low (3)); it compares command substitutions, which strip trailing newlines, so a row with extra blank lines or no final newline passes as the one row (found twice).
- Fix outline: expected row from committed content only (git show HEAD:file) and only for the records change; compare appended bytes exactly. Queued in `sprint-security-b`.

### merged_at without a pr accepts any ancestor of HEAD (sprint-14 review and sweep quality)

- Location: tools/run_state.sh:1581 (merged_at), :1539 (merged_on_main).
- Why: with no pr recorded, any ancestor of HEAD passes, a lane's pushed head included, against the comment that no pushed head is recorded as merged, and the refusal says "is no commit on main".
- Fix outline: require ancestry of origin/main only, or refuse until pr is recorded, with an expect case. Queued in `sprint-security-b`.

### The workflow treats a refused merged record as merged (sprint-14 sweep quality, merge-record-check retro 9)

- Location: .claude/workflows/deliver-change.js:1302 and the close's record chain.
- Why: the workflow sets state.merged and queues phase merge at the merger's sha even when run_state set merged refused it, so no merged record or history row is written and the lane stays open; one refused record in the close's && chain dropped 3 phase records and all 30 metric fields of merge-record-check (294,037 output, 181 calls).
- Fix outline: read back the merged record before treating the run as merged; a refused record reported without dropping the others. Queued in `merge-gate-integrity`.

### Bracketed paste is never enabled (sprint-14 sweep security Low (5))

- Location: carat/adapters/screen_presenter.rb:30.
- Why: pasted text holding an ESC byte leaves insert mode and the rest runs as normal-mode and ex commands (for example :w! over another file).
- Fix outline: enable bracketed paste on enter and disable it on leave, read the pasted text as literal input, test a paste holding ESC and a colon. Queued in `input-core-tidy`.

### MakePath and the project .caratrc check follow a link swapped after the probe (sprint-14 sweep security Low (3), Low (3))

- Location: carat/drivers/disk_files.rb:33; carat/adapters/rc_config_gateway.rb:70.
- Why: a probe then a write or read that follows links lets a symbolic link planted between them create a file outside the root or read a linked .caratrc.
- Fix outline: create with exclusive no-follow opens and mkdir; open the project file without following links and judge it by fstat. Queued in `file-access-tidy` and `project-config-guards`.

### RISKY_CONFIG omits pager keys (sprint-14 sweep security Low (3))

- Location: tools/agent_guard.sh:884.
- Why: a pager.CMD key runs a shell command whenever a git verb pages, and the guard does not refuse it.
- Fix outline: add pager keys to RISKY_CONFIG and its copy, with a tools-test case. Queued in `lane-guards`.

### language.trusted_roots keeps a word that is not a root (sprint-14 sweep quality)

- Location: carat/domain/config.rb:204 and :219, :223.
- Why: trusted_roots returns before its words are checked, so ./proj, projects, or ~x is kept and trusts nothing silently while an lsp.root root is reported; two consecutive blocks test the same setting.
- Fix outline: report each word RootWord.root? refuses, with a row in test/domain_rc_parser.rb; merge the two blocks. Queued in `project-config-guards`.

### Six sites re-implement tab_width and two clamp_col (sprint-14 sweep quality)

- Location: carat/use_cases/dispatcher.rb:112, repeat_last.rb:104, arrange_view.rb:43, insert_tab.rb:25, leave_insert.rb:69, carat/adapters/frame_presenter.rb:216; clamp at carat/use_cases/operate.rb:204 and repeat_last.rb:116.
- Why: each restates Options#tab_width or EditorState#clamp_col, so a change to either rule misses copies.
- Fix outline: call options.tab_width and state.clamp_col and delete the copies. Queued in `editing-dedup-a`.

### Small surface and wording tidy of the sweep (sprint-14 sweep quality)

- Location: carat/domain/keymap.rb:173 (apply public, two private callers); carat/adapters/frame_presenter.rb:320 (display_col with one internal caller); carat/use_cases/docs/format_docs.rb:36 and carat/domain/markdown_text.rb:261 (a bare positional framed flag beside two caps); carat/use_cases/plugins/window_requests.rb:30, file_requests.rb:25, carat/drivers/process_runner.rb:19 (mis-wrapped class comments); carat/use_cases/plugins/file_requests.rb:141 (the 2-second capture deadline spelled beside ProcessRunner::CAPTURE_SECONDS).
- Why: needless public surface, unclear call sites, and a constant two places must keep equal.
- Fix outline: make the helpers private, pass one layout value, rewrap, declare the deadline once on the port. Queued in `input-core-tidy`, `ui-code-tidy`, `markdown-reading-e`, `plugin-host-tidy`, `process-capture-hardening`.

### The map and architecture give PluginApi 2.6 against 2.8 (sprint-14 sweep quality)

- Location: docs/codebase-map.md:535, docs/architecture.md:330, against carat/plugin_api.rb:12.
- Why: map drift; the Paths list also omits absolute, which the explorer, WindowRequests, and VisitTarget call.
- Fix outline: set both to 2.8 and add absolute. Queued in `architecture-docs`.

### The gateway holds three UTF-16 walks and a URI codec (sprint-14 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:1116, :1162, :801, :1440; carat/use_cases/definitions/visit_target.rb:204.
- Why: three hand-rolled UTF-16 code unit walks over one lead-byte rule inside a 1486-line adapter.
- Fix outline: one domain UTF-16 module and a URI value, used by both callers. Queued in `gateway-split-a`.

### Tools gates fail open on edge inputs (sprint-14 sweep quality)

- Location: tools/gates.sh:333 (gate_cases: one expect line anywhere satisfies every changed script); tools/gates.sh:266 (has() matches a path as a regex); tools/open_pr.sh:123 (WAIT_STEP 0 loops forever); tools/metrics.sh:71 (measure reports a stale file with status 0).
- Why: each check passes or hangs on an input it should refuse.
- Fix outline: an expect line naming each changed script, grep -F, a positive step, die on a failed write; tools-test cases. Queued in `tools-fail-open`.

### Shell helpers are copied across four tools scripts (sprint-14 sweep quality)

- Location: tools/gates.sh:86 (bad, ok), tools/docs_lint.sh:37, tools/ci_scope.sh:65 (hex), the log pipeline of tools/gates.sh:222 in tools/pr_scan.sh:49.
- Why: duplication; a fix to one copy misses the others.
- Fix outline: keep the helpers once in tools/rules.sh and the pipeline behind one scan_text.sh option; a rules.sh edit lands alone first. Queued in `tools-docs-tidy`.

### Motion code keeps a require cycle, a dead store, and a cls name (sprint-14 sweep quality)

- Location: carat/domain/walker.rb:63 and carat/domain/text_objects.rb:252 (Motions.code_class used without its require, a cycle with motions.rb); carat/domain/motions.rb:599 (row = top overwritten in every branch); carat/domain/text_objects.rb:86 and carat/domain/runs.rb:90 (cls).
- Why: load-order reliance, dead code, and the abbreviation CLAUDE.md's naming rule cites as wrong.
- Fix outline: a small domain module for code_class and blank? both require; drop the store; rename to char_class. Queued in `motions-search-tidy`.

### Search code copies a class helper and a register loop (sprint-14 sweep quality)

- Location: carat/use_cases/search/find_match.rb:177; carat/use_cases/actions/motion_handler.rb:33, search_handler.rb:36, text_object_handler.rb:34 (the loop in fifteen handlers).
- Why: blank? re-implements Motions.code_class == 0; one names-descriptions loop is repeated.
- Fix outline: reuse the domain helper; an ActionTable method registering a list. Queued in `motions-search-tidy`.

### Area 6 tests and docs drift (sprint-14 sweep quality)

- Location: test/editor_motions.rb:105, :125 to :127, test/editor_text_objects.rb:67 to :69 (untyped table values); carat/domain/vim_pattern.rb:641 (collection_end comment), :674 (POSIX after private); docs/codebase-map.md:205 (LastSearch, SearchPrompt, VimPattern methods unnamed; code_class tested only in test/domain_line_cache.rb:115).
- Why: the typed-table rule of CLAUDE.md, a comment that misstates the return, and map drift.
- Fix outline: convert with to_s and to_i, reword and move the constant, name the methods and move the assertions. Queued in `motions-search-tidy`.

### The security record keeps only the last review round (merge-record-check retro 7)

- Location: the security record of tools/run_state.sh and the workflow's re-review.
- Why: security at 0b4329979642 found 2 Lows, written to the findings file and the pull request, while the re-review at f7208b282704 stored low=0, so the record disagrees with both after a rework round.
- Fix outline: accepted when a re-review finding fewer keeps the earlier round's Lows counted, shown by a tools-test case. Queued in `review-pipeline-b`.

### One blocking quality round costs a third of a medium budget (merge-record-check retro 8, overrun 6)

- Location: the rework round of the delivery workflow; the checker phase.
- Why: output rose from 129,569 at the first check pass to 210,601 at the second (+81,032, 27.6% of 294,037) for a rename in 3 shell helpers, crossing medium's 200,000 output; check 46,390 output in 12 calls over 2 passes against 2,431 to 6,411 on first-pass rows.
- Fix outline: accepted when over 5 rows with one rework round the round adds at most 40,000 output and check stays under 10,000 per pass. Queued in `check-skip`.

### The planner starts only to remove the delivered item (vim-line-commands-a retro 5)

- Location: plan-needed in tools/run_state.sh and the workflow's plan phase.
- Why: vim-line-commands-a's plan spent 11,391 output in 16 calls (6.2% of output, 10.6% of calls) and kept every decision; feature last-10 plan 9,255 to 21,937 output.
- Fix outline: accepted when the next 5 runs delivering an item as written show no plan phase and docs-lint passes the queue. Queued in `plan-skip`.

### The merge gates' fsck misses an object swapped back after the worktree add (security Low (5))
- Location: .claude/workflows/deliver-change.js:595 (the comment above the green line) and the archived ci-trust-gaps design.md
- Why: the comment and design say an fsck after the worktree add still catches an object swapped back in between, which is backwards: a process left running by branch code can plant the loose object before the add and restore main's real content before the fsck, so the add writes the planted tools/gates.sh into tmp/.merge-gates and fsck passes; such a process could also write the worktree directly, so this is defence in depth (security Low (5), and the quality review's advisory at the same line).
- Fix: correct the comment and the design: fsck catches an object still planted, not one swapped back; to close the gap, verify the checked-out files against main's tree after the fsck (hash each with git hash-object against git ls-tree origin/main under --no-replace-objects), or fsck both before and after the add, and say which window remains.
### The merge gates' worktree file can be rewritten on disk after the fsck (security Low (5))
- Location: .claude/workflows/deliver-change.js:650 (the green line's sh tmp/.merge-gates/tools/gates.sh merge)
- Why: a process left running by branch code, such as a background job of a check or the other lane's checks, can overwrite tmp/.lane-CHANGE/tmp/.merge-gates/tools/gates.sh between the worktree add and the run, which no object check sees; the fsck now between those steps (2 s warm, 47 s cold) widens that existing window.
- Fix: run main's gates from the verified store instead of the checked-out file, for example git --no-replace-objects cat-file blob origin/main:tools/gates.sh piped to sh -s merge after the fsck, or compare the checked-out tools/ against git ls-tree blob ids in the same command right before the run; record that a lingering branch process is outside the merge gates' threat model.
### The planted-object case pins fsck's exact exit status (missing-test robustness)
- Location: tools/tools_test.sh:3441
- Why: the case expects exit status 3, the OR of git's internal fsck error bits (object plus reachability), which another git version may report differently, so the case can fail with the gate still working.
- Fix: assert that the line fails and its output names the mismatch, without the exact status.
### The unpinned-git case proves the add, not that the planted gates ran (missing test)
- Location: tools/tools_test.sh:157 (the case an unpinned git would run the replaced gates past fsck)
- Why: the case sends the line's output to /dev/null and only cats the checked-out gates.sh, so it proves the worktree add followed the replace ref, not that fsck passed and the planted gates ran.
- Fix: assert the line's own output, sh -c "$2" 2>/dev/null expecting ^planted$, instead of the cat.
### The benchmark runs on a diff that touches no code (retro, third recording)
- Location: `.claude/workflows/deliver-change.js`, the bench phase start.
- Why: sprint-14-records spent 4,178 of 32,743 output tokens (12.8%) and 8 of 68 calls on bench for allocations all equal to main's and a us.insert 24% warning on a docs-only diff; over sprint-10 to sprint-14 records bench took 33,140 of 203,003 output tokens (16.3%) and 37 calls, first pass in all five; recorded before as sprint-12-records note 4 and sprint-13-records note 6.
- Fix: start no benchmark agent when the diff touches nothing under `carat/`, `bench/`, or `test/`, the row carrying main's recorded allocations and rounds; accepted when the next records row shows no bench phase and main's allocs and rounds.

### Planner and scout resolve the brief's locations twice (ci-trust-gaps retro)
- Location: `.claude/agents/planner.md`, `.claude/agents/scout.md`, `.claude/workflows/deliver-change.js` (the plan and scout phases)
- Why: ci-trust-gaps spent plan 28,293 plus scout 48,985 = 77,278 of 252,190 output tokens (30.6 percent) and 28 of 172 calls, the planner and scout disagreeing on one location (`deliver-change.js:614` against `:618`); tab-close-b 33.7 percent, check-parallel 29.8 percent.
- Fix: one of the two resolves locations and the other reuses its pack; accepted when the next three pipeline-lane rows hold plan plus scout under 20 percent of output tokens with no location re-corrected by the scout.

### The quality reviewer investigates findings it hands to security (ci-trust-gaps retro)
- Location: `.claude/agents/quality-reviewer.md`
- Why: in ci-trust-gaps quality note 1 (a replace ref past fsck, marked security's to judge) was the Medium (8) security then blocked on, the run's 1 rework round; reviews 50,343 of 252,190 output tokens (20.0 percent) and 27.3 percent of calls; quality first pass 77/143, the lowest gate.
- Fix: a finding the quality reviewer marks security's to judge is named, not investigated; accepted when reviews fall below 15 percent of output tokens on the next three pipeline rows with security never skipped.

### No case for a merged sha git cannot resolve
- Location: tools/tools_test.sh:311
- Why: the proposal counts a reported merged sha git cannot resolve (a mistyped hash) as a disagreement, but only a resolvable pushed head is tested, so a regression in that path would pass tools-test.
- Fix: add an expect running phase CHANGE merge merged with a hex value naming no commit and checking that the squash commit is recorded and the merge-disagreement note is written.

### The contributor's extras ship without their tests (T1 efficiency)
- Location: `.claude/agents/contributor.md`, its self-check step
- Why: motions-search-tidy first.quality 0 on :g and :v reading ~ through compile_search (`carat/use_cases/search/global_command.rb:65`, an extra the proposal named), the round adding 122,352 output tokens (30 percent of 407,893); 21 of 142 recorded quality-blocking notes read behavior change without its test; quality first pass 79/145.
- Fix: the self-check holds each extra the proposal names to its test like a brief entry; accepted when over the next 10 runs no quality-blocking note reads behavior change without its test on code the proposal lists as an extra.

### Passing check starts vary from 1,598 to 150,693 output tokens (T1 efficiency)
- Location: `.claude/agents/checker.md`
- Why: motions-search-tidy check 57,058 output tokens and 10 calls for two passing checks (14.0 percent of 407,893 output on 5.3 percent of 188 calls); 6 of the last 21 rows over 35,000 against a median of about 6,700; check first pass 143/145, no decision changed.
- Fix: a passing check reports from its stage logs without further reading; accepted when over the next 5 runs every passing check start costs under 12,000 output tokens.

### Scouts run on a one-area removal the plan already maps (T1 efficiency)
- Location: `.claude/workflows/deliver-change.js`, the scout phase
- Why: ruby-structure-remove scout 33,374 output tokens and 17 calls, 24.6 percent of 135,491 output and 14.4 percent of 118 calls with areas=1, while the plan named every line range; scout share tab-close-c 13.2, markdown-reading-d 11.0, lsp-container-c 16.8, vim-line-commands-a 21.9, bar-colors 28.3 percent.
- Fix: skip or shrink the scout when the plan already names every file and range; accepted when the next one-area removal or revert runs with no scout start (or under 10,000 scout output tokens) and keeps first.check, first.quality, and first.security at 1.

### Queue entries keep stale line references after their change edits the named code

- Location: docs/queue-feature.md:7 (the `ruby-structure-remove` entry), test/lint.rb (the named-path check)
- Why: the delivery had to unquote the two paths it removes so lint's path check passes, leaving the entry's line references (plugin.rb:86 and :111, tokenizer.rb:820, test/plugins_ruby.rb:145) pointing at code that no longer exists, and a delivery editing its own planner-written queue entry bypasses plan-apply.
- Fix: leave queue entries to plan-apply and have the lint path check skip docs/queue-*.md entries whose change is the branch's own, or drop the stale line numbers from queue entries.
### The mid-run output-token overrun check flags runs their totals do not confirm
- Location: `.claude/workflows/deliver-change.js`, the overrun check at the check pass (output tokens times 6 against the size's total budget)
- Why: tab-close-c flagged 219,748 output tokens against 200,000 while its total, 830,180, stayed under 1,200,000; the last 10 feature rows have total-to-output ratios 2.2 to 7.9, not 6, and 6 of them passed 200,000 output tokens while only markdown-reading-c (1,902,958) passed the total budget.
- Fix: base the mid-run flag on recorded totals or a ratio taken from the lane history; accepted when, replayed over the last 10 feature rows, it flags only rows whose total_tokens exceeded their size budget.

### The merge phase's output tokens vary 14-fold on a first-pass green CI
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js`
- Why: its only decision on a green CI is to merge, yet tab-close-c spent 52,904 output tokens in 11 calls (17.6% of 300,034), against vim-line-commands-a 4,992 and tab-close 5,808 at 11 calls; palette-narrow 69,031.
- Fix: accepted when over the next 5 runs with first.ci=1 the merge phase stays under 10,000 output tokens.

### Records changes are judged against the small budget with the sprint reviews in their totals
- Location: the budget line of `sh tools/run_state.sh budget`, the estimate of a `sprint-N-records` change
- Why: sprint-12-records 2,147,268, sprint-13-records 1,264,361, and sprint-14-records 1,973,945 total tokens against 500,000 (3 of 3 over) with only 36,282, 42,893, and 32,743 output tokens; sprint-14-records weighted phases periodicreview 19,054,636 and review 3,756,759 against deliverchange 3,040,840; the same proposal is ci-trust-gaps retro note 6.
- Fix: accepted when the next records row's budget line compares only its delivery phases with its size, or budgets the sprint review in its own line, and does not start with over for that reason alone.

# Findings of sprint-14-records

## The folded heading after the merger entry lacks a blank line

- Location: docs/backlog.md:7360 (format).
- Why: the folded heading 'The merger returns pending before its 30-minute CI wait ends' follows the previous entry's Fix line with no blank line; the known groom defect recurs and make docs-lint does not catch it.
- Fix: insert one blank line before it, and let folded_backlog put a blank line before every folded heading, as the queued groom entry says.

## Two defects are recorded twice in the backlog

- Location: docs/backlog.md:7470 (duplication), with :7380, :7375, and :7476.
- Why: the folded merge-record-check findings and the groomed sprint-14 entries record the same two defects twice: 'groom_row trusts history rows the branch can append after review' (:7380) against 'groom_row compares newline-stripped rows and trusts untracked inputs' (:7470), both at tools/gates.sh:131, and 'squash_commit falls back to HEAD' (:7375) against 'merged_at without a pr accepts any ancestor of HEAD' (:7476).
- Fix: fold each pair into one entry at the next grooming (backlog-dups), keeping the sprint-14 wording and the security Low (4) rating.

### Two definitions of a side window coexist after tab-close-c
- Location: carat/use_cases/files/quit.rb:87
- Why: TabPage#side_window? (a shown slot's window, the one place per the design) now sits beside Quit#beside_side_windows?, TabPage#editing_leaf, and file_window_count, which treat any scratch-buffer window as a side window, so :q counts a reading view or a pinned documentation split as a side window while buffer switches do not.
- Fix: route Quit#beside_side_windows? through TabPage#side_window?, or name the scratch-based notion apart (file window versus side window) in code and docs.

### No flow covers a buffer switch from a pinned documentation split
- Location: test/editor_tab_flows.rb:189
- Why: the design states a behavior change for a PinHover split, which now switches itself instead of the file window, yet only the reading view has flows, so a regression of the pinned split would pass.
- Fix: add one flow row that pins a hover split and runs :bn there, expecting the split to switch and the file window to keep its buffer.

### Cursor display column inside a closed fold drifts from the drawn one
- Location: carat/use_cases/arrange_view.rb:107
- Why: correctness; ArrangeView takes the cursor's display column from the line's column even inside a closed fold, while FramePresenter (carat/adapters/frame_presenter.rb:734) uses window.left there, so the scroll and the drawn cursor can disagree.
- Fix: one Window or presenter helper for the cursor's shown column, used by both.

### Layout#close frees a window without untracking its folds
- Location: carat/domain/layout.rb:229
- Why: performance; every later edit of the buffer shifts the dead fold record of the closed window (the design accepts the leak).
- Fix: drop the window's folds where a window is closed, as Window#show does.

### ChangeFolds#place resets want_col where Neovim keeps it
- Location: carat/use_cases/windows/change_folds.rb:44
- Why: correctness; place repeats ArrangeView#to_fold_start (carat/use_cases/arrange_view.rb:137), which now runs after every key, and the two differ on want_col: move_to resets it, while to_fold_start keeps it as Neovim's foldAdjustCursor does.
- Fix: keep one fold-start adjustment, for example a Window#to_fold_start(visual) in the domain that ArrangeView calls, and drop ChangeFolds#place (also drop the move in Operate#fold, carat/use_cases/operate.rb:162).

### A linewise put on a closed fold puts the lines inside the fold
- Location: carat/use_cases/put_register.rb:32
- Why: correctness, Neovim parity; a linewise p on a closed fold puts the lines inside the fold, hidden, where Neovim's do_put puts them below the fold's last line (P above its first).
- Fix: for a linewise entry pass the position at folds.last_row(cursor.row) for p, with an editor_folds row proving it.

### Visual modes do not take in closed folds
- Location: carat/use_cases/arrange_view.rb:138
- Why: correctness; as Neovim's foldAdjustVisual does not happen here, Vd on a closed fold over rows 0 and 1 deletes only row 0 and leaves a one-line fold, and carat/adapters/frame_presenter.rb:829 marks no selection on a fold row, while docs/compatibility.md says a linewise operator starting on a fold acts on all its lines.
- Fix: in a visual mode extend the anchor and cursor rows to the fold edges (first_row of the upper, last_row of the lower), paint the selection on the fold row, and add editor_folds rows such as zfjVd.
### The docs-lint path check fails a delivery that removes a file its own queue entry names (ruby-structure-remove retro)
- Location: `tools/docs_lint.sh:128` (check_paths), over the delivery's own item in `docs/queue-feature.md`
- Why: ruby-structure-remove's check failed in 5 s on 2 removed paths its own queue item named: first.check 0, 1 rework round (a contributor fix start and a second checker start, check 6,950 output tokens over two passes), and the fix's queue edit was discarded by plan-apply; check first pass 142/144.
- Fix: a delivery deleting a file its own queue entry names passes the check on its first pass with no hand edit of a lane queue; accepted when the next such delivery records first.check 1.

### The scout phase runs on a one-area removal whose plan names every location (ruby-structure-remove retro)
- Location: `.claude/workflows/deliver-change.js:184` (scoutTargets)
- Why: ruby-structure-remove's scout spent 33,374 output tokens and 17 calls, 24.6% of 135,491 output tokens and 14.4% of 118 calls, with 1 area, while the plan cited every file and line range and the contributor reversed the earlier diff exactly; scout share over recent feature rows 11.0% to 28.3%.
- Fix: the next one-area removal or revert runs without a scout start, or under 10,000 scout output tokens, keeping first.check, first.quality, and first.security at 1.
### The green line's refs/replace check fails open when for-each-ref errors (sprint-15 review security Low (3))

- Location: .claude/workflows/deliver-change.js:688
- Why: branch code that corrupts the ref store (for example a malformed packed-refs line) makes for-each-ref exit non-zero with no output; wc still prints 0, so the stop meant to catch any refs/replace entry passes, leaving only the --no-replace-objects flag on each pinned git.
- Fix outline: test for-each-ref's own exit status and output before the worktree add, so an error stops the line, with a tools_test case of a corrupt packed-refs file.

### Four sites compile a search against the last substitute by hand (sprint-15 review quality)

- Location: carat/use_cases/search/find_match.rb:83, carat/use_cases/search/preview_search.rb:46, global_command.rb:65, last_search.rb:70 (LastSearch#recompile); SetCommandHandler holds a LastSubstitute only to pass it through.
- Why: VimPattern.compile_search(source, ignorecase, smartcase, previous, previous_kept) is spelled in 4 places, so a change to how ~ reads the last substitute must be made in each.
- Fix outline: one domain helper taking (source, options, last_substitute), or LastSearch keeping the LastSubstitute it recompiles against.

### DelimitedPattern.typed is an alternate constructor not named from_x (sprint-15 review quality)

- Location: carat/domain/delimited_pattern.rb:42; callers find_match.rb:73, preview_search.rb:40.
- Why: the naming rule names an alternate constructor from_x.
- Fix outline: rename it from_prompt(text, forward) at both callers; cut stays public.

### The quality reviewer raises blocking parity bugs one round at a time (vim-folds-a retro 24)

- Location: .claude/agents/quality-reviewer.md and the quality phase of .claude/workflows/deliver-change.js.
- Why: vim-folds-a's later rounds raised blocking findings on behavior present at the first review (G or a mark leaving the cursor inside a closed fold; o on a closed fold): rework 3, implement 266,825 of 481,959 output tokens (55.4%) over 4 contributor starts; quality first pass 80/147 (54.4%), the lowest gate.
- Fix outline: the first review reports every blocking finding in the touched behavior; accepted when over the next 5 runs with first.quality 0 no later round raises a blocking finding on code unchanged since the first review.

### Quality re-reviews re-raise recorded advisories (vim-folds-a retro 25)

- Location: the quality phase of .claude/workflows/deliver-change.js.
- Why: in vim-folds-a the closed-window fold leak was raised 3 times (notes 5, 12, 17) and the fold-start duplication twice (15, 19); 13 advisories handed to packaging, 6 dropped; reviews 96,869 output tokens (20.1%) and 110 calls (31.6%).
- Fix outline: a later round knows the recorded advisories and raises none again by location and cause; accepted when one run records no advisory twice.

### focus_window refusal of the completion popup is untested
- Location: test/use_cases_plugins.rb:411 (the plugin-windows requirement on focus_window, openspec/specs/plugin-windows/spec.md)
- Why: the requirement names the completion popup among the floats focus_window refuses, but only another plugin's float is tested, so a regression letting a plugin focus the popup would pass the suite.
- Fix: open the completion popup in the test rig and assert focus_window on its float id answers No window N.

### moved compares the change's files through unquoted, magic-capable pathspecs
- Location: tools/run_state.sh:2762 (moved_change)
- Why: Security Low (confidence 6). It passes `git diff --name-only` output back to git as pathspecs; with the default core.quotePath a name with non-ASCII or control characters comes out quoted, and a name starting with ':' is read as pathspec magic (a file named ':(exclude)*' becomes an exclude), so files of the change drop out of the at..HEAD comparison and `moved` can report the change the same after a main-moved merge altered it, carrying the quality and security passes to a head no review saw.
- Fix: List the files with `git -c core.quotePath=false diff -z --name-only` (read NUL-separated) and run the final `git diff` with `--literal-pathspecs` (or GIT_LITERAL_PATHSPECS=1), or compare `git diff old_base at` with `git diff new_base HEAD` over non-records paths without pathspecs; add tools_test cases with a quoted name and a ':(exclude)*' name.

### A carried review rests only on the moved line the checker copies back
- Location: .claude/workflows/deliver-change.js:935 (carryReviews)
- Why: Security Low (confidence 5). It records quality and security as passed at the merged head from the line the checker agent returns as `moved`, never running `moved` itself, and neither the run state nor the merge gate keeps an independent record, so a misreported or invented 'the change is the same' line gets a security pass recorded at a head no review saw, which the merge gate accepts.
- Fix: Have `tools/run_state.sh moved` write its verdict to the run state (for example `moved.<head> <from> same`) and have `run_state.sh review ... carried` or the merge gate refuse a carried review unless that record names the same head and from commit, or have the queued record command re-run `moved` before writing the carried pass.

### Reviews rerun after a main-moved merge read every commit of the moved main
- Location: .claude/workflows/deliver-change.js:855 (narrowedFrom)
- Why: Correctness. When the reviews run again after a main-moved merge, narrowedFrom returns the pre-merge pass, so the quality and security reviews read `git diff <pass> HEAD`, which holds every commit main gained, and can block the change on main's code or spend the review on code that is not the change's.
- Fix: Skip the narrowing and review the whole branch diff (origin/main...HEAD) when the check that preceded the reviews ran with movedFrom set; add a tools_test or workflow case that asserts the review range after a main-moved merge.

### A check start returns a pass at a commit other than the lane head (sprint-size-six retro)
- Location: the check phase of `.claude/workflows/deliver-change.js` and `check` in `tools/run_state.sh`
- Why: sprint-size-six's first check verdict passed at the base 25604e0ec359, not the head 2d4d9a8ffa16, so the check reran (1 of 2) with no fix round: check 40,322 output tokens in 8 calls, 22.2 percent of 181,434 and more than implement's 38,917; 4 of the last 20 backlog rows spent over 35,000 on the check.
- Fix: a check start reaches its verdict at the head on the first start; accepted when a check can no longer return a pass at another commit and the next 5 runs with no fix round each spend under 12,000 check output tokens.

### Two lanes' exception lines against one uncounted exception (sprint-size-six retro)
- Location: `SPRINT_EXCEPTIONS` in `tools/run_state.sh` (`:408`, the sprint_state branch at `:2005`)
- Why: SPRINT_EXCEPTIONS=1 against 2 exception lines (one per lane) leaves sprint-size-six counted, so review-due prints 4 of 5 against the user's "Sprint 16 finishes as planned"; the planner and the contributor noted it twice with 0 decisions changed, and sprint-16 now closes with tab-close-d and vim-folds-b left over.
- Fix: each lane's exception line leaves its change uncounted, or the conflict stops the run for the user's answer before the merge; accepted when review-due over such a history names both changes beyond the sprint.

### A carried review trusts a moved record written by the branch's own run_state.sh
- Location: tools/run_state.sh:2806 (carried_backed)
- Why: security Low (4): the checker runs the branch's copy of tools/run_state.sh in the lane worktree, so a main-moved merge commit that edited the moved function could write the moved record although files changed after the review, carrying the earlier reviews to unreviewed code; not new, since before this change the moved line alone carried, and branch-controlled scripts already write the run state.
- Fix: in the review command's carried=1 path, run from the main checkout's trusted copy, compute the REVIEWED, CURRENT, and MOVED name diffs again (or call moved_change from that copy) instead of only reading the stored record, or refuse to carry whenever the diff from the reviewed commit to HEAD touches tools/run_state.sh or tools/agent_guard.sh.
### moved carries when the merge keeps the change's side of a file main also edited
- Location: tools/run_state.sh:2783 (moved_change)
- Why: correctness: a file both the change and main edited, merged keeping the change's text (a conflict resolved with checkout --ours), is in REVIEWED and CURRENT but not in MOVED, so HEAD reverts main's landed fix in that file and both reviews carry, the class of revert this change closed for main-only files (reproduced: moved names empty, git diff main HEAD shows -FIX +CHANGE).
- Fix: also read the names of git diff OLD_BASE NEW_BASE, its status checked, and run the reviews again when any of them outside RECORDS_RE is in REVIEWED, with a tools_test case merging a conflict resolved --ours.
### No case refuses a carried review when the moved record names another head
- Location: tools/tools_test.sh:860
- Why: missing test: the head check of the moved record behind a carried review has no case proving a record from an earlier head is refused.
- Fix: run moved to exit 0 at one head, commit, and expect review carried=1 at the new head refused.
### moved writes the run state yet stays a read-profile verb for agents
- Location: tools/agent_guard.sh:612
- Why: security: moved now writes the run state (drop_key, write_key) and its record gates the review record the merge gate reads, yet the checker and reviewers may run it with any commit.
- Fix: in a follow-up (the guard runs from main), restrict moved's COMMIT for agents or move the record's write out of the agent-run command, and say in the guard header that moved writes.

### make test-one does not compile test/use_cases_plugins.rb
- Location: test/use_cases_plugins.rb through carat/use_cases/history/list_undo.rb:27 and carat/use_cases/history/walk_history.rb:168
- Why: `make test-one T=test/use_cases_plugins.rb` still fails at 25604e0ec359 with "void value not ignored as it ought to be" in the generated C, so the plugin host's main test runs only inside the full runner; a contributor iterating on the plugin host waits about three minutes per change instead of one.
- Fix: make `ListUndo#call` and `WalkHistory#finish` return a typed value on every path (or not use the void result), then confirm test-one compiles the file on its own.

### A filetype plugin activated while highlighting is arranged and delivered only on the next key (plugin-lazy-activate quality)
- Location: carat/use_cases/plugins/plugin_syntax.rb:48, carat/use_cases/docs/format_docs.rb:56
- Why: a filetype trigger activates the plugin from HighlightView inside EditorAssembly#render, after ArrangeView and outside any PluginHost flush, so windows, a segment, or events the plugin's activate causes are neither arranged nor delivered until the next key; FormatDocs also activates it from hover docs, a trigger the plugin-host spec ("a buffer of its filetype is highlighted") does not name.
- Fix: activate filetype providers in PluginHost#resized, before arrange and then flush, for the visible buffers' syntaxes, and keep the provider a pure lookup.

### The git-status spec still says the segment shows on activation before any buffer opens (plugin-lazy-activate quality)
- Location: openspec/specs/git-status/spec.md:34, openspec/specs/plugin-host/spec.md:387
- Why: the scenario "The segment shows on activation" stays in the main spec though git_signs now activates only after the first frame and test/editor_git_signs.rb replaced its test with "Git runs only after the first frame"; the binding-conflict requirement still says "a plugin activated before it" while conflicts are now decided at prepare_all.
- Fix: add a git-status delta that removes or modifies the scenario, and reword the conflict requirement to "prepared".

### The hello plugin's opened count is always 1 at activate and misses earlier buffers (plugin-lazy-activate quality)
- Location: carat/plugins/hello/plugin.rb:49
- Why: read_buffer(0) resolves the current buffer, which always exists, so the ternary is a dead branch always giving 1, and buffers opened before the first greeting other than the current one are not counted (":e b.txt" then hh from a.txt reads "1 buffer opened").
- Fix: write "@opened = 1" with a comment saying it counts the current buffer, or count the listed buffers at activate if a host request offers them.
### test/use_cases_plugins.rb did not compile alone at 95bf2e04c258
- Location: `test/use_cases_plugins.rb`, `make test-one T=test/use_cases_plugins.rb` (git-signs-transport retro note 7).
- Why: the plugin host's own test file could not be run alone on the base, so a plugin host change is checked only through the whole runner; the contributor reported it and nothing recorded it.
- Fix: make the file compile alone in `make test-one`; accepted when `make test-one T=test/use_cases_plugins.rb` passes on main.

### vim-line-commands-b's quality advisories reached main unrecorded
- Location: `docs/compatibility.md:332` (the Substitute section's opening sentence pasted inside itself), `carat/domain/ex_range.rb:151` (`.5`, `$ 1`, `. 5` answer E16 where Neovim reads an implicit offset, untested), `carat/domain/ex_range.rb:101` (resolve re-reads the error text against UNREAD), `docs/codebase-map.md:128` (Messages entry lacks E477 and REPORT; RegisterCount lacks parse_count).
- Why: the package step fixed 2, the push gate refused, it reverted them (653eefe) and appended 1 of 4 to docs/findings (vim-line-commands-b retro note 5).
- Fix: rewrite the sentence as one; treat an address base followed by digits or blanks as unread, with a `domain_ex_range` row for `.5d`; call `unread?` directly; name the 3 symbols in the map. Skip any part already folded from the vim-line-commands-b findings file.

### The package step reverts advisory fixes and drops their findings (evidence for package-advisory-edit)
- Location: the package step of `.claude/workflows/deliver-change.js`; vim-line-commands-b retro note 5.
- Why: package 10,126/23 against the feature median of 15 calls; quality 4 advisories, 1 appended; third run after motions-search-tidy 16,259/22 and record-squash-commit 38,843/17.
- Fix: fold into backlog pool item `package-advisory-edit`; accepted when over 3 runs with advisories each one not fixed at the reviewed commit is in docs/findings and no revert commit is on the branch.

### The check-pass budget line converts output at a fixed 6 per token
- Location: the check-pass budget line of `.claude/workflows/deliver-change.js`; vim-line-commands-b retro note 6.
- Why: it noted 197,007 output as 98.5 percent of medium while the run closed at 893,872 total of 1,200,000; the last 10 feature rows' total to output ratio runs 2.42 to 7.94, so the line notes overruns the totals never show and changes no decision.
- Fix: drop the line, or make its over agree with the final total-token budget line on the last 10 medium feature rows.

### The merger reports the branch head as the merged commit
- Location: the merger's result and the merge record of `tools/run_state.sh`; vim-line-commands-b note 9.
- Why: it reported f230c3210a53, the branch head, not the squash commit 25604e0ec359, which the fallback recorded instead; a record that trusted the report would point at a commit absent from main.
- Fix: the merger reports the squash commit read from main's log; accepted when a tools-test case shows a branch head refused as the merged commit.

### The planner weighs quality-advisory notes the package step handled
- Location: the planner's input from `sh tools/run_state.sh show`; git-signs-transport retro note 6.
- Why: git-signs-transport 5 advisories (1 kept as a finding, 0 changed code) and secret-patterns 4, all 4 given a not-placed decision; quality first pass 83/151.
- Fix: leave handled `quality-*` notes out of what the planner reads; accepted when the next planner's decisions carry no line about them while a kept advisory still reaches docs/findings.

### A base defect a contributor names is not recorded
- Location: the contributor's return and docs/findings/CHANGE.md; git-signs-transport retro note 7.
- Why: 1 base defect reported (the test file above), 0 recorded.
- Fix: the contributor appends a named pre-existing defect to its findings file; accepted when the next such defect appears there.

### The configuration-file pattern of the secret check leaves out common formats
- Location: tools/rules.sh:37 (CONFIG_PATH_RE)
- Why: security Low (confidence 4): .json, .ini, .conf, .cfg, .properties, and .env.* variants are not matched, so an unquoted credential such as password=hunter2hunter2 committed in one of them passes the content gate and the pull request scan.
- Fix: add those extensions and a (^|/)\.env(\.[^/]*)?$ form to CONFIG_PATH_RE, each with a refusing expect case in tools/tools_test.sh.

### The bare assignment pattern refuses a shell test comparison
- Location: tools/rules.sh:38 (BARE_ASSIGN_RE, separator form)
- Why: correctness: the optional quote lets the closing quote of an expansion stand before =, so [ "$token" = expected_value ] in a shell file is refused, a false positive the design's risks do not name.
- Fix: require the name not to follow a dollar sign or brace, for example (^|[^$A-Za-z0-9_{])[A-Za-z0-9_-]* before the secret word, with a pass case in tools/tools_test.sh.

### A placeholder comment in the generator now matches the bare assignment pattern
- Location: tools/new.sh:133
- Why: correctness: the existing comment '# fill TOKEN=VALUE...:' matches BARE_ASSIGN_RE, so the next change that edits that line fails the content gate on a placeholder; this change edits only the gate rules, so the line was left as is.
- Fix: reword it to 'fill NAME=VALUE...', or skip shell comment lines in the configuration check.

### No case pins the eight-character boundary of the bare assignment check
- Location: tools/tools_test.sh:2845
- Why: missing test: a workflow line such as 'id-token: write' in a .yml file, the most edited configuration kind, passing is untested, so a later edit of the value length could refuse it unnoticed.
- Fix: add a pass case for a seven-character value in config/app.yml beside the refused eight-character one.

# Findings of sprint-15-records

## The fold keeps a findings file's title as a second level-one heading

- Location: docs/backlog.md:7555, tools/run_state.sh (folded_backlog)
- Why: groom folds the sprint-14-records findings file with its title, so the backlog gains a second level-one heading ('# Findings of sprint-14-records') that is no entry and nests every later folded entry under '## Two defects are recorded twice in the backlog'.
- Fix: drop the title line, and let folded_backlog in tools/run_state.sh skip a findings file's leading '# ' line.

## The fold adds headings with no blank line before them

- Location: docs/backlog.md:7488 (also 7492, 7496, 7500, 7540, 7613, 7622), tools/run_state.sh (folded_backlog)
- Why: the fold adds seven headings with no blank line before them (main had 10, the branch 17), the groom defect the folded sprint-14-records finding names, which make docs-lint does not catch.
- Fix: insert the blank lines, and let folded_backlog separate every folded heading by one blank line.

### The merger reports the branch head instead of the squash commit (vim-line-commands-b retro)
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js`
- Why: vim-line-commands-b's merger reported f230c3210a53 as the merged commit while main's squash commit was 25604e0ec359 (its merge-disagreement note 9), after record-squash-commit merged; the workflow's check recorded the right commit, so only the cross-check stands between a wrong head and the history's merged column.
- Fix: the merger reads the merged commit from the pull request's merge commit field (or main's first-parent commit naming the pull request number); accepted when a tools-test case or the next 3 merges record no merge-disagreement note.

### make test-one does not compile test/use_cases_plugins.rb at 95bf2e04c258 (git-signs-transport retro)
- Location: `test/use_cases_plugins.rb`, `make test-one`
- Why: git-signs-transport's contributor found `make test-one T=test/use_cases_plugins.rb` failing to compile at main 95bf2e04c258 while the full runner passes, so the one-file path a contributor uses to iterate is broken for the plugin host's largest test (retro note 7).
- Fix: find what the file relies on that only the whole runner supplies and make it self-contained; accepted when `make test-one T=test/use_cases_plugins.rb` passes at main.

### ExRange resolve answers E16 for an implicit offset Neovim reads (vim-line-commands-b quality)
- Location: carat/domain/ex_range.rb:151
- Why: resolve now answers E16 for a range piece Neovim reads as an implicit offset (`.5`, `$ 1`, `. 5`), where it answered Not implemented before, since unread? counts only + - ; / ? ' and bare digit runs; a behavior change without its test.
- Fix: treat an address base (. or $) followed by digits or blanks as unread too, and add a domain_ex_range row for `.5d`.
### The planner runs on a first queue item already placed and estimated (secret-patterns retrospective)
- Location: `tools/run_state.sh` plan-needed
- Why: secret-patterns' planner changed no decision (its queue only removed the delivered item and restated the Decisions) yet cost 11,077 of 127,363 output tokens (8.7 percent) and 12 of 112 tool calls (10.7 percent).
- Fix: plan-needed answers 0 for a delivery of the first queue item with its estimate set and no pending retro or overrun note, while plan-apply still removes the delivered item; accepted when such a run records planned=0 and no plan phase.

### A current area pack is scouted again for a missing location (secret-patterns retrospective)
- Location: `.claude/workflows/deliver-change.js` scout reuse
- Why: the build-and-ci pack, current at 8b54500, was discarded because its Locations line lacked `tools/scan_text.sh`; the scout then spent 42,854/20, 33.6 percent of output tokens and 1.34 times implement's 31,927, against 8.7 to 19.4 percent in the last medium backlog rows.
- Fix: reuse a pack current at the run's commit and add only the named locations; accepted when such a delivery spends under 15 percent of output tokens on the scout phase.

### The medium merge call cap overruns on CI waiting alone (secret-patterns retrospective)
- Location: `.claude/workflows/deliver-change.js` CALL_CAPS
- Why: a green first-pass CI with rework 0 made 16 merge calls over the medium cap of 14 with ci_wait_calls 6 and CI 8.4 min (record-squash-commit 14, markdown-reading-d 13 at the same wait count), and the overrun note then asks the planner to re-estimate a change whose size did not cause it.
- Fix: size the merge cap by CI waits, not by the estimate; accepted when the next three medium runs with first-pass green CI of 7 to 12 minutes record merge calls at or under the cap and no merge overrun note.
### Scrolls step into a closed fold's hidden rows (sprint-16 sweep quality)

- Location: carat/use_cases/windows/scroll_window.rb:64
- Why: line, page, and half-page scrolls move Window#top by buffer rows and never consult the window's Folds, while ArrangeView counts a closed fold as one row, so <C-e>, <C-f>, and <C-d> over a closed fold step into its hidden rows; no test in editor_folds.rb or editor_scroll.rb covers it.
- Fix outline: step the top as j and k do over folds, verified against Neovim, with fold rows in the scroll table test. Pool item `vim-folds-c`.

### ci_scope.sh loops over unquoted paths and asks gh twice (sprint-16 sweep quality)

- Location: tools/ci_scope.sh:99 and :123 (for path in $changed, $since), :80 (two gh calls for repos/REPO/commits/SHA/pulls).
- Why: the unquoted loop splits on spaces and expands globs in changed paths, failing safe but in the shape the tools avoid; the push path pays two API calls for one answer.
- Fix outline: read the lines with while IFS= read -r, or set -f with a newline IFS as moved_change does; one gh call printing both fields. Pool item `ci-trust-gaps-b`.

### Replace mode shows no mode message (sprint-16 sweep quality)

- Location: carat/adapters/frame_presenter.rb:1260 (paint_message).
- Why: Neovim's showmode prints -- REPLACE -- in replace mode; carat prints nothing, a compatibility gap.
- Fix outline: add the REPLACE branch and a row in test/adapters_frame_presenter.rb and docs/compatibility.md. Pool item `frame-presenter-tidy`.

### FramePresenter's public surface is wider than its callers (sprint-16 sweep quality)

- Location: carat/adapters/frame_presenter.rb:320 (display_col, display_width), :1252 (self.diagnostic_group).
- Why: public wrappers used only by place_cursor, paint_diagnostic, and one test widen the class's surface.
- Fix outline: make them private, the test calling DisplayWidth.column directly. Pool item `frame-presenter-tidy`.

### The map says check_queue allows 0 to 2 backlog sprint items (sprint-16 sweep quality)

- Location: docs/codebase-map.md:55, against tools/docs_lint.sh:161.
- Why: since sprint-size-six the lint allows 3 in each lane, so the map misleads.
- Fix outline: say 0 to 3 in each lane.

### Keymap and ControlText rely on another file's require (sprint-16 sweep quality)

- Location: carat/domain/keymap.rb:1 (KeyNotation, Mode), carat/domain/control_text.rb:1 (Utf8.size_at).
- Why: both work only because of the order in carat.rb, breaking the layer rule's explicit requires.
- Fix outline: add require_relative of key_notation and mode to keymap.rb and of utf8 to control_text.rb.

### Motions.code_class hides a require cycle, bare class numbers, and cls names (sprint-16 sweep quality)

- Location: carat/domain/walker.rb:63, carat/domain/text_objects.rb:86, carat/domain/runs.rb:18, carat/use_cases/search/find_match.rb:136 and :141.
- Why: Walker and TextObjects call Motions.code_class without requiring motions, which requires walker; find_match compares the class to a bare 2 and repeats class 0's blank test; locals and a parameter are named cls, which CLAUDE.md names as the bad example.
- Fix outline: move code_class into a small CharClass module that motions, text_objects, walker, and find_match require, with BLANK, PUNCTUATION, and KEYWORD constants; rename cls to char_class.

### The tabstop fallback is copied beside Options#tab_width (sprint-16 sweep quality)

- Location: carat/use_cases/dispatcher.rb:112, repeat_last.rb:104, arrange_view.rb:47, insert_tab.rb:25, leave_insert.rb:69, carat/domain/operators.rb:172, :251, :272, carat/domain/display_width.rb:57; Options#tab_width at options.rb:131.
- Why: "tabstop > 0 ? tabstop : 8" is spelled in 9 places while the visual use cases already call tab_width, so the fallback can drift.
- Fix outline: call options.tab_width, or pass it in, at each site.

### Keymap#name_group repeats bind_text's parse (sprint-16 sweep quality)

- Location: carat/domain/keymap.rb:318
- Why: the notation parse, empty-key check, and MAX_KEYS check are copied from bind_text.
- Fix outline: one private helper returning the parsed codes or the problem, used by both.

### The signature trigger compares bare key codes (sprint-16 sweep quality)

- Location: carat/use_cases/handle_key.rb:384 (code == 40 || code == 44).
- Why: magic numbers for ( and , hide what triggers parameter info.
- Fix outline: name them as constants in Key or as private constants.

### Three private clamps repeat EditorState#clamp_col (sprint-16 sweep quality)

- Location: carat/use_cases/operate.rb:233, carat/use_cases/repeat_last.rb:116 (private clamp), carat/domain/editor_state.rb:123 (end_visual); clamp_col at editor_state.rb:97.
- Why: the clamp is copied line for line in 3 places beside the one EditorState method (LineCommandHandler#place_cursor goes in `vim-line-commands-c`).
- Fix outline: call clamp_col at each site and delete the two private clamp methods.

### carat-gen-config writes a spin run header (sprint-16 sweep quality)

- Location: bin/carat-gen-config.rb:32, the header of carat/domain/default_config.rb.
- Why: it says to run spin run carat-gen-config where CLAUDE.md allows only make gen-config.
- Fix outline: write make gen-config in the header and regenerate.

### .PHONY leaves out metrics and metrics-compare (sprint-16 sweep quality)

- Location: Makefile:510 (targets at :389, :393).
- Why: a file named metrics would quietly stop make metrics.
- Fix outline: add both targets to .PHONY.

### Bounded count parsing and digits? are copied in six places (sprint-16 sweep quality)

- Location: carat/domain/register_count.rb:38, substitute_args.rb:80 (MAX_COUNT :27), ex_range.rb:134 (MAX_NUMBER); digits? in buffer_command_handler.rb:102, tab_command_handler.rb:102, history_command_handler.rb:67.
- Why: 3 bounded decimal loops with their own limits and 3 all-digits predicates, one a regex, drift apart.
- Fix outline: one domain bounded number reader and digits? predicate called by the three parsers and three handlers.

### Substitute's count range repeats ExRange#counted (sprint-16 sweep quality)

- Location: carat/use_cases/search/substitute_lines.rb:65, against ExRange#counted (ex_range.rb:112).
- Why: the same Vim count rule is computed twice, the line commands using counted.
- Fix outline: pass or build an ExRange and call counted.

### Change selection repeats Operate's linewise change (sprint-16 sweep quality)

- Location: carat/use_cases/visual/change_selection.rb:43, carat/use_cases/operate.rb:189.
- Why: the autoindent, set_lines, cursor, and insert-mode steps of a linewise change are copied.
- Fix outline: one domain function returning the indent column, called by both.

### WalkHistory keeps per-call counters as instance state (sprint-16 sweep quality)

- Location: carat/use_cases/history/walk_history.rb:20 (@gone, @back, @empty_before).
- Why: a use case built once and shared holds per-call state reset in start, which a re-entrant call would mix.
- Fix outline: return the counts from step into locals of call, or a small Struct record, and drop the three variables.

### Quit walks the layout for a question BufferList answers (sprint-16 sweep quality)

- Location: carat/use_cases/files/quit.rb:87 (beside_side_windows?), BufferList#lone_file_window? at buffer_list.rb:475.
- Why: a private walk duplicates the predicate DeleteBuffer uses.
- Fix outline: use !state.buffer.scratch? && @buffers.lone_file_window?(state.tab) and delete the walk.

### SplitWindow takes five positional values (sprint-16 sweep quality)

- Location: carat/use_cases/windows/split_window.rb:31; callers window_handler.rb:44, pin_hover.rb:52, window_requests.rb:189.
- Why: two bare booleans among five values break area 11's rule that variants with a count go through a Data request, as FocusWindow, ScrollWindow, and SwitchTab do.
- Fix outline: a SplitRequest Data value (vertical, size, path, fresh) passed at the call sites.

### ExtendVisual moves the cursor to read a text object (sprint-16 sweep quality)

- Location: carat/use_cases/visual/extend_visual.rb:55 (object_at), TextObjects.call at text_objects.rb:47.
- Why: it saves, moves, and restores the cursor around TextObjects, so a raise inside leaves the cursor moved.
- Fix outline: give TextObjects a position parameter and drop the save and restore.

### git_signs runs git on every focus outside a repository root (sprint-16 sweep quality)

- Location: carat/plugins/git_signs/plugin.rb:128
- Why: the no-git focus shortcut needs a non-empty HEAD key, so from a repository subdirectory every window_focus runs symbolic-ref, rev-list, and cat-file on the editor thread, each up to 2 s, and outside a repository a symbolic-ref per focus; untested.
- Fix outline: remember an empty key and skip a focus whose text is held, or settle the git dir once at activate, with a test.

### The No Name label is spelled in five files (sprint-16 sweep quality)

- Location: carat/adapters/status_bar.rb:47, tab_bar.rb:22, winbar.rb:18, carat/use_cases/buffers/list_buffers.rb:22, carat/domain/messages.rb:22.
- Why: architecture section 5 puts a constant several files need in the domain.
- Fix outline: one Domain::Messages::NO_NAME read by all five.

### The explorer's Tree takes positional arguments (sprint-16 sweep quality)

- Location: carat/plugins/explorer/tree.rb:23, exemption at test/lint.rb:1195.
- Why: the only positional constructor under carat/, against CLAUDE.md's keyword rule; @nodes is Array[untyped] though it holds Node.
- Fix outline: Tree.new(root:, show_hidden:, ignore:) with an Array[Node] pin, and drop the exemption or state it in CLAUDE.md.

### The capture deadline is spelled in the message and git_signs (sprint-16 sweep quality)

- Location: carat/use_cases/plugins/file_requests.rb:144, carat/drivers/process_runner.rb:27 (CAPTURE_SECONDS), git_signs TIMEOUT.
- Why: changing the deadline silently desyncs the "ran past 2 seconds" text.
- Fix outline: one domain constant the driver uses and the message is built from.

### path_of validates UTF-8 by hand (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:801 (path_of).
- Why: lead byte sizes, continuation, overlong, and surrogate checks are written out after percent decoding.
- Fix outline: append decoded bytes to a binary string and accept it only when valid_encoding? as UTF-8. Pool item `lsp-tidy`.

### git_signs keeps four parallel arrays (sprint-16 sweep quality)

- Location: carat/plugins/git_signs/plugin.rb:65 (@buffers, @keys, @paths, @texts).
- Why: keep, drop, held?, and held_text must keep four arrays in step.
- Fix outline: one small Struct record per held buffer in one list.

### ProcessRunner#write answers true after its writer failed (sprint-16 sweep quality)

- Location: carat/drivers/process_runner.rb:71 and :243 (drain); contract at carat/ports/process_port.rb:16.
- Why: once write_bytes fails the handle stays open, so write keeps answering true onto an outbox nobody pops; JsonRpcLanguageGateway#deliver never treats the server as crashed and the queue grows without bound while the child lives.
- Fix outline: drain marks its handle broken on a failed write and write and open? answer false, with a test in test/drivers_process_runner.rb of a child that closes its stdin. Pool item `lsp-tidy`.

### The language gateway repeats send, cancel, receive, and start bodies (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:865 and :718 (send_hover, send_definition), :494 to :505 (receive), :621, :746, :892, :972, :1025 (cancels), :201 and :235 (start, restart).
- Why: one body is copied per request kind and the start messages twice.
- Fix outline: one send_at_cursor, one cancel over the requests' shared readers, a request table for receive, a private launch_shown. Pool item `lsp-tidy`.

### HoverRequest and DefinitionRequest repeat their members (sprint-16 sweep quality)

- Location: carat/domain/hover_request.rb:3, carat/domain/definition_request.rb:3.
- Why: the anchor, want, sent, sent_id, language, deadline, languages members and at?, waiting?, offers? predicates are copied.
- Fix outline: a domain concern for the cursor-anchored ask, or one record both hold. Pool item `lsp-tidy`.

### UTF-16 conversions live in three places (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:1116 and :1162, carat/use_cases/definitions/visit_target.rb:204.
- Why: each walks lead bytes by hand.
- Fix outline: Domain::Utf8 utf16_length, utf16_offset, column_of_units called from both. Pool item `lsp-tidy`.

### Untrusted text is cut at a byte limit without a character boundary (sprint-16 sweep quality)

- Location: carat/adapters/json_rpc_language_gateway.rb:926, :943, :1141; ProcessRunner#cut_point (process_runner.rb:155) and MarkdownText.gather carry their own back-off.
- Why: an answer at the cap shows a trailing U+FFFD, and three cuts differ from the two that back off.
- Fix outline: one Utf8.cut(text, limit) backing off continuation bytes, used by all five. Pool item `lsp-tidy`.

### ShowHover repeats the definition float's placement (sprint-16 sweep quality)

- Location: carat/use_cases/docs/show_hover.rb:75, OpenDefinitionFloat#call.
- Why: the below, above, height clamp, and widest-row placement is copied almost line for line.
- Fix outline: open through OpenDefinitionFloat or a shared placement helper with a row cap. Pool item `lsp-tidy`.

### The map omits docs.toggle_reading (sprint-16 sweep quality)

- Location: docs/codebase-map.md:649, carat/use_cases/actions/docs_handler.rb.
- Why: the entry names docs.hover and docs.pin only.
- Fix outline: list docs.toggle_reading.

### ProcessRunner repeats its spawn and signal bodies (sprint-16 sweep quality)

- Location: carat/drivers/process_runner.rb:124 and :189 (start_quiet, start), :166 and :175 (kill, terminate).
- Why: the same Process.spawn with different streams, and two signal bodies differing in the signal and guard.
- Fix outline: one spawn helper taking the environment and streams, one signal(name, pid) with the guard. Pool item `lsp-tidy`.

### Json repeats the plain byte predicate (sprint-16 sweep quality)

- Location: carat/domain/json.rb:469 (Writer#plain?, Parser#ascii_text?, write_string inline).
- Why: one predicate in three spellings.
- Fix outline: one module-level Json.plain_byte? used by all.

### The planner starts on a placed item (merge-main-path retro 5)

- Location: .claude/workflows/deliver-change.js, plan-needed in tools/run_state.sh.
- Why: merge-main-path's brief and the user's answers fixed its tier, placement, sprint count, and size, yet its plan start spent 63,196 output tokens, 28.1 percent of the run's output; evidence for "### The planner runs on a placed first item (evidence for plan-skip-placed)".
- Fix outline: skip or bound the planner when the brief fixes every decision; accepted when the next such run's plan phase is at or under about 19,000 output tokens or absent with the same decisions.

### Fix-in-place round test checks only a hand-built state
- Location: tools/tools_test.sh:3691
- Why: the case named for the fix-in-place round only checks passedAt on a hand-built state and inPlaceCheck, so the alone branch of rounds() (contributor fix start, continue, check and both reviews again) and the reviews() wiring of reviewFindings (security only in_change non-blocking, quality advisories) are unexercised; raised twice by the quality review, merged here.
- Fix: extract the end-of-round decision into a helper returning the next step and test it, or drop the claim from the case name.

### Security reviewer prompt lacks the fixed_in_place instruction
- Location: .claude/agents/security-reviewer.md:1
- Why: the SECURITY schema gains fixed_in_place and quality-reviewer.md describes it, but security-reviewer.md says nothing, so the security side relies on the prompt alone.
- Fix: add the same one-sentence fixed_in_place instruction to security-reviewer.md.

### Periodic sweep tokens still count in the records budget
- Location: .claude/workflows/periodic-review.js:142
- Why: the sweep runs inside sprint-planning but its record start is labelled record, which add_tokens keys record, not sprint, so its tokens still count in the records change's budget; raised twice by the quality review, merged here.
- Fix: label it periodic: record or match the sweep's record in add_tokens.

### Budget line names the sprint key too narrowly
- Location: tools/run_state.sh:1795
- Why: the budget line says sprint-planning's reviews set apart though the sprint key also holds the due, notes, record, records-merged, and planner starts.
- Fix: say sprint-planning's own starts.

### Proposal names README pipeline step 8 as changed
- Location: openspec/changes/archive/2026-11-18-pipeline-diet-b/proposal.md:13 and :195
- Why: the proposal names README pipeline step 8 as changed but the diff leaves step 8 as it was; raised twice by the quality review, merged here.
- Fix: drop step 8 from the list or say why it stays.

### Two blank lines left where figuresFirst was removed
- Location: .claude/workflows/deliver-change.js:1007
- Why: removing figuresFirst left two blank lines between mayFix and qualityTask (also reported at :1009, merged here).
- Fix: keep one blank line.

### Fixed-in-place state lives only in memory across a resume
- Location: .claude/workflows/deliver-change.js:1169
- Why: fixedInPlace, awaiting, and offered live only in memory while seed rebuilds every quality-advisory note on a resume before the push, so a finding confirmed fixed in place in an earlier start (or offered just before a stop) is handed to docs/findings again.
- Fix: note each confirmed fix as fixed-in-place in the run state and have seed fill fixedInPlace from those notes.

### Run-check prompt may run moved after a failed check
- Location: .claude/workflows/deliver-change.js:924
- Why: checkRunTask lists the moved line as step 3, "Then", after the pass-only step 2, while the old prompt said once the check passed, so a run start may run moved (which writes the moved key) after a failed check.
- Fix: begin step 3 with "Only after that pass" as step 2 does.

### In-place-only rounds inflate the rework metric
- Location: .claude/workflows/deliver-change.js:1268
- Why: an in-place-only round goes through contributor('fix'), which increments rework, so metric.rework, the first-pass picture the planner reads, and the 'still blocked after N fix rounds' stop mix advisory clean-ups with blocking fixes.
- Fix: count in-place rounds in their own metric while still bounding them by ROUNDS.
### The Sprint 17 feature decision still places tab-close-d at place 1
- Location: `docs/queue-feature.md:30`.
- Why: the merge resolution of tab-close-d removed it from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list holds vim-folds-b at 1 and vim-line-commands-c at 2 (tab-close-d late finding at 5982df4f5353, quality advisory).
- Fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2.

### The tab-close-d findings entries drop the file's backticks and periods
- Location: the tab-close-d findings file, line 11 (folded into this file).
- Why: the three late entries drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use, two formats in one file (tab-close-d late finding at 5982df4f5353, quality advisory).
- Fix: backtick the locations and end each Location, Why, and Fix line with a period as the earlier entries do.

### plan-needed skips the planner for a security note recorded after a later sprint plan (pipeline-diet security Low (3))
- Location: tools/run_state.sh:2613 (plan_needed)
- Why: plan-needed now skips the planner for a pending change's `security` notes (PLAN_NOTES includes security) whenever any sprint-N-records change merged after it; a security note recorded on that change after the sprint planner ran would never be placed by a planner, so an advisory security finding could sit unqueued. The blocking periodic-security check above the loop is unchanged, so no blocking finding is affected.
- Fix: In plan_needed, apply placed_by_sprint only to retro and overrun notes and keep `security` (and `quality`) notes always triggering the planner, or compare each note's recording time with the sprint-records merge time instead of the change's merge commit.

### The contributor's package step drops its no-backlog clause (pipeline-diet quality)
- Location: .claude/agents/contributor.md:47
- Why: out of scope: the package step's 'never opening the backlog' is dropped, the contributor file's only statement of the no-backlog rule, which the brief does not ask to change.
- Fix: restore the clause.

### Unrelated wording trims in the contributor file (pipeline-diet quality)
- Location: .claude/agents/contributor.md:34, :70
- Why: out of scope: unrelated wording trims ('Do the plan notes beside the code' to 'too' at :34, 'Return the result the workflow's schema asks' to 'Return the workflow's schema' at :70) change no behavior the brief names.
- Fix: revert both lines.

### The proposal and the contributor disagree on when reviewed-edits runs (pipeline-diet quality)
- Location: openspec/changes/archive/2026-11-18-pipeline-diet/proposal.md:13 (was openspec/changes/pipeline-diet/proposal.md:13), .claude/agents/contributor.md:49
- Why: docs drift: the proposal says the package step runs reviewed-edits before each commit, while .claude/agents/contributor.md:49 runs it once in step 4 before the push, after the records commits.
- Fix: state one rule in both (before each commit, or once before the push with a restoring commit).

### scoutTargets matches a location as a substring of the brief (pipeline-diet quality)
- Location: .claude/workflows/deliver-change.js:195 (scoutTargets)
- Why: loose match: scoutTargets names an area when String(brief).includes(pathOf(l)), so a directory or prefix location (tools/, carat/domain) counts as named whenever the brief names any file under it, skipping its scout.
- Fix: match the location's path as a whole token of the brief (delimited by backticks, spaces, or punctuation).

### reviewed-edits fails open when git diff fails (pipeline-diet quality)
- Location: tools/run_state.sh:1692 (reviewed_edits)
- Why: fail-open: reviewed_edits discards git's errors and chains git diff && git ls-files, so a failing git diff yields an empty list and 'none since the security review' with exit 0.
- Fix: run git diff outside the 2>/dev/null pipeline and return 1 when it fails.

### docs-lint's own queue item skip needs a symbolic branch (pipeline-diet quality)
- Location: tools/docs_lint.sh:134 (own_change)
- Why: own_change reads only a symbolic branch, so a detached checkout (CI's pull_request merge ref) never skips the own queue item; harmless today since plan-apply removes the item before the push, but the comment claims only the check clone.
- Fix: say so in the comment, or fall back to GITHUB_HEAD_REF.

## sprint-16 row names the wrong six changes

- Location: docs/sprints.tsv:19, tools/run_state.sh:2295 (sprint_row)
- Why: the sprint-16 row names moved-review-carry (merged after the plan, the next sprint's security-first item) in place of plugin-lazy-activate, whose history row is only on bugfix/tab-close-d, so its names, wall time, tokens, and first-pass figures describe the wrong six changes; sprint_row reads only history rows while sprint_names counts the merged change without one.
- Fix: make sprint_row (or groom) refuse or wait when a merged sprint change has no history row, then rewrite the sprint-16 row in a records change once plugin-lazy-activate's row is on main.

## Fold adds a level-one heading per findings file

- Location: docs/backlog.md:7740, tools/run_state.sh:2143 (folded_backlog)
- Why: the fold adds a third level-one heading ('# Findings of sprint-15-records'), the very defect the folded entry under it records, nesting every later entry under it.
- Fix: drop the title line here and let folded_backlog skip a findings file's leading '# ' line.

## Folded headings lack a blank line before them

- Location: docs/backlog.md:7643, 7647, 7651, tools/run_state.sh (folded_backlog)
- Why: folded headings follow a text line with no blank line before them (the known fold defect, again).
- Fix: insert the blank lines and have folded_backlog separate every folded heading by one blank line.

## Committed queue still lists a merged security-first item

- Location: docs/queue-backlog.md:22
- Why: the committed queue still lists moved-review-carry under Security first though it merged as #199, relying on the package step's plan-apply to drop it.
- Fix: confirm plan-apply removes the section before the merge, or have groom drop queue items already merged.

## Records proposal names a file the diff does not touch

- Location: openspec/changes/archive/2026-11-18-sprint-16-records/proposal.md:25, tasks.md:7
- Why: Impact (and task 1.2) names docs/metrics-feature.tsv, which the diff does not touch.
- Fix: drop it from Impact and say in task 1.2 that only docs/metrics-backlog.tsv gains a row.

## New Pool drops items with no Decisions line

- Location: docs/queue-backlog.md:30, docs/backlog.md:137, 1017, 1168
- Why: the new Pool drops plugin-host-tidy batch 2 part b (PluginUi, bars comments, in_window, move_float), plugin-host-move, package-advisory-edit, lint-own-queue-paths, plan-skip-placed, scout-pack-reuse, and merge-cap-ci-wait with no Decisions line, their headings left in docs/backlog.md.
- Fix: the next planner run states each drop or puts the items back in the Pool.

### The squash trailer repeats the gates' trailer
- Location: tools/agent_guard.sh:964 (SQUASH_TRAILER), tools/gates.sh:78 (TRAILER)
- Why: quality advisory, duplication: two copies of the trailer line that must stay equal, or the merge hook and the gates disagree on the squash message.
- Fix: a tools_test.sh case comparing the two lines, as "the guard's risky keys are the gates'" does for RISKY_CONFIG; this change's head already carries it as "guard: the squash trailer is the gates' trailer", so the grooming may close this entry once it confirms the case on main.

### Two JSON string decoders in the guard
- Location: tools/agent_guard.sh:970 (json_text), tools/agent_guard.sh:153 (field)
- Why: quality advisory, duplication: json_text repeats field's key match, escape loop, and hex decoding, two JSON string decoders to keep in step.
- Fix: have field decode through json_text and apply its folding of newlines and non-ASCII after.

### Two lookups of the archived pr.md
- Location: tools/agent_guard.sh:1027 (merge hook lookup), tools/open_pr.sh:167
- Why: quality advisory, one clear way: the hook finds the archived pr.md by a non-recursive listing and a cat-file check while open_pr.sh still lists the whole archive with ls-tree -r, two lookups of the same file that grow apart.
- Fix: give open_pr.sh the same non-recursive listing of the archive's entries, or share one lookup.

### A scout runs for an area the change barely edits (plugin-lazy-activate retro 12)
- Location: `.claude/workflows/deliver-change.js`, the scout plan from the areas start.
- Why: plugin-lazy-activate spent 57,113 output tokens and 40 calls on scouts (16.6 percent of 343,926 output, 16.5 percent of 242 calls) for 3 packs, one (build-and-ci) for 8 of 813 changed lines; scout shares tab-close-b 25 percent, tab-close 21 percent, secret-patterns 33.6 percent.
- Fix: skip or fold the scout of an area whose planned edit is a few lines; accepted when the scout share of output over the next 10 feature runs has a median at or under 12 percent with first.check and first.quality rates not lower.

### The finder's tab pick repeats the open_file call of its default branch
- Location: carat/plugins/finder/plugin.rb:332 (open_path, the when :tab branch)
- Why: the :tab branch's target == 0 arm repeats the else branch's host.open_file(target, path) inside a ternary, so the default open lives in two places and can drift (two quality advisories, duplication and simplicity, merged here)
- Fix: before the case, map how to the default when it is :tab and target is 0 (or guard so :tab reaches open_as_tab only when target != 0), leaving when :tab to call open_as_tab alone and the zero case to fall through to the one open_file call

### The host's open_as_tab fallback with no file window is reached by no shipped caller
- Location: carat/use_cases/plugins/window_requests.rb:214, docs/plugins.md:79
- Why: every shipped plugin now checks editing_window before open_as_tab, so the host's no-file-window fallback to a tab page is dead for shipped callers, and docs/plugins.md asks each plugin to repeat the check
- Fix: at the next plugin API minor step make open_as_tab with no file window open in the current window as open_file does, and drop the finder's own check

### The finder's <C-t> row leaves out the lone-tree case
- Location: docs/compatibility.md:528
- Why: the explorer's row (line 508) and the file-finder spec state that with no file window the tab open opens as <CR> does, but the finder's <C-t> row omits it, so the table under-describes the behavior
- Fix: append "and with no file window as <CR> opens" to the row

## Findings of tab-close-d after its package step

- quality advisory docs/queue-feature.md:30 docs currency: the merge resolution removed tab-close-d from the Sprint 17 list, but the decision still places tab-close-d and vim-folds-b at places 1 and 2 and vim-line-commands-c third, while the list now has vim-folds-b at 1 and vim-line-commands-c at 2; fix: say tab-close-d merged from place 1, vim-folds-b and vim-line-commands-c now at places 1 and 2
- quality advisory docs/findings/tab-close-d.md:11 one clear way: the three new entries drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use; fix: backtick the locations and end each Location, Why, and Fix line with a period as above

### A lane's queue removal conflicts with a sprint-records rewrite of the queue (tab-close-d retro)
- Location: `tools/run_state.sh` merge-main and plan-apply, `docs/queue-feature.md`.
- Why: after merge-main the delivery's own plan-apply edit of `docs/queue-feature.md` conflicted with the sprint-16-records rewrite; merge-main aborted, a contributor start redid the merge by hand, and the check, both reviews, and a second 16-minute CI ran again (merge 60,874 output tokens/21 calls against 24,917/7; ci_wait_calls 10 against 4 to 8).
- Fix: re-run plan-apply over the new main's queue in merge-main instead of merging the queue text, so a lane whose base predates a records merge takes in main with no conflict in `docs/queue-*.md` and no contributor start.

### The moved check reruns the reviews on a cleanly merged file and misses a hand-resolved one (tab-close-d retro)
- Location: `tools/run_state.sh` moved_change.
- Why: after the merge of main the moved check named `README.md` (merged cleanly, same diff against the new main) as changed and both reviews ran again, while the hand-merged `docs/queue-feature.md` was not named; reviews 37,844 output tokens/46 calls, 20 percent of the run's 227 calls, the rerun changing no decision.
- Fix: rerun the reviews exactly when the change's own diff of some file differs from its diff before the merge, a hand-resolved conflict file always counting; a tools-test case for each.

### Packaging writes advisory findings into the findings file by hand (tab-close-d retro)
- Location: `.claude/workflows/deliver-change.js` package phase, `docs/findings/<change>.md`.
- Why: packaging turned the run state's quality advisories into findings entries and a rewritten pull request text by hand in two docs-only commits, and the next quality review flagged the entries' format; package 60,830 output tokens/51 calls against a last-ten feature median of about 8,000/15.
- Fix: a `tools/run_state.sh` command appends the advisory notes to `docs/findings/<change>.md` in the file's one format; accepted when the next five medium runs' package phase stays near the median.

### The tab-close-d findings entries break the file's format (tab-close-d late finding)
- Location: the tab-close-d findings file, line 11 (folded into this file).
- Why: the three entries added at packaging drop the backticks around paths and the trailing periods the file's earlier entries (lines 1 to 10) use, two formats in one file.
- Fix: backtick the locations and end each Location, Why, and Fix line with a period, as above them.

### A records change that resumes into the planner loses the planner's files (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` package line, `build/plan/sprint-16-records/`.
- Why: the package line forbids plan-apply on `sprint-N-records`, so the planner's `queue-backlog.md` (10,411 bytes) and `backlog.md` (2,758 bytes) never reached main; `docs/queue-backlog.md:5` still holds the merged moved-review-carry Security first section and moved-review-carry-b is not queued.
- Fix: a records run starts no planner, or lands every file the planner wrote in its squash commit.

### The benchmark phase starts an agent for a diff with no file under carat/ (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` benchmark phase.
- Why: with 0 carat files changed it builds base and change and reports every key unchanged: bench 3,547/6 in sprint-16-records, 4,178/8 in sprint-14-records, 3,467/7 in sprint-15-records, 11,192 output and 21 calls over 3 runs, 0 differences.
- Fix: record the bench phase without an agent start when no measured file changed; accepted when the next records row shows no bench share.

### Groom's fold keeps producing format defects the records run hand-fixes (sprint-16-records retro)
- Location: `tools/run_state.sh` folded_backlog (`:2143`), groom.
- Why: the docs-lint hand edit of a removed findings path recurred in sprints 10, 12, 13, and 16; 2 of sprint-16-records' 6 quality advisories were fold defects already in the backlog (a third level-one heading, headings at `docs/backlog.md:7643`, `:7647`, `:7651` with no blank line).
- Fix: folded_backlog skips a findings file's leading `# ` line and separates every folded heading by one blank line; accepted when a records run ends with no hand edit after groom and no fold-format finding.

### Marked fold copies outlive a committed plugin edit
- Location: carat/domain/buffer.rb:640
- Why: the fold copies taken by transaction_mark are cleared only by revert_to, so after a successful plugin edit they stay, holding a closed window's Folds alive, and a later revert_to without a fresh mark, for example with transaction_size, restores stale folds, contrary to the risk note of the vim-folds-b design.
- Fix: clear marked_folds and marked_fold_copies in commit_transaction and on revert_to's early return, and add a test of revert_to after a committed marked edit.

### A revert test pins folds misaligned with their reverted lines
- Location: test/domain_edits.rb:221
- Why: the assertion 'a revert with no fresh mark puts back no old copy' pins folds [2,3],[4,5] against lines already reverted to six rows, enshrining folds misaligned with their lines as expected.
- Fix: assert only that no stale copy comes back (a fold count or a fold the stale copy would differ in), or shift the folds back in revert_to as the signs are.

### mark_folds copies every folded window's folds on each plugin edit
- Location: carat/domain/buffer.rb:794
- Why: mark_folds allocates a Folds copy per folded window on every plugin edit_buffer, success included, for a rollback only a failure uses.
- Fix: acceptable as designed, or take the copy lazily on the first splice of the marked transaction that touches a tracked fold list.

### A fold test label repeats keys instead of naming the behavior
- Location: test/editor_folds.rb:127
- Why: the label 'zf3jzozfj nests a fold at the outer fold's first row' repeats the keys of the drawing row at line 88 instead of naming the behavior it proves.
- Fix: label it by the state it proves, for example 'zf at an open fold's first row adds a closed fold nested in it'.
### A records change that resumes into the planner loses the planner's files (sprint-16-records retro)
- Location: `.claude/workflows/deliver-change.js` package line, `build/plan/sprint-16-records/`.
- Why: the package line forbids plan-apply on `sprint-N-records`, so the planner's `queue-backlog.md` (10,411 bytes) and `backlog.md` (2,758 bytes) never reached main; `docs/queue-backlog.md:5` still holds the merged moved-review-carry Security first section and moved-review-carry-b is not queued.
- Fix: a records run starts no planner, or lands every file the planner wrote in its squash commit.

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
## JsonRpcLanguageGateway#path_of keeps dot segments (periodic security Low at 186ddfb)

- Where: `JsonRpcLanguageGateway#path_of` in `carat/adapters/json_rpc_language_gateway.rb` (line 789 at 186ddfb); split at sprint-18 planning from "## Security Lows of the periodic review at 186ddfb", whose OpenSpec pin stays with `check-clone-toolchain`.
- Why it matters: `.` and `..` segments pass `VisitTarget`'s lexical inside check where only `ResolveInside` refuses them, so one file gets two titles and keys, and a plugin joining an unchecked name reads outside the project.
- Fix outline: return `PluginApi::Paths.normalize(out)` from `path_of`, with a gateway row for a `..` path. Queued in `lsp-tidy`.

### The squash-merge hook leaves the commit title unchecked (sprint-17 review security Low (4))

- Where: `squash_message` in `tools/agent_guard.sh` (line 950 at 522a0e1).
- Why it matters: the hook compares `commit_message` with the archived pr.md but never `commit_title`, so a misled merger start could squash with a subject carrying a URL or a model name, and the subject of the commit on main is never compared.
- Fix outline: read `commit_title` as `commit_message` is read and require line 1 of the archived pr.md followed by ` (#N)`, N the run state's pull request; a tools-test case for a changed title. Queued in `ci-trust-gaps-c`.

### :normal commits the first buffer with another buffer's cursor (sprint-17 review quality)

- Where: `carat/use_cases/ex/normal_command_handler.rb:71` at 522a0e1.
- Why it matters: when the fed keys switch buffers (Ctrl-^), the original buffer's transaction commits with the other buffer's cursor as its after-cursor, unlike `GlobalCommand#run`, so undo puts the cursor at a position from another file; and keys that switch then enter insert mode (`:normal bix`) leave that buffer's transaction open past the command (`:69`).
- Fix outline: commit with the position from before the loop when the buffer changed, and commit or close whatever transaction the keys left open, with rows for both. Queued in `normal-command-fixes`.

### :normal can nest through a project remap until the editor hangs (vim-line-commands-c security Low (6))

- Where: `carat/use_cases/ex/normal_command_handler.rb:62` and `MAX_DEPTH` at `:24`, at 522a0e1.
- Why it matters: a hostile project `.caratrc` line such as `keymap.normal j :%normal Space j CR` runs each line's j again at the next depth, about line_count to the power 100 key runs; and depth 100 exceeds Spinel's 64 exception frames through a plugin action, so a stack error may come before E192.
- Fix outline: bound the total keys or depth well under the frame budget, refusing with E192, with a row for the remap above and a plugin-action path. Queued in `normal-command-fixes`.

### :normal leaves the caller's mode, depth, and command order wrong (vim-line-commands-c late findings)

- Where: `carat/use_cases/ex/normal_command_handler.rb:104` (the Esc loop), `:59` (normal_depth), `:51` (E471), `carat/use_cases/ex/history_command_handler.rb:43`, at 522a0e1.
- Why it matters: a plugin's `run_ex` of `:normal` from visual or insert mode ends the user's selection or insert session; a raise escaping the fed keys leaves normal_depth above 0, so every later key joins one transaction never closed; `:9normal` on 5 lines answers E16 where Neovim answers E471; `:undo x` (E474) under `:normal` still splits the undo state.
- Fix outline: end only what the keys left unfinished, reset the depth where the key loop recovers, check the argument before the range, sync only for a valid walk; rows for each. Queued in `normal-command-fixes`.

### :normal and :p tests and docs miss what the code promises (vim-line-commands-c late findings)

- Where: `test/adapters_assembly.rb:126`, `test/editor_line_commands.rb:171`, `:176`, `carat/use_cases/ex/print_command_handler.rb:34`, `docs/architecture.md:200`, `carat/use_cases/dispatcher.rb:75`, at 522a0e1.
- Why it matters: the one-instance check names only the controller though `NormalCommandHandler` holds `HandleKey` in a reader; a scenario comment sits above the wrong rows (sprint-17 review); only `:undo` is tested of the four undo commands `docs/compatibility.md` promises sync under `:normal`; E749 is given for one empty line where Neovim prints it, not listed as a difference; section 6 names `Outcome` as ok and message, without printed; `transaction_edits` is read for every dispatched key though only record uses it.
- Fix outline: add the holder to the strangers list, move the comment, add a `:redo` row, list E749 under Differences, name `printed` and `Outcome.from_print`, read the edits inside the change branch. Queued in `normal-command-fixes`.

### The code map's explorer flow names open_in_tab (sprint-17 review quality)

- Where: `docs/codebase-map.md:584` at 522a0e1.
- Why it matters: the flow says the explorer opens files through `open_file`, `open_in_split`, and `open_in_tab`, but `carat/plugins/explorer/plugin.rb` calls `open_as_tab` and `open_in_tree_window`, so a reader follows a name that is not called.
- Fix outline: name the requests the plugin calls. Fold into `explorer-tidy` if it touches the map, else a docs tidy.

### The advisory commit-prefix strip is written twice in the delivery workflow (sprint-17 review quality)

- Where: `.claude/workflows/deliver-change.js:1119` and `:791` (`addAdvisories`), and two blank lines in a row at `:1009`, at 522a0e1.
- Why it matters: fixed-in-place matching depends on the two copies of the regular expression staying identical; the blank lines are left from a removal.
- Fix outline: one helper used by both, one blank line. Fold into the next pipeline change editing the file.

### A re-review re-raised an advisory declined for the brief's reason
- Location: `.claude/agents/quality-reviewer.md`, `.claude/workflows/deliver-change.js` (notes handed to a later round); facet-palette note 6 repeating note 1
- Why: the PANEL_DIM advisory, declined in round 1 because the brief pins #a4aabd / #5c6173, came back word for word; round 2 grew output from 332,067 to 573,120 (+241,053, 33 percent of 736,922); quality first pass 93/166 (facet-palette retro 11).
- Fix: an advisory declined with a recorded reason goes to the findings file, not to a new round; accepted when no run has a later-round advisory repeating a declined note that drives a round of its own. Fold into `rework-review-repeat`.

### facet-palette dropped the brief's PANEL_DIM
- Location: `carat/domain/themes.rb` (no PANEL_DIM role, no #a4aabd, at caf4532ac051; DIM 0x5c6173 at line 269)
- Why: facet-palette's brief pinned PANEL_DIM #a4aabd / #5c6173 and its acceptance asked theme rows pinning each value; round 2 removed it on a re-raised advisory (retro 11), so the merged palette misses a value the user's Facet plan named.
- Fix: restore the PANEL_DIM role on carat-dark and carat-light with the pinned values; accepted when theme rows pin both. Queued with `ui-groups`.

### The check and merge phases spend a third of a feature run's output waiting
- Location: `.claude/agents/checker.md`, `.claude/agents/merger.md`, `.claude/workflows/deliver-change.js:126` (mergerCap); backlog queue item `merge-output-cap`
- Why: facet-palette check 123,463 output in 6 calls (16.8 percent, 3 passes all green first), merge 101,948 in 13 calls (13.8 percent, ci_wait_calls 6), together 30.6 percent of output for 8.4 percent of calls; guide-colors merge 26,423 in 11 calls (facet-palette retro 12).
- Fix: the checker and merger read the stage and CI results the run state holds and generate little; accepted when check stays under 10,000 output per pass and merge under 30,000 over the next 5 feature runs with first passes unchanged. Fold into `merge-output-cap`.

### Background delta spec removes and re-adds the requirement instead of modifying it
- Location: openspec/changes/archive/2026-11-18-background-default/specs/color-themes/spec.md:1 (quality advisory, raised at openspec/changes/background-default/specs/color-themes/spec.md:1)
- Why: one clear way: the delta removes 'The background option chooses who paints the background' and adds a renamed copy repeating three of its four scenarios word for word, where only the default and one scenario changed, so the history reads as a new requirement rather than a changed default.
- Fix: a MODIFIED block under the existing header with the new default, the painted-by-default scenario in place of Transparent by default, and the two named-kept scenarios; the contributor tried a MODIFIED block in a scratch copy and openspec validate refused it for dropping 'Transparent by default' (design.md records it), so a follow-up first checks whether the validator allows a modified requirement to drop a scenario, else closes this finding.

### The code map says the backlog lane's sprint holds 0 to 2 items

- Location: docs/codebase-map.md:55, tools/docs_lint.sh:23 (its header, check_lane)
- Why: sprint-size-six made a sprint 3 features and 3 backlog items, so the map's "0 to 2" for the backlog lane's `## Sprint` is stale and misleads a reader of the lane rules (the planner's note on backlog-throughput).
- Fix: say 0 to 3 in the map line and confirm `check_lane` in tools/docs_lint.sh enforces the same bound, with a docs-lint case.

### The planner's guard refuses backlog-pick, which its sprint mode runs

- Location: tools/agent_guard.sh:613 (run_state_form, the read profile)
- Why: the planner's sprint mode (.claude/agents/planner.md step 2, sprint-planning.js line 222) runs `sh tools/run_state.sh backlog-pick docs/backlog.md docs/findings/*.md`, but the read profile lists only backlog-dups among the backlog commands, so the guard refuses it ("refused for the read profile: tools/run_state.sh backlog-pick") and the planner must pick the batches by hand; backlog-throughput added backlog-oldest to the profile but left backlog-pick out of scope.
- Fix: add `read:backlog-pick` to the read profile and its header comment, with a guard case beside "guard: the read profile lists backlog duplicates" in tools/tools_test.sh.
### groom description overstates the refusal of a later removal of a merged heading
- Location: docs/codebase-map.md:48 (tools/run_state.sh:2642)
- Why: docs currency: the groom description says neither a merged entry's kept nor its merged heading is removed by another line, but groom refuses a merged line only when an earlier line already removes its heading, so a later listed or fixed line naming the same merged heading still passes (quality advisory at 65a5758220b7).
- Fix: say the merged heading is refused when an earlier line removes it, or refuse any later removal of a merged heading in groom with a tools_test case.

### The merge phase spends output out of proportion to its calls (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the merge phase, and `.claude/agents/merger.md`
- Why: guide-colors merge took 26,423 output tokens for 11 calls and 4 CI-wait calls (9.1 percent of 290,842) on a 7-minute green CI; the last 10 feature rows range 4,992 to 98,694 merge output at 10 to 21 calls.
- Fix: a run green on its first CI pass keeps its merge phase under 10,000 output tokens; accepted over 5 consecutive runs.

### A passing check phase costs a full agent start (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the check phase, and `.claude/agents/checker.md`
- Why: guide-colors check took 30,277 output tokens for 5 calls over two passes with all 9 stages passing (10.4 percent of 290,842), though the stages are deterministic; the benchmark already records equal figures without an agent.
- Fix: record a check phase whose stages all pass without an agent's reasoning, or with a minimal start; accepted when such a phase records under 3,000 output tokens.

### Groom's duplicate guard lets an unmarked security entry leave as a duplicate
- Location: tools/run_state.sh:424 (SECURITY_MARK) and the duplicate check at tools/run_state.sh:2510; reached the branch through the merge of main (#209, 9674689), not this change's own commits.
- Why: security Low (6). The guard now uses SECURITY_MARK instead of any line naming security, so a security entry recorded without the 'security Low' or 'Low (N)' form (for example the benchmark's reused temporary report path, recorded as a Low finding of the periodic security review at 66fd52b) can be removed by a planner-written groom.txt `duplicate` line, and an open security finding leaves without a merged item or a fixing commit.
- Fix: Widen SECURITY_MARK so it also matches an entry naming a severity next to a security review (for example '(high|medium|low)( finding)? of the (periodic )?security review'), or keep the old case-insensitive 'security' test for duplicates while the narrow mark stays for ranking; add a tools_test.sh case where groom refuses to remove such an entry as a duplicate; separately, normalize stored entries to the 'security Low (N)' form.
### The merge phase spends output out of proportion to its calls (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the merge phase, and `.claude/agents/merger.md`
- Why: guide-colors merge took 26,423 output tokens for 11 calls and 4 CI-wait calls (9.1 percent of 290,842) on a 7-minute green CI; the last 10 feature rows range 4,992 to 98,694 merge output at 10 to 21 calls.
- Fix: a run green on its first CI pass keeps its merge phase under 10,000 output tokens; accepted over 5 consecutive runs.

### A passing check phase costs a full agent start (guide-colors retro)
- Location: `.claude/workflows/deliver-change.js`, the check phase, and `.claude/agents/checker.md`
- Why: guide-colors check took 30,277 output tokens for 5 calls over two passes with all 9 stages passing (10.4 percent of 290,842), though the stages are deterministic; the benchmark already records equal figures without an agent.
- Fix: record a check phase whose stages all pass without an agent's reasoning, or with a minimal start; accepted when such a phase records under 3,000 output tokens.

### Groom's listed proof accepts a heading as a bare substring of the queue item (`groom-proof` security Low (5))
- Location: tools/run_state.sh:2387 (item_lists)
- Why: item_lists accepts the heading as a bare substring of the queue item, so a planner `listed` line for a short heading such as `## Foo` passes when the item only quotes a different, longer heading such as `### Foo bar`; a security entry can then leave the backlog without its merged item ever naming it, the proof this change set out to require.
- Fix: Require a bounded match: no `#` before it, and after it the closing quote the planner writes (`Backlog: "### title"`), a comma, or the end of the item; or match the quoted form `"` H `"`. Add a tools-test case refusing a shorter heading that prefixes a quoted longer one.

### Groom's duplicate guard lets a security entry without a `security <severity>` marker leave (`groom-proof` security Low (3))
- Location: tools/run_state.sh:422 (SECURITY_MARK)
- Why: The guard used to refuse any entry mentioning security and now refuses only text matching its severity marker, so a security entry written without it (an older entry, or one transcribed from a periodic note recorded as `High (8) file:line ...` under the note kind `security`) can leave as a `duplicate` without a listed item or a fixing commit. The design accepts the risk, since findings deliver-change.js hands over carry the `security <severity>` prefix, limiting the exposure to entries written some other way.
- Fix: Also treat an entry as a security entry when its heading or Location line carries a severity and confidence pair, `(High|Medium|Low) \([0-9]+\)`, or when it came from a security note; or make the planner's sprint mode write `security <severity>` into the heading of every security entry it adds, so the marker the guard reads always exists.

### Groom's listed proof still accepts a comma after an unquoted heading (`groom-proof` security Low (2))
- Location: tools/run_state.sh:2410 (item_lists)
- Why: item_lists accepts a comma after a heading that no double quote or backtick opens, so a short heading `## Foo` still counts as listed when an item mentions a longer heading `## Foo, bar` bare or in single quotes, and a security entry could then leave the backlog without its merged item naming it. It predates the change and is narrower now: the planner's double-quoted form is closed, so the residual needs a bare or single-quoted mention of a backlog heading that is the exact prefix of another heading followed by a comma.
- Fix: Accept a bare heading only at the end of the item, or treat a single quote like the other quote characters; stricter, require the planner's quoted form (Backlog: "H") outright. Add a tools-test case with a bare `## Foo, bar` against `## Foo`.

### Groom's guard against a `#` before a listed heading has no test (`groom-proof` quality advisory)
- Location: tools/run_state.sh:2406 (item_lists)
- Why: Untested branch: item_lists' guard against a `#` before the heading (a `## y` heading inside a quoted `### y` one) has no tools-test case; only the guard after it is exercised, so a regression in it would pass the suite.
- Fix: Add a listed case whose item quotes `### ...` for the same `## ...` heading, listed unquoted at the item's end or before a comma so the guard alone refuses it.

### exception_item now counts a wrapped `beyond the sprint` mark without a test (`groom-proof` quality advisory)
- Location: tools/run_state.sh:2127 (exception_item)
- Why: Untested branch: exception_item now reads the item through queue_items, which joins continuation lines, so a `beyond the sprint` mark inside a first parenthesis wrapped onto the next line now counts as an exception in review-due and the sprint row, where main read the first line only; no review-due case pins the new behavior.
- Fix: Add a review-due tools-test case whose item's parenthesis wraps before the mark.

### Groom leaves references to the findings files it removes (sprint-17-records retro)
- Location: `tools/run_state.sh` groom and its fold of docs/findings/, `tools/docs_lint.sh` path check
- Why: docs-lint refused 3 backticked paths to removed findings files that needed hand edits, as in earlier records changes, and missed a bare file name (`docs/queue-feature.md:44` naming vim-folds-b.md:36), 1 of 5 first-pass advisories that opened rework round 1 (rework 2 in sprint-17-records).
- Fix: groom rewrites or refuses references to the files it removes, bare names included; accepted when the next records change needs no hand edit for a removed findings file and no review reports one.
- Evidence: sprint-18-records again needed one hand edit, commit 1dba846 unquoting the removed findings directory in this entry's own Location line, since docs-lint refused it.

### Task 5.2 of sign-colors describes the superseded shown-layer scan
- Location: openspec/changes/archive/2026-11-18-sign-colors/tasks.md:22 (task 5.2, reviewed as openspec/changes/sign-colors/tasks.md:22)
- Why: docs currency: task 5.2 still calls Buffer#shown_layer_index private and says sign_at and sign_group_at read the shown layer once, while task 6.2 made it public and the presenter now does the one scan, so the archived record misdescribes the code.
- Fix: reword 5.2 to name the shared scan, or note that 6.2 supersedes it.

### A tab-close-d findings entry is folded twice into the backlog
- Location: docs/backlog.md:8156, docs/backlog.md:8020
- Why: quality advisory, duplication: "The tab-close-d findings entries break the file's format" at :8156 repeats the entry at :8020 (same finding, Location, Why, and Fix under another heading), which the groom triage missed.
- Fix: list the :8156 heading as a duplicate in the next sprint's groom.txt.

### Two fold format entries are covered by a third
- Location: docs/backlog.md:8066, docs/backlog.md:8072, docs/backlog.md:8171
- Why: quality advisory, duplication: "Fold adds a level-one heading per findings file" (:8066) and "Folded headings lack a blank line before them" (:8072) are covered by "Groom's fold keeps producing format defects" (:8171).
- Fix: groom the two into the :8171 entry at the next grooming.
### Buffer#sign_at and sign_group_at have no production caller (sprint-18 review quality, sweep quality)
- Location: `carat/domain/buffer.rb:406`, `:415`; `carat/adapters/frame_presenter.rb:852` to `:858`.
- Why it matters: the presenter reads `layer_at(shown_layer_index(row))` itself, so the two readers serve only tests and the sign lookup has two shapes.
- Fix outline: one Buffer reader of the shown sign layer (or nil) used by the presenter and the tests, the test-only pair dropped, `shown_layer_index` private again.

### Two tests scan the palette rows by hand (sprint-18 review quality)
- Location: `test/adapters_frame_presenter.rb:183` (`palette_rgb`), `test/domain_theme.rb` (`role_row`).
- Why it matters: the same lookup is written twice over the 4-value palette rows.
- Fix outline: one `Domain::Themes` reader of a role's 24-bit color, or one shared test helper, used by both.

### The panel color cases check the role the sprint did not change (sprint-18 review quality)
- Location: `test/domain_theme.rb:551`.
- Why it matters: the cases check `bg(H::STATUS)` (0x2e3346, 0xe3e6ef) while the label names the PANEL_NC and FLOAT change.
- Fix outline: drop the block or check TAB_LINE, STATUS_NC, and NORMAL_FLOAT.

### The architecture's Options entry and scope list drift from the code (sprint-18 sweep quality)
- Location: `docs/architecture.md:118`, `:245`; `carat/domain/options.rb:40`.
- Why it matters: the entry names wrap and clipboard as members and omits gt, theme, background, syntax_on, startscreen, reducedmotion, indentguides_char; the scope list omits startscreen, reducedmotion, jumptab, gt, indentguides.char.
- Fix outline: list the Struct members and the KINDS scopes as the code declares them.

### The README omits gt and node (sprint-18 sweep quality)
- Location: `README.md:91`, `README.md:9`; `Makefile:218`.
- Why it matters: the option list lacks gt; the prerequisites lack node, which `make doctor` requires and the js tools cases run.
- Fix outline: add gt beside jumptab; name node as a prerequisite of the checks or drop it from doctor.

### The tab width and shift width fallbacks are hand-written at ten sites (sprint-18 sweep quality)
- Location: `carat/use_cases/dispatcher.rb:114`, `repeat_last.rb:104`, `leave_insert.rb:71`, `arrange_view.rb:47`, `insert_tab.rb:25`, `carat/adapters/frame_presenter.rb:218`, `carat/domain/operators.rb:172`, `:251`, `:272`, `carat/domain/display_width.rb:57`.
- Why it matters: `tabstop > 0 ? tabstop : 8` repeats `Options#tab_width` (`options.rb:135`), dead since tabstop is validated from 1.
- Fix outline: call `options.tab_width`, and pass one resolved shift width (an `Options#shift_width`) to Operators.

### Use cases re-implement clamp_col and wanted_col (sprint-18 sweep quality)
- Location: `carat/use_cases/operate.rb:233`, `:70`, `:205`; `carat/use_cases/repeat_last.rb:116`; `carat/domain/editor_state.rb:126`; `carat/use_cases/ex/line_command_handler.rb:54`.
- Why it matters: private `clamp` copies and `end_visual` repeat `EditorState#clamp_col` (`editor_state.rb:100`); `place_cursor` repeats `Motions.wanted_col` (`motions.rb:247`); `yank` writes the cursor directly where siblings use `move_to`.
- Fix outline: call `state.clamp_col` and `Motions.wanted_col`, `case operator`, `cursor.move_to` in yank.

### Handlers repeat small helpers (sprint-18 sweep quality)
- Location: `carat/use_cases/ex/tab_command_handler.rb:102`, `buffer_command_handler.rb:102`, `history_command_handler.rb:61`, `carat/domain/json.rb:72` (`digits?` four times); `carat/use_cases/search/global_command.rb:82` and `substitute_lines.rb:112` (`remember`); `carat/domain/keymap.rb:321` (`name_group` repeats `bind_text`, `:200`); `carat/adapters/input_controller.rb:134`; `carat/use_cases/files/save_all.rb:33`.
- Why it matters: copies change apart.
- Fix outline: one domain digit predicate, one shared pattern-recording step, one keymap parse helper, one handle call, one branch.

### Outcome.success("") is still built at 23 sites (sprint-18 sweep quality)
- Location: `carat/use_cases/outcome.rb:30`; `carat/use_cases/files/quit.rb`, `windows/split_window.rb`, `open_side_window.rb`, `plugins/plugin_router.rb`.
- Why it matters: `Outcome.none` exists so a key allocates nothing.
- Fix outline: return `Outcome.none`.

### HandleKey's queue rule and signature triggers (sprint-18 sweep quality)
- Location: `carat/use_cases/handle_key.rb:259`, `:284`, `:391`.
- Why it matters: `dispatch` says its caller must assign the returned queue, yet `step` and `complete` discard it; `code == 40 || code == 44` are unnamed.
- Fix outline: state the rule once and apply it, or narrow the comment; named constants for ( and ,.

### A hidden slot's window comes back with its cursor past the last line (sprint-18 sweep quality)
- Location: `carat/domain/tab_list.rb:252`; `carat/use_cases/windows/toggle_slot.rb:45`, `open_side_window.rb:36`.
- Why it matters: `clamp_cursors` skips windows kept in hidden slots, so a plugin view whose buffer shrank while hidden returns past its end.
- Fix outline: clamp kept slot windows too, or on show, with a `test/editor_slots.rb` row.

### The language server gateway holds every request kind in one class (sprint-18 sweep quality)
- Location: `carat/adapters/json_rpc_language_gateway.rb:1` (1486 lines, 87 methods).
- Why it matters: lifecycle, sync, and five request kinds each carry their own send, cancel, and answer code.
- Fix outline: a collaborator per request kind sharing `cancel_request` and `position_params`.

### Doc comments and map entries drift (sprint-18 sweep quality)
- Location: `carat/testing.rb:4`; `bin/carat-gen-config.rb:32`; `carat/domain/range.rb:4`; `carat/adapters/editor_assembly.rb:190`; `docs/codebase-map.md:128`, `:478`, `:543`, `:474`; `tools/docs_lint.sh:22`, `docs/codebase-map.md:55`; `tools/gates.sh:39`.
- Why it matters: testing.rb credits spin with the diff; the generated header says `spin run`; range.rb names only charwise ranges; a broken comment and a repeated loop in EditorAssembly; the map omits Messages E16, E444, E477, E490, REPORT, StatusSlots `set_lsp`, Paths `absolute`, and still names FramePresenter `diagnostic_group`; docs_lint says 0 to 2 backlog items where the sprint holds 3; the gates usage names CHECK_STAGES where FAST_STAGES is read first.
- Fix outline: correct each text, `make gen-config` after the header fix.

### Requires leaned on carat.rb order (sprint-18 sweep quality)
- Location: `carat/use_cases/plugins/buffer_requests.rb:110`, `:49`; `carat/domain/messages.rb:22`; `carat/domain/walker.rb:63`; `carat/use_cases/search/find_match.rb:140`.
- Why it matters: Highlight, ControlText, and `Motions.code_class` are named without a require, Walker and Motions form a hidden cycle, `blank?` repeats `code_class`, and one comment line is mis-indented.
- Fix outline: add the requires, move `code_class` and `blank?` where both require it, use `code_class`, reindent.

### The cls abbreviation is still used (sprint-18 sweep quality)
- Location: `carat/domain/text_objects.rb:86`, `carat/domain/runs.rb:21`.
- Why it matters: CLAUDE.md names `cls` as the wrong form.
- Fix outline: rename to `char_class`.

### assert_true passes any truthy value (sprint-18 sweep quality)
- Location: `carat/testing.rb:31`.
- Why it matters: a predicate returning a non-bool passes while the failure text says expected true.
- Fix outline: compare `value == true`, or rename to `assert_truthy`.

### Tools pass what their usage says fails (sprint-18 sweep quality)
- Location: `tools/metrics.sh:86`; `tools/gates.sh:266`; `tools/run_state.sh:2538`; `tools/spec_validate.sh:25`; `tools/ci_scope.sh:80`.
- Why it matters: compare passes a base name CURRENT lacks; `has()` matches paths as a regex; backlog-oldest skips `####` entries backlog-pick takes; only the last spec preview survives; the push path calls one endpoint twice.
- Fix outline: fail every unseen strict base name; `grep -q -x -F`; one heading test in ENTRY_AWK; a preview directory per change; one gh call.

### The token weighting prices a mid-tier start at the cheap tier's price

- Location: `tools/run_state.sh` line 2009 (`add_tokens`; the alias list read from the agent files' `model:` lines at about line 1976, `TIER_PRICES` at line 448; the `weighted_phases` history column it feeds).
- Why: once `.claude/agents/contributor.md` has a `model:` line, the `tokens` command labels the contributor's starts cheap and prices them at 100/125/10/500 instead of a mid price, so `weighted_tokens` and `weighted_phases` are understated; the same starts are also recorded as `metric.start.N` `implement/cheap/...` and in `weighted_phases` under a `cheap` label the calibration profile no longer uses. The trial's revert rule uses total tokens, so its verdict is unaffected. Queued as Pool 30 `tier-price-mid`.
- Fix: in `tier-price-mid`, price each alias by its own tier, label such a start by the agent tier (or by the alias's own price key) together with its price, extend the design's no-cheap-label goal to the token labels then, and add a tools-test case that prices and labels a mid-tier start apart from a cheap one.

### The tier trial's keep rule does not say how its figures compare

- Location: `docs/goals.md:38`
- Why: the rule compares 6 deliveries with 10 rows without saying whether each figure is a per-row rate or a mean, which history (both lane files in merge order, or one lane), or how `total_tokens` of changes of mixed sizes compare, so the planner's verdict can be read either way.
- Fix: state per-row rates and means over both lane histories in merge order, `total_tokens` taken against each row's estimate budget.

### The calibration comment names the tier twice

- Location: `.claude/workflows/deliver-change.js:129`
- Why: the comment says the tier twice ("the tier the model: line of the agent's file names ... whichever tier that is"), wordier than the rule it states.
- Fix: "The tier is agent, the agent file's model: line (the only place a tier is named; tools/tools_test.sh compares them), or session, the session's model".

### The compatibility row misstates Neovim's sign column width

- Location: docs/compatibility.md:541
- Why: it says Neovim draws signcolumn=yes:1 one cell where its default auto takes two, but Neovim reserves two cells per sign column for both yes:1 and auto (auto:1), as the proposal itself says.
- Fix: write that the column is one cell where Neovim's sign column (yes:1 or the default auto) takes two.

### The group-only repaint check draws into a freshly allocated frame

- Location: test/adapters_frame_presenter.rb:270
- Why: the resize to 7 rows at :259 allocates both frames anew, so the repaint check draws into a fresh second frame that repaints every row whatever the record holds, and does not prove task 1.3's claim that a group-only change repaints.
- Fix: draw once more at 7 rows before placing the warning-group sign, so the checked frame already holds the same glyph in the error group.
### Groom's output fails the check's docs-lint stage on its own (sprint-18-records retro 11)
- Location: `tools/run_state.sh` groom (the fold that deletes the findings files), docs-lint stage
- Why: groom deleted the findings directory while a carried backlog entry still named it in backticks, so sprint-18-records failed its first check at 399adffe0be5 (docs-lint) and needed a contributor fix and a hand edit of groom output; check first passes 168/172 overall.
- Fix: groom output passes `make docs-lint` as written; accepted by a tools-test case folding a findings file whose entry names the removed directory, and the next 3 records runs passing check first.

### Records changes spend fix rounds on advisories only groom may fix (sprint-18-records retro 12)
- Location: `.claude/workflows/deliver-change.js` review rounds on a records change
- Why: 4 of 7 first-round advisories (backlog duplicates, stale security entries, fold format, map repeat) need backlog entries merged or removed, which CLAUDE.md leaves to groom, and 3 of the 4 second-round advisories repeat them with shifted lines; rework 2 with 0 blocking, reviews=25498/34 (29.5% of 86,421 output, 26% of 129 calls).
- Fix: an advisory in groom's own output on a records change goes to the findings file with no fix round; accepted when the next 3 records runs show rework 0 when blocking is 0. Near `review-lite`.

### The benchmark agent runs on records changes that touch no code (sprint-18-records retro 13)
- Location: `.claude/workflows/deliver-change.js` bench phase
- Why: on sprint-18-records it rebuilt dev-build, test-build, and bench-budget in the lane and a base worktree to find allocations and rounds equal: bench=4721/14 (10.9% of 129 calls); sprint-16-records bench=3547/6, sprint-17-records bench=4147/6.
- Fix: a change with no file under `carat/`, `bench/`, or the Makefile records the bench phase as skipped with no agent; accepted when records runs show bench 0/0. Joins `bench-skip-no-code`.

### Codebase map omits the bracket pair for a folded window
- Location: docs/codebase-map.md:474
- Why: the frame_presenter entry says a folded window records no scroll and draws no guides but not that it draws no MatchParen pair, which this change adds.
- Fix: end the sentence with 'and no bracket pair'.
### Advisory-only fix-in-place rounds count as rework (contributor-tier-trial retro 8)
- Location: `.claude/workflows/deliver-change.js` (rework counting of fix-in-place rounds); joins the queued `advisory-findings-auto` (backlog Pool 27).
- Why: contributor-tier-trial spent rework 2 of 3 with 0 blocking findings (7 advisories over 3 quality passes at 0979253d226d, a47624b033bf, 96085591e512); 8 of the last 20 rows with every first pass 1 spent 12 rework rounds, and rework-2 rows took 61.0 to 118.0 min against 44.8 for vim-folds-b at 0; reviews=36277/65, 31% of 207 calls.
- Fix: accepted when, over the next 10 metrics rows, rows whose first passes are all 1 average at most 0.5 rework rounds without a lower quality first-pass rate.

### A resumed implement start that commits nothing costs a full implementation (contributor-tier-trial retro 9)
- Location: `.claude/workflows/deliver-change.js` (the resume's implement start).
- Why: at head 96085591e512 every stage was 0 and every task done, yet implement took 78,908 of 165,645 output tokens (48%) and 73 of 207 calls (35%) to change nothing; check-stage-order's whole implement was 12941/27.
- Fix: accepted when a resume whose head already passes every stage and has every task checked records implement at most 15,000 output tokens and 25 calls.

### settled_round repeats the RECORDS_RE filtering of other records filters (review-lite quality advisory)

- Location: tools/run_state.sh:1248 and tools/run_state.sh:1264 (settled_round), beside settled_at in tools/gates.sh:122 and run_state.sh's own records filters around lines 1786 and 3170
- Why: the same filter of paths outside RECORDS_RE is written four times, so a change to what counts as a record must be repeated in each place or the settled round and the gates disagree; the two quality findings at lines 1248 and 1264 are merged here as one.
- Fix: one shared helper listing the paths outside RECORDS_RE, used by settled_round, settled_at, and the records filters, when review-lite-docs edits tools/rules.sh

### 'workflow: a blocking round never settles' repeats other settle cases (review-lite quality advisory)

- Location: tools/tools_test.sh:4063
- Why: the rewritten case repeats 'workflow: findings in place ride with the blocking ones' (line 4084, inPlaceRound(true, ...) is 'with') and the alone case of line 4086, and its settleFrom element repeats line 4049, so it adds no proof and costs upkeep.
- Fix: drop it from settle_js (and inPlaceRound from settle_js's names) and cite the place_js cases in tasks.md 2.6

### The guide-colors retro entries are folded twice into the backlog

- Location: `docs/backlog.md:8396`, `:8401`, `:8406` repeating `:8377`, `:8382`, `:8387`; the `:8361`-area facet-palette and sprint-17-records entries (sprint-18-records quality review, raised twice)
- Why: the three guide-colors retro entries came in twice from facet-palette's findings file, and with the facet-palette and sprint-17-records entries make four near-same notes on advisory-only rounds.
- Fix: list the second copies as duplicate and merge the advisory-only notes into one in the next `groom.txt`.

### Two security entries stay open though #214 fixed them

- Location: `docs/backlog.md:8392` and `:8416` (SECURITY_MARK misses unmarked security entries); `tools/run_state.sh:454`
- Why: both are carried open though b5b0aec (#214) widened SECURITY_MARK, so the backlog overstates open security work.
- Fix: list both as fixed by b5b0aec in the next `groom.txt` after checking its tools-test cases.

### Folded backlog entries lack the blank lines around their headings

- Location: `docs/backlog.md:8372`, `:8396`, `:8460` (`:8461` in the second review pass) and most added entries (sprint-18-records quality review, raised twice)
- Why: the entries lack the blank line after the heading and before the next heading, the same format defect groom's fold keeps producing.
- Fix: fold into the existing "Groom's fold keeps producing format defects" entry, or have groom normalize blank lines when folding.

### The backlog-lane sprint size entry repeats the drift entry

- Location: `docs/backlog.md:8361` and `:8520` (`:8521` in the second review pass); `tools/docs_lint.sh:22`, `docs/codebase-map.md:55` (sprint-18-records quality review, raised twice)
- Why: "The code map says the backlog lane's sprint holds 0 to 2 items" repeats part of "Doc comments and map entries drift".
- Fix: merge the two at the next grooming.
### A settled records-only round can remove security entries unseen (sprint-19 review security Low (5))

- Location: `.claude/workflows/deliver-change.js:952` (review-lite's settled round), `tools/gates.sh` settled_at, `tools/run_state.sh` settled_round.
- Why: in an advisory-only round that changes only records the security review does not run again, and the records include `docs/backlog.md` and `docs/findings/*.md`, so a contributor deleting or rewording a security entry there reaches the merge with no security reviewer seeing it; only the sprint-end combined-diff review would catch it.
- Fix: refuse to settle when the diff since the settled commit removes or changes an existing line of `docs/backlog.md` or `docs/findings/*.md` (append only), else run the security review again; a tools-test case each way. Queued in `review-lite-docs`.

### SECURITY_MARK matches security and a severity word anywhere in a long entry (sprint-19 review quality)

- Location: `tools/run_state.sh:461`
- Why: matched over the whole joined entry, the mark takes process entries as security ones: the repeated guide-colors retro entry at `docs/backlog.md:8377` and `:8396` (security 0 ... medium output budget) becomes a security entry that groom refuses as a duplicate; safe-side, but it grows with entry length.
- Fix: require the severity within a short window of security (or finding or review wording), with a tools-test case that an entry naming security 0 and a medium output budget is not a security entry. Queued in `groom-fold-format`.

### The bracket pair key multiplies by a bare number (sprint-19 review quality)

- Location: `carat/adapters/frame_presenter.rb:1246`
- Why: pair_key multiplies by 1_000_003 and the column bound it assumes is written only in the archived design.md, so a reader cannot see why it is safe.
- Fix: a private constant (PAIR_KEY_STRIDE) with a comment that columns stay below it. Queued in `render-tidy`.

### The bracket pair table has no multibyte or scrolled row (sprint-19 review quality)

- Location: `test/adapters_frame_presenter.rb:167`
- Why: pair_case has no row with multibyte text before the bracket or a window scrolled sideways (left > 0), where code-point indexing and fill_columns clipping could go wrong.
- Fix: add a row with a non-ASCII character before ( and one scrolled left so only one bracket is visible. Queued in `render-tidy`.

### The lane history files keep a 22-column header above 24-field rows
- Location: `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv` header line, and `HEADER` in `tools/run_state.sh`.
- Why: `history_row` now appends `advisories_closed` and `advisories_left`, but a file that already exists keeps its old header, so the first rows carrying them have two fields the header does not name.
- Fix: a records change that adds the two names to each header line, with the test that every history row has the header's columns (now 24 for a fresh file) read against the header of the file.
### Process text of the closing loop is absent from CLAUDE.md and docs/goals.md
- Location: `CLAUDE.md` Agents section (30,713 of 30,720 bytes) and `docs/goals.md` line about own-file advisories fixed in place within the rounds.
- Why: both describe advisories as fixed in place or recorded; the closing loop adds one last start after the rounds, described only in README.md and `docs/contributor-notes.md`.
- Fix: when budget allows, one sentence in the CLAUDE.md contributor bullet and the planner's goals text naming `close-advisories`, once its recorded figures show whether it stays.

### closeAdvisories trusts the contributor's reported head to skip the re-review
- Location: .claude/workflows/deliver-change.js, closeAdvisories (head === before)
- Why: a closing start that committed code but reported the old head would skip verify() in the workflow; the pre-push and merge gates (settled_at) still refuse a security pass that code changed since, so nothing is bypassed in practice. The workflow holds no shell, so a lane head read needs a new record start (new behavior).
- Fix: have the checker's verdict commit or a rev-parse record start give the lane head, compare it with before, and skip verify() only when they match.
### closeAdvisories trusts the contributor's self-reported head
- Location: .claude/workflows/deliver-change.js, closeAdvisories (around line 1383 and 1404)
- Why: when the closing start reports the earlier head, verify() and the security re-review are skipped, and since c5285fbabaac the same comparison clears awaiting; a start that committed code but reported the old head (for example after injection carried in advisory text) would reach package without a fresh workflow security review. The pre-push and merge gates (tools/gates.sh settled_at) still refuse a stale security pass, so nothing is bypassed in practice.
- Fix: compare the lane's actual HEAD (git rev-parse HEAD, read by a record start or taken from the checker's verdict commit) with before, not the returned head, before skipping verify() and clearing awaiting. Defense in depth only.

### closing figures are a lower bound after a resume during the closing re-review
- Location: .claude/workflows/deliver-change.js:1400 and openspec tasks 5.6 of closing-loop
- Why: the comment says final figures follow the early flush, but a resume during the closing re-review restores closed 0 left N, closeAdvisories returns at once, and awaiting and fixedInPlace are not restored, so advisories_closed stays 0 however many the re-review confirms.
- Fix: word the comment and the task as a lower bound on a resume, or record the confirmed count from the resumed re-review's fixed_in_place.

### Waiting timeout stated twice in the contributor notes
- Location: docs/contributor-notes.md:49 and .claude/agents/contributor.md:63
- Why: the Waiting section repeats the Bash timeout 600000 that package step 5 still states, and step 5 does not point to the section, so the 540 s reason is read only by chance.
- Fix: keep the timeout in one place, either step 5 pointing to docs/contributor-notes.md, Waiting, or the section dropped.
### Unclear antecedent in the merge-main notes
- Location: docs/contributor-notes.md:11
- Why: the section opens "On its conflicts", whose antecedent (merge-main) is only in contributor.md, so the notes read alone leave "its" unclear.
- Fix: write "On the conflicts of merge-main".

### Escalation triggers have no driven test
- Location: .claude/workflows/deliver-change.js:934, :935, :1326
- Why: only escalate itself is driven in tools/tools_test.sh; the three call sites (no result, self-check mismatch, second blocking quality round) are not exercised, so a removed trigger passes.
- Fix: drive contributor() with a stubbed null result and a self_check mismatch result, and reviews() with two blocking quality results, asserting escalated.

### Critical read in the queue line matches the word anywhere
- Location: .claude/workflows/deliver-change.js:1654
- Why: /critical/ matches the word in the queue line's name or reason, so a non-critical item whose reason says critical notes a spurious "plan: critical value not read", and unlike the planned-path note the note omits the unread text.
- Fix: test for critical inside the parenthesis only (for example /[(,] ?critical\b[^)]*\)/) and append the unread text as the planned-path note does.

### Skipped-plan critical note has no driven test
- Location: .claude/workflows/deliver-change.js:1654
- Why: the skipped-plan note is top-level code no test drives, nor is the planned-path note at :1674.
- Fix: move the skipped-plan critical read into a helper returning the rule or the note and drive it in tools/tools_test.sh calib_js with a read, an unread, and a no-critical queue line.

### light_plus LineNrFifth is the teal accent
- Location: carat/domain/themes.rb:482 (LIGHT_PLUS DIM 0x1f6b82, FAINT gray)
- Why: LineNrFifth maps to DIM, so in light_plus every fifth number is an accent color rather than a dim gray step.
- Fix: map LineNrFifth to a gray in light_plus or record the choice in the design.
### frame_presenter class comment leaves a short line
- Location: carat/adapters/frame_presenter.rb:57
- Why: the rewrapped class comment leaves a line ending in 'column. With' before 'indentguides' on the next line, which reads badly
- Fix: reflow lines 57 to 59 so the sentence 'With indentguides ...' continues the paragraph

### LineNrFifth has no 16-color or NO_COLOR distinction
- Location: carat/domain/themes.rb (the LineNrFifth row)
- Why: under 16 colors and NO_COLOR every fifth relative number looks like the others.
- Fix: give it a bold attribute or a basic-index accent there.

### The squash body of #223 claims styling its diff lacks
- Location: the squash commit of cursor-and-messages (#223): its Summary and Changes bullets 4 to 6
- Why: they claim command-line and message styling that the diff does not contain, so the history on main says something untrue.
- Fix: make it true with the message-styling change, which delivers that styling.
- Merged: ### Message styling claimed by 223 is not in its diff
- Location: the squash body of pull request 223 (cursor-and-messages)
- Why: it claims command-line and message styling that its diff does not contain
- Fix: make it true with the message-styling change

### The pull request text review is skipped on a resume past the package phase
- Location: .claude/workflows/deliver-change.js (prTextReview call after the package step)
- Why: it runs only in the start that packages, so a resume after the push never reviews the text; no verdict of it is recorded
- Fix: record the review's verdict (a phase or a note the run state returns) and run it on resume when none is recorded
### Text review is skipped on a resume past the package phase
- Location: .claude/workflows/deliver-change.js:1606 and :1616
- Why: the pull request text review runs only in the start that packages; a resume past the package phase skips it silently (still present, recorded instead of fixed)
- Fix: record the text review's verdict and run it on resume when none is recorded
### Findings gate docs say BASE where the code uses the fork point
- Location: tools/gates.sh:29, :505, :524
- Why: the usage line says headings at BASE, the gate_findings comment mixes the fork point with BASE..HEAD, and the failure message says present at the base, while the code reads the fork point and fork..HEAD
- Fix: say the fork point of BASE and HEAD and fork..HEAD in all three
### Design decision on findings is stale
- Location: openspec/changes/archive/2026-11-19-delivery-guards/design.md:9
- Why: the findings decision still lists headings with git grep at the base, not at the fork point of the base and HEAD
- Fix: say the fork point and that a moved main not yet merged is ignored
### Proposal docs currency
- Location: openspec/changes/archive/2026-11-19-delivery-guards/proposal.md:16 and :19
- Why: it says CLAUDE.md is unchanged at its size budget, but the branch edits its push allowance (CLAUDE.md:41), and line 16 repeats the --pr-text push twice
- Fix: say CLAUDE.md is updated, the push allowance names the text fix push, and drop the repeated clause on line 16
### Advisory fixes take two paths and an advisory-only round counts as rework (closing-loop retro 10)
- Location: `.claude/workflows/deliver-change.js` (the in-place round, `inPlaceRound` 'alone', and the closing loop at package)
- Why: closing-loop rework 2 of 3, round 2 advisory-only (note 8, 0 blocking), its rerun (tools-test 135 s, every review again) raised note 9; reviews 43,866 of 191,898 output tokens (22.9%), 57 of 233 calls; quality first pass 101 of 183.
- Fix: keep one advisory path, so an advisory-only round is never a rework round and a run starts at most one contributor for advisories; accepted when a tools-test case shows a run with advisory-only reviews records rework unchanged and starts exactly one advisory start.

### Pull request finding counts are hand-written and checked after the push (closing-loop retro 11)
- Location: `tools/open_pr.sh` (the body gate before the first push)
- Why: two counts were wrong in closing-loop's body (Changes "two non-blocking advisories" against 5 entries, 4 distinct; Testing "one advisory"), costing a body round and a second push: prtext 5,495 output tokens / 11 calls, pr_text_fixes 1, pushes 2.
- Fix: refuse before the first push a body whose finding counts differ from the run state's reviews or the findings file, or keep counts out of the body; accepted when the next runs record no prtext phase from a count.
### Grep picker reads every file synchronously when it opens
- Location: carat/plugins/finder/grep.rb, Grep#load
- Why: a large tree makes the editor wait once at open (one read_file call per file, up to 100,000 stored lines); the user's nothing-waits rule is only met by bounding it.
- Fix: stream the read as a background task once finder-streaming and plugin-tasks land after spinel-bump, searching what has arrived.
### Grep column is the first query byte, not the tightened match start
- Location: carat/plugins/finder/grep.rb, Grep#column_at
- Why: Matcher tightens the match from its end, so the highlighted span can start later than the first occurrence of the query's first byte; the cursor then lands a little early on such lines.
- Fix: expose the span start from Matcher.span_score (a second method, no extra allocation) and use it for the column.
### Grep files are searched only to their first 1000 lines
- Location: carat/plugins/finder/grep.rb, FILE_ROWS
- Why: read_file answers at most 1000 rows, so a match deeper in a long file is not found.
- Fix: a read request with a start row, a plugin API minor bump, then read the file in pages.

### Grep helper duplication with the plugin
- Location: carat/plugins/finder/grep.rb (strings, ints), carat/plugins/finder/plugin.rb (no_paths)
- Why: the typed-empty array helpers repeat across two classes of one plugin.
- Fix: one shared helper per type in the plugin directory, used by both.

### No grep scenario in the bench
- Location: bench/ (finder scenarios), carat/plugins/finder/grep.rb search
- Why: the finder bench measures paths only, so the grep search cost per key is unmeasured; the search is now bounded in memory but still scores every stored line.
- Fix: add a grep scenario to the bench and the map's Bench line.
- Merged: ### No bench scenario for the grep search
- Location: bench/ scenarios, carat/plugins/finder/grep.rb search
- Why: each key scores up to 100,000 lines and sorts every match to keep 200; the finder bench measures paths only.
- Fix: add a grep scenario and its map Bench line, or keep a bounded top-200 selection instead of a full sort.

### Findings file holds a fixed entry and a stale duplicate
- Location: docs/findings/finder-grep.md, the entries Grep helper duplication with the plugin and No bench scenario for the grep search
- Why: the duplication entry is fixed and the older bench entry (its Why still says it sorts every match) is superseded by the No grep scenario entry, so the file holds a fixed entry and a stale duplicate
- Fix: drop the fixed duplication entry and the older bench entry, keeping the new one (a grooming step, as no agent removes entries during a delivery)

### Code map Grep line omits public class methods
- Location: docs/codebase-map.md:568, the Grep line
- Why: it lists the public methods but not the class methods no_strings and no_ints (nor utf8_size), so the map is stale
- Fix: add no_strings, no_ints, and utf8_size to the method list
### Advisory fixes take two paths and an advisory-only round counts as rework (closing-loop retro 10)
- Location: `.claude/workflows/deliver-change.js` (the in-place round, `inPlaceRound` 'alone', and the closing loop at package)
- Why: closing-loop rework 2 of 3, round 2 advisory-only (note 8, 0 blocking), its rerun (tools-test 135 s, every review again) raised note 9; reviews 43,866 of 191,898 output tokens (22.9%), 57 of 233 calls; quality first pass 101 of 183.
- Fix: keep one advisory path, so an advisory-only round is never a rework round and a run starts at most one contributor for advisories; accepted when a tools-test case shows a run with advisory-only reviews records rework unchanged and starts exactly one advisory start.

### Pull request finding counts are hand-written and checked after the push (closing-loop retro 11)
- Location: `tools/open_pr.sh` (the body gate before the first push)
- Why: two counts were wrong in closing-loop's body (Changes "two non-blocking advisories" against 5 entries, 4 distinct; Testing "one advisory"), costing a body round and a second push: prtext 5,495 output tokens / 11 calls, pr_text_fixes 1, pushes 2.
- Fix: refuse before the first push a body whose finding counts differ from the run state's reviews or the findings file, or keep counts out of the body; accepted when the next runs record no prtext phase from a count.

### Mid-tier contributor returned a placeholder result
- Location: the contributor's fix start for round 2's blocking finding (tools/tools_test.sh:4304 at 76a1d047c65f)
- Why: the start returned no result ("placeholder") after committing its fix, so the workflow recorded the head as unknown and the run needed a resume; a trial breach of the schema-return rule by the mid-tier contributor (#219).
- Fix: count it against the trial; keep the schema-checked return, and have the workflow resume from the lane branch head (git rev-parse) when a start returns a placeholder.
- Merged: ### Contributor returned a placeholder instead of a result (mid-tier trial)
- Location: the contributor's last fix start of this change (head 76a1d047c65f), workflow phase implement
- Why: the contributor, on the mid tier as a trial (#219), returned the word placeholder instead of its schema result, so the workflow recorded the head as unknown and the run stopped; the fix had committed and its check stages passed, so only the return was lost.
- Fix: count it against the trial; have the workflow reject a placeholder return and re-ask for the schema, reading the head from git when the branch moved.

### Quality handler note test only greps the literal text
- Location: tools/tools_test.sh:4303
- Why: the handler case only greps the literal note text, so the order (re-raises removed before misses are noted) and that an unmarked finding is not noted go unexercised.
- Fix: move the quality blocking split into a pure helper returning the raised and missed findings and test it through speed_js.

### First-pass miss marker matches anywhere in the text
- Location: .claude/workflows/deliver-change.js:430
- Why: the marker regex matches anywhere in the text, case-sensitively, so a negation such as not a first-pass miss counts and First-pass miss does not.
- Fix: match the marker only right after the location findingAt returns, as the agent file asks, case-insensitively.

### README wording of the miss rule differs from the agent file
- Location: README.md:190
- Why: on lines the last review did not see changed is unclear and differs from the agent file; the quality step also still says the first pass reads every file of the diff to its end, while the agent file says each changed hunk with its enclosing function.
- Fix: say on lines unchanged since the last review, as .claude/agents/quality-reviewer.md:21 does, and use the agent file's reading wording.

### Marker refers to the wrong review commit
- Location: .claude/agents/quality-reviewer.md:21
- Why: that diff refers to the diff since the last passed review, while a blocked round's input names the last review's commit, blocked or passed.
- Fix: tie the marker to the commit the input names, the last quality review, as priorQuality words it.

### Whole-branch quality input lists no blocking findings
- Location: .claude/workflows/deliver-change.js:906
- Why: the agent file excludes the blocking findings its input lists, but priorQuality lists them only on the scoped path; on the whole-branch path none are listed, so the reviewer marks a still-unfixed blocking finding first-pass miss and only qualitySplit's prior filter keeps the record right.
- Fix: list the last review's blocking findings in the whole-branch input too when qualityBlocking holds them.

### Proposal still words the old miss rule
- Location: openspec/changes/archive/2026-11-19-quality-first-pass/proposal.md:9
- Why: What Changes still says lines the diff since the last review did not change and names only firstPassMiss, not that a miss is only a new finding nor the qualitySplit helper; it (and tasks.md:5) still says the first pass reads every file of the diff to its end.
- Fix: word bullets 9 to 11 as the agent file and tasks 2.1 and 2.2 do, and say each changed hunk is read with its enclosing function.

### firstPassMiss cases duplicate each other
- Location: tools/tools_test.sh:4301
- Why: the firstPassMiss case at 4301 and the marker case at 4305 both prove a marked finding counts.
- Fix: fold the unmarked case of 4301 into the 4305 case and drop 4301.

### Task 1.2 names a test that does not exist
- Location: openspec/changes/archive/2026-11-19-quality-first-pass/tasks.md:6
- Why: task 1.2 names a test, a blocking quality finding on unchanged lines is noted as a first-pass miss, that tools/tools_test.sh does not contain.
- Fix: name the existing tests (a first-pass miss is noted only for a new marked finding; the quality handler notes first-pass misses only when the prior list is the last review's).

### The known argument of the quality handler is derived inline and untested
- Location: .claude/workflows/deliver-change.js:1207
- Why: the commit of review.quality equal to qualityAt is derived inline in the handler and never run by a test, so the resumed-without-notes case is unproven.
- Fix: compute it in a small pure helper over ran and qualityAt and test it through speed_js.

### One-use alias of split.raised
- Location: .claude/workflows/deliver-change.js:1209
- Why: const raised = split.raised is a one-use alias.
- Fix: concat split.raised directly.

### An advisory-only fix round re-runs every review (sprint-19-records retro 5)
- Location: `.claude/workflows/deliver-change.js` (the fix-in-place round's re-review); joins the queued `rework-review-repeat` (backlog Pool 21).
- Why: sprint-19-records spent rework 1 on 4 advisory findings and 0 blocking, 1 fixed in place and 3 recorded; the second round re-ran check (passed), security (0 findings), and quality (0 blocking, 3 advisory); reviews took 13,756 of 34,522 output tokens (40%) and 27 of 69 tool calls (39%), as on sprint-17-records (30,387 of 72,515, 42%) and sprint-18-records (25,498 of 86,421, 30%), both rework 2.
- Fix: a round that fixes only advisory text in the change's own OpenSpec files does not re-run security and quality on the unchanged rest of the diff. Accepted when such a run records no second security and quality start and records-change rework drops to 0.

### The benchmark starts on a docs-only change for want of a recorded measurement (sprint-19-records retro 6)
- Location: `.claude/workflows/deliver-change.js` (the benchmark phase's start condition); joins the queued `bench-skip-no-code` (backlog Pool 26).
- Why: sprint-19-records' benchmark spent 3,513 output tokens and 5 calls (10% of output) on a docs-only diff, building base and change only to report no difference, started because build/metrics was missing; sprint-17-records 4,147 / 6, sprint-18-records 4,721 / 14; bench passes first 177 of 178.
- Fix: a change touching no file under carat/, bin/, test/, or bench/ starts no benchmark agent and carries its bench result as equal. Accepted when a docs-only or records-only run records no benchmark start.

- quality advisory, docs/backlog.md:8596, stale entry: the folded 'guide-colors retro entries are folded twice' note cites old line numbers and is half resolved, since this groom removed the advisory-only copies while 'The merge phase spends output out of proportion to its calls' (:8372, :8386) and 'A passing check phase costs a full agent start' (:8377, :8391) stay duplicated. Fix: list :8386 and :8391 as duplicate and this note as fixed in the next groom.txt.
- quality advisory, docs/backlog.md:8383 and :8402, the two SECURITY_MARK security entries stay open although docs/queue-feature.md's Sprint 20 notes say b5b0aec (#214) fixed them and the folded entry at :8604 asks to close them. Fix: list both as fixed by b5b0aec in the next groom.txt after checking its tools-test cases.
- quality advisory, docs/backlog.md:8555, :8574, :8619, format: folded headings follow the previous entry's Fix line with no blank line, the fold defect the entry at :8608 already records. Fix: have groom put a blank line before each folded heading (groom-fold-format) and fold this into that entry.

### Replace mode cannot be entered, so its fold opening has no test
- Location: carat/use_cases/arrange_view.rb (typing), carat/domain/mode.rb REPLACE
- Why: no key or handler enters Mode::REPLACE (R is unbound), so the replace branch that opens closed folds cannot be proved by a table row; the quality advisory asked for zfjRX<Esc>.
- Fix: when R is implemented, add the row zfjRX<Esc> expecting [[0, 1, false]] and the lines X b c d e.
### Extra push allowed by push --pr-text without a blocked text review
- Location: tools/run_state.sh:1327
- Why: `push --pr-text` only checks that the recorded push differs from HEAD, and agent_guard.sh lets the contributor pass `--pr-text` at any time, so a contributor gets one more push per run even when no pull request text review blocked, loosening the push-count rule. The merge gates still run on every head, so no unreviewed code reaches main. This came in with the merge of main (#224), not with this change's commit. Security Low, confidence 4.
- Fix: Have the workflow write a run-state marker (for example `pr_text_blocked`) when the text review blocks, make `push --pr-text` refuse unless it is set, clear it after the push, and add expect cases in tools/tools_test.sh.

### Replace mode opening closed folds has no test row
- Location: carat/use_cases/arrange_view.rb:58
- Why: replace mode now opens the closed folds holding the cursor, but only insert mode has a test row; R is unbound in normal mode and Mode::REPLACE cannot be entered, so it cannot be tested yet (quality advisory, tests beside behavior).
- Fix: add the table row `zfjRX<Esc>` expecting [[0, 1, false]] and the lines `X b c d e` once R is implemented.

### close_tab walks the tab page's slots twice
- Location: carat/domain/buffer_list.rb:408
- Why: close_tab collects the kept view windows' buffers (lines 407-412) and again walks the slots in drop_slot_folds (line 413), a duplication (quality advisory).
- Fix: drop each kept view window's folds in the existing loop and call drop_slot_folds only from close_window.

### Slot#clear forgets a kept hidden view window without dropping its folds
- Location: carat/domain/slot.rb:102
- Why: Slot#clear, also run by attach, forgets a kept hidden view window without drop_folds, so a plugin closing or replacing a hidden side window leaves its fold list tracked by the buffer (spec currency: windows, closing a window drops its folds; quality advisory).
- Fix: drop the kept window's folds before clear forgets it (in BufferList or the caller), with a test like the :tabclose slot assertion.
### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)

- Location: `carat/plugins/finder/plugin.rb:186`
- Why: In this change: the grep picker reads every listed file synchronously on the editor thread when it opens (up to MAX_FILES files of up to READ_LIMIT bytes each). Pressing <leader>fg in a very large or hostile repository can freeze the editor for a long time; it is a local denial of service that only the user can trigger.
- Fix: Cap the total bytes read across files (stop when MAX_LINES fills or a byte budget is spent), read only what FILE_ROWS needs, or load in steps between keys so Esc stays responsive.

### The new --pr-text push kind accepts any commit, as long as a recorded (sprint-20 review security Low (3), run_state.sh:1330)

- Location: `tools/run_state.sh:1330`
- Why: In this change: the new --pr-text push kind accepts any commit, as long as a recorded push other than HEAD exists; it does not check that the commit only rewrites pr.md. Because RECORDS_RE exempts all of openspec/ and docs/goals.md from a new review, this adds one more push after review whose records-path content nobody reviews (specs, or the goals that drive tier routing).
- Fix: In push_branch --pr-text, require that git diff --name-only <pushed> HEAD lists only openspec/changes/archive/*-<change>/pr.md, and add a tools_test.sh expect case for a refused wider diff.

### Docs drift (sprint-20 review quality, CLAUDE.md:41)

- Location: `CLAUDE.md:41`
- Why: docs drift: 'Push once, plus one per CI fix, review fix, moved main, text fix' reads as one push per review fix, moved main, and text fix, while run_state.sh push allows one of each of those three a run and one per CI fix
- Fix: 'plus one per CI fix and one review-fix, moved-main, and text-fix push a run'

### Unclear mode (sprint-20 review quality, contributor.md:83)

- Location: `.claude/agents/contributor.md:83`
- Why: unclear mode: body mode is written only for a red CI scan plus a terse '(--pr-text: text)', while the pull request text review's rewrite reaches the contributor through this mode and only the workflow prompt (deliver-change.js:1262) describes it
- Fix: add one sentence for the text-review rewrite (claims only what the diff holds, pushed with --pr-text, not --ci-fix)

### Comment drift (sprint-20 review quality, gates.sh:30)

- Location: `tools/gates.sh:30`
- Why: comment drift: the header says the findings gate compares headings 'at BASE', but gate_findings compares the merge-base fork point (line 517), and its comment line 505 overruns the wrap
- Fix: name the fork point in the header and rewrap lines 504 to 509

### Brittle snapshot (sprint-20 review quality, use_cases_toggle_reading.rb:88)

- Location: `test/use_cases_toggle_reading.rb:88`
- Why: brittle snapshot: the label interpolates raw highlight ids (test/use_cases_toggle_reading.rb.expected:4 prints [2, 5, 112]), so adding a highlight group churns an unrelated snapshot
- Fix: print the span's group through Highlight.name_of instead of its numeric id

### Gh pr list/view/edit --head BRANCH also match a fork's pull request of (sprint-20 sweep security Low (5), open_pr.sh:196)

- Location: `tools/open_pr.sh:196`
- Why: gh pr list/view/edit --head BRANCH also match a fork's pull request of the same branch name, so open-pr with PR_TOKEN can edit the fork's title and body instead of opening ours, or be blocked by it
- Fix: list with --json number,isCrossRepository, keep only same-repository pull requests, and view or edit by number

### Actions/checkout is pinned by the mutable tag v4 in the job that holds (sprint-20 sweep security Low (4), open-pr.yml:46)

- Location: `.github/workflows/open-pr.yml:46`
- Why: actions/checkout is pinned by the mutable tag v4 in the job that holds PR_TOKEN (also ci.yml, main.yml, scan.yml, actions/cache), so a moved tag runs foreign code beside the token
- Fix: pin every action by full commit hash with the tag in a comment

### Checkout keeps the default persist-credentials, leaving the read-only (sprint-20 sweep security Low (3), ci.yml:36)

- Location: `.github/workflows/ci.yml:36`
- Why: checkout keeps the default persist-credentials, leaving the read-only GITHUB_TOKEN in .git/config while later steps run the pull request's code (main.yml:34 likewise)
- Fix: set persist-credentials: false, the scope step already gets GH_TOKEN through env

### The project .caratrc is checked with lstat and then opened by path (sprint-20 sweep security Low (3), rc_config_gateway.rb:61)

- Location: `carat/adapters/rc_config_gateway.rb:61`
- Why: the project .caratrc is checked with lstat and then opened by path (DiskFiles#read follows links), so a link swapped in between escapes the link refusal
- Fix: open untrusted files with O_NOFOLLOW and judge the opened descriptor's stat

### The normal-mode count has no upper bound (sprint-20 sweep quality, command_grammar.rb:98)

- Location: `carat/domain/command_grammar.rb:98`
- Why: the normal-mode count has no upper bound: digit grows count*10 on every typed digit and take multiplies operator_count*count (line 186), so a long run of digits overflows the integer, while RegisterCount and SubstituteArgs cap ex counts at MAX_COUNT
- Fix: cap the count as they do (stop growing past 1_000_000_000 and clamp the product in take), with a domain_grammar row for a 20-digit count

### HEADER names 24 columns (sprint-20 sweep quality, run_state.sh:484)

- Location: `tools/run_state.sh:484`
- Why: HEADER names 24 columns (advisories_closed, advisories_left added) but the committed header rows of docs/metrics-feature.tsv:1 and docs/metrics-backlog.tsv:1 still name 22, and history appends rows only to existing files, so the files' header and their newest rows disagree
- Fix: append the two column names to both header rows

### Duplicates Options#tab_width (sprint-20 sweep quality, dispatcher.rb:114)

- Location: `carat/use_cases/dispatcher.rb:114`
- Why: duplicates Options#tab_width (tabstop > 0 ? tabstop : 8), as do arrange_view.rb:50, insert_tab.rb:25, leave_insert.rb:71, repeat_last.rb:105, and adapters/frame_presenter.rb:236, and Options.width_problem already keeps tabstop at 1 or more, so the fallback is dead
- Fix: call state.options.tab_width at each site

### The clear_message inside the list_message? branch is redundant (sprint-20 sweep quality, handle_key.rb:237)

- Location: `carat/use_cases/handle_key.rb:237`
- Why: the clear_message inside the list_message? branch is redundant: line 240 clears the message unconditionally
- Fix: keep only the early return for CR and Space in that branch

### The magic numbers 40 and 44 stand for (sprint-20 sweep quality, handle_key.rb:391)

- Location: `carat/use_cases/handle_key.rb:391`
- Why: the magic numbers 40 and 44 stand for ( and ,
- Fix: name them (a private_constant list of signature trigger codes) as the comment above describes them

### Unsaved_buffer calls ControlText.caret with no require_relative of (sprint-20 sweep quality, messages.rb:21)

- Location: `carat/domain/messages.rb:21`
- Why: unsaved_buffer calls ControlText.caret with no require_relative of control_text, so it compiles only through carat.rb's order, unlike every other domain file, which requires what it names
- Fix: add require_relative "control_text"

### Bind_text accepts a key-sequence value without parsing it (sprint-20 sweep quality, keymap.rb:199)

- Location: `carat/domain/keymap.rb:199`
- Why: bind_text accepts a key-sequence value without parsing it, so a bad sequence in a configuration line is reported only when pressed (HandleKey 'Bad mapping', handle_key.rb:367), never as file:line at load as every other configuration problem is
- Fix: parse the value with KeyNotation.parse in apply when it is not an action name and return its error

### Each active change's iteration runs rm -rf on build/spec-preview (sprint-20 sweep quality, spec_validate.sh:25)

- Location: `tools/spec_validate.sh:25`
- Why: each active change's iteration runs rm -rf on build/spec-preview, so an earlier change's failed preview is deleted by the next one while its message says the preview is in build/spec-preview
- Fix: preview each change under build/spec-preview/NAME

### The generated header of default_config.rb (sprint-20 sweep quality, carat-gen-config.rb:32)

- Location: `bin/carat-gen-config.rb:32`
- Why: the generated header of default_config.rb (and registry_source.rb:57 for registry.rb) says to run spin run carat-gen-config, while CLAUDE.md and the map name make gen-config, the one way
- Fix: write make gen-config in both headers and regenerate

### Language? tests setting == ROOTED_SETTING twice in a row (sprint-20 sweep quality, config.rb:219)

- Location: `carat/domain/config.rb:219`
- Why: language? tests setting == ROOTED_SETTING twice in a row (lines 219 and 223)
- Fix: one if block checking the word count and then the root

### FloatLayer#close drops a float without dropping its folds. A zf in a (sprint-20 sweep quality, float_layer.rb:76)

- Location: `carat/domain/float_layer.rb:76`
- Why: FloatLayer#close drops a float without dropping its folds. A zf in a focused float (Operate#fold goes through state.window, which is the focused float) leaves a fold list the buffer keeps tracking and shifting after :q, float.close, or :tabclose. This breaks the windows spec rule that closing a window drops its folds
- Fix: call window.drop_folds on the float's window before delete_at in close (BufferList#close_tab should do the same for the page's floats), and add an editor_folds row that runs zf in a float, closes it, and expects fold_lists to be empty

### And carat/use_cases/repeat_last.rb (sprint-20 sweep quality, operate.rb:233)

- Location: `carat/use_cases/operate.rb:233`
- Why: and carat/use_cases/repeat_last.rb:117 duplication: each private clamp(state, row, col) restates EditorState#clamp_col (carat/domain/editor_state.rb:100)
- Fix: delete both helpers and call state.clamp_col(row, col), as PutOverSelection and GlobalCommand already do

### Carat/use_cases/arrange_view.rb (sprint-20 sweep quality, repeat_last.rb:105,)

- Location: `carat/use_cases/repeat_last.rb:105,`
- Why: carat/use_cases/arrange_view.rb:50, carat/use_cases/leave_insert.rb:71, carat/use_cases/insert_tab.rb:25, carat/use_cases/dispatcher.rb:114 duplication: each restates the fallback 'tabstop > 0 ? tabstop : 8', which Options#tab_width (carat/domain/options.rb:135) already provides and PutOverSelection uses
- Fix: replace each with options.tab_width

### Carat/use_cases/ex/buffer_command_handler.rb (sprint-20 sweep quality, tab_command_handler.rb:102,)

- Location: `carat/use_cases/ex/tab_command_handler.rb:102,`
- Why: carat/use_cases/ex/buffer_command_handler.rb:102, carat/use_cases/ex/history_command_handler.rb:61 duplication (shared logic belongs in the domain, architecture 5): three copies of the same ASCII-digits predicate digits?
- Fix: keep one domain function (for example ExGrammar.digits? beside letter?) and call it from the three handlers

### Carat/use_cases/ex/buffer_command_handler.rb (sprint-20 sweep quality, tab_command_handler.rb:45,)

- Location: `carat/use_cases/ex/tab_command_handler.rb:45,`
- Why: carat/use_cases/ex/buffer_command_handler.rb:79, carat/use_cases/ex/lsp_start_command_handler.rb:27, carat/use_cases/ex/lsp_restart_command_handler.rb:26, carat/domain/substitute_args.rb:89, carat/domain/register_count.rb:62 duplication: six places build the literal 'E488: Trailing characters: ...', while E16 and invalid_argument live in Domain::Messages
- Fix: add Messages.trailing_characters(text) and call it from all six

### Duplication (sprint-20 sweep quality, quit.rb:87)

- Location: `carat/use_cases/files/quit.rb:87`
- Why: duplication: beside_side_windows? restates BufferList#lone_file_window? (carat/domain/buffer_list.rb:491) plus a scratch check, and lone_file_window? reads only the TabPage it is given
- Fix: move it to TabPage#lone_file_window? and use it from Quit (with !state.buffer.scratch?), DeleteBuffer, and BufferList#close_windows_of

### Carat/domain/undo_tree.rb (sprint-20 sweep quality, buffer_list.rb:382,)

- Location: `carat/domain/buffer_list.rb:382,`
- Why: carat/domain/undo_tree.rb:111, carat/use_cases/ex/ex_table.rb:86, carat/domain/window.rb:182 public helpers used only inside their own class: drop_slot_folds, head_of, handler_at, and scroll_folded have no outside caller
- Fix: move them under private (BufferList and UndoTree already have private sections) and drop scroll_folded from the area 11 map entry

### Map drift (sprint-20 sweep quality, codebase-map.md:362)

- Location: `docs/codebase-map.md:362`
- Why: map drift: the area 11 Window entry leaves out open_cursor_folds (carat/domain/window.rb:117, added in #225 and called by ArrangeView and RepeatLast), and the Folds entry at line 394 leaves out folded?, which every fold path checks first
- Fix: add both to their entries

### Operate keeps per-call state in @notice (sprint-20 sweep quality, operate.rb:46)

- Location: `carat/use_cases/operate.rb:46`
- Why: Operate keeps per-call state in @notice: search_motion sets it and call resets it, so a use case built once in EditorAssembly carries a mutable result between private methods
- Fix: return the search outcome with the motion (for example a small result value, or operand returning the failure Outcome) and drop the instance variable

### Column_at puts the cursor on the line's first byte equal to the query's (sprint-20 sweep quality, grep.rb:137)

- Location: `carat/plugins/finder/grep.rb:137`
- Why: column_at puts the cursor on the line's first byte equal to the query's first byte, not on the start of the match Matcher scored (span_score tightens to a later span), so 'abc' over 'a = x; abc' opens at column 0, away from the hit; the file-finder spec encodes the same weak rule
- Fix: answer the tightened span's start from Matcher (a span_start beside span_score), amend the spec's picking requirement, and add a test row where the first occurrence precedes the match

### The file finder builds its empty lists with Grep.no_strings (sprint-20 sweep quality, plugin.rb:70)

- Location: `carat/plugins/finder/plugin.rb:70`
- Why: the file finder builds its empty lists with Grep.no_strings (lines 70, 196, 296, 350), so the path picker depends on the grep index for a typed-empty-array helper
- Fix: move no_strings and no_ints to a neutral place in the finder (Matcher or a small helper module) or build them locally

### The action descriptions of plugin.finder.next, previous, open_split, (sprint-20 sweep quality, plugin.rb:89)

- Location: `carat/plugins/finder/plugin.rb:89`
- Why: the action descriptions of plugin.finder.next, previous, open_split, open_vsplit, and open_tab still say 'file' though they now also move over and open the grep picker's line rows
- Fix: say 'row' (the highlighted row) in the manifest and the matching docs/actions.md rows

### The default scenario list, documented as every scenario when none is (sprint-20 sweep quality, run.sh:69)

- Location: `bench/run.sh:69`
- Why: the default scenario list, documented as every scenario when none is named, omits lh-float, lh-winbar, n, and palette from bench/keys.rb SCENARIOS (named in the Bench lines of map areas 5, 6, and 13), so make bench without SCENARIOS silently skips them; a second hand-kept list of names drifts
- Fix: have bench/keys print its scenario names (a --list argument) and loop over that, removing the list from run.sh

### Tree takes positional constructor arguments (sprint-20 sweep quality, tree.rb:23)

- Location: `carat/plugins/explorer/tree.rb:23`
- Why: Tree takes positional constructor arguments (root, show_hidden, ignore) while CLAUDE.md Coding conventions requires required keywords for behavior classes; test/lint.rb:1195 exempts carat/plugins/ from the constructor rule, which CLAUDE.md does not say
- Fix: initialize(root:, show_hidden:, ignore:) with a keyword signature at its one call site (explorer/plugin.rb:488), or document the plugin exemption in CLAUDE.md

### Cut_point and carat/domain/markdown_text.rb (sprint-20 sweep quality, process_runner.rb:155)

- Location: `carat/drivers/process_runner.rb:155`
- Why: cut_point and carat/domain/markdown_text.rb:366 (gather) each walk back over UTF-8 continuation bytes to cut text before a character, while Domain::Utf8 holds only the forward boundary
- Fix: add one Utf8 helper (the largest offset at or below a limit that splits no character, at most three bytes back) and use it in both

### The matcher.rb entry lists score, span_score, key, and index_of, but (sprint-20 sweep quality, codebase-map.md:569)

- Location: `docs/codebase-map.md:569`
- Why: the matcher.rb entry lists score, span_score, key, and index_of, but Matcher.lower is now called from grep.rb (lines 140, 142) as part of its surface
- Fix: list lower in the map entry

### FixedInPlace (sprint-20 sweep quality, deliver-change.js:1374)

- Location: `.claude/workflows/deliver-change.js:1374`
- Why: fixedInPlace (and awaiting) are never restored by seed, so a run resumed after an advisory was confirmed fixed in place, or stopped during the closing loop's re-review, hands every such advisory to the package step as open (handOver, line 876) and keeps closingFigures at 0 closed, N left (closeAdvisories returns at line 1426)
- Fix: record each confirmed fix as a run-state note in confirmInPlace and rebuild fixedInPlace from those notes in seed, then recompute closingFigures after the resumed verify, with a tools_test.sh js case for the resume

### And docs/metrics-backlog.tsv (sprint-20 sweep quality, metrics-feature.tsv:1)

- Location: `docs/metrics-feature.tsv:1`
- Why: and docs/metrics-backlog.tsv:1 the committed headers still hold 22 columns while tools/run_state.sh:484 HEADER and the rows written since closing-loop hold 24 (advisories_closed, advisories_left); history only writes HEADER to a new file (line 2164), so the lane histories drift from the header the code documents
- Fix: append the two column names to both headers, or have history rewrite a shorter header line

### Keymap#bind has no caller in carat/, bin/, test/, or bench/ yet is (sprint-20 sweep quality, keymap.rb:223)

- Location: `carat/domain/keymap.rb:223`
- Why: Keymap#bind has no caller in carat/, bin/, test/, or bench/ yet is named in docs/codebase-map.md area 5; dead code
- Fix: remove bind and its map mention (bind_owned covers it)

### Apply is public but only add_lines and add_checked call it, and the (sprint-20 sweep quality, keymap.rb:173)

- Location: `carat/domain/keymap.rb:173`
- Why: apply is public but only add_lines and add_checked call it, and the map's keymap line lists neither apply, bind_text, holder_of, leader_problem, nor no_actions
- Fix: move apply under private and name the public helpers in docs/codebase-map.md area 5

### The walk from root (sprint-20 sweep quality, keymap.rb:246)

- Location: `carat/domain/keymap.rb:246`
- Why: the walk from root(mode) along codes is written four times (holder_of, node_at, lookup, unbind), and lookup inserts an empty root for an unbound mode
- Fix: have lookup and holder_of walk through node_at (which already answers an empty node) and keep one loop

### Tabstop > 0 ? tabstop (sprint-20 sweep quality, dispatcher.rb:114)

- Location: `carat/use_cases/dispatcher.rb:114`
- Why: tabstop > 0 ? tabstop : 8 repeats Options#tab_width (carat/domain/options.rb:135), as do repeat_last.rb:105, arrange_view.rb:50, insert_tab.rb:25, leave_insert.rb:71, operators.rb:172/251/272, and display_width.rb:57
- Fix: call state.options.tab_width (or pass it) at each site

### Step calls state.clear_message twice when a list message shows (sprint-20 sweep quality, handle_key.rb:237)

- Location: `carat/use_cases/handle_key.rb:237`
- Why: step calls state.clear_message twice when a list message shows (lines 237 and 240)
- Fix: drop the first call and keep the early return for CR and Space

### The signature trigger compares code with the bare numbers 40 and 44 (sprint-20 sweep quality, handle_key.rb:391)

- Location: `carat/use_cases/handle_key.rb:391`
- Why: the signature trigger compares code with the bare numbers 40 and 44
- Fix: name them (a private SIGNATURE_TRIGGERS constant or Key constants for ( and ,)

### Csi_key repeats ss3_key's mapping of the finals A, B, C, D, H, F, P, Q, (sprint-20 sweep quality, key_decoder.rb:148)

- Location: `carat/adapters/key_decoder.rb:148`
- Why: csi_key repeats ss3_key's mapping of the finals A, B, C, D, H, F, P, Q, R, S
- Fix: have csi_key handle 126 through tilde_key and fall back to ss3_key(final) for the rest

### Pump writes handle (sprint-20 sweep quality, input_controller.rb:134)

- Location: `carat/adapters/input_controller.rb:134`
- Why: pump writes handle(state, @decoder.feed(bytes)) twice around the start screen's dismissal
- Fix: dismiss when showing, remember it, and return handle(...) || dismissed once

### Accept_visual repeats accept's opening (sprint-20 sweep quality, command_grammar.rb:158)

- Location: `carat/domain/command_grammar.rb:158`
- Why: accept_visual repeats accept's opening (the want reset to :cancel, remember, and the :search branch to :prompt)
- Fix: share one private prologue that both call before their mode-specific part

### And carat/domain/text_objects.rb (sprint-20 sweep quality, runs.rb:18)

- Location: `carat/domain/runs.rb:18`
- Why: and carat/domain/text_objects.rb:86 name a character class cls, which the CLAUDE.md naming rule gives as its example of an unclear abbreviation (char_class, not cls)
- Fix: rename to char_class

### Match_at turns a RegexpError or ArgumentError from the engine into (sprint-20 sweep quality, search.rb:116)

- Location: `carat/domain/search.rb:116`
- Why: match_at turns a RegexpError or ArgumentError from the engine into budget.stop, so a pattern the engine rejects is reported as a search stopped by the budget
- Fix: record the error on the hit (SearchHit.refused with the engine's message) instead of stopping the budget

### The hints read only the editor keymap (sprint-20 sweep quality, show_key_hints.rb:63)

- Location: `carat/use_cases/discovery/show_key_hints.rb:63`
- Why: the hints read only the editor keymap (@keymap.node_at), while HandleKey#lookup (handle_key.rb:213) answers first from a scratch buffer's own keymap, so a prefix the buffer's keymap binds shows no hints or the editor keymap's children for the same keys
- Fix: look the node up in state.buffer.keymap first when it holds the prefix, as lookup does, with an editor_key_hints row for a scratch-buffer prefix

### Palette_add_plugin is a one-line private wrapper over @palette.add (sprint-20 sweep quality, open_palette.rb:72)

- Location: `carat/use_cases/discovery/open_palette.rb:72`
- Why: palette_add_plugin is a one-line private wrapper over @palette.add called from one place
- Fix: inline it in add_plugin_actions

### Duplication (sprint-20 sweep quality, repeat_last.rb:116)

- Location: `carat/use_cases/repeat_last.rb:116`
- Why: duplication: the private clamp repeats EditorState#clamp_col (editor_state.rb:100) line for line
- Fix: call state.clamp_col(row, col) at :102, :107, :112 and drop clamp

### Duplication (sprint-20 sweep quality, repeat_last.rb:105)

- Location: `carat/use_cases/repeat_last.rb:105`
- Why: duplication: re-derives the tab width (tabstop > 0 ? tabstop : 8) although Options#tab_width exists (options.rb:135), as do dispatcher.rb:114, leave_insert.rb:71, arrange_view.rb:50, insert_tab.rb:25
- Fix: use state.options.tab_width in each

### Dead code (sprint-20 sweep quality, undo_tree.rb:173)

- Location: `carat/domain/undo_tree.rb:173`
- Why: dead code: undo_seq has no caller anywhere (the comment at :185 says callers check it, but they use undo_path), and redo_seq (:179) is used only by test/domain_undo_tree.rb
- Fix: remove undo_seq, reword the :185 comment, and drop it from the area 9 map line (or test redo_seq through head_of(current))

### Duplication (sprint-20 sweep quality, history_command_handler.rb:61)

- Location: `carat/use_cases/ex/history_command_handler.rb:61`
- Why: duplication: digits? is defined again privately in buffer_command_handler.rb:102 and tab_command_handler.rb:102, and this public class method is used only in its own file
- Fix: one shared helper (a protected ExHandler method or an ex concern) and remove the three copies

### Consistency (sprint-20 sweep quality, history_command_handler.rb:74)

- Location: `carat/use_cases/ex/history_command_handler.rb:74`
- Why: consistency: the literal E474 message sits beside Domain::Messages.invalid_argument at :88 and repeats messages_command_handler.rb:27
- Fix: add one E474 message to Domain::Messages and use it in both handlers

### Dead requires (sprint-20 sweep quality, last_change.rb:2)

- Location: `carat/domain/last_change.rb:2`
- Why: dead requires: position (:2) and display_width (:5) are required but no Position or DisplayWidth is named in the file
- Fix: drop both require_relative lines

### Naming (sprint-20 sweep quality, last_change.rb:175)

- Location: `carat/domain/last_change.rb:175`
- Why: naming: the predicate resumed? has side effects (clears next_visual, starts a new mode.insert change, sets recording)
- Fix: split it into a command that resumes after an arrow key and a plain predicate, or rename it to a command listed in BOOL_COMMANDS

### Map drift (sprint-20 sweep quality, codebase-map.md:306)

- Location: `docs/codebase-map.md:306`
- Why: map drift: the LastChange method list omits unmeasure and split, which dispatcher.rb:117 and :103 call
- Fix: add both to the area 9 line

### Design (sprint-20 sweep quality, walk_history.rb:32)

- Location: `carat/use_cases/history/walk_history.rb:32`
- Why: design: per-call scratch counters @gone, @back, @empty_before live on the one shared WalkHistory instance, reset in start and read in finish, so a nested or reentrant walk would corrupt them
- Fix: keep them in a small Struct record built in call and passed to step and finish

### Map drift (sprint-20 sweep quality, codebase-map.md:331)

- Location: `docs/codebase-map.md:331`
- Why: map drift: the area 10 Flow says VisualModeHandler runs SwapVisualEnds and ExtendVisual and SelectionHandler runs one use case per operator, but SwapVisualEnds runs from SelectionHandler (selection_handler.rb:113), ExtendVisual from TextObjectHandler, and d, y, c, >, < from OperatorHandler (operator_handler.rb:44-48)
- Fix: rewrite the Flow sentence and list text_object_handler and operator_handler as callers

### Map drift (sprint-20 sweep quality, codebase-map.md:336)

- Location: `docs/codebase-map.md:336`
- Why: map drift: the Selection method list omits numbered_delete?, line_start, and as, which the visual use cases call
- Fix: add them to the area 10 line

### Duplication (sprint-20 sweep quality, selection_cut.rb:30)

- Location: `carat/domain/selection_cut.rb:30`
- Why: duplication: the block's top-left column, block.span(buffer.line(block.top), tabstop).from followed by a clamped move, is computed again in yank_selection.rb:39, shift_selection.rb:22, change_selection.rb:53, and put_over_selection.rb:39
- Fix: one Block method (e.g. left_col(buffer, tabstop)) used by all five

### Dead require (sprint-20 sweep quality, extend_visual.rb:6)

- Location: `carat/use_cases/visual/extend_visual.rb:6`
- Why: dead require: display_width is required but DisplayWidth is never named in the file
- Fix: drop the require_relative line

### Misleading flag (sprint-20 sweep quality, selection_handler.rb:81)

- Location: `carat/use_cases/actions/selection_handler.rb:81`
- Why: misleading flag: every variant is registered with repeat: true, including swap_ends, swap_corner, and yank_lines, which never change text; only the dispatcher's edit check (dispatcher.rb:142) keeps them out of the dot command, while action_handler.rb:15 documents repeat as a change the dot command repeats; also drop the historical 'as before' in the :66 comment
- Fix: pass repeat per variant, false for the swaps and the yank

### Untested behavior (sprint-20 sweep quality, yank_selection.rb:28)

- Location: `carat/use_cases/visual/yank_selection.rb:28`
- Why: untested behavior: the E354 refusal of a visual yank into a read-only register, and of a visual change (change_selection.rb:32), has no test (test/editor_registers.rb:136-140 cover normal yank, visual delete, and normal change), nor has the Not implemented outcome of a visual.* key outside a visual mode (selection_handler.rb:96)
- Fix: add table rows to test/editor_visual.rb or test/editor_registers.rb

### Duplication (sprint-20 sweep quality, show_hover.rb:76)

- Location: `carat/use_cases/docs/show_hover.rb:76`
- Why: duplication: the cursor-float placement (screen row, room below and above, up when below lacks rows, height clamp, FloatSpec row -(height+2) or 1) is copied line for line in carat/use_cases/definitions/open_definition_float.rb:32
- Fix: let ShowHover open its float through the one placement (OpenDefinitionFloat renamed OpenCursorFloat, or a Domain::FloatWindow helper returning the spec) and drop the copy

### Duplication (sprint-20 sweep quality, json_rpc_language_gateway.rb:1116)

- Location: `carat/adapters/json_rpc_language_gateway.rb:1116`
- Why: duplication: UTF-16 to UTF-8 conversion lives three times, utf16_offset (1116) and utf16_length (1162) here and column_of in carat/use_cases/definitions/visit_target.rb:204, each re-deriving the 0xF0 two-unit rule
- Fix: one domain helper (Domain::Utf8 units_of and offset_of_units, or a Utf16 module) used by the gateway and VisitTarget, with its own table test

### Public method used only inside the class (sprint-20 sweep quality, json_rpc_language_gateway.rb:281)

- Location: `carat/adapters/json_rpc_language_gateway.rb:281`
- Why: public method used only inside the class: listed(uri) is called only by diagnostics (275) and apply (1260)
- Fix: move it below private

### Misleading contract (sprint-20 sweep quality, process_runner.rb:71)

- Location: `carat/drivers/process_runner.rb:71`
- Why: misleading contract: write answers true after the writer thread has already stopped on a broken pipe (drain breaks silently at 243), so the gateway's crash-on-failed-write in deliver (json_rpc_language_gateway.rb:1482) fires only for a stopped handle and the outbox keeps growing until the reader's exit message arrives
- Fix: have drain mark the handle closed when write_bytes fails (or document that a broken input is reported only through the exit message and drop the gateway comment)

### Find_pair bounds the search by window.top + window.height buffer lines, (sprint-20 sweep quality, frame_presenter.rb:1203)

- Location: `carat/adapters/frame_presenter.rb:1203`
- Why: find_pair bounds the search by window.top + window.height buffer lines, which under a closed fold is not the range the window shows: a partner drawn below a fold is never matched and hidden folded rows are scanned
- Fix: bound it by the last buffer row the window shows (the fold-aware bottom ArrangeView computes) and add a MatchParen row with a fold to test/adapters_frame_presenter.rb

### Coupling (sprint-20 sweep quality, plugin.rb:70)

- Location: `carat/plugins/finder/plugin.rb:70`
- Why: coupling: the plugin builds its own typed empty lists through Grep.no_strings (70, 195, 296, 350), and Grep exposes the general helpers no_strings, no_ints, and utf8_size as public class methods of the content index
- Fix: give the plugin its own private typed-empty helper (or one small Finder module both require) and make Grep's helpers private

### Stale descriptions (sprint-20 sweep quality, plugin.rb:89)

- Location: `carat/plugins/finder/plugin.rb:89`
- Why: stale descriptions: plugin.finder.next, previous, open_split, open_vsplit, and open_tab say file, but the same actions move and open grep lines on <leader>fg
- Fix: describe them as the highlighted row or match (and the rows in docs/actions.md)

### Map drift (sprint-20 sweep quality, codebase-map.md:543)

- Location: `docs/codebase-map.md:543`
- Why: map drift: PluginApi::Paths lists normalize, join, dirname, basename, relative, inside? but not absolute (used by VisitTarget and GitSigns) or segments; line 549 PluginHost omits follow_prompt, flush, describe, action_names, reason; line 643 FakeProcesses omits script, which the git tests use
- Fix: add the missing names to the three entries
