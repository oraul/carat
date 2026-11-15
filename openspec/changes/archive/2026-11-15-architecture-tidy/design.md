# Design

## Context

Three findings of the architecture review (H3, R1, R3), each small and each in a different area: configuration (`carat/domain/config.rb`, `config/default.caratrc`), the ex command table (`carat/use_cases/ex/ex_table.rb` and the sixteen families' `self.register`), and five uncalled methods plus two plugin API predicates no code in the tree calls.

## Goals / Non-Goals

Goals: no shipped setting that does nothing, and a clear answer to a user who sets it; an ex command's description written where its name is registered, so a registration without one is visible in the diff and caught by a test; no uncalled method left undocumented. Non-goals: running a formatter, changing any palette text, removing plugin API methods.

## Decisions

### The formatter setting: unshipped and answered

`LANGUAGE_SETTINGS` becomes `["lsp"]`, and a private `PLANNED_SETTINGS = ["formatter"]` names the settings roadmap item 14 will read. `Config#language?` checks the planned list after the known one and notes "language setting formatter is not supported yet", returning false so the line is not kept. The shipped line and its comment mention go from `config/default.caratrc`; `make gen-config` regenerates the mirror, which `test/config_sync.rb` compares. A project file's line is still refused first by the project-file rule, so the trust boundary is unchanged.

Alternatives: removing `formatter` outright would report "unknown language setting formatter", true but misleading for a setting the roadmap plans; keeping the shipped line and noting it would show a problem at every start, or need a suppression for shipped lines (as `PluginRegistry` does), which keeps a line nothing reads.

### Ex descriptions travel with registration

`ExTable#register(handler, description)` (`(ExHandler, String) -> bool`) stores the description in `@descriptions`, keyed by full name, only for a named handler, beside `@names` and `@full_names`; `describe(full)` reads it. Each family's `self.register` passes the text that `DESCRIPTIONS` held for each name, a `descriptions` array beside `specs` and `variants` where a family registers in a loop, so every palette row stays as it is. `PluginCommandHandler` passes "" (it has no name; plugin commands are not in the palette's ex list). The required positional argument means a registration without a description does not compile; one with an empty description fails the assembly check "every ex command has a description of 1 to 32 characters" in `test/use_cases_actions.rb`. A table test checks that `describe` answers the text given at registration and "" for a name not registered. The `new-ex-command` generator writes `"TODO: short description"` in the registration, as the action generator does, so the place to fill is in the generated code.

### Dead code and the plugin API predicates

The five methods have no caller in `carat/`, `bin/`, `test/`, `bench/`, or `tools/` and are removed, with the names in the map lines of `command_grammar.rb`, `tab_request.rb`, and `display_width.rb` (`test/lint.rb` fails on a map line naming a method its file lacks). `args?` and `insertion?` are part of `carat/plugin_api.rb`, the one file a plugin requires; removing them could break a plugin outside the tree and would need a major API version, so they are documented in `docs/plugins.md` where `Command` and `Edit` are described.

## Risks / Trade-offs

- Every ex family file changes, a wide but mechanical diff; the palette test and the compatibility table test cover it.
- A user who had copied the formatter line into the user file now sees a startup problem; that is the intended answer, and the line had no effect before.
