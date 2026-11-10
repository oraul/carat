# Proposal

## Why

The language server knows where every Ruby symbol is defined, but carat cannot ask it: there is no `gd`, no way to look at a definition without leaving the buffer, and no jump list to come back with Ctrl-O. Go-to-definition is the one part of roadmap item 10, `language-services`, in `docs/architecture.md` section 12 that is not delivered ("Delivered but go-to-definition"), and it is the user's next request (docs/queue.md, definitions).

## What Changes

- `gd` in normal mode asks the buffer's running language server for the definition at the cursor (`textDocument/definition`), without waiting: the answer is read at the next idle moment. One target jumps there: the target file opens in the current window (the current buffer when it is the same file) with the cursor on the target, after the position left is added to the jump list.
- `<leader>dd` (Space d d) asks the same and shows the target's source in a bordered float below the cursor, at most 12 rows from the target line, titled with the path and line, highlighted as its file type; the cursor stays in the buffer; Esc or a cursor move closes it.
- Several targets open a pick list: an entered float of numbered rows `N path:line`, at most 50; Enter on a row goes to (or peeks) that target and closes the list; Esc closes it.
- No path or no running server of the buffer's file type advertising `definitionProvider`: the message row reads Neovim's `method textDocument/definition is not supported by any of the servers registered for the current buffer`, and nothing is asked. An empty, null, or error answer, or one with no `file:` target: `No locations found`.
- Requests are asynchronous and stale ones dropped: one request in flight, cancelled with `$/cancelRequest` by a newer ask or after two seconds unanswered; an answer is used only when the cursor, window, buffer, and normal mode are still where it was asked and no newer ask was made since it was sent.
- Targets are file URIs only. A target inside the project (the working directory, every link resolved) opens through the `:e` path with its refusals (a directory, a device, a FIFO, a file over 64 MiB). A target outside the project, or one whose path leaves it through a link, opens read-only: as a scratch view of the file's text titled with its path, which `:w` refuses as it refuses every scratch buffer. Peek reads at most 8 MiB and shows any regular file read-only. A modified current file buffer refuses a jump to another file with E37, as `:e` does.
- The jump list: `gd` adds the position it leaves; Ctrl-O goes to the older entry and Ctrl-I (Tab) to the newer, with a count, across buffers, refusing a buffer switch with E37 when the current file buffer is modified; at the newest end Ctrl-O first records the current position so Ctrl-I comes back. At most 100 entries; an entry on the same buffer line as a new one is replaced; an entry whose buffer is gone is dropped.
- New bindings `keymap.normal gd definition.jump`, `keymap.normal <leader>dd definition.peek`, `keymap.normal <C-o> jump.older`, `keymap.normal <C-i> jump.newer`; the pick list's Enter is `keymap.pick <CR> definition.choose`, a new `keymap.pick` line kind bound only in the pick list's scratch buffer. No cost per key while no peek float or pick list shows.

Out of scope: other jump commands adding to the jump list (`G`, `gg`, searches, `%`, marks; listed in `docs/backlog.md`), a per-window jump list and `:jumps`, `gD` and Vim's local-declaration `gd` without a server, declaration, type definition, implementation, and references requests, a quickfix list, and showing each target's line text in the pick list.

Assumptions: the jump list is one list for the editor, not one per window; the peek float closes on a cursor move like the hover float; the pick list lists targets in the server's order; a read-only view of a file outside the project is dropped when no window shows it, so Ctrl-I to it afterwards skips it.

## Capabilities

### New Capabilities

- `definitions`: `gd`, the peek float, the pick list, the messages, the asynchronous and stale-request rules, and the path rules for targets.
- `jump-list`: the list `gd` adds to, Ctrl-O and Ctrl-I.

### Modified Capabilities

None.

## Impact

- New: `carat/domain/definition_request.rb` (`DefinitionRequest`), `carat/domain/jump_list.rb` (`JumpList`), `carat/use_cases/definitions/request_definition.rb`, `show_definition.rb`, `visit_target.rb`, `choose_definition.rb`, `follow_definition.rb`, `carat/use_cases/definitions/walk_jumps.rb`, `carat/use_cases/actions/definition_handler.rb`, `test/adapters_definitions.rb`, `test/domain_jump_list.rb`.
- Changed: `JsonRpcLanguageGateway` (the request, its cancel, the answer, the capability), `InputController` (shows an arrived answer at the idle tick), `HandleKey` (follows the floats), `EditorAssembly`, `carat.rb`, `config/default.caratrc` and its generated mirror, `test/adapters_assembly.rb`, `test/runner/run_all.rb`.
- Docs: `docs/actions.md`, `docs/compatibility.md`, `docs/codebase-map.md`, `docs/backlog.md` (the plan notes, the jump commands).
- README.md: changed, the leader keys and the language features list `gd`, the peek, and Ctrl-O and Ctrl-I.
- docs/architecture.md: changed, roadmap item 10 no longer reads "but go-to-definition".
