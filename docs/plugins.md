# Writing a compiled plugin

Everything beyond core modal editing is a plugin on one API, `carat/plugin_api.rb`, and that file is the only one a plugin may require. A compiled plugin is a Ruby class compiled into the binary with the editor; it runs on the editor thread, obeys the Spinel rules of `docs/architecture.md` section 2.1, and talks to the editor only through values. This document is the practical guide; the `plugin-host`, `plugin-windows`, `icons`, and `file-explorer` specs under `openspec/specs/` are the contract. `carat/plugins/explorer/` is a complete plugin that ships with the editor; `carat/plugins/hello/plugin.rb` is the smallest complete example, a test fixture that is not in `config/plugins.json`, so the editor does not contain it and the tests register it directly.

## The files

A plugin named `thing` lives in `carat/plugins/thing/`. Its files require `carat/plugin_api.rb` (as `require_relative "../../plugin_api"`) and files in their own directory, nothing else; the `lint` test fails on any other `require_relative`. The class is `Carat::Plugins::Thing::Plugin < Carat::PluginApi::Plugin`, with inline RBS signatures on every method and instance variable like the rest of `carat/`.

The plugin is listed in `config/plugins.json`, in the order the plugins are registered:

```json
{ "name": "thing", "path": "thing/plugin", "class": "Carat::Plugins::Thing::Plugin" }
```

`make gen-config` then regenerates `carat/plugins/registry.rb`, one `require_relative` and one constructor call per entry; the `config_sync` test fails while the generated file is stale. The `plugins` object of `config/default.json` gets an entry `"thing": { "enabled": true, "options": { ... } }` with the option values the shipped configuration wants; a plugin with no entry is enabled with its manifest defaults.

## The manifest

`manifest` returns a `Carat::PluginApi::Manifest` value:

- `name`: lowercase letters, digits, and underscores, starting with a letter; the same as the directory and the configuration key.
- `version`: the plugin's own, free-form.
- `api_version`: the API this plugin was written against, `"1.1"` today (`Carat::PluginApi::VERSION`). The host refuses a greater major version and accepts any minor. Version 1.1 added `working_directory`, `editing_window`, `scratch_window`, `make_file`, `make_dir`, `rename_path`, `delete_path`, `prompt`, `on_input`, `FileInfo#symlink`, and `PluginApi::Paths`; a 1.0 plugin keeps working unchanged.
- `actions`: a hash from action name to a one-line description. Every action is `plugin.<name>.<action>`, with the plugin's own name, and goes into `docs/actions.md`.
- `commands`: a hash from ex command name to its abbreviation, or `""` for none. A name starts with an uppercase letter, as Vim's user commands do, and the abbreviation is a proper prefix of it.
- `bindings`: default key bindings in the JSON keymap shape, `{"normal" => {"<leader>tt" => "plugin.thing.toggle"}}`, or `nil`. A value is one of the plugin's own actions or a key sequence to replay. The host adds them to the keymap before the configuration's `keymaps`, so a user binding of the same keys replaces them and `null` removes them.
- `events`: the symbols the plugin wants delivered, among `Carat::PluginApi::EVENTS`.
- `options` and `option_types`: the option names with their defaults as text and their types, `:bool`, `:integer`, `:string`, or `:list`. Values travel as text: `"true"` or `"false"`, digits, the string, or list items joined by newlines.

A manifest that breaks a rule registers the plugin disabled with the rule as the reason; `make test` shows it through `test/use_cases_plugins.rb` style checks, and `Carat::Domain::ManifestCheck.check` is what runs.

## The base class

Override what the plugin needs:

- `activate(host)`: called once when the plugin is enabled, with the plugin's own `Carat::PluginApi::Host`. Keep it in an instance variable typed `Carat::PluginApi::Host?` and assign `nil` in `initialize`, since Spinel needs every instance variable assigned there.
- `deactivate`: called when the editor quits.
- `on_event(event)`: a `Carat::PluginApi::Event` with `name`, `buffer`, `window`, `path`, `row`, `col`, and `detail`.
- `on_action(name, context)`: one of the plugin's actions with a `Carat::PluginApi::Context`: the `count` and `register` typed before the key, the current `buffer` and `window` numbers, the `path`, and the cursor `row` and `col`.
- `on_command(command)`: a `Carat::PluginApi::Command` with the declared `name`, `bang`, and `args`.
- `on_input(input)`: a `Carat::PluginApi::Input` with the `id` the plugin gave a prompt, the `text` typed, and `cancelled`, when a prompt the plugin opened ends.

A plugin that raises in any of these is disabled with "Plugin thing disabled: ..." in the message row; the editor goes on, and the plugin's later requests are refused. Keep the work inside a call small: the editor draws after the key returns.

## Numbers

Buffers are numbered by their position in the buffer list from 1, as `:wa` reports `E141`; windows by their position in the current tab page's layout order from 1, as `<C-w>w` counts them. `0` means the current one. Both move when buffers or windows come and go, so read what is needed in the same call rather than keeping a number across keys.

## Requests

Every method of the host takes plain values and returns a value; nothing calls back into the plugin. Most return a `Response` with `ok`, `message`, `number`, and `lines`.

