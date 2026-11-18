## Context

`Themes::GROUPS` maps `IblIndent` to FAINT and `IblScope` to DIM, the roles of faint and secondary text, and `IndentGuides#paint` draws every guide with the one code point `Options#guide_code` gives. The design council's Facet plan, accepted by the user, gives the guides colors of their own, well below the text, and draws the cursor's block as a solid line. The `domain_theme` contrast tables hold every decoration, the guides included, to 3:1, which the chosen colors are not meant to meet.

## Goals / Non-Goals

**Goals:**
- Two palette roles, GUIDE and GUIDE_SCOPE, with the brief's colors in carat-dark and carat-light, index 8 at 16 colors.
- An ordering IblIndent < IblScope < Comment in Carat's two palettes, on the background and the cursor line, at 24-bit and 256 colors.
- The scope guide drawn as `│`, `|` with the ascii icon set.

**Non-Goals:**
- New guide colors for the four other palettes; an option for the scope glyph.

## Decisions

- Roles over reuse: the guides get GUIDE and GUIDE_SCOPE in every palette, so a palette can tune them without touching its text roles. The four palettes the brief names no colors for get their current FAINT and DIM values, so they draw exactly as before and keep the 3:1 floor.
- The rule in Carat's palettes: the guides leave the 3:1 decoration list there and gain a rule that orders them below Comment, with a floor of 1.1:1 so neither guide vanishes on the background or the cursor line. The floor is the smallest contrast the chosen colors keep at 256 colors on carat-light's cursor line (about 1.17:1), rounded down.
- 256 colors: the nearest indexes (237 and 240 on carat-dark, 253 and 146 on carat-light) keep the ordering, so no explicit index is given; 16 colors keep index 8 for both, the scope guide told apart there by its glyph.
- The scope glyph is fixed, `Options::SCOPE_GUIDE_CHAR` `│`, and `Options#scope_guide_code` gives it or the ascii fallback `|`; a configurable glyph would add an option the brief does not ask for. `IndentGuides#configure` folds whether the fallback is in effect into its stamp, so switching icon sets repaints the scope column.

## Risks / Trade-offs

- [Guides below 3:1 in Carat's palettes] -> they are decorations meant to recede; the ordering rule and the 1.1:1 floor keep them visible and below the text.
- [At 16 colors both guides share index 8] -> the solid scope glyph distinguishes the block.
