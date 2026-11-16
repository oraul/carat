## MODIFIED Requirements

### Requirement: The server is told about the documents
Once the server has answered `initialize`, the editor SHALL send `textDocument/didOpen` for each buffer with a path whose file type is the server's, `textDocument/didChange` with a higher version at an idle tick after the buffer changed, `textDocument/didSave` after it was written, and `textDocument/didClose` when its buffer is closed or renamed. The `didChange` SHALL follow the `textDocumentSync` kind the initialize result announced, as a number or as the options object's `change`: under 2 it carries ranged content changes, with zero-based lines and UTF-16 code unit characters, whose application in order to the text the server holds reproduces the buffer; under 1 the whole text; under 0, another value, or none announced no `didChange` is sent.

#### Scenario: Open, change, save, close
- **WHEN** `a.rb` is open with a server announcing sync kind 1 ready, `x` deletes a character, `:w` writes it, and `:bd` closes it, each followed by an idle tick
- **THEN** the server received `didOpen` with version 1, `didChange` with the new text and version 2, `didSave`, and `didClose`, in that order

#### Scenario: Incremental changes reproduce the buffer
- **WHEN** a server announcing sync kind 2 is ready and the buffer is edited by inserts, deletes, a multi-line edit, an edit on a line with non-ASCII characters, or an undo, each followed by an idle tick
- **THEN** every `didChange` carries ranges, and applying them in order to the opened text gives the buffer's text

#### Scenario: The options object announces the kind
- **WHEN** the initialize result's `textDocumentSync` is an object whose `change` is 2
- **THEN** an edit is sent as a ranged change

#### Scenario: No sync kind sends no change
- **WHEN** the server announces sync kind 0, or no `textDocumentSync`, and the buffer is edited
- **THEN** the idle tick sends no `didChange`
