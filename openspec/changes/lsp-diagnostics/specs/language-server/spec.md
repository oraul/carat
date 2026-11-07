## Purpose

The language server client: which server runs for a buffer, what it is told about the documents, its states on the bar, its diagnostics as values, its restart, and the limits on what it may send.

## ADDED Requirements

### Requirement: A server starts for the current buffer's language
When the editor is idle and the current buffer's file type names a `language.<name>.lsp` command, the editor SHALL start that command once as a language server and send it `initialize`, then `initialized` when it answers. A command that cannot start SHALL leave the `lsp` slot empty and SHALL NOT be tried again until `:LspRestart`. No key SHALL wait on a server: messages are read and sent only when no key is waiting.

#### Scenario: Opening a Ruby file starts ruby-lsp
- **WHEN** `a.rb` is opened and the editor is idle
- **THEN** `ruby-lsp` is started, an `initialize` request is sent, and the slot reads "ruby-lsp starting"

#### Scenario: A missing command leaves the slot empty
- **WHEN** `a.rb` is opened and `ruby-lsp` cannot be started
- **THEN** the slot is empty and later idle ticks start nothing

#### Scenario: A text file starts nothing
- **WHEN** `a.txt` is opened and the editor is idle
- **THEN** no server is started

### Requirement: The server is told about the documents
Once the server has answered `initialize`, the editor SHALL send `textDocument/didOpen` for each buffer with a path whose file type is the server's, `textDocument/didChange` with the whole text and a higher version at an idle tick after the buffer changed, `textDocument/didSave` after it was written, and `textDocument/didClose` when its buffer is closed or renamed.

#### Scenario: Open, change, save, close
- **WHEN** `a.rb` is open with the server ready, `x` deletes a character, `:w` writes it, and `:bd` closes it, each followed by an idle tick
- **THEN** the server received `didOpen` with version 1, `didChange` with the new text and version 2, `didSave`, and `didClose`, in that order

### Requirement: The slot shows the server's state
The `lsp` slot SHALL show the server's name when ready, "starting" after it while it starts, "indexing" and the percent while a `$/progress` report runs, "stopped" after it was stopped, and "crashed :LspRestart" after it ended on its own. The name SHALL be the server's reported name, or the command's first word.

#### Scenario: Indexing shows a percent
- **WHEN** the server reports progress begin and then 42 percent
- **THEN** the slot reads "ruby-lsp indexing 42%", and "ruby-lsp" after the progress ends

#### Scenario: A crash names the restart command
- **WHEN** the server's output ends without a shutdown
- **THEN** the slot reads "ruby-lsp crashed :LspRestart" in the error group

### Requirement: :LspRestart restarts the servers
`:LspRestart` SHALL stop every server, forget commands that could not start, and start the current buffer's server again at the next idle tick, which reopens its documents. With no server configured for the current buffer it SHALL report so.

#### Scenario: Restart after a crash
- **WHEN** the server crashed and `:LspRestart` is entered
- **THEN** a new server is started and the slot reads "ruby-lsp starting"

### Requirement: Diagnostics are kept as values
The editor SHALL keep the diagnostics of each `textDocument/publishDiagnostics` notification as row, column, severity, and message per file, replacing that file's earlier ones, at most 1,000 per file, each message at most 500 bytes with control characters removed.

#### Scenario: Diagnostics replace the file's earlier ones
- **WHEN** the server publishes two diagnostics for `a.rb` and then one
- **THEN** `a.rb` has the one diagnostic, with its row, column, severity, and message

### Requirement: Server output cannot harm the editor
A frame header over 1 KiB or a body over 8 MiB SHALL end the server as crashed. A body that is not JSON, or nests deeper than 64, SHALL be dropped without stopping the editor. Text the server sends SHALL reach the screen with its control characters removed, and bytes that are not UTF-8 SHALL be read and written as U+FFFD. The editor SHALL send `shutdown` and `exit` when it ends and SHALL NOT wait for an answer.

#### Scenario: Malformed JSON is dropped
- **WHEN** the server sends a body that is not JSON and then a valid result
- **THEN** the editor keeps running and the valid result is handled

#### Scenario: An escape sequence in the name is stripped
- **WHEN** the server reports its name as "evil" followed by an escape sequence
- **THEN** the slot shows the name without the escape character
