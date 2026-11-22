# Tasks

## 1. Guard

- [ ] 1.1 Refuse writes of `.claude/settings.local.json`, `.mcp.json`, `CLAUDE.local.md`, and the `.claude` directory for every profile in `write_target`, and every call while one of the three is untracked at the top of the project; proved by the tools-test cases "guard: PROFILE refuses a write of the local settings" and "guard: every call is refused while an untracked local settings file stands"
- [ ] 1.2 Allow `date` only with its read options and a `+FORMAT` operand (`date_form`); proved by "guard: PROFILE refuses date -s" and "guard: PROFILE reads the clock with date"
- [ ] 1.3 Accept the merger's `read-tree` only in `tmp/.merge-gates`; proved by "guard: merger refuses a read-tree of another worktree"
- [ ] 1.4 Update the guard's header and the codebase map's guard row

## 2. Workflows and spec preview

- [ ] 2.1 Add the green line's untracked-file check of the merge gates' copy; proved by "lanes: the green line stops on an untracked file in the merge gates' copy" and the guard's green-line case
- [ ] 2.2 Refuse a symbolic link under `openspec/` in `tools/spec_validate.sh`; proved by "spec_validate: refuses a symbolic link under openspec" and the codebase map's `spec_validate.sh` row
- [ ] 2.3 Run the Notes phase's command through the quality reviewer in record mode; proved by "sprint: the security notes run under the guarded quality reviewer in record mode"
- [ ] 2.4 Move the report's Security line into `securityReport`; proved by "sprint: the report's security line names unrecorded findings"
- [ ] 2.5 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
