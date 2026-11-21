# Proposal

## Why

The command line has no completion: `config/default.caratrc` binds no `<Tab>` under `keymap.cmdline`, so `:e app/models/order.rb` is typed letter by letter (the user's cmdline-editing decision of 2026-11-21, the design council, decision 2). This is the second part of that decision; the cursor of the command line, its first part, merged as #281. It delivers no roadmap item of `docs/architecture.md` section 12: it is a command-line basic the design council put ahead of the remaining waves.

## What Changes

- `<Tab>` at the `:` prompt completes, as Neovim 0.10 does with `wildoptions=pum`: an ex command name when the text before the cursor is only letters, from the registered ex commands in their precedence order; a path after `:e`, `:w`, `:sp`, `:vs`, and `:tabe` (`:r` and `:cd` are not implemented), relative to the working directory, read through the file port, directories ending in `/`, a path outside the working directory only when typed as such (`../`, `/`, `~/`), dot files only when the typed name starts with a dot.
- At most `CompleteCommandLine::MAX_ENTRIES`, 1000, entries are read per directory, through a new file port request `list_first(dir, limit)`, which `DiskFiles` answers with `Dir.open` and `read`, stopping at the limit, and `MemoryFiles` alike.
- The first `<Tab>` inserts the first match at the cursor of #281 in place of the typed word and opens a bordered popup menu above the command line, at the word's column, in `Pmenu`, the inserted match in `PmenuSel`, the typed characters in `PmenuMatch` (`PmenuMatchSel` on the selected row), at most 10 rows around the selection; with no match it reads `No matches  Esc close` and the line is kept. `<Tab>` and `<S-Tab>` cycle through the matches and back to the typed text.
- A key that changes the line or its cursor otherwise (typing, a deletion, a cursor move, Enter) closes the menu, keeping the line as shown; `<Esc>` closes the menu first, keeping the line, and a second `<Esc>` discards the line. `<Tab>` and `<S-Tab>` at the `/`, `?`, palette, or a plugin's prompt do nothing, and `<C-n>` and `<C-p>` keep the palette's meaning.
- A new key `<S-Tab>` (`Key::SHIFT_TAB`), decoded from `ESC [ Z` and named by key notation, which the binding needs.
- Keymap lines `keymap.cmdline <Tab> cmdline.complete_next` and `keymap.cmdline <S-Tab> cmdline.complete_previous`, `make gen-config` current.
- Docs: README's command-line paragraph, `docs/compatibility.md` and `docs/actions.md` rows with the differences from Neovim, the code map.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-line-mode`: ADDED "Tab completes an ex command name", "Tab completes a path after a file command", "The completion menu shows above the command line", and "The completion menu closes before the line".
- `key-input`: ADDED "Shift-Tab is its own key".

## Out of scope

- The `wildmode`, `wildoptions`, `wildmenu`, `wildignore`, and `fileignorecase` options; completion of option names, buffer names, or any argument other than a path; `<C-n>`, `<C-p>`, `<Up>`, `<Down>`, `<C-y>`, and `<C-e>` in the menu; `:r` and `:cd`, which carat does not implement; completion at the search, palette, or plugin prompts.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumptions: `<Esc>` with the menu open keeps the line as shown (the brief: the menu closes first, then the line), where Neovim abandons the line; a path argument is the rest of the line after the command's blanks, spaces included and unescaped, as carat's `:e` reads it; the empty `:` line completes every command name; matching is case-sensitive, as Neovim's default on Linux.

## Impact

- README.md: changed, the command-line paragraph.
- docs/architecture.md: changed, the `FilePort` row of section 6 names `list_first`.
- docs/codebase-map.md: area 12 (the use cases, the handler, the record, the test) and area 17 (the port request).
- docs/compatibility.md and docs/actions.md: the command-line rows and `<S-Tab>`.
- Performance: one comparison per key in `HandleKey#follow` while no menu shows; the popup is built only on `<Tab>`.
