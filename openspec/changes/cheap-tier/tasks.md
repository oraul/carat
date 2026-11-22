# Tasks

## 1. Runner agent and guard

- [ ] 1.1 Add `.claude/agents/runner.md` (Bash only, the cheapest tier's `model:` line, the pinned hook with the `runner` profile); proved by the hook-line cases ("guard: every hook line resolves main the same way", the per-agent hook cases) and "caps: the runner file's maxTurns is its large cap and the margin"
- [ ] 1.2 Add the `runner` profile to `tools/agent_guard.sh`; proved by "guard: runner runs the resume steps", "guard: runner runs the records", and the runner refusal cases

## 2. Workflows

- [ ] 2.1 Start resume and record as `runner` at `agent/low` in `deliver-change.js`; proved by "calibration: the agent tier is the agent files' model lines" and "calibration: the resume and record starts run as the runner"
- [ ] 2.2 Start sprint-planning's due, notes, skeptic notes, record, and records-merged as `runner`; proved by "sprint: the bookkeeping starts run as the runner at low effort"

## 3. Merger

- [ ] 3.1 Drop the remote branch delete from `merger.md` step 7 and the guard's merger profile; proved by "guard: merger refuses the remote branch deletion" and "caps: the merger deletes no remote branch"

## 4. Trailer check

- [ ] 4.1 Refuse a merged commit whose last line is not exactly the trailer in `tools/run_state.sh`; proved by "run_state: set merged refuses a squash commit with a stray quote after the trailer" (fails with the fix reverted) and the two merge-tool guard cases

## 5. Docs

- [ ] 5.1 Note the move in `docs/goals.md` Calibration; name the runner in `README.md` and `CLAUDE.md`; checked by `make docs-lint` and `make gates`
- [ ] 5.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`
