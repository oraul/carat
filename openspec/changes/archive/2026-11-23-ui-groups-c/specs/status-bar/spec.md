## ADDED Requirements

### Requirement: The bar's groups differ in the bytes the terminal receives
The bar's file name SHALL be written in the sequence of `StatusLine` and its file type in the sequence of `StatusLineDim`, which differ in every terminal: at 16 colors (`TERM=xterm-color`) with basic colors only, at 256 colors (`TERM=xterm`) with 256-color indexes, and under `NO_COLOR`, which keeps the groups, so the name is bold and the type is not at each.

#### Scenario: The bar's bytes at 16 colors, 256 colors, and under NO_COLOR
- **WHEN** the editor runs in a pseudo-terminal at `TERM=xterm-color`, at `TERM=xterm`, and at `TERM=xterm` with `NO_COLOR` set, each with an empty `COLORTERM`, and draws the bar of a Ruby file
- **THEN** the sequence written before the file name differs from the one written before the file type each time, the name's is bold and the type's is not, at 16 colors both hold basic colors only, and at `TERM=xterm` both hold 256-color indexes
