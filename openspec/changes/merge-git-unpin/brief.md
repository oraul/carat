# Brief

CHANGE: merge-git-unpin   LANE: backlog   BRANCH: bugfix/merge-git-unpin   BASE: 628d55e62d80
WHERE: `tools/run_state.sh:4400` (merge_main's merge through pinned_git), `:4418` (the queue checkout, add, and abort), `:4420` (the commit), `:4426` (the abort), `:4428` (a conflict outside the queues ends merge-main); `.claude/workflows/deliver-change.js:1254` (the main-moved start returns stopped where both sides changed the same logic); `tools/tools_test.sh` the two merge-main hook cases #328 added ("merge-main merges past a global hooks path and a repository hook", "merge-main ran neither hook").
WHY: the user (2026-11-23) asks to remove the pinned git that #328 put on merge_main, after deliveries stalled around the merge of a moved main.
OUTCOME: every conflict the merge of main meets, in the check or after a refused merge, goes back to the contributor, who resolves it, commits the merge, and the delivery goes on (check again, reviews when the change's files changed, one main-moved push) without stopping to ask, the same-logic case included; merge_main runs its merge, queue checkout, add, commit, and abort with plain git as before #328; the check clone's pinned_git and merge_main's fetch stay as they are; the two hook cases go, and the reopened finding (merge_main runs git merge with global configuration and hooks) is appended to docs/findings/merge-git-unpin.md.
ACCEPTED WHEN: a tools-test case that greps merge_main for pinned_git, and one that greps the main-moved start for a stop on a same-logic conflict, fail before and pass after, and tools-test passes.
CONSTRAINTS: only the repository rules that apply; none added
OUT OF SCOPE: anything not named in OUTCOME; the record step's runner, ci-stages, and every other part of #328 stay
USER DECISIONS: the user (2026-11-23): "Remove the pinned git only", and "during the check merge, if it sees a conflict, go to deliver to fix it".
