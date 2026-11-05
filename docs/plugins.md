# Writing a compiled plugin

Everything beyond core modal editing is a plugin on one API, `carat/plugin_api.rb`, and that file is the only one a plugin may require. A compiled plugin is a Ruby class compiled into the binary with the editor; it runs on the editor thread, obeys the Spinel rules of `docs/architecture.md` section 2.1, and talks to the editor only through values. This document is the practical guide; the `plugin-host`, `plugin-windows`, `icons`, `file-explorer`, `syntax-highlighting`, and `ruby-syntax` specs under `openspec/specs/` are the contract. `carat/plugins/explorer/` is a complete plugin that ships with the editor, and `carat/plugins/ruby/` a complete tokenizer; `carat/plugins/hello/plugin.rb` is the smallest complete example, a test fixture that is not in `config/plugins.caratrc`, so the editor does not contain it and the tests register it directly.

## The files

A plugin named `thing` lives in `carat/plugins/<name>/`, here `thing`. Its files require `carat/plugin_api.rb` (as `require_relative "../../plugin_api"`) and files in their own directory, nothing else; the `lint` test fails on any other `require_relative`. The class is `Carat::Plugins::Thing::Plugin < Carat::PluginApi::Plugin`, with inline RBS signatures on every method and instance variable like the rest of `carat/`.

The plugin is listed in `config/plugins.caratrc`, in the order the plugins are registered, one line of the configuration format each, `plugin.<name> <path under carat/plugins/> <class>`:

```
plugin.thing thing/plugin Carat::Plugins::Thing::Plugin
```

`make gen-config` then regenerates `carat/plugins/registry.rb`, one `require_relative` and one constructor call per entry; the `config_sync` test fails while the generated file is stale. `config/default.caratrc` gets a line `plugin.thing.enabled true` and a `plugin.thing.<option> <value>` line for each option value the shipped configuration wants; a plugin no line names is enabled with its manifest defaults. A user sets the same lines in `~/.config/carat/caratrc` or a project's `.caratrc`, and a line naming an option the plugin does not declare, or a value of the wrong kind, is reported by file and line and keeps the earlier value.

## The manifest

`manifest` returns a `Carat::PluginApi::Manifest` value, built with keyword arguments like every value of the API (`Carat::PluginApi::Manifest.new(name: "thing", version: "0.1.0", ...)`, `Carat::PluginApi::Edit.new(from_row: 0, from_col: 0, to_row: 0, to_col: 1, text: "x")`), as the plugins of this repository and the `lint` test require; `Data` also accepts positional arguments, in the order below, but they say nothing about which value is which:

- `name`: lowercase letters, digits, and underscores, starting with a letter; the same as the directory and the configuration key.
- `version`: the plugin's own, free-form.
- `api_version`: the API this plugin was written against, `"2.1"` today (`Carat::PluginApi::VERSION`). The host refuses a different major version and a newer minor than its own, and accepts the same major with its minor or an older one. Version 1.1 added `working_directory`, `editing_window`, `scratch_window`, `make_file`, `make_dir`, `rename_path`, `delete_path`, `prompt`, `on_input`, `FileInfo#symlink`, and `PluginApi::Paths`. Version 1.2 addresses buffers and windows by id, spells events, option types, and sides as strings, adds `buffer_close`, `buffer_rename`, the changed rows of `buffer_change` (`Event#removed` and `Event#inserted`), `open_in_split`, `open_in_tab`, `WindowResponse`, `TextResponse`, and `BufferView#message`, and renames `BufferView#number` to `buffer`; it is not purely additive, and the plugins in this repository moved with it. Version 1.3 adds the `filetypes` member of the manifest, `Plugin#tokenize`, and `syntax_group`; a plugin built against 1.2 passes `filetypes: []`, or `[]` last when it builds the manifest positionally. Version 2.0 makes `bindings` and `options` lists of configuration lines and takes the scratch keymap of `open_scratch` as keymap lines too, so a plugin writes its defaults in the format a user writes; a 1.x manifest is refused, and a plugin moves by turning each hash into lines, as the plugins of this repository did. Version 2.1 lets `syntax_group` resolve the file-icon groups and tokens carry them, and gives a plugin's new scratch buffer the syntax named after the plugin when the manifest declares that filetype. Events and option types given as symbols are still read.
- `actions`: a hash from action name to a one-line description. Every action is `plugin.<name>.<action>`, with the plugin's own name, and goes into `docs/actions.md`.
- `commands`: a hash from ex command name to its abbreviation, or `""` for none. A name starts with an uppercase letter, as Vim's user commands do, and the abbreviation is a proper prefix of it. The command runs when typed as its abbreviation, its full name, or any spelling between them, with the same matcher as the editor's own commands (`Hel`, `Hell`, and `Hello` for `"Hello" => "Hel"`); the editor's commands are tried first, then the plugins' in registration order.
- `bindings`: default key bindings as configuration lines, `["keymap.normal <leader>tt plugin.thing.toggle"]`, or `[]`. The action is one of the plugin's own actions or a key sequence to replay; `<leader>` is the configured leader, and a plugin cannot set the leader itself. The host adds them to the keymap before the configuration's keymap lines, so a user binding of the same keys replaces them and `none` removes them.
- `events`: the names of the events the plugin wants delivered, among `Carat::PluginApi::EVENTS`.
- `options` and `option_types`: the defaults as configuration lines, one per option, `["plugin.thing.width 30", "plugin.thing.ignore .git build"]`, and a hash from each option name to its type, `"bool"` (`true` or `false`), `"integer"` (one to nine digits), `"string"` (one word, quoted when it has spaces), or `"list"` (any number of words). The configuration's `plugin.thing.<option>` lines are applied after the defaults, the last winning. Values reach the plugin as text: `"true"` or `"false"`, the digits, the word, or a list's words joined by newlines.
- `filetypes`: the filetypes the plugin tokenizes, `["ruby"]`, each lowercase letters, digits, and underscores starting with a letter, or `[]` for none. When two enabled plugins declare one filetype, the one registered first tokenizes it; see Tokenizers below.

