## MODIFIED Requirements

### Requirement: The server is told about the documents
Once the server has answered `initialize`, the editor SHALL send `textDocument/didOpen` for each buffer with a path under the working directory whose file type is the server's, `textDocument/didChange` with a higher version at an idle tick after the buffer changed, `textDocument/didSave` after it was written, and `textDocument/didClose` when its buffer is closed or renamed. A buffer whose path, its `.` and `..` segments resolved, lies outside the working directory SHALL never be sent.

#### Scenario: Open, change, save, close
- **WHEN** `a.rb` is open with a server announcing sync kind 1 ready, `x` deletes a character, `:w` writes it, and `:bd` closes it, each followed by an idle tick
- **THEN** the server received `didOpen` with version 1, `didChange` with the new text and version 2, `didSave`, and `didClose`, in that order

#### Scenario: A file outside the working directory is never opened on the server
- **WHEN** a server runs for `/project` and a Ruby file outside it, named by an absolute path or by a relative path climbing out with `..`, is opened and edited, each followed by an idle tick
- **THEN** the server is sent nothing about that file, while a Ruby file under `/project` named with a `..` segment is opened on it

## ADDED Requirements

### Requirement: A save while the server starts is sent once it is ready
A buffer written while its server starts SHALL be sent `textDocument/didSave` after its `didOpen` once the server is ready.

#### Scenario: A save while the server starts is sent once it is ready
- **WHEN** `a.rb` is opened, its server is started, `:w` writes it before the server answers `initialize`, and the server then answers
- **THEN** the server receives `didOpen` and then `didSave` for `a.rb`

### Requirement: A server that does not end when asked is killed
A server process that has not ended half a second after the editor asked it to end, on quit, `:LspRestart`, `:LspStop`, or a crash, SHALL be killed, by signalling that process itself.

#### Scenario: A server ignoring its end of input and TERM is killed
- **WHEN** a server process ignores both the end of its input and TERM, and it is stopped
- **THEN** its process ends

### Requirement: A server whose input broke takes no more input
Once writing to a server's input failed, the editor SHALL treat the server as taking no more input.

#### Scenario: A server whose input broke takes no more input
- **WHEN** a server process closes its input and a write to it fails
- **THEN** the next write to it answers that it takes no input
