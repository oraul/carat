## ADDED Requirements

### Requirement: A failed initialize leaves the server not ready
When a server answers `initialize` with an error, or without a result object, the editor SHALL NOT mark it ready: it SHALL stop the server, the `lsp` slot SHALL name the restart as for a crash, and no `initialized` notification, document, or completion request SHALL be sent to it.

#### Scenario: An initialize error
- **WHEN** ruby-lsp answers `initialize` with an error and the editor is idle
- **THEN** the slot shows the crash and names `:LspRestart`, and nothing after `initialize` was sent to the server
