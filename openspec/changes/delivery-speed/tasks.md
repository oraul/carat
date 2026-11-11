# Tasks

## 1. Run state, gates, and guard

- [x] 1.1 `tools/run_state.sh`, `tools/gates.sh`, `tools/agent_guard.sh`: remove the backup, restore, and abandon commands, the backup gate group, and the guard's backup form. Proved by `tools/tools_test.sh` "run_state: backup is no longer a command".
- [x] 1.2 `tools/run_state.sh`: `history` appends each merged run's late-finding notes to `docs/backlog.md`. Proved by "run_state: history appends a merged run's late findings to the backlog".
- [x] 1.3 `Makefile`, `tools/run_state.sh`, `tools/gates.sh`, `.github/workflows/ci.yml`: `FAST_STAGES` for the checker, main's full list while main has none, the release build on pull requests. Proved by "run_state: check runs main's full list while main has no fast list" and "gates: stages read the fast list".
- [x] 1.4 `tools/gates.sh`: the pr-body gate refuses a session line. Proved by "gates: pr-body refuses a session line".

## 2. Workflow

- [x] 2.1 `.claude/workflows/deliver-change.js`: late findings as notes (`noteText`), the push without findings. Proved by "workflow: a late finding becomes a shell-safe note".
- [x] 2.2 `.claude/workflows/deliver-change.js`: `staleRed` and the body-only fix without a round. Proved by "workflow: a red superseded by a green run of the same check is stale".
- [x] 2.3 `.claude/workflows/deliver-change.js`: fix-round review scope from this start's pass (`narrowedFrom`), `reRaised` for quality only, and `securityBlocking` with no re-rating. Proved by "workflow: a blocking finding at an earlier advisory's location is re-raised", "workflow: a re-rated security Medium at confidence 8 still blocks", and "workflow: a fix round narrows both reviews only from this start's pass".
- [x] 2.4 `.claude/workflows/deliver-change.js`: flush only before a gate that reads a pending review record, no close fallback. Proved by "workflow: only check and review records need a record start".
- [x] 2.5 `.claude/workflows/deliver-change.js`: a resume past the push takes no record from the run state and runs the check and the reviews again at the head (item 9 dropped by the security review). Proved by "workflow: a resume past the push builds no merge records from the run state" and "workflow: only this start's verdicts enter its records".

## 3. Agents and docs

- [x] 3.1 `.claude/agents/quality-reviewer.md`, `checker.md`, `merger.md`, `contributor.md`: narrowed blocking, fast stages, latest run per check, the body mode and body equality, no backup. Proved by "agents: the quality reviewer blocks only on correctness and a missing test" and `make docs-lint`.
- [x] 3.2 CLAUDE.md, README.md, `docs/codebase-map.md`, `docs/architecture.md`: the commands, stages, and steps. Checked by `make gates` and `make docs-lint`.
