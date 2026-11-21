feat(cmdline): complete command names and paths with tab

## Summary

Adds Tab completion at the `:` prompt: Tab completes an ex command name at the start of the line, or a file or directory path after `:e`, `:w`, `:sp`, `:vs`, and `:tabe`, and shows the matches in a popup menu above the command line, as Neovim 0.10 does with `wildoptions=pum`. Without it every path was typed letter by letter, since `keymap.cmdline` bound no Tab; this is part 2 of the command-line editing decision, after the command-line cursor of pull request 281.

---

## Changes

- Add `CompleteCommandLine`, which completes command names from the registered ex commands in their precedence order and paths relative to the working directory through the file port, directories ending in `/`, a path outside the working directory only when typed from `/`, `../`, or `~/`, and dot files only for a typed leading dot.
- Add the completion popup above the command line in `Pmenu`, `PmenuSel`, and `PmenuMatch`, at most 10 rows around the selection, with a `No matches  Esc close` empty state; Tab and Shift-Tab insert the next or previous match at the cursor and cycle back to the typed text.
- Add `Domain::CmdlineMenu` and `CloseCmdlineMenu`: a key that changes the line closes the menu keeping the line, and Esc closes the menu first and discards the line only on a second press.
- Add the file port request `list_first(dir, limit)`, answered by `DiskFiles` and `MemoryFiles`, so at most 1000 entries (`CompleteCommandLine::MAX_ENTRIES`) are read per directory.
- Add the key Shift-Tab (`Key::SHIFT_TAB`), decoded from `ESC [ Z` and named by key notation.
- Add the keymap lines `keymap.cmdline Tab to cmdline.complete_next` and `keymap.cmdline Shift-Tab to cmdline.complete_previous`, with the generated default configuration current, registered by `CommandLineCompleteHandler`.
- Add the table-driven test `test/editor_cmdline_complete.rb` (command names, a directory, a file, no match, many matches, cycling back, a path with a space, the bounded read, the menu closing) and extend the key decoder, key notation, disk files, and assembly tests.
- Add the `cmdline-tab` benchmark scenario stepping the popup with Tab and Shift-Tab.
- Document the completion in README's command-line section, the `docs/compatibility.md` and `docs/actions.md` rows with the differences from Neovim, the `FilePort` row of `docs/architecture.md`, and the code map.
- Add the four completion scenarios to the `command-line-mode` spec and the Shift-Tab scenario to the `key-input` spec, with the archived OpenSpec change.

---

## Testing

- Run the security review of the committed diff, passed with no finding (high 0, medium 0, low 0).
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass.
- Run the benchmark review, passed: `lh` holds 25.0 objects per key and the `cmdline-tab` popup measures 79.5 objects per key, within the cursor scenario's budget of 100.
- Run `make spec-validate` after the archive, 55 passed and 0 failed.
- Run `make gates` and `make docs-lint` before the push, both pass.

---

## Notes

The `wildmode`, `wildoptions`, `wildmenu`, `wildignore`, and `fileignorecase` options, completion of option names, buffer names, and other arguments, and the menu's Ctrl-N, Ctrl-P, Up, Down, Ctrl-Y, and Ctrl-E are left out; `:r` and `:cd` are not implemented, so they complete nothing. Esc with the menu open keeps the line as shown, where Neovim abandons it. Three findings of the change's own quality review (a repeated menu close, a command-name popup starting at column 3, and the popup's allocations measured but not gated by `make bench-budget`) are recorded in `docs/findings/cmdline-completion.md` for a later change.
