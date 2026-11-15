# Proposal

## Why

The architecture review (openspec/changes/archive/2026-11-15-architecture-review/design.md, H3, R1, R3) found three loose ends: `language.ruby.formatter` is shipped and validated but nothing reads it, so a user who sets it gets silence; ex command descriptions sit in one `DESCRIPTIONS` constant of `ExTable` apart from the registrations, unlike action descriptions, so a new ex command can be registered without one; and five methods are never called while two plugin API predicates are called by nothing in the tree and named nowhere in `docs/plugins.md`.

## What Changes

- The shipped `language.ruby.formatter` line leaves `config/default.caratrc` (and its generated mirror). A `language.<name>.formatter` line in the defaults or the user file is answered "language setting formatter is not supported yet" and not kept, until roadmap item 14 (`plugin-git-and-formatting`) runs a formatter; from a project file it is still refused as a language command first.
- `ExTable#register` takes the command's description beside its handler, as `ActionTable#register` does; `DESCRIPTIONS` is removed and each ex family's `self.register` passes the description of each name it registers. `describe` answers the description given at registration. The palette shows the same text for every command.
- A test of the table checks that a description arrives with its registration, and the assembly check that every ex command has a description of 1 to 32 characters now fails on a command registered with an empty one.
- `DisplayWidth.of_char`, `ExtendVisual#tabstop_of`, `CommandGrammar#operator_pending?`, `TabRequest#counted?`, and `FakeTerminal#input?` are removed with their code-map entries.
- `PluginApi::Command#args?` and `PluginApi::Edit#insertion?` stay, since third-party plugins may call them, and are documented in `docs/plugins.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `config-files`: an added requirement, a formatter line is answered as not supported yet and none is shipped.

## Impact

- `config/default.caratrc`, `carat/domain/default_config.rb` (regenerated), `carat/domain/config.rb`, `test/domain_rc_parser.rb`.
- `carat/use_cases/ex/ex_table.rb` and the sixteen `carat/use_cases/ex/*_command_handler.rb` families, `tools/new.sh` (the ex command generator writes a description), `tools/tools_test.sh`, `test/use_cases_actions.rb`.
- `carat/domain/display_width.rb`, `carat/use_cases/visual/extend_visual.rb`, `carat/domain/command_grammar.rb`, `carat/use_cases/windows/tab_request.rb`, `carat/doubles/fake_terminal.rb`.
- `docs/plugins.md`, `docs/codebase-map.md`, `docs/examples.md` where it names the ex wiring.
- README.md: changed, the `language.*` paragraph no longer offers a formatter command.
- docs/architecture.md: changed, section 7's example and scope list drop the formatter setting, which section 8 keeps as planned.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.

Outside the roadmap of `docs/architecture.md` section 12: a tidy from the architecture review; it prepares item 14 by leaving no half-shipped formatter setting.

## Out of scope

- Running a formatter (roadmap item 14) or any `FormatBuffer` use case.
- Removing `args?` or `insertion?`: they face third-party plugins and removing them would need a major plugin API version.
- Other findings of the architecture review, the queue's order, and the backlog's other entries.

Assumptions recorded here instead of asked: the formatter setting is both unshipped and answered with a message, because unshipping alone would leave a user's line reported as an unknown setting while roadmap item 14 plans it; the message is a configuration problem reported like every other, not a separate notice; a plugin's ex commands register through `PluginCommandHandler` with an empty description, since the handler has no name and the palette lists only named commands.
