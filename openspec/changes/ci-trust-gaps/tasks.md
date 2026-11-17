# Tasks

## 1. Merge gates' object check

- [x] 1.1 `.claude/workflows/deliver-change.js` mergeLines: run `${PINNED_GIT} fsck --no-dangling --no-progress origin/main` after the worktree add and before the merge gates; proved by the tools-test cases "workflow: the green line hashes every object before the merge gates" and "workflow: a planted loose object stops the green line before the merge gates"
- [x] 1.2 `tools/agent_guard.sh` git_form: admit that fsck form to the merger only; proved by "guard: merger runs the green line", "guard: merger refuses another fsck", and "guard: read refuses git fsck"

## 2. Hook pins of the https form alone

- [x] 2.1 Every hook line under `.claude/agents/`: keep the https form's id alone; proved by "guard: every hook line carries the one pinned digest", "guard: a hook refuses the ssh form of origin", and "guard: a hook refuses the scp form of origin"
- [x] 2.2 `.claude/workflows/deliver-change.js` ORIGIN_IDS: the https id with and without `.git`; proved by "workflow: the origin check fails the ssh form" and "workflow: the origin check fails the scp form"
- [x] 2.3 `tools/agent_guard.sh` header: name the one pinned form

## 3. Documents

- [x] 3.1 `docs/codebase-map.md` (agent_guard.sh, the build-and-ci flow) and README.md (the pipeline's merge step): the one pinned form and the fsck before the merge gates; `make docs-lint` and `make gates` pass
