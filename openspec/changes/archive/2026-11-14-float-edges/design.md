# Design

## Context

`FloatWindow#place` (float-frame) gives every box a column of padding on each side, inside the border, and cuts the text width to `cols - 2 * (edge + PAD)`. The core floats were sized before the padding existed: the palette (`follow_palette.rb:114`), the documentation float (`show_hover.rb:59`), the signature (`show_signature.rb:53`), and the definition float (`open_definition_float.rb:40`) cap their text at `screen_cols - 2`, so on a screen narrower than the cap plus 4 they lay rows out 2 columns wider than `place` leaves, and the last 2 columns of every row are cut. The key hints already subtract the padding (`show_key_hints.rb:132`) with a literal 2 for the border. The finder computes its boxes with the literals 6, 5, and 11 (`finder/plugin.rb:265` to `:280`), which assume a bordered box, and leaves a column between the boxes.

## Goals / Non-Goals

Goals: one rule for the columns a frame takes, used by `place` and by every core float that sizes its text to the screen; the finder's sizes named from the documented `FloatOptions` box; tests that read the frame.

Non-goals: placement, margins, and centering at show and on resize, the frame through the plugin API, and offset checks, all `float-placement`.

## Decisions

### The rule lives on FloatWindow

`FloatWindow.frame_width(edge)` is `2 * (edge + PAD)`, the columns beside the text, and `FloatWindow.text_room(cols, border, style)` is `cols - frame_width(edge)` with the edge 1 when `border` is true and `BorderStyle.edged?(style)`. `place` cuts the width with `frame_width(edge)` and moves the box in by the text plus `frame_width(edge)`, the arithmetic it had. The rule takes the style rather than an edge so each caller passes `state.options.winborder`, the same input `ArrangeView#place_floats` gives `place`. Alternative: a helper in each use case or a shared concern; rejected, since the frame is a fact of the float record and `place` needs it too.

### Callers keep their caps

The palette keeps its cap of 90, hover and the definition float their cap of 80, the signature its label width; only the screen bound changes to `text_room`. The palette's column is written with `frame_width(1)`, the value it had, since its centering without an edge belongs to `float-placement`.

### The finder names its numbers

A plugin requires only `carat/plugin_api.rb` and cannot read `option.winborder`, so the finder lays its boxes out for the bordered box `FloatOptions` documents, `width + 4`, named `FRAME`, with `MARGIN = 1` from each screen edge: the list's text is `cols - 2 * MARGIN - FRAME` alone, or `(cols - 2 * MARGIN - 2 * FRAME) / 2` beside the preview; the preview starts at `MARGIN + width + FRAME`, the column after the list box, and takes the rest less the right margin. The boxes share an edge (adjacent borders) under a drawn border; under `none` each box is 2 columns narrower and they stand 2 columns apart. Overlapping the borders by one column was rejected: the preview, drawn later, would put its corner over the list's.

## Risks / Trade-offs

- Under `winborder none` the finder's right margin is 3 columns, since the preview's box shrinks from its fixed corner; `float-placement`, which makes the frame readable through the API, can close it.
- At 120 by 36 the palette was already drawn whole in the frame; the test covers the narrower screen where the old width was cut, and pins the wide one.

## Migration Plan

None: no option, binding, or API changes.
