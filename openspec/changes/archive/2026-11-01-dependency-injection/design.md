# Design

## Context

See proposal.md for the motivation. Every finding of the review was checked again on 9c45e9f, after `plugin-host-hardening`:

| Finding | State on 9c45e9f |
| --- | --- |
| 1 central case blocks | open: `Dispatcher` has 69 `when` arms (47 in `run`, 22 in `visual`) and 16 positional collaborators; `ExecuteEx` has 23 arms and 9; `CommandGrammar::OPERATORS` repeats `Operate`'s names |
| 2 ex abbreviations | open: `:vsp`, `:spl`, `:wr`, `:wal`, `:xi`, `:tabfirs` report E492; plugin commands match their name or their abbreviation only |
| 3 unknown actions in bindings | open: `Keymap#add_all` accepts any well-formed name; the dispatcher answers "Not implemented: name" when the key is pressed; nothing reports configuration problems |
| 4 output port | open: `Move`, `Operate`, `EnterInsert`, `InsertText`, `LeaveInsert`, `FocusWindow`, `ResizeLayout`, `EditCommandLine`, the visual use cases, and the plugin router return nothing and some write the message row (`E353`, the plugin action refusals); the dispatcher drops `SwitchTab`'s outcome |
| 5 `ExecuteEx` placement | open: in `use_cases/files/` |
| 6 lint gaps | open: only `require_relative` lines are checked; ports and use cases share rank 1, adapters and doubles rank 2; `plugin_api.rb` has no layer while `Domain::ManifestCheck` and `Domain::PathPolicy` name `PluginApi` (the memory files double no longer does) |
| 7 naming | mostly followed; `Walker#cls`, `Walker#inc`, `Walker#dec`, `Runs#cls`, `Motions.fwd_word`, `bck_word`, `bckend_word`, `Json::Parser#skip_ws`, `KeymapNode#child!` (no safe twin), `Buffer#modified`, `RegisterEntry#linewise` and `blockwise` (predicates without `?`), `Keymap.build` (an alternate constructor not named `from_`), and `Tree#set_root(path)` (a one-value `set_`) break a rule; eight domain files hold more than one public class |
| 8 constructors | positional everywhere |
| 9 concerns | `Guarded` follows the rules; they are written in the architecture but not in `CLAUDE.md` |

Spinel facts this design relies on, beyond those of the earlier designs, all probed on the pinned compiler: a table class holding `# @rbs @handlers: Array[untyped]` and `# @rbs @index: Hash[String, Integer]` with a `find` declared to return the base class compiles clean, and a call through the result dispatches to the subclass; a plain array literal of two handler subclasses gives an unresolved call in `spinel-doctor`, so handlers are never kept in a literal array; required keyword parameters, on constructors and on class methods, are typed fully from a `#: (move: Move) -> void` signature; a default value such as `store: Store.new` is typed too but evaluated again on every call, so two objects built with the default do not share it; a module method included in several classes is copied into each with its parameter types inferred, and its signature is not applied; a `# @rbs @ivar` line directly under a method's comment block is not applied, so the instance variable block is separated from the first method's comment by a blank line.

## Goals / Non-Goals

**Goals:**

- The dispatcher and the ex runner depend on one table each and on nothing else; adding an action or an ex command is a registration line and a branch in the feature's own handler.
- One matcher for ex names, core and plugin.
- Every handler returns an `Outcome`, applied in one place.
- The lint test catches a constant reference across layers, the naming rules, and itself when a rule breaks.
- Key handling within 10 percent of `main` on the benchmark, `make diagnose` clean, and no new `untyped` on the dispatcher path in `make types`.

**Non-Goals:**

- Everything the proposal leaves to `state-and-ports`; in particular `PluginHost#attach` and `UiRequests#attach` stay, since the plugin host and the ex runner still need each other.
- Changing what any action or ex command does, apart from the abbreviations and the load-time report.

## Decisions

### Input ports: handler base classes and tables

`UseCases::ActionHandler` (`use_cases/actions/action_handler.rb`) has `kind`, a `Symbol` set by its constructor, and `call(state, command)`, which raises `NotImplementedError`; subclasses override it and return an `Outcome`. Because a subclass overrides it, its signature is given as `# @rbs` parameter lines with the return described in prose, as the ports do. `ActionTable` (`actions/action_table.rb`) keeps `# @rbs @handlers: Array[untyped]` and `# @rbs @index: Hash[String, Integer]`; `register(name, handler)` returns false and adds nothing for a name already registered, `find(name)` returns `ActionHandler?` through a typed `handler_at(i)`, `kind_of(name)` returns the handler's kind or `:action`, and `names` lists the registered names in order. One namespace handler may be registered with `register_namespace(prefix, handler)`: a name no exact entry takes that starts with the prefix finds it, which is how `plugin.<name>.<action>` reaches the plugin host without the dispatcher knowing about plugins.

