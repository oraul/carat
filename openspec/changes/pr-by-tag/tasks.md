# Tasks

## 1. The check clone

- [ ] 1.1 `tools/run_state.sh`, `Makefile`: every detached check stage gets `CARAT_BIN=build/dev/carat` (commit 9a828bb). Proved by `tools/tools_test.sh` "run_state: check runs the smoke test on dev-build's binary, as CI does".

## 2. The tag

- [ ] 2.1 `tools/pr_tag.sh`: `read`, `branch`, `gate`, and `same`. Proved by "pr_tag: a tag message is read into the title and the body", "pr_tag: a body failing the pr-body gate is refused", "pr_tag: a branch of no allowed type is refused", and "pr_tag: a branch missing on origin is refused".
- [ ] 2.2 `tools/pr_tag.sh`: `push` and `wait`. Proved by "pr_tag: push tags the pushed head with the title and the body", "pr_tag: wait records the pull request whose head is the pushed head", and "pr_tag: wait fails while the tag is on origin".
- [ ] 2.3 `.github/workflows/open-pr.yml`: the tag push opens, reads back, and deletes. Proved by this change's own pull request opened by the workflow.

## 3. Guard, workflow, agents, and docs

- [ ] 3.1 `tools/agent_guard.sh`: the contributor runs `tools/pr_tag.sh push` and `wait` and no other push. Proved by "guard: the contributor runs pr_tag push" and "guard: the contributor's git push of a tag is refused".
- [ ] 3.2 `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`: the package step by tag, no create tool, a run without a number stopped. Checked by `make docs-lint` and `make tools-test`.
- [ ] 3.3 CLAUDE.md, README.md, `docs/codebase-map.md`: the pull request by tag and the new files. Checked by `make gates` and `make docs-lint`.
