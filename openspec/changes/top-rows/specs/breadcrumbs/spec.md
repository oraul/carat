## MODIFIED Requirements

### Requirement: The winbar shows the cursor's symbol path
When the language server of the current window's buffer offers `documentSymbolProvider` and its answer for that buffer is held, every winbar of a window showing that buffer SHALL follow the path with ` › ` (` > ` under `option.icons ascii`) and the name of each symbol whose range holds that window's cursor row, outermost first. A window on another buffer SHALL show its path only. Symbol names SHALL be shown without control characters and cut to 40 bytes, at most 500 symbols and 8 levels kept.

#### Scenario: Inside a method of a class
- **WHEN** two windows show "a.rb", the server answers that class `Foo` spans rows 1 to 5 and method `bar` rows 2 to 3, and the current window's cursor is on row 2
- **THEN** the current winbar shows " a.rb › Foo › bar"

#### Scenario: The ASCII separator
- **WHEN** the configuration holds `option.icons ascii` and the same answer is held with the cursor on row 2
- **THEN** the current winbar shows " a.rb > Foo > bar"

#### Scenario: Outside every symbol
- **WHEN** the cursor moves to a row no symbol holds
- **THEN** the winbar shows " a.rb" only, with no new request

#### Scenario: A flat symbol answer
- **WHEN** the server answers a list of symbols with locations instead of children
- **THEN** each symbol whose range holds the cursor row is shown in the answer's order

#### Scenario: A hostile answer is bounded
- **WHEN** the server answers a name holding control characters and longer than 40 bytes, or more than 500 symbols
- **THEN** the name shows without the control characters and cut to 40 bytes, and only the first 500 symbols are kept
