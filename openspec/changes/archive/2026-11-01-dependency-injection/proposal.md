# Proposal

## Why

The architecture review behind the core-quality queue found that the core is wired by hand in a few central places: `Dispatcher#call` routes 69 action names through `case` arms and takes 16 positional collaborators, `ExecuteEx#call` routes 23 ex command arms with 9, the command grammar keeps its own copy of the operator names, and adding one ex command touches seven files, most of them wiring. Ex commands match only their shortest and longest spelling, so `:vsp`, `:spl`, `:wr`, `:wal`, `:xi`, and `:tabfirs` report E492 although `docs/compatibility.md` documents the `name[suffix]` forms. An unknown action name in a key binding shows up only when the key is pressed. Some use cases report through a return value and others write the message row themselves. The lint test reads only `require_relative` lines and ranks ports with use cases. The user asked for dependency injection in the Clean Architecture style, concern modules, and Ruby naming conventions before more plugins; this is the first of two changes that deliver them, and `state-and-ports` follows.

## What Changes

This change is outside the roadmap order: it is the third change of the core-quality queue the user approved before more plugins, and it changes how the core is wired rather than adding a roadmap item.

- Add input ports for the core: an `ActionHandler` base class with `call(state, command)` returning an `Outcome` and a `kind`, and an `ExHandler` base class carrying a Vim name spec with `call(state, ex_command)` returning an `Outcome`. An `ActionTable` and an `ExTable` hold the registered handlers; each feature registers its own handlers through a `register` function with explicit dependencies, and the dispatcher and the ex runner depend only on their table.
- Classify actions for the command grammar by the `kind` of their registered handler (motion, find motion, operator, text object, register prefix, action wanting a character, plain action) instead of name prefixes and a constant list.
- Recognize every ex command from its abbreviation to its full name, as Vim's `name[suffix]` notation means, with one matcher for core and plugin commands; the registered order decides between two matches, core commands first, then plugin commands in registration order.
- Report a key binding whose value is an unknown action name when the configuration is loaded, with the file name and the JSON path, in the message row after startup; the binding is not added and the rest loads. A test keeps the action table and `docs/actions.md` in step.
- Make every handler return an `Outcome` that one place, the `Reporting` concern, applies to the message row; `Move`, `Operate`, `InsertText`, `FocusWindow`, `ResizeLayout`, and the visual use cases now return one, and the dispatcher no longer discards `SwitchTab`'s.
- Move `ExecuteEx` from `use_cases/files/` to `use_cases/ex/` with its handlers; the write-all loop moves to `SaveFile`.
- Strengthen the lint test: constant references are checked per layer, not only `require_relative` lines; ports rank below use cases and doubles above adapters; `carat/plugin_api.rb` sits in the innermost ring with the entities, and the documentation says so.
- Write the Ruby naming conventions, the keyword-argument constructor convention, and the concern rules into `CLAUDE.md`, and teach the lint test the mechanical naming rules: one public class or module per file named after it, namespaces by layer directory, CamelCase classes, upper snake case constants, snake_case methods without unclear abbreviations, predicates ending in `?` and returning a boolean, no `get_`, `is_`, or `has_`, `!` only beside a safe twin, no single-value `set_` methods, and the suffixes of handlers, ports, doubles, and concerns. The files that held several public classes are split and the names that break a rule are renamed (`Walker#cls` becomes `char_class`).
- Constructors of the classes this change creates or touches take required keyword arguments.

Out of scope, for `state-and-ports`: splitting `EditorState`; the `CommandRunner` interface that removes `PluginHost#attach`; injecting a real `ConfigPort` instead of a raw configuration hash; a `SignalPort` instead of the `Signals` class flags; a typed `FilePort#stat`; moving the test doubles out of the production require graph; converting every remaining constructor to keyword arguments; the test that every shared object is one instance.

Assumptions recorded here rather than asked:

- The type is `feat` because the ex abbreviations and the load-time report are user-visible; the rest is a refactor with unchanged behavior.
- The first configuration problem is shown in the message row after the file's own message, with the count of the others, because the message row holds one line; all problems are kept on the assembly for tests and a later `:messages`.
- The configuration's file name is passed to the assembly with the configuration value; reading the user and project files is the `options-and-config` item, so today every binding comes from `config/default.json`.
- A `visual.*` action other than `visual.reselect` outside a visual mode keeps answering "Not implemented: name", as it does today.
- Subdirectories of a layer group files by feature and add no namespace of their own, as the layer table of the architecture says; only a plugin's directory adds one.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-line-mode`: ex command names are recognized from their abbreviation to their full name.
- `plugin-host`: a plugin's ex command is recognized from its abbreviation to its full name, after the core commands, in registration order.
- `keymap-config`: a binding naming an unknown action is reported with the file name and JSON path when the configuration loads and is not added.

## Impact

- Use cases: new `actions/` (the base class, the table, and the handlers), new `ex/` (`execute_ex.rb` moved here, the base class, the table, and the handlers), new `concerns/reporting.rb`; `dispatcher.rb`, `handle_key.rb`, `edit_command_line.rb`, `move.rb`, `operate.rb`, `enter_insert.rb`, `insert_text.rb`, `leave_insert.rb`, `files/save_file.rb`, the window and tab use cases, the visual use cases, and the plugin host and router.
- Domain: new `ex_name.rb`; `command_grammar.rb` (kinds), `keymap.rb` (checked loading), `motions.rb` and `text_objects.rb` (name lists, renames), and the split files `find.rb`, `keymap_node.rb`, `keymap_match.rb`, `layout_node.rb`, `walker.rb`, `sentence_starts.rb`, `motion.rb`, `register_entry.rb`, `span.rb`, `block.rb`, `runs.rb`.
- Adapters: `editor_assembly.rb` (registration, configuration check, keyword constructor), `json_config_gateway.rb`; the doubles' `editor_harness.rb` and `fixed_config.rb`; `bin/carat.rb`.
- Tests: new `test/use_cases_actions.rb` and the ex table, abbreviation, and configuration tests; `test/lint.rb` with its new rules and self-checks; updated grammar, keymap, ex, and plugin tests.
- Docs: `CLAUDE.md`, `docs/architecture.md`, `docs/compatibility.md`, `docs/actions.md`, `docs/plugins.md`, `docs/backlog.md`.
- No new dependency, no configuration change, and no plugin API change.
