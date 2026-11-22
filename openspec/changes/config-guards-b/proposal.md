# Proposal

## Why

A project's `.caratrc` is untrusted, yet two holes stayed open in what it may bind. `Config::PROJECT_REFUSED` is a denylist of four actions plus the `cmdline.` prefix, so every other action stays bindable from a cloned repository, a plugin's file actions among them: `keymap.normal x plugin.explorer.delete` binds a key to deleting a file. And a project `none` unbinds any key, so `keymap.normal : none` takes the command line away and the quit and save keys go the same way. These are the sprint-24 security review's notes 1 and 2 and the untrusted-project finding, the backlog headings "A project .caratrc can bind a key to a plugin's file action" and "Config predicates note problems and repeat the none word". The predicates `language?` and `binding?` of `Config` also note problems as a side effect and repeat the keymap words (`"none"`, `"group"`, `"leader"`) that `Keymap` names too. This is part 1 of the queue entry `config-guards-b`, split by the planner; the options, `:set`, gateway, input controller, and gen-config tidies are queued as `config-guards-c`. Outside the roadmap: a security fix of the configuration files (roadmap item 9, delivered).

## What Changes

- An allowlist replaces the denylist: `Config::PROJECT_BINDABLE` names the action families a project file may bind in any mode (motions, operators, text objects, the visual, insert, completion, fold, scroll, search, history, register, jump, buffer, tab, tabline, layout, docs, definition, palette, float, message, substitute, and mode actions) and the window actions but `window.quit`. Every other action, every `plugin.*` action included, is refused as `file:line: <action> is not bound from a project file`.
- A project keymap line, `none` included, may not take a key from a binding it could not make itself, read from the defaults and the user file in effect before it: a write, a quit, a command-line action, a plugin action, a key sequence, or `mode.cmdline` on `:`. It is refused as `file:line: <keys> runs <action>, which a project file may not unbind or rebind`. Keys compare by the codes they spell under the leader, so `<Space>fs` is `<leader>fs`.
- `Config#language_problem` and `Config#binding_problem` return the problem text and `add` notes it, in place of the predicates that noted as a side effect. `Config::NONE`, `GROUP`, `LEADER`, and `DEFAULT_LEADER` name the keymap words once; `Keymap` uses them, and `Config#leader` and `Config.leader_problem` hold the leader rule `Keymap.leader_from` now delegates to.
- Docs: the README's configuration paragraph, `docs/architecture.md` section 7's project-file rule, and the `config.rb` and `keymap.rb` lines of `docs/codebase-map.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `config-files`: MODIFIED "A project file cannot bind keys to a write, a quit, or the command line" (an allowlist, plugin actions refused, and no unbinding or rebinding of a held key); MODIFIED "A project file cannot bind keys to key sequences" (its last sentence names the allowlist).

## Out of scope

- The queue's second part, `config-guards-c`: `options.rb` and the eight `icons == "ascii"` sites, `set_command_handler.rb` PENDING, `rc_config_gateway.rb:33`, `input_controller.rb:96` and `:144`, and `bin/carat-gen-config.rb`.
- A plugin's manifest bindings are not read by `Config`, so a project line rebinding a key only a plugin's manifest binds is not held; no shipped manifest binds a write, a quit, or the command line.
- No `tools/rules.sh` edit; no file of the feature lane.
- Assumption: refusing a rebinding as well as `none` is the same guard; the brief names `none`, and `: cursor.down` takes the command line away just as `: none` does.
- Assumption: the parse-error note in `add` keeps its hand-made `source:number:` text, since a line that does not parse has no `RcLine` to format it.

## Impact

- README.md: the configuration paragraph says which actions a project file may bind and that it cannot unbind or rebind the held keys.
- docs/architecture.md: section 7's project-file rule says the same.
- docs/codebase-map.md: the `config.rb` and `keymap.rb` lines.
- CLAUDE.md: unchanged, no process change.
- Performance: the held keys are read once per untrusted file, so a project line costs one key parse and one table lookup; no key's path changes.
