# Proposal

## Why

Every pull request runs the release build (63 s) and its smoke test (23 s) beside the 84 s compile of the development builds (#140), although the smoke test already runs on the development editor in the `Test` step, and one workflow, `.github/workflows/ci.yml`, serves both pull requests and pushes to `main`, so an equal-tree push to `main` still runs five compiling steps. `tools/run_state.sh ci-stages` reads each CI step's seconds as whole seconds and drops a step under one second, so a fractional step is lost.

## What Changes

- `.github/workflows/ci.yml` runs on pull requests only: the full checks under the job `spin`, the required check name kept, with the comparison with main's measurement; the release build, its smoke test, and keeping main's measurement leave it.
- A new `.github/workflows/main.yml`, the workflow `main` with the job `main`, runs on a push to `main` (and by hand) only: the measurement of `main` and its save, the compile-cache warming, the release build and its smoke test; the full checks only when `tools/ci_scope.sh` answers `run=true` (the squash tree differs from the passed head with code changed); nothing compiles when the tree equals the passed head and the compile cache already holds the exact entry of these sources.
- `tools/ci_scope.sh` writes a third output, `compile`: `true` when the checks run, and on a push also when the compile cache's exact entry is missing (`CACHED`, from a lookup-only probe of that entry), else `false`.
- `tools/run_state.sh ci-stages` computes each step's seconds with their fraction, rounded to a tenth, and keeps every step that rounds above zero.
- Cases in `tools/tools_test.sh` prove the equal-tree cached push compiles nothing, the equal-tree uncached push compiles, a differing-tree push runs the full checks, a pull request runs no main-only step, `spin` stays the pull request workflow's job, and a fractional step is recorded.
- The Makefile's comment on the stages CI runs, area 1 of `docs/codebase-map.md`, the README pipeline section, and `docs/architecture.md` section 10 say where each step now runs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters CI and the delivery pipeline's records, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `.github/workflows/ci.yml`, `.github/workflows/main.yml` (new), `tools/ci_scope.sh`, `tools/run_state.sh`, `tools/tools_test.sh`, `Makefile` (a comment only).
- `docs/codebase-map.md`: area 1's outside-the-roots line names `main.yml`, and the `tools/ci_scope.sh` line its `compile` output.
- README.md: changed, the pipeline section says the release build and its smoke test run on the push to `main`.
- docs/architecture.md: changed, the continuous integration paragraph of section 10 describes the two workflows.
- CLAUDE.md: unchanged, its Checks line says the checker runs `FAST_STAGES` and CI the rest, which still holds across the two workflows; the split is carried by the map, the README, and the architecture, and it stays within its budget.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline fix (T1) of sprint 8, part b of `ci-time-tidy`.

Backlog headings this change covers, from its queue entry: "## CI time doubled after the Spinel pin bump".

## Out of scope

- The carry of a scoped dev-build at `tools/run_state.sh:503` and the other #142 advisories (`ci-scope-quoting`, `tools-docs-tidy`).
- Changing the branch protection setting, which lives outside the repository: it keeps requiring `spin`, which only the pull request workflow reports.
- Recording the steps of the `main` workflow with `ci-stages`, which keeps reading the `ci` workflow's `spin` job at the pull request head.
- Any queue reordering.

Assumptions recorded here instead of asked: "no compile when equal and cached" reads "cached" as the compile cache of `main` holding the exact entry of the sources' hash, so an equal-tree push of a code change still warms the cache, measures `main`, and builds and smoke tests the release binary once, while an equal-tree push whose sources `main` already compiled builds nothing; the run by hand (`workflow_dispatch`), which ran every step before, moves to the `main` workflow, where it still runs every step, so the pull request workflow answers pull requests alone; a step rounding to 0.0 seconds is still left out, and the rest carry one decimal only when they have a fraction, so whole-second figures read as before.
