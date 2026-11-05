## ADDED Requirements

### Requirement: Text on the cursor line stays readable
In every shipped palette, drawn with the theme's background, every group SHALL keep a contrast ratio of at least 3:1 between its foreground and its background when drawn on the cursor line, on the `CursorLine` background unless the group has a background of its own, at 24-bit colors and at the 256 colors written for them, as text on the selection is drawn. At 16 colors a group without a background of its own SHALL be underlined on the cursor line.

#### Scenario: Every palette passes on the cursor line
- **WHEN** the contrast of every group of `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured on the cursor line
- **THEN** no group is below 3:1

#### Scenario: Sixteen colors
- **WHEN** a Comment cell on the cursor line is written to a 16-color terminal
- **THEN** its sequence underlines it and keeps Comment's color
