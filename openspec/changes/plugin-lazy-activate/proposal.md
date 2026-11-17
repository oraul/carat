# Proposal

## Why

Every enabled compiled plugin is activated while the editor is assembled, before the first frame, and git_signs runs git in its `activate`. Startup is fast today (11.7 to 13.7 ms to the first frame), but each new plugin written to assume activation at startup adds to it and makes the rule harder to change later; the user asked that a plugin load only when it is first called, as the standard for every plugin.

This is outside the roadmap order of `docs/architecture.md` section 12: a user request delivered as Sprint 16's user-approved exception. It refines section 9 (Plugins).

## What Changes

- The host reads each enabled plugin's manifest at startup, resolving its options and merging its default bindings, without calling `activate`.
- A plugin is activated on its first trigger: the first action it declares (so the first key bound to one), the first ex command it declares, or the first time a buffer of a filetype it declares is highlighted.
- A plugin that declares no action, ex command, or filetype (git_signs) is activated when the editor first goes idle after the first frame, so git never runs before the first frame.
- Events reach a plugin only once it is active; events before that are not delivered, and `activate` reads the current state it needs instead.
- A plugin that raises in a late `activate` is disabled as today and the trigger does nothing more; the editor runs on. Only an active plugin is deactivated at quit.
- The plugin API moves to 2.9: the host contract, when `activate` is called and which events arrive, changed; no request was added or removed.
- The rule is written into `docs/architecture.md` section 9, `docs/plugins.md`, the plugin-host spec, and the `make new-plugin` template.

Assumption (minor, recorded here): the brief lists "the first event it declares" among the triggers. A plugin that also declares an action, ex command, or filetype is not woken by its events: the explorer subscribes to `cursor_move`, so the first cursor move would load it and defeat the user's "loaded only when I call it". Events wake only a plugin with no other trigger, and they wake it at the first idle after the first frame, the moment the brief names for git_signs.

Out of scope: process plugins (none exist yet); an `idle` event for plugins (it arrives with the language services change); unloading a plugin after use; any change to the plugin requests.

## Capabilities

### New Capabilities

### Modified Capabilities
- `plugin-host`: plugins activate on their first trigger instead of at startup; events reach only active plugins; a plugin running ex commands while activating does so at its first trigger.

## Impact

- `carat/use_cases/plugins/` (registry, entry, router, events, syntax, host), `carat/adapters/input_controller.rb` and `editor_assembly.rb` (the idle wake), `carat/plugin_api.rb` (VERSION 2.9, the `activate` contract), `tools/new.sh` (the template).
- Tests: `test/editor_lazy_plugins.rb` (new), `test/editor_git_signs.rb`, `test/use_cases_plugins.rb`, `test/use_cases_plugin_hardening.rb`, `test/editor_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb`, and the other plugin tests whose plugins now activate on a trigger.
- Docs: `docs/architecture.md` section 9 (changed), `docs/plugins.md`, `docs/codebase-map.md` (area 15 and the new test).
- README.md: unchanged, it does not describe when plugins activate.
- CLAUDE.md: unchanged, no process changes.

## Results

- Startup to the first frame, in a pty over 15 runs: before 11.7 to 13.7 ms (79b6b7c, brief); after: filled in by task 6.2.
