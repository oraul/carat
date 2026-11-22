# Proposal

## Why

The finder plugin binds only `<leader>ff`, `<leader>fg`, and `<C-p>` (`carat/plugins/finder/plugin.rb:101`): there is no way to pick among the open buffers, to reopen a file used a moment ago, or to get the last search back after closing it. The design council of 2026-11-21 approved (2) a buffer picker with recent files and (3) the keys `<leader>fr` and `<leader>fR`. Roadmap: item 12, `plugin-explorer-and-finder` (`docs/architecture.md` section 12), whose finder gains the pickers that telescope and fzf-lua users expect.

## What Changes

- `<leader>fb` opens the finder's picker over the listed file buffers, in `:ls` order, titled `Buffers N/M`, filtered and picked as the file finder is.
- `<leader>fr` opens the picker over the recent files, most recent first, titled `Recent N/M`: every file shown in a window since the editor started, also after `:bd`, at most 100, a file shown again moving to the top.
- `<leader>fR` reopens the last picker the finder closed, the files, grep, buffers, or recent picker, with its typed text and its highlight, the list read again; with none closed yet it shows `No search to resume`.
- Two plugin host requests at API 2.14: `list_buffers` (the paths of the listed file buffers) and `recent_files` (the recent file paths, most recent first), each a `PluginApi::Host` method, a `PluginLink` override, and a buffer request family method.
- The buffer list keeps the bounded recent file list as each file buffer enters a window.
- Docs: `docs/actions.md` rows for the three actions, `docs/compatibility.md` File finder rows, `docs/plugins.md` (the two requests, the version history, `api_version`), README's `<leader>f` paragraph, `docs/architecture.md` section 9.1's request list and the item 12 line, `docs/codebase-map.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `file-finder`: ADDED requirements for the buffer picker, the recent files picker, and resuming the last search, and for their frame rows in both carat themes and under `option.icons ascii`.
- `plugin-host`: ADDED requirements for the `list_buffers` and `recent_files` requests and for the recent list's bounds; MODIFIED the three requirements whose "still loads" scenarios name the host version (set_float_lines, style_float, set_float_border), now 2.14.

## Out of scope

- Recent files kept across editor runs (Neovim's `oldfiles` from shada): this change keeps them for the session only, so no state file is written; a persisted list is a follow-up recorded in the findings file.
- A buffer preview of unsaved text: the preview reads the file from the disk as the file finder's does.
- Sorting buffers by last use, deleting a buffer from the picker, and the finder's one-frame layout of `docs/design.md` (`finder-rows`).
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: a resume reads the list again (buffers closed since are gone, grep reads the files again) and puts the highlight back on its row, clamped to the last match, rather than keeping a stale list.
- Assumption: the recent list records the path as the buffer holds it (as `:ls` shows it), skipping scratch and unnamed buffers.

## Impact

- README.md: the `<leader>f` paragraph names `fb`, `fr`, and `fR`.
- docs/architecture.md: section 9.1 lists the two requests, and the item 12 line names `buffer-picker`; two "from the explorer change" notes the asterisk already says are dropped and the item 12 line is shortened, so the file stays within its docs-lint budget.
- docs/codebase-map.md: the `plugin_api.rb` (2.14), `buffer_list.rb`, `buffer_requests.rb`, `plugin_link.rb`, and finder lines.
- CLAUDE.md: unchanged, no process change.
- Performance: the recent list is updated when a buffer enters a window, a bounded array of at most 100 paths; no key of `lh`, `j`, or `insert` changes a window's buffer.
