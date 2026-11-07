## ADDED Requirements

### Requirement: Diagnostics are drawn as signs
After a server publishes diagnostics for a file, each buffer of that file SHALL show, at the next idle tick, a sign on each row with a diagnostic: the `error`, `warning`, `info`, or `hint` icon of the icon set, the most severe when several share a row. The sign SHALL win over a plugin's sign on the row, move with the lines as the buffer is edited, and be replaced by the next publish.

#### Scenario: Signs on the published rows
- **WHEN** the server publishes an error on row 0 and a hint on row 1 of a two-line `a.rb` with the ascii icons
- **THEN** row 0 of the window starts with "X " and row 1 with "? " before the line numbers

#### Scenario: The most severe sign on a shared row
- **WHEN** a hint and a warning are published for the same row
- **THEN** the row shows the warning's icon

#### Scenario: Signs follow an edit
- **WHEN** a line is inserted above a row with a diagnostic
- **THEN** the sign and the row's message move down with the row

#### Scenario: An empty publish clears the signs
- **WHEN** the server publishes no diagnostics for a file that had some
- **THEN** its buffer shows no sign column

### Requirement: The bar counts the current buffer's diagnostics
At each idle tick the bar's diagnostics slot SHALL show the counts of errors, warnings, infos, and hints published for the current buffer's file, and SHALL take no cells when it has none.

#### Scenario: Counts after a publish
- **WHEN** the server publishes two errors and one warning for the current buffer
- **THEN** the bar shows the error count 2 and the warning count 1

#### Scenario: Another buffer has its own counts
- **WHEN** the current buffer becomes one with no diagnostics
- **THEN** the slot takes no cells

### Requirement: A diagnostic message is one bounded line
A diagnostic message SHALL be drawn with each line feed, carriage return, and tab turned into a space, every other control character removed, at most 500 bytes, and cut at the screen's width.

#### Scenario: A message of two lines
- **WHEN** the server publishes the message "expected end\nfound EOF" with an escape sequence after it
- **THEN** the message row reads "expected end found EOF" followed by the sequence without its escape character

### Requirement: A restart clears the drawn diagnostics
`:LspRestart`, and `:LspStart` after the server crashed or stopped, SHALL remove the signs and the counts of the diagnostics of the restarted file type until the new server publishes.

#### Scenario: Restart clears the signs
- **WHEN** a buffer shows a diagnostic sign and ":LspRestart" is run
- **THEN** the buffer shows no sign column and the slot no counts
