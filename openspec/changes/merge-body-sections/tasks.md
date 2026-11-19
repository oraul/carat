# Tasks

## 1. The squash message is built from pr.md

- [x] 1.1 `tools/open_pr.sh`, `message CHANGE SHA`: prints the body of the change's archived `pr.md` at SHA, one blank line, and the trailer, refusing a bad name or sha, no one archived `pr.md`, and an empty body. Tested in `tools/tools_test.sh` by "open_pr: message builds the squash message from a four-section pr.md, its headings and dividers kept" and the message refusal cases.

## 2. The merger passes it and the guard reads the tool's head parameter

- [x] 2.1 `tools/agent_guard.sh`: `merge_tool` reads `expectedHeadSha`; the merger may run `open_pr.sh message CHANGE SHA`. Tested by "guard: the merge tool allows the message open_pr message builds", "guard: the merge tool refuses an expected head passed as sha", "guard: the merger runs open_pr message", and "guard: the contributor refuses open_pr message".
- [x] 2.2 `.claude/agents/merger.md` step 5: one `open_pr.sh message` call, its output passed exactly as `commit_message`, the head as `expectedHeadSha`; the first green is eight calls.

## 3. Documents and self-check

- [x] 3.1 CLAUDE.md Commands, `docs/codebase-map.md` area 1, the headers of `tools/open_pr.sh` and `tools/agent_guard.sh` describe `message` and the head parameter; the finding on the hooks is appended to `docs/findings/merge-body-sections.md`.
- [x] 3.2 Self-check: `make tools-test`, `make gates`, `make docs-lint`, and `make spec-validate` pass.

## 4. Review fixes

- [x] 4.1 Security (Low): `.claude/agents/merger.md` step 5 runs `open_pr.sh message` in the main checkout, with no `cd` into the worktree, so main's copy runs, never the branch's; `tools/agent_guard.sh` refuses `open_pr.sh message` after a `cd` into a worktree in the same call. Tested by "guard: merger refuses open_pr message after a cd into a worktree, the branch's copy" and "guard: merger prints the squash message before a cd into a worktree".
- [x] 4.2 Quality: `open_pr.sh message` computes the body once with one `sed '1,2d'` and prints it with the blank line and the trailer, dropping the awk loop the command substitution made dead; the existing message cases still pass.
- [x] 4.3 Quality: a case with two `DATE-CHANGE` archive directories each holding `pr.md`: "open_pr: message refuses a change with two archived pr.md at the sha".
- [x] 4.4 Quality: `tools/agent_guard.sh` clears the worktree a `cd` entered on a `cd` back to the project, so `open_pr.sh message` after it, main's copy, is allowed and the comment on `cd_worktree` holds. Tested by "guard: merger prints the squash message after a cd back to the project from a worktree".
