# Tasks

## 1. The tree

- [x] 1.1 Drop the root node: `Tree#build` walks the root at depth 0, `Node#root?` and the guards in `Plugin` go, `parent_row` answers -1 for a top-level entry, `a` creates in the root when no entry is under the cursor (`carat/plugins/explorer/`); prove it in `test/plugins_explorer.rb` and `test/editor_explorer.rb` (Scenario: The tree starts at the root's entries, Scenario: Top level, Scenario: Nested, Scenario: Top-level entry)
- [x] 1.2 Make `current` the bar `▎` in the unicode set and `|` in ascii (`carat/domain/icons.rb`); prove it in `test/domain_icons.rb` (Scenario: Current marker)

## 2. The current row

- [x] 2.1 Add `Buffer#marked_row` and the host request `mark_scratch_row`, API 2.17 (`carat/domain/buffer.rb`, `carat/plugin_api.rb`, `plugin_link.rb`, `window_requests.rb`); prove it in `test/editor_plugins.rb` and the version tests (Scenario: A plugin marks a row, Scenario: Clearing the mark, Scenario: A row outside the buffer)
- [x] 2.2 Draw the marked row in the frame presenter (`paint_marked_row`) and mark the current file's row from the explorer (`mark_current`); prove it in `test/editor_explorer.rb` (Scenario: The current row is a full-width highlight, Scenario: The highlight follows the current file)

## 3. Docs

- [x] 3.1 Update `docs/plugins.md`, `docs/design.md` (drop the drift row), `docs/codebase-map.md`, and the README's file tree paragraph
- [x] 3.2 Append the findings to `docs/findings/explorer-rows.md`

## Quality review

