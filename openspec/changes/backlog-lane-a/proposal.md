# Proposal

## Why

Changes in flight conflict on three shared records: every package step rewrites `docs/queue.md`, appends a row to `docs/metrics.tsv`, and appends findings to the end of `docs/backlog.md`, so two branches open at once collide on the same lines (T1 pipeline, user request, estimated medium). The user asked for lanes: the features and the backlog work each keep their own queue and history, and findings land in a file per change that the sprint grooming folds into the backlog.

## What Changes

- The queue splits into `docs/queue-feature.md` (the sprint's 3 features, the feature pool, the user's guide) and `docs/queue-backlog.md` (the sprint's 2 backlog changes: fixes, tidy-ups, docs, tooling, and a pipeline change only for a defect; the backlog pool), each with its own `## Sprint N`, `## Pool`, and `## Decisions`. The planner writes `build/plan/queue-feature.md` and `build/plan/queue-backlog.md`, and `groom` copies each over its `docs/` lane file.
- The metrics history splits into `docs/metrics-feature.tsv` and `docs/metrics-backlog.tsv`, the same header. The lane of a change is recorded by the file its row goes to: the lane file of its queue item at the parent of its squash commit, else its squash subject (`feat` the feature lane, another Conventional Commits type the backlog lane), else the feature lane; `sh tools/run_state.sh lane CHANGE` prints it. Readers that need the order (status, bench, review-due, groom's sprint row, plan-needed's merged-since) read both lanes merged by the committer time of each row's merged commit.
- Findings: the package step writes the non-blocking findings it is handed to `docs/findings/<change>.md` (with `>>`) instead of `docs/backlog.md`, and `history` writes a merged run's late findings to `docs/findings/<that change>.md`. `groom`, applying the planner's sprint plan, folds every findings file into `docs/backlog.md` (in name order) and removes it; its groom lines may name headings of the folded files; `backlog-dups` reads the backlog with the findings files.
- The sprint shape: 3 features and 2 backlog changes, a pipeline change only for a defect (T0 exempt; a `The user-approved exception` line lifts it). `make docs-lint` checks each lane file: tier and size per item, at most 3 sprint items in the feature lane and 2 in the backlog lane, a pipeline sprint item only for a defect; the two lane files share the queue's byte budget (`QUEUE_BUDGET`, 17,369 bytes plus 600 for the second file's title and opening line); `check_paths` lets older records, the backlog's entries among them, name the two retired paths.
- Exemptions: `exception_item` and `estimate_of` read the lane files at a commit, and `docs/queue.md` only at a commit predating the split, so the history before it stays readable; `exception_item` also accepts the unnumbered `The user-approved exception: \`NAME\` (...)` line, and reads the merged commit's own queue when the parent's item lacks the mark, so a change the plan its package step applied names as beyond the sprint is not counted (this change, Sprint 10's exemption).
- The contributor's conflict rules: keep both sides of an appended file, regenerate a generated file with its `make` target, stop and name a conflict where both sides changed the same logic; a conflict fix stays in the same change and the checks and reviews run again.
- Records: `tools/rules.sh` RECORDS_RE names the lane files and `docs/findings/`; every script, agent, command, workflow, and doc naming the old paths names the new ones.
- Migration: the current rows of `docs/metrics.tsv` move into the lane files by their squash subject, none lost; the current `docs/queue.md` items move into the lane files; the old files are removed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `tools/rules.sh`, `tools/docs_lint.sh`, `tools/gates.sh` (header), `tools/ci_wait.sh` (comment), `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `.claude/agents/` (planner, contributor, checker, quality reviewer, retrospective), `.claude/commands/` (plan, review, sprint, status).
- `docs/queue-feature.md`, `docs/queue-backlog.md`, `docs/metrics-feature.tsv`, `docs/metrics-backlog.tsv` added; `docs/queue.md`, `docs/metrics.tsv` removed; `docs/findings/` holds one file per change until the next sprint grooming.
- README.md: changed, the pipeline steps, the docs-lint budgets, and the sprint shape.
- CLAUDE.md: changed, the Status, Agents, Commands, and coding-convention lines naming the old paths and the sprint shape.
- docs/architecture.md: unchanged, it names `docs/backlog.md` only as the store of open items, which stays.
- docs/codebase-map.md: changed, the entries naming the old paths; no file under a mapped directory is added or removed.
- docs/goals.md: changed, the sprint shape and the paths.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline change (T1) the user requested, Sprint 10's exemption. One reviewable pull request; `backlog-lane-b` (Sprint 11) takes the backlog lane's selection rules.

Minor assumptions: the guide stays in the feature lane file and each lane keeps its own decisions; a row whose merged commit git does not know sorts first, keeping its file order; reading `docs/queue.md` at commits before the split is the one kept reader of an old path, as it reads history, never the working tree; the existing rows are classified by squash subject, a row without a known commit going to the feature lane.

## Out of scope

- How the backlog lane picks its entries (`backlog-lane-b`), and any separate calibration of the backlog lane: its budgets, call caps, tiers, and scout and benchmark rules are judged from `docs/metrics-backlog.tsv` after about 5 backlog runs, a separate workflow only if its phases differ.
- Reordering the queue beyond what the waiting sprint plan already holds.
