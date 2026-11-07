## Purpose

The language server client: which server runs for a buffer, what it is told about the documents, its states on the bar, its diagnostics as values, its restart, and the limits on what it may send.

## ADDED Requirements

### Requirement: A server starts for the current buffer's language
When the editor is idle, the current buffer's file type names a `language.<name>.lsp` command, and the working directory is, or is under, a root of `language.trusted_roots`, the editor SHALL start that command once as a language server and send it `initialize`, then `initialized` when it answers. A command that cannot start SHALL leave the `lsp` slot empty and SHALL NOT be tried again until `:LspStart` or `:LspRestart`. No key SHALL wait on a server: messages are read and sent only when no key is waiting.

#### Scenario: Opening a Ruby file starts ruby-lsp
- **WHEN** `a.rb` is opened in a directory under a trusted root and the editor is idle
- **THEN** `ruby-lsp` is started, an `initialize` request is sent, and the slot reads "ruby-lsp starting"

#### Scenario: A missing command leaves the slot empty
- **WHEN** `a.rb` is opened and `ruby-lsp` cannot be started
- **THEN** the slot is empty and later idle ticks start nothing

#### Scenario: A text file starts nothing
- **WHEN** `a.txt` is opened and the editor is idle
- **THEN** no server is started

### Requirement: An untrusted directory starts no server on its own
A language server runs the project's own code, so in a working directory under no root of `language.trusted_roots` the editor SHALL NOT start a server on its own; the `lsp` slot SHALL read the command's name followed by "untrusted :LspStart".

#### Scenario: An untrusted directory spawns nothing
- **WHEN** `a.rb` is opened in a directory no `language.trusted_roots` line names and the editor is idle
- **THEN** no process is started and the slot reads "ruby-lsp untrusted :LspStart"

### Requirement: Only the user names the trusted roots
`language.trusted_roots` SHALL be read from the defaults and the user file only; a project file's line SHALL be reported and ignored, and no root is shipped. A root SHALL be an absolute path, or a `~/` path under the home directory, without a `.` or `..` segment; any other word SHALL name no root.

#### Scenario: A project file cannot trust its own directory
- **WHEN** the project's `.caratrc` holds `language.trusted_roots /project` and `a.rb` is opened in `/project`
- **THEN** the line is reported, no process is started, and the slot reads "ruby-lsp untrusted :LspStart"

#### Scenario: A sibling sharing a root's prefix is not under it
- **WHEN** the user file trusts `/project` and `a.rb` is opened in `/projectx`
- **THEN** no process is started

### Requirement: :LspStart starts the current buffer's server
`:LspStart` SHALL start the current buffer's server when none runs for its file type, a crashed or stopped server counting as none, whether or not the directory is trusted, and SHALL leave a running server alone. With no server configured for the current buffer it SHALL report so; arguments SHALL be refused.

#### Scenario: :LspStart in an untrusted directory
- **WHEN** `a.rb` is opened in an untrusted directory and `:LspStart` is entered
- **THEN** `ruby-lsp` is started and the slot reads "ruby-lsp starting"

#### Scenario: :LspStart after a crash
- **WHEN** the server of `a.rb` ended on its own and `:LspStart` is entered
- **THEN** a new `ruby-lsp` process is started and the slot reads "ruby-lsp starting"

#### Scenario: :LspStart on a text file
- **WHEN** `b.txt` is the current buffer and `:LspStart` is entered
- **THEN** "No language server for this buffer" is shown and nothing is started

### Requirement: The server is told about the documents
Once the server has answered `initialize`, the editor SHALL send `textDocument/didOpen` for each buffer with a path whose file type is the server's, `textDocument/didChange` with the whole text and a higher version at an idle tick after the buffer changed, `textDocument/didSave` after it was written, and `textDocument/didClose` when its buffer is closed or renamed.

#### Scenario: Open, change, save, close
- **WHEN** `a.rb` is open with the server ready, `x` deletes a character, `:w` writes it, and `:bd` closes it, each followed by an idle tick
- **THEN** the server received `didOpen` with version 1, `didChange` with the new text and version 2, `didSave`, and `didClose`, in that order

### Requirement: The slot shows the server's state
The `lsp` slot SHALL show the server's name when ready, "starting" after it while it starts, "indexing" and the percent while a `$/progress` report runs, "stopped" after it was stopped, "crashed :LspRestart" after it ended on its own, and "untrusted :LspStart" while it waits for an explicit start in an untrusted directory. The name SHALL be the server's reported name, or the command's first word.

#### Scenario: Indexing shows a percent
- **WHEN** the server reports progress begin and then 42 percent
- **THEN** the slot reads "ruby-lsp indexing 42%", and "ruby-lsp" after the progress ends

#### Scenario: A crash names the restart command
- **WHEN** the server's output ends without a shutdown
- **THEN** the slot reads "ruby-lsp crashed :LspRestart" in the error group

### Requirement: :LspRestart restarts the servers
`:LspRestart` SHALL stop every server, forget commands that could not start, and start the current buffer's server again, which reopens its documents once it answers. With no server configured for the current buffer it SHALL report so.

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
