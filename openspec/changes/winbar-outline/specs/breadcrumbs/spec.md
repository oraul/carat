# Spec Delta

## MODIFIED Requirements

### Requirement: File windows show a winbar when two or more are shown
When the tab page shows two or more file windows (windows of the layout whose buffer is not a scratch buffer), each file window with two text rows or more SHALL give its first row to a winbar and show its text from the row below. Slot windows and plugin windows SHALL show no winbar and SHALL NOT be counted. With fewer than two file windows no winbar SHALL show and the windows SHALL keep every row. A split count SHALL count the new window's text rows, a winbar row added only when the new window shows a file and winbars show after the split; a split from a scratch window that keeps showing the scratch buffer SHALL get exactly the rows counted.

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

#### Scenario: A split count from a scratch window
- **WHEN** the configuration holds `option.breadcrumbs always`, the current window shows a scratch buffer, and "5<C-w>s" is typed
- **THEN** the new window shows the scratch buffer with no winbar and 5 text rows

#### Scenario: A split from a scratch window to a file has its row
- **WHEN** the configuration holds `option.breadcrumbs always`, the current window shows a scratch buffer, and `:split b.txt` is typed
- **THEN** the new window's first row is its winbar showing " b.txt" and its text starts on the row below

### Requirement: Symbol requests never delay a key
The editor SHALL ask for the current window's buffer's symbols only at an idle tick, while a winbar shows, when the server offers `documentSymbolProvider`, once per text of the buffer, with at most one request in flight. A key SHALL be handled at once whether or not a request is in flight, the winbar showing the last answer held. A request unanswered for two seconds SHALL be cancelled, and an answer to any request but the one in flight dropped. `:LspRestart` SHALL drop the symbols held and the text last asked, so the winbar shows the path until the restarted server answers, that server is asked at the first idle tick once it is ready, and no answer to a request sent before the restart SHALL reach the winbar.

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

#### Scenario: A restart keeps the new outline
- **WHEN** a request is in flight, `:LspRestart` is typed, the restarted server is ready, and it answers the request sent at the next idle tick before the old server's answer arrives
- **THEN** the winbar shows the path after the restart, the restarted server's symbols after its answer, and the old answer changes nothing
