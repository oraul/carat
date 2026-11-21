# Proposal

## Why

A plugin float's border is one bool (`FloatOptions#border`, `carat/plugin_api.rb`) drawn in the user's global `option.winborder`, so a plugin cannot ask for one of Neovim's named border styles for its own float, as `nvim_open_win`'s `border` key lets a Neovim plugin. This is item 1 of the Sprint 25 feature queue (`docs/queue-feature.md`, `border-vocabulary`, the user's Facet wave 3, carried from Sprint 24); it is outside the numbered roadmap of `docs/architecture.md` section 12, which closed, and extends the delivered plugin floats (API 2.3). `FloatOptions` has required members, so a new member would be a major version (`docs/architecture.md` section 9.4): the style is a separate request at API 2.13 and a 2.12 plugin's bool is still honored.

## What Changes

- A host request `set_float_border(window, style)` at API 2.13 gives one of the plugin's floats, 0 for the current window, a border style of its own: `none`, `single`, `double`, `rounded`, or `solid`, Neovim's names, which `Domain::BorderStyle` already draws, or `""` for the user's `option.winborder`. The float is then bordered whatever its `FloatOptions#border` was, `none` drawing no edge and no title with the padding kept. It is a `PluginApi::Host` method, a `PluginLink` override, and a `WindowRequests` method; `FloatOptions` gains no member.
- The style's ASCII form (`+ - |`) is drawn under `option.icons ascii` and under `NO_COLOR`, as the global border's is; the border stays in `FloatBorder` and the title in `FloatTitle`.
- The request fails with "No float N" for another plugin's float or an unknown id, and with "No border style X: none, single, double, rounded, or solid" for any other name; a refused request changes nothing.
- A styled float is placed with its own style's edge, and the presenter's float key moves with a restyle (the float's `style_count`), so a style change with the same box repaints.
- `PluginApi::MINOR` and `VERSION` become 13 and "2.13"; a manifest written against 2.0 to 2.12 still loads, its floats bordered by the bool in `option.winborder` as before.
- Docs: `docs/plugins.md` (the request row, the version history, `api_version`) and the code map.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-host`: ADDED requirements "A plugin chooses its float's border style" (with the host's version 2.13 and a 2.12 manifest loading with its bool honored) and "A bad border style request is refused"; MODIFIED requirements "A plugin refills its float in place" (its 2.10 scenario names the host 2.13 and a refused 2.14) and "A plugin styles its float" (its version sentence moves to the new requirement, its 2.11 scenario names the host 2.13).

## Out of scope

- The split separators `SEPARATOR` and `ROW_SEPARATOR` in `carat/adapters/frame_presenter.rb`: queued as `separator-styles`.
- `float_frame`'s answer stays under the global `option.winborder`; a styled float's edge is 1 cell for every style but `none`, as `docs/plugins.md` says.
- The editor's own floats (palette, hover, signature, definition, key hints) and the notification boxes keep the global style; no plugin under `carat/plugins/` is edited.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: a float switched to a listed scratch buffer may still be restyled, since the border belongs to the window, not its buffer (`own_float_tab`, as `move_float` and `close_float`).
- Assumption: `set_float_lines` keeps the border style; it drops only `style_float`'s row and spans.

## Impact

- README.md: unchanged, it names the plugin API by its document (`docs/plugins.md`), not its version or its requests.
- docs/architecture.md: unchanged, section 9 names the request families and the version rule, not each request or the current minor.
- CLAUDE.md: unchanged, no process changes.
- docs/codebase-map.md: area 15 (`VERSION` 2.13, `set_float_border`), `FloatWindow` (`border_style`, `style_under`), `FloatSpec` (`bordered`), `FramePresenter` (a float's own glyphs).
- docs/plugins.md: the request row, the version history, and `api_version`.
- docs/compatibility.md and docs/actions.md: unchanged, no Neovim command or action changes.
- Performance: the per-float edge and glyph choice is a string comparison and a frozen constant, no allocation on the paths `lh-float` drives.
