## MODIFIED Requirements

### Requirement: Files open in splits and tab pages
`s` and `v` on a file SHALL open it in a new window split horizontally or vertically from the previously used file window, and `t` SHALL open it in a new tab page; on a directory they SHALL do nothing. A file name holding a space or a `|` SHALL open as it is named, since the tree opens files without building an ex command line.

#### Scenario: Horizontal split
- **WHEN** `s` is pressed on "b.rb" with the tree and one file window
- **THEN** there are three windows and the current one shows "b.rb"

#### Scenario: Vertical split
- **WHEN** `v` is pressed on "b.rb"
- **THEN** there are three windows side by side and the current one shows "b.rb"

#### Scenario: Tab page
- **WHEN** `t` is pressed on "b.rb"
- **THEN** there are two tab pages and the current one shows "b.rb"

#### Scenario: A name with a space in a split
- **WHEN** `s` is pressed on "my notes.md"
- **THEN** there are three windows and the current one shows "my notes.md" with its text

#### Scenario: A name with a bar in a tab page
- **WHEN** `t` is pressed on "a|b.md"
- **THEN** there are two tab pages and the current one shows "a|b.md" with its text
