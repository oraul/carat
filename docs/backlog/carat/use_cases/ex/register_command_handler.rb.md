# Backlog: carat/use_cases/ex/register_command_handler.rb

## :registers cuts wide text by characters

- Where: `carat/use_cases/ex/register_command_handler.rb` line 70, at 5e4c140; `test/editor_registers.rb` has no wide-text row. Periodic quality. Queue item `buffer-list-tidy`.
- Why it matters: a register of wide characters runs to twice the screen width, the mistake `palette-pad-crash` fixed in the palette.
- Fix outline: cut with `Domain::DisplayWidth.cut` and count down by `DisplayWidth.text_width`, with a wide-register row.
- Also: test/editor_registers.rb
- Category: editor
- Added: 2026-11-09

### RegisterCommandHandler compares entry kinds by hand
- Location: carat/use_cases/ex/register_command_handler.rb:112
- Why: compares kind with :linewise and :blockwise though RegisterEntry has linewise? and blockwise?. Folded into ex-handlers-tidy.
- Fix: use the predicates.
- Category: editor
- Added: 2026-11-17

### RegisterCommandHandler re-implements RegisterEntry#lines

- Location: carat/use_cases/ex/register_command_handler.rb:61, :58 (sweep, quality).
- Why: TextLines.split with an empty fallback copies RegisterEntry#lines; :58 compares kind where linewise? and blockwise? exist.
- Fix outline: parts = entry.lines and the predicates.
- Category: editor
- Added: 2026-11-17
