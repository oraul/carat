# Design

## Context

See proposal.md, Why. The review reads `docs/architecture.md` and `docs/codebase-map.md` against the code at main (a9812b5): each class, file, command, and number the documents name is checked with `grep` and `find` over `carat/`, `bin/`, `config/`, `test/`, `bench/`, and the Makefile, never over `docs/backlog.md`. `test/lint.rb` already proves the map's file coverage, its method lists, and the port table of section 6, so the review spends its effort on what no check covers: prose claims, the layer diagram, lists of names, sizes, versions, and the shape of the code.

## Goals / Non-Goals

**Goals:**

- A report a planner can queue from: every open finding with a location, why it matters, and a fix outline, small enough to become one queue item each.
- Documents that no longer state as present what the code does not have.

**Non-Goals:**

- Completeness of the architecture: it names the core pieces and leaves the rest to the map, so an omission is a finding only where a reader would miss a mechanism (floats).

## Decisions

- Planned pieces are marked in place, `(planned)` with the roadmap item where there is one, instead of being deleted. The architecture is the target and the roadmap builds toward it; deleting the target would lose decisions already made, and leaving it unmarked misleads. Alternative: a separate "not yet built" section, which would split each description from its plan.
- The plugin API's version history stays only in `docs/plugins.md`, the plugin author's guide; section 9.4 names the current version and points there. Two copies had already diverged (9.4 said 2.0, the code and the guide 2.6).
- Findings this change corrects are listed under Findings, Corrected here, and not appended to the backlog, since nothing is left to do; every other finding is appended once, in the backlog's entry shape (a heading, location, why, fix outline), written without reading the file.
- Dead code is found by a heuristic: every method defined under `carat/` and `bin/` whose name appears nowhere else in `carat/`, `bin/`, `test/`, or `bench/`. Plugin-facing API members with no caller are reported separately, since a third-party plugin may call them.

## Risks / Trade-offs

