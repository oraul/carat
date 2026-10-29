# Proposal

## Why

Everything beyond core modal editing is meant to be a plugin, and the next roadmap items, the explorer and the finder, cannot start until there is a plugin API, a host that routes actions, ex commands, events, and requests, a registry that compiles the built-in plugins into the binary, and a side window a plugin can draw a list in. Roadmap item 11 of `docs/architecture.md`, `plugin-host`, delivers exactly that, proven by a tiny `hello` plugin so the API is exercised by the project itself from the first plugin change.

## What Changes

This change delivers roadmap item 11, `plugin-host`. The explorer and the finder are item 12 and are not part of it.

- Add `carat/plugin_api.rb`, the only file a plugin may require: the manifest value (name, version, API version, actions with descriptions, ex commands with abbreviations, default bindings in the JSON keymap shape, event subscriptions, options with types and defaults), the event value, the action context and ex command values, the edit value, the response values, the host base class with one method per request, and the plugin base class with `manifest`, `activate(host)`, `deactivate`, `on_event(event)`, `on_action(name, context)`, and `on_command(command)`. Every request and response is a value with no callbacks.
- Add the plugin host use case: it registers the compiled plugins, validates every manifest and refuses one written against a newer major API version with a message, reads the `plugins` entries of the configuration to enable or disable each plugin and to resolve its options, merges each enabled plugin's default bindings below the user's bindings, routes `plugin.<name>.<action>` actions and the plugin's ex commands to the plugin, delivers the events `buffer_open`, `buffer_change`, `buffer_save`, `cursor_move`, `mode_change`, `window_focus`, `resize`, and `quit` as values after the use case that caused them, and executes requests against the editor state and the ports: read a buffer, apply a list of replacements as one validated transaction, move the cursor, open a scratch buffer in a fixed-width side window with the plugin's own keymap, replace a scratch buffer's lines, close the plugin's window, focus a window, open a file in a window, show a message, set a status line segment, place and clear signs, run an ex command, list a directory, stat a path, look up an icon, and read an option. A plugin that raises is disabled with a message in the message row and the editor keeps running; the editor starts, edits, saves, and quits with every plugin disabled.
- Add scratch buffers: a buffer with no path owned by a plugin, titled, shown in a side window on the left or the right edge of the tab page that keeps its width on resize and equalize, with a keymap of its own that wins over the mode's keymap while the cursor is in that window and falls back to it otherwise; `:q` in that window closes it, `:w` on it reports `E382`, `:wa` skips it, and `:qa` does not count it as modified.
- Add `config/plugins.json`, the ordered list of the built-in compiled plugins, from which `bin/carat-gen-config.rb` now also generates `carat/plugins/registry.rb` with one explicit `require` and one constructor call per plugin; `test/config_sync.rb` fails when the registry is stale, and the `lint` test gains the rule that a file under `carat/plugins/<name>/` requires only `carat/plugin_api.rb` and files in its own directory.
- Add the `icons` option with the values `nerd` (the default), `unicode`, and `ascii`, and an icon table in the domain mapping names (folder closed, folder open, file, symlink, modified, error, warning, info, hint, and the file types ruby, json, markdown, toml, makefile, shell, c, yaml, git, lock, and a default) to one glyph per set; plugins ask for icons by name, so the option switches the whole editor. The private use areas U+E000 to U+F8FF and U+F0000 to U+FFFFD, where Nerd Font glyphs live, count as one cell wide.
- Add the sign column, two cells before the line numbers, shown while a buffer has signs, and the status line segments of plugins after the file name on the current window's status line; a scratch buffer's status line shows its title.
- Add the built-in `hello` plugin under `carat/plugins/hello/`: the action `plugin.hello.greet` bound by default to `<leader>hh`, the ex command `:Hello` with the abbreviation `:Hel`, a subscription to `buffer_open`, a message with the info icon, a status segment, and a `greeting` option. It is listed in `config/plugins.json` and enabled in `config/default.json`.
- Add `docs/plugins.md` on writing a compiled plugin, a README section on icons and Nerd Fonts, the new action in `docs/actions.md`, and the updates to `CLAUDE.md` and `docs/architecture.md`; add the domain, use case, and editor tests listed under Impact.

Out of scope, left for later changes: the explorer and the finder (item 12); process plugins and `docs/plugin-protocol.md` (item 13); the `idle` event, which needs an idle tick the main loop does not have and arrives with the language services change; highlights for a range and virtual text, which need highlight groups a plugin can own and arrive with the syntax highlighting change; a child process request, which arrives with `ProcessPort`; selection and marks in the buffer view and the `set_selection` and `set_mark` requests, which need the visual modes and marks; asking for input on the command line with a prompt; undoing a plugin edit in one step, which needs the undo tree; shifting signs when lines are inserted or deleted above them; floating windows; and the user and project configuration files themselves (item 9), although a configuration value that disables a plugin is honored wherever it comes from.

Assumptions recorded here rather than asked:

