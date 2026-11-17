## Why

Carat has no `:m[ove]`, `:co[py]`, or `:t` (`docs/compatibility.md`, the Global section's differences), so lines cannot be moved or copied by address and `:g` cannot move or copy the lines it marks. `docs/architecture.md` section 5.2 lists `m t` among the planned ex commands; this change is part a of the `vim-line-commands` user request in `docs/queue-feature.md` (Sprint 14 item 1), outside the numbered roadmap items of section 12, which are delivered.

## What Changes

- `:[range]m[ove] {address}` moves the lines of the range (the cursor line without one) below the line the address names, `0` meaning above the first line; the cursor goes to the last moved line, keeping the wanted column, as Neovim does with `nostartofline`; above two lines the message is `N lines moved`.
- `:[range]co[py] {address}` and its synonym `:[range]t {address}` put a copy of the lines below the line the address names; the cursor goes to the last copied line; above two lines the message is `N more lines`.
- The address is one a range takes: a line number, `.`, `$`, `'<`, or `'>`. A missing address, one past the last line, or text that is not an address is `E16: Invalid range`; an offset (`+`, `-`), a pattern, or another mark answers `Not implemented: address x`, as the ranges do. A move into its own range is `E134: Cannot move a range of lines into itself`; a move to just above or below its own range changes nothing. A bang is `E477: No ! allowed`.
- Each is one undo step, and inside `:g` each runs on the marked line, so `:g/x/m0` reverses the order of the lines holding `x` at the top of the buffer.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `line-commands`: adds `:m[ove]`, `:co[py]`, and `:t`.

## Impact

- Domain: `ExRange.target`, the one address a target takes, with its refusals.
- Use cases: new `MoveCommandHandler` (`m[ove]`) and `CopyCommandHandler` (`co[py]`, `t`) under `use_cases/ex/`, each editing through `Buffer#set_lines` inside the command line's transaction; registered after `:mes[sages]`, before the plugin commands, in the order of `docs/compatibility.md` (no core command shares their abbreviations).
- Adapters: `EditorAssembly` requires and registers the two handlers; `carat.rb` requires them.
- Tests: new `test/editor_line_commands.rb`, a table over the editor; `test/use_cases_ex.rb` spelling rows.
- Docs: `docs/compatibility.md` rows and the Global section's sentence, `docs/codebase-map.md` area 12, `docs/architecture.md` section 5.2 (`m t` move from planned to registered).
- README.md: unchanged, it names no ex command list that `:m` or `:t` would join.
- Out of scope: part b of the request (`:normal`, `:p`, or what `docs/queue-feature.md` names for it); offsets in addresses (`:m+1`, `:t-2`), patterns, and marks other than `'<` and `'>` as the target; flags after the address (`:t. l`); Vim's totals after a global.
- Assumptions: the cursor column after `:m` and `:t` is the wanted column clamped to the line, as Neovim's default `nostartofline` gives it (`beginline(BL_SOL | BL_FIX)`); text after the address is `E16`, where Neovim may report `E488`; the messages follow Carat's fixed `'report'` of 2.
