# Tasks

## 1. The squash message is built from pr.md

- [ ] 1.1 `tools/open_pr.sh`, `message CHANGE SHA`: prints the body of the change's archived `pr.md` at SHA, one blank line, and the trailer, refusing a bad name or sha, no one archived `pr.md`, and an empty body. Tested in `tools/tools_test.sh` by "open_pr: message builds the squash message from a four-section pr.md, its headings and dividers kept" and the message refusal cases.

## 2. The merger passes it and the guard reads the tool's head parameter

- [ ] 2.1 `tools/agent_guard.sh`: `merge_tool` reads `expectedHeadSha`; the merger may run `open_pr.sh message CHANGE SHA`. Tested by "guard: the merge tool allows the message open_pr message builds", "guard: the merge tool refuses an expected head passed as sha", "guard: the merger runs open_pr message", and "guard: the contributor refuses open_pr message".
- [ ] 2.2 `.claude/agents/merger.md` step 5: one `open_pr.sh message` call, its output passed exactly as `commit_message`, the head as `expectedHeadSha`; the first green is eight calls.

## 3. Documents and self-check

- [ ] 3.1 CLAUDE.md Commands, `docs/codebase-map.md` area 1, the headers of `tools/open_pr.sh` and `tools/agent_guard.sh` describe `message` and the head parameter; the finding on the hooks is appended to `docs/findings/merge-body-sections.md`.
- [ ] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.
