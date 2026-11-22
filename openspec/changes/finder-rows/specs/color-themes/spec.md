## ADDED Requirements

### Requirement: The selected row's mark and label groups have a row in every palette
Every palette SHALL give `PmenuMarkSel` the sapphire role as its foreground and `PmenuLabelSel` the text role (`FG`), both on the `SELECTION` background of `PmenuSel` and bold; at 16 colors both SHALL be reverse and bold, as `PmenuSel` is reverse there. Both SHALL sit before `StatusLineDim`, which stays the last UI group.

#### Scenario: The mark and label groups in every palette
- **WHEN** `PmenuMarkSel` and `PmenuLabelSel` are looked up in each shipped palette
- **THEN** the mark's foreground is the palette's sapphire and the label's its text color, both backgrounds are `PmenuSel`'s, both are bold at 24 bits and reverse and bold at 16 colors, and their names are `PmenuMarkSel` and `PmenuLabelSel`
