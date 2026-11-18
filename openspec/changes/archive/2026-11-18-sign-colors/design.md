## Context

`Buffer#place_sign(owner, priority, row, glyph)` stores glyphs in one `SignLayer` per owner, and `FramePresenter#paint_row` fills the two sign cells and puts the glyph in `Highlight::SIGN_COLUMN`, which `Themes::GROUPS` colors `YELLOW`. The icon name is resolved to its glyph in `BufferRequests#place_sign` and dropped; diagnostic signs come from `Buffer#set_diagnostics`, which picks `glyphs[severity - 1]`. `PaintedRows` skips a row whose glyph is unchanged.

## Goals / Non-Goals

**Goals:**
- An error sign red, a warning yellow, git added green and changed cyan, on carat-dark and carat-light, as Neovim's `DiagnosticSign*` (linked to `Diagnostic*`) and gitsigns' `GitSigns*` (linked to `Added`, `Changed`, `Removed`) draw them.
- No change to the plugin API.

**Non-Goals:**
- Sign kinds beyond the icon table's (review, AI, suggestion) and plugin-chosen groups.

## Decisions

- The group is chosen by the icon name in the domain, `Highlight.sign_group(icon)`, so the host passes it and a plugin never names a group. Alternative: a group argument on `place_sign`; rejected by the brief (no API change) and because a plugin could then paint a sign in any UI group.
- Diagnostic signs reuse `DiagnosticError` through `DiagnosticHint`, as Neovim's `DiagnosticSign*` link to them; the severity's group is `DIAGNOSTIC_ERROR + severity - 1`, the same index `set_diagnostics` uses for the glyph.
- Git signs get three new UI groups with Neovim's names `Added`, `Changed`, `Removed` (foreground green, cyan, red; background the terminal's own like `SignColumn`). Alternative: reuse `Question` (green) and `DiagnosticHint` (cyan); rejected because a theme change to one would recolor the other. They go last among the UI groups, so the syntax, file-icon, and markup ids move up by three; plugins reach those by name (`syntax_group`), so no plugin sees the shift.
- `SignLayer` keeps a `groups` array beside `glyphs`, one entry per distinct glyph and group pair, so the marks stay one integer per line and shift with the lines as before. `Buffer#sign_group_at(row)` answers the shown sign's group, `SIGN_COLUMN` for none.
- `paint_row` still fills the two cells with `SignColumn` and puts the glyph in the sign's group; `PaintedRows` compares the sign group too, so a row whose glyph stays but whose group changes is repainted.

## Risks / Trade-offs

- [Shifted ids change a snapshot that prints group numbers] → `make test` shows it; snapshots are rewritten only by `make snapshots` with the diff read.
- [A new group fails a palette's contrast rule] → the three use the palettes' green, cyan, and red text colors, already held to 4.5:1 by `Question`, `DiagnosticHint`, and `DiagnosticError`; `domain_theme` checks every group.
