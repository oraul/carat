# Tasks

## 1. Domain

- [x] 1.1 Split the domain files that hold several public classes into one file per class (`find.rb`, `keymap_node.rb`, `keymap_match.rb`, `layout_node.rb`, `walker.rb`, `sentence_starts.rb`, `motion.rb`, `register_entry.rb`, `span.rb`, `block.rb`, `runs.rb`) and list them in `carat.rb`; verify with `make build` and the unchanged domain test snapshots
- [x] 1.2 Rename the names that break a naming rule (`Walker#cls`, `inc`, `dec`, `Runs#cls`, `Motions.fwd_word`, `bck_word`, `bckend_word`, `Json::Parser#skip_ws`, `KeymapNode#child!`, `Keymap.build`, `Buffer#modified`, `RegisterEntry#linewise` and `blockwise`, the explorer's `Tree#set_root`) and their callers; verify with `make test`
- [x] 1.3 Add `Domain::ExName` with `parse` and `match?`, and the name lists `Motions::NAMES`, `Motions::FIND_NAMES`, `TextObjects::NAMES` with `TextObjects.object?`; verify with the ex name table in `test/use_cases_actions.rb` and `test/domain_grammar.rb`
- [x] 1.4 Make `CommandGrammar#accept` and `accept_visual` take the action's kind and remove the name lists and predicates; verify with `test/domain_grammar.rb`
- [x] 1.5 Add `Keymap#add_checked` with the file name and JSON path in every problem; verify with `test/domain_keymap.rb`

## 2. Input ports and handlers

- [x] 2.1 Add `ActionHandler`, `ActionTable`, `ExHandler`, `ExTable`, `Outcome.none`, and the `Reporting` concern; verify with the table tests in `test/use_cases_actions.rb` (register, find, unknown name, duplicate refused, namespace)
- [x] 2.2 Return an `Outcome` from `Move`, `Operate`, `EnterInsert`, `InsertText`, `LeaveInsert`, `FocusWindow`, `ResizeLayout`, `EditCommandLine`, `StartVisual`, `ExtendVisual`, `OperateOnSelection`, and the plugin router and host's `action`; verify with `make test` and the unchanged editor snapshots
- [x] 2.3 Add the action handlers under `use_cases/actions/` with their `register` functions and keyword constructors, and rewrite `Dispatcher` and `HandleKey` over the table; verify with every editor test and the handler test in `test/use_cases_actions.rb` that every registered handler returns an `Outcome`
- [x] 2.4 Move `ExecuteEx` to `use_cases/ex/`, add the ex handlers with their `register` functions, move the write-all loop to `SaveFile#all`, and route plugin commands through `PluginCommandHandler` and `ExName`; verify with `test/use_cases_ex.rb` and the abbreviation table over every documented command
- [x] 2.5 Wire `EditorAssembly` (keyword constructor, registration order, `config_source:`, `config_errors`, the startup report) and convert `EditorHarness`, `FixedConfig`, `PluginHost`, and `PluginRouter` to keyword constructors with `PluginHost` receiving `SplitWindow` and `OpenTab`; verify with `test/editor_cmdline.rb` and the configuration tests in `test/editor_plugins.rb`
- [x] 2.6 Compare the action table with `docs/actions.md` in `test/use_cases_actions.rb`; verify both directions fail on a drifted name and pass now

## 3. Lint and documentation

- [x] 3.1 Add the constant reference rule, the new ranks, the plugin API ring, the naming rules, and the constructor rule with its pending list to `test/lint.rb`, each with a good and a bad self-check; verify with `make lint`
- [x] 3.2 Update `CLAUDE.md` (Status, Layout, Coding conventions with naming, constructors, and concerns), `docs/architecture.md` (sections 3, 5, 6, 9.1, 10, 11), `docs/compatibility.md` (the abbreviation rule), `docs/actions.md` (kinds), `docs/plugins.md` (command abbreviations), and `docs/backlog.md`; verify by reading them against the code

## 4. Verification

- [x] 4.1 Run `make check` and `make types` (the dispatcher path does not widen and each `find` returns its base class), and the key benchmark against `main` for `keys lh 2000 10000` and `keys i 2000 10000`, recording the result in the design; verify key handling stays within 10 percent

## Workflow follow-up

- Run the security review on the committed branch, archive the change, and open, check, and merge the pull request.
