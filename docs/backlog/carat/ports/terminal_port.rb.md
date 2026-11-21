# Backlog: carat/ports/terminal_port.rb

## NO_COLOR leaves syntax, bars, and messages colored

- Where: `TerminalPort#no_color?` (`carat/ports/terminal_port.rb`), read by `EditorAssembly#open` for the start screen's glyphs (`start-screen`) and, through `FramePresenter#plain=` (`carat/adapters/editor_assembly.rb` line 489 at 5e4c140), for the ASCII notification boxes and progress, the plain status bar, and the uncolored documentation floats and pinned split (`quick-docs-styles`); `SgrTable.from_theme` and `ScreenPresenter` color every other cell from the theme.
- Why it matters: the `NO_COLOR` convention asks a program to add no ANSI color at all, so a user who sets it still gets syntax, status line, and message colors.
- Fix outline: a color depth of none in `Domain::ColorDepth` chosen by `AnsiTerminal` when `NO_COLOR` is set, for which `SgrTable.sequence` emits attributes only (bold, reverse, underline), with rows in `test/adapters_screen_presenter.rb` and `docs/compatibility.md`.
- Merged: ### NO_COLOR leaves syntax, bars, and messages colored
- Location: carat/adapters/editor_assembly.rb:591 and :593 (the only readers of `no_color?`), carat/adapters/frame_presenter.rb:353 (`plain=`)
- Why: under NO_COLOR only the border, the status bar's glyphs, the start art, and the hover float go plain, while the syntax highlight, the bars' colors, and the message row keep their colors; split from lsp-tidy by the plan and queued as `lsp-tidy-c`
- Fix: have the frame presenter drop every color attribute when plain (keeping bold, reverse, and underline), with a frame test per surface under NO_COLOR that fails before the fix
- Also: carat/adapters/editor_assembly.rb, test/adapters_screen_presenter.rb, docs/compatibility.md, carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-09
