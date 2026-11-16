# Design

## Context

`.github/workflows/ci.yml` (workflow `ci`, job `spin`) runs on `pull_request`, `push` to `main`, and `workflow_dispatch`. `tools/ci_scope.sh` answers `run` and `tools`; the compile steps (dev-build, test-build, bench-budget, metrics, release build, smoke) run on `run == 'true' || github.event_name == 'push'`, so a pull request with code runs the release build and its smoke test, and every push to `main` runs all six even when its tree equals the passed head. On a pull request the smoke test already runs on the development editor (`make test-run CARAT_BIN=build/dev/carat`). Caches a pull request saves are scoped to it; only a run on `main` writes the entries every pull request restores. `ci_stages` in `tools/run_state.sh` reads the newest run named `ci` at the pushed head, its job `spin`, and computes `fromdateiso8601` differences, which hold whole seconds, then keeps a step only when its seconds are a run of digits of at least 1.

## Goals / Non-Goals

**Goals:**

- Two workflows with no shared trigger: pull requests run only the checks, a push to `main` only what `main` needs.
- An equal-tree push whose sources `main` already compiled compiles nothing; a differing-tree push with code runs the full checks.
- The required check `spin` unchanged for branch protection.
- `ci-stages` keeps a fractional step.

**Non-Goals:**

- Changing the checks themselves, their order, or the scope rules of part a.
- Recording the `main` workflow's steps.

## Decisions

### `ci.yml` keeps the name `ci` and the job `spin`; `main.yml` is a new workflow `main`

Branch protection reads the check run named after the job, `spin`, and `tools/ci_scope.sh` queries `check_name=spin` at pull request heads; `ci_stages` selects runs named `ci` at the pushed head. Keeping both names on the pull request workflow leaves all three as they are. The push workflow's job is `main`, so no check named `spin` is ever reported for a commit of `main`. Alternative considered: one workflow with event conditions on every step; rejected, since the user asked for two with no overlap and the conditions were where the release build leaked onto pull requests.

### The run by hand moves to `main.yml`

A run by hand ran every step, the release build included. In `main.yml` the scope answers `run=true` for it, so it still runs every step but the save of main's measurement, which stays on a push to `main`. The pull request workflow then answers pull requests alone.

### "Cached" is a lookup-only probe of the compile cache's exact key

`main.yml` resolves the Spinel commit, then probes `actions/cache/restore` with `lookup-only: true` and the exact key the compile cache uses (Spinel commit, level, OS, and the hash of every Ruby source the development builds read), and hands its `cache-hit` to the scope step as `CACHED`. `tools/ci_scope.sh` answers `compile=true` when `run=true`, or on a push when `CACHED` is not `true`; else `false`. Every step that compiles or runs a compiled program, the toolchain restore included, runs on `compile`; the checks that compile nothing (doctor, no-cruby, docs lint, config-current, test) run on `run`, tools-test on `tools`. Putting the decision in the script keeps it under the tools test, since a workflow condition cannot be run there. A hit means `main` already compiled, measured, and release-built exactly these sources, so the measurement a pull request restores by the newest prefix is of the same code. Alternative considered: compiling nothing on every equal-tree push; rejected, since a pull request's caches are invisible to `main`, so `main` would never warm the units, never save its measurement, and never build the release binary of a merged code change.

### The workflows' shape is checked by cases

`tools/tools_test.sh` reads both workflow files: `ci.yml` triggers on `pull_request` alone and declares the job `spin`; it runs no release build, no release smoke test, and no cache save; `main.yml` has no `pull_request` trigger, and every step of it that runs `make dev-build`, `test-build`, `bench-budget`, `metrics`, `build`, or the release smoke test is conditioned on `compile`. With the `ci_scope` cases for `compile`, this proves the acceptance without a GitHub run.

### `ci-stages` computes fractional seconds in gh's jq and rounds in awk

The jq takes the first 19 characters of each timestamp plus `Z` through `fromdateiso8601` and adds the fraction captured after them, when present; the start and end of one step share a zone, so their difference is exact. The awk accepts a decimal first field, rounds each step to a tenth, keeps it above zero, sums repeats, and prints a whole number without a decimal, so existing figures and history rows read as before.

## Risks / Trade-offs

- The release build no longer runs before the merge: a release-only failure turns `main` red after it. The smoke test still runs on the development editor on every pull request with code, and Spinel documents the same answers at every level.
- A Makefile change to build flags with the sources' hash unchanged hits the probe and skips the release build on an equal-tree push; the compile cache's key already ignores the Makefile, and a differing-tree push still runs everything.
- Cancelling an older `main` run (`cancel-in-progress`) can skip its cache save; the newer run probes and warms it.
