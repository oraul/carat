# Proposal

## Why

The user reported that Ctrl-O does nothing after a search or a `G`: only `gd` and buffer switches add to the window's jump list (`docs/compatibility.md`, the `<C-o>` row, "here do not yet"), where in Neovim `G`, `gg`, `/`, `?`, `n`, `N`, `*`, `#`, `%`, `(`, `)`, `{`, `}`, `H`, `M`, `L`, and `:N` each add the position left. No alternate file exists either, so `Ctrl-^`, `Ctrl-6`, and `:e #` reach nothing. This is queue item `jump-motions` (part 2b of the user's jump brief, the backlog heading "Only gd and buffer switches add to the jump list"). It is outside the roadmap of `docs/architecture.md` section 12: it completes the delivered `jump-list` item.

## What Changes

- Each jump form adds one entry for the position left to the window's jump list, as in Neovim: `G`, `gg`, `(`, `)`, `{`, `}`, `H`, `M`, `L`, `%` (with or without a count), `/`, `?`, `n`, `N`, `*`, `#`, `g*`, `g#`, and a range alone (`:N`, `:$`). The entry is added only when the motion or search succeeds, also in the visual modes and under an operator, as Neovim's `setpcmark` does.
- `%` goes to the bracket matching the first `(`, `[`, `{`, `)`, `]`, or `}` at or after the cursor on its line, across lines, inclusive; `{count}%` goes to the line at count percent of the buffer, keeping the wanted column as `G` does. It is bound in `normal`, `operator_pending`, and the three visual modes.
- Each window remembers its alternate buffer, the buffer it showed before the current one (Neovim's `w_alt_fnum`), set by every buffer switch in it and copied by a split and a new tab page with the jump list.
- `Ctrl-^` (and `Ctrl-6`, which terminals send as the same code) shows the window's alternate buffer as `:b N` does, `{count}Ctrl-^` buffer count; `E23: No alternate file` without one.
- `:e #` edits the alternate buffer's file as `:e name` does; `E194` without an alternate, `E499` for one with no name.
- `<C-6>` is read as Ctrl-^ in key notation, and code 30 is spelled `<C-^>` (it showed `<C-~>`), so the key hints show the binding.
- The `<C-o>` row of `docs/compatibility.md` loses "only gd adds" and lists the jump forms.

Assumptions:

- `%` did not exist (no action, binding, or row), so the acceptance's `%` row needs the motion itself: the bracket pairs and the count form only, without `matchpairs`, the C comment and `#if` items, or Vim's skipping of brackets inside quotes, each named in the Differences line.
- An entry is recorded only for a numbered buffer, as a buffer switch records none for the startup buffer, whose number 0 no walk can find.
- A search under an operator and in a visual mode records like a plain one, as Neovim does.
- `Ctrl-^` refuses a modified current file buffer with `E37` without a bang, as `:b N` does here.
- `Ctrl-^` shows no file message, as `:b N` shows none here; `:e #` shows `:e`'s.

Out of scope, named for a later change: the `#` and `%` flags of `:ls` and `#` anywhere but `:e #` (`:sp #`, `#N`, `:b #`); marks and `'`, `` ` ``; `[[`, `]]`, `:s`, and `:tag` as jumps; `:jumps`, `:clearjumps`; moving `jump.older` and `jump.newer` out of `DefinitionHandler`, which the backlog entry's outline also suggests.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `jump-list`: the jump forms add the position left; the window's alternate buffer, `Ctrl-^`, `Ctrl-6`, and `:e #`.
- `motions`: the `%` motion.

## Impact

- `carat/domain/motions.rb` (`%`, the jump names), `carat/domain/window.rb` (`alternate`, `record_jump`), `carat/domain/buffer_list.rb` (`load` sets the alternate, `alternate_of`), `carat/domain/key_notation.rb` (`<C-6>`, `<C-^>`), `carat/use_cases/move.rb`, `carat/use_cases/operate.rb`, `carat/use_cases/search/jump_to_match.rb`, `carat/use_cases/ex/execute_ex.rb`, `carat/use_cases/buffers/switch_buffer.rb`, `carat/use_cases/actions/buffer_handler.rb`, `carat/use_cases/ex/file_command_handler.rb`, `carat/use_cases/windows/open_tab.rb`, `carat/adapters/editor_assembly.rb`, `config/default.caratrc` and the generated `carat/domain/default_config.rb`.
- Tests: `test/editor_jumps.rb` (the jump forms and the alternate file), `test/editor_motions.rb` (`%`), `test/domain_keys.rb`.
- `docs/compatibility.md` (rows for `%`, `Ctrl-^`, `:e #`, the `<C-o>` row, the Differences lines), `docs/actions.md` (`motion.match_pair`, `buffer.alternate`), `docs/codebase-map.md` (area 11's tests).
- README.md: changed, the jump list sentence names the jump motions and `Ctrl-^`.
- docs/architecture.md: changed, the `Window` entry names the alternate buffer.
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
