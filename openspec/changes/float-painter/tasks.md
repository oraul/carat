# Tasks

## 1. Line painter

- [x] 1.1 Add `carat/adapters/line_painter.rb` (`LinePainter`) with `paint_text`, `paint_tokens`, and the private `paint_plain` and `hex_digit` moved from `FramePresenter`, the presenter's window path calling it. Proven by `test/adapters_frame_presenter.rb` and every window snapshot unchanged.

## 2. Float painter

- [x] 2.1 Add `carat/adapters/float_painter.rb` (`FloatPainter`) with the float and notification methods and constants moved from `FramePresenter`, `configure`, `plain=`, `boxes?`, `build_key`, and `paint`; the presenter takes `float_painter:` in place of `notices:` and keeps the frame bookkeeping. Proven by `test/editor_floats.rb`, `test/editor_messages.rb`, and `test/adapters_frame_presenter.rb` unchanged.
- [x] 2.2 Build it in `carat/adapters/editor_assembly.rb` and in the tests that build a presenter (`test/adapters_frame_presenter.rb`, `test/adapters_indent_guides.rb`, `test/adapters_whitespace_marks.rb`, `test/adapters_screen_presenter.rb`); `test/adapters_assembly.rb` checks the one cache and the one notifications.
- [x] 2.3 Add `test/adapters_float_painter.rb` with its snapshot: a bordered float with a title, a notification box, a plain box in ASCII, and the key per box.

## 3. Docs

- [x] 3.1 `docs/codebase-map.md` area 13: the two new files, the float painter's methods moved from the presenter's entry, the new test; `docs/architecture.md` section 8.2 names `FloatPainter`.

## 4. Checks

- [ ] 4.1 `make lint`, `make diagnose-one` on the new files, `make docs-lint`, `make gates`, `make spec-validate`.
