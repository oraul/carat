# Proposal

## Why

The language server client and its process driver leave two security Lows and three bugs open, and one of their guards has no test. A definition target URI such as `/project/lib/../../etc/x.rb` reaches the editor with its dot segments kept, so a path that reads as inside the project names a file outside it. Every buffer of a server's file type is sent with its text, a file opened from outside the project included, to a server that runs the project's own code. A save made while the server is still starting is forgotten at the next idle tick, so the server never hears of it. A server that ignores both the end of its input and TERM keeps running after `:LspStop`, `:LspRestart`, or quit. After the writer thread stopped on a broken pipe, `ProcessRunner#write` still answers true, so the gateway never sees the server's input broke. No test shows that a command that could not start is not tried again at the next idle tick.

This is Sprint 22 backlog item 2, split by the plan: it delivers 6 of the brief's 10 headings, the 4 left (the `DiskFiles#stat` calls, the two NO_COLOR headings, and the client's repetition) are queued as `lsp-tidy-c`. It is outside the roadmap of `docs/architecture.md` section 12: a backlog fix of delivered language server work.

## What Changes

- `JsonRpcLanguageGateway#path_of` answers "" for a URI whose decoded path holds a `.` or `..` segment, `%2E` escapes included, so such a definition target is dropped like a relative one.
- The gateway opens a buffer on its server only when the buffer's path, made absolute against the working directory with its `.` and `..` segments resolved, lies under the working directory, the root the server is given as `rootUri`; a buffer outside it is never sent, so no `didOpen`, `didChange`, `didSave`, or `didClose` names it.
- A save of a buffer whose server is still starting is kept until that server's first sync, which sends `didSave` after the buffer's `didOpen`; saves of buffers with no starting server are forgotten after each tick as before. A save in the tick a buffer is first opened on a running server now follows its `didOpen` too, so the pathless buffer written to a name is sent `didOpen` and `didSave` (`test/adapters_pathless_language.rb` updated).
- `ProcessRunner#stop` waits up to `STOP_SECONDS` (0.5 s) for the child to end on TERM and then signals KILL to it, so a server that ignores its end of input and TERM does not outlive the editor.
- The writer thread closes its outbox when a write fails, and `ProcessRunner#write` answers false for a closed outbox, so the gateway crashes the server instead of queueing bytes no one writes.
- A test shows a command that cannot start is spawned once and not again at the next idle tick (`FakeProcesses#attempts` counts the refused spawns too).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `language-server`: the documents told to the server lie under the working directory and a save while it starts is sent once it is ready; stopping a server kills one that ignores TERM, and a server whose input broke takes no more input.
- `definitions`: a target whose path holds a `.` or `..` segment is dropped.

## Out of scope

- "DiskFiles#stat makes four system stats per path", "NO_COLOR leaves syntax, bars, and messages colored", "No test reads NO_COLOR through AnsiTerminal", and "The language server client repeats itself and names little of what it uses": queued as `lsp-tidy-c` by the plan and appended to `docs/findings/lsp-tidy.md`.
- Requests (completion, hover, definition, signature help, document symbols) for a buffer outside the working directory are still sent, naming its URI but not its text; whether to skip them is recorded as a finding.
- A link inside the working directory that leads out of it is judged by its lexical path, as the definitions' project check is; resolving links on every sync would read the disk at each idle tick.
- No `tools/rules.sh` edit; no file of the feature lane.

## Impact

- carat/adapters/json_rpc_language_gateway.rb, carat/drivers/process_runner.rb, carat/ports/process_port.rb (the stop contract), carat/doubles/fake_processes.rb (`attempts`).
- test/adapters_language_gateway.rb, test/adapters_definitions.rb, test/drivers_process_runner.rb, test/adapters_pathless_language.rb (one expectation), and test/lint.rb (`post` joins `BOOL_COMMANDS`, a command answering whether the writer took the bytes).
- README.md: unchanged, it names the language server features but not which files are synced, how a server is stopped, or how a target URI is decoded.
- docs/architecture.md: section 8.4's language server paragraph gains the working-directory rule and the KILL after the stop's grace; no layer, port name, or rule changes.
- docs/codebase-map.md: area 17's process runner and gateway entries name the new behavior; no file is added, moved, or removed.
- CLAUDE.md: unchanged, no process changes.
- Performance: the working-directory check runs only for a buffer the server has not opened, so an opened buffer's idle tick allocates nothing more; `stop` may wait up to 0.5 s, only for a server that has not ended on TERM.
