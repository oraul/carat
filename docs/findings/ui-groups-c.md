### NO_COLOR keeps every theme color in the bytes the terminal receives
- Location: `carat/adapters/screen_presenter.rb`, `carat/adapters/sgr_table.rb` (`sequence`), `carat/drivers/ansi_terminal.rb` (`no_color?`)
- Why: under NO_COLOR the editor changes glyphs and fills but still writes 256-color or 24-bit sequences (the smoke case in `test/smoke_editor.rb` shows `38;5;` in the bar under NO_COLOR); the no-color convention asks for no color sequences, and `docs/compatibility.md` and the specs say only that the groups are kept, so the smoke case proves the bold-versus-plain difference and not the absence of colors
- Fix: give `SgrTable.from_theme` a plain mode that writes the attributes and no color, set from `terminal.no_color?` in `EditorAssembly#open`, and change the specs that say NO_COLOR keeps the groups to say it keeps the attributes

### At 16 colors StatusLine and StatusLineDim differ only by bold
- Location: `carat/domain/themes.rb` (the `STATUS` and `STATUS_DIM` rows), `carat/adapters/sgr_table.rb`
- Why: the bytes at `TERM=xterm-color` are `\e[0;1;30;47m` and `\e[0;30;47m`, the same foreground and background; a terminal that draws bold as bright, as xterm does by default, shows the file name in a lighter color than the quiet text, the reverse of the design's order
- Fix: give `STATUS_DIM` a 16-color foreground of its own (bright black on the bar's background, as `TabLine` has) and add a sequence row for it in `test/adapters_screen_presenter.rb`

### TERM=xterm is detected as 256 colors
- Location: `carat/domain/color_depth.rb` (`BASIC_TERMS`)
- Why: the brief and `docs/design.md` speak of 16 colors under xterm's default colors, but only `xterm-color` and the other listed names reach 16 colors, so a plain `xterm` gets 256-color sequences; the smoke case checks `xterm-color` for 16 colors and `xterm` for 256
- Fix: keep the list (a real xterm shows 256 colors) and say so in `docs/design.md`, or list `xterm` when its `COLORTERM` is empty
