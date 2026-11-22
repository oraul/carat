# Tasks

## 1. The Folded group

- [ ] 1.1 Add `Highlight::FOLDED` after `MESSAGE_DIM` with the name `Folded`, moving the later ids up by one (`carat/domain/highlight.rb`); prove it in `test/domain_theme.rb` (the group table checks)
- [ ] 1.2 Add the `Folded` row to `Themes::GROUPS`, the dim role with no background (`carat/domain/themes.rb`); prove it in `test/domain_theme.rb` (Scenario: Folded in the carat themes)

## 2. The fold row

- [ ] 2.1 Paint a closed fold's row text in `Folded` through one constant token entry (`carat/adapters/frame_presenter.rb`); prove it in `test/adapters_frame_presenter.rb` (the four fold scenarios: the row, both themes at 24 bits and 16 colors, ascii and NO_COLOR, the cursor line)
- [ ] 2.2 Update the tests and snapshots the moved ids change (`make test-one`, `make snapshots` diff read)

## 3. Docs

- [ ] 3.1 Update `docs/compatibility.md` (the fold differences, the UI group count), `docs/architecture.md` (the Highlight paragraph's count), `docs/codebase-map.md` (areas 13 and 14), and README.md (the fold sentence)
- [ ] 3.2 Append the planner's backlog notes (`build/plan/folded-row/backlog.md`) and the label-text and ascii-fill findings to `docs/findings/folded-row.md`
