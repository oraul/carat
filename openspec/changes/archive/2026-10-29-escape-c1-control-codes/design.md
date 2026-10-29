# Design

## Context

See proposal.md for motivation. Rendering today: `FramePresenter#paint_line` walks a buffer line one code point at a time, asks `char_width` for its display width (tab to the next tabstop, 2 for a code point below 32, otherwise `DisplayWidth.of_char`) and `shown_text` for what to draw (blanks for a tab, `^X` for a code point below 32, otherwise the character), and writes it with `Frame#put`. `display_col` uses the same `char_width` to map the cursor's code point column to a frame column, so the marker width and the cursor mapping cannot disagree. `Frame#put` stores one code point per cell with the width `DisplayWidth.of` gives it, and `ScreenPresenter#render_row` packs the codes of each row straight into the terminal bytes. Nothing between a buffer line and the terminal rejects U+007F or U+0080 to U+009F, and `DisplayWidth.of` gives them width 1.

Spinel facts the change relies on, all already used by the code it touches: `String#ord` on a one-character string, `Integer#to_s(16)`, string building with `+` on frozen literals, and `each_codepoint` in `Frame#put`.

## Goals / Non-Goals

**Goals:**

- One definition of "unprintable" shared by the presenter and the frame, so the two cannot drift.
- The presenter stays the only place that knows how a buffer line is laid out; the frame's guard is a last line of defense, not a second renderer.
- The screen presenter needs no change: the invariant on frame cells is what keeps raw control code points out of the terminal bytes.

**Non-Goals:**

- A `listchars` or `display` option, Vim's `<xx>` form for other non-printable Unicode such as unassigned code points, and a complete width table.
- Sanitizing anything written by the drivers outside the frame path; the editor writes to the terminal only through `ScreenPresenter`.

## Decisions

### The predicate lives in `DisplayWidth`

`Carat::Domain::DisplayWidth.control?(code)` returns true for a code point below 32, U+007F, and U+0080 to U+009F. `DisplayWidth` is already the domain module that answers "how does this code point display" for both the frame and the presenter, and both already require it, so a new module or a duplicated range check in each file would only add a place to get the range wrong. Alternative considered: a constant range in `FramePresenter` and a second one in `Frame`; rejected because the spec's invariant and the presenter's rendering would then be two definitions.

### The presenter renders the marker; the frame stores U+FFFD

`char_width` returns 4 and `shown_text` returns `"<" + hex + ">"` (two lowercase hexadecimal digits from `code.to_s(16)`, which for this range is always two digits) for U+007F and U+0080 to U+009F, leaving tabs and the caret escapes for code points below 32 as they are. The marker uses `Highlight::NORMAL`, the highlight `paint_line` gives every character, so it matches the existing caret escapes as the request asks.

`Frame#put` stores U+FFFD, the replacement character, for any code point `control?` accepts, with width 1. The alternative of storing the marker in `put` was rejected: `put` writes one code point per cell and returns the column after the last cell, the presenter computes the cursor column from `char_width` before painting, and a frame has no tabstop, so a frame that expanded controls into markers on its own would be a second layout engine whose widths could disagree with the presenter's. U+FFFD keeps `put` a one-code-point-per-cell operation, gives the caller a visible sign that something unprintable was written, and cannot be an introducer on any terminal. In the editor the frame's guard is never hit for buffer text because `paint_line` has already replaced the code point; it covers text that reaches the frame on another path, such as a path with a control byte in the status line or a message that quotes user input.

### The screen presenter is unchanged

`render_row` emits the code points of the cells, and the frame invariant is what guarantees none of them is a control. A second filter in `render_row` would hide a frame that violated the invariant instead of letting the frame test catch it. The screen presenter test asserts the property on the bytes: after removing the presenter's own escape sequences, the output contains no code point from U+0080 to U+009F.

### Partial markers at the right edge

`paint_line` already drops a character whose cells would cross the right edge of the text area, so a four-cell marker that does not fit is dropped as a whole, like a cut caret escape or a cut wide character. Vim shows the part that fits; the simpler rule keeps the existing loop and is noted in the proposal as an assumption.

## Risks / Trade-offs

- [`display_col` now charges four columns for a C1 code point, so a long line of them scrolls horizontally sooner] → Expected; it is the same effect a line of tabs has, and the cursor and the text agree.
- [A caller writing a tab or newline to the frame directly sees U+FFFD, not blanks] → Intended: the presenter expands tabs before `put`, and a tab arriving in `put` is a bug made visible rather than a cell with a raw control.
- [The `make snapshots` run rewrites every `.expected` file] → The diff is reviewed; only the two presenter snapshots gain lines.
