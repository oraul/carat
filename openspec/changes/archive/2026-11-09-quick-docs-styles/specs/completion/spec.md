## ADDED Requirements

### Requirement: The documentation beside the popup is styled
The documentation float beside the completion popup SHALL draw its headings, emphasis, code spans, link text, and fenced code in the markup groups the hover documentation uses, fenced code of a tokenized language through the syntax highlighter, and none of them when `NO_COLOR` is set.

#### Scenario: A strong word in the documentation
- **WHEN** the selected item's documentation is "Use **map**." and the documentation float shows
- **THEN** "map" is drawn in `@markup.strong` and "Use" in NormalFloat
