# Tasks

## 1. The tab row

- [x] 1.1 Remove the separator and its constants, set `FRAME_CELLS` to 5, and start the row at a start column (`carat/adapters/tab_bar.rb`); prove it in `test/adapters_tab_bar.rb` (Scenarios: Two tabs, one modified; The ascii icons give the ascii gem and separator; The row starts at the editor's first column)
- [x] 1.2 Add `TabBar#paint_head` and paint it over the left sidebar on the tab row, tabs starting after it (`carat/adapters/frame_presenter.rb`, `paint_tab_head`); prove it in `test/adapters_tab_bar.rb` and `test/adapters_frame_presenter.rb` (Scenarios: The sidebar's head reads the project and branch; The tab row beside a sidebar)

## 2. The sidebar

- [x] 2.1 Add `Slot#headed?` and use it in `ArrangeView#reserve_headers`; paint the head in a one-view left sidebar's header row (`paint_header`); prove it in `test/domain_slot.rb`, `test/editor_slots.rb`, and `test/editor_plugins.rb` (Scenarios: Header of one view; Header of two views)
- [x] 2.2 Draw blank rows below a sidebar's text with `PaintedRows::BLANK`; prove it in `test/adapters_frame_presenter.rb` and `test/editor_explorer.rb` (Scenario: Rows past a sidebar's text are blank)
- [x] 2.3 Update the expectations and snapshots the changes make stale (`test/editor_tabs.rb`, `test/editor_tab_flows.rb`, `make snapshots` diff read)

## 3. Docs

- [x] 3.1 Update README.md, `docs/compatibility.md`, and `docs/codebase-map.md`
- [x] 3.2 Append the out-of-scope gaps to `docs/findings/surface-edges-fix.md`

## Quality review

- [x] 4.1 The head reuses three existing groups; recorded in `docs/findings/surface-edges-fix.md` (a new group shifts every group id and `one-accent` adds its own)
- [x] 4.2 The project name lags a `:cd`, as `BufferList#base` is set only at startup and by `OpenFile`; recorded in the findings file (a working-directory port in the presenter is new behavior)
- [x] 4.3 The right sidebar and the panel keep their title rows and the tab row spans a right sidebar; recorded in the findings file (a design decision)
- [x] 4.4 Tabs sit three cells apart, the council's spec being two; recorded in the findings file (`one-accent` owns the padding)
- [x] 4.5 A narrow sidebar cuts the head with no ellipsis; recorded in the findings file (the council defers narrow widths)
