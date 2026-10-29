# Design

## Context

See proposal.md for motivation. The plugin host of the previous change gives a plugin scratch buffers in fixed-width side windows with their own keymap, `list_dir`, `stat`, `icon`, `option`, `open_file`, `focus_window`, `run_ex`, and events after every key; it has no way to learn the working directory, to tell which window shows its scratch buffer or which window the user edits in, to change the file system, or to ask the user anything. `FilePort` has `read`, `write`, `exist?`, `list`, and `stat`; `MemoryFiles` keeps a flat hash of paths, so its `list` answers every path with a prefix rather than a directory's entry names as `DiskFiles` does. The `open_file` request loads through `OpenFile`, whose `state.load` drops the buffer the window showed when no other window shows it, even a modified one, because its callers (`:e`) check first; the request does not. `open_scratch` drops a scratch buffer shown in another tab page and makes a new one. `Quit` closes the current window whenever another window exists, so `:q` in the last file window leaves a tree alone on screen. `Window#gutter_width` gives a scratch window line numbers.

The Spinel facts recorded by the earlier designs apply: an `Array[untyped]` of `Data` values leaks `untyped` and a `Data` value read from it cannot be dispatched to, so lists of program objects hold `Struct` records read through one method with a return signature; a local holding two types widens a method for the whole program; block-form `Data.define` and `Struct.new` ignore inline RBS; an empty array literal is `Array[Integer]` unless stored through a writer after `super()` or returned through a signature; an empty array literal held in a local and passed to another method is copied, so results are built where they are returned; `Array[Symbol]` names no type Spinel can pin; there is no reflection, no `const_get`, and no computed `send`; a method a subclass overrides cannot carry a return type; a literal `"require"` string can be misread by the require scanner; a method does not both take a block and recurse. The probe of this change confirmed that `File.symlink?`, `File.rename`, `File.delete`, `Dir.mkdir`, `Dir.rmdir`, and `Dir.pwd` compile and raise the `Errno` class on failure.

## Goals / Non-Goals

**Goals:**

- The explorer requires only `carat/plugin_api.rb` and its own files, and everything it does goes through host requests that a process plugin could make as well.
- Every file system change a plugin asks for is validated by the host, so a typed name cannot escape the tree's root, overwrite an entry, or remove a directory's contents.
- The tree is readable in all three icon sets; nothing needs a Nerd Font.
- `make diagnose` stays clean.

**Non-Goals:**

- The finder, git status, file clipboard operations, watching the file system, and per-line highlights (see the proposal).
- Physical containment through `realpath`: the root check is lexical, as the user sees the tree.

## Decisions

### The API grows by requests, a callback, and a path helper (version 1.1)

`PluginApi::Host` gains `working_directory`, `editing_window`, `scratch_window(title)`, `make_file(root, path)`, `make_dir(root, path)`, `rename_path(root, path, name)`, `delete_path(root, path)`, and `prompt(id, text, initial)`; `Plugin` gains `on_input(input)` with `Input < Data.define(:id, :text, :cancelled)`; `FileInfo` gains `symlink`. `MINOR` becomes 1 and `VERSION` "1.1"; a 1.0 manifest is still accepted, so the bump is the record of what a plugin may rely on. Window numbers stay positions, so `scratch_window` and `editing_window` answer a `Response` whose `number` is the window, read in the same call as the docs already ask. The alternative of one generic `fs(op, args)` request was rejected for the same reason the host has one method per request: a typed method per operation is what a JSON-RPC gateway maps onto.

`PluginApi::Paths` holds the pure path functions both sides need, `normalize` (resolves "." and ".." and repeated slashes lexically), `join`, `dirname`, `basename`, `absolute(cwd, path)`, `relative(cwd, path)`, and `inside?(root, path)` (strictly below). It lives in the API file because a plugin may require nothing else and the host already requires it; putting it in the domain would force the explorer to copy it. `MemoryFiles` uses it too, which the lint rule allows since the API file has no layer.

### The file requests are validated in the host, then done through the port

