chore(groom): prune backlog entries no one named for three sprints

## Summary

The backlog grooming tool now accepts a stale proof: an old non-security entry that nobody has named for three sprints can leave the backlog, and the planner's sprint-24 close scans every entry instead of the oldest 50. Before this, an entry could leave only if it was fixed or its files were gone, so entries that pointed at files still in the tree stayed forever and the backlog only grew. This follows the user's backlog decision of 2026-11-20 and removes no entry itself; the Sprint 24 close's groom does that.

---

## Changes

- Add the `stale HEADING` kind to `tools/run_state.sh groom`: it is refused for a security entry and accepted only when the commit that first added the heading comes before the commit that added the third-last row of `docs/sprints.tsv`, no later commit adds a line naming its title to the backlog, a findings file, a lane queue, or a `- Merged:` line, and no current lane queue or plan queue holds the title.
- Count only new lines as naming an entry again: a line a commit just moves, such as groom's fold of a findings file or a queue item moving between lanes, does not count, and a heading with no title is refused.
- Change `backlog-oldest` to list every backlog entry at the sprint-24 close (`PRUNE_ALL_SPRINT`) and keep the oldest 50 (`PRUNE_COUNT`) for every other sprint.
- Add `tools/tools_test.sh` cases that accept stale for an old unnamed entry, one folded from a findings file, and one whose queue item moved unchanged and was drained; refuse it for a security entry, a too-new entry, an entry named again since, fewer than three sprint rows, a third-last row corrected after the entry, a later `- Merged:` line, a title a lane queue or the plan queue still holds, and a heading with no title; and show the whole-backlog scan listing entries past the 50th.
- Document the stale proof and the scan size in the `tools/run_state.sh` header, `.claude/agents/planner.md`, CLAUDE.md, README.md, and `docs/codebase-map.md`.
- Add the user-approved exception line for this change under the Sprint 24 heading of `docs/queue-backlog.md`, and record the backlog lane's queue and metrics history row.
- Record the review advisories this change does not fix in `docs/findings/groom-stale-prune.md`.

---

## Testing

- Run the security review on the committed diff at 530e0e955f9e: passed, no High, Medium, or Low findings.
- Run the quality review at 530e0e955f9e: passed, no blocking findings and one advisory, which is recorded in the findings file.
- Run the benchmark review at 530e0e955f9e: passed, no blocking findings.
- Run the checker's stages at 530e0e955f9e (gates, docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, metrics): all pass.
- Run `make gates` and `make docs-lint` before the push: both pass.

---

## Notes

The Sprint 24 close's groom does the actual pruning. `PRUNE_ALL_SPRINT` names sprint-24 because the planner's guard profile does not allow setting a variable before a command; the findings file has a follow-up to remove that constant once Sprint 24 closes. `docs/architecture.md` is unchanged because it does not name groom's kinds. No file of the feature lane is touched and `tools/rules.sh` is not edited.
