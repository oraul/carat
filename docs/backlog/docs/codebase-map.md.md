# Backlog: docs/codebase-map.md

## The delivered-changes list stops at pull request 46

- Where: the Delivered changes list closing `docs/codebase-map.md`, whose last numbered line is `#46 buffer-search`: lines 623 to 625 list `pipeline-speed`, `pipeline-speed-b`, and `pipeline-speed-c` without their numbers (#48, #49, #51), and #47, #50, and #52 to #82 are missing. Periodic quality advisories at 598cf1b, f31f4e8, d386c74, 3a99ddd, 803fe6e (notes 24 and 25), and 7711421 (note 22).
- Why it matters: the list `CLAUDE.md` names as the record of delivered changes misses thirty-three merged pull requests and cannot be matched to three others.
- Fix outline: number the three lines and add #47, #50, and #52 to #82, with the check `docs-index` asks for: every merged pull request of `docs/metrics.tsv` appears in the list. Queued in `docs-index`.
- Also: CLAUDE.md
- Category: design
- Added: 2026-11-04

## The map's Designs lines omit the last features

- Where: the Designs lines of `docs/codebase-map.md` (line 523 at 3a99ddd and the others): area 16 lacks `explorer-folder-toggle` and `theme-tokens`, areas 3 and 13 lack `theme-tokens`, and areas 13 and 17 lack `start-screen`. Periodic quality at 3a99ddd; `completion-request` added `completion` and `diagnostics-display` to areas 13 and 17 (periodic quality at 5722559); at b76b722 area 5 (line 166) names no design of discoverability, quick-docs, or parameter-info, and area 3 (line 101) omits discoverability and layout-slots. At 31919d9 (periodic quality): `docs/codebase-map.md` line 117 names `show` twice, line 121 lists Messages without E444 and `unsaved_buffer`, Designs lines 279, 383, 389, and 437 miss completion, window, slot, breadcrumbs, `:LspStart`, `:LspRestart`, `:messages`, lsp-diagnostics, and feedback, and `docs/architecture.md` line 137 gives EditorState without the message, its error flag, and the history.
- Why it matters: the Designs line is where a change finds the archived decisions of its area, so a reader of these areas misses why the code looks as it does.
- Fix outline: add each change with the sections that touch the area, drop the second `show`, name the missing entries, and add the message history to the architecture's section 4, within the budgets. Queued in `architecture-drift`; the 31919d9 part in `docs-index`.
- Also: docs/architecture.md
- Category: design
- Added: 2026-11-05

## Icons sit in the explorer's map area

- Where: `docs/codebase-map.md:545` (periodic quality at 5722559).
- Why it matters: `carat/domain/icons.rb` and `test/domain_icons.rb` are in area 16, but the explorer never calls `Icons`; its callers are the bars, the gateway's signs, the plugin requests, and the completion kind icons.
- Fix outline: move both entries to area 13 Rendering.
- Also: carat/domain/icons.rb, test/domain_icons.rb
- Category: design
- Added: 2026-11-07

## Map method lists lag the code

- Where: `docs/codebase-map.md:502`, 438, 435, 614 (periodic quality at 5722559); also lines 151, 185 to 188, and 285 at c1b3a12 (periodic quality, docs-index): the `LastChange` bullet omits `split` and `unmeasure`, and the other two lag their files' method lists. At 38628bb also `docs/codebase-map.md` lines 223, 292, and 320 (periodic quality); at b76b722 also PaintedRows, Frame, FakeTerminal, EditorHarness (lines 450 to 638), Layout, TabList, BufferList, and FloatLayer (lines 256 to 355) miss public methods.
- Why it matters: `PluginApi::Paths` omits `absolute`, `StatusSlots` omits `set_lsp` and `label`, `FramePresenter` omits `float_group`, `EditorHarness` omits `completions`; a reader trusting the map misses the methods.
- Fix outline: add the missing names at each line. Queued in `docs-index`.
- Category: design
- Added: 2026-11-07

## The map's area 8 omits the completion popup

- Where: `docs/codebase-map.md` line 236 at cd87445: area 8's What and Flow lines never mention the six popup files (lines 257 to 265), its Designs line (269) omits `completion` and `completion-request`, its Bench line names no completion scenario. Periodic quality at cd87445, again after 5722559.
- Why it matters: a change to the popup finds neither its flow nor its decisions in the map.
- Fix outline: name the popup in What, add one Flow sentence and the two designs, or move the completion files to an area of their own. Queued in `completion-tidy`.
- Category: design
- Added: 2026-11-07

## The map's palette lines drift from the code

- Where: `docs/codebase-map.md` line 160 (ex commands said to get a key), area 6 (the search description lists), line 189 (`compile_substitute`), and lines 386 and 415 (the palette path in area 12's Flow), at 38628bb (periodic quality). Queued in `docs-index`.
- Why it matters: a reader trusting the map misses the palette's ex command path and the description lists.
- Fix outline: correct line 160, name the lists and the method, and add the palette path to the Flow line.
- Category: design
- Added: 2026-11-09

## The map's bullets lag Messages, Options, the plugin API, and two tools

- Where: `docs/codebase-map.md` line 119 (Messages without E444 and `unsaved_buffer`), line 94 (Options without `range_problem`, `slot_size`, and the three layout sizes), line 513 (VERSION 2.3, the code 2.4), line 44 (the check entry without `runner_finish`), and line 579 (AnsiTerminal named the only environment reader, while `DiskFiles#home` reads HOME), at b76b722. Periodic quality. Queue item `docs-index`. Raised again at ce6abdb (periodic quality): line 94 also omits `guide_code`, `guide_char?`, and the indentguides members.
- Why it matters: the map is the start of every change and states facts the code contradicts.
- Fix outline: add the names, say 2.4 or name the constant without a number, and say the terminal driver's only environment reads.
- Category: design
- Added: 2026-11-09

## The map's agent_guard.sh bullet omits two helpers

- Where: `docs/codebase-map.md` line 48 at 847851d: no `local_origin` nor `worktree_name`, both added or used by `pinned-main`. Periodic quality. Queue item `docs-index`.
- Why it matters: the bullet names the guard's other helpers, so a reader misses two refusals.
- Fix outline: add `local_origin` to the git clause and `worktree_name` beside `worktree`.
- Category: design
- Added: 2026-11-09

## The map's area 10 Flow names the wrong handlers

- Where: `docs/codebase-map.md` lines 316 and 320 at 847851d. Periodic quality. Queue item `docs-index`.
- Why it matters: `SwapVisualEnds` is `SelectionHandler`'s, `ExtendVisual` is `TextObjectHandler`'s, and the five operators reach their use cases through `OperatorHandler`; the selection line omits `Selection#numbered_delete?`, `as`, and `line_start`, which architecture section 5 names.
- Fix outline: name the handler per use case and add the three methods.
- Category: design
- Added: 2026-11-09

## The map misses SymbolRequest methods and the breadcrumbs test

- Where: `docs/codebase-map.md` line 591 and the render and language areas' Tests lines at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: the entry omits `count` and `name_at`, and the Tests lines do not name `test/editor_breadcrumbs.rb` though it covers `winbar.rb`, `symbol_outline.rb`, and `symbol_request.rb`.
- Fix outline: add the two methods to the entry and the test to both areas' Tests lines.
- Also: test/editor_breadcrumbs.rb
- Category: design
- Added: 2026-11-09

## The map omits Layout and search methods other files call

- Where: `docs/codebase-map.md` line 349 (Layout without `leaf_showing`, `leaf_number`, `leaf_count`, `node`, `node_count`, `window_at`), line 189 (VimPattern without `compile_substitute`), line 194 (LastSearch without `any?`, `end_preview`), line 195 (SearchPrompt without `close`, `prefix`), at 7711421. Periodic quality. Queue item `docs-index`. Raised again at ce6abdb (periodic quality): `Layout#leaf_number`, `leaf_count`, and `window_at` are still missing.
- Why it matters: callers look up a method the map does not name.
- Fix outline: name them on those lines.
- Category: design
- Added: 2026-11-09

## The map names EditorState's show twice and lacks Tree readers

- Where: `docs/codebase-map.md` line 117 (a second `show` before `list_message?`) and line 558 (area 16's Tree line without `expanded?`, `root`, `marked`, `count`, `node`), at 5e4c140. Periodic quality. Queue item `docs-index`.
- Why it matters: the map is where every agent starts.
- Fix outline: drop the second `show`; name the readers or say the list is the operations only.
- Raised again as "The map lists EditorState#show twice": Where: `docs/codebase-map.md` line 117 (area 4) at 3895e21. Periodic quality advisory. Queue item `docs-index`. Why it matters: the method list is checked by `test/lint.rb`, and a doubled name hides a missing one. Fix outline: drop the second `show`.
- Also: test/lint.rb
- Category: design
- Added: 2026-11-09

## The map and architecture lag plugin API 2.4, FormatDocs, and Config

- Where, at df4654c: `docs/codebase-map.md` line 92 (Config lacks `count`), line 517 (VERSION 2.3, `carat/plugin_api.rb` line 12 is 2.4), line 523 and the area 15 and 16 bullets (PluginHost, Paths, PluginEntries, PluginEntry, Tree methods); `docs/architecture.md` line 181 (5.3 lacks `FormatDocs`, `MarkdownText`, `DocsText`). Periodic quality. Queue item `docs-index`.
- Why it matters: CLAUDE.md keeps both in sync; drift here caused 9 of 47 quality blockers.
- Fix outline: update the bullets and the 5.3 docs line.
- Also: carat/plugin_api.rb, docs/architecture.md, CLAUDE.md
- Category: design
- Added: 2026-11-09

## Map entries miss the definitions change's names

- Where: `docs/codebase-map.md` line 523 at fafe59c, the `path_info.rb` entry, which does not name `refusal` and `BUFFER_LIMIT`, and line 612, the `json_rpc_language_gateway.rb` entry, which does not name `textDocument/definition`. Quality advisory in `definitions`.
- Why it matters: the map is where a change starts; a missing name sends the next reader searching.
- Fix outline: add both to their entries.
- Category: design
- Added: 2026-11-10

## Docs drift found by the periodic review at 8d8832f

- Where: `docs/codebase-map.md` line 140 (InputController omits ShowDefinition), 150 (HandleKey omits FollowDefinition), 117 (EditorState lists `show` twice), 520 (area 15 says plugin API 2.3, `carat/plugin_api.rb` line 12 is 2.4), 523 and 624 (PathInfo omits `refusal` and `BUFFER_LIMIT`, DefinitionRequest omits `clear_targets`, `target_count`, `LIMIT`, `OWNER`), the buffer.rb line (omits `display_name`, `path_text`, `byte_count`, `signs?`, `transaction_size`; `Buffer#blanks` at `carat/domain/buffer.rb` line 457 public but used only inside); `docs/architecture.md` line 167 (no OpenCompletionPopup), 178 (no OpenFloat, CloseFloat, ListBuffers, SwitchBuffer, DeleteBuffer); `README.md` line 9 and CLAUDE.md Stack name no `node`, which `make doctor` (Makefile line 173) needs for `tools/tools_test.sh` line 2030. Queued in `docs-index`.
- Why it matters: the map and the architecture are where a change starts, and a clone following the README fails its first `make check` stage.
- Fix outline: add the names, drop the duplicate, write 2.4, move `blanks` below `private`, and name `node` or say why it is outside the prerequisites.
- Also: carat/plugin_api.rb, carat/domain/buffer.rb, docs/architecture.md, README.md, CLAUDE.md, Makefile, tools/tools_test.sh
- Category: design
- Added: 2026-11-10

## Map entries miss names of indent-guides and older changes

- Where: `docs/codebase-map.md:325` (Selection: `numbered_delete?`, `as`, `line_start`), 144, 148, and 196 (Keymap, CommandGrammar, LastSearch), 299 (UndoTree), and area 11 (`FloatSpec#cursor_anchored?`, `FloatWindow#id`). Periodic quality at ce6abdb; the Options and Layout gaps are folded into their map entries; queue item `docs-index`.
- Why it matters: the map is kept current and agents plan from it.
- Fix outline: add each name to its line.
- Category: design
- Added: 2026-11-10

## The code map is behind the code

- Where: `docs/codebase-map.md` line 584 (area 17 Flow says every port method raises, but `FilePort#stat` answers a value); lines 523 and 532 (`Paths` omits `absolute`, `PluginEntry` omits `attach` and `full_command`). Periodic quality at e49f63d.
- Why it matters: agents start from the map and the architecture.
- Fix outline: update each sentence and list. Queue item: `docs-index`.
- Category: design
- Added: 2026-11-10

## The map misses the definition follow-ups, Paths names, and PluginEntry#attach

- Where: `docs/codebase-map.md:141`, `:151`, `:526`, `:535`. Periodic quality advisory.
- Why it matters: the pump and HandleKey lines omit ShowDefinition and FollowDefinition; Paths omits `absolute` and `segments`.
- Fix outline: add the names. Queue item `docs-index`.
- Category: design
- Added: 2026-11-10

## Docs drift found at 9a92265

- Where: `docs/codebase-map.md:118` (EditorState names `show` twice); `docs/codebase-map.md:443` (area 12 claims every ex spelling, but no buffer-list command row is in `test/use_cases_ex.rb`); `docs/architecture.md:326` (plugin API 2.0 against 2.5 in `carat/plugin_api.rb:12` and `docs/plugins.md:23`); `carat.rb:2` (says `bin/*.rb` require only it, while `bin/carat-gen-config.rb:11` requires two files directly). Periodic quality.
- Why it matters: agents plan from these documents.
- Fix outline: correct each, or add the spelling rows. Queue item `docs-index`.
- Also: test/use_cases_ex.rb, docs/architecture.md, carat/plugin_api.rb, docs/plugins.md, carat.rb, bin/carat-gen-config.rb
- Category: design
- Added: 2026-11-10

## delivery-speed quality advisory at docs/codebase-map.md:46

- Where: `docs/codebase-map.md:46`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: the set entry now reads a commit hash;, phase with its parenthesis never closed after drop_backup was removed.
- Fix outline: write commit hash), phase.
- Category: design
- Added: 2026-11-11

## tab-keys quality advisory at docs/codebase-map.md:125

- Why: map currency: the messages.rb entry does not name the new E16 and invalid_argument, and the buffer_request.rb entry at :383 does not list the new :tab target.
- Fix: add them to both entries.
- Category: design
- Added: 2026-11-12

## Docs drift found at 8b9bf6a

- Where: `docs/codebase-map.md` line 161 (BufferHandler omits `buffer.alternate`), 125 (Messages omits E16, E444, invalid_argument, unsaved_buffer), 121 (show twice), 47 (a stray `;,`), 364 (FloatWindow omits frame_width and text_room), 464 (StatusSlots omits set_lsp and label), 331 and 303 (Selection and LastChange methods); `README.md:5` lacks `%` and `<C-^>`; `docs/architecture.md:126` lacks `%` and `{count}%`. Sprint-2 review and sweep.
- Why it matters: the map and README lag jump-motions, tab-keys, and float-edges.
- Fix outline: update those lines. Pool item `docs-index`.
- Also: README.md, docs/architecture.md
- Category: design
- Added: 2026-11-14

### docs/codebase-map.md:170 editor_palette test description is stale

Docs currency: the Tests line still describes test/editor_palette.rb as opening, filtering, selection, and running, without the row layout and match marking it now covers. Fix: add the columns, caret keys, and match groups to that description.
- Also: test/editor_palette.rb
- Category: design
- Added: 2026-11-14

### The map's areas 8, 13, and 15 drift from the code

- Location: docs/codebase-map.md:251, :231, :420, :529, :464, :47, :121 (sprint-4 sweep, quality).
- Why: area 8 omits completion; Registers.unnamed?, ExHandler#ranged?, Paths.absolute, StatusSlots#set_lsp unnamed; the run_state bullet has an unclosed parenthesis; the editor_state bullet names show twice.
- Fix: correct each line.
- Category: design
- Added: 2026-11-14

### docs/codebase-map.md:599 the corrected environment sentence reads ambiguously

- Where: docs/codebase-map.md:599.
- Why: the sentence reads 'the environment reads but the HOME of DiskFiles#home', which is hard to parse.
- Fix: write 'the only environment reads besides the HOME that DiskFiles#home reads'.
- Category: design
- Added: 2026-11-15

### docs/codebase-map.md:51 the tools_test.sh entry omits the Spinel warning cases

- Where: docs/codebase-map.md:51, the tools/tools_test.sh entry.
- Why: the entry lists what it tests but not the new Spinel warning cases on the build targets with a stub toolchain (stub_make), which its header and make help now name (quality advisory, docs currency).
- Fix: add 'the Spinel warning check on the build targets with a stub toolchain (stub_make)' to the entry.
- Also: tools/tools_test.sh
- Category: design
- Added: 2026-11-15

### The BufferRequest map entry omits two targets

- Location: docs/codebase-map.md:383 and :161. Sprint-6 sweep, quality advisory. Queue item `tools-docs-tidy`.
- Why: SwitchBuffer also takes the tab and alternate targets (buffer_request.rb, tab_handler.rb:36, buffer_handler.rb:43) and line 161 omits buffer.alternate.
- Fix outline: list both targets and the action.
- Category: design
- Added: 2026-11-15

### The CommandGrammar and ActionTable map bullets omit public methods

- Location: docs/codebase-map.md:152 and :157. Sprint-6 sweep, quality advisory. Queue item `tools-docs-tidy`.
- Why: HandleKey calls pattern, wants_pattern?, char, digit?, and digit, and the table's count and handler_at are public, none listed.
- Fix outline: list them.
- Category: design
- Added: 2026-11-15

### The map omits public methods in several areas

- Location: docs/codebase-map.md:232 (Registers, Selection, ExTable, Layout, BufferList), :99 (Options), :153 (CommandGrammar), :530 and :536 (PluginApi::Paths, PluginHost, PluginRegistry) (sprint-8 sweep, quality); queued in `architecture-docs`.
- Why: entries miss methods callers use, so the map misleads a scout.
- Fix: bring the method lists in line with the code.
- Category: design
- Added: 2026-11-16

### Code map entries lack the git-signs-status-a methods
- Location: docs/codebase-map.md:547, 608, 617, 629
- Why: the map is not current: file_requests.rb lacks run_program, process_port.rb and process_runner.rb lack capture, fake_processes.rb lacks script, capture, and captured.
- Fix: add them to the four entries.
- Category: design
- Added: 2026-11-16

### The map and architecture lag the plugin API, ProcessPort, StatusSlots, and DisplayWidth
- Location: docs/codebase-map.md:531, :547, :608, :617, :465, :476; docs/architecture.md:330, :275
- Why: VERSION 2.6 where carat/plugin_api.rb:12 is 2.7; FileRequests omits run_program; Paths omits absolute and segments; ProcessPort and ProcessRunner omit capture and section 6/7 still plans Open3.capture3; StatusSlots omits set_lsp and label; DisplayWidth omits code_cells. Folded into architecture-docs.
- Fix: name each in its entry and describe capture in the architecture.
- Also: docs/architecture.md, carat/plugin_api.rb
- Category: design
- Added: 2026-11-17

### The Messages map entry lists half its messages

- Location: docs/codebase-map.md:127 (sweep, quality).
- Why: it omits E16, E444, unsaved_buffer, and invalid_argument.
- Fix outline: list them all.
- Category: design
- Added: 2026-11-17

### The BufferRequest and SwitchBuffer map entries drift

- Location: docs/codebase-map.md:385, :387 (sweep, quality).
- Why: buffer_request.rb:3 also has :tab and :alternate; switch_buffer.rb:9 handles Ctrl-^ and E23, all unlisted.
- Fix outline: add both targets, Ctrl-^, and E23.
- Category: design
- Added: 2026-11-17

### The docs give PluginApi 2.6 against the code's 2.7

- Location: docs/codebase-map.md:532, docs/architecture.md:330, carat/plugin_api.rb:12 (sweep, quality, two notes).
- Why: the map and section 9 say 2.6; the code and docs/plugins.md:23 say 2.7; the map's Paths list omits absolute.
- Fix outline: say 2.7 in both and add absolute.
- Also: docs/architecture.md, carat/plugin_api.rb, docs/plugins.md
- Category: design
- Added: 2026-11-17

### Area 13 map entries omit LineCache#size and two StatusSlots methods

- Location: docs/codebase-map.md:478, :466 (sweep, quality).
- Why: size (line_cache.rb:50), set_lsp and label (status_slots.rb:45, :86) are unlisted.
- Fix outline: list them.
- Category: design
- Added: 2026-11-17

### The map and architecture give PluginApi 2.6 against 2.8 (sprint-14 sweep quality)

- Location: docs/codebase-map.md:535, docs/architecture.md:330, against carat/plugin_api.rb:12.
- Why: map drift; the Paths list also omits absolute, which the explorer, WindowRequests, and VisitTarget call.
- Fix outline: set both to 2.8 and add absolute. Queued in `architecture-docs`.
- Also: docs/architecture.md, carat/plugin_api.rb
- Category: design
- Added: 2026-11-17

### The map says check_queue allows 0 to 2 backlog sprint items (sprint-16 sweep quality)

- Location: docs/codebase-map.md:55, against tools/docs_lint.sh:161.
- Why: since sprint-size-six the lint allows 3 in each lane, so the map misleads.
- Fix outline: say 0 to 3 in each lane.
- Also: tools/docs_lint.sh
- Category: design
- Added: 2026-11-18

### The map omits docs.toggle_reading (sprint-16 sweep quality)

- Location: docs/codebase-map.md:649, carat/use_cases/actions/docs_handler.rb.
- Why: the entry names docs.hover and docs.pin only.
- Fix outline: list docs.toggle_reading.
- Also: carat/use_cases/actions/docs_handler.rb
- Category: design
- Added: 2026-11-18

### The code map gives the backlog lane's sprint share as 0 to 2
- Location: `docs/codebase-map.md:55`, `tools/docs_lint.sh:183`
- Why: the map's `tools/docs_lint.sh` entry says a `## Sprint` of 0 to 2 items in the backlog lane, while the lint checks `backlog:3` since the 3 + 3 sprint of sprint-17 (`docs/goals.md`), so an agent reading the map plans one backlog item too few.
- Fix: say 0 to 3 in the backlog lane in the map entry; accepted when the entry matches the lane shares `check_queue` reads.
- Also: tools/docs_lint.sh, docs/goals.md
- Category: design
- Added: 2026-11-18

### The code map's explorer flow names open_in_tab (sprint-17 review quality)

- Where: `docs/codebase-map.md:584` at 522a0e1.
- Why it matters: the flow says the explorer opens files through `open_file`, `open_in_split`, and `open_in_tab`, but `carat/plugins/explorer/plugin.rb` calls `open_as_tab` and `open_in_tree_window`, so a reader follows a name that is not called.
- Fix outline: name the requests the plugin calls. Fold into `explorer-tidy` if it touches the map, else a docs tidy.
- Also: carat/plugins/explorer/plugin.rb
- Category: design
- Added: 2026-11-18

### The code map says the backlog lane's sprint holds 0 to 2 items

- Location: docs/codebase-map.md:55, tools/docs_lint.sh:23 (its header, check_lane)
- Why: sprint-size-six made a sprint 3 features and 3 backlog items, so the map's "0 to 2" for the backlog lane's `## Sprint` is stale and misleads a reader of the lane rules (the planner's note on backlog-throughput).
- Fix: say 0 to 3 in the map line and confirm `check_lane` in tools/docs_lint.sh enforces the same bound, with a docs-lint case.
- Also: tools/docs_lint.sh
- Category: design
- Added: 2026-11-18

### groom description overstates the refusal of a later removal of a merged heading
- Location: docs/codebase-map.md:48 (tools/run_state.sh:2642)
- Why: docs currency: the groom description says neither a merged entry's kept nor its merged heading is removed by another line, but groom refuses a merged line only when an earlier line already removes its heading, so a later listed or fixed line naming the same merged heading still passes (quality advisory at 65a5758220b7).
- Fix: say the merged heading is refused when an earlier line removes it, or refuse any later removal of a merged heading in groom with a tools_test case.
- Also: tools/run_state.sh
- Category: design
- Added: 2026-11-18

### Codebase map omits the bracket pair for a folded window
- Location: docs/codebase-map.md:474
- Why: the frame_presenter entry says a folded window records no scroll and draws no guides but not that it draws no MatchParen pair, which this change adds.
- Fix: end the sentence with 'and no bracket pair'.
- Category: design
- Added: 2026-11-19

### Code map Grep line omits public class methods
- Location: docs/codebase-map.md:568, the Grep line
- Why: it lists the public methods but not the class methods no_strings and no_ints (nor utf8_size), so the map is stale
- Fix: add no_strings, no_ints, and utf8_size to the method list
- Category: design
- Added: 2026-11-19

### Map drift (sprint-20 sweep quality, codebase-map.md:362)

- Location: `docs/codebase-map.md:362`
- Why: map drift: the area 11 Window entry leaves out open_cursor_folds (carat/domain/window.rb:117, added in #225 and called by ArrangeView and RepeatLast), and the Folds entry at line 394 leaves out folded?, which every fold path checks first
- Fix: add both to their entries
- Also: carat/domain/window.rb
- Category: design
- Added: 2026-11-19

### The matcher.rb entry lists score, span_score, key, and index_of, but (sprint-20 sweep quality, codebase-map.md:569)

- Location: `docs/codebase-map.md:569`
- Why: the matcher.rb entry lists score, span_score, key, and index_of, but Matcher.lower is now called from grep.rb (lines 140, 142) as part of its surface
- Fix: list lower in the map entry
- Category: design
- Added: 2026-11-19

### Map drift (sprint-20 sweep quality, codebase-map.md:306)

- Location: `docs/codebase-map.md:306`
- Why: map drift: the LastChange method list omits unmeasure and split, which dispatcher.rb:117 and :103 call
- Fix: add both to the area 9 line
- Category: design
- Added: 2026-11-19

### Map drift (sprint-20 sweep quality, codebase-map.md:331)

- Location: `docs/codebase-map.md:331`
- Why: map drift: the area 10 Flow says VisualModeHandler runs SwapVisualEnds and ExtendVisual and SelectionHandler runs one use case per operator, but SwapVisualEnds runs from SelectionHandler (selection_handler.rb:113), ExtendVisual from TextObjectHandler, and d, y, c, >, < from OperatorHandler (operator_handler.rb:44-48)
- Fix: rewrite the Flow sentence and list text_object_handler and operator_handler as callers
- Category: design
- Added: 2026-11-19

### Map drift (sprint-20 sweep quality, codebase-map.md:336)

- Location: `docs/codebase-map.md:336`
- Why: map drift: the Selection method list omits numbered_delete?, line_start, and as, which the visual use cases call
- Fix: add them to the area 10 line
- Category: design
- Added: 2026-11-19

### Map drift (sprint-20 sweep quality, codebase-map.md:543)

- Location: `docs/codebase-map.md:543`
- Why: map drift: PluginApi::Paths lists normalize, join, dirname, basename, relative, inside? but not absolute (used by VisitTarget and GitSigns) or segments; line 549 PluginHost omits follow_prompt, flush, describe, action_names, reason; line 643 FakeProcesses omits script, which the git tests use
- Fix: add the missing names to the three entries
- Category: design
- Added: 2026-11-19

### docs/codebase-map.md:232: method lists of areas 7-11 drift from the code (sprint-22 sweep quality)

- Location: `docs/codebase-map.md:232`
- Why: method lists of areas 7-11 drift from the code: Operators omits ascii_recase and indent_width; line 233 says eight OperatorKind names where there are nine with FOLD; Selection (336) omits numbered_delete?, as, line_start; Layout (365) omits window_at, node, node_count, leaf_count, leaf_number, leaf_showing; TabList (372) omits tab_at, tab_count; Window (363) omits open_cursor_folds; Folds (395) omits count, empty?, folded?, first_of, last_of, closed?, open_all, close_all, next_fold_row, open_fold_row; LastChange (307) omits unmeasure, split
- Fix: bring the lists in line with each file's public methods
- Category: design
- Added: 2026-11-20

### docs/codebase-map.md:509: says 65 UI groups and then the popup match (sprint-22 sweep quality)

- Location: `docs/codebase-map.md:509`
- Why: says 65 UI groups and then the popup match and extra groups, Added, Changed, Removed, LineNrFifth, and MsgDim, but ids 0 to 64 (carat/domain/highlight.rb:18-82) are 65 groups that already include those
- Fix: say 65 UI groups (ids 0 to 64) ending with the popup groups, Added, Changed, Removed, LineNrFifth, and MsgDim
- Also: carat/domain/highlight.rb
- Category: design
- Added: 2026-11-20

### docs/codebase-map.md:645: the FakeProcesses method list leaves out script (carat/doubles/fake_processes.rb:54), which (sprint-22 sweep quality)

- Location: `docs/codebase-map.md:645`
- Why: the FakeProcesses method list leaves out script (carat/doubles/fake_processes.rb:54), which tests use to set capture output
- Fix: add script to the list
- Also: carat/doubles/fake_processes.rb
- Category: design
- Added: 2026-11-20

### docs/codebase-map.md:483: area 13 lists Frame's methods but omits the public (sprint-22 sweep quality)

- Location: `docs/codebase-map.md:483`
- Why: area 13 lists Frame's methods but omits the public put_digits, put_number, hl_at, width_at, same_cells?, scroll_count, text_rows, index, and digits; area 17 likewise omits DefinitionRequest clear_targets and target_count (line 656) and SymbolRequest name_at (629), and area 15 PluginHost action_names and reason (550)
- Fix: add them to the lists
- Category: design
- Added: 2026-11-20

### The area 11 map lines omit the zR and zM names (sprint-24 sweep quality)

- Location: `docs/codebase-map.md:395`, `:396`, `:397`, `:363`
- Why: the Folds, ChangeFolds, FoldHandler, and Window lines omit open_all, close_all, next_fold_row, open_fold_row, folded?, zR, zM, fold.open_all, fold.close_all, and open_cursor_folds.
- Fix: add the names to the four lines.
- Category: design
- Added: 2026-11-21

### The area 13 flow omits the guides and whitespace marks (sprint-24 sweep quality)

- Location: `docs/codebase-map.md:471`
- Why: the Flow sentence leaves out IndentGuides#paint and WhitespaceMarks#paint over each file row.
- Fix: add both.
- Category: design
- Added: 2026-11-21

### The map's gates entry omits the findings gate (sprint-24 sweep quality)

- Location: `docs/codebase-map.md:49`
- Why: gate_findings runs in static, pre-push, and merge.
- Fix: add findings to the list.
- Category: design
- Added: 2026-11-21

### The map's run_state entry is one 10,700-character line (sprint-24 sweep quality)

- Location: `docs/codebase-map.md:48`
- Why: it restates the script header, so every area 1 reader pays for it and the 157 KB map outgrows a start.
- Fix: list the command names and point to the header.
- Category: design
- Added: 2026-11-21

### The code map and the docs-lint header lag the code at docs/codebase-map.md:126 (sprint-28 sweep quality, notes 15, 25, 44, 45)

- Location: docs/codebase-map.md:126 (EditorState lacks replace_cmdline, cmdline_position, cmdline_position=), :422 (Replacement lacks too_long?, MAX_BYTES, TOO_LONG), :339 (Selection lacks numbered_delete?), :50 (gates.sh lacks findings), :56; tools/docs_lint.sh:23
- Why: the map names public methods and gates; the docs-lint header and map say a backlog sprint holds 0 to 2 items while check_queue passes 3.
- Fix: add the names; say 0 to 3 in each lane.
- Also: tools/docs_lint.sh
- Category: design
- Added: 2026-11-22

### the KeyDecoder entry says a CSI modifier is read at docs/codebase-map.md:148 (sprint-30 sweep quality, note 13)

- Location: docs/codebase-map.md:148
- Why: area 5 drift: the KeyDecoder entry says a CSI modifier is read only for Ctrl on the page keys, but arrow_key reads Shift and Ctrl on Left and Right; the Key entry omits PASTED, pasted?, and unmodified; the HandleKey entry omits the paste path
- Fix: update the three entries
- Category: design
- Added: 2026-11-23

### the EditorState entry omits replace_cmdline and cmdline_position and its at docs/codebase-map.md:126 (sprint-30 sweep quality, note 14)

- Location: docs/codebase-map.md:126
- Why: area 4 drift: the EditorState entry omits replace_cmdline and cmdline_position and its writer, the Messages entry omits E16, E444, E477, E490, REPORT, unsaved_buffer, and invalid_argument; carat/domain/editor_state.rb:13 and 16 are unwrapped comment lines
- Fix: update the entries and rewrap
- Also: carat/domain/editor_state.rb
- Category: design
- Added: 2026-11-23

### the Options entry omits slot_size, guide_code, scope_guide_code, and guide_char? at docs/codebase-map.md:102 (sprint-30 sweep quality, note 15)

- Location: docs/codebase-map.md:102
- Why: area 3 drift: the Options entry omits slot_size, guide_code, scope_guide_code, and guide_char?
- Fix: name them in the entry
- Category: design
- Added: 2026-11-23

### says ProbePath is the one call of FilePort#stat, but at docs/codebase-map.md:449 (sprint-30 sweep quality, note 28)

- Location: docs/codebase-map.md:449
- Why: says ProbePath is the one call of FilePort#stat, but carat/use_cases/files/list_tree.rb:69 and carat/use_cases/complete_command_line.rb:213 call @files.stat directly
- Fix: reword the map line to name ProbePath as the one stat of OpenFile and the plugin file operations, or route the other two through it
- Also: carat/use_cases/files/list_tree.rb, carat/use_cases/complete_command_line.rb
- Category: design
- Added: 2026-11-23

### area 13's flow says the presenter paints the buffer at docs/codebase-map.md:485 (sprint-30 sweep quality, note 37)

- Location: docs/codebase-map.md:485
- Why: area 13's flow says the presenter paints the buffer tabs row when BufferList#tab_row?, but FramePresenter now asks TabBar#showing? (frame_presenter.rb:232, since #318), and the tab_bar.rb entry at line 494 does not list showing?
- Fix: name TabBar#showing? in the flow and add showing? to the tab_bar.rb entry
- Category: design
- Added: 2026-11-23

### the header (and docs/codebase-map.md:56) says a sprint holds 0 at tools/docs_lint.sh:23 (sprint-30 sweep quality, note 54)

- Location: tools/docs_lint.sh:23
- Why: doc drift: the header (and docs/codebase-map.md:56) says a sprint holds 0 to 2 items in the backlog lane, but check_queue (tools/docs_lint.sh:235) allows 3 in each lane, the 3 + 3 decision
- Fix: say 0 to 3 in each lane in both places
- Also: tools/docs_lint.sh
- Category: design
- Added: 2026-11-23

### the MemoryFiles line omits its public directory? and unwritable at docs/codebase-map.md:708 (sprint-30 sweep quality, note 68)

- Location: docs/codebase-map.md:708
- Why: the MemoryFiles line omits its public directory? and unwritable, and the FakeProcesses line (664) omits script
- Fix: list them
- Category: design
- Added: 2026-11-23

### the AnsiTerminal line says the environment reads but HOME at docs/codebase-map.md:636 (sprint-30 sweep quality, note 76)

- Location: docs/codebase-map.md:636
- Why: the AnsiTerminal line says the environment reads but HOME of DiskFiles#home are its own, but ProcessRunner#program_path now reads PATH
- Fix: name PATH in ProcessRunner beside HOME
- Category: design
- Added: 2026-11-23
