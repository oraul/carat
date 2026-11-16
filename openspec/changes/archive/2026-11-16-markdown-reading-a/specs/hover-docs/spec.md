## ADDED Requirements

### Requirement: The documentation markers follow the icon set
The documentation float and its pinned split SHALL draw list bullets, quote bars, and thematic-break rules from the icon set: `•`, `│`, and `─` with `option.icons unicode` or `nerd`, and `* `, `| `, and `-` with `option.icons ascii`.

#### Scenario: Documentation markers under ascii
- **WHEN** `option.icons ascii` is set and documentation with a list, a quote, and a thematic break is laid out
- **THEN** the rows read `* ` for each bullet, `| ` for each quote level, and a rule of `-`, with no character above code point 127
