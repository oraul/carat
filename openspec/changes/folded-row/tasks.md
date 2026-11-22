# Tasks

## 1. The Folded group

- [x] 1.1 Add `Highlight::FOLDED` after `MESSAGE_DIM` with the name `Folded`, moving the later ids up by one (`carat/domain/highlight.rb`); prove it in `test/domain_theme.rb` (the group table checks)
- [x] 1.2 Add the `Folded` row to `Themes::GROUPS`, the dim role with no background (`carat/domain/themes.rb`); prove it in `test/domain_theme.rb` (Scenario: Folded in the carat themes)

## 2. The fold row

- [x] 2.1 Paint a closed fold's row text in `Folded` through one constant token entry (`carat/adapters/frame_presenter.rb`); prove it in `test/adapters_frame_presenter.rb` (the four fold scenarios: the row, both themes at 24 bits and 16 colors, ascii and NO_COLOR, the cursor line)
- [x] 2.2 Update the tests and snapshots the moved ids change (`make test-one`, `make snapshots` diff read)

## 3. Docs

- [x] 3.1 Update `docs/compatibility.md` (the fold differences, the UI group count), `docs/architecture.md` (the Highlight paragraph's count), `docs/codebase-map.md` (areas 13 and 14), and README.md (the fold sentence)
- [x] 3.2 Append the planner's backlog notes (`build/plan/folded-row/backlog.md`) and the label-text and ascii-fill findings to `docs/findings/folded-row.md`

## Quality review

- [x] 4.1 The scenario "A closed fold's row is in Folded" said "zfj" is typed, while its test builds the fold through `Folds`; reword the scenario to the fold's state (`specs/folds/spec.md`), fixed
- [x] 4.2 `palette_basic` repeated the loop of `palette_rgb` in `test/adapters_frame_presenter.rb`; both read one `palette_entry` helper, fixed
