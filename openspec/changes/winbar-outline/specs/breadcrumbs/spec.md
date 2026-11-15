# Spec Delta

## ADDED Requirements

### Requirement: A split count from a scratch window counts the new window's rows
A split count SHALL give the new window a winbar row only when the new window shows a file and winbars show once the split is made. A split from a scratch window that keeps showing the scratch buffer SHALL get exactly the rows counted, under every breadcrumbs mode.

#### Scenario: A split count from a scratch window
- **WHEN** the configuration holds `option.breadcrumbs always`, the current window shows a scratch buffer, and "5<C-w>s" is typed
- **THEN** the new window shows the scratch buffer with no winbar and 5 text rows

#### Scenario: A split from a scratch window to a file has its row
- **WHEN** the configuration holds `option.breadcrumbs always`, the current window shows a scratch buffer, and `:split b.txt` is typed
- **THEN** the new window's first row is its winbar showing " b.txt" and its text starts on the row below

### Requirement: A language server restart drops the outline
`:LspRestart` SHALL drop the symbols held and the text last asked, so the winbar shows the path until the restarted server answers and that server is asked at the first idle tick once it is ready. No answer to a request sent before the restart SHALL reach the winbar.

#### Scenario: A restart keeps the new outline
- **WHEN** a request is in flight, `:LspRestart` is typed, the restarted server is ready, and it answers the request sent at the next idle tick before the old server's answer arrives
- **THEN** the winbar shows the path after the restart, the restarted server's symbols after its answer, and the old answer changes nothing
