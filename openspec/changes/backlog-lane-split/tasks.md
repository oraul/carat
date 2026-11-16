# Tasks

## 1. Carry backlog-lane-a

- [x] 1.1 Cherry-pick the implementation commits 28e3040, 64f71f1, cac79e5, 6fa3542, b8480ad, c192eb9 in order, without the `openspec/changes/backlog-lane-a` directory; a28599a touches only that directory and is skipped; the archive, records, and pull request text commits (bf5f439, 87311b9, fa3947b) are left behind

## 2. Lanes in the run state

- [x] 2.1 `history_rows`, `lane_rows`, `lane_of`, `queue_at`, and the `lane` command in `tools/run_state.sh`, history appending to the lane file; proved by "run_state: history appends a change with no lane queue item and a feat squash to the feature lane" and the existing history and review-due cases in `tools/tools_test.sh`
- [x] 2.2 `estimate_of`, `exception_item`, and `plan_needed` read the lane queues; proved by "run_state: review-due leaves out a change the exception line of its merged commit's queue names" and the estimate and plan-needed cases; the fallback of `queue_at` to the one queue at a commit before the lanes proved by "run_state: history reads the estimate from the one queue at a squash parent before the lanes"
- [x] 2.3 `lane_of` falls back to the feature lane; proved by "run_state: a squash subject of no known type goes to the feature lane"
- [x] 2.4 `history` strips each lane file's header at BASE; proved by "run_state: history reads no lane file's header at BASE as a row"
- [x] 2.5 The BASE-names-no-commit case asserts its one row; "run_state: a BASE that names no commit leaves the order to HEAD's ancestry, a row it holds the newest"
- [x] 2.6 Late findings to `docs/findings/`, folded by `groom`, read by `backlog-dups`; proved by "run_state: groom folds two changes' findings into the backlog and removes their files" and "run_state: history appends a merged run's late findings to its findings file"

## 3. Lint, gates, migration

- [x] 3.1 `tools/docs_lint.sh`: the shared lane budget and lane sprint shapes; the pipeline limit counted over both lanes' sprint sections, proved by "docs_lint: a pipeline defect in each lane's sprint is two for the sprint and fails" and "docs_lint: an exception line in either lane lifts the sprint's pipeline limit"
- [x] 3.2 The retired paths only in `docs/backlog.md`; proved by "docs_lint: the backlog may name the retired queue and history", "docs_lint: the backlog naming a path that never existed fails", and "docs_lint: another document naming a retired path fails"
- [x] 3.3 `tools/rules.sh` RECORDS_RE names the lane files and `docs/findings/`; proved by the scope cases for `docs/metrics-backlog.tsv`, `docs/findings/x.md`, and `docs/queue-feature.md`
- [x] 3.4 The rows of `docs/metrics.tsv` and the items of `docs/queue.md` moved into the lane files, none lost, the old files removed

## 4. Agents, workflow, docs

- [x] 4.1 The planner, contributor (findings file after `mkdir -p docs/findings`, conflict rules), checker, quality reviewer, retrospective, the commands, and `.claude/workflows/deliver-change.js` (the `mkdir -p` in the package prompt)
- [x] 4.2 CLAUDE.md (the `ci-stages CHANGE COMMIT` and `tokens CHANGE DIR` descriptions restored), README.md (main's merge order), docs/goals.md, docs/codebase-map.md, the `tools/gates.sh` settled_at comment rewrapped
- [x] 4.3 Run `make tools-test` (1331 cases, 102 s against main's 103 to 105 s), `make docs-lint`, `make gates`, `make spec-validate`
