## ADDED Requirements

### Requirement: Every exit restores the terminal's cursor
However the editor ends, by ":q", ":wq", closing the last window, `SIGTERM`, `SIGINT`, or an error after it entered the screen, opening the file included, it SHALL restore the terminal's own cursor shape, show the cursor, and leave the alternate screen as the last bytes it writes.

#### Scenario: Quit by a command
- **WHEN** `carat FILE` runs in a pseudo-terminal, "i" is typed so the cursor is a bar, and ":wq" Enter ends it after Escape
- **THEN** its output ends with the reset of the cursor shape to the terminal's default, the cursor shown, and the alternate-screen disable sequence

#### Scenario: Quit by a signal
- **WHEN** a running editor receives SIGTERM, or SIGINT
- **THEN** it exits with status 0 and its output ends with the same three sequences
