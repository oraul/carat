# Design

## Context

See proposal.md, Why. `Buffer#path` is `String?` and `Buffer#path_text` answers `""` for nil. `JsonRpcLanguageGateway#sync` (reached from `poll` on every idle tick once a server runs) guards with `!buffer.path.empty?`, and `complete`, `send_hover`, and `send_signature` end their guard with `buffer.path.empty?`; each raises `NoMethodError` on nil once the buffer's file type matches a running server. `send_symbols` and `apply` (the publish matching) already read `path_text` and skip `""`. Nothing rescues a raise from `poll`, so the editor stops.

A pathless buffer takes a file type from a shebang on its first line (`Filetype.detect` reads the name only when there is one) or from `:set filetype=`.

## Goals / Non-Goals

**Goals:**

- No pathless buffer reaches the server through a sync or a request, and none stops the editor at a sync, a request, or a publish.
- No allocation on a key and none added at an idle tick.

**Non-Goals:**

- Serving pathless buffers through untitled URIs.
- Rescuing exceptions from `poll` in general; the crash is fixed at its cause.

## Decisions

- Read `buffer.path_text` wherever the gateway needs the path: the guard in `sync` and the URI in `sync_buffer`, and the guard and URI in `complete`, `send_hover`, and `send_signature`, each through one local as `send_symbols` does. `path_text` answers the stored string, so the change allocates nothing.
- `sync_buffer` reads `path_text` itself instead of trusting its only caller's guard, so the method is safe on its own.
- Alternative considered: give `uri_of` a `String?` and answer `""` for nil. Rejected: every caller would still have to check the answer, and the nil would cross into a method typed for a String.
- The test is a new file over the production gateway and `ServerCompletions`, as `test/adapters_server_completions.rb` and `test/adapters_signature.rb` build theirs, since `EditorHarness` has a fixed completion source and would not reach the completion request. One table, one row per path, each row a fresh editor whose server advertises completion, hover, and signature help; the row answers the methods sent after the pathless buffer exists, whether the server is still running, and whether the buffer shows a sign. The control row (written to `c.rb`) proves the rows are not vacuous.

## Risks / Trade-offs

- [The hover row cannot reach the gateway's hover guard, since `K` already refuses a pathless buffer in `RequestHover`] → The gateway's guard is fixed anyway, and the row proves the observable behavior: nothing is asked and the editor runs.
