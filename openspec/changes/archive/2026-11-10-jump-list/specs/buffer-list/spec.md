## ADDED Requirements

### Requirement: Moving to the first and the last buffer
`:bf`, `:bfirst`, `:br`, and `:brewind` SHALL show the first listed file buffer in the current window, and `:bl` and `:blast` the last one, with the refusals of the buffer switch (E37 without the bang over a modified buffer, E85 with no listed file buffer); showing the buffer already shown SHALL change nothing.

#### Scenario: First and last
- **WHEN** "a.txt", "b.txt", and "c.txt" are listed in that order, "b.txt" is current, and ":bfirst" is run
- **THEN** the window shows "a.txt", and ":blast" then shows "c.txt"

#### Scenario: Rewind is first
- **WHEN** "a.txt" and "b.txt" are listed and "b.txt" is current and ":br" is run
- **THEN** the window shows "a.txt"

#### Scenario: First refused on a modified buffer
- **WHEN** "x" is pressed on "b.txt" with "a.txt" listed first and ":bfirst" is run
- **THEN** the message is "E37: No write since last change (add ! to override)" and the window keeps "b.txt"
