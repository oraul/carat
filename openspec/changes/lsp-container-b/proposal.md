# Proposal

## Why

Part b of the `lsp-container` user request (docs/queue-feature.md, Sprint 13 item 1), outside the numbered roadmap of `docs/architecture.md` section 12, as an extension of the delivered item 10 (`language-services`). Two gaps are left in the language server gateway since part a (#171):

- Quit and `:LspRestart` stop a server by closing its input and detaching its process: no signal reaches it, so a server that ignores `exit`, or a container wrapper a `language.<name>.lsp.root` line now runs, keeps running after carat. Ending it must end only the process carat spawned, never its group or a process number reused after the child was reaped.
- `command?` runs on each idle tick while the current buffer's language has no server, building the setting key and scanning every configuration line backward twice (`root_line`, then `Config#last`), though the configuration never changes in a session.

Re-verified on main at 5fdd787bbddd: `ProcessRunner#stop` sends no signal at all (the brief's "may end more than the server" does not hold as worded; the risk is ending nothing, and a naive kill after `Process.detach` could hit a reused number); `command?` is at `json_rpc_language_gateway.rb:317` and `root_line` at `:339`.

## What Changes

- `ProcessPort#stop` ends the child it started: the driver queues the close of the child's input, signals `TERM` to the child's own process number (never a group, never a number of another handle), while the child is still unreaped, then detaches it; a child already gone is ignored.
- The gateway settles whether a language names a server command, and its program, the first time it is asked and keeps the answer for the session, as `trusted?` keeps its own; an idle tick with no server for the current buffer's language reads no configuration line. The full command is still read when a server starts.

Out of scope: a grace period between `exit` and the signal (the server gets `shutdown` and `exit` queued first, then `TERM`); ending processes the server itself started; several servers of one language at once; re-reading the configuration in a session, which carat does not do.

Assumptions: `TERM` is the signal that ends a server, the one a terminal or service manager sends; quit and `:LspRestart` both reach the driver through the gateway's `stop`, so one driver change covers both.

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `language-server`: quit and `:LspRestart` end only the server process carat started; a language's server command is settled once.

## Impact

`carat/drivers/process_runner.rb` (`stop` signals the child's own pid before detaching), `carat/ports/process_port.rb` (the `stop` contract), `carat/adapters/json_rpc_language_gateway.rb` (`words_of` keeps each language's settled command); tests in `test/drivers_process_runner.rb`, `test/adapters_language_gateway.rb`, `test/editor_lsp.rb`. No new file, no dependency, no new port method.

- README.md: changed, the language server paragraph says quit and `:LspRestart` end only the server process Carat started.
- docs/architecture.md: changed, the `ProcessRunner` entry names the signal to the child's own process and the settled command.