| Request | Returns |
| --- | --- |
| `read_buffer(number)` | a `BufferView`: `ok`, `number`, `path`, copies of the `lines`, the cursor `row` and `col` when the buffer is the current one, `modified` |
| `edit_buffer(number, edits)` | applies a list of `Edit` values (`from_row`, `from_col`, `to_row`, `to_col`, `text`; exclusive end, ascending, not overlapping) as one batch; one bad edit refuses them all with its number in the message |
| `move_cursor(row, col)` | moves the cursor of the current window, clamped into the buffer |
| `open_scratch(title, side, width, lines, bindings)` | opens the plugin's scratch buffer of that title in a fixed-width window at the `:left` or `:right` edge of the tab page, with its own keymap built from `bindings`; `number` is the window number; `E36` when it does not fit; a title already shown is refreshed and focused instead |
| `set_scratch_lines(title, lines)` | replaces the lines of that scratch buffer, leaving it unmodified |
| `close_scratch(title)` | closes the window showing it |
| `focus_window(number)` | makes that window current |
| `open_file(number, path)` | shows the file in that window as `:e` would there, with the opened message |
| `message(text, error)` | shows text in the message row |
| `set_status(text)` | sets the plugin's segment on the current window's status line; `""` removes it |
| `place_sign(number, row, icon)` | places the named icon as a sign on the row; the last sign on a row wins |
| `clear_signs(number)` | removes the signs this plugin placed in the buffer |
| `run_ex(text)` | runs an ex command line and returns its outcome |
| `list_dir(path)` | the sorted entries of a directory in `lines` |
| `stat(path)` | a `FileInfo`: `ok`, `size`, `mtime`, `directory` (following a link), `symlink` |
| `icon(name)` | the glyph of the configured icon set, see `Carat::Domain::Icons::NAMES`; `""` for an unknown name |
| `option(name)` | the plugin's option value as text |
| `working_directory` | the editor's working directory as an absolute path |
| `editing_window` | `number` is the window to open a file in: the previously used window when it shows a file, otherwise the first that does, 0 when none does |
| `scratch_window(title)` | `number` is the window of the current tab page showing the plugin's scratch buffer of that title, 0 when none does |
| `make_file(root, path)`, `make_dir(root, path)` | creates an empty file or a directory at a path strictly inside root |
| `rename_path(root, path, name)` | renames the entry at path, inside root, to name in the same directory; open buffers of it follow |
| `delete_path(root, path)` | deletes a file or an empty directory inside root; an open buffer of the file stays and becomes modified |
| `prompt(id, text, initial)` | opens a prompt in the command-line row; the answer arrives later through `on_input` |

The four file requests are validated by the host before anything changes on disk, and refused with a message in the response: a path that is not strictly inside root after resolving `.` and `..` ("Outside the tree root: path"), an empty name, `.`, or `..` ("Empty name"), a rename to a name containing `/` ("Name contains a path separator: name"), a path that already exists ("Already exists: path"), a missing parent ("No such directory: dir") or source ("No such file or directory: path"), and a directory with entries ("Directory not empty: path"); there is no recursive delete. Paths in messages are relative to the working directory when they lie below it. The root check is lexical, so a symbolic link inside the root counts as inside it, as the tree shows it.

A prompt puts the editor in command-line mode with the prompt's text in place of `:` followed by `initial`; the command-line keys edit it, Enter delivers the text, and Escape or a backspace on an empty line delivers a cancel. Only one prompt is open at a time; a second request while one is open is refused. A plugin keeps what the answer is about in an instance variable until `on_input` arrives.

`Carat::PluginApi::Paths` holds the pure path functions a plugin needs: `normalize`, `join`, `dirname`, `basename`, `absolute(cwd, path)`, `relative(cwd, path)`, and `inside?(root, path)`.

A scratch buffer has no path, shows its title on the status line, has no line numbers, is never written (`:w` reports `E382`), is skipped by `:wa`, never counts as unsaved work, and leaves the buffer list when its window closes; `:q` in its window closes it like any window, and `:q` in the last file window beside it ends the editor, or closes that tab page when there are others. Opening a scratch buffer shown only in another tab page shows the same buffer in the current one. `open_file` over a modified buffer keeps that buffer hidden in the list, opening the file the window already shows leaves it as it is, and a side window that `open_file` gives a file loses its fixed width. Its keymap is consulted before the mode's keymap in every mode and falls through for keys it does not bind, so the cursor motions keep working in it.

## Events

After every key the host compares the editor state with the state after the previous key and delivers, to every subscribed plugin in registration order: `buffer_open` for each buffer that entered the list, `buffer_change` when the current buffer's text changed, `cursor_move` when the cursor or the current buffer changed, `mode_change` with the mode name in `detail`, `window_focus` when the current window or tab page changed, and `quit` when the editor is ending, followed by `deactivate`. `buffer_save` is delivered when a buffer is written, inside the write, and `resize` when the editor is drawn at a new size, with the rows and columns in `row` and `col`. What a plugin changes while handling an event produces no event. `idle` is not delivered yet.

## Icons

Ask for icons by name, never by code point: `host.icon("folder_closed")`. The `icons` option chooses the set for the whole editor, `nerd`, `unicode`, or `ascii`; see the README for the fonts.
