# Golden examples

One small file per common kind, already in the tree, that follows every rule the checks enforce: copy its shape instead of searching for one. Each is compiled, linted, and tested on every run, so it stays current; `make docs-lint` fails when one moves without this page. A generator writes the kind and wires it in, so the tree compiles and passes lint and the tests at once; the Wiring list says what it does and what is left. The Spinel rules behind the shapes are in `docs/spinel-notes.md`; the layer rules in `docs/architecture.md` sections 3 and 5.

| Kind | Golden files | Generator |
| --- | --- | --- |
| Use case | `carat/use_cases/join_lines.rb`, `carat/use_cases/windows/split_window.rb` | `make new-use-case NAME= [DIR=] AREA=` |
| Action handler | `carat/use_cases/actions/tab_handler.rb` | `make new-action NAME= ACTION= [AREA=5]` |
| Ex handler | `carat/use_cases/ex/syntax_command_handler.rb` | `make new-ex-command NAME= SPEC= [AREA=12]` |
| Domain record | `carat/domain/position.rb` (`Data`), `carat/domain/cursor.rb` (`Struct`) | none |
| Port, driver, double | `carat/ports/clock_port.rb`, `carat/drivers/monotonic_clock.rb`, `carat/doubles/manual_clock.rb` | none |
| Plugin | `carat/plugins/hello/plugin.rb` | `make new-plugin NAME= [AREA=15]` |
| Table-driven test | `test/domain_ex_grammar.rb` (domain), `test/editor_insert.rb` (whole editor) | `make new-test NAME= AREA=` |

`AREA` is the number of the section of `docs/codebase-map.md` the file belongs to. Every generator refuses an existing file, a name that is not snake_case, an action or ex command already documented, and a missing anchor line, before it writes anything.

## Use case

`JoinLines` has no collaborators: `call(state, command)` returns an `Outcome`. `SplitWindow` takes its collaborators as required keywords with readers (the shared-instance test reads them) and its own arguments in `call`. One public method, `call`; everything else private, constants in `private_constant`.

Wiring: the file with a signed `call` (generator); its `require_relative` in `carat.rb` (generator); its map bullet (generator); its construction in `EditorAssembly`, the only place that wires the core, and the handler that calls it (by hand); its test.

## Action handler

`TabHandler` passes `kind:` and `repeat:` to `ActionHandler`, keeps its use case as a required keyword, and registers its names in `self.register(table, ...)`. The kind tells the grammar how the action reads keys: `:action`, `:motion`, `:find`, `:operator`, `:text_object`, `:register`, or `:char`.

Wiring: the handler answering `Not implemented: name` (generator); its requires in `carat.rb` and `EditorAssembly` and its `register` call before the plugin namespace handler (generator); its row in `docs/actions.md`, which `test/use_cases_actions.rb` compares with the table (generator, effect by hand); its map bullet (generator); a `keymap.<mode> <keys> <action>` line in `config/default.caratrc` and `make gen-config` (by hand; a motion is bound in `normal`, `operator_pending`, `visual`, `visual_line`, and `visual_block`); the behavior and its test.

## Ex handler

`SyntaxCommandHandler` passes its Vim name spec (`sy[ntax]`) to `ExHandler`, answers an `Outcome` from `call(state, command)`, and registers itself in `self.register(table)`. The table tries handlers in registration order, which is the order of `docs/compatibility.md`.

Wiring: the handler with its spec (generator); its requires and its `register` call last before the plugin commands (generator; move it to Vim's precedence when another command shares its abbreviation); its `docs/compatibility.md` row before `unknown`, from which `test/use_cases_ex.rb` checks every spelling (generator, behavior and messages by hand); its map bullet (generator); the behavior and a table-driven test.

## Domain record

`Position` is a `Data` value with methods, so its pins apply; `Cursor` is a `Struct` with `keyword_init: true`, every member pinned, a keyword `initialize` that names every member in `super`, and methods that use the readers and writers. Both are built with keywords at every call site.

Wiring: its `require_relative` in `carat.rb` among the entities; its map bullet; its table test.

## Port, driver, and double

`ClockPort` raises `NotImplementedError` in each method; an overridden method carries `# @rbs` parameter lines or `# @rbs skip` and states its return in prose. `MonotonicClock` is the driver, constructed only in `bin/carat.rb`; `ManualClock` is the double, whose name starts with `Fake`, `Memory`, `Manual`, or `Fixed`.

Wiring: the port in `carat.rb`; the driver required by `bin/carat.rb` and passed to `EditorAssembly`; the double required only by `carat/test_support.rb` and used by `EditorHarness`; map bullets for all three.

## Plugin

`hello` is the smallest complete plugin: it requires only `carat/plugin_api.rb`, declares its actions, command, bindings, events, and options in its manifest, and reaches the editor only through its `Host`. `docs/plugins.md` is the guide; it is a fixture outside the registry, so the editor does not contain it.

Wiring: the plugin with a manifest of one action (generator); its `config/plugins.caratrc` line and the registry regenerated by `make gen-config` (generator and target); its `plugin.<name>.enabled` line in `config/default.caratrc` (generator); its row in the Plugins table of `docs/actions.md` (generator, effect by hand); its map bullet, or an area of its own for a plugin of substance (generator); its bindings and option defaults as configuration lines in the manifest, and its test (by hand).

## Table-driven test

`test/domain_ex_grammar.rb` is a module named after the file with the suffix `Test`, its rows `[label, input, expected]` through `t.table`, its statements in `def self.main`, and the guard `DomainExGrammarTest.main if __FILE__ == $0`. `test/editor_insert.rb` drives the whole editor through `EditorHarness` over the doubles with keys in Vim notation. A table value is converted by a typed helper before it reaches the library; a helper returning several values returns an object with typed readers.

Wiring: the program and a snapshot equal to its output (generator); its `require_relative` and `when` lines in `test/runner/run_all.rb` (generator); its entry on the area's Tests line of the map (generator); the real rows, then `make test-one T=test/NAME.rb` and `make snapshots` with the diff reviewed (by hand). A Neovim command's rows also go into `docs/compatibility.md`.
