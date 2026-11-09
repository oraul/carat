## ADDED Requirements

### Requirement: Documentation markup is drawn in its own groups
The documentation float SHALL draw a heading's text in `@markup.heading`, strong text in `@markup.strong`, emphasized text in `@markup.italic`, a code span's text in `@markup.raw`, a link's or an image's text in `@markup.link.label`, and the rows of fenced code in `@markup.raw.block`, each over the float's background. While no documentation float shows, a key SHALL allocate nothing more for the styles.

#### Scenario: Markup in its groups
- **WHEN** the answer is "# Title\n\nUse **map**, *each*, `x`, or [docs](#d)." and the float shows
- **THEN** "Title" is drawn in `@markup.heading`, "map" in `@markup.strong`, "each" in `@markup.italic`, "x" in `@markup.raw`, and "docs" in `@markup.link.label`, and "Use" in NormalFloat

### Requirement: Fenced code of a known language is highlighted
When a fence names a language that an enabled plugin tokenizes and syntax is on, the code's tokens SHALL be drawn in their syntax groups over `@markup.raw.block`, as a buffer of that filetype is highlighted.

#### Scenario: Fenced Ruby through the highlighter
- **WHEN** the answer holds a fenced block opened by "```ruby" with the line "# note" and the float shows
- **THEN** the comment is drawn in Comment over the float's background

#### Scenario: Fenced code of an unknown language
- **WHEN** the answer holds a fenced block opened by "```text" with the line "plain words"
- **THEN** the code is drawn in `@markup.raw.block`

### Requirement: The pinned split keeps the styles and NO_COLOR drops them
The pinned split SHALL draw its rows with the same groups over the window's background. When `NO_COLOR` is set, no markup or token group SHALL be drawn in the float or the pinned split.

#### Scenario: The pinned split keeps the styles
- **WHEN** the float shows a heading and the pin key is typed
- **THEN** the split draws the heading's text in `@markup.heading`

#### Scenario: NO_COLOR draws the documentation plain
- **WHEN** `NO_COLOR` is set and the float shows a heading
- **THEN** the heading's text is drawn in NormalFloat
