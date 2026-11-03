# Proposal

## Why

The delivery workflow forgets everything when a run ends: no file records what a change cost (allocations, analysis rounds, CI minutes, tokens, tool calls) or how often each gate passed the first time, so the queue in `docs/queue.md` is ordered by judgment, not data, and no one can tell whether a later change to the pipeline helped. CI checks one absolute allocation budget and never compares with `main`, the workflow has no step that learns from a run, and the whole-codebase security review that `docs/goals.md` promises every five changes has no trigger. This is item 2 of `docs/queue.md`, placed before `authoring-kit` so later decisions have a baseline.

## What Changes

- Add a `planner` agent that runs in a new Plan phase at the start of every delivery and on `/plan`: it reads the metrics history, the pending run states (metrics, retrospective proposals, periodic review findings), the backlog, the goals, and the queue, writes the next `docs/queue.md` (and `docs/goals.md` only on the user's request) under `build/plan/`, cites a metric, finding, or request for every decision, and stops the run when an unresolved blocking security finding should go first.
- Archive each change's brief: the contributor writes it verbatim to `openspec/changes/<change>/brief.md`, which the archive keeps.
- Add a metrics history, `docs/metrics.tsv`, one row per merged change (bench allocations and time per key, analysis rounds, CI minutes, output tokens and tool calls per phase, first-pass results per gate, rework rounds, periodic review), written only by `tools/run_state.sh` through the new commands `metric`, `metrics`, `note`, `pending`, `history`, and `review-due`; `status` adds the first-pass rates.
- Add `tools/metrics.sh` (`measure`, `compare`), the stage `make metrics` in `CHECK_STAGES`, and `make metrics-compare`: allocations and time per key of eight scenarios and the analysis rounds and milliseconds of both compile roots, compared with a base that fails on more allocations or rounds and warns on time.
- Compare with `main` in CI: a push to `main` saves its measurements in the Actions cache, and a pull request restores the newest and runs `make metrics-compare`.
- Add a `retrospective` agent that runs after each merge: it records the run's metrics, proposes at most three simplifications or improvements of the workflow, its script, or the agents, each citing a metric, and says whether a periodic review is due.
- Add `.claude/workflows/periodic-review.js`, a whole-codebase security review and quality review in a periodic mode of the two reviewers, which the delivery workflow runs every five merged changes and after a change to config loading, file access, plugin boundaries, terminal output, or process spawning, and `/review` runs on demand.
- Add the `/plan` and `/review` commands; have the workflow time each phase's output tokens and collect each agent's tool calls, first-pass results, rework rounds, and CI minutes.
- Simplify the benchmark agent around `tools/metrics.sh`; extend the README section on how AI builds carat, and update `CLAUDE.md`, the code map, and `docs/queue.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a tooling, agent, CI, and documentation change with no change to the editor's behavior; `skip_specs` is set.

## Impact

- New: `.claude/agents/planner.md`, `.claude/agents/retrospective.md`, `.claude/workflows/periodic-review.js`, `.claude/commands/plan.md`, `.claude/commands/review.md`, `tools/metrics.sh`, `docs/metrics.tsv`.
- Changed: `.claude/workflows/deliver-change.js`, `.claude/agents/benchmark.md`, `contributor.md`, `security-reviewer.md`, `quality-reviewer.md`, `reporter.md`, `tools/run_state.sh`, `tools/gates.sh`, `tools/ci_scope.sh`, `tools/analysis_budget.sh`, `tools/tools_test.sh`, `Makefile`, `.github/workflows/ci.yml`, `CLAUDE.md`, `README.md`, `docs/codebase-map.md`, `docs/queue.md`.
- No file under `carat/`, `bin/`, `test/`, or `bench/` changes; the editor binary is unchanged.

This change is outside the roadmap of `docs/architecture.md` section 12: it is the second of the three tooling changes the user asked for before more features (`docs/queue.md` item 2).

Out of scope: golden examples, generators, Spinel notes, and the docs size gate (`authoring-kit`); acting on any retrospective proposal or periodic review finding (each becomes a queue item for a later change); exact token counts per agent, which the workflow runtime does not expose.

Assumptions recorded instead of asked:

- What a run learns after its merge (CI minutes, the retrospective, a periodic review) cannot be committed by that run, since `main` takes only pull requests. The next change carries it: its package step appends the history rows of the merged run states and applies the planner's queue, as it carries its own archived OpenSpec change. A run state lost before the next change (a fresh workspace) loses that row; the pull request and the report still hold its figures.
- Tokens per phase are the output tokens the workflow runtime reports (`budget.spent()` before and after the phase); tool calls are what each agent reports in an optional schema field. Both are labelled as such in the history.
- "Gate first-pass rates" are the first verdicts of the check, quality, security, benchmark, and CI phases, plus whether the pre-push gates passed at the first push attempt.
- The CI comparison fails open when no measurement of `main` is cached (a notice, not a failure): the benchmark agent's comparison with `main` in the pipeline stays the blocking one.
- The planner, like the scouts, writes only under an ignored directory (`build/plan/`); the contributor stays the only agent that edits tracked files, so the queue changes only through a delivered change.
