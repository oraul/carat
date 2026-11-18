## Why

The indent guides are painted in the palettes' text roles, FAINT and DIM, so every guide competes with the code it frames, and every guide, the cursor's block included, is the same dotted `┊`: the block holding the cursor stands out only by a color close to the comment color. The user accepted the design council's Facet plan, whose first item gives the guides their own quiet colors and the scope guide a solid glyph.

## What Changes

- The palettes gain two color roles, GUIDE and GUIDE_SCOPE, which color `IblIndent` and `IblScope`: carat-dark #30364b and #46506e, carat-light #d8dce8 and #a9b4d6, both index 8 at 16 colors; the other four palettes keep the colors their guides have today (their FAINT and DIM).
- In carat-dark and carat-light the guides recede behind the text: `IblIndent` is fainter than `IblScope`, which is fainter than `Comment`, on the background and on the cursor line, at 24-bit and at 256 colors, each guide still apart from the background; they leave the 3:1 decoration floor, which the other four palettes' guides keep.
- The cursor's block guide is drawn as a solid `│`, `|` with `option.icons ascii`; the other guides keep the guide character, `┊` as shipped.
- Roadmap: outside the numbered roadmap of `docs/architecture.md` section 12; a user request from the Facet plan (wave 1 item 1) refining the indent guides already delivered.
- Out of scope: an option to set the scope glyph (it is fixed, as the float border glyphs are per style); new guide colors for one_dark, one_light, dark_plus, and light_plus; any other Facet item.

## Capabilities

### New Capabilities

### Modified Capabilities
- `color-themes`: the indent guides get their own palette colors and, in Carat's two palettes, an ordering below Comment in place of the 3:1 floor.
- `indent-guides`: the cursor's block guide is a solid `│`.

## Impact

- Domain: `Themes` (roles GUIDE and GUIDE_SCOPE in every palette, the two guide groups mapped to them), `Options` (the scope guide's code point, `SCOPE_GUIDE_CHAR`).
- Adapters: `IndentGuides#paint` draws the scope guide's code; `configure` folds the ascii fallback into its stamp.
- Tests: `test/domain_theme.rb` (the guide ordering rows, the guides out of the 3:1 list only in Carat's palettes), `test/adapters_indent_guides.rb` (frame rows with `┊` and `│`, the scope glyph's ascii fallback), `test/domain_options_config.rb` (the scope code).
- Docs: `docs/compatibility.md` (UI groups and Indent guides), README.md option line.
- README.md: changed, its option line says the cursor's block guide is a solid `│`.
- docs/architecture.md: unchanged, it names neither the palette roles nor the guide glyphs.
- Assumptions: the four palettes the brief names no colors for keep their guides' current colors through the new roles, so they draw as before; the scope glyph is not configurable; each guide keeps at least 1.1:1 against the background so it never vanishes; the 256-color fallbacks are the nearest colors, which keep the ordering.
