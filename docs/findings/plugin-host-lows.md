### Plugin on_action is guarded after activate, and manifest_check shapes
- Location: carat/use_cases/plugins/plugin_router.rb:44 (the guarded on_action after activate) and carat/domain/manifest_check.rb:32 (check_shapes, shapes_ok?)
- Why: the brief named only these two locations of the "Plugin, grammar, and generator findings at df4654c" entry, without the finding's text, and the delivery may not read the backlog; this change did not alter either, so the entry stays open.
- Fix: read the entry's text in a later sprint's planning, then fix each location as it says, with a test per branch.
### The grep picker's file reads stay synchronous on the editor thread
- Location: carat/plugins/finder/grep.rb load (host.read_file per listed file)
- Why: the byte budget (READ_BUDGET, 16 MiB) bounds the work of one opening but the reads still run on the editor thread; up to 16 MiB is read before the first frame of the picker.
- Fix: read the files in slices across idle ticks, or lazily on the first typed key, with the cap mark shown while the load runs.
### Registry locals still named e
- Location: carat/use_cases/plugins/plugin_registry.rb (register, activate, disable, and the binding merge name an entry e)
- Why: the brief's locals-named-e rename listed the host, events, buffer, ui, and router files; the registry's own locals keep the short name.
- Fix: rename each to entry in the same way, a mechanical change with no behavior.
