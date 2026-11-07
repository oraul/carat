# Design

## Context

No driver spawns a process, starts a thread, or uses a `Queue`; the only input is `AnsiTerminal#read_key`, an `IO.select` with the timeout `InputController#next_timeout` picks (0.05 s while an escape is pending, 0.25 s idle). `StatusSlots` has `lsp_name` and `lsp_state` (`:none`, `:starting`, `:ready`, `:error`) and no writer. `Config#last("language.ruby.lsp")` holds the server's words, refused from a project file. Buffers count `changes` and `closed_count` and move `saved_change` on a write; `BufferList` holds every buffer. `Carat::Json` has no production caller and copies illegal UTF-8 bytes through (backlog). Scout packs: ports and drivers, composition and state, at 803fe6e.

## Goals / Non-Goals

**Goals:** a client that never makes a key wait: no work per key, allocations per key unchanged with no server and with one; a hostile or crashing server never crashes or blocks the editor.

**Non-Goals:** the diagnostics display, requests the user waits on, cancellation, several servers per language, an automatic restart loop.

## Spike

Section 12 asks for a spike before item 10. On the pinned Spinel a program spawned `cat` with `Process.spawn(argv, in: r, out: w, err: File::NULL)` over two `IO.pipe` pairs, read its stdout with `readpartial` in a `Thread` pushing to a `Queue` while the main thread sat in `IO.select` on stdin, and saw the echo and then EOF; `Process.waitpid(pid)`, `Process.detach(pid)`, and `Process.kill("TERM", pid)` compile and work, and a missing command raises `Errno::ENOENT` at the spawn. `Process.wait(pid)` and `Process.waitpid(pid, Process::WNOHANG)` are refused at compile time, so a child is reaped with `Process.detach`, never polled.

## Decisions

### Three ports, two drivers, two doubles

- `ProcessPort`: `spawn(argv)` answers a handle number, 0 when the command cannot start; `write(handle, bytes)` answers whether the bytes went; `stop(handle)` marks the handle closed, queues the end of input so the writer closes the child's stdin, and detaches the child, sending no signal. `ProcessRunner` implements it and starts two threads per child: a reader, which reads chunks, frames them with `RpcFramer`, and pushes each body, then an `exit` message at EOF or an `overflow` message when the framer refuses, on the queue; and a writer, which takes queued bytes off an outbox, so a child that stops reading never blocks the editor thread. The section 8.4 `ServiceThreads` is folded into it: each thread is a dozen lines and needs the child's pipes, and the driver stays the only place a thread starts.
- `MessageQueuePort`: `push(message)` and `pop`, which answers nil at once when empty: the editor never blocks on it, so the section 6 `pop(timeout)` is not needed. `RuntimeQueue` wraps the runtime's `Queue`, the only object both threads hold.
- `LanguageServicePort`: `poll(state)`, `restart(state)`, `saved(buffer)`, `stop`; the core (the input controller, `SaveFile`, `:LspRestart`, and the composition root) sees only it, so no use case sees JSON. `FakeLanguageServices` serves use cases a test builds by hand.
- `FakeProcesses` records spawns and written frames and can refuse a command; `MemoryQueue` is an array. Tests push bodies on the queue as a server's thread would.

### The gateway works only on idle ticks

`InputController#pump` calls `services.poll(state)` when the read returns nothing, after the escape flush and the key deadline; a key never reaches it, so the per-key path is unchanged. `JsonRpcLanguageGateway#poll` drains at most 64 messages, then syncs documents: for the current buffer's file type it starts the server once (a refused spawn is remembered until `:LspStart` or `:LspRestart`); for each buffer of a running server's file type with a path it sends `didOpen` once, `didChange` with the whole text and the next version when `changes` or `closed_count` moved (`changes` alone goes back on undo), and `didSave` for a buffer `SaveFile` reported since the last tick (`saved_change` also moves on an undo back to the saved text, so it cannot tell a write); a document whose buffer is gone or renamed gets `didClose`. Documents are sent only once the server answered `initialize`. `JsonRpcLanguageGateway` keeps its servers in an `Array[untyped]` read through a typed `server_at`, as `make diagnose` asks. The slot is written from the current buffer's server at the same tick, through `StatusSlots#set_lsp`, which builds the label once, so a render allocates nothing for it.

### States and the slot

`LanguageServer` (a `Struct`) holds the language, the words, the handle, the state, the percent, the next request id, the initialize id, the document maps keyed by URI (the version sent, the buffer's `changes` and `closed_count` at that send, and the tick that last saw it), the count of running progress reports, and the diagnostics by URI. States: `:starting` after the spawn, `:ready` after the `initialize` result, `:indexing` while a `$/progress` report runs (begins counted against ends), `:stopped` after `stop` or a refused restart, `:crashed` after an `exit` or `overflow` message the client did not cause. Labels: the name, `name starting`, `name indexing 42%`, `name stopped`, `name crashed :LspRestart`. The groups: starting and indexing `StatusLineLspStarting`, ready `StatusLineLspReady`, crashed `StatusLineLspError`, stopped `StatusLine`. The name is `serverInfo.name` from the result when given, else the command's first word, stripped and capped at 32 bytes.

### Untrusted output

`RpcFramer` reads `Content-Length` headers byte by byte with a 1 KiB header limit and an 8 MiB body limit; past either it refuses, and the driver stops reading and reports `overflow`, which the gateway treats as a crash and stops the child. `Json.parse` errors are rescued per message and the message dropped; `Json` refuses nesting deeper than 64, so a hostile body cannot exhaust the stack, and turns illegal UTF-8 bytes into U+FFFD both ways, which fixes the backlog entry. `ControlText.strip` drops C0, DEL, and C1 controls and caps on a character boundary; the name and every diagnostic message (at most 500 bytes, at most 1,000 per file) pass through it. Server requests get a reply: `window/workDoneProgress/create` and `client/registerCapability` a null result, any other a `MethodNotFound` error, so a server waiting on one is not stuck.

### Trusted directories

ruby-lsp evaluates the project's Gemfile, loads its add-ons and its `.rubocop.yml` requires, so starting it in a cloned directory runs that directory's code. The security review of this change found that auto-starting it on opening a Ruby file broke the rule that opening a directory never decides what Carat runs. A server therefore starts on its own only when the working directory is, or is under, a root of `language.trusted_roots`, a `language` line so the project file cannot set it, with no root shipped; elsewhere the slot reads `untrusted :LspStart` and `:LspStart` (nvim-lspconfig's name) or `:LspRestart` starts it. Roots are compared as strings against `FilePort#cwd` (the resolved working directory) with a `/` boundary, a relative root or one with a `.` or `..` segment naming nothing, so a mistake fails closed. The answer is computed once: neither the directory nor the configuration changes during a session. Alternatives: a per-directory prompt (needs a persisted trust store, a later change) and trusting the directory of the user file (too broad).

### Lifecycle at the edges

`bin/carat.rb` calls `services.stop` in its `ensure`, which sends `shutdown` and `exit` to each running server and stops the child without waiting for answers, so quitting never waits on a server. `:LspRestart` stops every server, forgets refused spawns, and starts the current buffer's server at once; its documents are reopened once it answers `initialize`.

## Risks / Trade-offs

- A changed buffer is sent whole at each idle tick that finds it changed: for a large file this is one copy per pause in typing, not per key; incremental sync can come with completion.
- Messages wait while keys arrive without a 0.25 s pause; the bar may lag a fast typist, which is the price of no per-key work.
