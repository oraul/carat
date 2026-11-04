# Proposal

## Why

A change takes about an hour and 1.1M to 1.7M total tokens, input plus output, while the size budgets count output tokens only, so the cost the user pays is never measured or held to a budget. `guard-allowlist` spent 860,176 output tokens and about 2.9M total over two starts and reached 5 rework rounds, because each start counted its rounds from 1 (`.claude/workflows/deliver-change.js:328`). The periodic review ran after 4 of the last 5 changes, at 32k to 89k output tokens each, mostly because every tooling change counted as a sensitive area, and the planner ran on every change at 20k to 39k output tokens even when the next item only had to be taken as written. The user made token and pipeline efficiency goal 1 and security goal 2. This is part A of `pipeline-speed`, the plan and the measures; part B (`pipeline-speed-b`) and the rest (`pipeline-speed-c`) follow in the queue.

## What Changes

- Goals: `docs/goals.md` (from the planner's `build/plan/goals.md`, committed by the package step) makes token and pipeline efficiency goal 1 and security goal 2, with T1 covering pipeline defects and efficiency. `CLAUDE.md`'s hard rule says blocking security fixes go to the front of the queue; room for the edit is taken from wording elsewhere in the file.
- Totals: `sh tools/run_state.sh usage CHANGE TOKENS MINUTES` adds one start's total tokens and wall minutes, as the Workflow tool reports them, to the run state; `/deliver` runs it after each start. `docs/metrics.tsv` gains the columns `total_tokens` and `wall_min` after `estimate`. `budget` compares total tokens with the new budgets (small 500k and 25 minutes, medium 1.2M, large 2.5M) and names the output tokens beside them. The retrospective flags an overrun of the change of the history's last row, the newest run whose totals are final.
- Rework: the three-round limit holds across starts. The rounds are counted from `metric.rework`, which the checker now stores before each check, and the CI fixes share the limit. A resume of a run that already spent rounds gets one extra round when its previous start did not stop at the limit (a killed stage, a container restart), recorded as `metric.extra` and an `extra-round` note with the reason; `metric.stop` records whether a start stopped at the limit.
- Periodic review: `REVIEW_AREAS` replaces "tooling and CI" with "guard and gates" (`tools/agent_guard.sh`, `tools/gates.sh`, `tools/rules.sh`, `.claude/settings.json`, the CI workflows, and an agent file whose tools or hook lines change); other tooling, docs-only, and keymap-only changes only count toward the five.
- Planner: `sh tools/run_state.sh plan-needed CHANGE` says whether the queue needs a decision: the change is not the head of `docs/queue.md`, or a merged run without a history row holds a retrospective proposal, an overrun, or a periodic finding. The workflow starts the planner only then, or for a brief that is more than the change name; otherwise it takes the head item's estimate and records the plan phase, and the package step removes the item from `docs/queue.md` instead of copying `build/plan/`.
- Docs: `CLAUDE.md`, `README.md`, `docs/codebase-map.md`, the agent and command files, `docs/backlog.md` (goal numbers and Queued lines the planner named), and `docs/metrics.tsv` (the two new columns on every row).

## Capabilities

### New Capabilities

None. The change alters only the delivery tooling and its documents, which no spec under `openspec/specs/` describes; `.openspec.yaml` sets `skip_specs: true`.

### Modified Capabilities

None.

## Impact

Outside the roadmap of `docs/architecture.md` section 12: delivery tooling under the new goal 1. No file under `carat/`, `bin/`, `test/`, or `config/` changes, so the editor and its benchmarks are unaffected.

Out of scope, queued as `pipeline-speed-b` and `pipeline-speed-c`: parallel quality and security reviews, skipping a repeated check or compile stages, fix-diff-only reviews, one agent for record, retrospective, and report, short briefs for agents that do not edit, a work-in-progress backup push, killed stages reported as killed, and the merger's re-check of the pushed head.

## Assumptions

- Neither the workflow script nor its agents can read input tokens or the clock (the runtime counts output tokens only and refuses `Date.now()`), so the main session that ran the Workflow tool records each start's totals from the tool's result; a start whose result never reaches it (a killed container) leaves its totals unrecorded.
- Only the small size has a wall-time budget, 25 minutes, as the brief gives none for the others.
- A fix round is stored when the next check starts; a start killed during a fix loses that one count, and its resume gets the extra round anyway.
- A CI fix counts toward the same three rounds as a review fix, as `CLAUDE.md` already states ("a red CI included ... at most three rounds").
- Retrospective proposals count as a decision for the planner, since only the planner places them and the history row drops them otherwise.
