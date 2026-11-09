# Design

## Context

See proposal.md, Why. `FollowPalette#pad` cuts a column's text with `cut(text, width - 1)`, which keeps `width - 1` characters, then pads with `" " * (width - used)` where `used` is the text's cells; seven wide characters in the key column (12 cells) give 14 cells and a negative count, and `String#*` raises. `ShowKeyHints#cut` is a copy that cuts by characters too; its layout pads only when the target is ahead, so it overflows rather than raises. `ShowCompletion#fit` already cuts by cells, slicing every character into a new string. `DisplayWidth.text_width` walks bytes and counts a control character one cell, as `Frame#put` draws it.

## Goals / Non-Goals

**Goals:**

- One cell-aware cut and one cut-and-pad in the domain, used by the palette, the key hints, and the completion menu.
- No negative pad anywhere a menu pads by display width.
- No allocation while no menu shows, and none added when the text already fits.

**Non-Goals:**

- Changing the palette's column widths or the hints' column layout.
- `DisplayWidth.col_at`, which counts tabs and controls as the window draws them; menus draw text through `Frame#put`, which `text_width` matches.

## Decisions

- `DisplayWidth.bytes_within(text, width)` walks the bytes as `text_width` does and answers the byte length of the longest prefix within `width` cells: it stops before the first character that would pass the width, so a zero-width combining mark after the last kept character is kept and one after a dropped character is dropped. A negative width answers 0. Bytes rather than characters, so the cut is one `byteslice` and invalid UTF-8 is measured as the frame decodes it (each stray byte one U+FFFD cell).
- `DisplayWidth.cut(text, width)` answers the text itself when it fits, else `text.byteslice(0, n).to_s`, written through a local rather than a guard return of the argument, the shape `docs/spinel-notes.md` lists among the open miscompilations; the table test catches it either way.
- `DisplayWidth.fit(text, width)` builds a new string of the cut text padded with spaces to `width`, the pad added only when the cut text is narrower, so it can never be negative. The palette's column is `fit(text, width - 1)` and one space, the same layout as before for narrow text.
- Alternative considered: clamp the pad at 0 in `FollowPalette#pad` alone. Rejected: the key column would still overflow into the description, and the hints keep the same defect; the backlog entry asks for one helper.
- The helpers live in `Domain::DisplayWidth`, beside `text_width`, since all three callers are use cases and already require it.

## Risks / Trade-offs

- [The completion menu's rows change if the helper differs from its old `fit`] → The old `fit` measured each character with `text_width` and stopped at the first that passed the width, the same rule; `test/editor_completion.rb` and its snapshot cover the rows.
- [Allocations] → `cut` allocates only when it cuts; `fit` allocates the row cell as before; nothing runs while no menu shows, so `lh` and `lh-float` are unchanged.
