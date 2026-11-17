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
- The gateway keeps settled commands in two parallel lists, the languages and their words (an empty list for no command), filled by `words_of` on the first ask; `command?` and every later `words_of` answer from them. Nothing forgets them: the configuration is read once at start and the working directory does not change, as `trusted?` already assumes. Alternative: forget them on `:LspRestart`, rejected since the configuration it would re-read is the same object.
- The lookup compares the language string in place over a short list, so the idle tick allocates nothing for it.

## Risks / Trade-offs

- [`TERM` can reach the server before it reads `shutdown` and `exit`] → the server ends either way, which is what quit and `:LspRestart` ask; a grace period is left out (proposal).
- [A configuration changed in a session would not be seen] → carat has no configuration reload; one would have to forget the settled commands.
