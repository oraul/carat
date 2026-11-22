# Proposal

## Why

`FramePresenter` paints the windows, the headers, the winbars, the separators, the message row, the floats, and the notifications in one class of 1474 lines and 60 methods (the sprint-26 sweep's quality note 35). The design council's decision 4 puts this split before `window-surfaces`, the Facet wave that restyles the floats, so that wave edits a float painter of its own instead of the presenter. The status bar, the winbar, and the tab bar were already cut out as collaborators (`StatusBar`, `Winbar`, `TabBar`); the floats and the notifications follow them. Roadmap: outside the roadmap of `docs/architecture.md` section 12, a refactor the queue places before the Facet wave 3 items it serves.

## What Changes

- A new adapter `FloatPainter` (`carat/adapters/float_painter.rb`) paints the floats of the tab page and the notification boxes: it builds their box key (the float key, `STRIDE` integers a box), holds the border glyphs set per frame from `option.winborder` and the icon set, the plain flag for `NO_COLOR`, and the notifications, and paints every box row, or only the rows painted again under it. The methods move unchanged: `build_float_key`, `add_notice_boxes`, `paint_floats`, `paint_float_row`, `paint_mark`, `float_group`, `paint_border_row`, `paint_notices`, `paint_notice_row`, `notice_group`, `paint_edge`, `paint_title`, `mend_edges`, and the notice constants.
- A new adapter `LinePainter` (`carat/adapters/line_painter.rb`) holds the text cell painting a window row and a float row share: `paint_text` (with `paint_plain` and `hex_digit`) and `paint_tokens`, moved unchanged. The presenter's window path calls it explicitly, as the float painter does, so neither class reaches into the other.
- `FramePresenter` keeps the frame bookkeeping of the boxes (`forget_rows`, `compare_boxes`, `under_float?`, `covers?`, `clear_repainted`, the repainted rows) and reads the key from the float painter; it takes `float_painter:` in place of `notices:`, and its `plain=` passes the flag on to the float painter as it does to the status bar.
- `EditorAssembly` builds the float painter with the shared line cache and notifications.
- Tests: `test/adapters_float_painter.rb` paints a float and a notification through the float painter alone (the key, the rows, the plain box); `test/adapters_assembly.rb` checks the float painter holds the one cache and the one notifications. Every frame snapshot stays as it is.
- Docs: `docs/codebase-map.md` area 13 names the two files and moves the float and notice methods to the float painter's entry; `docs/architecture.md` section 8.2 names `FloatPainter`.

## Out of scope

- Any change of what is drawn: no snapshot, group, glyph, or geometry changes.
- The window path, the headers, the winbars, and the message row stay in `FramePresenter`; splitting them further is not this change.
- `IndentGuides` and `WhitespaceMarks` keep their place.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: no behavior changes, `skip_specs: true`, archived with `--skip-specs`.

## Impact

- `carat/adapters/frame_presenter.rb`, the new `carat/adapters/float_painter.rb` and `carat/adapters/line_painter.rb`, `carat/adapters/editor_assembly.rb`, the five test files that build a presenter, the new test and its snapshot, `test/runner/run_all.rb`, `docs/codebase-map.md`, `docs/architecture.md`.
- Performance: the moved methods allocate nothing new and run the same loops; `lh-float` time and allocations are held, the window path paying one call on a collaborator per painted row.
- README.md: unchanged, it describes what the floats and notifications show, not which class paints them.
- CLAUDE.md: unchanged, no process changes.
- Assumption: "the window path explicit" in the queue entry is read as the window path calling the shared text painting explicitly on its own collaborator, so the float painter needs nothing from the presenter.
