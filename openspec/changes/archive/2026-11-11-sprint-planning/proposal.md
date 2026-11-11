# Proposal

## Why

The periodic review of the whole tree ran inside the delivery after every fifth merge and after any change to a REVIEW_AREAS path, so nearly every pipeline change paid for it, about half of a run's tokens; the queue's items pointed to backlog entries the contributor and the scouts then grepped for, so each delivery read the backlog. This change delivers decisions 15 and 16 of `tmp/briefs/pipeline-skeptic.md` (the user's decisions of 2026-11-11), replacing queue item `periodic-council`: the queue becomes a sprint of 5 self-contained changes, and a `sprint-planning` workflow, run when the sprint's 5 changes have merged, does the sprint-end review, the backlog grooming, the next sprint's queue, and the sprint's metrics row. It is outside the roadmap of `docs/architecture.md` section 12: it is delivery process.

## What Changes

- New `.claude/workflows/sprint-planning.js` (`/sprint`), fixed phases: Due (one start runs `sh tools/run_state.sh review-due`; not due ends the run at once), Review (the security reviewer and the quality reviewer over the sprint's combined diff in their sprint mode, plus the whole-tree sweep of `periodic-review.js` in every second sprint), Skeptic (the quality reviewer reads both results against the code, records only the quality findings it keeps and every security finding, one it disputes as `disputed`), Plan (the planner in its sprint mode: the backlog grooming and the next sprint's queue of 5 under `build/plan/`), and the record of the reviews.
- `tools/run_state.sh review-due` counts merges in sprints from `docs/sprints.tsv` (due at the fifth merge of the sprint, a sweep in every even sprint, not due while the sprint's plan waits in `build/plan/`); the REVIEW_AREAS triggers, `keymap_only`, and `agent_hooks` go.
- New `tools/run_state.sh backlog-dups` (the duplicate candidates: backlog entries whose headings name the same `file:line`) and `groom` (the package step applies a waiting sprint plan: the queue, the removal of the entries `build/plan/groom.txt` names, refusing a security entry removed other than by a merged item's listed heading or its fixing commit, and the sprint's row in `docs/sprints.tsv`); `plan-needed` reads the waiting sprint's queue.
- The delivery workflow no longer runs the periodic review; its close reports when `sprint-planning` is due. The scouts' grep exception goes: a delivery never reads or greps `docs/backlog.md`, the contributor only appends with `>>`.
- The planner: queue items self-contained (locations, why, fix outline, acceptance, the headings of the backlog entries they cover), its rule "Locations go in the backlog entries" reversed; a sprint mode that alone reads the backlog. `make docs-lint` checks a `## Sprint` section of the queue: 0 to 5 items, at most one `pipeline` item, T0 exempt.
- The quality reviewer gains the sprint and skeptic modes, which take the broad points (style, naming, architecture and the layer rule, duplication across changes, docs currency); the per-change review keeps correctness and tests.
- CLAUDE.md's Agents section, the agent files, `docs/goals.md` (the sprint cadence, the pace, the tracked budgets, the quality held), README, the map, and the workflow headers follow.

Out of scope: `ci-time` and the price-weighted measurement of decision 4; the `reRaised` downgrade at `.claude/workflows/deliver-change.js:802`, which the planner queues; a guard refusal of backlog reads (the cases check the agents' and workflow's text); the queue's byte budget, which stays: pool items stay short and are made self-contained when drawn into a sprint.

Assumptions:

- The sprint's plan lands through the next delivery's package step, as the planner's queue and the metrics rows already do: `sprint-planning` writes `build/plan/` and the marker `build/plan/sprint`, and `groom` applies it; a planner running before that starts from the waiting queue.
- Sprint 0 in `docs/sprints.tsv` is the seed ending at `remove-commit-hooks` (#102), so sprint 1 is `backlog-compaction`, `delivery-speed`, `pr-on-push`, `sprint-planning`, and `ci-time`, as decision 15 says.
- A backlog entry is a security entry when any of its lines says `security`; the duplicate tool matches the `file:line` its heading names.
- `/review` stays as the whole-tree review on demand, the sweep's engine.

## Capabilities

### New Capabilities

None: the change is delivery process and alters no editor behavior (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- `.claude/workflows/sprint-planning.js` (new), `.claude/commands/sprint.md` (new), `docs/sprints.tsv` (new), `.claude/workflows/deliver-change.js`, `.claude/workflows/periodic-review.js`, `tools/run_state.sh`, `tools/agent_guard.sh`, `tools/docs_lint.sh`, `tools/tools_test.sh`, the agent files, `docs/goals.md`, `docs/codebase-map.md`.
- CLAUDE.md: changed, the Agents section (sprints, the sprint-planning workflow, the backlog rule) and the commands.
- README.md: changed, the delivery process and the periodic review.
- docs/architecture.md: unchanged, section 10 names no periodic review cadence.
