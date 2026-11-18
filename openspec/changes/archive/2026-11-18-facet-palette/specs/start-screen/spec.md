## MODIFIED Requirements

### Requirement: The gem takes the theme's colors
The start screen's cells SHALL carry the theme's groups: `Operator`, `Function`, and `Keyword` for the facets, `Type` for the point, `Title` for the sparkle and the wordmark, `Special` for the hint keys, and `Comment` for the hint text.

#### Scenario: Colors
- **WHEN** the last frame shows on a 256-color terminal with the default theme
- **THEN** the wordmark's cells and the sparkle's carry `Title`
