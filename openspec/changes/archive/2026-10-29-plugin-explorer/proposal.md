# Proposal

## Why

The editor can open files only by typing their paths, and the plugin host exists so that features like a file tree are built on it rather than inside the editor. Roadmap item 12 of `docs/architecture.md`, `plugin-explorer-and-finder`, is the first real use of the plugin API; this change delivers its explorer half, a file tree with icons that works with or without a Nerd Font, and adds what the host is missing for it: creating, renaming, and deleting files, and asking the user for a name or a confirmation on the command line.

## What Changes

This change delivers the explorer half of roadmap item 12. The architecture document splits the item into two changes, `plugin-explorer` (this one) and `plugin-finder` (the fuzzy finder, later), as item 7 was split.

- Add the built-in compiled plugin `explorer` under `carat/plugins/explorer/`, listed in `config/plugins.json` and enabled in `config/default.json` with the options `width` (30), `side` (`left` or `right`), `show_hidden` (false), and `ignore` (`.git`, `build`, `tmp`).
- The tree is a scratch buffer in a fixed-width side window rooted at the editor's working directory: the root's name on the first line, then the entries indented two spaces per level, directories first and then files, each group sorted by name ignoring case, every line with an icon by name from the host's icon table (folder closed or open, a file type chosen by extension or name, symlink). The `icons` option switches the set, so `unicode` and `ascii` give a readable tree with no Nerd Font. The file of the current editing window is marked and its directories are expanded when the tree opens and whenever another file becomes current (follow).
- Actions with default bindings in the plugin manifest: `plugin.explorer.toggle` on `<leader>e` (open, focus, or close), `plugin.explorer.focus`, and in the tree's own keymap `<CR>` and `l` (open a file in the previous editing window or expand a directory), `h` (collapse or go to the parent), `o` (toggle a directory), `s`, `v`, `t` (open in a split, a vertical split, a tab page), `a` (create a file, or a directory with a trailing `/`), `r` (rename), `d` (delete after a yes or no confirmation), `R` (refresh), `H` (hidden files), `-` (root up one directory), `C` (root to the directory under the cursor), `q` (close), `?` (key help in the message row). Other keys, such as `j k gg G`, fall through to the normal keymap. Ex commands `:Explorer` (toggle) and `:ExplorerFind` (reveal the current file).
- Extend `FilePort`, `DiskFiles`, and `MemoryFiles` with `mkdir`, `rename`, `delete` (a file or an empty directory, never recursive), `cwd`, and a `symlink` flag in `stat`; `MemoryFiles` gains real directories, so `list` answers entry names as the disk does.
- Extend the plugin API to version 1.1 with the requests `working_directory`, `editing_window`, `scratch_window`, `make_file`, `make_dir`, `rename_path`, `delete_path`, and `prompt`, the `Input` value delivered to the new `on_input` callback, and `symlink` on `FileInfo`. The host validates every file request against the root the plugin names and refuses, with a message and no change on disk, a path outside it, an empty name, a name with a path separator for a rename, an existing target, a missing parent, and a non-empty directory. A renamed file's open buffer follows the new path; a deleted file's open buffer stays and becomes modified. The prompt shows its text in the command-line row, is edited with the command-line keys, and delivers the text on Enter or a cancel on Escape.
- Change the host so that opening a file from a plugin over a modified buffer keeps that buffer hidden in the list instead of dropping it, a scratch buffer already shown in another tab page is shown again rather than replaced, and a side window that a plugin turns into a file window loses its fixed width.
- Change `:q`, `:wq`, `:x`, and `<C-w>q` on the last window that shows a file, when the only other windows of the tab page are plugin side windows, to act as on the last window: end the editor (or close the tab page when there are others), as Neovim's tree plugins arrange, instead of leaving the tree alone on screen.
- Change plugin side windows to show no line numbers, as Neovim's tree plugins set `nonumber`; the sign column stays.
- Add the icon name `current`, the marker of the current file.
- Keep the `hello` plugin as a test fixture and an example only: it leaves `config/plugins.json` and `config/default.json`, so the binary no longer contains it and `<leader>hh` and `:Hello` are gone for users; the tests register it directly.
- Document the explorer in `docs/actions.md`, `docs/compatibility.md`, `docs/plugins.md`, the README (a "File tree" section), `docs/architecture.md`, and `CLAUDE.md`.

