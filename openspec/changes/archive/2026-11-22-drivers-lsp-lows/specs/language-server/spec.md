## ADDED Requirements

### Requirement: Diagnostics are kept only for opened documents
The editor SHALL keep a `textDocument/publishDiagnostics` notification only for a document it told that server is open; a publish for any other URI SHALL be dropped, so the diagnostics kept are bounded by the open files of the server's type.

#### Scenario: A publish for an unopened file is dropped
- **WHEN** ruby-lsp runs with `a.rb` open and publishes diagnostics for three URIs no buffer opened
- **THEN** no diagnostics are kept for them and only `a.rb`'s entry is kept

### Requirement: A request whose send failed is not in flight
When writing a request to a server fails, the editor SHALL treat the request as never sent: nothing SHALL be in flight for it, and the editor SHALL stop waiting on it at once instead of polling until its answer is overdue.

#### Scenario: A failed completion send leaves nothing in flight
- **WHEN** the server's input breaks and the wanted word's completion request is then written
- **THEN** the server is crashed and the editor waits on no request
