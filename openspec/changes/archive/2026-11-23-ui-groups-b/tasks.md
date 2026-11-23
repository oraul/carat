# Tasks

## 1. The bar

- [x] 1.1 Draw the file's folder in `StatusLineDim` and its last segment in `StatusLine` (`carat/adapters/status_bar.rb`, `paint_file_name`); prove it in `test/adapters_status_bar.rb` (Scenario: The folder before the file name)
- [x] 1.2 Draw the `lsp` slot as the name in `StatusLineDim` and one dot in the state's group, the crash and untrusted hints after it, with `StatusSlots.hint` (`carat/adapters/status_bar.rb`, `carat/domain/status_slots.rb`); prove it in `test/adapters_status_bar.rb` (Scenario: The slot names the state, A row per state) and `test/adapters_language_gateway.rb` (Scenario: Indexing shows a percent, A crash names the restart command)
- [x] 1.3 Draw the progress bar's undone cells and the percent in `StatusLineDim` (`carat/adapters/status_bar.rb`); prove it in `test/adapters_status_bar.rb` (Scenario: A bar at a percent, An ascii bar, Plain bar under NO_COLOR, The quiet text)
- [x] 1.4 Update the expectations and snapshots the dot changes (`test/editor_lsp.rb`, `make snapshots` diff read)

## 2. Docs

- [x] 2.1 Update README.md, `docs/compatibility.md`, and `docs/codebase-map.md`
- [x] 2.2 Append the out-of-scope gaps to `docs/findings/ui-groups-b.md`

## Quality review

- [x] 3.1 `StatusSlots.hint` had no direct test; assert each state's hint in `test/adapters_status_bar.rb`, fixed
- [x] 3.2 `paint_entry` asks `lsp_group` again after `paint_lsp` did for the closing space; recorded in `docs/findings/ui-groups-b.md` (a return of two values would need an object per frame)
