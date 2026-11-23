# Tasks

## 1. The groups

- [x] 1.1 Draw the visual indicators in `ModeMsg` (`carat/adapters/frame_presenter.rb`, `paint_message`); prove it in `test/adapters_frame_presenter.rb` (Scenario: The visual indicators are in ModeMsg)
- [x] 1.2 Remove `MESSAGE_MORE`, its name, and its theme row, moving the later ids down one (`carat/domain/highlight.rb`, `carat/domain/themes.rb`); prove it in `test/domain_theme.rb` (Scenario: The UI groups, The groups in the carat themes)

## 2. The bytes

- [x] 2.1 Add a pty case at `TERM=xterm-color`, at `TERM=xterm`, and under `NO_COLOR` comparing the bar's `StatusLine` and `StatusLineDim` sequences and the indicator's (`test/smoke_editor.rb`, `test/smoke_editor.rb.expected`; Scenario: The bar's bytes at 16 colors, 256 colors, and under NO_COLOR)

## 3. Docs

- [x] 3.1 Update README.md, `docs/compatibility.md`, and `docs/codebase-map.md`
- [x] 3.2 Append the findings to `docs/findings/ui-groups-c.md`

## Quality review

- [x] 4.1 `design.md` said NO_COLOR writes no color, which the bytes contradict; corrected, the behavior recorded in `docs/findings/ui-groups-c.md`, fixed
