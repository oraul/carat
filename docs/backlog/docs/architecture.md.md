# Backlog: docs/architecture.md

## The architecture lists only some of OpenFile's responses

- Where: `docs/architecture.md` section 5.2 (line 171) lists `E37`, `E212`, and `E492` as the responses of the file use cases. Advisory of the periodic quality review at 389c118.
- Why it matters: `OpenFile` also refuses a directory, a non-regular file, and a file over 64 MiB with `E484` and Vim's messages, and the binding document should say so.
- Fix outline: name those responses in that line, making room within the document's budget. Queued as `file-access-tidy`.
- Category: design
- Added: 2026-11-03

## The architecture omits the global marks from the splice

- Where: `docs/architecture.md` section 4.1 (line 146 at 76fa78b), which says every splice moves the sign layers through `LineSplice.shift_marks`. Quality advisory of `buffer-global`.
- Why it matters: the splice now moves the buffer's `GlobalMarks` too, so a reader of the section misses why a global finds its marked lines after an edit moved them.
- Fix outline: name the global marks beside the sign layers in that sentence. Queued in `global-tidy`.
- Category: design
- Added: 2026-11-05

## Section 11 names only some of the documents and no agent or CI directory

- Where: the tree of `docs/architecture.md` section 11 (its `docs/` line near line 398), now the stated home of the layout detail `CLAUDE.md` dropped in `docs-currency`. Quality advisory at 13473da.
- Why it matters: its `docs/` line names 4 of the 12 documents, one of them, `plugin-protocol.md`, not yet written, and the tree omits `.claude/`, `.github/`, and `dist/`, so neither file lists where the documents, the agents, and CI live.
- Fix outline: list the documents and the `.claude/`, `.github/`, and `dist/` directories in the tree, or have the Layout section of `CLAUDE.md` point to the map for `docs/`.
- Also: CLAUDE.md
- Category: design
- Added: 2026-11-05

## The architecture gives the plugin API as 2.0

- Where: the plugin API version sentence of `docs/architecture.md` (line 321 at `theme-tokens`) and its `syntax_group` and `tokenize` bullets near lines 295 to 296, while `carat/plugin_api.rb` (line 12) and `docs/plugins.md` (line 23) give 2.3 at 803fe6e. Periodic quality at 4c65f4e and 803fe6e. Raised again at 38628bb (periodic quality). Queued in `architecture-drift`.
- Why it matters: the binding architecture lists changes only through 1.3 and misses 2.1's file-icon groups in `syntax_group` and tokens and a scratch buffer's syntax named after its plugin, 2.2's `set_segment` and `PluginApi::FileIcons`, and 2.3's floats (`open_float`, `move_float`, `close_float`, `FloatOptions`), so a plugin author reading it targets an older API.
- Fix outline: say 2.3 and add the 2.1, 2.2, and 2.3 additions to the version sentence and to the `syntax_group`, `tokenize`, and window request bullets, within the file's budget.
- Also: carat/plugin_api.rb, docs/plugins.md
- Category: design
- Added: 2026-11-05

## The architecture's InputController and FramePresenter bullets omit the start screen

- Where: the binding `InputController` and `FramePresenter` bullets of `docs/architecture.md` (lines 247 and 252 at `start-screen`); only the `TerminalPort` row (line 198) was updated. Periodic quality at 5ac9674.
- Why it matters: the controller now shortens its read timeout for the next frame, advances the start screen in `tick`, and dismisses it on a key, and the presenter paints `StartArt` over the current window and repaints every row after it, none of which the binding document says.
- Fix outline: one clause in each bullet, within the file's budget.
- Category: design
- Added: 2026-11-05

## Section 7 of the architecture omits startscreen and reducedmotion

- Where: the flag options of the option scope in section 7 of `docs/architecture.md` (line 236 at 5b128b5), while `config/default.caratrc` (lines 31 and 32), `README.md` (line 66), and `docs/compatibility.md` carry both. Periodic quality at 5b128b5.
- Why it matters: the binding document lists fewer options than the code accepts, so a change planned from it misses two.
- Fix outline: add both to the flag list within the file's budget, beside the start-screen bullets.
- Also: config/default.caratrc, README.md, docs/compatibility.md
- Category: design
- Added: 2026-11-05

## The roadmap asks for a CRuby sample plugin

- Where: roadmap item 13 of `docs/architecture.md` (line 405 at 5b128b5), and line 314, which invites CRuby process plugins. Periodic quality at 5b128b5.
- Why it matters: the hard rules forbid running or testing anything with a CRuby interpreter, so the item cannot be delivered as written.
- Fix outline: make the sample a Spinel-compiled program or a shell script, and say CRuby process plugins are the author's choice, never built or tested here.
- Category: design
- Added: 2026-11-05

