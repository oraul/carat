# Proposal

## Why

The user reported, again after #96 and with a target inside the project, that every `gd` adds a buffer tab: from `a.rb`, `gd` into `b.rb` opens a tab for `b.rb` and keeps the one for `a.rb`, so the tab row fills with files the user only passed through (the "ghost" tab). This is Vim's behavior, every opened file staying a listed buffer, but the user decided that a jump takes over the tab of the buffer it leaves. This change is Part 1 of the user's brief (`tmp/briefs/gd-replace-tab.md`); Parts 2 (a jump list per window, buffer switches and jump motions in it, `Ctrl-^`) and 3 (`gt` and `gT` through the buffer tabs) are queued right after it by the planner. It is outside the roadmap of `docs/architecture.md` section 12: it fixes the delivered `definitions` and `jump-list` items.

## What Changes

- A jump (`gd` with one target, a definition picked from the pick list, `Ctrl-O`, and `Ctrl-I`) to a buffer that has no tab shows the target in the tab of the buffer it leaves, at the same position in the tab row, and the buffer left becomes unlisted: still loaded, with its cursor, undo history, and language server sync, in the jump list, but with no tab.
- A jump to a buffer that already has a tab selects that tab and changes no other. The buffer left keeps its tab when another window shows it or when it is modified (a jump from a modified buffer is already refused with E37); only the buffer the jump leaves can lose its tab, so buffers opened with `:e`, `:b`, the finder, or the explorer keep theirs.
- `Ctrl-O` back to the buffer left gives it its tab again by the same rule, so going back and forth never grows or shrinks the tab row.
- An unlisted buffer is Neovim's: `:ls` hides it, `:ls!` shows it with `u` in the first flag column (and `u` filters it), `:bn`, `:bp`, and `:bd`'s replacement skip it, and `:e`, `:b N`, or any other open of it lists it again.
- A new option `option.jumptab` takes `replace` (the shipped default, the user's choice) or `keep` (Vim's behavior: every jumped-to file adds a tab, as before), with the message `file:line: unknown jumptab mode WORD` for any other word.
- The outside-target behavior of #96 (a listed read-only file buffer) keeps working under both settings; under `replace` the read-only buffer takes over the tab like any other target.

Assumptions:

- A boolean `listed` member of `Buffer`, named after Neovim's `'buflisted'`, true by default, is the simplest shape: the unlisted buffer stays in the buffer list's array, so it keeps its number, its jump list entries find it by id, and the language server, `:wa`, and the rename and delete of a path keep seeing it as a loaded buffer; only the tab row, `:ls`, and the buffer stepping ask whether a buffer has a tab.
- `Options.new` keeps Vim's behavior (`keep`), as its other fields keep Vim's defaults; the shipped `config/default.caratrc` sets `replace`.
- A target that already had a tab is moved nowhere, and when the buffer left keeps its tab (another window, modified, scratch) the target is listed at the end, as before.
- `Ctrl-^`, `:e #`, and the `#` alternate flag of `:ls` are Part 2's; `gt`, `gT`, `[b`, `]b` are Part 3's. The Neovim keys of the brief's section "Every Neovim way keeps working" that carat has today (`:bn`, `:bp`, `:b N`, `:ls`, `:tabnext`, `:tabprevious`, Ctrl-O, Ctrl-I, `<leader>bn`, `<leader>bp`) keep working as before; an unlisted buffer is reached by `:b N` as in Neovim.

Out of scope: Part 2 and Part 3 of the brief (queued by the planner), `Ctrl-W gd` (queued as `definition-tab`), `:set jumptab` (the option is read from `option.*` lines only, as `breadcrumbs`), `:badd`, `:bunload`, `:bwipeout`, and an unlisted buffer in a plugin's view of the buffers.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `definitions`: a jump to a buffer with no tab takes over the tab of the buffer it leaves under `option.jumptab replace`; the target-has-a-tab requirement holds under `keep`.
- `jump-list`: `Ctrl-O` and `Ctrl-I` follow the same tab rule.
- `buffer-list`: a buffer a jump leaves is unlisted, hidden by `:ls` and the buffer stepping, shown by `:ls!` with `u`, and listed again when opened.

## Impact

- `carat/domain/buffer.rb` (the `listed` member and `tabless?`), `carat/domain/buffer_list.rb` (`hand_tab`, relisting in `add`, the stepping and counting skip unlisted buffers), `carat/domain/options.rb` (`jumptab`), `carat/use_cases/definitions/visit_target.rb`, `carat/use_cases/definitions/walk_jumps.rb`, `carat/use_cases/buffers/list_buffers.rb`, `carat/adapters/tab_bar.rb`; `config/default.caratrc` and its generated mirror.
- Tests: `test/adapters_definitions.rb`, `test/domain_options_config.rb`.
- `docs/compatibility.md`: the `gd`, `<C-o>`, `<C-i>`, and `:ls` rows and an `option.jumptab` row; `docs/codebase-map.md`: the `VisitTarget` and `BufferList` lines.
- README.md: changed, the `gd` sentence and the option list name `option.jumptab`.
- docs/architecture.md: unchanged, no layer, port, module name, or roadmap item changes, and its Scopes paragraph already sends Carat's own options to `docs/compatibility.md` for their values (the file is 3 bytes under its budget).
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
