# Tasks

## 1. The marker

- [x] 1.1 Add `DisplayWidth.format_char?`, give it six cells in `code_cells`, and paint it as `<xxxx>` in `LinePainter`; prove it in `test/adapters_frame_presenter.rb` and `test/domain_display_width.rb` (Scenarios: Override and zero-width marks as hexadecimal markers; Cursor over and after a format marker)

## 2. One decoder

- [x] 2.1 Move `code_of` from `DisplayWidth` to `Utf8.code_of`; prove it in `test/domain_utf8.rb`

## 3. Docs

- [x] 3.1 Update `docs/architecture.md`, `docs/codebase-map.md`, `docs/compatibility.md`, and the delta spec

## Quality review

- [x] 4.1 Names, menus, and markdown text written through `Frame#put` still draw a format code point raw; recorded in `docs/findings/render-text-lows.md` (a different writer, outside the brief)
- [x] 4.2 U+00AD, U+180E, and U+034F stay unmarked; recorded in `docs/findings/render-text-lows.md` (the set follows Vim's and the finder's)
