fix(tools): lock the run state and harden the check runner and escape scan

## Summary

Gives every heading of the run_state.sh backlog work list for the check runner and escape scan theme an outcome with proof: fixes with a tools-test case that fails at the base and passes at the head, earlier fixes with a behavior case, and the rest recorded with evidence or a reason. The run state writer, the detached check runner, and the escape scan had races and holes that could lose a record, leave a runner alive, or let a stage write after the scan. The groom, plan, and push themes are queued as run-state-backlog-c, -d, and -e.

---

## Changes

- Add a lock directory holding a pid file beside the run state, so the detached runner and a caller rewriting it at once lose no record; a live holder makes a write wait and refuse, and a dead holder's lock is taken over.
- Fix a lost check runner: its process group is stopped before a second runner starts, and each stage job runs in its own session whose group is killed when the job ends.
- Change the escape scan so a branch is skipped only when it is new and its worktree lies under a lane path, the escaped-path list is filtered before it reaches the terminal, the remote probe has a time limit, and a file a stage planted under the main checkout's build directory is removed.
- Add tools-test cases for the earlier fixes that had a grep or none, each recorded failing at the commit before the earlier change and passing at the head.
- Record every heading of the work list exactly once in docs/findings/run-state-backlog-b.md with its outcome, correct the ten claims the code did not back, and record the groom, plan, and push themes as not fixed and queued.
- Append the planner's queue and the metrics history rows, and update the run_state.sh entry of the code map.

---

## Testing

- Run the tools-test stage at the head of the change, passes
- Run the fast and CI stages of the check (docs-lint, gates, dev-build, test-build, test-run, diagnose, bench-budget, metrics), all pass
- Run the security review of the committed diff, passes with no blocking finding and one Low, recorded in the findings file
- Run the benchmark review, passes with no blocking finding
- Run make spec-validate after the archive, all 56 items pass

---

## Notes

The three non-blocking security Lows about escaped_revert and state_lock (its pid is still written after the directory is made) are recorded in docs/findings/run-state-backlog-b.md with fix outlines. No change touches tools/rules.sh. Headings that need an operating-system sandbox are recorded not fixed with the reason.
