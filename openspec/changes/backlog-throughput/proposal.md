# Proposal

## Why

The backlog grew every sprint and never shrank: 1,151 headings at the sprint-10 records, then 1,154, 1,241, 1,279, 1,313, and 1,328 at sprint-15, about 1,450 at this sprint's close, a net of about +35 a sprint, since a sprint's backlog items close about 10 to 15 entries while the reviews add about 50. The user asked how the pipeline can get through more backlog entries, keeping one appended backlog and never ignoring a review note. The planner's sprint mode, already the backlog's only reader, becomes its curator; no new agent and no new start.

This change delivers part (a) of the brief, intake and pruning at each sprint's groom; parts (b), bigger batches of small entries, and (c), fix-on-touch entries in a feature delivery's brief, are queued as `backlog-throughput-b` by the planner's split (three independently testable parts). It is outside the roadmap of `docs/architecture.md` section 12, which covers the editor; it is a pipeline change the user asked for on 2026-11-18.

## What Changes

- `groom` (`tools/run_state.sh`) reads three new kinds of `build/plan/groom.txt` line, each proven before anything is written, as groom-proof's lines are:
  - `merged KEPT <= NEAR-SAME`: the near-same entry's lines (its reasons and locations) are appended under the kept entry, after a `- Merged: NEAR-SAME` line, and its heading leaves; refused when either heading is not a backlog heading, when the two are the same, when the kept heading is itself removed by another line, or when a security entry would merge into an entry carrying no severity.
  - `closed COMMIT HEADING`: pruning an old entry fixed in any earlier sprint: the commit is in HEAD, follows the commit that first added the heading to the backlog or a findings file, and changes a file the entry names (`touches_entry`); a security entry may leave this way, by its fixing commit.
  - `gone HEADING`: the location gone: every path the entry names that the history ever held is absent at HEAD, and it names at least one; refused for a security entry.
- A new `backlog-oldest FILE...` command prints the heading lines of the first `PRUNE_COUNT` (50) entries of the files, in order (the backlog is appended, so the oldest first), leaving out those the plan's `groom.txt` already removes: the entries the planner checks against the head each sprint.
- The planner's sprint mode (`.claude/agents/planner.md`) and `.claude/workflows/sprint-planning.js` name the intake (a near-same note merged, never dropped; `duplicate` only for a text another entry already holds) and the pruning of the oldest 50 entries.
- The guard's read profile (`tools/agent_guard.sh`), which the planner runs under, allows `backlog-oldest`, as it allows `backlog-dups`.
- README.md pipeline step 11, CLAUDE.md Agents (Backlog), the `tools/run_state.sh` header, and the `docs/codebase-map.md` line of `tools/run_state.sh` describe them.

Out of scope: parts (b) and (c) (queued as `backlog-throughput-b`); `backlog-pick`'s batch sizes; any change to `listed`, `fixed`, or `duplicate`; `tools/rules.sh`; the feature lane's files.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery tooling only, no editor behavior, so it sets `skip_specs: true`.

## Impact

- `tools/run_state.sh` (`groom`, new `entry_paths`, `entry_added`, `backlog_oldest`, `PRUNE_COUNT`, the header and dispatch), `tools/tools_test.sh` (new expect cases).
- `.claude/agents/planner.md`, `.claude/workflows/sprint-planning.js`, and `tools/agent_guard.sh` (the read profile, which the planner runs under, allows `backlog-oldest`).
- README.md: changed, pipeline step 11 names the merge and the pruning.
- docs/architecture.md: unchanged, it describes the editor's layers and roadmap, not the sprint grooming.
- CLAUDE.md: changed, Agents (Backlog) names the merge and the pruning.
- docs/codebase-map.md: changed, the `tools/run_state.sh` line names the new command and groom lines.
