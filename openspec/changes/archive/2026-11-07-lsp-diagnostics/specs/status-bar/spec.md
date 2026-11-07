## MODIFIED Requirements

### Requirement: The reserved slots stay empty until a service fills them
The git branch, the diagnostics counts, and the `lsp` slot SHALL take no cells while empty and keep their place in the order. A branch SHALL show as the `git` icon, a space, and the name. The diagnostics counts SHALL show each count above zero as its icon (`error`, `warning`, `info`, `hint`), a space, and the number, in that order, each in its own group. The `lsp` slot SHALL show the server's name and its state (requirement "The lsp slot names the state").

#### Scenario: Empty slots take no room
- **WHEN** no branch, no diagnostics, and no server are set
- **THEN** the bar shows the same cells as a bar without those slots

#### Scenario: Filled slots
- **WHEN** the branch is "main", there are 2 errors and 1 hint, and the server "ruby-lsp" is ready, with the unicode icons and a wide frame
- **THEN** the left part reads " NORMAL  a.txt  ± main  ✖ 2 ◇ 1 " and the right part starts with " ruby-lsp " in the ready group

#### Scenario: The lsp slot keeps its place
- **WHEN** the server "ruby-lsp" is set while a plugin segment "x" is shown
- **THEN** " ruby-lsp " stands after " x " and before the encoding

### Requirement: The slots' colors follow their kind and state
The diagnostics counts SHALL be drawn in `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, and `DiagnosticHint`, the `lsp` slot in `StatusLineLspStarting` while starting or indexing, `StatusLineLspReady` when ready, `StatusLineLspError` when crashed, and `StatusLine` when stopped or untrusted, and every other segment in `StatusLine`.

#### Scenario: A row per state
- **WHEN** the bar is drawn with the server in each state and with a count of each kind
- **THEN** the slot's cells and each count's cells carry the group of that state or kind

## ADDED Requirements

### Requirement: The lsp slot names the state
The `lsp` slot SHALL show the server's name followed by its state's text: nothing when ready, "starting", "indexing" and a percent, "stopped", "crashed :LspRestart", or "untrusted :LspStart".

#### Scenario: The slot names the state
- **WHEN** the server "ruby-lsp" is indexing at 42 percent
- **THEN** the slot reads " ruby-lsp indexing 42% "
