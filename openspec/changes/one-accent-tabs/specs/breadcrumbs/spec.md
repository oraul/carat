## MODIFIED Requirements

### Requirement: The winbar names the window's file
The winbar SHALL show one space and the window's file path (the scratch title or `[No Name]` otherwise); the leading space, the path, the separators, and the outer names SHALL be in `TabLine`, the quiet dim, for every window, except the last name of the current window's winbar, its innermost symbol when symbols are shown or else its path, which SHALL be bold in `TabLineName`, with no accent fill. The rest of the row SHALL be in `TabLineFill`, cut at the window's right edge.

#### Scenario: Windows on different files named
- **WHEN** "a.txt" is shown and `:vsplit b.txt` is typed
- **THEN** the left winbar shows " b.txt" with the path in `TabLineName` and the right one " a.txt" in `TabLine`

#### Scenario: Only the innermost symbol is in the accent
- **WHEN** the current window's winbar reads " a.rb > Foo > bar"
- **THEN** only "bar" is in `TabLineName` and the rest of the row's text is in `TabLine`
