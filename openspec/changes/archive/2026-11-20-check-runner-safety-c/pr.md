fix(tools): widen a lane check's escape scan to the main checkout

## Summary

A lane check now fails when a stage writes the main checkout, the common git directory's references or info directory, or the global git configuration, and it no longer fails when a git status refreshes the lane's index. The escape scan read only the lane's own worktree and git directory, so a stage could plant code in those places by an absolute path while the check passed, and the scan of the lane's whole git directory gave a false failure on any index refresh.

---

## Changes

- Fix the escape scan in tools/run_state.sh to check the main checkout from a lane: its untracked files changed during the check, its status and flagged index entries, and its HEAD, which may move only to the commit origin's branch reports through git ls-remote.
- Fix the escape scan to compare the common git directory's references by name and object, leaving out the remote-tracking refs, the branches other lane worktrees hold, and the main checkout's branch.
- Fix the escape scan to cover the common info directory and the global git configuration file beside the hooks.
- Fix the false failure on a lane index refresh by scanning the lane's git directory without its index and comparing staged entries instead, so a stat refresh passes and a staged change fails.
- Add tools-test cases that fail a lane check for each new kind of write and pass it for an index refresh, another lane's commit, a removed lane worktree, and the main checkout fast-forwarded to origin's commit.
- Document the scan's coverage in the README checker paragraph and the new helpers in the code map entry for tools/run_state.sh.
- Record the review findings this change leaves, among them the other lanes' branches and worktree files, stage-made worktrees, forged remote-tracking refs, and HOME files run by later tools, in docs/findings/check-runner-safety-c.md.

---

## Testing

- Run the security review of the committed diff, pass with no High or Medium finding at confidence 8 or above and three Low findings, recorded in the findings file.
- Run the quality review, pass with no blocking finding after two fix rounds added the flagged-index and origin-commit test cases.
- Run the checker's stages diagnose, dev-build, test-build, test-run, gates, docs-lint, bench-budget, tools-test, and metrics, all pass.
- Run the benchmark review, pass with no blocking finding.
- Run make spec-validate after the archive, all 54 items pass.
- Run make gates and make docs-lint before the push, both pass.

---

## Notes

The change is a pipeline defect run first in Sprint 22's backlog lane by the user-approved exception. It leaves tools/rules.sh untouched. The common objects directory and the remote-tracking refs stay unscanned, since every lane writes them; a stage moving another lane's branch, a stage-made worktree, a forged per-branch remote-tracking ref, and HOME files such as shell rc files remain as recorded findings for a follow-up.
