# Proposal

## Why

The user asked for compiling and testing to take two minutes at most, CI included, with parallelism only where Spinel or spin document it. After `test-build`, CI's job on a pull request still took 2 minutes 16 seconds on #25 and 2 minutes 40 seconds on #26: Build 33 to 40 seconds, Compile the tests 45 to 55, Test 17 to 19, and Allocation budget 31 to 38. Two of those steps compile a whole program at `-O 2` only to run a smoke test and to count allocations, and #26's compile step was slower than #25's although it restored `main`'s compile cache.

## What Changes

- Explain #26's compile step: it restored `main`'s entry of the compile cache through the fallback key, and 141 of the runner's 145 units of C missed anyway, because #26 added classes and instance variables, which Spinel documents as missing every unit of the program; only the 4 runtime units hit. The key does not defeat reuse: a pull request restores `main`'s newest entry of the same Spinel commit, level, and OS. Every development build now prints its analysis time and its units of C compiled and missed, so the log shows the cache result.
- A new `make dev-build` compiles the editor `bin/carat.rb` with the development flags (`-O TEST_OPT --incremental`) into `build/dev/carat`; the smoke test runs the binary `CARAT_BIN` names (default `build/bin/carat`), and CI's pull requests run it on the development build instead of building the release binary. Its C compiles in 2 seconds cold against 15 for the release build.
- `make bench-budget` compiles the benchmark with the development flags into `build/bench/keys-budget`, through the compile cache: all 30 scenarios allocate the same objects and the same bytes per key at `-O 0` as at `-O 2`. `make bench` and `make profile` measure time and keep `-O 2`.
- `make test-run` takes `TESTS`, the tests to run (default all).
- CI: the compile cache holds the units of the three development builds and its key hashes `bench/` too; a push to `main` always compiles all three, so the next pull request finds every unit warm, and builds the release binary with `make build` and runs the smoke test on it, so every commit of `main` still has its release build compiled and run.
- Documentation: `CLAUDE.md` (status, Commands, Layout), `docs/architecture.md` section 10, and the README's command table.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a build and CI change with no change to the editor's behavior; `skip_specs` is set.

## Impact

- `Makefile` (`dev-build`, `bench-budget`, `test-run`, `test-build`'s summary line), `.github/workflows/ci.yml`, `test/smoke_editor.rb` (its binary from `CARAT_BIN`; the snapshot is unchanged).
- `CLAUDE.md`, `docs/architecture.md`, `README.md`.
- No file under `carat/`, `bin/`, or `bench/` changes. `make check` and `make test` still build and smoke test the release binary.

This change is outside the roadmap of `docs/architecture.md` section 12: it is the third change of the compile and test time effort the user asked for before more features.

Out of scope: changing Spinel or spin; parallel compiler processes or test runs of the project's own; the release build's flags; the smoke test's waits; the analysis itself, which no flag shortens; `--unit-bytes` and `--no-inline-hot`, which were measured and left at their defaults (see design.md).

Assumptions recorded instead of asked: running the release build and a smoke test on it on every push to `main`, rather than on every pull request, keeps the coverage the user asked for, since a pull request still compiles and runs the real editor root (`bin/carat.rb`, analysed as its own program) and Spinel documents the same answers at every level; a failure only an `-O 2` build shows would surface on `main`'s run instead of the pull request's. A pull request that changes library code is measured by this pull request's own run, which changes a test file (the runner partly hits `main`'s cache) and compiles the editor's and the benchmark's program units cold, and by the full miss measured from #26's run.
