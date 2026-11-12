# Design

## Context

`groom` (`tools/run_state.sh`) applies a plan when `sprint_waiting` holds: the marker `build/plan/sprint` names a sprint the working `docs/sprints.tsv` lacks. `build/plan/` and the run states under `build/pipeline/` are ignored files shared by every branch of the clone, while `docs/sprints.tsv` and `docs/metrics.tsv` are tracked per branch, so two branches packaged before either merges both apply the plan and both append a run's row. `history` skips only a change with a row in the working `docs/metrics.tsv` (`has_row`). Nothing in the run state or the workflow lets a brief exclude either command. The records-only path list stands as `settled_at`'s regex, `TEST_ONLY`, and the globs of `documentation()`; `settled_at` checks path names only.

## Goals / Non-Goals

Goals: a plan and a row land once per clone, and never again on a branch behind a main that holds them; a brief can exclude both commands; one path list; an earlier sprint row edited after the review fails the gates. Non-goals: reconciling the rows already on main and jump-motions' branch; the guard; the backlog entries.

## Decisions

- The marker is the clone-wide record of a plan, so `groom` retires it (`mv` to `sprint.applied`, which no reader treats as a marker and the planner's next delivery-mode start removes as an older file) both after applying and when it finds the sprint's row already in the working or BASE's `docs/sprints.tsv`, printing `groom: sprint-N already has its row in ...; not applied again`. Alternative: keep the marker and compare only `docs/sprints.tsv`, which cannot see another unmerged branch.
- `history` records `row` (the branch) in each run state whose row it appends, and skips a run state holding one, or a change BASE's `docs/metrics.tsv` holds, printing why. `pending_list` stays as it is, so `review-due` still counts a change merged without a row on this branch. Alternative: drop it from `pending_list`, which would make the sprint count depend on the branch.
- `records=skip` is an ordinary run-state key, written by `set`, which only the workflow's unguarded record start may run for it (the guard admits the contributor's `set` for `pr` alone). `history` and `groom` take an optional CHANGE, the change whose package step runs them, and print `history: CHANGE excludes the planning records; nothing appended` (groom: `nothing applied`). The workflow queues `set CHANGE records skip` when `input.records` is `skip` or the planner returns `records: skip`; that line is no closable line, so the first `flush()` in `verify()` writes it before the package step. The package text says to run neither. Passing the change to both commands is the contributor file's one edit, within its 62 free bytes.
- `RECORDS_RE` in `tools/rules.sh`, which the gates already source; `run_state.sh` and `ci_scope.sh` source it beside their own path. `TEST_ONLY` becomes `^(test/|RECORDS_RE|$)`, `settled_at` greps `^(RECORDS_RE|$)`, and `documentation()` returns true for a records path before its case, which keeps the exclusions of the documents a test reads. A tools-test case keeps the three readers on the one name.
- Appended rows: `appended_rows COMMIT FILE` is true when FILE is absent at COMMIT, or when its blob at COMMIT is empty or ends in a line break and equals the first bytes of HEAD's blob (the hash of `head -c SIZE` of HEAD's file equals COMMIT's blob id). `settled_at` requires it when `docs/sprints.tsv` changed.

## Risks / Trade-offs

- A retired marker and a recorded `row` assume the branch that applied them merges; one that is abandoned loses that sprint's row or that run's metrics row until someone appends it by hand. That is rarer and visible (the sprint count reports the gap), where a double application silently conflicts.
- Sourcing `tools/rules.sh` from `run_state.sh` and `ci_scope.sh` makes them depend on it; every copy of `tools/` in the tests and the merge worktree carries the whole directory or already copies `rules.sh` beside `run_state.sh`.
