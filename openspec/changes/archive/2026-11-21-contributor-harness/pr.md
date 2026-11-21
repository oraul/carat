chore(tools): read lane facts from git with a harness script

## Summary

Adds `tools/lane_facts.sh`, which prints a lane's head, branch, base, push state, uncommitted path count, and last check verdict as key value lines read from git and the check log, and makes the delivery workflow read the head from git instead of trusting a hand-copied one. Agents had to remember `git rev-parse --short=12` and copy the hash by hand, and in #265 a placeholder head over committed work was refused, escalated every later start of the run, and restarted a start that had nothing left to redo.

---

## Changes

- Add `tools/lane_facts.sh CHANGE`, printing `head`, `branch`, `base`, `pushed`, `dirty` (or `unknown` when git status fails), `check`, and `check_at` from the main checkout or the lane, and exiting 2 on a bad name or a missing lane.
- Change `deliver-change.js` to read the lane facts after every contributor start and take a head that differs only in form (placeholder, short hash, upper case) from a committed lane head from git with a `head-form` note, without refusal, escalation, or restart, while a dirty or unreadable lane and a head that is not the lane's are refused as before.
- Change the contributor rules card, in the agent file and the workflow, the head restart text, and the contributor work schema to point at the `head` line of `tools/lane_facts.sh` instead of a hand-copied hash.
- Change `tools/agent_guard.sh` to let every profile run `sh tools/lane_facts.sh CHANGE`, the merger only from the main checkout and never the branch's copy after a cd into a worktree.
- Add `tools/tools_test.sh` cases for the script's lines and refusals on a test repository with a lane worktree, the workflow's head-form handling over a stubbed agent, and the guard forms.
- Document the script and the head-form rule in CLAUDE.md Commands, README.md, `docs/goals.md`, and `docs/codebase-map.md` area 1.
- Change the reason of the existing Sprint 25 exception line for this change to the self-check council, remove `head-form-restart` from Pool 11, and apply the plan queue updates in `docs/queue-backlog.md`, and append the lane-isolation metrics row.
- Record two findings in `docs/findings/contributor-harness.md`: the merger and quality reviewer still copying main's short hash by hand, and the merger profile still running a worktree's `run_state.sh` and `ci_wait.sh`.

---

## Testing

- Run the security review on the committed diff, pass with 0 High, 0 Medium, and 1 Low, recorded in the findings file
- Run the checker stages docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, and metrics at the reviewed commit, all pass
- Run the benchmark review, pass with no blocking change
- Run `make spec-validate` after the archive, 55 passed and 0 failed
- Run `make gates` and `make docs-lint` before the push, both pass

---

## Notes

The change edits only delivery tooling and docs, so its OpenSpec change has no delta specs and is archived with skip specs, and `docs/architecture.md` stays unchanged since no layer, port, or roadmap item moves. `tools/rules.sh` is untouched. The wider refusal of every merger `tools/*.sh` form after a cd into a worktree predates this change and is left as a finding. The Resume agent prompt and its schema still ask for `git rev-parse --short=12 HEAD` and are unchanged by this diff.
