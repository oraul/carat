# Proposal

## Why

A buffer without a path (a `:new` buffer, a pinned docs split, a plugin's scratch) whose file type a running language server serves stops the editor: the gateway asks `empty?` of the buffer's nil path at the next idle tick's document sync, and again before a completion, hover, or signature help request. `:set filetype=ruby` in a `:new` buffer while ruby-lsp runs is enough. This is a T0 crash (queue item 1), and a crash goes to the front of the queue.

## What Changes

- Change the language gateway to read a buffer's path through `Buffer#path_text`, which is `""` for a buffer without one, in the document sync and in the completion, hover, and signature help requests, as the document symbol request and the diagnostics matching already do; a pathless buffer is then skipped: never opened, changed, saved, or closed on the server and never the document of a request.
- Add a table-driven test of a pathless Ruby buffer beside a running server for each path: the sync, the three requests, a publish, and a control row where writing the buffer to a name opens it.
- Remove the backlog entry this fixes and record the plan's bookkeeping in `docs/backlog.md`.

Out of scope: giving a pathless buffer an untitled URI so a server can serve it (Neovim sends none for a `nofile` buffer either), the definition request (word-completion, definitions, and the file finder follow in the queue), and the other backlog entries.

Roadmap: outside the roadmap of `docs/architecture.md` section 12; it fixes a crash in the delivered language services, which a crash puts at the front of the queue.

Assumptions: skipping is the behavior wanted, rather than an untitled document, since the brief's acceptance says a pathless buffer is never sent; `:new` followed by `:set filetype=ruby` is the representative way a pathless buffer gets a served file type in the tests, the pinned docs split and the scratch buffers taking theirs the same way (a shebang or `:set filetype=`).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `language-server`: a buffer without a path is never sent to the server and never stops the editor at a sync, a request, or a publish.

## Impact

- `carat/adapters/json_rpc_language_gateway.rb` (`sync`, `sync_buffer`, `complete`, `send_hover`, `send_signature`).
- Tests: a new `test/adapters_pathless_language.rb`, registered in `test/runner/run_all.rb` and on area 17's Tests line of `docs/codebase-map.md`.
- `docs/backlog.md`: the fixed entry removed, the plan's entries added.
- README.md: unchanged, no command, binding, option, or target changes.
- docs/architecture.md: unchanged, the gateway's role and ports are as described; the fix is inside one adapter.
- No allocation on a key: the gateway works only on idle ticks and `path_text` answers the stored string; `lh` is unchanged.
