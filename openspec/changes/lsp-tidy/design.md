# Design

## Context

`JsonRpcLanguageGateway` (map area 17) syncs every buffer of a server's file type at each idle tick and decodes the file URIs of definition targets in `path_of`; `ProcessRunner` runs each server with a reader and a writer thread and ends it in `stop`. The scout pack at cd3c148 names the lines: `path_of` keeps every segment, `sync_buffer` checks only that a path is set, `poll` clears `@saves` after syncing only running servers, `stop` sends TERM and detaches, and `drain` stops on a failed write without telling `write`.

## Decisions

- Dot segments in a target are refused, not resolved. A server names its files by absolute, normalized URIs, so a `.` or `..` segment is either a mistake or an attempt to make a path read as inside the project; dropping it matches how `path_of` already drops a relative, NUL-holding, or malformed URI. The check is `Domain::RootWord.root?` on the decoded path, the rule that already refuses such segments in a root word, so no second copy of it is written.
- The boundary for syncing is the working directory, not the trusted root. The server is started with the working directory as `rootUri` and its one workspace folder, and an explicit `:LspStart` in an untrusted directory has no trusted root at all, so the trusted root would sync nothing there. The working directory is the trusted root or under it whenever a server started on its own, so the rule is never looser than the heading asks. The path is made absolute and normalized with `PluginApi::Paths.absolute` and judged with `Domain::PathPolicy.inside?`, the helpers the definitions' project check uses.
- The check runs only for a document the server has not opened (no version kept), so an opened buffer's idle tick allocates nothing more; a buffer renamed out of the directory gets a new URI, which is checked, and its old URI is closed by the unseen-document loop.
- A save waits for a starting server: after the sync loop, `poll` keeps the save of a buffer whose file type's server is in the `:starting` state and forgets the others. `sync_buffer` sends `didSave` after `didOpen` too, so the first sync of a server that was starting tells it of the save. A buffer closed or a server crashed before it is ready drops the save at the next tick.
- `stop` waits up to `STOP_SECONDS` (0.5 s) on the `Process.detach` thread after TERM and signals KILL when it has not ended. A server that ends on TERM, the default action, is reaped at once and costs no wait; only one that handles or ignores TERM delays `:LspStop`, `:LspRestart`, a crash, or quit, by at most 0.5 s each. A wait off the editor thread would die with the editor at quit, the very case the heading names. The KILL goes to the child's own pid while the detach thread has not reaped it; the one window left is a child ending between the wait's timeout and the signal, as narrow as the existing TERM.
- The writer thread closes its outbox (`Queue#close`) when a write fails; `write` answers false for a closed outbox, and a push that loses the race to the close rescues `ClosedQueueError` and answers false. `@open` stays the editor thread's own, so `stop` still signals a child whose writer stopped.

## Risks

- A server that needs more than 0.5 s to clean up on TERM is killed. Such a server already received `shutdown` and `exit` before `stop`.
- Requests for a buffer outside the working directory still name its URI without its text; recorded as a finding.
