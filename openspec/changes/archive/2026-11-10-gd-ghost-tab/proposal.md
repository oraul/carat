# Proposal

## Why

The user reported that after `gd` opens its target the tab becomes a ghost (queue item 1, `gd-ghost-tab`). A table-driven reproduction over the editor names two causes. A target outside the working directory, the usual case for a gem or the standard library with ruby-lsp, and a project file whose link leaves the working directory, open as a scratch view owned by `:definitions`; the tab bar draws no tab for a scratch buffer, so after `gd` the window shows a file with no tab, no tab is selected, and the tabs and `:bn` cannot bring it back (with a single file the tab row does not even show). And when the outside file is already open as a listed buffer (`:e /gems/c.rb`), `gd` ignores that buffer and shows a second, scratch copy: the file's tab stays in the row but is never the selected one, a tab that cannot be focused. A target inside the project opens through `OpenFile` and gets its tab, selected, so it has no cause of its own. This change is outside the roadmap of `docs/architecture.md` section 12: it fixes the delivered `definitions` item.

## What Changes

- A target outside the working directory, or linked out of it, opens as a read-only file buffer instead of a scratch view: a listed file buffer named with the target's path (as `:e` would show it), flagged read-only, so it gets a tab that shows, selects (`:bn`, `:bp`, `:b N`), and closes (`:bd`) like the others, stays listed when another buffer is shown, and is synced with the language server like any file buffer of its type, which lets `gd` follow on from it. The open message stays `"path" [readonly] NL, NB`.
- A read-only buffer is never written: `:w`, `:w name`, `:wq`, `:x`, `:wa`, `:wqa`, and the save action refuse it with `E45: 'readonly' option is set`, and no bang overrides it (Neovim's `:w!` does; Carat keeps the definitions design's promise that a server cannot steer the user into writing a file outside the project). Like a Neovim read-only buffer it may be edited, and then counts as unsaved work (E37 and E162 guard it until `:e!`, a bang, or undo).
- A jump to a file outside the project that is already listed shows that buffer, with its unsaved text, instead of reading a second copy.
- `:ls` shows `=` in its fourth flag column for a read-only buffer, and the `=` filter keeps the read-only buffers, as Neovim's do; the listing had no read-only buffer before.

Assumptions:

- A new boolean `readonly` member of `Buffer`, named after Neovim's option, is the simplest shape: the scratch concept bundles "never written" with "no tab, unlisted when hidden, skipped by `:bn` and `:bd`", and splitting those per owner would touch the 51 places that ask `scratch?`; a read-only file buffer gets the tab, the listing, and the buffer commands for free, and only `SaveFile` and `:ls` learn the flag.
- The status line shows no `[RO]` marker yet; the open message says `[readonly]`. Left out to keep the change to the bug.

Out of scope: `Ctrl-W gd` in a new tab page (queued after this item), an `[RO]` status marker, `:set readonly` and `:view`, refusing edits to a read-only buffer (`'modifiable'`), and the backlog entry on decoded control bytes in target paths (owned by `bidi-controls`).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `definitions`: a target outside the project, or linked out of it, opens as a listed read-only file buffer with its tab, never written; an outside file already listed is shown instead of copied.
- `buffer-list`: the fourth flag column of `:ls` and the `=` filter show the read-only buffers.

## Impact

- `carat/domain/buffer.rb` (the `readonly` member), `carat/use_cases/definitions/visit_target.rb`, `carat/use_cases/files/save_file.rb`, `carat/use_cases/buffers/list_buffers.rb`; tests `test/adapters_definitions.rb`.
- `docs/compatibility.md`: the `gd` and `:ls` rows and the differences paragraph; `docs/codebase-map.md`: the `VisitTarget` line.
- README.md: changed, the `gd` sentence says an outside definition opens read-only in its own tab.
- docs/architecture.md: unchanged, no layer, port, module name, or roadmap item changes; the read-only flag is a record member like the others.
- CLAUDE.md: unchanged, no agent, workflow, command, or target changes.
