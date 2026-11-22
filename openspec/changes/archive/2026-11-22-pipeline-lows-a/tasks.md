# Tasks

## 1. Check records a contributor's runner cannot back

- [x] 1.1 `tools/run_state.sh` `check_run`: refuse a tracked file differing from HEAD at the runner's start, before the clone, with a `stage none failed` verdict and no record. Test: `tools/tools_test.sh` "run_state: a runner started over a dirty tree refuses at its own start", "run_state: a runner started over a dirty tree records nothing, so its pass backs no head".
- [x] 1.2 `tools/run_state.sh` `check_stages`, `RERUN_STAGES`, `COMPILE_STAGES`: `diagnose` skipped at the head only when the backed commit is the recorded `phase.check`, never compiled-skipped; header and comments. Test: "run_state: check reruns diagnose at a contributor's claimed head and skips the other stages", "run_state: check still skips the other stages at a contributor's claimed head", "run_state: check skips diagnose at the head the recorded phase.check backs", "run_state: a tooling commit keeps the code key, diagnose runs again".

## 2. Skeptic notes recorded literally

- [x] 2.1 `.claude/workflows/sprint-planning.js`: `SKEPTIC.notes`, `skepticNotes` with `shellWord`, a record start before the planner, `skepticNoted` in `reviewed`. Test: "sprint: each skeptic note is recorded literally, a finding holding a command substitution included", "sprint: the skeptic's notes are recorded before the planner starts".
- [x] 2.2 `.claude/agents/quality-reviewer.md` skeptic mode: record nothing, return `notes`; `.claude/agents/security-reviewer.md` sprint mode names the skeptic's disputes as the workflow's records. Test: "agents: the skeptic records nothing and returns its notes".

## 3. Held and unpushed finding notes only from the workflow

- [x] 3.1 `tools/agent_guard.sh` `run_state_form`: refuse `note` of `late-finding`, `held-finding`, `unpushed-finding` but in the close profile. Test: "guard: the read profile plants no held-finding note", "guard: the read profile plants no unpushed-finding note", "guard: the read profile plants no late-finding note", "guard: the read profile still records its other notes", "guard: the close profile runs held-finding and unpushed-finding notes".
- [x] 3.2 `tools/run_state.sh` `add_note`: a `held-finding` only after the push and before the merge, an `unpushed-finding` only before the push. Test: "run_state: note refuses a held-finding before the push", "run_state: note refuses an unpushed-finding after the push", "run_state: note refuses a held-finding after the merge", "run_state: note records an unpushed-finding before the push", "run_state: note records a held-finding after the push".
- [x] 3.3 `.claude/workflows/deliver-change.js`: the comments of `claimFrom` and `recordLate` name the rerun of `diagnose` and the notes' writers; `tools/run_state.sh` header of `note`.

## 4. Docs and checks

- [x] 4.1 README.md steps of the check and the sprint, `.claude/agents/checker.md`, `.claude/agents/security-reviewer.md`, `docs/contributor-notes.md` Checking, `docs/codebase-map.md` area 1. Test: `make docs-lint`, `make gates`, `make spec-validate`, `make check-stage S=tools-test`.

## Quality review

- [x] 5.1 `tools/run_state.sh` `check_stages`: the recorded `phase.check` kept in a variable named `recorded`, a word other commands use for other values; renamed `phase_check`. Fixed.
- [x] 5.2 `design.md` Risks: a close's `held-finding` line refused when the run state holds a `merged` record the workflow's memory lacks was not stated; added. Fixed.
- [x] 5.3 `proposal.md` Impact left out `.claude/agents/security-reviewer.md`, which the change edits; added. Fixed.
- [x] 5.4 The quality reviewer's Periodic mode step 4 still records its own notes as a double-quoted argument, the same exposure the skeptic had; outside this change's scope (the skeptic's notes), recorded in `docs/findings/pipeline-lows-a.md`.

## Security review

- [x] 6.1 security Low (4) `.claude/workflows/sprint-planning.js`: the skeptic's notes ran in an unguarded general agent, though their texts quote reviewed code; the start is now the quality reviewer in a new `Mode: record` of `.claude/agents/quality-reviewer.md`, whose hook runs `tools/agent_guard.sh`'s read profile. Test: "sprint: the skeptic's notes run under the guarded quality reviewer's record mode". The security findings' runner (`securityNotes`), the same exposure before this change, recorded in `docs/findings/pipeline-lows-a.md`.

## CI fix

- [x] 7.1 CI tools-test: "a write to HOME's git configuration from a lane ends in a failed verdict line" read a check log ending on an escaped path, since the waiter's `check_verdict` took the escape scan's heading `check: files outside its clone changed ...` for a verdict and returned before the runner printed one; `check_verdict` now reads only the header's verdict forms. Test: "run_state: a check log ending on the escape heading holds no verdict", failing with the fix reverted.
