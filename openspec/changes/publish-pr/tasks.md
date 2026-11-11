# Tasks

## 1. The publish script

- [ ] 1.1 `tools/publish_pr.sh`: gate the body and title, post or patch through `curl`, record the number, read back and compare byte for byte, print the number. Tested by "publish_pr: a body failing the gate is refused before any call", "publish_pr: a title failing the scan is refused before any call", "publish_pr: a live body unlike the file is reported and fails", "publish_pr: the number is recorded and printed", and "publish_pr: a recorded number updates instead of creating".
- [ ] 1.2 `tools/agent_guard.sh`: the contributor profile runs `sh tools/publish_pr.sh CHANGE TITLE`, no other profile. Tested by "guard: contributor publishes with tools/publish_pr.sh" and "guard: reviewer may not run tools/publish_pr.sh".

## 2. The command and the agent

- [ ] 2.1 `.claude/commands/publish-pr.md` and `.claude/agents/contributor.md`: the command, the package and body steps through the script, the create and update tools dropped. Checked by "repository: the contributor names no pull request create or update tool" and `make docs-lint`.

## 3. Docs and bookkeeping

- [ ] 3.1 CLAUDE.md, README.md, `docs/architecture.md` section 10, `docs/codebase-map.md` area 1, the Makefile's `tools-test` description. Checked by `make gates` and `make docs-lint`.
- [ ] 3.2 `docs/backlog.md` and `docs/queue.md`: the plan's backlog entries and queue, in the package step. Checked by `make docs-lint`.
