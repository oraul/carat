# Proposal

## Why

Carat has a file tree but no way to jump to a file by a few letters of its name: Space f f answers "Not implemented: file.find". The fuzzy finder is the second half of roadmap item 12, `plugin-explorer-and-finder`, in `docs/architecture.md` section 12 ("`plugin-finder` brings the fuzzy finder"), and the user's next request (docs/queue.md item 1, `file-finder`).

## What Changes

- A new built-in compiled plugin, `finder`, opened by `<leader>ff` (Space f f) and `<C-p>` in normal mode, both default bindings of its manifest. It lists the project's files below the working directory once per opening and puts a `> ` prompt on the command line; every change of the typed text filters the list again, best match first, in a bordered float titled `Files N/M` near the top of the screen, the highlighted row marked `> `, `No match` when nothing matches.
- Fuzzy matching is by path, ignoring ASCII case: every typed byte appears in order; a match inside the file name, at the start of a path segment or word, and in a run scores higher, a shorter path breaks a tie, then the listing order.
- Names in `plugin.finder.ignore` (default `.git build tmp`, the explorer's list) are never listed nor entered; a symbolic link whose target, every link resolved, is outside the project is skipped; a link to a directory is never entered; a link to a file inside the project is listed.
- When the screen is at least 100 columns wide, a second float to the right previews the first rows of the highlighted file, titled with its path; a file that cannot be read previews its message.
- In the prompt: `<C-n>` and `<Down>` move the highlight down, `<C-p>` and `<Up>` up; `<CR>` opens the highlighted file in the editing window; `<C-x>` (and `<C-s>`) in a horizontal split, `<C-v>` in a vertical split, `<C-t>` in a new tab page; `<Esc>` (or a backspace on the empty prompt) closes the finder with its floats and opens nothing.
- Plugin API 2.5, the requests the finder needs: `list_files(root, ignore)` (the files below a root, recursively, with the rules above, at most 100,000), `read_file(path, rows)` (the first rows of a regular file of at most 256 KiB), `live_prompt(id, text, initial, bindings)` (a prompt whose every change of text reaches the new callback `Plugin#on_prompt_change`, with its own command-line keymap bound to the plugin's actions), and `close_prompt` (closes the plugin's own prompt without an answer).
- The core action `file.find` and its `keymap.normal <leader>ff file.find` line are removed: the plugin owns the key.
- A bench scenario `finder` types into the finder over 10,000 files; the time per key stays under 20 ms. While the finder is closed the per-key path adds one boolean read and allocates nothing.

Out of scope: grep over file contents, buffers and recent-files pickers, multi-select, smart case, highlighting the matched letters, a cache of the listing across openings, syntax highlighting in the preview, and a watched file system.

Assumptions: the finder has its own `plugin.finder.ignore` option, defaulting to the explorer's list, since a plugin reads only its own options; hidden files are listed unless ignored; the highlight does not wrap at the ends of the list; Enter on no match closes the finder and opens nothing; a listing past 100,000 files keeps the first 100,000 and says so in the message row.

## Capabilities

### New Capabilities

- `file-finder`: the finder's keys, listing rules, filtering and ranking, preview, and opening.

### Modified Capabilities

- `plugin-host`: the requests `list_files`, `read_file`, `live_prompt`, and `close_prompt`, and the `on_prompt_change` callback (API 2.5).

## Impact

- New: `carat/plugins/finder/plugin.rb`, `carat/plugins/finder/matcher.rb`, `carat/use_cases/files/list_tree.rb`, `test/editor_finder.rb`, `test/plugins_finder_matcher.rb`.
- Changed: `carat/plugin_api.rb` (2.5), `PluginLink`, `FileRequests`, `UiRequests`, `PluginRouter`, `PluginHost`, `Domain::PluginUi`, `HandleKey` (the prompt keymap and the change after each key), `FileHandler` (no `file.find`), `config/plugins.caratrc` and the generated registry, `config/default.caratrc` and its mirror, `bench/keys.rb`, `test/editor_leader.rb`, `test/editor_floats.rb`, `test/use_cases_plugin_files.rb`, `test/runner/run_all.rb`.
- Docs: `docs/plugins.md`, `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, `docs/backlog.md` (the plan notes).
- README.md: changed, Space f f and Ctrl-P open the finder.
- docs/architecture.md: changed, roadmap item 12 is delivered and section 9 lists the 2.5 requests.
