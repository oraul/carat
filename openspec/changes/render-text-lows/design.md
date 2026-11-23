# Design

## Context

`LinePainter#paint_text` marks C0 controls as `^X` and delete and C1 controls as `<xx>`; every other code point is written to the cell as it is. `DecodedLine` takes each code point's width from `DisplayWidth.code_cells`, so a change of width there reaches the cursor and the scroll.

## Goals / Non-Goals

**Goals:**
- No format, bidirectional, or zero-width code point of a file reaches a cell raw; one decoder.

**Non-Goals:**
- Text written through `Frame#put` (bars, floats, menus, markdown) and the file finder's sanitizer.

## Decisions

- The marker is `<xxxx>`, six cells, as Vim shows its unprintable format code points; one width for every member keeps `code_cells` a single branch. All members are in the basic plane, so four digits always suffice.
- The set is Vim's U+200B to U+200F, U+202A to U+202E, U+2060 to U+206F, and U+FEFF, with U+061C and U+2028 and U+2029 added because the file finder already hides them for the same reason.
- `code_cells` checks `format_char?` after `control?`, so the hot path for ASCII and CJK adds one range test after the existing ones.
- `code_of` moves to `Utf8.code_of` (same body): the decoder lives in one module and `DisplayWidth` only measures.
