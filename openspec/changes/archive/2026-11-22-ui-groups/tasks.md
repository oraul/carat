# Tasks

## 1. The quiet group

- [x] 1.1 Add `Highlight::STATUS_DIM` after `FOLDED` with the name `StatusLineDim`, moving the later ids up by one (`carat/domain/highlight.rb`); prove it in `test/domain_theme.rb` (the group table checks)
- [x] 1.2 Add the `PANEL_DIM` role to every palette and the `StatusLineDim` row to `Themes::GROUPS` (`carat/domain/themes.rb`); prove it in `test/domain_theme.rb` (Scenario: StatusLineDim is the bar's quiet text in every palette, at 24 bits, 256 colors, and 16 colors)

## 2. The bar

- [x] 2.1 Draw the branch, file type, encoding, and a stateless server in `StatusLineDim` (`carat/adapters/status_bar.rb`); prove it in `test/adapters_status_bar.rb` (Scenario: The quiet text, A row per state)
- [x] 2.2 Add the one-cell gap before each segment that starts an independent group, counted in the width (`carat/adapters/status_bar.rb`); prove it in `test/adapters_status_bar.rb` (Scenario: The spacing between the groups, Widths drop segments one by one, the segment tables, NO_COLOR)
- [x] 2.3 Draw the three visual mode indicators of the message row in `MsgDim` (`carat/adapters/frame_presenter.rb`); prove it in `test/adapters_frame_presenter.rb` (Scenario: The visual indicators are dim)
- [x] 2.4 Update the tests and snapshots the spacing and the ids change (`make test-one`, `make snapshots` diff read)

## 3. Docs

- [x] 3.1 Update `docs/compatibility.md` (the segment table, the UI group count), `docs/architecture.md` (the `Highlight` count), `docs/codebase-map.md` (areas 13 and 14), and README.md (the status bar sentence)
- [x] 3.2 Append the planner's backlog notes (`build/plan/ui-groups/backlog.md`) and the out-of-scope gaps to `docs/findings/ui-groups.md`

## Quality review

- [x] 4.1 The proposal did not say how far apart the diagnostics counts sit inside their group; state that they are one group and stay one cell apart (`proposal.md`, Assumptions), fixed
