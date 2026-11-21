feat(cmdline): edit the command line at a cursor

## Summary

Adds a cursor to the command line and the search prompts, so the line can be moved through and edited in the middle, with deletion of a character, a word, or everything before the cursor. The command line only appended and backspaced at its end, so a typo in a long path meant retyping the line; this is the first part of the change, and Tab completion with its popup follows as a separate change.

---

## Changes

- Add a cursor to the command line shared by the `:` line, the search prompts, the palette prompt, and a plugin prompt, with typed text inserting at the cursor and history recall placing it at the end.
- Add cmdline keys for Left, Right, Home and Ctrl-b, End and Ctrl-e, and word movement on Shift or Ctrl with Left and Right, bound under keymap.cmdline in config/default.caratrc.
- Add deletion under the cursor with Del, the word before it with Ctrl-w, and everything before it with Ctrl-u, while Backspace deletes before the cursor and still leaves an empty line.
- Add the keys Shift-Left, Shift-Right, Ctrl-Left, and Ctrl-Right to the decoder and key notation, which a mode that does not bind them resolves as the plain arrow so no other mode changes.
- Change the frame presenter to draw the cursor bar at the display column of the prompt plus the text before the cursor, counting wide characters by their cells.
- Add Domain::CommandLineText for the word arithmetic, the use cases MoveCommandLineCursor and DeleteCommandLineText, and the CommandLineEditHandler with nine cmdline actions.
- Document the keys in README.md, docs/compatibility.md with the differences from Neovim, docs/actions.md, the code map, and the command-line-mode and key-input specs.
- Record the plan, the metrics history, and the findings the review left for later.

---

## Testing

- Run the security review of the committed diff, no High, Medium, or Low findings, none blocking.
- Run the benchmark review, pass with nothing blocking.
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, and metrics, all exit zero.
- Run the quality review of the diff, three findings, two fixed and one recorded in the findings file.

---

## Notes

Tab completion, the popup above the command line, and the bounded directory read are left to the follow-up change cmdline-completion, as are the register insert and the wildmode and wildoptions options. Shift-Left and Shift-Right move by blank-separated word and Ctrl-w deletes by word-character run, as Neovim does. No edit of tools/rules.sh and no file of the backlog lane.
