# Design

## Context

`groom` checks every line of `groom.txt` before it writes anything. `entry_added` already finds the oldest commit changing how often a whole heading line stands in the backlog or a findings file (the `closed` proof); `security_entry` is the one judgement of security; `sprint_state` reads only the last row of the sprints file. `backlog_oldest` stops at `PRUNE_COUNT`, a plain assignment. The planner runs under the `read` profile of `tools/agent_guard.sh`, which refuses an assignment before `sh`.

## Decisions

- Age: the third-last data row of the sprints file (the header left out) marks three sprints ago; its commit is the newest commit whose diff changes how often a line starting with that row's sprint name and a tab stands in the file (`git log --pickaxe-regex -S`), so a later correction of the row's other fields does not move the mark. The entry's adding commit must be a strict ancestor of it: an entry added by the same commit (a records change appending `groomed.md` with its row) waits one more sprint. Fewer than three rows, or a row no commit added, refuses the line.
- Named again: the commits after the adding one up to HEAD, merges left out as `git log -p` shows them, over the backlog, the findings directory, and `docs/queue-*.md`; in each commit an added line holding the title (the heading less its `#` marks) counts unless the same line is removed in that commit, so groom's fold (a findings file's lines moved into the backlog) and a queue item moved unchanged do not count, while a queue item or `- Merged:` line written anew does. A title standing inside a longer heading counts too, which only keeps an entry.
- Scan size: `PRUNE_COUNT=50` stays a constant, one way to ask for the whole scan: a constant `PRUNE_ALL_SPRINT=sprint-24` makes the scan whole when the sprint in progress is sprint-24, the close the user named, since the planner cannot set the variable under its guard and the workflow starts it with a prompt only. After that sprint the default holds again; removing the then dead constant is recorded in `docs/findings/groom-stale-prune.md`.

## Risks

- A note still relevant but unnamed for three sprints leaves the backlog; the planner judges each stale line, groom proves only age and silence, and a security entry never leaves this way.
- The whole scan prints every entry once at sprint-24's close, a longer planner input for one sprint.
