# Backlog: carat/use_cases/plugins/plugin_router.rb

## Plugin, grammar, and generator findings at df4654c

- Where: `carat/use_cases/plugins/plugin_router.rb` line 44 (the register string passed uncopied), `carat/domain/manifest_check.rb` line 32 (shapes checked twice, a dead guard at line 145), `carat/use_cases/plugins/plugin_registry.rb` line 175 (`leave` repeats `cause`), `carat/plugins/hello/plugin.rb` line 11 (stale comment, the action spelled beside `GREET`), `carat/plugins/registry.rb` line 2 and the `default_config.rb` header (generator names `spin run`), `test/lint.rb` line 845 (plugins exempt from keyword constructors, unstated in CLAUDE.md), comment wraps at `carat/plugin_api.rb` line 480 and 732, `window_requests.rb` lines 28 and 67, `ui_requests.rb` line 15, `carat/domain/plugin_ui.rb` line 7; `carat/domain/command_grammar.rb` line 138 (`accept` and `accept_visual` repeat a prefix), `carat/adapters/input_controller.rb` line 137 (`next_timeout` ignores `state`). Periodic quality advisories. Queue item 39 (backlog items by domain). Raised again at ce6abdb (periodic quality): `accept_visual` (`command_grammar.rb:163`), queue item `editing-counts`: one shared grammar opening.
- Why it matters: the router breaks the strings-copied plugin rule; the rest are copies, dead code, and drift.
- Fix outline: `command.register.dup`; one shapes result; pop then set from `cause`; reword and key by `GREET`; generator writes `make gen-config`; state the exemption or give `Tree` keywords; rewrap; one shared grammar step; drop the parameter.
- Also: carat/domain/manifest_check.rb, carat/use_cases/plugins/plugin_registry.rb, carat/plugins/hello/plugin.rb, carat/plugins/registry.rb, test/lint.rb, CLAUDE.md, carat/plugin_api.rb, carat/domain/plugin_ui.rb, carat/domain/command_grammar.rb, carat/adapters/input_controller.rb
- Category: plugins
- Added: 2026-11-09

### Plugin host strings, focus, and parameters

- Location: carat/use_cases/plugins/plugin_router.rb:77, window_requests.rb:303, plugin_host.rb:189 (sprint-4 sweep, quality).
- Why: answer passes prompt_id uncopied; in_window restores focus only after the block returns, so a raise leaves it moved; follow_prompt takes the state the host keeps.
- Fix: id.dup; restore in ensure; drop the parameter.
- Category: plugins
- Added: 2026-11-14

### PluginRouter spells the registry's refusal texts again

- Location: carat/use_cases/plugins/plugin_router.rb:40 against PluginRegistry#refusal (plugin_registry.rb:100). Sprint-6 sweep, quality advisory. Queue item `plugin-host-tidy`.
- Why: duplication of the no-plugin and disabled texts.
- Fix outline: use the registry's refusal and fail when it is not empty.
- Category: plugins
- Added: 2026-11-15

### PluginRouter#answer hands the prompt id uncopied (sprint-24 sweep quality)

- Location: `carat/use_cases/plugins/plugin_router.rb:81`, `:91`
- Why: answer passes `ui.prompt_id` uncopied while follow_prompt copies it, against the strings-copied rule of the plugin boundary.
- Fix: `id: id.dup`.
- Category: plugins
- Added: 2026-11-21

### PluginRouter#action respells the registry's refusal (sprint-24 sweep quality)

- Location: `carat/use_cases/plugins/plugin_router.rb:41`
- Why: PluginRegistry#refusal already builds both messages.
- Fix: return `Outcome.failure(@registry.refusal(plugin_name))` when it is not empty.
- Category: plugins
- Added: 2026-11-21