`FilePort` gains `mkdir(path)`, `rename(from, to)`, `delete(path)` (a file or an empty directory; the driver calls `Dir.rmdir` for a real directory and `File.delete` otherwise, so a non-empty directory raises and a symlink to a directory is unlinked, never followed), and `cwd`; `stat` adds `"symlink"`. `DiskFiles#stat` reads a broken link as a zero-sized link instead of raising. `MemoryFiles` gains a directory set: `put` and `write` register every ancestor, `mkdir` adds one, `list` answers the sorted entry names of a directory and raises for a missing one, `rename` moves a file or a directory with everything under it, `delete` refuses a non-empty directory, `link(path)` marks a test path as a symlink, and relative paths resolve against `cwd` (default "/project", settable with `move_to`), so the editor's relative paths and the explorer's absolute ones name the same entries. Every existing test that puts and reads relative paths keeps working; the one assertion on the old prefix listing changes to entry names.

`PluginHost` resolves the root and the path with `Paths.absolute` against the port's `cwd`, then checks, in order: inside the root, the last name, existence of the source or absence of the target, the parent directory, and for a delete the directory being empty; the first failure is the response's message, with paths shown relative to the working directory when inside it. Only then does it call the port, under a rescue that turns a raise into a failed response. After a rename it walks the buffer list and rewrites the path of every file buffer equal to the old path or under it, keeping a relative path relative; after a delete it marks the matching buffer modified, as Neovim's tree plugins leave the buffer of a removed file. The alternative of letting the plugin validate was rejected: the host is the boundary a process plugin will cross too, so the rule must live there. Containment is lexical; `realpath` would make a symlinked directory that the tree shows expanded refuse creation inside it, which is not what the user sees.

### The prompt reuses command-line mode

`EditorState` gains `prompt`, `prompt_owner`, and `prompt_id` (all `""` when no prompt is open). `PluginHost#prompt` refuses while one is open, otherwise sets them, puts the initial text in `cmdline`, and enters command-line mode. `EditCommandLine` now receives the host: `execute` with a prompt open clears it, returns to normal mode, and calls `PluginHost#answer(state, text, false)` instead of `ExecuteEx`; `cancel` (Escape, and backspace on an empty line) answers with `cancelled` true; `start` clears any prompt. `answer` delivers `Input` to the owning plugin's `on_input` under the usual rescue. `FramePresenter` writes the prompt text in place of ":" and places the cursor after both. Reusing command-line mode keeps one editing path and one set of keys (`<CR>`, `<Esc>`, `<BS>` from `config/default.json`) instead of a second input mode; a floating input window waits for floating windows.

### Window rules the explorer relies on

- `editing_window`: the tab page's `previous` leaf when it still exists and shows a file buffer, else the first leaf in layout order showing one, else 0. The previously used window is what Neovim's tree plugins open into.
- `scratch_window(title)`: the window of the current tab page showing that plugin's scratch buffer, or 0.
- `open_scratch` with the buffer shown only in another tab page now builds the new side window over the same buffer instead of dropping it, so one tree buffer is shared and `set_scratch_lines` reaches every tab page.
- `open_file` remembers the window's old buffer and, when it was a modified file buffer that the load dropped, adds it back to the list hidden; when the window showed a scratch buffer it clears `fixed_width`, since the side window became a file window.
- `Quit#call` and `Quit#leave` first ask whether the current window shows a file while every other leaf of its tab page shows a scratch buffer. Then, with other tab pages, they close the side windows and the current one through `CloseWindow#remove`, which removes the tab page with its last window; with one tab page they apply the last-window rule. `:close` and `<C-w>c` are unchanged, as in Neovim.
- `Window#gutter_width` returns only the sign column for a scratch buffer.

### The explorer: a tree model, a node record, an icon chooser, and the plugin

