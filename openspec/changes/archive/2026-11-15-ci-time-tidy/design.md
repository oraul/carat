# Design

## Context

`tools/run_state.sh check` runs `make stages` (`FAST_STAGES`) in a throwaway clone and skips a stage only when it passed at the backed head, when only tests changed since (`tests_only_since`, the non-test stages carried), or when a compile stage's code key is unchanged (`compiled_same`). Nothing looks at which paths the branch changed. `tools/ci_scope.sh` writes one output, `run`, which gates every CI step but the push-only ones; its `documentation` function decides it. `tools/rules.sh` is already sourced by both scripts for `RECORDS_RE`. The stage gate (`tools/gates.sh` `gate_stages`) requires a `0` record at the checked commit for every stage of the list, and `bench_compare` requires the metrics stage passed at HEAD and reads `build/metrics/current.tsv`.

## Goals / Non-Goals

**Goals:**

- A docs-only change's local check runs only `docs-lint` and `gates`; a docs-only pull request runs only its docs lint in CI.
- `tools-test` runs, locally and in CI, only when a path it reads changed.
- One definition of the path classes for both.

**Non-Goals:**

- Splitting CI into two workflows, the equal-tree push, and the fractional CI steps (part b).
- Changing which stages exist or their order.

## Decisions

### The path classes live in `tools/rules.sh`

`documentation` moves from `tools/ci_scope.sh` into `tools/rules.sh` unchanged but for `LICENSE` (at the root or in a directory), which no test or build reads. `TOOLS_RE` sits beside it: `tools/`, `.claude/agents/`, `.claude/workflows/`, `.claude/commands/`, `.claude/settings.json`, `.github/`, `Makefile`, and the files the generator cases copy (`carat.rb`, `carat/adapters/editor_assembly.rb`, `docs/codebase-map.md`, `docs/actions.md`, `docs/compatibility.md`, `test/runner/run_all.rb`, `test/lint.rb`, `config/plugins.caratrc`, `config/default.caratrc`). A case lists every `$here/../PATH` and every kit path in `tools/tools_test.sh` and fails on one `TOOLS_RE` misses, so a new read cannot silently skip the stage. Alternative considered: a list per stage in the Makefile; rejected, since the classes are shell patterns both scripts already source from `rules.sh`.

### The local check scopes by the merge base, recording a skipped stage as `scoped`

`check_stages` takes the paths changed from `git merge-base BASE HEAD` to HEAD (`BASE` defaulting to `origin/main`, renames counting both paths). `docs-lint` and `gates` always run; `tools-test` runs when a path matches `TOOLS_RE`; any other stage runs when a path is not documentation. No paths (no merge base, or none changed) runs every stage, so the scope only ever removes work it can justify. A scoped stage is written `0 0s HEAD TIME scoped`, like the carried and compiled records, so the stage gate, which reads the status and the commit, passes unchanged. The scope check comes after the backed-head skip and the test-only carry and before the compile key.

### Bench carries main's figures when the measurement was scoped

With the metrics stage scoped, no measured path changed, so main's recorded figures are the change's. `bench_compare` builds the base file as before, copies it over `build/metrics/current.tsv`, imports it as the change's figures (which the next history row reads), prints that the figures were carried, and exits 0, so the workflow's `bench_same` holds and no benchmark agent starts.

### CI gets a `tools` output; the docs lint always runs

`answer` writes `tools=` beside `run=` and `reason=`. A run by hand and any path that `TOOLS_RE` matches give `tools=true`; the equal-tree push gives `tools=false`. The `Tools` step runs on `tools == 'true'`. `make docs-lint` needs no toolchain and fails in a second, so it runs on every pull request; it keeps running on pushes as before only when `run` is true. Compile, test, and bench keep their `run` condition, so docs-only stays without them.

## Risks / Trade-offs

- [A tool case starts reading a new repository path] → the `TOOLS_RE` coverage case fails until the pattern names it.
- [The merge base is stale, so more paths count as changed] → more stages run, never fewer: the scope fails safe.
- [A scoped metrics stage leaves an older `build/metrics/current.tsv`] → bench overwrites it with main's figures before importing.