`UseCases::ExHandler` (`use_cases/ex/ex_handler.rb`) carries its name spec as a `Domain::ExName` built from Vim notation (`"w[rite]"`), answers `matches?(typed)` through it, and has `call(state, ex_command)` raising `NotImplementedError`. `ExTable` (`ex/ex_table.rb`) keeps the same two members; `register(handler)` refuses a handler whose full name or abbreviation is already registered, `find(typed)` walks the handlers in registration order and returns the first that matches, and `names` lists the full names. The handler carries the spec rather than the table, as the review asked, so a handler that serves several commands is registered once per command with its own spec.

Each feature registers its own handlers through a class method `register(table, ...)` with required keyword dependencies, for example `WindowHandler.register(table, split_window: split, close_window: close, focus_window: focus, resize_layout: resize, quit: quit)`. `EditorAssembly` calls the register functions in order and builds `Dispatcher.new(actions: table)` and `ExecuteEx.new(commands: table)`. The alternative of one class per action would add about seventy files for one-line bodies; a handler class per feature, each instance holding the variant it runs (`:left`, `:next`, `:write`), keeps the branches next to the feature they belong to and the number of classes small, which also keeps the virtual call on the hot path to a handful of receiver types.

Action handlers, under `use_cases/actions/`: `MotionHandler` (every name in `Domain::Motions::NAMES`, kind `:motion`, and `Motions::FIND_NAMES`, kind `:find`), `OperatorHandler` (the five pending operators, kind `:operator`, which run `Operate` in normal mode and `OperateOnSelection` in a visual mode), `EditHandler` (`x s S C D Y J p P`), `TextObjectHandler` (`Domain::TextObjects::NAMES`, kind `:text_object`), `InsertModeHandler`, `InsertTextHandler`, `NormalModeHandler` (`mode.normal`), `VisualModeHandler` (`mode.visual*`, `visual.reselect`), `SelectionHandler` (the other `visual.*` actions; `visual.replace` has kind `:char`), `CommandLineHandler`, `WindowHandler`, `TabHandler`, `PluginActionHandler` (the `plugin.` namespace), and `MessageHandler`, which answers a fixed message: the quit hint, `register.select` (kind `:register`, consumed by the grammar and never dispatched), and the reserved actions, which answer "Not implemented: name" as before. Ex handlers, under `use_cases/ex/`: `FileCommandHandler` (`w wq x exi wa wqa xa e q qa quita`), `WindowCommandHandler` (`sp vs new vne clo on`), `TabCommandHandler` (the `tab*` commands), and `PluginCommandHandler`, registered last, whose `matches?` asks the plugin host.

### The grammar reads kinds

`CommandGrammar#accept(action, kind, codes)` and `accept_visual(action, kind, codes)` take the kind `HandleKey` reads from the action table. `:register` waits for a register name, `:operator` starts a pending operator, `:find` and `:char` wait for a character, `:text_object` completes only under an operator, `:motion` completes on its own and as an operand, and `:action` completes at once. `OPERATORS`, `CHAR_MOTIONS`, `REGISTER_SELECT`, `VISUAL_REPLACE`, and the three name predicates are gone. The motion and text object name lists live with the functions that implement them (`Motions::NAMES`, `Motions::FIND_NAMES`, `TextObjects::NAMES`), whose `case` statements they mirror, and `Operate` asks `TextObjects.object?` for its operand. The grammar is simpler: it no longer knows a single action name. Its tests pass the kind with each action.

### Ex names

`Domain::ExName < Data.define(:short, :full)` is parsed from Vim notation by `ExName.parse("tabfir[st]")` and built for a plugin command with `ExName.new(abbreviation, command)`. `match?(typed)` holds when the typed name is at least as long as `short` and `full` starts with it. The core table registers its commands in the order of `docs/compatibility.md`: `w[rite] q[uit] wq x[it] exi[t] wa[ll] qa[ll] quita[ll] wqa[ll] xa[ll] e[dit] sp[lit] vs[plit] new vne[w] clo[se] on[ly] tabnew tabe[dit] tabc[lose] tabo[nly] tabn[ext] tabp[revious] tabN[ext] tabfir[st] tabl[ast]`. No two of these accept the same typed name, so the order only matters against plugin commands, which come after every core command (they start with an uppercase letter, so they never meet), and between plugins, where the first registered wins. Vim reports E464 for a prefix two user commands share; Carat's manifest gives every plugin command an explicit abbreviation, so the registration order is the documented rule instead. `PluginEntry#full_command` uses the same `ExName#match?`.

