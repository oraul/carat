## ADDED Requirements

### Requirement: The icon table holds the branch counts
The table SHALL hold, for each set, a glyph for the names `ahead` and `behind`: a Nerd Font arrow in the private use areas in the nerd set, `↑` and `↓` in the unicode set, and `+` and `-` in the ascii set.

#### Scenario: The ahead and behind glyphs per set
- **WHEN** "ahead" and "behind" are looked up in the unicode and the ascii sets
- **THEN** they are "↑" and "↓", then "+" and "-"
