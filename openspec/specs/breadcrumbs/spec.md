# breadcrumbs Specification

## Purpose
Breadcrumbs give each file window a winbar naming its file and, when the language server knows the document's symbols, the symbols the cursor is in, shown when two or more file windows share the screen, without ever delaying a key.

## Requirements

### Requirement: File windows show a winbar when two or more are shown
When the tab page shows two or more file windows (windows of the layout whose buffer is not a scratch buffer), each file window with two text rows or more SHALL give its first row to a winbar and show its text from the row below. Slot windows and plugin windows SHALL show no winbar and SHALL NOT be counted. With fewer than two file windows no winbar SHALL show and the windows SHALL keep every row.

#### Scenario: One window has no winbar
- **WHEN** the editor shows "a.txt" in one window
- **THEN** the window's first text row is the screen's first row

#### Scenario: Two windows have winbars
- **WHEN** "a.txt" is shown and `<C-w>v` is pressed
- **THEN** each window's first row shows " a.txt", the left (current) one in `TabLineSel` and the right one in `TabLine`, and each window's text starts on the second row

#### Scenario: Closing back to one window removes the winbar
- **WHEN** "a.txt" is split with `<C-w>s` and `<C-w>c` is pressed
- **THEN** no winbar shows and the window's text starts on the first row again

#### Scenario: The explorer is not a file window
- **WHEN** the explorer is open beside one file window
- **THEN** no winbar shows

#### Scenario: A split count counts text rows
- **WHEN** "a.txt" is shown in one window and "5<C-w>s" is typed
- **THEN** the new window has its winbar and 5 text rows below it

#### Scenario: A window of one text row keeps its row
- **WHEN** two file windows are shown and one has a single text row
- **THEN** that window shows its text row and no winbar

### Requirement: The winbar names the window's file
The winbar SHALL show one space and the window's file path (the scratch title or `[No Name]` otherwise), in `TabLineSel` for the current window and `TabLine` for the others, the rest of the row in `TabLineFill`, cut at the window's right edge.

#### Scenario: Windows on different files named
- **WHEN** "a.txt" is shown and `:vsplit b.txt` is typed
- **THEN** the left winbar shows " b.txt" in `TabLineSel` and the right one " a.txt" in `TabLine`

### Requirement: The breadcrumbs option
`option.breadcrumbs` SHALL take `auto` (the default: the winbar shows with two or more file windows), `always` (every file window with two rows or more shows one), or `never` (none shows). Another word SHALL be reported as `file:line: unknown breadcrumbs mode WORD` and keep the value before it.

#### Scenario: Always shows the winbar on one window
- **WHEN** the configuration holds `option.breadcrumbs always` and one file window is shown
- **THEN** the window's first row is its winbar

#### Scenario: Never hides the winbar on two windows
- **WHEN** the configuration holds `option.breadcrumbs never` and `<C-w>v` is pressed
- **THEN** no winbar shows

#### Scenario: An unknown mode is reported
- **WHEN** the configuration holds `option.breadcrumbs sometimes`
- **THEN** the problem `unknown breadcrumbs mode sometimes` is reported at that line and the winbar follows `auto`

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

### Requirement: Symbol requests never delay a key
The editor SHALL ask for the current window's buffer's symbols only at an idle tick, while a winbar shows, when the server offers `documentSymbolProvider`, once per text of the buffer, with at most one request in flight. A key SHALL be handled at once whether or not a request is in flight, the winbar showing the last answer held. A request unanswered for two seconds SHALL be cancelled, and an answer to any request but the one in flight dropped.

#### Scenario: No winbar, no request
- **WHEN** one window shows "a.rb" and its server offers document symbols
- **THEN** no `textDocument/documentSymbol` request is sent

#### Scenario: No capability, no request
- **WHEN** two windows show "a.rb" and its server does not offer document symbols
- **THEN** no `textDocument/documentSymbol` request is sent and the winbar shows the path

#### Scenario: A slow answer does not hold a key
- **WHEN** a request is in flight and `j` is pressed before its answer
- **THEN** the cursor moves at once and the winbar shows the path, and the symbol path after the answer arrives

#### Scenario: An edit is asked after the answer
- **WHEN** the text changes while a request is in flight
- **THEN** no second request is sent until the answer arrives, and one is sent at the next idle tick after it

#### Scenario: An overdue request is cancelled
- **WHEN** a request is unanswered for two seconds
- **THEN** `$/cancelRequest` is sent with its id, its late answer changes nothing, and no request is sent again until the text changes

### Requirement: The winbar adds no allocation per key while hidden
With no winbar shown, a key SHALL allocate no more objects than before winbars existed, and with winbars shown painting them SHALL allocate nothing.

#### Scenario: Allocations held
- **WHEN** `make bench` runs the `lh` and `j` scenarios
- **THEN** their allocations per key are the figures recorded on main, and `lh-winbar`, two file windows with winbars, allocates as many per key as the same windows with `option.breadcrumbs never`