### Outcomes and the Reporting concern

`UseCases::Reporting` (`use_cases/concerns/reporting.rb`) has one method, `report(state, outcome)`, which shows a non-empty message as an error when the outcome failed, and needs no reader. `Dispatcher` includes it and reports each handler's outcome after the call; `HandleKey` includes it for its remap errors (E223 and a bad mapping), and `EditorAssembly#open` for the startup open and the configuration report. The use cases behind the handlers return their messages instead of writing them: `Operate#put` and `OperateOnSelection#put` return the E353 failure, the plugin router returns its refusals, `EditCommandLine#execute` returns the ex command's outcome, and `SwitchTab`'s is no longer dropped. `Outcome.none`, a shared frozen value, is returned where nothing is reported, so a key allocates no outcome. A message now lands after the whole command, where before a use case could write it in the middle; no command writes two, so nothing an existing test sees changes. A second candidate concern, `Counting`, was not added: `Command#count_or` already gives the count default in one place, and a concern's method would lose its signature on the hot path.

### Configuration problems at load time

`Keymap#add_checked(keymaps, leader, known, source)` adds the configuration's bindings as `add_all` does, but refuses a value that is an action name missing from `known` (a `Hash[String, bool]`), and records every problem of the configuration, malformed keys included, as `"#{source}: keymaps.#{mode}.#{key}: #{reason}"` in `errors`. `known` is the action table's names plus every action a registered plugin declares, enabled or not, so a binding of a disabled plugin's action is not reported. `EditorAssembly` takes the configuration's file name as `config_source:` (`JsonConfigGateway::SOURCE` and `FixedConfig::SOURCE`, both `config/default.json`), keeps the problems in `config_errors`, and `open` shows the first after the file's own message, as an error, with `" (and N more)"` when there are more. The `options-and-config` item, which reads the user and project files, passes each file's name.

### ExecuteEx moves to use_cases/ex

`ExecuteEx` parses the line, returns success for an empty one, E492 for a name no handler matches, and otherwise the handler's outcome. The write-all loop moves to `SaveFile#all`, which the `wa`, `wqa`, and `xa` handlers share; `edit` and `exit` become private methods of `FileCommandHandler`.

### Lint

`test/lint.rb` gains, each as a function with a known good and a known bad case asserted at the end:

