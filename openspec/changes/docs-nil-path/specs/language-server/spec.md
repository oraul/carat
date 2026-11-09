## ADDED Requirements

### Requirement: A buffer without a path is never sent to the server

A buffer that has no path (a `:new` buffer, a pinned docs split, a plugin's scratch buffer) SHALL never be opened, changed, saved, or closed on a language server and SHALL never be the document of a completion, hover, or signature help request, even when its file type is one a running server serves. A publish SHALL draw nothing on such a buffer. None of these SHALL stop the editor. Once the buffer is written to a name, it SHALL be opened on the server like any other file of its type.

#### Scenario: A pathless buffer is never opened on the server

- **WHEN** ruby-lsp runs, the user types `:new`, `:set filetype=ruby`, and `ifoo<Esc>`, and idle ticks pass
- **THEN** no message is sent to the server and the editor keeps running

#### Scenario: A word typed in a pathless buffer asks no completion

- **WHEN** ruby-lsp completes, the user types `:new`, `:set filetype=ruby`, and `ifoo` in insert mode, and the debounce passes
- **THEN** no completion request is sent and the editor keeps running

#### Scenario: K in a pathless buffer asks no hover

- **WHEN** ruby-lsp hovers, the user types `:new`, `:set filetype=ruby`, `ifoo<Esc>`, and `K`, and idle ticks pass
- **THEN** no hover request is sent and the editor keeps running

#### Scenario: An open paren in a pathless buffer asks no signature help

- **WHEN** ruby-lsp gives signature help, the user types `:new`, `:set filetype=ruby`, and `ifoo(` in insert mode, and the debounce passes
- **THEN** no signature help request is sent and the editor keeps running

#### Scenario: A publish draws nothing on a pathless buffer

- **WHEN** ruby-lsp runs, the user types `:new`, `:set filetype=ruby`, and `ifoo<Esc>`, and the server publishes diagnostics for the working directory's URI
- **THEN** the pathless buffer shows no sign and the editor keeps running

#### Scenario: A pathless buffer written to a name is opened

- **WHEN** ruby-lsp runs, the user types `:new`, `:set filetype=ruby`, `ifoo<Esc>`, and `:w c.rb`, and an idle tick passes
- **THEN** the server receives `didOpen` for `c.rb`
