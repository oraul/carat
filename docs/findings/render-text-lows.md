### Names and menus still draw format code points raw
- Location: `carat/domain/frame.rb` `put_from` (:195) and `DisplayWidth.text_width`, `bytes_within`, used by the tab bar, the status bar, floats, menus, and markdown text
- Why: a buffer name, a symbol name, or a float line holding U+202E or U+200B is still stored in a cell as it is, so a terminal reorders or hides the row; only buffer-line text goes through `LinePainter` here
- Fix: have `put_from` store U+FFFD (or the marker) for `format_char?` beside `control?`, and count the same in `text_width`, `bytes_within`, and `markdown_text`, with a frame test per writer

### Soft hyphen and other invisible code points stay raw
- Location: `carat/domain/display_width.rb` `format_char?`
- Why: U+00AD, U+180E, and U+034F take no cell or an uncertain one in some terminals; the set follows Vim's plus the finder's, so they are not marked
- Fix: add them to `format_char?` after checking how Neovim draws each, with a row in the width table
