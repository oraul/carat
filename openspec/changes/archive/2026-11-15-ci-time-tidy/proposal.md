# Proposal

## Why

The checker and CI run stages that check none of the paths a change touched. Locally the checker ran 664 s of stages on docs-only #137 (diagnose 207 s, test-build 162 s) and 91 of 663 s on `tools-test` for #138, which touched no file `tools-test` reads: `tools/run_state.sh check` has no path-based choice of stages, so every change runs every `FAST_STAGES` stage but those its carry and compile key skip. In CI, `tools/ci_scope.sh` skips the checks only when every changed path is documentation no test reads, so #137's root `LICENSE`, which nothing reads, ran the whole job, and `make tools-test` runs on every change with code, whether or not it touches a tool. The Makefile comment on the analysis budget still cites the figures from before the Spinel pin bump (2 rounds and 22 to 26 seconds; it was line 79 at #135), which the current pin no longer holds.

## What Changes

- `tools/rules.sh` holds the path classes both CI and the checker use: `documentation`, moved from `tools/ci_scope.sh` and now also counting a `LICENSE` file, and `TOOLS_RE`, the paths `make tools-test` reads (the tools, the agents, workflows, commands, and settings, `.github/`, the Makefile, and the files the generator cases copy).
- `tools/run_state.sh check` scopes the stages to the paths changed since the merge base with main (`BASE`): `docs-lint` and `gates` always run; `tools-test` runs only when a changed path matches `TOOLS_RE`; every other stage runs only when a changed path is not documentation. A stage left out is recorded as passed at HEAD with the note `scoped`, so the stage gate still sees every stage. A docs-only change therefore runs only `docs-lint` and `gates`.
- `tools/run_state.sh bench`, when the metrics stage was scoped out, carries main's recorded figures as the change's own and reports them the same, since no measured path changed.
- `tools/ci_scope.sh` writes a second output, `tools=true` or `tools=false`, by `TOOLS_RE` over the same changed paths; CI's `Tools` step runs on it instead of on `run`, and the `Docs lint` step runs on every pull request, so a docs-only pull request runs its paths' one check while compile, test, and bench stay skipped.
- The Makefile's analysis budget comment drops the stale figures and says where the current ones print.
- Cases in `tools/tools_test.sh` prove each of the above, and one checks that every repository path `tools/tools_test.sh` reads matches `TOOLS_RE`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change alters the delivery pipeline and CI, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/rules.sh`, `tools/ci_scope.sh`, `tools/run_state.sh`, `.github/workflows/ci.yml`, `Makefile` (a comment only), `tools/tools_test.sh`.
- `docs/codebase-map.md`: area 1's lines for `tools/ci_scope.sh`, `tools/run_state.sh`, and `tools/rules.sh`.
- README.md: changed, the pipeline section says the checker and CI run only the stages of the changed paths.
- docs/architecture.md: changed, the continuous integration paragraph of section 10 says a docs-only pull request runs only the docs lint and `tools-test` runs only on the paths it reads.
- CLAUDE.md: unchanged, its Checks line names the stage lists and the scripts, not how a check scopes them, which the map and the README carry; it stays within its budget.

Outside the roadmap of `docs/architecture.md` section 12: a pipeline fix (T1) of sprint 8, part a of `ci-time-tidy` as the planner split it.

Backlog headings this change covers, from its queue entry: none ("## CI time doubled after the Spinel pin bump" belongs to part b, `ci-time-tidy-b`, and stays until it merges).

## Out of scope

- Part b, `ci-time-tidy-b`, left in the queue: the two CI workflows (pull requests only, push to `main` only, the required check `spin` kept), an equal-tree push to `main` compiling nothing, and `ci-stages` keeping a fractional step.
- Treating `docs/codebase-map.md`, `docs/actions.md`, or `docs/compatibility.md` as documentation: the lint, action, and ex tests compile and read them, so a change to one keeps running the tests; skipping them would weaken those checks.
- Any other queue reordering.

Assumptions recorded here instead of asked: "`Makefile:79` stale" names the line that held the analysis figures at the Spinel pin bump (#135), now the analysis budget comment, since the current line 79 states nothing the code contradicts; the paths `tools-test` reads are taken from what `tools/tools_test.sh` opens in this repository, and a new case's read is held to `TOOLS_RE` by a case; the merge base with main decides the changed paths, so the check of a branch whose merge base cannot be found runs every stage.
