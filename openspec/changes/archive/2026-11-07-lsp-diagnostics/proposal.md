# Proposal

## Why

Carat has no language server client: the bar's `lsp` slot has no writer and nothing runs `language.ruby.lsp`. This delivers the first part of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 (docs/queue.md item 2, goal 2): the client and its lifecycle. The planner split the brief; the diagnostics display (signs, the message row, the counts slot) is `diagnostics-display`, next in the queue.

## What Changes

- A language server starts when a buffer whose file type names a `language.<name>.lsp` command is current at an idle tick and the working directory is under a root of `language.trusted_roots` (defaults and user file only, none shipped), or on `:LspStart` in any directory, as a subprocess through `Process.spawn` with `IO.pipe` pairs, with a reader thread per server that frames JSON-RPC messages and pushes them on a `Queue` and a writer thread; the editor drains the queue only at idle ticks, never while keys are waiting.
- The lifecycle: `initialize` and `initialized`, `textDocument/didOpen`, `didChange` (the whole text, once per idle tick that finds the buffer changed), `didSave`, `didClose`, `shutdown` and `exit` when the editor ends, and `:LspRestart`, which restarts the servers after a crash or a stop.
- The bar's `lsp` slot shows the server's name and state: `starting`, ready (the name alone), `indexing` with a percent from `$/progress`, `stopped`, `crashed :LspRestart`, and `untrusted :LspStart` in an untrusted directory.
- `textDocument/publishDiagnostics` is kept as plain diagnostic values per file (row, column, severity, message), for `diagnostics-display` to draw.
- Server output is untrusted: a frame header over 1 KiB or a body over 8 MiB ends the server as crashed, a body that is not JSON is dropped, the server's name and every message are capped and stripped of control characters, and `Carat::Json` refuses nesting deeper than 64 and writes and reads illegal UTF-8 bytes as U+FFFD.
- `Carat::Json` fixes the backlog entry on text that is not UTF-8.

Out of scope: drawing diagnostics (`diagnostics-display`); requests with responses the user sees (completion, hover, definition) and their cancellation (`completion`); an automatic restart loop; a stderr log file (stderr goes to the null device); more than one server per language.

Assumptions: restarting after a crash is the user's `:LspRestart`, named after nvim-lspconfig's command, which the crashed state's hint names; a missing server command leaves the slot empty, as Neovim without a configured server, and `:LspRestart` reports it; `didSave` is reported by `SaveFile` through the services port and sent at the next idle tick, since the buffer's saved mark also moves on an undo back to the saved text. Trust is a list of roots in the user file rather than a per-directory prompt with a persisted store, which can come later; a root is matched as a string against the resolved working directory, so a root written through a symbolic link fails closed.

## Capabilities

### New Capabilities

- `language-server`: the language server client: when a server starts, the documents it is told about, its states, its diagnostics as values, its restart, and the limits on its output.

### Modified Capabilities

- `status-bar`: the `lsp` slot shows the state's text after the name, and the states are starting, ready, indexing, stopped, and crashed.

## Impact

- Domain: new `RpcFramer`, `ServiceMessage`, `Diagnostic`, `LanguageServer`, `ControlText`; `StatusSlots` gains `lsp_label` and `set_lsp`; `Json` gains the depth limit and the UTF-8 handling.
- Ports: new `ProcessPort`, `MessageQueuePort`, `LanguageServicePort`. Drivers: new `ProcessRunner` (the spawn and the reader thread) and `RuntimeQueue`. Doubles: new `FakeProcesses`, `MemoryQueue`, `FakeLanguageServices`.
- Adapters: new `JsonRpcLanguageGateway`; `EditorAssembly` takes `processes:` and `messages:`; `InputController` polls the services on an idle tick; `StatusBar` draws the label and the new states.
- Use cases: new `LspRestartCommandHandler` for `:LspRestart`; `SaveFile` reports a write to the services. `bin/carat.rb` builds the drivers and stops the services in its `ensure`.
- Docs: `docs/compatibility.md`, `docs/codebase-map.md`, `docs/architecture.md` sections 6 and 8, `README.md`, `docs/backlog.md`.
