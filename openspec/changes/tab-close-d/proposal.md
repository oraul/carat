# Proposal

## Why

Under `option.gt buffers`, the explorer's `t` pressed when only the tree is left in the tab page opens tab page 2 and leaves tab page 1 holding only the tree, a state the tab flows reject and a user reported; the host's `open_as_tab` falls back to a tab page when no window shows a file, and no test covered it. The finder's `<C-t>` still always opens a tab page, while the explorer's `t` follows `option.gt`, so the same "open as a tab" key does two different things under the default option.

This is outside the roadmap order of `docs/architecture.md` section 12: a user-reported bug (Sprint 16, item 1) in the explorer and finder plugins of section 9.

## What Changes

- The explorer's `t` on a file, when no window of the tab page shows a file, opens it as `l` does: the tree's window takes the file and the tree opens again at its edge, under `option.gt buffers` and `option.gt tabpages` alike, so no tab page is left holding only the tree.
- The finder's `<C-t>` opens the pick as the tab the top row shows, as the explorer's `t` does: a buffer tab in the editing window under `option.gt buffers`, a new tab page under `option.gt tabpages`; when no window of the tab page shows a file it opens the pick as `<CR>` does.
- The finder's action description, header comment, and `docs/actions.md` row say so.

Assumption (minor, recorded here): the brief's acceptance names "option.gt buffers and tabs"; the option's values are `buffers` and `tabpages`, so "tabs" is read as `option.gt tabpages`.

Assumption (minor, recorded here): the fix lives in the two plugins, each checking `editing_window` before asking for a tab, as `l` and `<CR>` already do. The host request `open_as_tab` keeps its documented contract (a tab page when no window shows a file), so the plugin API stays at 2.9 and no third-party plugin sees a changed request; only the explorer can reopen its tree at the edge, which a host-side fallback could not do.

Out of scope: changing `open_as_tab` or `open_in_tab` in the host; keeping the tree when the finder opens a pick from a lone tree (it replaces the current window as `<CR>` does today); any other explorer or finder key.

## Capabilities

### New Capabilities

### Modified Capabilities
- `file-explorer`: adds that `t` with no file window in the tab page opens the file as `l` does.
- `file-finder`: `<C-t>` moves to its own requirement: it follows `option.gt` and, with no file window, opens the pick as `<CR>` does.

## Impact

- `carat/plugins/explorer/plugin.rb` (`open_path`, the `t` decision and its comments), `carat/plugins/finder/plugin.rb` (`open_path`, the action description, the header comment).
- Tests: `test/editor_tab_flows.rb` (flows for `t` from a lone tree and the finder's `<C-t>` under both values), `test/editor_finder.rb` (the `<C-t>` rows under both values), `test/editor_explorer.rb` if a row expects the old behavior.
- Docs: `docs/actions.md` (the finder's `open_tab` row), `docs/plugins.md` (the `open_as_tab` row's mention of the finder's `<C-t>`).
- README.md: unchanged, it does not describe the explorer's `t` or the finder's `<C-t>`.
- docs/architecture.md: unchanged, section 9 does not describe these keys; the specs are the contract.
- CLAUDE.md: unchanged, no process changes.