Out of scope: the fuzzy finder (the other half of item 12), git status in the tree (item 14), copy, cut, and paste of files, bookmarks, recursive delete, trash, creating intermediate directories, live updates when files change outside the editor, mouse support, moving the tree's cursor to a followed file while the tree is not the current window, and highlighting the marked line, which needs plugin highlight groups from the syntax highlighting change.

Assumptions recorded here rather than asked:

- The tree's paths are absolute; a file is opened by its path relative to the working directory when it is inside it, so the status line shows `lib/a.rb`, not a full path.
- The marker of the current file is the `current` icon in a one-cell column at the start of every line; the root line is the open folder icon and the root's name.
- `<CR>` and `l` on an expanded directory leave it expanded; `o` on a file opens it as `<CR>` does; `s`, `v`, and `t` on a directory do nothing; `h` on the root line does nothing; `C` on a file makes its directory the root.
- When no window of the tab page shows a file, opening a file from the tree shows it in the tree's window and opens the tree again at the edge, so the file takes the rest of the width.
- A new name may contain `/` to create inside an existing subdirectory, but missing directories are not created; a name that ends in `/` creates a directory.
- The delete confirmation accepts `y` or `yes` in any case; anything else, or Escape, cancels with "Delete cancelled".
- Following is driven by `buffer_open`, `window_focus`, and `cursor_move` events: the last one covers `:e` of a buffer already listed, and it costs one string comparison per key when the file did not change.
- The host's root check is lexical, after resolving `.` and `..`; a symlinked directory inside the root is treated as inside it, as the tree shows it.
- The `?` help is one line in the message row and is cut at the screen width.

## Capabilities

### New Capabilities

- `file-explorer`: the file tree plugin: its window, its lines and icons, follow, its keys and actions, its ex commands, its options, and its file operations from the user's side.

### Modified Capabilities

- `plugin-host`: the new requests (working directory, editing and scratch window numbers, create, rename, and delete with their refusals, the prompt), the `on_input` delivery, API version 1.1, the open file request keeping a modified buffer hidden, and the registry and option scenarios that named the `hello` plugin.
- `plugin-windows`: no line numbers in a side window, a scratch buffer shown again in another tab page, and a side window turned into a file window losing its fixed width.
- `windows`: `<C-w>q` on the last file window beside plugin side windows ends the editor or closes the tab page.
- `command-line-mode`: `:q`, `:wq`, and `:x` follow the same rule.
- `screen-rendering`: the message row shows a plugin's prompt in command-line mode.
- `icons`: the `current` icon name.

## Impact

- New: `carat/plugins/explorer/plugin.rb`, `tree.rb`, `node.rb`, `file_icons.rb`; `test/plugins_explorer.rb`, `test/editor_explorer.rb`, `test/use_cases_plugin_files.rb`.
- Changed: `carat/plugin_api.rb` (requests, `Input`, `Paths`, `FileInfo#symlink`, version 1.1); `carat/ports/file_port.rb`, `carat/drivers/disk_files.rb`, `carat/doubles/memory_files.rb`; `carat/use_cases/plugins/plugin_host.rb`, `plugin_link.rb`; `carat/use_cases/edit_command_line.rb`, `files/quit.rb`; `carat/domain/editor_state.rb` (prompt fields), `window.rb` (no numbers for a scratch buffer), `icons.rb`; `carat/adapters/frame_presenter.rb`, `editor_assembly.rb`; `config/plugins.json`, `config/default.json`, the generated `carat/domain/default_config.rb` and `carat/plugins/registry.rb`; `test/smoke_editor.rb`, `test/editor_plugins.rb`, `test/use_cases_plugins.rb`, `test/domain_icons.rb`, `test/adapters_frame_presenter.rb`, and other snapshots touched by the gutter of side windows.
- Docs: `docs/actions.md`, `docs/compatibility.md`, `docs/plugins.md`, `docs/architecture.md`, `README.md`, `CLAUDE.md`. No new dependencies; the ports gain methods but no new port.
