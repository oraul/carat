feat(ex): add :normal and :p

## Summary

Adds the `:normal` and `:p` ex commands as Neovim runs them, alone, with a range, and inside a `:g`, so `:g/x/normal Ax` and `:g/x/p` work where Carat answered E492. They are the commands a global most often runs besides `:s` and `:d`, and the change also tidies the sprint-16 review's findings on part b of the line commands.

---

## Changes

- Add `:[range]norm[al][!] {commands}`, which runs its argument as keys typed in normal mode once at the cursor or once per line of the range from column 0, ends an unfinished command as Esc would, keeps the keys in one undo step with the command, and refuses with E471 without an argument and E192 past 100 nested calls.
- Add `:[range]p[rint] [count]`, which shows the range, the cursor line, or count lines from the range's end, leaves the cursor on the last line with a jump recorded, and refuses with E749 on an empty buffer, E477 for a bang, and E488 for flags.
- Change a global to show together the lines each `:p` it runs printed, and let the dispatches and `LeaveInsert` that `:normal` keys trigger join the open undo step instead of closing it.
- Fix the remap count so a mapping that runs `:normal` and replays itself still stops at E223 instead of looping, keeping the count across the nested keys.
- Refactor the line commands to place the cursor through `EditorState#clamp_col` and give `ExRange` the count of addresses typed, which `:j` reads instead of re-reading the range text.
- Build `HandleKey` in `EditorAssembly` before the ex handlers are registered, since `:normal` receives it.
- Add table-driven rows for `:normal`, `:{range}normal`, `:g/x/normal`, `:p`, and `:{range}p` to `test/editor_line_commands.rb`, with `ExRange` address-count rows and the updated ex snapshots.
- Document the two commands in `docs/compatibility.md` with the join and shift rows unchanged, fix its garbled range sentence, and add the map entries for `RegisterCount.parse_count`, `Registers.unnamed?`, and `Buffer#transaction_size` with the new handlers.
- Sync the `line-commands` and `global` specs and update the README and `docs/architecture.md` section 5.2.

---

## Testing

- Run the security review of the committed diff in every review round, the last at the head after the main merge and the :g fix, pass with 0 high, 0 medium, and 0 low findings.
- Run the quality review over four rounds, its blocking findings fixed in place (the recursive remap count; the trailing blanks, undo states, and last change of :normal; the trailing blanks of a :normal that :g runs), the last round passing with 0 blocking findings, its advisories recorded in `docs/findings/vim-line-commands-c.md`.
- Run the checker's stages docs-lint, dev-build, test-build, test-run, diagnose, tools-test, bench-budget, gates, and metrics, all pass.
- Run the benchmark comparison against main's recorded figures, pass with no allocation or round increase.
- Run `make spec-validate` after the archive, 54 of 54 pass.

---

## Notes

`:normal!` runs the same keys as `:normal`, since every Carat key is a keymap binding; `:normal` reading a bar, the `l` and `#` flags of `:p`, and the related `:P`, `:l`, `:nu`, and `:#` commands are left for later. The nesting limit is fixed at 100 rather than read from an option. Six non-blocking review findings, among them the quadratic copy of printed lines in a global and the per-key follow cost of `:normal`, are recorded in `docs/findings/vim-line-commands-c.md`.
