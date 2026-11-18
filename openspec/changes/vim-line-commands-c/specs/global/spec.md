## MODIFIED Requirements

### Requirement: The global reports as Vim does
When no line is marked the message SHALL be "Pattern not found: pat" for `:g` and "Pattern found in every line: pat" for `:g!` and `:v`, and nothing runs. The first command that fails SHALL stop the global and its message SHALL be shown; otherwise the lines every `:p` it ran showed SHALL be shown together, one per line, and else the last message a command gave.

#### Scenario: Nothing matches
- **WHEN** ":g/z/d" is run on the line "a"
- **THEN** the message is "Pattern not found: z" and the line is "a"

#### Scenario: Every line matches
- **WHEN** ":v/a/d" is run on the lines "a", "ab"
- **THEN** the message is "Pattern found in every line: a"

#### Scenario: A failing command stops it
- **WHEN** ":g/a/foo" is run on the lines "a", "a"
- **THEN** the message is "E492: Not an editor command: foo"

#### Scenario: The printed lines are shown together
- **WHEN** ":g/x/p" is run on the lines "x1", "a", "x2"
- **THEN** the message is "x1" and "x2" on two lines and the cursor is on row 3
