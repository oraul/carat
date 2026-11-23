# Design

## Context

`StatusBar#paint` collects segments into parallel integer arrays, fits them to the width by priority, then paints each entry as a space, its text, and a space in one group. The file entry wrote the name in one call; the `lsp` entry wrote `StatusSlots#lsp_label` in the state's group; the percent entry and the progress bar's undone cells used `StatusLine`.

## Goals / Non-Goals

**Goals:**
- The folder, the server's dot, the undone cells, and the percent in the groups of `docs/design.md` section 8.

**Non-Goals:**
- The message row's indicators, `ModeMsg` and `MoreMsg`, and the terminal bytes of NO_COLOR and 16 colors (`ui-groups-c`); removing `lsp_label`.

## Decisions

- The folder is not a segment of its own: the file entry writes the name whole in `StatusLine` and recolors the first cells to `StatusLineDim` up to the width of the bytes before `Buffer#name_start`, the width coming from `DisplayWidth.text_width` of the whole and of the tail. No string is cut, so the bar stays allocation-free, and the file stays one entry of priority 90 that is never dropped. Alternative: a folder kind with its own priority, which would let a narrow bar drop the folder but change the order, widths, and tests of every segment.
- The dot is `Icons.glyph("modified", set)`, the glyph the design table gives to state after a name; no new icon name. The name is `StatusLineDim`, the dot takes `lsp_group(state)`, and the hint of a crash or untrusted directory, which the user needs to recover, stays after the dot in the same group. Indexing's percent is dropped from the slot because the progress segment shows it.
- `StatusSlots.hint(state)` returns the command a state names, so the bar and `label` share it; `label` and its record member remain for the gateway's tests.
- The percent entry takes `StatusLineDim` for its spaces and text; the undone cells of the bar are always `StatusLineDim`, plain or not, as only the group differs under NO_COLOR.
