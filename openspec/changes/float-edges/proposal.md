# Proposal

## Why

The user reported after #97 that floats lose their right columns: the palette's rows end short of its border after a filter shrinks it (`carat/use_cases/discovery/follow_palette.rb:114`, `:124`), the finder's two boxes stand 1 column apart, more under `winborder none` (`carat/plugins/finder/plugin.rb:268`, `carat/plugin_api.rb:197`), and hover, signature, and peek lose 2 columns of every row on screens under 84 columns (`carat/use_cases/docs/show_hover.rb:59`, `carat/use_cases/docs/show_signature.rb:53`, `carat/use_cases/definitions/open_definition_float.rb:40`). Each of these sizes its text as the screen less 2, the border alone, while `FloatWindow#place` keeps a column of padding on each side too, so the text area is cut by 2 more columns than the rows were laid out for; the finder's sizes are literals that assume a bordered box. This is queue item `float-edges`, sprint 2 item 1 (part a of the user's report), covering the backlog headings "Floats cap their width at the border only and lose two columns", "The palette width ignores the float padding", and "The finder's box sizes are magic numbers that assume a bordered float". It is outside the roadmap of `docs/architecture.md` section 12: it corrects the delivered float-frame work.

## What Changes

- One frame-width rule in `Domain::FloatWindow`: a float's frame is the padding on each side plus, when it is bordered and `option.winborder` draws an edge, the border on each side; the widest text a float can show is the screen less that frame. `place` cuts a box by the same rule.
- The palette, the documentation float, the signature float, the definition peek and pick list, and the key hints size their text by that rule, so no row they lay out is cut by the screen: at 80 columns a hover row is wrapped at 76 columns and shows its last word; under `winborder none` they use the two edge columns.
- The finder sizes its boxes from named constants, a one-column margin and the documented box frame of `FloatOptions` (width + 4), instead of literals: with a drawn border the list box and the preview box share an edge, the list starting one column from the left and the preview ending one column from the right; under `winborder none` each box loses its edge columns and they stand 2 columns apart.

Assumptions:

- "Share an edge" is read as adjacent boxes, the preview's left border in the column after the list's right border, so no glyph overwrites another; the plugin cannot read `option.winborder`, so under `none` the boxes keep a gap, the reading "an edge or a gap under both borders" allows. Making the frame readable through the plugin API is the next item, `float-placement`.
- At 120 by 36 the harness already drew every palette row with its right border at the box edge before this change, so the frame test pins that at 120 by 36 and shows the cut rows at a narrower screen (60 by 24), where the old width was 2 columns too wide; the "about 8 columns" of the report could not be reproduced in the frame.
- The palette's column keeps its formula, which assumes a drawn edge; its centering without a border is `float-placement`'s.

Out of scope: placement at show and on resize, margins around floats, notice titles, the frame through the plugin API, offset range checks (all `float-placement`), and the completion documentation float beside the popup, which has a fixed width of 60 and is placed by the popup.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `floating-windows`: the floats the editor opens size their text to the screen less their frame.
- `file-finder`: the list and preview boxes share an edge under a drawn border and keep a gap without one.

## Impact

- `carat/domain/float_window.rb` (`frame_width`, `text_room`, `place`), `carat/use_cases/discovery/follow_palette.rb`, `carat/use_cases/discovery/show_key_hints.rb`, `carat/use_cases/docs/show_hover.rb`, `carat/use_cases/docs/show_signature.rb`, `carat/use_cases/definitions/open_definition_float.rb`, `carat/plugins/finder/plugin.rb`.
- Tests: `test/editor_palette.rb` (the frame while a filter shrinks, at 120 by 36 and 60 by 24, under both borders), `test/adapters_hover.rb` (an 80-column row), `test/adapters_signature.rb` and `test/adapters_definitions.rb` (a narrow screen), `test/editor_finder.rb` (the box edges under both borders), `test/domain_float_layer.rb` (the rule and `place`).
- README.md: changed, the `winborder` sentence says a float's text fits beside its padding and border.
- docs/architecture.md: unchanged, it names the float use cases but not the frame arithmetic, which the archived float-frame design and this change's design hold.
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
