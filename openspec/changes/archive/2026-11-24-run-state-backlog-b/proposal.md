# Proposal

## Why

`tools/run_state.sh` still has 206 backlog headings after the first pass over its backlog. An independent check of that pass found 134 of 200 closed, 64 not done, 2 unclear, 10 claims the code does not back, and about 15 fixes whose cases pass without the fix; 6 headings are new. This change takes the check runner and escape scan theme, the one with the security Lows, and gives every heading of the work list an outcome with proof: the headings it fixes get a tools-test case that fails at the base and passes at the head, the earlier fixes get a behavior case that fails at the commit before them, and the rest are recorded with evidence or a reason in `docs/findings/run-state-backlog-b.md`. The groom, plan, and push themes are queued to `run-state-backlog-c`, `-d`, and `-e`.

## What Changes

- Run state writes: `write_key` and `drop_key` take a lock directory holding a pid file beside the run state (`state_lock`, `state_unlock`), so the detached runner and a caller rewriting it at once lose no record; a live holder makes a write wait `STATE_LOCK_WAIT` seconds and refuse, a dead holder's lock is taken over.
- Lost runner: `check_lost` stops the process group a dead runner left (`runner_group_stop`), only when no process holds the runner's pid, before a second runner starts.
- Stage jobs: each stage job runs in its own session (`setsid`) and its group is killed when the job ends, so a process a stage leaves running writes nothing after the escape scan.
- Escape scan: a branch of a worktree first seen at the scan is skipped only when it is new and its worktree lies at a `tmp/.lane-` path (`refs_view`, `new_lane_branches`); the escaped-path list is printed through `visible_text`; a regular file or link a stage planted under the main checkout's `build/`, not named by `LANE_WRITTEN`, is removed (`escaped_revert`); the scan's `ls-remote` limit is `SCAN_TIMEOUT` (60); the runner wait limit is `RUNNER_WAIT` (30).
- Proof: behavior cases for the earlier fixes that had a grep or none (the compile cache, the carry link, the HOME sandbox, the refusal before the compile records, the clock-bound wait, the `ls-remote` limit), each recorded failing at the commit before the earlier change and passing at the head.
- Record: every heading of the work list exactly once in `docs/findings/run-state-backlog-b.md` with its outcome, the ten claims corrected, and each heading of `run-state-backlog-c`, `-d`, and `-e` recorded not fixed and queued.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/run_state.sh`.
- Tests: `tools/tools_test.sh`.
- Docs: `docs/codebase-map.md` (the run_state.sh entry), `docs/findings/run-state-backlog-b.md`.
- Assumptions: the three environment variables `STATE_LOCK_WAIT`, `RUNNER_WAIT`, and `SCAN_TIMEOUT` exist so a case need not wait the full default; `setsid` is used where present, as the runner already does.
- README.md: unchanged, a tooling change whose behavior the README does not describe at this level.
- CLAUDE.md: unchanged, its run_state.sh bullet names no lock, wait, or scan limit.
- docs/architecture.md: unchanged, no layer, port, or rule moves.
- docs/compatibility.md: unchanged, no Neovim command is touched.
- docs/actions.md: unchanged, no action is bound or changed.
