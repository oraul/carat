# Design

## Context

The finder (`carat/plugins/finder/plugin.rb`) fills its list float with `list_lines`, each row `MARK` (`"> "`) or `SPACE` plus the path or grep row, through `show_float`, which refills a float in place with `set_float_lines` or opens one. The host already has `style_float(window, selected, spans)` (API 2.12): the selected row is drawn in `PmenuSel` (`FG` on `SELECTION`, no attribute, reverse at 16 colors) across the float, the others in `Pmenu`, and spans are drawn as tokens on the float layer, where a group without a background of its own takes `NormalFloat`'s. `set_float_lines` drops the style. Under `NO_COLOR` the float painter (`@plain`) skips every span, while the fills keep their groups.

## Goals / Non-Goals

**Goals:**
- The highlighted row of every picker is `▎`, the selection fill, and a bold label, at 24 bits, 256 colors, 16 colors, under `NO_COLOR`, and under `option.icons ascii`.
- The finder's allocations per key stay within `PICKER_BUDGETS` (`finder:600`).

**Non-Goals:**
- The rest of design section 8's Finder note (matched letters, the query row, one frame).
- The editor's own menus and the palette, which keep `PmenuSel` (`one-accent`).

## Decisions

- Two new UI groups, `PmenuMarkSel` (`BLUE` on `SELECTION`, bold) and `PmenuLabelSel` (`FG` on `SELECTION`, bold), both reverse and bold at 16 colors, inserted before `StatusLineDim`. A span needs its own background, since a span's group without one takes `NormalFloat`'s on the float layer and would cut the fill. Alternative rejected: making `PmenuSel` bold, which would change the completion menu, the command-line menu, and the palette, beyond the brief and into `one-accent`'s band. Alternative rejected: a syntax group for the mark, which would follow the syntax colors and carry no selection background.
- At 16 colors the mark is reverse like the fill, so the band stays unbroken and the mark cell reads as a sapphire block; without reverse the cell would fall back to the terminal's background inside a reversed band.
- `style_float` admits the two groups as it admits `PmenuSel` and `PmenuMatch` (`Highlight::FLOAT_GROUPS`); `syntax_group` resolves them through `float_style_id`, and `token?` still refuses them for a tokenizer. A plugin may now send groups a 2.14 host refuses, so the API is 2.15.
- Under `NO_COLOR` the float painter paints the spans whose group is a UI group (the four float groups) and skips token groups: `LinePainter#paint_tokens` takes a flag that skips a token group, false for the editor's syntax. `NO_COLOR` already keeps the fills' groups, so the bold label follows the same rule; no shipped plugin styled a float before, so no other surface changes.
- The finder resolves the two group ids once with `syntax_group` (cached in instance variables, 0 until resolved) and, after every `show_float` of a non-empty list, calls `style_float(list, selected - top, [0, 0, 1, mark, 0, 2, length, label])`, the label's length in code points of the row text after the mark. `top` comes from one helper shared with `list_lines`.
- `MARK` becomes `"▎ "`, two cells like `"> "`, so the columns of the rows, the preview, and the boxes stay; the grep preview, which takes the same mark, starts its matched line with `▎ `.

## Risks / Trade-offs

- Renumbering the syntax, file-icon, and markup ids by two: plugins get ids from `syntax_group` at run time and tests use the constants, as the `StatusLineDim` change did.
- One more host request per key (`style_float`) and one small spans array: a handful of allocations against the 600 budget, measured by `make bench-budget`.
- The preview's matched line has the `▎` without a fill or color; recorded in the findings file for a later item.