## The architecture names no float

- Where: `docs/architecture.md` at 803fe6e: the Window, Layout, TabPage bullet (line 129), the Frame bullet (line 130), section 5.3 (line 177), and the ArrangeView bullet (line 178). Periodic quality advisory.
- Why it matters: the binding architecture omits `FloatSpec`, `FloatWindow`, `FloatLayer`, `TabPage#window` answering the focused float first, `OpenFloat`, `CloseFloat`, float placement, and the float key.
- Fix outline: add the three entities to section 4, the two use cases and the placement to section 5.3, and the key to the Frame bullet, within the file's budget. Queued in `architecture-drift`.
- Category: design
- Added: 2026-11-07

## The architecture omits the language service start, trusted roots, and the writer thread

- Where: `docs/architecture.md` at eb63fb4: the section 6 port table (line 203), the section 7 Scopes sentence (line 236), and the service threads bullet (line 268); `docs/codebase-map.md` lines 567 and 577. Periodic quality at eb63fb4.
- Why it matters: `LanguageServicePort` declares `start`, which `:LspStart` calls, but the table and the map omit it; the Scopes sentence omits `language.trusted_roots`, its word format, and that only the defaults and the user file set it; the bullet names only the reader thread while the code starts a reader and a writer per child.
- Fix outline: add `start(state)` to the table row and both map lines, `trusted_roots` to the Scopes sentence, and the writer thread to the bullet, within the file's budget. Queued in `architecture-drift`.
- Also: docs/codebase-map.md
- Category: design
- Added: 2026-11-07

## Architecture section 4 names no completion domain object

- Where: `docs/architecture.md:92` (periodic quality at 5722559).
- Why it matters: `CompletionMenu`, `CompletionItem`, `CompletionList`, and `FuzzyMatch` are missing from Entities though section 5.1 names their use cases.
- Fix outline: one section 4 bullet for the four within the file's budget, in the queued `architecture-drift` change.
- Category: design
- Added: 2026-11-07

## The architecture's RequestDefinition line was reworded out of scope

- Where: `docs/architecture.md` line 180 at 925d759, reworded by `completion-docs` with no connection to completion documentation. Quality advisory in `completion-docs`.
- Why it matters: an unrelated rewording widens the change and hides what the architecture said before.
- Fix outline: restore the original sentence and keep only the `CompletionPort` and `ShowCompletionDocs` edits. Queued in `completion-docs-tidy`.
- Category: design
- Added: 2026-11-07

## The architecture's hover sentence reads as a wait for idle

- Where: `docs/architecture.md` line 181 at 78078ad, "sends RequestHover's ask and reads the answer when idle". Quality advisory in `quick-docs`.
- Why it matters: it reads as if the answer waits for idle, while the gateway sends the ask at the next idle tick and reads only the answer to the request in flight.
- Fix outline: reword it to "which sends RequestHover's ask at the next idle tick and reads only its answer".
- Category: design
- Added: 2026-11-07

## Roadmap item 10 lost the changes that delivered it

- Where: item 10 of the roadmap in `docs/architecture.md` line 405 at c59a43d, which now reads `Delivered but go-to-definition (map).`. Quality advisory in `parameter-info`.
- Why it matters: the other items keep the changes that delivered them, this one drops `lsp-diagnostics` and `diagnostics-display`, and `(map)` does not say what it points to.
- Fix outline: restore the delivering changes, add `completion`, `quick-docs`, and `parameter-info`, and name go-to-definition as what remains.
- Category: design
- Added: 2026-11-07

## Vim messages are spelled in several files

- Where: E477 in `delete_command_handler.rb` line 34, `substitute_command_handler.rb` line 37, `global_command_handler.rb` line 35; E488 in five files; E486, E492, E32, E33, E363, E474, E939 in two or more, at b0dd342. Periodic quality. Queued in the backlog item batch.
- Why it matters: `docs/architecture.md` section 5 puts a message several use cases need in `Domain::Messages`; copies drift from Neovim's text.
- Fix outline: constants or builders in `Domain::Messages` called from every site.
- Raised again as "Eight Vim messages are spelled in more than one file": Where: `KNOWN_REPEATED_MESSAGES` in `test/lint.rb`: E32 (`file_command_handler.rb`, `save_file.rb`), E33 (`vim_pattern.rb`, `substitute_lines.rb`), E474 (`history_command_handler.rb`, `messages_command_handler.rb`), E477 (the delete, global, and substitute command handlers), E484 (`path_info.rb`, `visit_target.rb`, `open_file.rb`), E486 (`find_match.rb`, `substitute_lines.rb`), E488 (`register_count.rb`, `substitute_args.rb`, and the buffer, LspRestart, and LspStart command handlers), E939 (`register_count.rb`, `substitute_lines.rb`). Recorded by `implement-contracts-c`, queued in `messages-tidy`. Why it matters: a wording fix can reach one copy and miss the others; lint refuses a new repeat but keeps these listed. Fix outline: one `Domain::Messages` constant or function per message, called from every file, and the line removed from `KNOWN_REPEATED_MESSAGES` (lint fails on a listed message that no longer repeats).
- Also: test/lint.rb
- Category: design
- Added: 2026-11-07

