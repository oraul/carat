## ADDED Requirements

### Requirement: Folded has a row in every palette
Every palette SHALL give `Folded`, the group of a closed fold's row and the last UI group, the dim role as its foreground, no background of its own, and no attributes, so it shows at 24 bits, at 256 colors, and at 16 colors.

#### Scenario: Folded in the carat themes
- **WHEN** `Folded` is looked up in each shipped palette
- **THEN** its foreground is the palette's dim color at every depth, it has no background and no attributes, and its name is `Folded`