- The API version is `1.0`. A manifest names the version it was written against as `major.minor`; the host refuses a greater major and accepts any minor.
- A plugin name is lowercase letters, digits, and underscores starting with a letter; an action name is `plugin.<name>.<action>` with the plugin's own name; an ex command name starts with an uppercase letter, as Vim's user commands do, and its abbreviation is a proper prefix of it or empty.
- A plugin's default bindings may name only the plugin's own actions or key sequences to replay, and a user binding of the same keys, including `null`, replaces them.
- Buffers are referred to by their position in the buffer list counted from 1, with 0 meaning the current buffer; windows by their position in the current tab page's layout order counted from 1, as `<C-w>w` counts them, with 0 meaning the current window.
- The events are produced after a key has been handled, by comparing the editor state with the state after the previous key; `buffer_save` is produced by the write itself and `resize` by the render that sees a new size. Changes a plugin makes while handling an event do not produce events, and `idle` is deferred.
- An edit is a charwise replacement with an exclusive end; the edits of one request must be in ascending order and must not overlap, and one bad edit refuses the whole request with a message naming it.
- A scratch buffer's own keymap is consulted first in every mode; a key it does not bind falls through to the mode's keymap, so the cursor motions still work in a plugin window. Editing a scratch buffer is not prevented, but it is never considered modified for `:q`, `:qa`, and `:wa`.
- The side window takes the full height of the tab page at its left or right edge, is fixed-width, and reports `E36` when the layout cannot give it its width and leave the other windows their minimum. The window number of the new window is returned to the plugin.
- A sign is a glyph on one line; the last sign placed on a line wins, and a plugin clears only the signs it placed. The sign column is two cells wide and appears only while the buffer has signs.
- A status segment is one per plugin, shown on the current window's status line after the file name and the modified marker, in registration order, and removed when set to the empty text.
- The `hello` plugin counts the buffers it saw opened and greets with the option `greeting` and the name given to `:Hello`, defaulting to "world"; it sets no message on `buffer_open`, so the startup screen is unchanged.
- A plugin's option value of the wrong type keeps the manifest default and is recorded by the host, as a malformed binding is.
- The `unicode` icon set uses triangles, bullets, and geometric shapes present in common terminal fonts; the `ascii` set uses plain characters. An unknown icon name yields the empty string.

## Capabilities

### New Capabilities

- `plugin-host`: registration and validation of compiled plugins, enabling and options from the configuration, routing of plugin actions and ex commands, event delivery, the requests a plugin can make, failure isolation, and the generated registry.
- `plugin-windows`: scratch buffers owned by a plugin, the side window that shows them, their own keymap, and how the file commands treat them.
- `icons`: the icon table, the `icons` option and its sets, and the display width of the private use areas.

### Modified Capabilities

- `keymap-config`: the bindings are built from the enabled plugins' default bindings and then the configuration, so a configuration binding wins; an action name may have more than one namespace segment.
- `screen-rendering`: the status line shows a scratch buffer's title and the plugins' status segments, and a buffer with signs gets a sign column before the line numbers.
- `command-line-mode`: `:wa` and its forms skip scratch buffers.

## Impact

- New: `carat/plugin_api.rb`; `carat/domain/manifest_check.rb`, `carat/domain/icons.rb`, `carat/domain/registry_source.rb`; `carat/use_cases/plugins/plugin_entry.rb`, `plugin_link.rb`, `plugin_host.rb`; `carat/plugins/registry.rb` (generated) and `carat/plugins/hello/plugin.rb`; `config/plugins.json`; `docs/plugins.md`.
- Changed: `carat/domain/buffer.rb` (owner, title, keymap, signs, change counter), `editor_state.rb` (status segments, scratch rules in the modified checks and release), `window.rb` (sign column in the gutter), `layout.rb` (split at the edge of the tab page), `options.rb` (`icons`), `keymap.rb` (adding bindings to an existing keymap), `display_width.rb`; `carat/use_cases/handle_key.rb` (scratch keymap first, plugin action names, event observation), `dispatcher.rb`, `files/execute_ex.rb`, `files/save_file.rb`; `carat/adapters/frame_presenter.rb`, `editor_assembly.rb` (takes the plugin list); `carat/doubles/editor_harness.rb`; `bin/carat.rb`, `bin/carat-gen-config.rb`; `config/default.json` (`icons`, the `plugins` entries); `test/lint.rb`, `test/config_sync.rb`; `carat.rb`.
- Tests: new `test/domain_plugin_manifest.rb`, `test/domain_icons.rb`, `test/use_cases_plugins.rb`, `test/editor_plugins.rb`; extended `test/domain_buffer.rb`, `test/domain_layout.rb`, `test/domain_keymap.rb`, `test/adapters_frame_presenter.rb`, `test/use_cases_ex.rb`, `test/config_sync.rb`, `test/lint.rb`, with their snapshots.
- Docs: `docs/plugins.md`, `docs/actions.md`, `README.md`, `CLAUDE.md`, `docs/architecture.md`. No new dependencies and no new ports.
