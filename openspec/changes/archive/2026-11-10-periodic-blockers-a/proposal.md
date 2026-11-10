# Proposal

## Why

The periodic quality review at 8d8832f was blocked (`blocking=4`). Its one finding marked BLOCKING (`note.58` of the `definitions` run state) is the gateway's request lifecycle copied per request kind, and it names the two backlog entries that hold the copies beside the one it raises; the fourth is the correctness defect the queue names: `gd` misses its own file when the buffer is named `./a.rb` or `lib/../a.rb`, so over a modified buffer it is refused with E37 and over an unmodified one it opens the file a second time.

This change is outside the roadmap of `docs/architecture.md` section 12: it fixes review findings (`docs/queue.md` item 1, `periodic-blockers-a`).

## What Changes

- `VisitTarget` compares the current and listed buffers' paths with a target by their normalized absolute form (`PluginApi::Paths.absolute`), so a buffer named with `.` or `..` segments or a doubled slash is the target's file: `gd` moves the cursor in it, modified or not, and no second buffer opens.
- `JsonRpcLanguageGateway` cancels every request kind through its one `cancel_request(language, id)` (completion, resolve, hover, definition, symbols, signature).
- The gateway forgets a stopped or crashed server's asks in one step, `forget_server`, for completion, hover, definition, signature, and symbols alike; `stop` used to skip the symbols ask, so a winbar request in flight to a stopped server was kept until its deadline.
- The gateway builds the document and cursor position params of completion, hover, definition, and signature in one `position_params`, and finds a running server in one `running_server`.
- `docs/backlog.md`: three entries removed ("The gateway cancels a request in five copies", "The signature gateway copies the hover forget and position steps", "gd misses its own file under a relative or dotted name"), and "The definition ask copies the hover ask in the gateway" narrowed to the two sends that keep a body each, with the Spinel reason and the shared domain anchor record as its outline.

## Out of scope

- The domain records: `DefinitionRequest` repeating `HoverRequest`'s anchor fields stays (see design: a shared send over two record classes needs an `untyped` parameter in Spinel).
- Normalizing the URI the gateway sends for a buffer named with dot segments; servers resolve it, and the comparison is on the editor's side.
- The blocking findings of the periodic reviews at 186ddfb and 2f54bb5 (queue item `periodic-blockers-b`).

## Impact

- `carat/use_cases/definitions/visit_target.rb`, `carat/adapters/json_rpc_language_gateway.rb`.
- `test/adapters_definitions.rb` (rows for both spellings), `test/editor_breadcrumbs.rb` (the stop row), with their snapshots.
- `openspec/specs/definitions/spec.md`: the gd requirement names the same-file match by normalized path.
- `docs/codebase-map.md`: the gateway entry names the shared steps.
- README.md: unchanged, no key, command, option, or target changes; the fix makes `gd` behave as documented.
- docs/architecture.md: unchanged, the definitions use cases and the gateway keep their roles and ports.

## Assumptions

- The review's result names only one finding BLOCKING; the four entries are read as the three backlog entries `note.58` names or raises (the cancel copies, the signature forget and position copies, the definition ask copies) and the `gd` path defect the queue names, which matches the queue's "gateway request lifecycle copied" and "a correctness defect".
- The cancel through `cancel_request` keeps every existing row unchanged; `cancel_symbols` gains the id-0 guard, harmless since it is called only with a request in flight.
