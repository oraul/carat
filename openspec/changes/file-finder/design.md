# Design

## Context

The plugin host already gives a plugin floats (`open_float`, `close_float`), file opening in a window, a split, or a tab page, a one-level `list_dir`, and a command-line `prompt` that answers once, on Enter or Escape. The command palette (`OpenPalette`, `FollowPalette`) is a core precedent for a prompt filtered as you type into a float. The finder is a plugin (`docs/architecture.md` section 9: "The finder, the explorer, and git signs are plugins built on it"), so what it lacks is added to the API, not to the core as a second palette.

## Goals / Non-Goals

Goals: the finder as a plugin on API requests any plugin may use; filtering 10,000 paths per key well under 20 ms; nothing allocated per key while it is closed.

Non-goals: a general picker framework in the core, content search, a cached or watched listing.

## Decisions

### The API grows by four requests and a callback (2.5)

- `list_files(root, ignore)`, a `FileRequests` method over a new use case `ListTree` (`carat/use_cases/files/list_tree.rb`): a depth-first walk with `FilePort#list` and `FilePort#stat`, each directory's names sorted as the port answers them. A name in `ignore` is skipped before it is stated. A link (`PathInfo#symlink`) is resolved with `FilePort#real_path` and kept only when it is a regular file strictly inside the root's real path (`PluginApi::Paths.inside?`); a linked directory is never entered, so the walk cannot loop and lists every real file once. An unreadable directory below the root is skipped; an unreadable root fails. At `MAX_FILES` (100,000) the walk stops and the response carries a message. Alternative considered: giving the plugin `list_dir` and `stat` and walking in the plugin; rejected because link resolution needs `real_path`, which is not a request, and one request per directory costs more copies.
- `read_file(path, rows)`: `FilePort#read(path, 262_144)`, which already refuses a directory, a special file, and a longer file without blocking, cut to the first `rows` lines (1 to 1000) by walking newlines, so a large file is not split whole. It takes any path, as `stat` and `list_dir` do: a compiled plugin is trusted code, and the read bound is what protects the editor.
- `live_prompt(id, text, initial, bindings)` and `close_prompt` in `UiRequests`. `Domain::PluginUi` gains `prompt_live`, `prompt_seen` (the text last delivered), and `prompt_keymap` (a `Keymap` built from the bindings with `Keymap.from_lines`, nil for a plain prompt), all reset by `close_prompt`, which also runs when a plugin is disabled. `HandleKey#lookup` consults `prompt_keymap` first while the mode is command-line; `HandleKey#call` and `#timeout` end with `PluginHost#follow_prompt` only when `prompt_live` is set, a boolean read on the closed path. `follow_prompt` compares the command line with `prompt_seen` and, when it changed, delivers `on_prompt_change(Input)` through the router's guarded path and flushes events. `close_prompt` refuses a plugin that does not own the prompt, closes it, clears the command line, and sets normal mode.
- `Plugin#on_prompt_change(input)` is a new no-op base method; `Input` keeps its members, so 2.4 plugins compile unchanged and the version is a minor bump.

### The finder plugin

`carat/plugins/finder/plugin.rb` holds the state of one opening: the root, the listed paths, the match indices, the highlight, the two float ids, and the screen size from the `resize` event (80 by 24 until one arrives). Each refresh closes its floats and opens them again with the new lines, as `FollowPalette` does, so no request to replace a float's lines is needed. The list float is anchored to the editor at row 1, its height the screen rows less 6, its width the screen less 4 columns, half of that when the preview shows (100 columns or more). Rows are the visible window of matches around the highlight, `> ` before the highlighted one and two spaces before the others. The preview reads as many rows as the float is high through `read_file`.

Enter arrives as `on_input` (the prompt is already closed); the split, vertical split, and tab keys are prompt bindings to plugin actions, which call `close_prompt`, close the floats, and open the path. The open goes to `editing_window` as the explorer's does, the path relative to the working directory, never through an ex command line.

### Matching

`carat/plugins/finder/matcher.rb`, `Matcher.score(query, path)`, allocates nothing: bytes compared with `getbyte`, ASCII letters folded. It first tries the query inside the file name (after the last `/`) and otherwise across the whole path; in each it finds the leftmost match and then walks back from its end to the latest start, so the span is tight. Each matched byte scores 16, plus 24 at a segment or word start (after `/`, `_`, `-`, `.`, a space, or a lowercase-to-uppercase step), plus 16 right after the previous matched byte; a file-name match adds 256; the gap inside the span and the path length subtract. The finder packs each match as `score << 20 | (0xFFFFF - index)` into an integer array and sorts it once, so equal scores keep the listing order and no comparison block runs per pair. An empty query shows every file in listing order without scoring.

### Bindings

The manifest binds `keymap.normal <leader>ff plugin.finder.open` and `keymap.normal <C-p> plugin.finder.open`; the core `file.find` and its default line go, since a configuration line for the same keys would win over the plugin's binding. The prompt's own bindings are the plugin's constant keymap lines (`<C-n>`, `<Down>`, `<C-p>`, `<Up>`, `<C-x>`, `<C-s>`, `<C-v>`, `<C-t>`).

## Benchmark

`bench/keys.rb` gains a `finder` plugins kind and the scenario `["finder", "f<BS>", 2_000, 1_000, " ffd", "code", "finder"]` over `FINDER_FILES` (10,000) paths in the memory file system: every key filters all 10,000 against a one- or two-letter query. The closed path is the existing `lh` figure, which `make metrics` compares.

## Risks / Trade-offs

- Reopening the floats per key allocates a scratch buffer per float per key while the finder is open; acceptable for an open picker, and it keeps the API smaller.
- The listing is read once per opening; a 100,000-file tree takes a noticeable moment to open. A cache is out of scope.
- `<C-s>` may be taken by terminal flow control; `<C-x>` is the same action.
