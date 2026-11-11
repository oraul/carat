# Tasks

## 1. The script

- [ ] 1.1 `tools/open_pr.sh` (replacing `tools/pr_tag.sh`): `write` gates the title and the body file and writes `pr.md` into the archived change. Proved by `tools/tools_test.sh` "open_pr: write puts the title, a blank line, and the body into the archived change's pr.md" and "open_pr: write refuses a body failing the pr-body gate".
- [ ] 1.2 `tools/open_pr.sh`: `read` and `gate`. Proved by "open_pr: pr.md is parsed into the title and the body", "open_pr: a branch without a new pr.md is left alone", "open_pr: a body failing the pr-body gate is refused", and "open_pr: a branch of no allowed type is refused".
- [ ] 1.3 `tools/open_pr.sh`: `open` and `wait`. Proved by "open_pr: a branch with an open pull request is left alone", "open_pr: open creates the pull request and reads it back equal", "open_pr: a pull request read back with a footer is refused", and "open_pr: wait records the pull request whose head is the pushed head".

## 2. The workflows

- [ ] 2.1 `.github/workflows/branch-push.yml` (replacing `pr-tag.yml`) and `open-pr.yml`: the branch push runs the permissionless trigger, whose completion runs open-pr from main with main's script, no tag and no ref delete. Accepted once open-pr is on main; this change's pull request 108 was opened by hand (design, Risks).

## 3. Guard, workflow, agents, and docs

- [ ] 3.1 `tools/agent_guard.sh`: the contributor runs `tools/open_pr.sh write` and `wait` only, and pushes only through `tools/run_state.sh push`. Proved by "guard: the contributor runs open_pr write and wait" and "guard: the contributor refuses the workflow's open_pr open".
- [ ] 3.2 `.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`: the package step writes `pr.md` before its push and waits for the pull request, no create tool. Proved by "agents: the contributor opens the pull request by pr.md, never a create tool", "agents: the contributor holds no pull request create tool", and "workflow: a package step without a pull request number stops the run".
- [ ] 3.3 CLAUDE.md, README.md, `docs/codebase-map.md`: the pull request opened on the branch push and the new files. Checked by `make gates` and `make docs-lint`.
