## ADDED Requirements

### Requirement: The selected row's mark and label groups have a row in every palette
Every palette SHALL give `PmenuMarkSel` the `MARK` role (its blue, lighter in `dark_plus`) as its foreground and `PmenuLabelSel` the text role (`FG`), both on the `SELECTION` background of `PmenuSel` and bold; at 16 colors both SHALL be reverse and bold, as `PmenuSel` is reverse there. The bar SHALL read at 3:1 on the selection, as a decoration.

#### Scenario: The mark and label groups in every palette
- **WHEN** `PmenuMarkSel` and `PmenuLabelSel` are looked up in each shipped palette
- **THEN** the mark's foreground is the palette's `MARK` (the blue of the carat themes) reading at 3:1 or more on the selection and the label's its text color, both backgrounds are `PmenuSel`'s, both are bold at 24 bits and reverse and bold at 16 colors, and their names are `PmenuMarkSel` and `PmenuLabelSel`
