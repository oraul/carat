# Proposal

## Why

`docs/design.md` section 8 says the tab row heads the explorer's column with the project and branch, and that the current row is a full-width highlight with the sapphire `▎`. Today the tree still spends its first row on the root's name, repeating the head above it, and marks the current file with a one-cell `›` and nothing else. Section 7 lists both as known drift, closed by this change.

## What Changes

- The tree has no line for the root: its first line is the root's first entry, the entries of the root are at depth 0 (no indent), and the rows of the keys that named the root line go: `h` on a top-level entry, `<CR>` `l` `o` on the root, `r` and `d` on the root all disappear with it. `a` on a top-level file, or in a tree with no entry, creates in the root.
- The `current` icon is the bar `▎` in the unicode set and `|` in the ascii set (the nerd set keeps its private use glyph, its contract), no longer a chevron or `>`.
- A new host request `mark_scratch_row(title, row)` (plugin API 2.17) marks one row of a plugin's scratch buffer; the frame presenter draws a marked row as the selection fill (`PmenuSel`) across the window with its first cell in `PmenuMarkSel`, under NO_COLOR the bar alone. `set_scratch_lines` clears the mark. The explorer marks the row of the current file after every fill and refresh.
- `docs/design.md` section 7 drops its closed drift row.

Assumptions: the entries of the root start at depth 0, so the line is the marker cell, the icon, a space, and the name, the marker cell being the one cell of padding; the icon of the current row is drawn in `PmenuSel` with its text rather than in its file-type color, as the finder's selected row is, since a cell holds one group; the nerd set's `current` glyph stays a private use glyph because the icon table's test requires that of every nerd glyph, recorded in the findings file; the label of the current row is not bold, the design's bold label left for the facet that unifies the four selection marks (`one-accent`). The roadmap: outside it, a UI refinement of `docs/design.md`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `file-explorer`: no root line, the current row's highlight, the keys that no longer meet a root line.
- `plugin-host`: `mark_scratch_row`, API 2.17.
- `icons`: the current marker glyphs.

## Impact

- Code: `carat/plugins/explorer/tree.rb`, `node.rb`, `plugin.rb`; `carat/domain/buffer.rb` (`marked_row`), `carat/domain/icons.rb`; `carat/plugin_api.rb`, `carat/use_cases/plugins/plugin_link.rb`, `window_requests.rb`; `carat/adapters/frame_presenter.rb`.
- Tests: `test/editor_explorer.rb`, `test/plugins_explorer.rb`, `test/editor_plugins.rb`, `test/domain_icons.rb`, `test/domain_buffer.rb`, the API version tests, and their snapshots.
- Docs: `docs/plugins.md` (the request and version 2.17), `docs/design.md` (the drift row), `docs/codebase-map.md`, README.md (the file tree paragraph).
- docs/architecture.md: unchanged, it names neither the tree's lines nor the request.
- docs/compatibility.md: unchanged, the tree is no Neovim command.
- docs/actions.md: unchanged, no action is added or removed.
