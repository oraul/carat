## Why

Every sign is drawn in `SignColumn`, which every palette colors yellow, so an error sign, a warning sign, and git's added, changed, and deleted signs all look alike: the sign column says that a row has something but not what. The sign record keeps only the glyph, so the presenter cannot tell the kinds apart.

## What Changes

- Each sign is drawn in the highlight group of its kind, chosen from the icon name it was placed with: `error` in `DiagnosticError` (red), `warning` in `DiagnosticWarn` (yellow), `info` in `DiagnosticInfo`, `hint` in `DiagnosticHint`, `git_added` in `Added` (green), `git_changed` in `Changed` (cyan), `git_deleted` in `Removed` (red); a sign of any other icon stays in `SignColumn`. The language server's diagnostic signs take the group of their severity the same way.
- Three UI groups are added after the popup menu's, with Neovim's names `Added`, `Changed`, and `Removed`, colored green, cyan, and red in every palette; the syntax, file-icon, and markup groups move up by three ids (plugins name them, never number them).
- No plugin API change: `place_sign(buffer, row, icon)` keeps its signature and the host picks the group from the icon name.
- Roadmap: no new roadmap item; a defect fix of the sign column (section 12, the Facet wave 1 user request).
- Out of scope: the other sign kinds of the Facet order (review, AI, suggestion), a sign group a plugin chooses itself, and line-number or line highlights for signs.

## Capabilities

### New Capabilities

### Modified Capabilities
- `color-themes`: three UI groups `Added`, `Changed`, `Removed`; each sign is drawn in the group of its kind.

## Impact

- Domain: `Highlight` gains `ADDED`, `CHANGED`, `REMOVED` and `sign_group(icon)`; `Themes::GROUPS` colors them; `SignLayer` keeps a group beside each glyph; `Buffer#place_sign` takes the group and `Buffer#sign_group_at` answers it; `set_diagnostics` passes the severity's group.
- Use cases: `BufferRequests#place_sign` passes `Highlight.sign_group(icon)`.
- Adapters: `FramePresenter#paint_row` draws the glyph in the sign's group; `PaintedRows` repaints a row whose sign group changed.
- Tests: `test/adapters_frame_presenter.rb` (frame rows on carat-dark and carat-light), `test/domain_buffer.rb`, `test/domain_theme.rb`, `test/use_cases_plugins.rb`, and the callers of `Buffer#place_sign` in `test/domain_edits.rb`.
- Docs: README.md (the palette paragraph), `docs/compatibility.md` (the UI group count, the sign colors, and the git signs row), `docs/codebase-map.md` (the `Highlight`, `SignLayer`, and `Buffer` lines), `docs/architecture.md` (the `Highlight` group count), `docs/plugins.md` (`place_sign` draws the sign in its icon's group).
- README.md: changed, its palette paragraph says each sign takes its kind's color.
- docs/architecture.md: changed, its `Highlight` entry counts 63 UI groups.
- Assumptions: git's deleted sign is red, as Neovim's `Removed` is; the diagnostic info and hint signs take `DiagnosticInfo` (blue) and `DiagnosticHint` (cyan); the empty sign cells keep `SignColumn`.
