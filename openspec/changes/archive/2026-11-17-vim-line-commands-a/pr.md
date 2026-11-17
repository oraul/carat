feat(ex): add the move, copy, and t line commands

## Summary

Adds the ex commands :m (move), :co (copy), and its synonym :t, which put the lines of a range below a target address as one undo step, so :g can now move or copy the lines it marks. Users asked for these commands, and the compatibility table listed them as missing, which blocked common Neovim idioms such as :g/x/m0.

---

## Changes

- Add MoveCommandHandler for :m[ove], which moves the range (the cursor line without one) below the target, puts the cursor on the last moved line, reports N lines moved above two lines, and refuses a move into its own range with E134
- Add CopyCommandHandler for :co[py] and :t, which puts a copy of the range below the target, puts the cursor on the last copied line, and reports N more lines above two lines
- Add ExRange.target, which reads the one target address (a line number, ., $, or a visual mark, 0 meaning above the first line) and refuses a missing, out-of-range, or unreadable address with E16
- Register both handlers in EditorAssembly in the order of docs/compatibility.md, after :mes[sages] and before the plugin commands
- Add the table-driven test test/editor_line_commands.rb covering :2m0, :1,3m$, :t., :co0, :g/x/m0, undo, E134, E16, and E477, plus ExRange.target rows and spelling rows in the ex use case test
- Add the line-commands spec requirements for :m, :co, and :t and archive the OpenSpec change
- Document the commands in docs/compatibility.md (new rows and the updated Global section sentence), README.md, docs/architecture.md section 5.2, and docs/codebase-map.md
- Record the feature lane's queue and metrics history row

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding
- Run the quality review, pass with no blocking finding and three advisories, and the benchmark review, pass with no blocking finding
- Run the checker's stages (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass
- Run make spec-validate after the archive, 53 items pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

Offsets, patterns, and marks other than the visual ones as a target address answer Not implemented, as the ranges already do, and flags after the address are left out; part b of the request follows in its own change. The move and copy handlers repeat the same bang, range, and target preamble and cursor placement; folding them into one handler holding the variant is left for a later tidy-up, since it changes no behavior.
