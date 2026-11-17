# Spec Delta

## MODIFIED Requirements

### Requirement: The slots' colors follow their kind and state
The diagnostics counts SHALL be drawn in `StatusLineDiagnosticError`, `StatusLineDiagnosticWarn`, `StatusLineDiagnosticInfo`, and `StatusLineDiagnosticHint`, the status bar's count groups, on the bar's background, the `lsp` slot in `StatusLineLspStarting` while starting or indexing, `StatusLineLspReady` when ready, `StatusLineLspError` when crashed, and `StatusLine` when stopped or untrusted, and every other segment in `StatusLine`.

#### Scenario: A row per state
- **WHEN** the bar is drawn with the server in each state and with a count of each kind
- **THEN** the slot's cells and each count's cells carry the group of that state or kind
