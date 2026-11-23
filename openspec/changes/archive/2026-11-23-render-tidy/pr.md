fix(render): read a bracketed paste as text and tidy the presenter

## Summary

Turns bracketed paste on while the editor runs and reads a paste as literal text, so pasted Escape and colon characters no longer leave insert mode or open the command line. Before this, a paste arrived as typed keys and could run `:w!` or any other command. The same change tidies the frame presenter, tab bar, and status bar items queued by the sprint reviews.

---

## Changes

- Change the screen presenter to turn bracketed paste on when the screen is entered and off first when it is left.
- Change the key decoder to read the text between the paste marks as codes flagged as pasted, dropping Escape and other control bytes and turning CR, LF, or CRLF into one newline.
- Change the key handler so a pasted code is never looked up in a keymap: insert mode inserts it, the command line takes its printable characters and drops newlines, and other modes ignore it.
- Fix the frame presenter so a row painted after the highlighting budget stopped is painted again with its matches on the next frame.
- Refactor the frame presenter to pass the buffer row, the window's currency, and the number's highlight group as arguments, share one clear for the hit-enter prompt and the start screen, and ask the tab bar through the new showing? method.
- Refactor the status bar to drop an unused require, name the lsp state parameter, and rename the plugin owners index.
- Document the paste in the compatibility table, the code map, and the README, and add the key-input and screen-rendering scenarios to the specs.

---

## Testing

- Run the security review of the committed diff, passed with no blocking finding and one Low finding recorded in the findings file
- Run the benchmark check, passed with no blocking finding
- Run the staged checks docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics at the final code commit, all pass
- Run the quality review of the diff, five findings, two fixed and three recorded
- Run make gates, make docs-lint, and make spec-validate after archiving, all pass

---

## Notes

A paste ends at the first end mark, so a terminal that passes a literal end mark inside pasted text through can still let the bytes after it act as typed keys; this relies on the terminal filtering the mark, is stated in the compatibility document, and a defense in depth is recorded as a finding. Pasted text in normal and the other modes does nothing, where Neovim puts it in. The two decode items of the queue entry and the walk of matches left of the horizontal scroll are left out and recorded in the findings file.
