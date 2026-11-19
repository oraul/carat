# Tasks

## 1. Rendering

- [x] 1.1 Lift the cursor line from the window's left edge and pick a number's group in `FramePresenter` (`carat/adapters/frame_presenter.rb`; `test/adapters_frame_presenter.rb`, the gutter and number scenarios)
- [x] 1.2 Add `LineNrFifth`, make `LineNr` FAINT, and hold `LineNr` to 3:1 (`carat/domain/highlight.rb`, `carat/domain/themes.rb`; `test/domain_theme.rb`)
- [x] 1.3 Give the command line the bar cursor (`shape_of`; the shape table of `test/adapters_frame_presenter.rb`)

## 2. Docs

- [x] 2.1 Document the cursor line, numbers, and shapes in `docs/compatibility.md`, `docs/architecture.md` section 8, and map area 13 (`make docs-lint`)

## 3. Review fixes

- [x] 3.1 Make relativenumber an input of the frame key and test toggling on one presenter with the cursor on row 9
- [x] 3.2 Pick LineNrFifth by the cursor flag so a closed fold holding the cursor is never a fifth number
- [x] 3.3 Correct the class comment, the table comment, the theme test label and names, the WCAG sentence, and the 256-color note; assert the gutter group directly and a sign on the cursor row
- [x] 3.4 Toggle relativenumber after two relative draws so each double-buffered frame is repainted; rewrap two comments; record the Light+ LineNrFifth choice in the design
