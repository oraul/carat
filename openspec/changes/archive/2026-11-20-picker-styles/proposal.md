# Proposal

## Why

A plugin cannot change what one of its floats shows: the only float requests are `open_float`, `move_float`, `float_frame`, and `close_float`, so the finder closes its list and preview floats and opens new ones on every key that changes the prompt, every highlight move, and every resize (`carat/plugins/finder/plugin.rb` `refresh`). Each key builds new windows and buffers, and the window ids a plugin holds change under it. This is the user's Sprint 23 feature order (queue item 1, feature lane, the finder and explorer council picks of 2026-11-20); it is outside the numbered roadmap of `docs/architecture.md` section 12, which closed, and extends the delivered plugin floats (API 2.3).

## What Changes

- A host request `set_float_lines(window, lines, title)` at API 2.11 replaces every line of one of the plugin's floats, 0 for the current window, and its title in place: the window id, box, z order, and focus stay, the float's cursor and scroll go back to the first line, and another plugin's float or an unknown id fails with "No float N". It is a `PluginApi::Host` method, a `PluginLink` override, and a `WindowRequests` method; `FloatOptions` gains no member.
- `PluginApi::MINOR` and `VERSION` become 11 and "2.11"; a manifest written against 2.0 to 2.10 still loads.
- The finder refills its list float and its preview float with `set_float_lines` while their box is unchanged, so typing and moving the highlight keep one list float; it closes and reopens a float only when its box changes (a resize), when the refill fails, and closes the preview when none is shown.
- Docs: `docs/plugins.md` (the request row, the version history, `api_version`) and the code map.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-host`: ADDED requirement "A plugin refills its float in place", which also states the host's version 2.11 and that a 2.10 manifest loads; the older requirement "The host refuses a newer major API version" is left as it is, its rule unchanged.
- `file-finder`: ADDED requirement "The finder keeps its floats across keys".

## Out of scope

- The brief's `style_float(window, selected, spans)` and admitting `PmenuSel` and `PmenuMatch` (`carat/domain/highlight.rb`) while other ids under 65 stay refused: split off by the plan as `picker-styles-b`, at the API minor after this one. This change edits neither `carat/domain/highlight.rb` nor `carat/adapters/frame_presenter.rb` nor `carat/use_cases/discovery/follow_palette.rb`.
- Resizing a float in place: a box change still closes and reopens it.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: the refill resets the float's cursor and scroll to the first line, as the reopen it replaces did, so a shorter list never leaves the cursor past the last line.
- Assumption: the plan's two backlog entries (`build/plan/picker-styles/backlog.md`) reach `docs/findings/picker-styles.md` through `plan-apply` in the package step, which appends that file, so this step does not append them a second time.

## Impact

- README.md: unchanged, it names the plugin API by its document (`docs/plugins.md`), not its version or its requests.
- docs/architecture.md: unchanged, section 9 names the request families and the version rule, not each request or the current minor.
- CLAUDE.md: unchanged, no process changes.
- docs/codebase-map.md: area 15 (`VERSION` 2.11, `set_float_lines`).
- docs/plugins.md: the request row, the version history, and the finder's floats.
- docs/compatibility.md and docs/actions.md: unchanged, no Neovim command or action changes.
- Performance: a key in the finder reloads two buffers in place instead of closing two floats and opening two new ones.
