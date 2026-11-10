# Design

## Context

`VisitTarget#absolute` (line 166 at 2f54bb5) joins a relative buffer path to the working directory without resolving `.` or `..`, and its result is compared with the target path the gateway decoded from the server's URI, which a server answers resolved. A buffer named `./a.rb` gives `/project/./a.rb` against `/project/a.rb`: the same-file test in `jump` (line 77) and `listed_for` (line 141) both miss, so a modified buffer is refused with E37 and an unmodified one is opened again through `OpenFile` under the shown name `a.rb`. `PluginApi::Paths.absolute(cwd, path)` already answers the normalized absolute form, and the file use cases (`DeletePath`, `RenamePath`, `MakePath`, `WindowRequests`) compare paths with it.

`JsonRpcLanguageGateway` holds one request per kind. Each kind repeats: its cancel (server lookup, `$/cancelRequest`, zeroing the id) beside the private `cancel_request(language, id)` that only `cancel_signature` calls; its forget step on a stopped or crashed server (drop the language, zero the id when it was the ask's); the `textDocument` and `position` params of a cursor request; and the running-server lookup. `stop` calls four forget steps, `crash` five: `stop` skips the symbols ask.

## Goals / Non-Goals

**Goals:** `gd` finds its own file under any spelling of its path; one owner for each copied step of the gateway's request lifecycle; a row for each.

**Non-Goals:** a shared record for the anchored asks in the domain; a change to what the gateway sends.

## Decisions

### Normalize both sides through PluginApi::Paths.absolute

`VisitTarget#absolute(path)` keeps its `""` for an empty path (a buffer with no file is never a target) and otherwise answers `PluginApi::Paths.absolute(@files.cwd, path)`; the target is compared through the same function, so a target spelled with dot segments also matches. `visit_target.rb` requires `carat/plugin_api.rb`, as `delete_path.rb` does in the same layer. Alternative: normalize the target once in the gateway's `path_of`. Rejected alone: the buffer side is the one the review found, and normalizing both in the one comparison keeps a single rule.

### One cancel, one forget, one params step, one server lookup

- Every cancel method calls `cancel_request(language, id)` and then zeroes its own id: the id lives in different records (`CompletionRequest`, `CompletionDocs`, `HoverRequest`, `DefinitionRequest`, `SymbolRequest`, `SignatureRequest`), so the zeroing stays with the caller as `cancel_signature` already does.
- `forget_server(server)` replaces `forget_hover`, `forget_definition`, `forget_signature`, and `forget_symbols`, and calls `forget_completion` (whose resolvers and docs id are its own); `stop` and `crash` call it, so `stop` now forgets the symbols ask too.
- `position_params(path, buffer, cursor)` answers the `textDocument` and `position` hash of completion, hover, definition, and signature; completion adds its `context` to it.
- `running_server(language)` answers the language's server when it runs, else nil, for the six sends.

### Why the anchored sends keep a body each

`send_hover` and `send_definition` still differ only by their record, its offer predicate, and the method name. One helper over both records would type its record parameter once for the whole program (`docs/spinel-notes.md`, Types), as `untyped`, widening every call on it; with the steps above shared, what stays per record is the three-line replace-or-overdue check and four field writes. A shared anchor record in the domain would remove it and is left out: it changes `HoverRequest`, `DefinitionRequest`, their use cases, and their tests, more than one reviewable fix.

## Risks / Trade-offs

- `cancel_symbols` gains the id-0 guard of `cancel_request`; it is called only when an id is in flight, so nothing changes.
- `stop` forgetting the symbols ask is a behavior change on the quit path only; the editor exits after it, and the row checks the ask is cleared.
