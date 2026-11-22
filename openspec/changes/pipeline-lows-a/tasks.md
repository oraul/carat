# Tasks

## 1. Check records a contributor's runner cannot back

- [ ] 1.1 `tools/run_state.sh` `check_run`: refuse a tracked file differing from HEAD at the runner's start, before the clone, with a `stage none failed` verdict and no record. Test: `tools/tools_test.sh` "run_state: a runner started over a dirty tree records nothing, so its pass backs no head".
- [ ] 1.2 `tools/run_state.sh` `check_stages`, `RERUN_STAGES`, `COMPILE_STAGES`: `diagnose` skipped at the head only when the backed commit is the recorded `phase.check`, never compiled-skipped; header and comments. Test: "run_state: check reruns diagnose at a contributor's claimed head and skips the other stages", "run_state: check skips diagnose at the head the recorded phase.check backs", "run_state: a tooling commit keeps the code key, diagnose runs again".

## 2. Skeptic notes recorded literally

- [ ] 2.1 `.claude/workflows/sprint-planning.js`: `SKEPTIC.notes`, `skepticNotes` with `shellWord`, a record start before the planner, `skepticNoted` in `reviewed`. Test: "sprint: each skeptic note is recorded literally, a finding holding a command substitution included", "sprint: the skeptic's notes are recorded before the planner starts".
- [ ] 2.2 `.claude/agents/quality-reviewer.md` skeptic mode: record nothing, return `notes`. Test: "agents: the skeptic records nothing and returns its notes".

## 3. Held and unpushed finding notes only from the workflow

- [ ] 3.1 `tools/agent_guard.sh` `run_state_form`: refuse `note` of `late-finding`, `held-finding`, `unpushed-finding` but in the close profile. Test: "guard: the read profile plants no held-finding note", "guard: the read profile plants no unpushed-finding note", "guard: the close profile runs held-finding and unpushed-finding notes".
- [ ] 3.2 `tools/run_state.sh` `add_note`: a `held-finding` only after the push and before the merge, an `unpushed-finding` only before the push. Test: "run_state: note refuses a held-finding before the push", "run_state: note refuses an unpushed-finding after the push".
- [ ] 3.3 `.claude/workflows/deliver-change.js`: the comments of `claimFrom` and `recordLate` name the rerun of `diagnose` and the notes' writers.

## 4. Docs and checks

- [ ] 4.1 README.md steps of the check and the sprint, `.claude/agents/checker.md`, `docs/contributor-notes.md` Checking, `docs/codebase-map.md` area 1. Test: `make docs-lint`, `make gates`, `make spec-validate`, `make check-stage S=tools-test`.
