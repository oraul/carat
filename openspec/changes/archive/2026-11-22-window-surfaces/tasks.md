# Tasks

## 1. The sidebar layer

- [x] 1.1 Add `Highlight::SIDEBAR_LAYER`, grow `LIMIT` to four layers, and let `Highlight.base` strip it (`carat/domain/highlight.rb`); prove it in `test/domain_theme.rb` (Scenario: A sidebar window sits on a darker background)
- [x] 1.2 Build the sidebar layer in `Themes.from_palette` on `PANEL_NC`, the group itself at 16 colors, and make `WinSeparator` the `BORDER` role (`carat/domain/themes.rb`); prove it in `test/domain_theme.rb` (Scenario: A sidebar window sits on a darker background, Scenario: WinSeparator is the quiet border tone)
- [x] 1.3 Let `Frame#lift` lift only a plain group's cell (`carat/domain/frame.rb`); proved by the cursor-line and sidebar tests

## 2. The edge

- [x] 2.1 Draw a fixed-width window's rows on the sidebar layer and the column beside a sidebar as a blank cell of it, with `basic_colors=` and `plain` keeping the glyph (`carat/adapters/frame_presenter.rb`, `editor_assembly.rb`, `Layout#sidebar?` public); prove it in `test/adapters_frame_presenter.rb` (Scenario: A sidebar beside the editor draws no separator glyph, Scenario: Without a background change the sidebar keeps its edge)
- [x] 2.2 Update the explorer test's highlight and separator expectations (`test/editor_explorer.rb`) and `make snapshots`, the diff read

## 3. Docs

- [x] 3.1 Update `docs/design.md` (the fallback edge), `docs/architecture.md`, `docs/compatibility.md`, `docs/codebase-map.md`, and README.md

## Quality review

- [x] 4.1 The cursor row of a current sidebar (cursor-line layer over the sidebar layer) had no test of its own; add it to `test/adapters_frame_presenter.rb`, fixed
- [x] 4.2 The bottom panel stays on `Normal`, though the design lists it among the panels; recorded in `docs/findings/window-surfaces.md` as out of this change's scope (the brief names the sidebar), recorded
