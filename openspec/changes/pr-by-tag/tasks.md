# Tasks

## 1. The check clone

- [x] 1.1 `tools/run_state.sh`, `Makefile`: every detached check stage gets `CARAT_BIN=build/dev/carat` (commit 9a828bb). Proved by `tools/tools_test.sh` "run_state: check runs the smoke test on dev-build's binary, as CI does".

## 2. The tag

- [x] 2.1 `tools/pr_tag.sh`: `read`, `branch`, `gate`, and `same`. Proved by "pr_tag: a tag message is read into the title and the body", "pr_tag: a body failing the pr-body gate is refused", "pr_tag: a branch of no allowed type is refused", and "pr_tag: a branch missing on origin is refused".
- [x] 2.2 `tools/pr_tag.sh`: `push` and `wait`. Proved by "pr_tag: push tags the pushed head with the title and the body", "pr_tag: wait records the pull request whose head is the pushed head", and "pr_tag: wait fails while the tag is on origin".
- [x] 2.3 `.github/workflows/open-pr.yml`: the tag push opens, reads back, and deletes, its steps the script's proved commands. Accepted by this change's own pull request, which the package step opens through it after the archive.

## 3. Guard, workflow, agents, and docs

- [x] 3.1 `tools/agent_guard.sh`: the contributor runs `tools/pr_tag.sh push` and `wait` and no other push. Proved by "guard: the contributor runs pr_tag push and wait" and "guard: the contributor's git push of a tag is refused".
- [x] 3.2 `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`: the package step by tag, no create tool, a run without a number stopped. Proved by "agents: the contributor opens the pull request by its tag, never a create tool", "agents: the contributor holds no pull request create tool", and "workflow: a package step without a pull request number stops the run".
- [x] 3.3 CLAUDE.md, README.md, `docs/codebase-map.md`: the pull request by tag and the new files. Checked by `make gates` and `make docs-lint`.
