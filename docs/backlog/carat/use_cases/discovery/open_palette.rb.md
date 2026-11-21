# Backlog: carat/use_cases/discovery/open_palette.rb

## The palette lists and replays unchecked plugin action names

- Where: `carat/use_cases/discovery/open_palette.rb` line 79, which lists every `plugin.<name>.<action>` of an enabled plugin's manifest, and `carat/use_cases/handle_key.rb` line 269, which replays a chosen name that is not an action name as keys, at d828abb. Security Low findings (confidence 3 and 5) in `discoverability`.
- Why it matters: a compiled-in plugin whose manifest fails `ManifestCheck` can declare an action such as `plugin.explorer.:w ~/.bashrc<CR>`, which is listed because the plugin is enabled, and Enter on it types the keys. No new capability, since a plugin can already bind replays in its manifest defaults, but the palette should only ever dispatch actions.
- Fix outline: build the plugin entries from a registry method returning the enabled plugins' checked action names (only those for which `Domain::Keymap.action_name?` holds), and in `HandleKey` dispatch the palette's chosen name only when `Domain::Keymap.action_name?` holds, never through replay, with a row in `test/editor_palette.rb` for a refused name.
- Also: carat/use_cases/handle_key.rb, test/editor_palette.rb
- Category: security
- Added: 2026-11-09

## OpenPalette re-parses plugin action names

- Where: `plugin_of` in `carat/use_cases/discovery/open_palette.rb` line 91 against `PluginRouter` line 36, and the one-line single-use `palette_add_plugin` at line 85, at d828abb. Quality advisories in `discoverability`. Raised again at 38628bb and b76b722 (periodic quality); a second entry for `palette_add_plugin` was folded in here at 186ddfb. Queued in `menu-hints`.
- Why it matters: two parsers of `plugin.<name>.<action>` can drift, and the wrapper adds a hop for one call.
- Fix outline: have `PluginRegistry` return the enabled plugins' action names (the same method the palette entry above needs) and inline `@palette.add` into `add_plugin_actions`.
- Category: editor
- Added: 2026-11-09

### Palette_add_plugin is a one-line private wrapper over @palette.add (sprint-20 sweep quality, open_palette.rb:72)

- Location: `carat/use_cases/discovery/open_palette.rb:72`
- Why: palette_add_plugin is a one-line private wrapper over @palette.add called from one place
- Fix: inline it in add_plugin_actions
- Category: editor
- Added: 2026-11-19
