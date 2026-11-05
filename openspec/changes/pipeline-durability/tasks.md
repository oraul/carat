# Tasks

## 1. Killed and superseded stages (b)

- [ ] 1.1 `tools/run_state.sh` `run_stage`: the commit read before the command, a `running` record first, the command waited in the background, `killed` for a signal's exit status, `superseded` when `HEAD` moved, the log's last line. Tested by the `tools/tools_test.sh` cases "run_state: a stage killed by a signal is recorded as killed", "run_state: a killed stage's log says so", and "run_state: a stage during which HEAD moved is superseded at the commit it ran on".

## 2. The detached runner and the waiter (a)

- [ ] 2.1 `tools/run_state.sh` `check` (waiter) and `check-run` (runner): the pid file, `setsid -f`, the trap, the verdict lines, `CHECK_WAIT` and exit 3, rejoining, superseding, and the hard-killed runner. Tested by "run_state: a check killed by a signal names its stage and log", "run_state: a hard-killed check is reported killed by the next check", "run_state: a check still running exits 3", "run_state: a second check at the same head rejoins the running one", "run_state: a check at a newer head supersedes the running one", and the existing check cases unchanged.
- [ ] 2.2 `.claude/agents/checker.md`: the check in the foreground, repeated on exit 3, its last line returned as `verdict`.

## 3. The workflow reruns what did not finish (c)

- [ ] 3.1 `.claude/workflows/deliver-change.js`: `CHECK.verdict`, `checkVerdict`, the rerun without a round, at most two in a row. Tested by "run_state: the workflow reruns every verdict word the check prints but failed and passed" (a contract case over the workflow's pattern), a syntax check, and a simulation with stub agents (a killed check, a verdict at a stale commit, a missing verdict, then a pass; three kills in a row stopping the run with rework 0).

## 4. The backup ref (d)

- [ ] 4.1 `tools/gates.sh`: the `backup` group (trailer and content). Tested by "gates: backup passes a clean branch" and "gates: backup refuses forbidden content".
- [ ] 4.2 `tools/run_state.sh` `backup`, `restore`, and `push` deleting the backup. Tested by "run_state: backup pushes the branch to its backup ref", "run_state: backup refuses main", "run_state: backup after the push has nothing to do", "run_state: restore creates the branch from its backup", "run_state: restore leaves a branch that exists", and "run_state: push deletes the backup ref".
- [ ] 4.3 `tools/agent_guard.sh`: the contributor's `backup CHANGE`. Tested by "guard: contributor backs up the branch" and "guard: contributor backup takes only the change".
- [ ] 4.4 `.claude/agents/contributor.md` (back up after each commit) and the resume step of `.claude/workflows/deliver-change.js` (restore before creating the branch).

## 5. Docs and bookkeeping

- [ ] 5.1 `CLAUDE.md`, `README.md`, `docs/codebase-map.md` area 1, and the headers of `tools/run_state.sh`, `tools/gates.sh`, and `tools/agent_guard.sh`.
- [ ] 5.2 `docs/backlog.md`: the plan notes (the scratch-file entry queued in `merge-gate-integrity`, the entry of `build/plan/backlog.md`, the six `buffer-global` advisories queued in `global-tidy`, the global's ex commands pointing to item 27).
- [ ] 5.3 Run `make tools-test`, `make docs-lint`, `make gates`, and `openspec validate pipeline-durability --strict --no-interactive`.