`Explorer::Node < Struct.new(:path, :name, :depth, :directory, :symlink)` is one visible line; `Explorer::Tree` holds the root, the expanded directories (`Hash[String, String]` used as a set), `show_hidden`, the ignore list, the marked path, and the visible nodes (`Array[untyped]` read through `node(i) -> Node`). `Tree#build(host)` walks from the root with `while` loops and an explicit recursion that takes no block, listing each expanded directory with `list_dir`, dropping hidden and ignored names, stating each entry, and sorting directories then files with a case-insensitive comparison (ties by the exact name). `Tree#lines(host)` renders the marker column, two spaces per level, the icon, a space, and the name; `FileIcons.name_for(name, directory, expanded, symlink)` picks the icon name from the rules of the spec. `reveal(path)` expands every directory between the root and a path inside it. The model takes the `Host` it reads through, so the unit tests drive it with a fake host over an in-memory directory table.

`Explorer::Plugin` keeps the tree and the pending prompt target. Its manifest spells every action name as a literal (a constant key widens the hash), binds `<leader>e` in normal mode, declares `:Explorer` and `:ExplorerFind`, subscribes to `buffer_open`, `window_focus`, and `cursor_move`, and declares the four options. The tree's keymap is the hash given to `open_scratch`. Follow is one comparison of the event's path with the last followed path, so a `cursor_move` per key costs nothing when the file did not change; when it changed and the tree is shown, the tree reveals it and replaces its lines. Opening a file uses `editing_window` and opens the path relative to the working directory; with no editing window it opens the file in the tree's window (which loses its fixed width) and opens the tree again at the edge, which gives the layout a tree plus a file window. `s` and `v` focus the editing window and run `split` or `vsplit` with the path; `t` runs `tabnew`. `a`, `r`, and `d` remember the target path and prompt; `on_input` finishes them. The tree's cursor is moved only while the tree is current (on open, `:ExplorerFind`, and after its own actions), because the API moves only the current window's cursor.

### The hello plugin stays as a fixture

The `hello` plugin leaves `config/plugins.json` and `config/default.json`, so the binary no longer contains it and its `<leader>hh` and `:Hello` disappear for users, while `test/editor_plugins.rb` registers it directly with the harness, which already takes a plugin list. It keeps its role as the smallest complete example in `docs/plugins.md` and as the fixture of the registry, routing, option, and icon scenarios. Removing it would mean rewriting those tests around a new fixture with the same shape; keeping it in the binary would ship a feature with no use.

### Tests

`test/plugins_explorer.rb` drives the tree model and the icon chooser over a fake host: ordering, indentation, expand and collapse, reveal, hidden and ignore filtering, symlinks, and every icon set. `test/use_cases_plugin_files.rb` drives the new host requests over `MemoryFiles` with every refusal, buffer following, the prompt, and the window numbers. `test/editor_explorer.rb` runs the registry's explorer over the harness for every key and both ex commands, including splits, a tab page, create, rename, delete with confirmation, the cancel path, `<C-w>=`, and quitting with the tree open, plus the tree window rendered in each icon set. `test/adapters_frame_presenter.rb` gains the prompt row and the scratch window without numbers; `test/domain_icons.rb` the new name; `test/editor_plugins.rb` registers `hello` directly; `test/smoke_editor.rb` opens the tree with `<leader>e` in the pseudo-terminal and quits.

## Risks / Trade-offs

- [`cursor_move` is delivered to the explorer on every key] → the handler compares one string and returns; listing happens only when the current file changed and the tree is shown.
- [A deep expanded tree is listed again on every refresh] → listing is per expanded directory only, and the tree redraws only on its own actions and on follow; caching listings can come with file watching.
- [The tree's cursor row drifts when follow expands directories above it while another window is current] → recorded in the proposal; the API moves only the current window's cursor, and moving focus back and forth would change `<C-w>p`.
- [Lexical containment lets a symlinked directory inside the root lead outside it] → the tree shows such a directory as inside, and Neovim's tree plugins behave the same; the host still refuses every typed `..` that leaves the root.
- [Changing `MemoryFiles#list` semantics] → only one existing assertion used it, and the new semantics match the disk.
- [`make snapshots` rewrites every `.expected`] → the diff is reviewed; only the changed and new test programs move.
