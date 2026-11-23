# Backlog: carat/use_cases/plugins/plugin_router.rb

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

### Plugin on_action is guarded after activate, and manifest_check shapes
- Location: carat/use_cases/plugins/plugin_router.rb:44 (the guarded on_action after activate) and carat/domain/manifest_check.rb:32 (check_shapes, shapes_ok?)
- Why: the brief named only these two locations of the "Plugin, grammar, and generator findings at df4654c" entry, without the finding's text, and the delivery may not read the backlog; this change did not alter either, so the entry stays open.
- Fix: read the entry's text in a later sprint's planning, then fix each location as it says, with a test per branch.
- Also: carat/domain/manifest_check.rb
- Category: plugins
- Added: 2026-11-23