- [A finding duplicates a sprint-4 sweep entry the review could not read] → the planner's sprint mode removes duplicates (`backlog-dups`), as the brief says.
- [The dead-code heuristic misses a method called only through a dynamic name, or reports one used by a name shared with another method] → Spinel forbids computed `send`, so the first cannot happen; each reported method was checked by hand.
- [A correction changes a budgeted document's size] → `make docs-lint` checks the budgets; the corrections replace text rather than add sections.

## Findings at a9812b5

The review the brief asks for, kept here so the archived change records it. Every class, file, command, version, and size the two documents name was checked over `carat/`, `bin/`, `config/`, `test/`, `bench/`, and the Makefile; `docs/backlog.md` was not read, so a finding may repeat a sprint-4 sweep entry, which the planner's sprint mode removes. Each open finding (H, R, M) is appended to the end of `docs/backlog.md`; Corrected here is closed and not appended.

### Holes

#### H1. The language-service asks have no port

- Location: `carat/domain/hover_request.rb`, `definition_request.rb`, `signature_request.rb`, `symbol_request.rb`, and `completion_request.rb`; `carat/adapters/editor_assembly.rb` (the `hover`, `definition`, `symbols`, and `signature` readers, built near line 345); `docs/architecture.md` section 5.3 ("no port").
- Why: completion goes through `CompletionPort`, while hover, definition, signature help, and document symbols go through mutable domain records the use cases and `JsonRpcLanguageGateway` both write: two mechanisms for one job. The records hold protocol bookkeeping (the request in flight, its deadline, the serial), so the domain carries what belongs to the adapter, a second backend or a double must mimic the record mutations, and section 3's rule that a boundary is crossed with plain values does not hold here.
- Fix outline: one `LanguageAskPort` (an ask by kind and anchor, an answer by kind, `waiting?`), or the `CompletionPort` shape for each ask; the domain records keep the anchor and the answer, the gateway the request ids and deadlines; one double for every ask.

#### H2. An asynchronous language feature has no extension point

- Location: `carat/adapters/input_controller.rb:62` (the constructor takes `show_completion`, `show_hover`, `show_definition`, `show_signature`, and the `signature` record); `carat/use_cases/handle_key.rb:92-105` (`follow_hover`, `follow_definition`, `follow_signature`, `follow_palette`).
- Why: each new feature of this kind (references and rename are next on the roadmap) widens two constructors, the assembly, and the idle and after-key paths by hand, and the order in which answers are shown or floats followed is implicit. The action and ex tables solved the same problem for keys and commands.
- Fix outline: an ordered list of idle steps (`call(state)` answering whether it showed something) and one of after-key followers, filled by each feature's `register` like the action table, so `InputController` and `HandleKey` walk a list and a new feature adds one registration.

#### H3. The formatter setting does nothing

- Location: `carat/domain/config.rb:21` (`LANGUAGE_SETTINGS`), `config/default.caratrc:749` (`language.ruby.formatter`); no `FormatBuffer` use case and no one-shot runner exist.
- Why: the setting is shipped, validated, and refused from the project file, yet nothing reads it, so a user who sets it sees no effect and no message; the refusal guards nothing.
- Fix outline: deliver formatting (roadmap item 14) or, until then, drop the shipped line and report the setting as not yet supported.

### Redundancy

#### R1. Ex command descriptions live apart from their registration

- Location: `carat/use_cases/ex/ex_table.rb:20` (`DESCRIPTIONS`, by full name) against each `*_command_handler.rb`'s name specs; action descriptions arrive with each action's registration (`ActionTable#describe`).
- Why: two lists to keep in sync, and two mechanisms for one job across actions and ex commands; an ex command registered without a description shows an empty one in the command palette and nothing fails.
- Fix outline: pass the description with each ex handler's registration, as actions do, remove `DESCRIPTIONS`, and fail a test on a named command without one.

#### R2. Two file-name classifiers

- Location: `carat/domain/filetype.rb:8-11` (`EXTENSIONS`, `NAMES`) and `carat/plugin_api.rb:424-481` (`FileIcons::NAMES`, `file_type`).
- Why: both map a file name or extension to a kind (`rb` to `ruby` in each), so a new language is added twice and the two can disagree; `PluginApi`, which names no layer, cannot reuse `Domain::Filetype`.
- Fix outline: one table in `carat/plugin_api.rb` (rank 0, beside the entities) that `Filetype` reads, the icon-only names apart, or `FileIcons` taking the filetype the host already detected.

#### R3. Dead code

- Location: `DisplayWidth.of_char` (`carat/domain/display_width.rb:37`), `ExtendVisual#tabstop_of` (`carat/use_cases/visual/extend_visual.rb:53`, private), `CommandGrammar#operator_pending?` (`carat/domain/command_grammar.rb:84`), `TabRequest#counted?` (`carat/use_cases/windows/tab_request.rb:14`), `FakeTerminal#input?` (`carat/doubles/fake_terminal.rb:55`): no caller in `carat/`, `bin/`, `test/`, or `bench/`. The plugin API's `args?` (`carat/plugin_api.rb:125`) and `insertion?` (line 142) have no caller either but face third-party plugins.
- Why: code nobody calls is still read, compiled, analysed, and listed; `of_char` also contradicts the rule that nothing in `DisplayWidth` takes one-character strings.
- Fix outline: remove the five and their map entries; keep or document the two API members in `docs/plugins.md`; a lint rule for a private method no line of its file calls would catch the next one.

### Reading and maintenance costs

#### M1. The language gateway is one class of 1,373 lines

- Location: `carat/adapters/json_rpc_language_gateway.rb`.
- Why: the lifecycle, document sync, diagnostics, progress, and five request kinds share one class, so every language feature edits it; section 9.3 says the plugin gateway will reuse its framing, process handle, and queue, which today are woven into the language protocol.
- Fix outline: extract a JSON-RPC session (ids, pending requests, cancellation, framing over `ProcessPort`) and one small class per request kind, before `plugin-protocol` (roadmap item 13).

#### M2. The frame presenter still paints floats, menus, and messages itself

- Location: `carat/adapters/frame_presenter.rb` (1,274 lines); `TabBar`, `StatusBar`, `Winbar`, `IndentGuides`, and `PaintedRows` were split out already.
- Why: the adapters' largest file after the gateway; floats, the completion menu, the message area, notifications, and the diagnostic line are painted inline, so each new overlay grows it.
- Fix outline: move the float and menu painting and the message rows into painters on the pattern of `StatusBar`, the presenter keeping the frame swap and the window rows.

#### M3. The plugin API file mixes four concerns

- Location: `carat/plugin_api.rb` (888 lines): the request and response values, the `Host` and `Plugin` bases, `Paths`, and `FileIcons`.
- Why: it is the one file a plugin author reads, and the API reference is buried among path functions and an icon table.
- Fix outline: keep `carat/plugin_api.rb` as the one file a plugin requires, requiring `carat/plugin_api/` files (values, host, plugin, paths, file icons), and widen the lint's plugin rule to that directory.

#### M4. Floats have no place in the architecture

- Location: `docs/architecture.md` sections 4, 5.3, and 8.2; the code has `Domain::FloatWindow`, `Domain::CompletionMenu`, `UseCases::OpenFloat` and `CloseFloat`, `Highlight::FLOAT_LAYER`, and plugin API 2.3 and 2.6.
- Why: floats carry the documentation, definitions, signature help, the finder, the key hints, and the palette, yet the architecture mentions them only in passing, so where a new overlay belongs is not written down.
- Fix outline: a short paragraph on floats in section 4 (the record, the layer of groups, a plugin's ownership) and in section 8.2 (painting order), within the budget by pointing to the map for the lists.

#### M5. The assembly grows with every feature

- Location: `carat/adapters/editor_assembly.rb` (582 lines), whose `initialize` builds every record and use case.
- Why: it is the one wiring place by design, but one long constructor makes a feature's wiring hard to find and to review.
- Fix outline: group the construction into a private method per feature (language services, discovery, plugins), keeping the readers and the one-instance rule the assembly test checks.

### Corrected here

Each was a statement of `docs/architecture.md` or `docs/codebase-map.md` the code at a9812b5 contradicts; this change corrects the document only.

- Architecture, top: the target and the present were mixed with no marker; a piece not built yet is now marked planned.
- Section 2 and the layout tree: the Makefile calls `spinel` directly and runs the scripts under `tools/`; it no longer says every target calls only `spin` or OpenSpec.
- Section 3: the layer diagram named `Threads`, `Insert`, `Undo`, `ManageWindows`, `Complete`, `Diagnose`, `Marks`, `Motion`, and `TextObject`, none of which exists; it now names real classes.
- Section 4: `Marks` described an entity that does not exist; marked planned.
- Section 5: "the only layer that talks to ports" contradicted section 8 (`InputController` reads the terminal port, the gateways drive the process port); corrected.
- Section 5.2: the ex commands listed included `saveas`, `m`, `t`, `normal`, `sort`, `marks`, `jumps`, and `setlocal`, which are not registered, and left out the tab, message, search, and language-server commands that are; corrected, the rest planned.
- Section 5.3: `RequestReferences`, `Rename`, and `FormatBuffer` do not exist; marked planned.
- Sections 5.4 and 13: `Carat::Json` is about five hundred lines, not two hundred.
- Section 6: the `FilePort` row said only `DiskFiles` reads the environment; the terminal driver reads it too.
- Section 8.2: the completion menu is drawn today, not later.
- Section 8.4: one-shot tools through `Open3.capture3` do not exist; marked planned.
- Section 9.4: the API version was 2.0 against 2.6 in the code, and its history repeated `docs/plugins.md`; it names 2.6 and points to the guide.
- Section 11: `git_signs/`, `docs/plugin-protocol.md`, and the plugin gateway in `carat/adapters/` do not exist; marked planned; the service threads are `ProcessRunner`'s.
- Section 12: each item was to leave `spin build` and `spin test` green, while `CLAUDE.md` forbids calling `spin test` directly; it says `make check`.
- Map area 17: `AnsiTerminal`'s environment reads were called the only ones; `DiskFiles#home` reads `HOME`.
- Map area 4: `EditorState#show` was listed twice.
- Map area 1: a stray `;,` in the `run_state.sh` entry.
