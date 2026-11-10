# Proposal

## Why

The user reported, with the replace-jump bug of #98, that Ctrl-O does not take them back to the previous file. The jump list is one for the editor and only `gd` adds to it (`docs/compatibility.md`, the `<C-o>` row), so after `:e`, `:b`, `:bn`, `:bp`, the finder, the explorer, or the buffer keys (`<leader>bn`, `<leader>bp`) Ctrl-O does nothing, where Neovim keeps one list per window and records the position left by every buffer switch. This change is part 2a of the user's brief (`tmp/briefs/gd-replace-tab.md`, Part 2), queue item 1 `jump-list`; the planner moved the alternate file (`Ctrl-^`, `Ctrl-6`, `:e #`) into `jump-motions` with the jump motions. It also closes the gap #98 left: under `option.jumptab replace`, Ctrl-O back to a scratch buffer still shown in another window unlists the file buffer it leaves. It is outside the roadmap of `docs/architecture.md` section 12: it fixes the delivered `jump-list` item.

## What Changes

- Each window keeps its own jump list, with Neovim's limit of 100 entries and its rule of dropping an older entry on the same line; a new window (a split, `:new`, `:vnew`, a new tab page) starts with a copy of the list of the window it was opened from, as Neovim's `win_init` copies it.
- Every buffer switch records the position left in the window's list: `:e`, `:b N`, `:bn`, `:bp`, `:bN`, the new `:bfirst` and `:blast`, the buffer keys, the finder's and the explorer's opens, and `gd`, so Ctrl-O returns to the previous file at its cursor and Ctrl-I comes forward again. Ctrl-O and Ctrl-I themselves, `:bd`'s replacement, and a window that closes record nothing, as in Neovim.
- A file opened over the empty startup buffer records nothing, since that buffer leaves the list and its number goes to the file.
- Ctrl-O back to a buffer a jump left without its tab gives it the tab again, also when buffer switches came between (the existing tab rule, now reached through the window's list).
- A walk back to a scratch buffer never takes the tab of the file buffer it leaves (#98).
- Ctrl-O on an empty list leaves the list empty, so Ctrl-I has nothing to reach (the backlog's `JumpList#step` entry).
- `:bf[irst]`, `:br[ewind]`, and `:bl[ast]` show the first and the last listed file buffer, as Neovim does, honoring the brief's section "Every Neovim way keeps working".
- The rule for when a jump takes over a tab lives in one predicate, `Options#jump_takes_tab?`, instead of two copies of the option test.

Assumptions:

- The list is a member of the `Window` record, so it lives and dies with the window and a split copies it with the rest of the view; the editor-wide `EditorAssembly#jumps` reader goes away, and `VisitTarget` and `WalkJumps` read the current window's list.
- A switch records through one `BufferList` method beside `load`, used by `OpenFile` and `SwitchBuffer`, so the finder, the explorer, `:sp file`, and `:tabedit file` (all through `OpenFile`) record too; `gd`'s own push stays for a target in the same file, and its push after `OpenFile`'s is the same entry, which the duplicate rule keeps once.
- A scratch buffer's position is recorded like any other, as Neovim does; an entry whose buffer is gone is dropped by the walk, as today.
- `:bfirst` and `:blast` take no count and a bang as `:bn` does; `:brewind` is `:bfirst`'s Neovim alias.

Out of scope: the alternate file (`Ctrl-^`, `Ctrl-6`, `:e #`, the `#` flag of `:ls`) and the jump motions (`G`, `gg`, searches, `%`, and the rest), both queue item `jump-motions`; `:jumps` and `:clearjumps`; `gt`, `gT`, `[b`, `]b`, `[B`, `]B`, and the tab page keys (queue item `tab-keys`); `Ctrl-W gd` (`definition-tab`).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `jump-list`: one list per window, copied by a new window; every buffer switch records the position left; Ctrl-O on an empty list adds nothing; a walk back to a scratch buffer keeps the file's tab.
- `buffer-list`: `:bfirst`, `:brewind`, and `:blast`.

## Impact

- `carat/domain/window.rb` (the `jumps` member, copied by `copy_from`), `carat/domain/jump_list.rb` (`step`'s bounds check first), `carat/domain/buffer_list.rb` (`enter`, `first_file`, `last_file`, `hand_tab`'s scratch guard), `carat/domain/options.rb` (`jump_takes_tab?`), `carat/use_cases/files/open_file.rb`, `carat/use_cases/buffers/switch_buffer.rb`, `carat/use_cases/buffers/buffer_request.rb`, `carat/use_cases/ex/buffer_command_handler.rb`, `carat/use_cases/windows/open_tab.rb`, `carat/use_cases/definitions/visit_target.rb`, `carat/use_cases/definitions/walk_jumps.rb`, `carat/adapters/editor_assembly.rb`, `carat.rb` (the jump list before the window).
- Tests: a new `test/editor_jumps.rb`; `test/domain_jump_list.rb`, `test/adapters_definitions.rb`, `test/adapters_assembly.rb`, `test/editor_buffers.rb`.
- `docs/compatibility.md`: the `<C-o>`, `<C-i>`, and `option.jumptab` rows, `:bfirst` and `:blast` rows; `docs/codebase-map.md`: the jump list, window, and buffer list lines and the new test; `docs/backlog.md`: the four fixed entries removed, owners moved.
- README.md: changed, the jump list sentence says each window keeps one that every buffer switch adds to.
- docs/architecture.md: changed, the Options list names `jumptab` and `winborder` (the backlog entry), with prose trimmed to stay under its budget.
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
