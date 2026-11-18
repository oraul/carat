fix(folds): nest folds at a shared first row and restore them on revert

## Summary

Makes `zf` nest a new fold that starts on the first row of an existing fold, as Neovim does, and makes a failed plugin edit request leave every window's folds exactly as before it. `zf3jzozfj` left rows 0 to 3 folded twice where Neovim nests a fold over rows 0 and 1, and a plugin edit that failed while applying put its lines back but left the folds where its edits had moved, shrunk, or dropped them.

---

## Changes

- Fix `Folds#create` so a fold sharing the new fold's first row counts as nested or holding, and only a fold that truly crosses another grows to cover both
- Fix `Buffer#revert_to` so it puts back a copy of every tracked fold list taken by `Buffer#transaction_mark`, so a reverted plugin edit restores the folds as it restores the lines, signs, and marks
- Add rows to `test/domain_folds.rb` for `[[2,6],[2,3]]`, to `test/editor_folds.rb` for the drawn `zf3jzozfj` nesting, and to `test/domain_edits.rb` for a reverted plugin edit leaving the folds as before
- Document the nesting at a shared first row in `docs/compatibility.md` and the README feature list, and the fold rollback of a failed `edit_buffer` in `docs/plugins.md`
- Update the `folds` spec with the shared-first-row nesting and the failed-edit rollback, and archive the OpenSpec change
- Record the plan, the lane's metrics history, and the four non-blocking review findings in `docs/findings/vim-folds-b.md`

---

## Testing

- Run the security review of the committed diff, passed with no High, Medium, or Low finding
- Run the quality review, passed with no blocking finding and four advisories recorded as findings
- Run the checker's stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics, all pass
- Run the benchmark review against main's recorded figures, passed
- Run make spec-validate after the archive, 54 passed and 0 failed
- Run make gates and make docs-lint before the push, both pass

---

## Notes

The planner split `vim-folds-b` at its start: Insert mode opening the cursor's closed fold (`zfjiX`) and a closed split or tab page untracking its windows' folds (`zfj` then a split closed) are left to `vim-folds-windows`, now first in the feature Pool with the three backlog headings the brief named. An identical fold still nests as a second fold, as Neovim's `zf` on the same range does.
