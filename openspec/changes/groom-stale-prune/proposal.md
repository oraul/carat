# Proposal

## Why

`groom` (`tools/run_state.sh`) removes an old backlog entry only with a proof that it was fixed (`closed`) or that its files are gone (`gone`), and the sprint planner checks only the oldest 50 entries (`backlog-oldest`, `PRUNE_COUNT`). An entry nobody has named for three sprints, still pointing at standing files, can never leave, so the backlog only grows. The user decided on 2026-11-20 to let such entries go with their own proof and to scan the whole backlog once. The brief is `brief.md`; outside the roadmap of `docs/architecture.md` section 12, a pipeline change run by the user-approved exception.

## What Changes

- `groom` accepts a `stale HEADING` line of `groom.txt`: refused for a security entry (`security_entry`), as `closed`, `gone`, and `duplicate` are; accepted only when the commit first adding the heading line to the backlog or a findings file (`entry_added`) strictly precedes the commit adding the third-last row of the sprints file (`stale_mark`), and no later commit adds, without removing the same line in that commit, a line holding the heading's title to the backlog, a findings file, a lane queue (`docs/queue-*.md`), a `- Merged:` line included (`named_since`, over one walk of that history per groom run, `named_history`), and no lane queue nor the plan's holds the title now; a heading of only `#` marks and spaces is refused. A line a commit only moves, as groom's fold moves a findings file into the backlog or a queue item moves between the lane queues, does not count as naming it again.
- `PRUNE_COUNT` (the scan size of `backlog-oldest`) stays a constant 50; the sprint planner's scan lists every entry at the close of `PRUNE_ALL_SPRINT`, sprint-24 (the sprint in progress, one after the sprints file's last row), the one whole-backlog scan the brief asks for, since the planner's guard profile allows no assignment before a command.
- `docs/queue-backlog.md`: the Sprint 24 heading carries the user-approved exception line for this change (from the plan's rebuilt queue, applied at the package step by `plan-apply`).
- The `tools/run_state.sh` header, `.claude/agents/planner.md` step 1 (its new words kept short, so its rules stand whole within the agent budget), CLAUDE.md's Backlog line, README.md pipeline step 11, and `docs/codebase-map.md` name `stale` and the scan size.
- `tools/tools_test.sh`: cases accept `stale` for an old unnamed entry and one only folded from a findings file, refuse it for a security entry, a too-new entry, one named again since, and a sprints file with fewer than three rows, a third-last row corrected after the entry, a later `- Merged:` line, a title a lane queue still holds, and a heading with no title, and accept one whose queue item moved unchanged and was drained; `backlog-oldest` lists entries past the 50th at sprint-24's close, 50 otherwise.

Out of scope: no backlog entry is removed by this change (the Sprint 24 close's groom does); `tools/rules.sh` and `tools/agent_guard.sh` are not edited; no file of the feature lane is touched; `.claude/workflows/sprint-planning.js` keeps its command, the one-sprint scan living in `tools/run_state.sh`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `tools/run_state.sh` (`groom`, `backlog_oldest`, three new helpers `stale_mark`, `named_history`, and `named_since`, `sprint_next`, the header and the pruning constants), `tools/tools_test.sh`, `.claude/agents/planner.md`.
- README.md: changed, the grooming sentence of pipeline step 11.
- CLAUDE.md: changed, the Backlog line names stale entries among the proofs.
- docs/codebase-map.md: changed, the `groom` description of `tools/run_state.sh`; no file is added, moved, or removed.
- docs/architecture.md: unchanged, it names none of groom's kinds.
