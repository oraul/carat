# Tasks

## 1. wait without gh

- [x] 1.1 Remove `head_owned`, its call, the `unread` variable and its refusal from `tools/open_pr.sh`, and update the header and the `wait` comment to name the merger's step 1
- [x] 1.2 Replace the `head_owned` cases of `tools/tools_test.sh` with a lone-pull-request case where `gh` fails and one proving no `gh` ran

## 2. Docs

- [x] 2.1 Check README.md, CLAUDE.md, and `docs/codebase-map.md` still describe `wait` correctly; they do, unchanged

## Quality review

- [x] 3.1 Self-review of the diff by the quality reviewer's checklist: no finding beyond the recorded security Low in docs/findings/lane-guard-lows-b.md

- [x] 3.2 Review-round finding (security Low 6, merge hook pull request number and title check): its fix is in tools/agent_guard.sh, a file this change does not edit, and adds new code, so it is recorded in docs/findings/lane-guard-lows-b.md