A manifest that breaks a rule registers the plugin disabled with the rule as the reason, recorded in the host's errors; `Carat::Domain::ManifestCheck.check` holds the rules of one manifest, members of the wrong type included ("actions is not an object of action names"), and the host adds the rules between plugins: a name already registered ("a plugin named thing is already registered") and an ex command name or abbreviation an earlier enabled plugin declares ("command Thing is already declared by plugin other") are refused. A manifest method that raises registers the plugin disabled under `plugin<N>`, its position in the list, and the editor starts. A default binding of keys another plugin's defaults already bind is not added, and the conflict is recorded ("plugin thing: binding normal.<leader>tt is already bound by plugin other"); the first plugin keeps the keys.

## The base class

Override what the plugin needs:

- `activate(host)`: called once when the plugin is enabled, with the plugin's own `Carat::PluginApi::Host`; it may already run ex commands with `run_ex`. Keep it in an instance variable typed `Carat::PluginApi::Host?` and assign `nil` in `initialize`, since Spinel needs every instance variable assigned there.
- `deactivate`: called when the editor quits.
- `on_event(event)`: a `Carat::PluginApi::Event` with `name`, `buffer`, `window`, `path`, `row`, `col`, and `detail`.
- `on_action(name, context)`: one of the plugin's actions with a `Carat::PluginApi::Context`: the `count` and `register` typed before the key, the current `buffer` and `window` ids, the `path`, and the cursor `row` and `col`.
- `on_command(command)`: a `Carat::PluginApi::Command` with the declared `name`, `bang`, and `args`.
- `on_input(input)`: a `Carat::PluginApi::Input` with the `id` the plugin gave a prompt, the `text` typed, and `cancelled`, when a prompt the plugin opened ends.
- `tokenize(filetype, text, state, tokens)`: one line of a buffer in a filetype the manifest declares; see Tokenizers below.

A plugin that raises anything in any of these, also a `NotImplementedError` from a method nobody implemented and a stack overflow, and also while its manifest is read, is disabled with "Plugin thing disabled: ..." in the message row; the editor goes on, and the plugin's later requests are refused with "Plugin thing is disabled". Disabling also removes what the plugin left: the windows of its scratch buffers close (the last window of the editor shows a new empty buffer instead), its scratch buffers leave the list, its signs and status segment go, its open prompt is cancelled without an `on_input`, and its default key bindings are removed, while a binding the configuration made for the same keys stays. Keep the work inside a call small: the editor draws after the key returns.

## Ids

Buffers and windows are addressed by id: the number the editor gives a buffer when it first enters the buffer list and a window when it is created, never given to another one, also after it is gone. `0` means the current one. A plugin may keep an id across keys; a request with an id no listed buffer or no window has fails ("No buffer 9", "No window 9"). A window id addresses a window in any tab page, and focusing it or opening a file in it makes its tab page current. Positions stay only where the user sees them, as `:wa` reports `E141` with the list position.

## Requests

Every method of the host takes plain values and returns a value; nothing calls back into the plugin. Most return a `Response` with `ok`, `message`, `number` (a count), and `lines`; the window requests return a `WindowResponse` with `ok`, `message`, and the `window` id; `icon`, `option`, and `working_directory` return a `TextResponse` with `ok`, `message`, and `text`. Every string a plugin receives is a copy, and every string it gives is copied before the editor keeps it, so changing one in place changes nothing on the other side.

