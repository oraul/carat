feat(ex): add the join and shift line commands

## Summary

Adds the Neovim line commands join (`:j`) and the shift-right and shift-left commands (colon followed by a greater-than or less-than sign) with ranges, counts, and the bang of `:j!`, which Carat refused with E492 before. The line commands of sprint 14 also repeated their bang, range, and target prelude, their cursor placement, the report threshold, and the E477 message, and `ExRange.target` answered other errors and a 1-based line beside the rows `resolve` answers. One `LineCommandHandler` base now holds that prelude for every line command, and one address rule in `ExRange` serves both `resolve` and `target`.

---

## Changes

- Add `:[range]j[oin][!] [count]`, joining with Neovim's spacing (none with the bang), the cursor on the first non-blank of the joined line, in one undo step.
- Add the shift-right and shift-left commands with a range and a count, each repeated sign shifting once more, reporting the lines shifted above the report threshold, in one undo step, a bang refused with E477.
- Add a `LineCommandHandler` base holding the bang and range prelude, the target, the count, and the cursor placement for `:d`, `:m`, `:co`, `:t`, `:j`, and both shift commands, with `:m` and `:t` behavior unchanged.
- Move the E477 message and the report threshold into `Domain::Messages` and add `RegisterCount.parse_count` for the count of `:j` and the shift commands.
- Change `ExRange` to classify an unreadable address in one place for `resolve` and `target`, `target` now answering the row the lines are put at.
- Let `ExGrammar` read the greater-than and less-than signs as one-character command names.
- Add table-driven rows for the new commands in `test/editor_line_commands.rb` and for the address rule in `test/domain_ex_range.rb`, `test/domain_ex_grammar.rb`, `test/domain_global.rb`, and `test/use_cases_ex.rb`.
- Document the commands in `docs/compatibility.md`, map area 12 of `docs/codebase-map.md`, `docs/architecture.md` section 5.2, and the README.
- Add the synced `line-commands` spec and the archived OpenSpec change.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding and nothing blocking.
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass.
- Run the quality review, pass with no blocking finding and four advisories.
- Run the benchmark review, pass with nothing blocking.
- Run make spec-validate after the archive, 54 passed and 0 failed.
- Run make gates and make docs-lint on the packaged branch, both pass.

---

## Notes

The flags of `:j` and the shift commands (`l`, `p`, `#`) and `'shiftround'` are out of scope and answer E488 as trailing characters. The four quality advisories are left for follow-up: resolve answering E16 for an implicit offset such as `.5` is recorded in the change's findings with its missing test, while a simplification of how resolve re-words a refusal, the garbled opening sentence of the Substitute section in `docs/compatibility.md`, and the map entries of `Messages` and `RegisterCount` not naming E477, the report threshold, and `parse_count` are wording and style advisories left out of this pull request, since editing them after the recorded check and security review would leave the branch unreviewed.