- Constant references per layer: a code line (comments and string literals removed) naming `Domain::`, `Ports::`, `UseCases::`, `Adapters::`, `Doubles::`, `Drivers::`, or `Plugins::` from a file of a lower rank is a violation, as a `require_relative` already is. The ranks are entities and the plugin API 0, ports 1, use cases 2, adapters 3, doubles and drivers 4; a double never names a driver nor a driver a double. `carat/plugin_api.rb` requires nothing and names no layer.
- Naming: a file under a layer declares exactly one public class or module at its namespace level, named after the file in CamelCase (`carat/plugin_api.rb`, the API's single file, and `carat/domain/json.rb`, `Carat::Json`, are the recorded exceptions; the generated `default_config.rb` declares a constant only); layer subdirectories add no namespace and `carat/plugins/<name>/` adds `Plugins::<Name>`; class names are CamelCase; constants upper snake case; method names snake_case without the unclear abbreviations `cls fwd bck inc dec ws buf cnt idx tmp msg cmd num str val obj mgr ctx`; a method ending in `?` returns `bool`; a method returning `bool` ends in `?` unless it is a command listed in the lint table's `BOOL_COMMANDS` (`pump`, `handle`, `begin_transaction`, `decode_escape`, `decode_csi`, `decode_utf8`, `reveal`, `next_tab`, `resized`, `terminated`, `flag`, the word steps of `Motions`, and the tables' `register` and `register_namespace`); no `get_`, `is_`, or `has_`; `name!` only beside `name`; no `set_` method with one parameter outside the plugin API's request names (`plugin_api.rb` and `plugin_link.rb`); alternate constructors are `from_` class methods (no class method named `build`, `create`, or `make`, nor starting with `new_` or `build_from`; a helper such as `Operators.make_indent` is not a constructor); subclasses of `ActionHandler` and `ExHandler` end in `Handler`, ports in `Port`, doubles start with `Fake`, `Memory`, `Manual`, or `Fixed` (`EditorHarness` is the recorded exception: it assembles the doubles and is not one), concerns end in `ed`, `ing`, `able`, or `ible`.
- Constructors: a behavior class this change created or touched takes required keyword arguments; the files still to convert are listed in the lint table as pending for `state-and-ports`, so the list can only shrink.

The renames that follow: `Walker#cls` to `char_class`, `inc` to `forward`, `dec` to `backward`; `Runs#cls` to `class_at`; `Motions.fwd_word` to `forward_word`, `bck_word` to `backward_word`, `bckend_word` to `backward_word_end`; `Json::Parser#skip_ws` to `skip_whitespace`; `KeymapNode#child!` to `child_for`; `Keymap.build` to `Keymap.from_config`; `Buffer#modified` to `modified?`; `RegisterEntry#linewise` and `blockwise` to `linewise?` and `blockwise?`; the explorer's `Tree#set_root(path)` to `reroot(path)`. The domain files with several public classes are split into one file per class with no change to the classes. Use cases being verb phrases with `call` and drivers being concrete nouns are conventions the lint test cannot check and `CLAUDE.md` states.

### Where the plugin API lives

The code already treats `carat/plugin_api.rb` as the innermost ring: it requires nothing, and the domain's manifest and path rules name it. The architecture's "owned by the use case layer" is changed to say so: the API's values and base classes sit beside the entities, every layer may name them, and a plugin may name nothing else. `CLAUDE.md` loses "no layer" for the same sentence.

### Constructors

Classes created or touched here take required keyword arguments: the handlers, the tables, `ExecuteEx`, `Dispatcher`, `HandleKey`, `EditCommandLine`, `EnterInsert`, `InsertText`, `SaveFile`, `PluginHost`, `PluginRouter`, `EditorAssembly`, `EditorHarness`, and `FixedConfig`. A default is allowed only for a collaborator that takes no arguments, keeps no state, and does no I/O, because Spinel evaluates the default on every call (probed: two services built with the default did not share it); everything shared or needing input is a required keyword built once in `EditorAssembly`. `PluginHost` now receives `SplitWindow` and `OpenTab` instead of building its own.

## Risks / Trade-offs

- [A virtual call per key through the table] → the old path compared the action against up to 47 strings in turn; a hash lookup and one call are measured below against `main`.
- [Kinds come from the table, so a grammar test must state each action's kind] → the domain grammar test maps names to kinds in one small table; the editor tests go through the real table.
- [Prefix matching widens what a plugin command accepts] → a typed name must still be at least the declared abbreviation; the hello plugin's tests cover the new middle forms.
- [The lint naming rules are textual] → each rule has a good and a bad self-check; the exceptions are named in the lint table with their reason.
- [Splitting files changes many requires] → the classes do not change, and the require graph in `carat.rb` lists every file.

## Migration Plan

None: no data, configuration, or plugin API change. Rolling back is reverting the squash commit.

## Measured result

Key handling per key (the `handle` column of the scratch key benchmark, which excludes rendering) on a buffer of 10,000 lines, built from scratch copies of `main` at 9c45e9f and of this change, run alternately 15 times each pinned to one core:

| Keys | `main` median (min) | This change median (min) | Change of the median |
| --- | --- | --- | --- |
| `keys lh 2000 10000` (cursor only) | 17.8 us (15.8 us) | 18.3 us (15.6 us) | +2.8 percent |
| `keys i 2000 10000` (typing in the middle of a line) | 15.4 us (12.7 us) | 14.5 us (12.3 us) | -5.8 percent |

Both stay within the 10 percent the change allows. Unpinned runs on the shared machine scatter by more than 30 percent between runs of the same binary (12 to 23 us for typing), so only the pinned, interleaved medians are compared. `make types` shows 118 widened signatures against 124 on `main`: the dispatcher's `run`, `report`, the plugin host's `action`, and the use case entry points that returned nothing now return `Outcome`; `ActionTable#find` returns `ActionHandler` and `ExTable#find` returns `ExHandler`; the new widened entries are `void` methods run once at load (`add_checked`, the `register` functions) and `known_actions`, whose `bool` values are not pinned.
