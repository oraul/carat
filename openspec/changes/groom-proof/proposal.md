# Proposal

## Why

`groom` (`tools/run_state.sh`) removes backlog entries on the sprint planner's word without proof: a `listed CHANGE HEADING` line passes for any archived change whose name ends in CHANGE, whatever sprint merged it and whether its queue item named the heading, and a `fixed COMMIT HEADING` line passes for any ancestor of HEAD, the root commit included, touching any file. So a security entry can leave the backlog unfixed (`sprint-planning` security Low (6)). Its duplicate guard refuses any entry whose text holds the word security, so the retro entry that only quotes the "Security first section" of CLAUDE.md could not leave as a duplicate and stopped sprint-17-records. The brief is `brief.md`; outside the roadmap of `docs/architecture.md` section 12, a pipeline defect.

This is part a of the brief's item, as the planner split it: groom's proofs and its guard. Part b, `sprint-review-continuation` (the sprint security continuation that drops differently spelled unreviewed files, and the capped sprint quality review with no continuation, both in `.claude/workflows/sprint-planning.js`), is queued separately.

## What Changes

- `listed CHANGE HEADING` passes only when CHANGE is one of the sprint's merged changes (`sprint_names`) and its queue item (the numbered item naming it, its wrapped lines joined, in the queue at the parent of its merged commit, else at that commit) holds the whole heading line.
- `fixed COMMIT HEADING` passes only when COMMIT is in HEAD, inside the sprint's range (after the sprint's base, `sprint_base`, which must name a commit), and changes a file the entry names (in its heading or its `- Location:` or `- Where:` lines, or anywhere in an entry with neither, a group of findings), as a whole path token.
- The duplicate guard refuses only an entry carrying a security severity marker (`security High`, `Medium`, or `Low`, a plural included, any case), so an entry that only mentions security leaves as a duplicate.
- `tools/tools_test.sh`: the groom fixture's sprint rows name real commits and a queue item listing a heading; new cases refuse a `listed` change outside the sprint and one whose item lacks the heading, refuse a `fixed` commit at or before the sprint's base and one touching no file of the entry, accept a group entry's fix by a commit touching a file it names, and remove a duplicate whose text only mentions security.

Out of scope: `.claude/workflows/sprint-planning.js` (part b); `tools/rules.sh` is not edited; no file of the feature lane is touched; no backlog entry is removed by this change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the delivery pipeline is described by no spec under `openspec/specs/` (`skip_specs: true`).

## Impact

- `tools/run_state.sh` (`groom`, two new helpers, its header), `tools/tools_test.sh`, `.claude/agents/planner.md` (the `fixed` line's meaning).
- README.md: changed, the grooming sentence of pipeline step 11.
- docs/codebase-map.md: changed, the `groom` description of `tools/run_state.sh`; no file is added, moved, or removed.
- CLAUDE.md: unchanged, its Backlog line (a security entry leaving only by a merged item's heading or its fixing commit) still holds, now proven, and it stands at its byte budget.
- docs/architecture.md: unchanged, it does not describe groom.
