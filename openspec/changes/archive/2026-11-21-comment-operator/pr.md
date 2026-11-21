feat(operators): add the gc comment operator and text object

## Summary

Adds Neovim's built-in comment operator: `gc{motion}`, `[count]gcc`, visual `gc`, and the `gc` text object toggle line comments by the buffer's filetype. Without it `gc` fell through the grammar, the `g` was dropped and the next `c` started a change, so `gcc` deleted text instead of commenting it.

---

## Changes

- Add the `operator.comment` pending operator, so `gc{motion}` toggles the comment of the lines a motion or text object covers, with counts, and `gcc` toggles [count] lines as the doubled form of its last key
- Add visual `gc`, which toggles the selected lines in visual, visual_line, and visual_block through a new `CommentSelection` use case
- Add the `textobject.comment` text object, so `dgc` and `ygc` select the adjacent commented lines around the cursor and nothing when the cursor line is not commented
- Add the `Comments` domain module with Neovim's toggle rule (uncomment all when every non-blank line is commented, else comment all at the smallest indent with one space, blank lines untouched) and a one-row-per-filetype marker table, `#` for ruby and for an unknown filetype
- Make the whole toggle one undo step through one `set_lines`, repeated by `.`
- Add the keymap lines for normal, operator_pending, and the visual modes to `config/default.caratrc`, mirrored in `carat/domain/default_config.rb`
- Add the table-driven `test/editor_comments.rb` covering comment, uncomment, a mixed range, blank lines, indent, counts, a text object, the visual modes, undo, dot repeat, the last line, and the old bug where `gcc` deleted text
- Add the operators and text-objects spec requirements and archive the OpenSpec change
- Document the operator in README.md, `docs/actions.md`, `docs/compatibility.md` (no `commentstring` option yet listed as a difference), `docs/architecture.md`, and `docs/codebase-map.md`
- Record the planner's feature queue, with the Sprint 25 exception line and the `one-accent` and `glyph-audit` pool entries, and the border-vocabulary run's metrics row

---

## Testing

- Run the security review of the committed diff, passed with no finding (high 0, medium 0, low 0)
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, test-run, tools-test, gates, and metrics, all pass
- Run the benchmark review against main's recorded figures, passed with no blocking finding
- Run make spec-validate after the archive, 55 passed and 0 failed

---

## Notes

The Sprint 25 exception line is written in backticks, unlike the brief's plain text, so the queue parser reads the change names. Markers with a right part such as `/* %s */` and a `commentstring` option are left for a later change.
