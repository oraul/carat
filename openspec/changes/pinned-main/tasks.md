# Tasks

## 1. Main fetched by a pinned refspec

- [x] 1.1 `.claude/workflows/deliver-change.js` and `.claude/agents/merger.md`: the green line fetches `+refs/heads/main:refs/remotes/origin/main` with `--refmap=`. Tested by "workflow: the green line fetches and adds the copy with no global configuration or hook", "workflow: the green line checks origin before its fetch", and "guard: merger runs the green line".
- [x] 1.2 `tools/agent_guard.sh`: the fetch form admits the pinned fetch and refuses another refspec; every call is refused while `remote.origin.fetch` is not a clone's default. Tested by "guard: merger fetches main by its pinned refspec", "guard: merger refuses the pinned refspec reading the configured one", "guard: merger refuses another refspec onto origin/main", "guard: a fetch refspec other than a clone's refuses every call", "guard: a second fetch refspec refuses every call", and "guard: no fetch refspec refuses nothing".

## 2. The merge-tool hook

- [x] 2.1 `.claude/agents/merger.md`: the hook refuses when main's guard is missing, empty, or lacks the merge tool, and always runs it otherwise. Tested by "guard: the merge hook refuses with main's guard", "guard: the merge hook refuses when main's guard lacks the merge tool", and "guard: the merge hook refuses when main's guard is empty".

## 3. Worktrees of the project

- [x] 3.1 `tools/agent_guard.sh`: `worktree_name` for `git worktree add` and `remove`; `worktree` admits an existing `tmp/.NAME` only as a linked worktree of the project's repository. Tested by "guard: read allows git, cd, and make in a worktree of the project", the planted, linked, and forged `tmp/.NAME` cases, "guard: merger refuses a checkout in a planted repository", "guard: read adds a worktree not there yet and uses it", "guard: read removes a worktree by its name", and "guard: read refuses a .git file naming another worktree's record"; the measurement cases now use a real worktree.

## 4. Contributor pushes

- [x] 4.1 `tools/tools_test.sh`: every contributor `git push` form is refused and the run state's backup and push are admitted. Tested by the "guard: contributor refuses git push ..." cases, "guard: contributor backs up and pushes through tools/run_state.sh", and "guard: the contributor hook refuses a direct push to the backup refs".

## 5. Records

- [x] 5.1 `docs/backlog.md`: remove the entries this change fixes and add the planner's entries from `build/plan/backlog.md`, with its extensions of four existing entries. Checked by `make docs-lint`.
- [x] 5.2 `tools/agent_guard.sh` header and the docs that describe the worktree rule, the fetch, and the merge hook. Checked by `make gates` and `make docs-lint`.
