# Proposal

## Why

`docs/design.md` decides that a query lives inside the float, on its first row, never on the command line. Today the finder's prompt is `> ` on the command-line row with a counted title (`Files 2/3`), and the palette's is `>` there with the bare title `Commands`, so the two modal floats frame their prompt and title differently. This is the user's request, wave 4 of the Facet queue.

## What Changes

- Show the typed text of the command palette and of every finder picker (files, grep, buffers, recent) on the first text row of their float: the prompt `> ` (one constant, `Domain::Palette::PROMPT`, the finder's own `PROMPT` the same text) then the text. The list follows on the rows after it, the highlight on its row of the list.
- Put the cursor, a bar, in that row at the command line's cursor, and leave the command-line row blank, while the prompt's float is shown (`FramePresenter#prompt_float`); with no float (a screen too small for a query row and a list row) the prompt stays on the command-line row as before.
- Title the palette's float `Commands N/M` (matches over entries), the finder's `Files N/M` form; the grep picker keeps its own two-count title.
- Add the plugin API request `float_prompt(window)` (API 2.16, `PluginUi#prompt_float`): a plugin attaches its open prompt to one of its floats; the plugin writes the row, the host places the cursor. Bump the API to 2.16 and update the tests and spec scenarios that name the version.

Assumptions: "pick lists" are the finder's pickers, the only list floats with a query; the definition pick list has none and is unchanged. The plugin writes the query row itself rather than the host drawing it, since the plugin already refills its float after every change of text. The query is cut at the float's width, not scrolled. The grep picker's title (`Grep F of M files, L of N lines`) carries two counts and cannot take the `N/M` form, so it stays. The dim count and the left-aligned title belong to `float-polish`.

## Capabilities

### New Capabilities

### Modified Capabilities
- `command-palette`: the query row in the float, the titled counts.
- `file-finder`: the query row in every picker's list float.
- `plugin-host`: `float_prompt`, and the API version the scenarios name.

## Impact

- Code: `carat/adapters/frame_presenter.rb`, `carat/use_cases/discovery/follow_palette.rb`, `carat/plugins/finder/plugin.rb`, `carat/plugin_api.rb`, `carat/use_cases/plugins/plugin_link.rb`, `ui_requests.rb`, `window_requests.rb`, `carat/domain/plugin_ui.rb`, `carat/domain/palette.rb`.
- Tests: `test/editor_palette.rb`, `test/editor_finder.rb`, `test/editor_finder_grep.rb`, `test/use_cases_plugin_files.rb`, the version lines of `test/use_cases_plugins.rb`, `test/domain_plugin_manifest.rb`, `test/editor_floats.rb`, `test/editor_cmdline_edit.rb`, `test/editor_cmdline_complete.rb`, and the snapshots.
- Docs: `docs/plugins.md`, `docs/codebase-map.md`, `docs/compatibility.md`, `docs/actions.md`, `docs/design.md`, README.md.
- README.md: updated
- docs/architecture.md: unchanged, it is at its size budget and its request list names families of requests, none of which changed
