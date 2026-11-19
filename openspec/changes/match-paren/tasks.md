# Tasks

## 1. Rendering

- [x] 1.1 Add the `pair` key to every segment of `PaintedRows` (`carat/adapters/painted_rows.rb`; `test/adapters_frame_presenter.rb`, the repaint scenario)
- [x] 1.2 Find the pair in view under `PAIR_BUDGET` and paint it in `MatchParen` in `FramePresenter` (`carat/adapters/frame_presenter.rb`; `test/adapters_frame_presenter.rb`, the pair, unmatched, and mode scenarios)

## 2. Docs

- [x] 2.1 Document the highlight and its differences from Neovim in `docs/compatibility.md`, `docs/architecture.md` section 8, and map area 13 (`make docs-lint`)

## 3. Review fixes

- [x] 3.1 State the closed-fold exclusion and the Visual precedence in the requirement and `docs/compatibility.md`, with a scenario and table row for a window holding a closed fold
- [x] 3.2 Write the pair condition once in `FramePresenter`
- [x] 3.3 Test the `PAIR_BUDGET` stop with a table row
- [x] 3.4 Say in `find_pair` why it stays apart from `Motions.match_pair`
- [x] 3.5 Name the insert case in `pair_case` and make the unknown case return a value no row expects
- [x] 3.6 List the matching brackets in the row segment record of `docs/architecture.md`
