feat(status-bar): draw the folder and the server state in the quiet group

## Summary

Draws the status bar's folder segment and the language server's state as the design asks: the file's folder is quiet text, the server is its name and one dot, and the progress bar's undone cells and percent are quiet too. The bar showed the whole path as one bold run, spelled the server state in words, and left the progress bar's undone cells and percent bold beside quiet neighbours, against section 8 of the design.

---

## Changes

- Draw the folder of the file's path in the quiet StatusLineDim group and its last segment in StatusLine, leaving a path with no folder, the root, a scratch title, and no-name buffers as one run
- Draw the server slot as its name in StatusLineDim followed by one dot in the state's group, replacing the words starting, indexing, and stopped, and keep the crash and untrusted-directory commands after the dot
- Draw the progress bar's undone cells and the percent in StatusLineDim, leaving the done cells, title, file, and position as they were
- Add StatusSlots.hint for the command a state names, which the label reuses
- Update the status-bar and language-server specs, README.md, docs/compatibility.md, and docs/codebase-map.md for the new segments
- Extend test/adapters_status_bar.rb with a case per scenario, including each state's hint and the plain bar under NO_COLOR, and refresh the language server snapshots the dot changes

---

## Testing

- Run the pre-push check stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics) at the head, all pass
- Run the security review of the committed diff, pass with no High, Medium, or Low findings
- Run the benchmark review, pass with no blocking finding
- Run spec-validate after archiving the change, all 56 items pass
- Run the quality review of the diff, one finding fixed with a test and one recorded in the findings file

---

## Notes

The visual indicator, the message mode and more groups, and the terminal-byte proof of NO_COLOR and 16 colors are left for the next UI groups change. The dot reuses the modified icon, so no icon name is added, and NO_COLOR keeps the groups as before, so the driver is unchanged.
