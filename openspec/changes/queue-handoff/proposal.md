# Proposal

## Why

The user is putting the project on hold and resetting the main session, whose notes live only in that session. The queue order the user asked for (the Spinel bump first, then the `gd` ghost-tab bug the user reported, then the finder extras and the scheduled features) and the user's standing decisions must therefore live in the repository, where `/status` and `/deliver` find them after the hold. The periodic review at ce6abdb also left findings in the run state of `indent-guides` that only the planner's notes carry, and they would be lost with the session. This change is outside the editor roadmap of `docs/architecture.md` section 12: it changes documents only.

## What Changes

- `docs/queue.md` becomes the planner's queue: `spinel-bump` (move `SPINEL_REF` from 001419ff to the upstream head, its own pull request, no regression in allocations, rounds, or analysis time, the recorded miscompilations re-tested), `gd-ghost-tab` (reproduce the ghost tab `gd` leaves, fix it with a table-driven test), `finder-grep`, `finder-pickers`, `markdown-preview`, `periodic-blockers-b`, `csv-viewer`, `backlog-compaction`, then the rest in the planner's order, each with a tier, a size, the problem, and the acceptance. Its header says the project holds and how it resumes.
- The queue's Decisions section records the user's standing decisions: the UI first, then code intelligence; at most one pipeline change per three features, T0 security findings and crashes first; the security reviewer never on a cheaper tier or a lower effort (these three are already rules of `docs/goals.md`, which stays unchanged); indent guides kept in the core renderer for the per-key allocation budget; the session-link footer added by the GitHub tool outside the repository, so only the package step's removal remains; parked and not scheduled: `image-viewer`, the mouse, and a chart of CSV columns.
- `docs/backlog.md`: the periodic findings at ce6abdb are recorded. Each one whose location an entry already names is folded into that entry as a "Raised again at ce6abdb" note (30 entries); the rest become 9 new entries; the stale UI group count entry (41 against 49) is replaced by the current one (49 and 41 against 51). The session-link footer entry says the user confirmed it as standing, and the `image-viewer` entry says it is under discussion and parked, and that GNOME Terminal needs the plugin's own PNG decoder.
- `README.md`: the paragraph on where the plan lives gives the goals' current order and says how the queue resumes after a hold: `/status`, then `/deliver` with the first item.

Assumptions:

- The brief's item 3, `finder-extras`, is split by the planner into `finder-grep` and `finder-pickers` (items 3 and 4), since together they are large outside the roadmap, as `file-finder` was; the brief's order is otherwise kept, items 4 to 7 moving to 5 to 8.
- The brief estimated small; the planner estimated medium from comparable docs-only rows.
- The planner's queue is copied as written: it is 17,313 of the 17,369 bytes `tools/docs_lint.sh` allows, and no budget is raised.

Out of scope: any code change, any budget change, the fixes the queued items name, and merging the backlog's duplicate entries (queued in `backlog-compaction`).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches documents only and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `docs/queue.md`, `docs/backlog.md`, `README.md`; `docs/metrics.tsv` at the package step.
- `docs/goals.md`: unchanged, it already states the three standing rules.
- `CLAUDE.md`: unchanged, no agent, workflow, command, or target changes, and its Status line already points to `docs/queue.md`.
- `docs/architecture.md`: unchanged, no spec or design changes.