## The architecture's group example names a bound prefix

- Where: `docs/architecture.md` line 230 at d828abb, the section 7 example. Quality advisory in `discoverability`.
- Why it matters: the example names `keymap.group <leader>w windows` while the same example binds `keymap.normal <leader>w :w<CR>`, so that prefix is bound and its hints never show, since a bound prefix resolves by `timeoutlen`.
- Fix outline: name a group for an unbound prefix in the example, such as `keymap.group <leader>f files`.
- Category: design
- Added: 2026-11-09

## The architecture's Options and :set lines drift

- Where: `docs/architecture.md` line 113 (the Options bullet) and line 174 (section 5.2), at b76b722. Periodic quality. Queue item `architecture-drift`. Raised again at be4b63a (owner `docs-index`).
- Why it matters: the bullet lists `wrap` and `clipboard` as members, which are only checked keys of `Options::KINDS`, and omits `theme`, `background`, `syntax_on`, `startscreen`, and `reducedmotion`; section 5.2 lists `setlocal`, which has no handler, and says `:set` handles filetype and syntax only.
- Fix outline: list the members as `carat/domain/options.rb` declares them, the options `:set` handles, and drop `setlocal` until a handler exists.
- Also: carat/domain/options.rb
- Category: design
- Added: 2026-11-09

## Architecture section 10 omits the map method-list lint rule

- Where: `docs/architecture.md` line 343 at the `implement-contracts-b` change, which lists what `test/lint.rb` checks as the code map's coverage only. Quality advisory of `implement-contracts-b`.
- Why it matters: the lint test now also checks the map's method lists, so a reader of section 10 misses why a renamed method fails lint.
- Fix outline: say the code map's coverage and method lists.
- Also: test/lint.rb
- Category: design
- Added: 2026-11-09

## Docs drift: option list, UI group count, a doubled map entry, run-together parentheticals

- Where: `docs/architecture.md:241` omits `jumptab`, `indentguides.char`, `startscreen`, and `reducedmotion`, which `carat/domain/options.rb:82` accepts; `docs/codebase-map.md:493` and `docs/architecture.md:106` say 49 UI groups and `docs/compatibility.md:510` says 41, while `carat/domain/highlight.rb:66-69` has 52; `docs/codebase-map.md:120` lists `EditorState#show` twice; `docs/codebase-map.md:48` runs two parentheticals together. Periodic quality and #102 package advisories at d0d783c.
- Why it matters: the docs an agent reads disagree with the code.
- Fix outline: name the options (or point at `docs/compatibility.md`) within the byte budget, say 52 in the three docs, drop the second `show`, merge the parentheticals. Queue item `docs-index`.
- Also: carat/domain/options.rb, docs/codebase-map.md, docs/compatibility.md, carat/domain/highlight.rb
- Category: design
- Added: 2026-11-11

### Floats have no place in the architecture (architecture-review M4)

Location: `docs/architecture.md` sections 4, 5.3, and 8.2; the code has `Domain::FloatWindow`, `Domain::CompletionMenu`, `UseCases::OpenFloat` and `CloseFloat`, `Highlight::FLOAT_LAYER`, and plugin API 2.3 and 2.6. Why: floats carry documentation, definitions, signature help, the finder, the key hints, and the palette, yet the architecture mentions them only in passing, so where a new overlay belongs is not written down. Fix outline: a short paragraph on floats in section 4 (record, group layer, plugin ownership) and section 8.2 (painting order), within the budget by pointing to the map for lists.
- Category: design
- Added: 2026-11-15

### docs/architecture.md:29 the Makefile statement is still contradicted by the Makefile

- Where: docs/architecture.md:29, and the section 11 tree line that repeats it.
- Why: the toolchain target runs git and builds Spinel with make, and doctor and no-cruby run inline shell, so not every target calls spin, spinel, OpenSpec, or a tools/ script as the corrected sentence says.
- Fix: name the toolchain build among what the targets run, or say most targets call those and the toolchain recipe fetches and builds Spinel.
- Also: Makefile
- Category: design
- Added: 2026-11-15

### docs/architecture.md:174 the ex command list still omits registered commands

