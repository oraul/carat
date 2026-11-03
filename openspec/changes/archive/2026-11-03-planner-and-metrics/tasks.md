# Tasks

## 1. Measurement

- [x] 1.1 Add `--fields` to `tools/analysis_budget.sh` and add `tools/metrics.sh` (`measure`, `compare`); verify with `make tools-test`.
- [x] 1.2 Add `make metrics` to `CHECK_STAGES` and `make metrics-compare` to the Makefile; verify with `make metrics` and `make metrics-compare BASE_METRICS=build/metrics/current.tsv`.
- [x] 1.3 Measure on pushes to `main`, save it in the Actions cache, and compare pull requests with it in `.github/workflows/ci.yml`; verify by reading it against the Makefile and by CI on the pull request.

## 2. Run state and history

- [x] 2.1 Add `metric`, `metrics`, `note`, `pending`, `history`, and `review-due` to `tools/run_state.sh`, count gate failures in `push`, add the phases `plan` and `retro`, and print the first-pass rates in `status`; verify with `make tools-test`.
- [x] 2.2 Let `docs/queue.md`, `docs/goals.md`, and `docs/metrics.tsv` change after the reviewed commit in `tools/gates.sh`, and treat `docs/metrics.tsv` as documentation in `tools/ci_scope.sh`; verify with `make tools-test`.
- [x] 2.3 Add `docs/metrics.tsv` with its header; verify with `sh tools/run_state.sh status`.

## 3. Agents, workflows, and commands

- [x] 3.1 Add the `planner` and `retrospective` agents; verify each against its phase and that neither edits a tracked file.
- [x] 3.2 Add the periodic mode to the security and quality reviewers and `.claude/workflows/periodic-review.js`; verify with `node --check`.
- [x] 3.3 Add the Plan, Retrospective, and Review phases and the per-phase measurement to `.claude/workflows/deliver-change.js`; verify with `node --check` and by reading it against the design.
- [x] 3.4 Update the benchmark, contributor (brief, package records), and reporter agents; verify by reading them against `CLAUDE.md`.
- [x] 3.5 Add `.claude/commands/plan.md` and `review.md`; verify by reading them against the agents and the workflow.

## 4. Docs

- [x] 4.1 Update `CLAUDE.md` (Agents, Commands, Layout), the code map area 1, and `docs/queue.md`; verify with `make lint` and `make gates`.
- [x] 4.2 Extend the README section on how carat is built with AI; verify by reading it against what this change ships.
