# Tasks

## 1. Runner agent and guard

- [x] 1.1 Add `.claude/agents/runner.md` (Bash only, the cheapest tier's `model:` line, the pinned hook with the `runner` profile); proved by the hook-line cases ("guard: every hook line resolves main the same way", the per-agent hook cases) and "caps: the runner file's maxTurns is its large cap and the margin"
- [x] 1.2 Add the `runner` profile to `tools/agent_guard.sh`; proved by "guard: runner runs the resume steps", "guard: runner runs the records", and the runner refusal cases

## 2. Workflows

- [x] 2.1 Start resume and record as `runner` at `agent/low` in `deliver-change.js`; proved by "calibration: the agent tier is the agent files' model lines" and "calibration: the resume and record starts run as the runner"
- [x] 2.2 Start sprint-planning's due, record, and records-merged as `runner` (the notes starts: 7.1); proved by "sprint: the bookkeeping starts run as the runner at low effort"

## 3. Merger

- [x] 3.1 Drop the remote branch delete from `merger.md` step 7 and the guard's merger profile; proved by "guard: merger refuses the remote branch deletion" and "caps: the merger deletes no remote branch"

## 4. Trailer check

- [x] 4.1 Refuse a merged commit whose last line is not exactly the trailer in `tools/run_state.sh`; proved by "run_state: set merged refuses a squash commit with a stray quote after the trailer" (fails with the fix reverted) and the two merge-tool guard cases

## 5. Docs

- [x] 5.1 Note the move in `docs/goals.md` Calibration; name the runner in `README.md` and `CLAUDE.md`; checked by `make docs-lint` and `make gates`
- [x] 5.2 Run `make tools-test`, `make docs-lint`, `make gates`, and `make spec-validate`

## Quality review

- [x] 6.1 The quality reviewer's record mode and the prose naming it (README.md, docs/codebase-map.md, sprint-planning.js comments, the agent's description) went stale once the notes starts moved to the runner; fixed in place, then undone by 7.1, which keeps the notes starts on the record mode
- [x] 6.2 `.claude/workflows/periodic-review.js`'s record start still runs as the default agent on the session's model, unguarded; recorded in `docs/findings/cheap-tier.md`: the brief names only the delivery and sprint starts

## Security review

- [x] 7.1 Medium (5) `tools/agent_guard.sh:683`: the sprint notes and skeptic notes starts, whose commands quote reviewed code, ran under the `runner` profile, which also records reviews, phases, metrics, ci-stages, init, and lane-open of any change; they stay on the quality reviewer's record mode under the `read` profile (its record mode, README.md, and the comments restored); proved by "sprint: the security notes run under the guarded quality reviewer in record mode", "sprint: the skeptic's notes run under the guarded quality reviewer's record mode", "sprint: the bookkeeping starts run as the runner at low effort" (3 3), and the two "guard: the notes' read profile refuses" cases
- [x] 7.2 Low (4) `tools/agent_guard.sh:684`: `runner:note` refuses the late, held, and unpushed finding kinds as `read:note` does; proved by "guard: runner refuses a late-finding note", "held-finding", and "unpushed-finding" (fail with the fix reverted)
