# Tasks

## 1. The refs/replace stop fails closed

- [ ] 1.1 `.claude/workflows/deliver-change.js` `mergeLines`: list `refs/replace` and `refs/remotes/origin/main` newest name first and pass only on origin/main's one line. Test: `tools/tools_test.sh` "workflow: a failing for-each-ref stops the green line before the worktree add", "workflow: the line stopped by a failing for-each-ref added no merge-gates worktree"; the existing refs/replace cases still pass.

## 2. Main's merge gates run only from a copy matching main's tree

- [ ] 2.1 `.claude/workflows/deliver-change.js` `mergeLines`: after the fsck, `read-tree origin/main` and `diff --quiet` in the copy, before the gates; the comment above `MERGE_GATES` corrected. Test: "workflow: an object swapped back before the fsck stops the green line before the merge gates", "workflow: a merge-gates file rewritten after the fsck stops the green line before the merge gates", "workflow: the green line checks the copy's content after the fsck and before the merge gates"; "workflow: the green line runs main's merge gates over a clean store" still passes.
- [ ] 2.2 `tools/agent_guard.sh` `git_form`: the merger's `git -C tmp/.NAME read-tree origin/main`, header. Test: "guard: merger reads main's tree into a worktree's index", "guard: merger refuses another read-tree", "guard: read refuses git read-tree", "guard: merger runs the green line the workflow builds", and the updated "guard: merger runs the green line".

## 3. The fork heading re-verified

- [ ] 3.1 No edit: `7cbcf29` (#268) closed it; its cases "open_pr: open opens its own pull request beside a fork's on the branch's name" and the three after it fail with `7cbcf29^`'s `tools/open_pr.sh` and pass at main (proposal).

## 4. Docs and checks

- [ ] 4.1 README.md delivery step 9, `.claude/agents/merger.md` step 4, `docs/codebase-map.md` area 1. Test: `make docs-lint`, `make gates`, `make spec-validate`, `make tools-test`.
