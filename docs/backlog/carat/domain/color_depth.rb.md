# Backlog: carat/domain/color_depth.rb

### TERM=xterm is detected as 256 colors
- Location: `carat/domain/color_depth.rb` (`BASIC_TERMS`)
- Why: the brief and `docs/design.md` speak of 16 colors under xterm's default colors, but only `xterm-color` and the other listed names reach 16 colors, so a plain `xterm` gets 256-color sequences; the smoke case checks `xterm-color` for 16 colors and `xterm` for 256
- Fix: keep the list (a real xterm shows 256 colors) and say so in `docs/design.md`, or list `xterm` when its `COLORTERM` is empty
- Also: docs/design.md
- Category: editor
- Added: 2026-11-24
