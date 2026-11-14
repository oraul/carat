# Proposal

## Why

The user reported (part b of the float report) that floats touch the screen edges and the bars, and only the palette is centered, one column off without a border (`carat/use_cases/discovery/follow_palette.rb:124`): its column is computed once at show with the bordered frame, so it neither follows `option.winborder none` nor a resize. Notification titles are drawn flush against the corner while float titles are centered with a blank on each side (`carat/adapters/frame_presenter.rb:508`). A plugin cannot ask for the frame, so the finder's boxes stand 2 columns apart under `winborder none`, and `docs/plugins.md:83` omits the padding and the box width (`carat/plugin_api.rb:194`). A plugin's float offset is never range-checked, so a value near the integer maximum wraps past the clamp in `FloatWindow#place` (security Low (3), `carat/domain/float_window.rb:81`). This is queue item `float-placement` (sprint 2, the user's now-request, part b), covering the backlog headings "The palette is one column off center without a border", "FloatWindow#place shadows its edge reader", "Notification titles are drawn flush, float titles centered", "The open_float row omits the padding and the box width", "Float offsets are not range-checked at the plugin boundary", "The frame presenter's comment and map bullet predate float-frame", and the four quality advisories at `carat/plugins/finder/plugin.rb:32`, `carat/domain/float_window.rb:80`, `README.md:58`, and `carat/domain/float_window.rb:46`. It is outside the roadmap of `docs/architecture.md` section 12: it finishes the delivered float-frame work.

## What Changes

- Every float keeps a margin of one cell from the screen's edges: `FloatWindow#place` cuts the box to the area less the margin and moves it inside it, so a box never covers the first or last column, the top row (the buffer tabs), or the row above the message row (the status bar), as long as the screen holds the box and its margin; on a screen too small for that the box uses the margin cells.
- The widest text a float shows is the screen less its margin and its frame (`FloatWindow.text_room(cols, style)`, the border argument every caller passed as true removed), so the palette, the documentation, signature, and definition floats, and the key hints never lay out a row the placement cuts.
- A float can be centered: `FloatWindow#centered`, set by the opener, makes `place` compute its column from the box's own width at every arrange, so it is centered at show and again after a resize, under any border style. The palette uses it instead of its fixed column.
- Notification titles are drawn as float titles are: centered between the corners with a blank on each side, in the severity's group.
- A new plugin request `float_frame(border)` answers a `FloatFrame` (the edge, padding, and margin cells and `box_width`), plugin API 2.6, a minor bump; the finder sizes its boxes from it, so the list and preview boxes share an edge under every border style. The `FloatOptions` comment and the `open_float` row of `docs/plugins.md` give the padding and the box width.
- `open_float` and `move_float` refuse a row or column offset outside -10000 to 10000 with "No offset N: -10000 to 10000" before it reaches placement.
- `FloatWindow#place` no longer shadows its `edge` reader; the frame presenter's comment and map bullet describe the floats, their padding, border, and titles.

Assumptions:

- "Every float keeps a margin" is read as one cell on each side of the area floats are placed in (the screen above the message row); notifications, which are not floats, keep their placement (top right, one column from the right edge, from the row under the buffer tabs).
- The `FloatOptions` choice: `FloatOptions` has required members, so a new member would be a major version (`docs/architecture.md` section 9.4); centering stays a core placement flag on `FloatWindow` and the frame is a separate host request, keeping 2.x. Plugins get no centering request, which no plugin needs yet.
- Centering is horizontal only: the palette keeps row 1, the key hints keep their place (their panel is `menu-hints`).
- The offset bound, 10000 cells each way, is far past any terminal and far from the integer limits.

Out of scope: the key hints panel and the palette's row columns (`menu-hints`), the completion popup's double padding (`menu-hints`), the notification placement, and any new anchor value.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `floating-windows`: floats keep a margin, a centered float is placed at show and on resize, and the frame rule counts the margin.
- `plugin-windows`: a plugin reads the float frame, and float offsets out of range are refused.
- `file-finder`: the finder's boxes share an edge under every border style.
- `messages`: a notification's severity is centered on its top border like a float title.

## Impact

- Code: `carat/domain/float_window.rb`, `carat/domain/float_spec.rb`, `carat/use_cases/discovery/follow_palette.rb`, `carat/use_cases/discovery/show_key_hints.rb`, `carat/use_cases/docs/show_hover.rb`, `carat/use_cases/docs/show_signature.rb`, `carat/use_cases/definitions/open_definition_float.rb`, `carat/adapters/frame_presenter.rb`, `carat/plugin_api.rb`, `carat/use_cases/plugins/plugin_link.rb`, `carat/use_cases/plugins/window_requests.rb`, `carat/plugins/finder/plugin.rb`.
- Tests: `test/domain_float_layer.rb`, `test/editor_floats.rb`, `test/editor_palette.rb`, `test/editor_finder.rb`, `test/adapters_hover.rb`, `test/adapters_signature.rb`, `test/adapters_definitions.rb`, `test/editor_key_hints.rb` (the key hints), `test/domain_plugin_manifest.rb`, and their snapshots.
- Docs: `docs/plugins.md` (2.6, `float_frame`, the `open_float` row), `docs/codebase-map.md` (areas 11, 13, 15), `docs/architecture.md`.
- README.md: changed, the `winborder` sentence gives the margin and the centered palette, and the finder sentence says the boxes share an edge under every border.
- docs/architecture.md: changed, section 9's request list names the float frame (2.6).
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
