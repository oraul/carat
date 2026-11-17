## ADDED Requirements

### Requirement: The icon table holds the git line signs
The table SHALL hold, for each set, a glyph for the names `git_added`, `git_changed`, and `git_deleted`, each distinct from the others in its set: a Nerd Font diff glyph in the private use areas in the nerd set, `┃`, `┇`, and `▁` in the unicode set, and `+`, `~`, and `_` in the ascii set.

#### Scenario: The git sign glyphs per set
- **WHEN** "git_added", "git_changed", and "git_deleted" are looked up in the unicode and the ascii sets
- **THEN** they are "┃", "┇", and "▁", then "+", "~", and "_"
