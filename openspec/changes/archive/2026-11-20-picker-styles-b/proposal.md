# Proposal

## Why

A plugin float cannot be styled: no host request marks a selected row or match spans on one, and `Highlight.token?` (`carat/domain/highlight.rb`) admits no group id under 65, so the finder marks its row with a `> ` prefix (`carat/plugins/finder/plugin.rb` `MARK`) while the editor's own palette draws its selected row in `PmenuSel` and its matched characters in `PmenuMatch` (`carat/use_cases/discovery/follow_palette.rb`). This is the second part of the user's Sprint 23 feature order (queue item 1, feature lane, the finder and explorer council picks of 2026-11-20), split from `picker-styles`, which added `set_float_lines` at API 2.11; it is outside the numbered roadmap of `docs/architecture.md` section 12, which closed, and extends the delivered plugin floats (API 2.3).

## What Changes

- A host request `style_float(window, selected, spans)` at API 2.12 styles one of the plugin's floats, 0 for the current window: `selected` is the row drawn in `PmenuSel`, the other rows then in `Pmenu` as a menu's are, or -1 for none; `spans` are flat quadruples of row, start column, length, and group id in code point columns, drawn as a tokenizer's tokens are, `PmenuMatch` drawn in `PmenuMatchSel` on the selected row. It replaces the float's previous style; an empty style clears it. It is a `PluginApi::Host` method, a `PluginLink` override, and a `WindowRequests` method; `FloatOptions` gains no member.
- A span's group may be a syntax, file-icon, or markup group, as a token's, or `PmenuSel` or `PmenuMatch`; every other id under 65 (or past the last group) is refused with "No float group N", and `syntax_group` resolves the two names from 2.12. A tokenizer's token in either group is still dropped (`token?` is unchanged).
- The request fails with "No float N" as `set_float_lines` does, "No row N" for a selected row or a span row outside the float's lines, "Spans are row, column, length, and group" for a list whose length is not a multiple of four, and "No span at column C length L" for a negative column or a length below one; a refused request changes nothing.
- `set_float_lines` drops the float's style, so a refill is drawn plain until the plugin styles it again.
- The frame presenter's float key gains the float's style count, so a restyle with unchanged lines repaints the float.
- `PluginApi::MINOR` and `VERSION` become 12 and "2.12"; a manifest written against 2.0 to 2.11 still loads.
- Docs: `docs/plugins.md` (the request row, `syntax_group`'s row, the version history, `api_version`) and the code map.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-host`: ADDED requirements "A plugin styles its float" (with the host's version 2.12 and a 2.11 manifest loading), "A float span admits only the popup menu's two groups beside the token groups", and "A bad float style is refused"; MODIFIED requirement "A plugin refills its float in place" loses its version sentence, which moves to the new requirement, and its 2.10 scenario names the host 2.12 and a refused 2.13.

## Out of scope

- The finder drawing its rows with `style_float` instead of the `> ` prefix: the queue's `finder-rows` item; this change edits no plugin under `carat/plugins/`.
- Admitting any group under 65 other than `PmenuSel` and `PmenuMatch`, and a style request for scratch windows.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: a span may run past its line's end and is cut there, as a token is, so only its row, a negative column, and a length below one are refused.
- Assumption: a selected row makes the float a menu, its other rows in `Pmenu`, as the completion popup and the palette are drawn; a plugin wanting `NormalFloat` rows passes -1 and marks spans only.

## Impact

- README.md: unchanged, it names the plugin API by its document (`docs/plugins.md`), not its version or its requests.
- docs/architecture.md: unchanged, section 9 names the request families and the version rule, not each request or the current minor.
- CLAUDE.md: unchanged, no process changes.
- docs/codebase-map.md: area 15 (`VERSION` 2.12, `style_float`), `Highlight` (`float_style?`, `float_style_id`), `FloatWindow` (`style_count`).
- docs/plugins.md: the request rows, the version history, and `api_version`.
- docs/compatibility.md and docs/actions.md: unchanged, no Neovim command or action changes.
- Performance: one more integer per float in the presenter's float key; nothing on the paths a benchmark drives.