- Where: docs/architecture.md:174.
- Why: the list the design calls corrected leaves out wqa and xa among the file commands, and vnew, bf, and bl among the buffer and window commands, which ExTable DESCRIPTIONS names.
- Fix: add them, or say the list is a sample and point to docs/compatibility.md for the full set.
- Also: docs/compatibility.md
- Category: design
- Added: 2026-11-15

### docs/architecture.md:180 the (planned) markers do not cite their roadmap item

- Where: docs/architecture.md:180, 374, 379, and 392.
- Why: the change's design (design.md:20) says planned pieces are marked (planned) with the roadmap item where there is one, but no marker cites its item: FormatBuffer and git_signs are item 14, the plugin gateway and plugin-protocol.md item 13.
- Fix: append the item number to each marker, or drop that clause from the design.
- Category: design
- Added: 2026-11-15

### docs/architecture.md:271 the one-shot runner is marked as future twice

- Where: docs/architecture.md:271, and the layout line at docs/architecture.md:379.
- Why: 'will run ... (planned)' marks the one-shot runner as future twice, and the edited layout line now sits one column right of the tree's description column.
- Fix: drop 'will' to match the other (planned) markers and realign the column.
- Category: design
- Added: 2026-11-15

### The architecture's section 10 omits the Spinel warning gate

- Location: docs/architecture.md:351, the diagnose bullet of section 10 (sprint-7 review, quality, docs currency).
- Why: section 10 describes make diagnose and the build machinery but not that a Spinel warning now fails every compile target, nor that diagnose runs Spinel through tools/spinel_warnings.sh because spinel-doctor --quiet hides warnings; only docs/spinel-notes.md says it, and the architecture is binding.
- Fix outline: one sentence in the diagnose bullet of section 10. Queue item `tools-docs-tidy`.
- Also: tools/spinel_warnings.sh, docs/spinel-notes.md
- Category: design
- Added: 2026-11-15

### The ProcessPort row still names capture(argv)
- Location: docs/architecture.md:213
- Why: the port takes capture(argv, environment) since #160, so the binding architecture table misstates the port.
- Fix: name the environment argument in the row.
- Category: design
- Added: 2026-11-17

### The architecture names no one-shot ProcessRunner path (sprint-13 quality)
- Location: docs/architecture.md:275, :431; carat/drivers/process_runner.rb:93.
- Why: the rewritten line names only the language server path and a planned Open3.capture3 formatter, and the table only Open3, while ProcessRunner#capture already runs short commands with spawn and no shell.
- Fix: name capture as the one-shot path; Open3 stays planned only for a tool needing stdin_data. Queue item `architecture-docs`.
- Also: carat/drivers/process_runner.rb
- Category: design
- Added: 2026-11-17

### The architecture's Options entry and scope list drift from the code (sprint-18 sweep quality)
- Location: `docs/architecture.md:118`, `:245`; `carat/domain/options.rb:40`.
- Why it matters: the entry names wrap and clipboard as members and omits gt, theme, background, syntax_on, startscreen, reducedmotion, indentguides_char; the scope list omits startscreen, reducedmotion, jumptab, gt, indentguides.char.
- Fix outline: list the Struct members and the KINDS scopes as the code declares them.
- Also: carat/domain/options.rb
- Category: design
- Added: 2026-11-18

### The TerminalPort row rewords main's Driver and Test double cells
- Location: docs/architecture.md:206 (quality advisory, reported twice, still present at the head)
- Why: the TerminalPort row's Driver and Test double cells, rewritten in the fix, no longer say how background is answered (AnsiTerminal asks OSC 11 at its first read; FakeTerminal answers unknown) and reword main's unchanged text.
- Fix: keep main's Driver and Test double cells and append only the background clauses.
- Category: design
- Added: 2026-11-20

### docs/architecture.md:331: says the plugin API is 2.9 in PluginApi::VERSION, but (sprint-22 sweep quality)

- Location: `docs/architecture.md:331`
- Why: says the plugin API is 2.9 in PluginApi::VERSION, but carat/plugin_api.rb:12 is "2.10" and docs/plugins.md:23 says 2.10
- Fix: update the architecture to 2.10
- Also: carat/plugin_api.rb, docs/plugins.md
- Category: design
- Added: 2026-11-20

### docs/architecture.md stood over its docs-lint budget on main
- Location: docs/architecture.md, the configuration section's trust bullet and the line-check bullet; tools/docs_lint.sh BUDGETS.
- Why: the merge of the project-file trust fix left the file 8 bytes over its 88064-byte budget, so make docs-lint, a stage of the check, failed for every later change; this change trimmed 9 bytes of wording to get under it.
- Fix: keep the file under budget by trimming wording at the change that grows it, and have the merge gate run docs-lint on the pull request's head so a budget overrun fails before the merge.
- Also: tools/docs_lint.sh
- Category: design
- Added: 2026-11-22
