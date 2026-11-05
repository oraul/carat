# Tasks

## 1. The secret patterns and the content gate

- [x] 1.1 `tools/rules.sh`: `KEY_RE`, `TOKEN_RE`, `ASSIGN_RE` in `scan`, reported by label only. Tested by the `tools/tools_test.sh` cases "gates: content refuses a secret: KIND" for a private key block, an AWS key id, a GitHub token, a Slack token, an `sk-` key, and a password, secret, token, and API key assigned a literal, "gates: content does not print the secret", and "gates: content allows a token read from a variable".
- [x] 1.2 `tools/gates.sh` `gate_content`: every commit's added lines against each parent, and an added `.env` file refused. Tested by "gates: content refuses a secret a later commit removed", "gates: content refuses an added .env file", "gates: content refuses an added .env.local in a directory", and the existing content cases unchanged.
- [x] 1.3 `.gitignore`: `.env` and `.env.*`. Tested by "repository: .gitignore ignores .env files".

## 2. The backup's base and the restore

- [x] 2.1 `tools/run_state.sh` `branch_base` and `backup_branch`: the base recorded, checked, given to the gates, and pushed with the head atomically. Tested by "run_state: backup records the branch's base", "run_state: backup pushes the base ref", "run_state: backup refuses a secret and pushes nothing", and the existing backup cases.
- [x] 2.2 `tools/run_state.sh` `restore_branch`: refuses a backup without a base ref, one whose base is not on main, and one with a commit not descended from the base. Tested by "run_state: restore refuses a backup without a recorded base", "run_state: restore refuses a base not on main", "run_state: restore refuses commits not descended from the base", and "run_state: restore creates the branch from its backup".

## 3. Deleting the backup refs

- [x] 3.1 `tools/run_state.sh` `drop_backup`, used by `push` (always, reported), `set CHANGE merged`, and the new `abandon CHANGE`. Tested by "run_state: push deletes the backup refs", "run_state: recording merged deletes the backup refs", "run_state: abandon deletes the backup refs", and "run_state: abandon says when there is no backup".
- [x] 3.2 `tools/agent_guard.sh` refuses `abandon` to every profile (its default). Tested by "guard: contributor never abandons a run".
- [x] 3.3 `.claude/workflows/deliver-change.js` notes `abandon` when a run stops; `.claude/agents/merger.md` says recording `merged` deletes the backup refs. Checked with `node --check` when a runtime is present, else by reading.

## 4. Docs and bookkeeping

- [x] 4.1 `README.md`, `docs/codebase-map.md` area 1, and the headers of `tools/run_state.sh` and `tools/gates.sh` (`abandon`, `base`, the base ref, the secret patterns). Checked by `make docs-lint` and `make gates`.
- [x] 4.2 `docs/backlog.md`: remove the two entries fixed here, append the six entries of `build/plan/backlog.md`, update the figures of the `CLAUDE.md` budget entry (to `docs-currency`) and the delivered-changes entry (to `docs-index`), and add the limits of the secret patterns; `docs/queue.md` from `build/plan/queue.md`. Checked by `make docs-lint`.
- [ ] 4.3 Run `make tools-test`, `make docs-lint`, `make gates`, and `openspec validate backup-secret-scan --strict --no-interactive`.
