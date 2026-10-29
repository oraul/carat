# Proposal

## Why

The frame presenter escapes only code points below 32 as caret notation, so U+007F and the C1 controls U+0080 to U+009F in a buffer line pass through the frame and the screen presenter raw. On xterm and VTE terminals the UTF-8 forms of U+009B and U+009D act as CSI and OSC introducers, so an attacker-supplied file can repaint rows to hide or alter displayed lines, set the window title, or change colors. The security review of the command grammar change found this and recorded it as the first entry of `docs/backlog.md`; this change fixes it.

## What Changes

This change is outside the roadmap of `docs/architecture.md`: it is a defect fix in the screen-rendering capability of roadmap item 2, `editor-foundation`, found by a security review, and it delivers no roadmap item.

- Change the frame presenter to treat U+007F and U+0080 to U+009F as unprintable: each is shown as `<7f>`, `<80>` to `<9f>` (lowercase hexadecimal, four cells wide) with the highlight the existing caret escapes use, and the frame cursor over such a code point lands on the first cell of its marker. Code points below 32 keep their caret notation.
- Change the frame so that a cell never holds a control code point: text written to the frame that contains a code point below 32, U+007F, or U+0080 to U+009F stores U+FFFD in that cell instead. The presenter already turns the ones it meets in a buffer line into markers, so this guard covers any other text that reaches the frame (the status line path, a message, the command line) and makes the screen presenter unable to emit a raw C0 or C1 code point outside the escape sequences it writes itself.
- Add table-driven presenter tests with lines containing U+007F, U+0080, U+009B, and U+009D, asserting the markers, their widths, the cursor column, and that no cell holds a code point in those ranges, and a screen presenter assertion that the bytes written for such a frame contain no raw C1 code point outside the presenter's own escape sequences.
- Remove the C1 entry from `docs/backlog.md`, leaving the `make types` entry in place.

Out of scope: the complete East Asian width table, the `display` option and `listchars` of Vim, combining marks over an escaped code point, and any Neovim command, so `docs/compatibility.md` gains no row.

Assumptions recorded here rather than asked:

- The marker form follows Vim's `<xx>` for code points from U+0080 to U+009F and U+007F, lowercase hexadecimal, and keeps `^X` for code points below 32, because that is what a Vim user expects to see for the same bytes.
- The frame stores U+FFFD, the replacement character, rather than the marker, when a control code point reaches it outside the presenter's line painter, because the frame knows no tabstop and no line layout and the marker is a presenter concern; the design document records the decision.
- A marker that would be cut by the right edge of the text area is dropped as a whole, as a cut caret escape already is.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `screen-rendering`: adds the requirement that unprintable code points are rendered as escape markers and never reach a frame cell or the terminal raw.

## Impact

- `carat/domain/display_width.rb` gains the predicate that names the unprintable code points; `carat/domain/frame.rb` applies it in `put`; `carat/adapters/frame_presenter.rb` renders the markers in `char_width` and `shown_text`.
- `test/adapters_frame_presenter.rb` and `test/adapters_screen_presenter.rb` and their snapshots.
- `docs/backlog.md` loses its first entry. No dependency, port, binding, or configuration changes.
