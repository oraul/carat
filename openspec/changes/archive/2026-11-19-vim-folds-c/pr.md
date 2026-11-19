feat(folds): add zR, zM, and the fold motions zj, zk, [z, ]z

## Summary

Adds Neovim's `zR` and `zM`, which open and close every fold of the window, and the fold motions `zj`, `zk`, `[z`, and `]z`, which move between folds and to the start or end of the fold holding the cursor. Without them a user could not unfold a file at once or move from fold to fold, and the single-window branch of closing a tab page dropped a kept slot window's folds with no test proving it.

---

## Changes

- Add `fold.open_all` (`zR`) and `fold.close_all` (`zM`), bound in normal mode, the cursor going to the first line of the closed fold `zM` leaves it in and neither giving an error without folds
- Add the motions `motion.fold_next` (`zj`), `motion.fold_previous` (`zk`), `motion.fold_start` (`[z`), and `motion.fold_end` (`]z`), each taking a count, going to column 0, recording a jump, acting as an exclusive charwise motion under an operator, and doing nothing where it cannot move, bound in normal, operator-pending, and the three visual modes
- Add the fold walks behind these keys to the domain fold list, a closed fold counted as one by `zj` and `zk`
- Add table-driven rows for every new key and a test that runs `:q` on a second tab page's only window beside a hidden slot window with a fold and sees the fold lists shrink
- Change a register test to cancel its pending operator with Escape, since `z` after `d` now starts a fold motion
- Document the new keys in `docs/compatibility.md`, `docs/actions.md`, and the README, and sync the folds and windows specs

---

## Testing

- Run the security review of the committed diff, passed with no finding
- Run the quality review, passed with no blocking finding, its two advisories fixed in the branch
- Run the checker stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics), all pass
- Run the benchmark comparison against main, passed
- Run `make spec-validate`, 54 passed and 0 failed
- Run `make gates`, all pass

---

## Notes

`zj` and `zk` are exclusive charwise under an operator, as `[z` and `]z` are in Neovim, which sets no motion type for them. `zO`, `zC`, `zA`, `zv`, `zx`, `zn`, `zN`, `zi`, the fold options, the fold ex commands, and `zR` or `zM` in visual mode are left for later changes.
