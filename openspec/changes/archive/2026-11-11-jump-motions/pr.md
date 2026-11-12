fix(motions): record the jump motions and add the alternate buffer

## Summary

Records the position left in the window's jump list for every Neovim jump form (G, gg, searches, sentence and paragraph motions, H, M, L, the new % motion, and a range alone), and adds the window's alternate buffer with Ctrl-^, Ctrl-6, and :e #. Ctrl-O did nothing after a search or a G because only gd and buffer switches added entries, and no alternate file existed, so Ctrl-^ and :e # reached nothing.

---

## Changes

- Fix the jump motions so G, gg, (, ), {, }, H, M, L, %, /, ?, n, N, *, #, g*, g#, and :N add the position left when they succeed, also in the visual modes and under an operator, through a new Window#record_jump.
- Add the % motion, matching the first bracket at or after the cursor across lines, and {count}% going to the line at count percent, bound in normal, operator_pending, and the three visual modes, a delete over it filling register 1 even within one line as in Neovim.
- Add the window's alternate buffer, set by every buffer switch and copied by a split and a new tab page with the jump list.
- Add Ctrl-^ and Ctrl-6 to show the alternate buffer, or buffer count with a count, answering E23 without one and E37 on a modified buffer without a bang.
- Add :e # to edit the alternate buffer's file, answering E194 without an alternate and E499 for one with no name.
- Change the key notation so code 30 reads as C-^ and C-6 is accepted, so the key hints show the binding.
- Add editor_jumps tests covering each jump form, the tab alternate, E499, and searches under an operator, and an editor_registers case for d% filling register 1.
- Document the jump forms, %, and Ctrl-^ in docs/compatibility.md and docs/actions.md, and archive the jump-motions change with its jump-list and motions specs.
- Record the queue, the metrics rows, and the quality advisories of both review rounds in docs/backlog.md.

---

## Testing

- Run the security review of the committed diff, pass with no findings (high 0, medium 0, low 0).
- Run the checker's fast stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run the quality review, pass after two rounds: the first added the three missing tests it flagged as blocking, the second made d% fill register 1.
- Run the benchmark against main's recorded figures, pass with no regression.
- Run make spec-validate after the archive, 51 passed and 0 failed.
- Run make gates and make docs-lint on the packaged branch, all pass.

---

## Notes

The % motion leaves out matchpairs, the C comment and preprocessor items, and Vim's skipping of brackets inside quotes. The # and % flags of :ls, # outside :e #, marks, and :jumps are left for a later change. Three non-blocking advisories go to the backlog: BufferList#enter duplicating the guard of Window#record_jump, Ctrl-^ showing a scratch alternate buffer that :b N refuses with E86, and the :e handler resolving the alternate buffer itself instead of a use case or a BufferList helper.
