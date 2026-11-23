# Proposal

## Why

A file holding U+202E (right-to-left override) makes the terminal reorder the cells of its row, and U+200B (zero width space) hides text, because the line painter writes every code point that is not a C0 or C1 control raw. The decoding of a first character, `DisplayWidth.code_of`, also sits in the width table beside the decoder it wraps.

## What Changes

- `DisplayWidth.format_char?` names the code points a terminal draws in no cell or reorders: U+061C, U+200B to U+200F, U+2028 to U+202E, U+2060 to U+206F, and U+FEFF (Vim's unprintable format set plus the bidirectional and separator code points the file finder already hides). `code_cells` gives each six cells, so the cursor, the columns, and the horizontal scroll agree with the frame.
- `LinePainter` paints such a code point as `<` and four lowercase hexadecimal digits and `>` in Normal, as it does for the C1 controls with two digits.
- `code_of` moves from `DisplayWidth` to `Utf8.code_of`, the one decoder; `DisplayWidth.cell` calls it.
- README.md, `docs/architecture.md`, the code map, and the compatibility differences name the new marker.
- Closed by evidence, with no code: `NO_NAME` has one copy (`carat/domain/messages.rb`), `DisplayWidth.of_char` and `TabBar#icon_group` are gone, so their three backlog entries close as listed.

Out of scope, recorded in the findings file: names painted through `Frame#put` and `text_width` (bars, floats, markdown) still draw a format code point raw.

Roadmap: outside `docs/architecture.md` section 12 (a hardening of the delivered rendering).

Assumptions: the marker follows Vim's `<xxxx>` form; U+00AD and U+180E stay as they are. A marker cut by the window's edge shows as blanks, as a C1 marker does.

## Capabilities

### New Capabilities

### Modified Capabilities
- `screen-rendering`: the marker of a format code point in a buffer line.

## Impact

- Code: `carat/domain/display_width.rb`, `carat/domain/utf8.rb`, `carat/adapters/line_painter.rb`.
- Tests: `test/adapters_frame_presenter.rb`, `test/domain_utf8.rb`, `test/domain_display_width.rb`.
- Docs: README.md, `docs/architecture.md`, `docs/codebase-map.md`, `docs/compatibility.md`.
