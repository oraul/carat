### Names and menus still draw format code points raw
- Location: `carat/domain/frame.rb` `put_from` (:195) and `DisplayWidth.text_width`, `bytes_within`, used by the tab bar, the status bar, floats, menus, and markdown text
- Why: a buffer name, a symbol name, or a float line holding U+202E or U+200B is still stored in a cell as it is, so a terminal reorders or hides the row; only buffer-line text goes through `LinePainter` here
- Fix: have `put_from` store U+FFFD (or the marker) for `format_char?` beside `control?`, and count the same in `text_width`, `bytes_within`, and `markdown_text`, with a frame test per writer

### Soft hyphen and other invisible code points stay raw
- Location: `carat/domain/display_width.rb` `format_char?`
- Why: U+00AD, U+180E, and U+034F take no cell or an uncertain one in some terminals; the set follows Vim's plus the finder's, so they are not marked
- Fix: add them to `format_char?` after checking how Neovim draws each, with a row in the width table

### Frame#put_from writes bidirectional and zero-width format code points raw (security Low (6))

- Where: `carat/domain/frame.rb:195`.
- Why it matters: `DisplayWidth.of` gives them width 1, so they are not skipped; a buffer name, a file name in the tab or status bar, or LSP hover and float text holding U+202E can make the terminal reorder or hide the row, a visual spoofing of what the user sees outside buffer lines.
- Fix outline: in `put_from`, map `DisplayWidth.format_char?(raw)` to `REPLACEMENT` (or the `<xxxx>` marker) beside `control?`, and count the same in `text_width`, `bytes_within`, and `markdown_text`, with a frame test for each writer.
None.
