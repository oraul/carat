# Design

## Context

A plugin float is a `Domain::FloatWindow` whose `FloatSpec#border` bool comes from `FloatOptions#border` (`WindowRequests#open_float`). `ArrangeView#place_floats` computes one `edged` flag from `option.winborder` and passes it to every float's `place`, which sets the float's `edge` to `spec.edge` (1 when bordered) or 0. `FramePresenter#render` keeps one glyph set, `@border = BorderStyle.glyphs(winborder, plain || icons ascii)`, which `paint_edge` draws for every float and notification. See proposal.md, Why.

## Goals / Non-Goals

Goals: a per-float named style requested after the float opens, its ASCII form, and no extra allocation per key. Non-goals: the separators, `float_frame`, the editor's own floats.

## Decisions

### A separate request, not a FloatOptions member

`set_float_border(window, style)` in the window family: `Host#set_float_border`, `PluginLink#set_float_border` (refusal check, then forward), `WindowRequests#set_float_border(name, id, style)`. A member on `FloatOptions` would break every plugin that builds it with keywords, a major version. The plugin opens its float and sets its style in the same call into the plugin, so no frame shows the float in between.

### The style is the float's border

The request sets `FloatWindow#border_style` to a copy of the name and gives the spec `border: true` (`FloatSpec#bordered`), so `double` on a float opened without a border draws one, as Neovim's `border` key does, and `none` removes the edge with the padding kept. `""` returns the float to `option.winborder`, still bordered. `FloatWindow#style_under(winborder)` answers the style a float draws: its own, or the option when it has none. `ArrangeView#place_floats` asks `BorderStyle.edged?(float.style_under(winborder))` per float instead of once; it allocates nothing. Alternative: keep the open bool and refuse a style on an unbordered float; rejected, it adds a refusal a plugin must work around with a reopen.

### Drawing

`paint_edge` takes the glyph set as an argument: notifications pass the frame's `@border`, `paint_border_row` passes `@border` for an unstyled float or `BorderStyle.glyphs(float.border_style, @ascii)`, a frozen constant, where `@ascii` is `@plain || icons ascii`, set beside `@border` in `render`. So a styled float follows `option.icons ascii` and `NO_COLOR` as the global border does.

### Repainting

Every accepted request raises `FloatWindow#style_count`, already in the presenter's float key, so a style change that keeps the box (`rounded` to `double`) repaints; a change of edge moves the box too. No stride change.

### Validation

`own_float_tab` (another plugin's float or an unknown id: "No float N"), then `BorderStyle.style?` or `""` ("No border style X: none, single, double, rounded, or solid"), before anything changes.

### Version

`MINOR` 13, `VERSION` "2.13"; `ManifestCheck.refusal` already accepts every older 2.x minor, so a 2.12 plugin loads and its bool keeps working unchanged.

## Risks / Trade-offs

- `float_frame` still answers under the global style: a plugin sizing a styled float uses edge 1 for every style but `none`, documented in `docs/plugins.md`.
