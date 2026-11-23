# Backlog: carat/use_cases/plugins/plugin_registry.rb

### Registry locals still named e
- Location: carat/use_cases/plugins/plugin_registry.rb (register, activate, disable, and the binding merge name an entry e)
- Why: the brief's locals-named-e rename listed the host, events, buffer, ui, and router files; the registry's own locals keep the short name.
- Fix: rename each to entry in the same way, a mechanical change with no behavior.
None.
- Category: plugins
- Added: 2026-11-23

### the plugin-host-lows rename of the one-letter local e to at carat/use_cases/plugins/plugin_registry.rb:98 (sprint-30 sweep quality, note 33)

- Location: carat/use_cases/plugins/plugin_registry.rb:98
- Why: the plugin-host-lows rename of the one-letter local e to entry or found stopped short: plugin_registry.rb keeps e at lines 98, 105, 112, 155, 206, 238, 289, 305 and in disable, refuse, first_problem, and merge_bindings parameters, and plugin_syntax.rb:47 keeps e, against the naming rule of no unclear abbreviations
- Fix: rename them to entry as plugin_router.rb and plugin_events.rb now do
- Category: plugins
- Added: 2026-11-23
