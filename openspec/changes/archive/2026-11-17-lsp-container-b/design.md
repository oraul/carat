# Design

## Context

See proposal.md. Quit (`bin/carat.rb`, the `ensure` calling `services.stop`) and `:LspRestart` (`JsonRpcLanguageGateway#restart`, which calls `stop`) both stop each launched server through `ProcessPort#stop(handle)` after queuing `shutdown` and `exit`; a crash calls it too. `ProcessRunner#stop` closes the outbox and calls `Process.detach`, which reaps the child once it ends. `JsonRpcLanguageGateway#command?` and `words_of` rebuild `language.<type>.lsp` and scan `@config.settings` on each call; `poll` calls `command?` on every idle tick when no server runs for the buffer's language.

## Goals / Non-Goals

**Goals:**
- Quit and `:LspRestart` end the server process carat spawned and nothing else.
- An idle tick without a server reads no configuration line and allocates no key.

**Non-Goals:**
- A wait for the server to exit on its own before the signal: the editor thread never waits on a child, and at quit the threads that could wait end with the process.
- Process groups: the child stays in carat's group; carat never signals a group.

## Decisions

- `ProcessRunner#stop` signals `TERM` to `@pids[handle - 1]` before `Process.detach`: until the detach reaps it, the number is still the child's (a zombie at worst), so the signal cannot reach a process that reused it; after `stop` the handle is closed and never signalled again. A positive number only: a signal to `0` or a negative number would reach a whole group. `Errno::ESRCH` and other `SystemCallError`s are ignored. Alternative: `KILL`, rejected since a server should be able to clean up; a signal to the process group, rejected as ending more than the server.
- `ProcessRunner#initialize` traps `PIPE` with a handler that does nothing: `stop` TERMs a child its writer thread may still be writing to (the queued `shutdown` and `exit`, or a write blocked on the full pipe of a stalled server), and the runtime traps only `INT` and `TERM`, so that write would otherwise end carat by `SIGPIPE` instead of failing with `EPIPE`, which `write_bytes` rescues. Alternative: `Signal.trap("PIPE", "IGNORE")`, rejected since an ignored signal stays ignored in every spawned child, so a child program writing to a closed pipe would loop on `EPIPE` instead of ending; a handler resets to the default on exec.
- The gateway keeps settled answers in two parallel lists of strings, the languages and the program each names ("" for no command), filled by `head_of` on the first ask; `command?` and the untrusted slot (`hold`) answer from them, and `words_of` reads the full command only when a server starts or a start fails, once per start. Alternative: keep each language's word list, rejected since a list of word lists cost the test runner two more re-narrowing rounds than `make test-build` allows (4 against 2). Nothing forgets them: the configuration is read once at start and the working directory does not change, as `trusted?` already assumes. Alternative: forget them on `:LspRestart`, rejected since the configuration it would re-read is the same object.
- The lookup compares the language string in place over a short list, so the idle tick allocates nothing for it.

## Risks / Trade-offs

- [`TERM` can reach the server before it reads `shutdown` and `exit`] → the server ends either way, which is what quit and `:LspRestart` ask; a grace period is left out (proposal).
- [A configuration changed in a session would not be seen] → carat has no configuration reload; one would have to forget the settled commands.