| Request | Returns |
| --- | --- |
| `read_buffer(buffer)` | a `BufferView`: `ok`, `message` (why it failed), the `buffer` id, `path`, copies of the `lines`, the cursor `row` and `col` when the buffer is the current one, `modified` |
| `edit_buffer(buffer, edits)` | applies a list of `Edit` values (`from_row`, `from_col`, `to_row`, `to_col`, `text`; exclusive end, ascending, not overlapping) as one transaction, which the user undoes and redoes in one step (inside an action bound to a key it joins that key's undo state); every item is checked first, and one bad item ("edit 3: not an edit") refuses them all and changes nothing |
| `move_cursor(row, col)` | moves the cursor of the current window, clamped into the buffer |
| `open_scratch(title, side, width, lines, bindings)` | opens the plugin's scratch buffer of that title in a fixed-width window at the `"left"` or `"right"` edge of the tab page, with its own keymap built from `bindings`, keymap lines as in the manifest (`["keymap.normal <CR> plugin.thing.open"]`); a `WindowResponse` with the window's id; `E36` when it does not fit; a title already shown is refreshed and focused instead |
| `set_scratch_lines(title, lines)` | replaces the lines of that scratch buffer, leaving it unmodified |
| `close_scratch(title)` | closes the window showing it |
| `focus_window(window)` | makes that window current, and its tab page |
| `open_file(window, path)` | shows the file in that window as `:e` would there, then makes the window current, with the opened message; a failed open leaves the focus where it was |
| `open_in_split(window, path, vertical)` | splits that window and shows the file in the new window, which becomes current; the path is taken as it is, so a space or a `|` in it is part of the name; `E36` when there is no room |
| `open_in_tab(path)` | opens a tab page after the current one showing the file, taken as it is |
| `message(text, error)` | shows text in the message row |
| `set_status(text)` | sets the plugin's segment on the current window's status line; `""` removes it |
| `place_sign(buffer, row, icon)` | places the named icon as the plugin's sign on the row, replacing its own sign there and never another plugin's; when two plugins mark one row, the one registered first shows; a sign moves with its line and goes away with it |
| `clear_signs(buffer)` | removes the signs this plugin placed in the buffer; `number` is how many |
| `run_ex(text)` | runs an ex command line and returns its outcome; refused with `E169: Command too recursive` when plugin calls are already nested 4 deep |
| `list_dir(path)` | the sorted entries of a directory in `lines` |
| `stat(path)` | a `FileInfo`: `ok`, `size`, `mtime`, `directory` (following a link), `symlink` |
| `icon(name)` | the glyph of the configured icon set, see `Carat::Domain::Icons::NAMES`; failed with "No icon named x" for an unknown name |
| `option(name)` | the plugin's option value as text; failed with "No option named x" for an unknown name |
| `working_directory` | the editor's working directory as an absolute path |
| `editing_window` | the window to open a file in: the previously used window when it shows a file, otherwise the first that does, 0 when none does |
| `scratch_window(title)` | the window of the current tab page showing the plugin's scratch buffer of that title, 0 when none does |
| `make_file(root, path)`, `make_dir(root, path)` | creates an empty file or a directory at a path strictly inside root |
| `rename_path(root, path, name)` | renames the entry at path, inside root, to name in the same directory; open buffers of it follow |
| `delete_path(root, path)` | deletes a file or an empty directory inside root; an open buffer of the file stays and becomes modified |
| `prompt(id, text, initial)` | opens a prompt in the command-line row; the answer arrives later through `on_input` |
| `syntax_group(name)` | a `Response` whose `number` is the id of the syntax highlight group (`"Comment"`, `"String"`, ... `"Error"`) or the file-icon group (`"DevIconDefault"`, `"DevIconRb"`, ... `"DevIconLock"`, 2.1) with that name; failed with "No highlight group named x" for any other name, the editor's own UI groups included |

The four file requests are validated by the host before anything changes on disk, and refused with a message in the response: a path that is not strictly inside root after resolving `.` and `..` ("Outside the tree root: path"), an empty name, `.`, or `..` ("Empty name"), a rename to a name containing `/` ("Name contains a path separator: name"), a path that already exists ("Already exists: path"), a missing parent ("No such directory: dir") or source ("No such file or directory: path"), and a directory with entries ("Directory not empty: path"); there is no recursive delete. Paths in messages are relative to the working directory when they lie below it. The root check is lexical, so a symbolic link inside the root counts as inside it, as the tree shows it.

A prompt puts the editor in command-line mode with the prompt's text in place of `:` followed by `initial`; the command-line keys edit it, Enter delivers the text, and Escape or a backspace on an empty line delivers a cancel. Only one prompt is open at a time; a second request while one is open is refused. A plugin keeps what the answer is about in an instance variable until `on_input` arrives.

`Carat::PluginApi::Paths` holds the pure path functions a plugin needs: `normalize`, `join`, `dirname`, `basename`, `absolute(cwd, path)`, `relative(cwd, path)`, and `inside?(root, path)`.

A scratch buffer has no path, shows its title on the status line, has no line numbers, is never written (`:w` reports `E382`), is skipped by `:wa`, never counts as unsaved work, and leaves the buffer list when its window closes; `:q` in its window closes it like any window, and `:q` in the last file window beside it ends the editor, or closes that tab page when there are others. Opening a scratch buffer shown only in another tab page shows the same buffer in the current one. `open_file` over a modified buffer keeps that buffer hidden in the list, opening the file the window already shows leaves it as it is, and a side window that `open_file` gives a file loses its fixed width. Its keymap is consulted before the mode's keymap in every mode and falls through for keys it does not bind, so the cursor motions keep working in it.

## Events

An `Event` carries its `name` (a string), the `buffer` and `window` ids, the `path`, the cursor `row` and `col`, a `detail`, and for `buffer_change` the rows `removed` and `inserted`. Events are delivered to every subscribed plugin in registration order, after the key that caused them:

- First the buffer events, in the order they happened: `buffer_open` when a buffer entered the list, `buffer_change` once per closed transaction of any buffer (one command, one insert session when insert mode is left or an arrow key splits it, one plugin edit request, one undo or redo), with the first changed row in `row` and the rows removed there and inserted in their place, `buffer_save` when a buffer was written, `buffer_rename` when a listed buffer's path changed (the old path in `detail`), and `buffer_close` when a buffer left the list.
- Then, from comparing the editor with the state after the previous key: `cursor_move` when the cursor or the current buffer changed, `mode_change` with the mode name in `detail`, `window_focus` when the current window or tab page changed, and `quit` when the editor is ending, followed by `deactivate`.
- `resize` when the editor is drawn at a new size, with the rows and columns in `row` and `col`. `idle` is not delivered yet.

What happens while a plugin call runs is queued and delivered after the outermost call returns, so one plugin's changes reach the others; an event a plugin's own request caused (its edit, its write, the buffer it opened, closed, or renamed) is not delivered back to it. Delivering can cause more events, which go out in the next round; after 8 rounds the rest are dropped with "Plugin events dropped after 8 rounds" in the message row, which only a pair of plugins answering each other's events without end reaches.

## Tokenizers

A plugin colors the text of a language by tokenizing it, line by line. It declares the filetypes in its manifest, resolves the names of the highlight groups it uses once, in `activate`, with `syntax_group`, and implements `tokenize(filetype, text, state, tokens)`:

- `text` is one line of the buffer, a copy in a string the host reuses: it is valid during the call only, so keep a `dup` if you need it later.
- `state` is the state at the start of the line: 0 for the first line of the buffer, otherwise what `tokenize` returned for the line above.
- `tokens` is an empty integer array; append three integers per token, its start column, its length, and its group id, in code point columns (a character is one column whatever its bytes or display width). Tokens may leave gaps, which are drawn in the normal group, and should not overlap.
- Return the state at the end of the line, a non-negative integer. The host only compares states and passes them on, so encode what is open at the end of the line (a string, a comment block, a heredoc) however suits the language; `carat/plugins/ruby/line_state.rb` documents the Ruby plugin's packing.

The editor calls `tokenize` only for the rows on the screen and the rows above them, keeps each line's tokens while the line is visible, and after an edit calls it again from the changed row until a line ends in the same state it did before, so the state must be a pure function of the line and the state before it: equal inputs, equal outputs. A token with a negative start, a length below one, or an id that is neither a syntax nor a file-icon group is ignored, and a state that is not a non-negative integer counts as 0. Build the token array's contents without making a string per token (walk the bytes with `getbyte`), since a scroll tokenizes a line per key. A tokenizer that raises is disabled like any plugin and its buffers are drawn plain from that frame on, or by the next plugin that declares the filetype. The filetype of a buffer comes from the editor's table in `carat/domain/filetype.rb` or from `:set filetype=name`; a plugin's scratch buffer has the syntax named after the plugin when the manifest declares that filetype, so a plugin can color its own lines, as the explorer colors its icons.

The highlight groups are Neovim's standard names: `Comment`, `Constant`, `String`, `Character`, `Number`, `Boolean`, `Float`, `Identifier`, `Function`, `Statement`, `Conditional`, `Repeat`, `Label`, `Operator`, `Keyword`, `Exception`, `PreProc`, `Include`, `Define`, `Macro`, `Type`, `StorageClass`, `Structure`, `Typedef`, `Special`, `SpecialChar`, `Delimiter`, `SpecialComment`, `Todo`, and `Error`; the theme decides their colors.

## Icons

Ask for icons by name, never by code point: `host.icon("folder_closed").text`. The `icons` option chooses the set for the whole editor, `nerd`, `unicode`, or `ascii`; see the README for the fonts.
