# Backlog: carat/domain/json.rb

## Json.pretty_generate has no production caller

- Where: `carat/domain/json.rb` line 36 at c1b3a12, called only by `test/json.rb` (periodic quality). Queued in item 46, dead methods.
- Why it matters: dead code the map lists as part of the JSON-RPC library.
- Fix outline: remove it and its test row, or record why the library keeps it.
- Also: test/json.rb
- Category: editor
- Added: 2026-11-09

### The language gateway's and SymbolOutline's untyped reads have no item

- Location: `carat/domain/json.rb:53` (`Json.field`, `element`, `reach`), `carat/adapters/json_rpc_language_gateway.rb`, `carat/adapters/symbol_outline.rb`, `docs/spinel-notes.md:47` (sprint-5 quality review).
- Why it matters: the typed readers serve the language-server tests (about 68 calls, 1,181 to 779 rebuilds), but the gateway's 210 untyped reads and SymbolOutline's 18 stay, as the Spinel notes list them.
- Fix outline: move the gateway's and SymbolOutline's reads onto the readers, accepted with a lower `SP_TIMING` rebuild count at the pin. Queue item `spinel-workarounds`.
- Also: carat/adapters/json_rpc_language_gateway.rb, carat/adapters/symbol_outline.rb, docs/spinel-notes.md
- Category: editor
- Added: 2026-11-15

### Json repeats the plain byte predicate (sprint-16 sweep quality)

- Location: carat/domain/json.rb:469 (Writer#plain?, Parser#ascii_text?, write_string inline).
- Why: one predicate in three spellings.
- Fix outline: one module-level Json.plain_byte? used by all.
- Category: editor
- Added: 2026-11-18
