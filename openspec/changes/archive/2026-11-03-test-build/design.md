# Design

## Context

See proposal.md, Why. Spinel compiles a whole program at a time: it parses every file the root requires, infers types across all of them (the analysis), writes one C program, and compiles it. Every test program required the whole library, so each paid the analysis and the C compile of the library. `spin test` compiles the stale test programs in parallel (`xargs -P` over the cores, at `-O 1`) and then runs and compares each; `make snapshots` compiled them one after another at `-O 2`; `make diagnose` ran `spinel-doctor` on every root, which runs Spinel three times per root (`-c` for the unsupported and unresolved legs, `--emit-rbs` for the inference and advice legs, and a build).

Documented facts this design relies on, all at the pinned `SPINEL_REF`:

- `spin test` treats only `test/*.rb` as test programs (`Dir.glob("test/*.rb")` in `tools/spin.rb`), comparing a run's standard output and error, merged, with `test/<name>.rb.expected`.
- `if __FILE__ == $0` is folded at compile time: true in the entry script, false in a required file (`docs/spin.md`, "Compiled as a plain binary the guard is true"; `sp_program_guard` in `src/spinel_parse.c`).
- `-O LEVEL` sets the C optimization level (default 2); `spin build --debug` or `SPIN_DEBUG=1` is `-g -O0` with line maps.
- `--incremental` cuts the C into units of about 256 KB, reuses the object of every unit whose text did not change from `SPINEL_CACHE_DIR`, and compiles the misses `--jobs` at a time (default the cores, up to 16). `docs/limitations.md`: "a development-build mode ... The answers are the same; release builds (without `--incremental`) are unchanged." `docs/profiling.md`: the frontend runs in full every time.
- `spinel-doctor --skip a,b` skips legs; everything after `--` goes to every Spinel run it makes.

## Goals / Non-Goals

**Goals:**

- One analysis and one C compile of the library per `make test`, whatever the number of tests, with every test still checked against its own snapshot, by itself, as before.
- `make check` under two minutes locally with a warm cache, CI's job under two minutes with its caches hit, `make snapshots` under two minutes.
- No coverage lost: the same assertions, the same snapshots byte for byte, and every check `make check` and CI ran before still run (the analysis budget and spinel-doctor included).

**Non-Goals:**

- Faster analysis: no flag shortens it, and Spinel offers no parallel analysis.
- Parallel compiler processes of the project's own.
- Changing the release build, the benchmark's build, or any code under `carat/`.

## Measurements

On this four-core machine, with nothing else running. The machine ran Spinel about twice as fast during this change as during `analysis-speed` (the analysis of `bin/carat.rb` took 11.7 seconds under `spin build` here against 22 to 25 then), so the "before" numbers are taken again here where it matters.

The runner's build, `SP_TIMING=1`, wall seconds, analysis and C compile in milliseconds:

| Build | Wall | Analysis | C compile | Units, misses |
| --- | --- | --- | --- | --- |
| `-O 0` | 37.9 | 25,250 | 9,384 | |
| `-O 1` | 58.3 | 24,723 | 30,469 | |
| `-O 2` | 77.5 | 27,810 | 46,300 | |
| `-O 0 --incremental`, cold | 37.9 | 25,709 | 8,907 | 134, 134 |
| `-O 0 --incremental`, warm, nothing changed | 30.2 | 24,926 | 1,763 | 134, 0 |
| `-O 0 --incremental`, warm, a test edited | 31.9 | 26,727 | 1,868 | 134, 0 |
| `-O 1 --incremental`, cold | 58.4 | 25,071 | 30,063 | 134, 134 |
| `-O 1 --incremental`, warm | 30.4 | 25,526 | 1,722 | 134, 0 |

The runner's analysis takes 4 fixpoint and 2 re-narrowing rounds, like every program before; it holds the library, the doubles, and 8,600 lines of tests, and costs about 26 seconds against 11.7 for `bin/carat.rb`. Codegen adds about 2.5 seconds. The cache holds 24 MB at `-O 0`. Running all 50 tests from the runner takes about 15 seconds, 10.7 of them the smoke test's waits.

`make check` on this change: cold (no `build/bin`, `build/test`, or compile cache) 121 seconds, warm 90 and 87 seconds; in the warm run `make build` and `make gen-config` take no time, `make test-build` 30 seconds, `make test-run` 15, `make diagnose` with the legs that can fail it 40, and `make no-cruby` 1. `make diagnose` with every leg but behavior takes 136 seconds; `make snapshots` warm 45; `make test-one T=test/domain_buffer.rb` 15; `make diagnose-one T=test/domain_buffer.rb` 41; `make analysis-budget` 41 (two roots, one after another); `make bench-budget` 26. Every snapshot is byte for byte the same.

Before, on 04f742d: the stage logs of `analysis-speed` on the same tree give `make build` 55 seconds, `make analysis-budget` 27, `make test` 1,021, `make diagnose` 2,397, about an hour for `make check`; CI's job on #24 took 17 minutes 32 seconds, its Test step 16 minutes. Measured again on this machine on 04f742d: `make test` 532 seconds (50 programs at `-O 1`, compiled by `spin test` four at a time); spinel-doctor 50 seconds on `bin/carat.rb` and 57 and 61 seconds on two test programs, so about 50 minutes for the 52 roots; one test program compiled at `-O 2`, as `make snapshots` did 50 times one after another, in 31 to 34 seconds, about 27 minutes for all.

## Decisions

### One runner, one process per test

Each test file becomes a module named after it, `<Camel>Test`, whose `main` holds the file's statements; its constants, classes, and helper methods (as `def self.name`) are in the module body, so nothing collides between files (twenty files defined `D`, several the same helper names and test classes). The file ends with `<Camel>Test.main if __FILE__ == $0`, so compiled alone it runs, and required by the runner it does not. The transformation was done by a script, the same for every file: the header (comments and requires) stays, column-0 `def`, `class`, `module`, and constant assignments with the comments right above them go into the module in their order, and everything else goes into `main` in its order. Constants are evaluated when the module body runs rather than at their old place among the statements; none depends on a statement, and every snapshot is unchanged.

`test/runner/run_all.rb` requires every test and runs the one named by its first argument; `tools/run_tests.sh` runs the binary once per test and compares, as `spin test` does, the merged output with the snapshot, adding the exit status check `docs/spin.md` describes. One process per test keeps each test's exit status, output, and fresh process state (the doubles, the smoke test's files) exactly as before; running all of them in one process would need `Testing#finish` not to exit and the standard output to be captured per test, which changes the harness and would let one test's state leak into the next. Fifty processes cost about five seconds. A name missing from the runner exits 2 and fails by name, which is the guard against a new test file left out; a `require_relative` of a missing file is a compile error.

The runner is one directory below `test/` so `spin test` never takes it for a test program; the smoke test is part of it and runs after `make build`, as before. Alternatives: a runner under `tools/` or `bin/` (rejected: `bin/` is installed and built by `spin build`, `tools/` holds scripts, not Spinel programs); several runners per layer, as the backlog suggested (rejected: each pays the library's analysis again, about 26 seconds, for nothing, since one program analyses in about the time of one test).

### The helpers that returned arrays return objects

Moving statements into a method changed one thing: an array a helper returned and the caller destructured (`state, host, keymap, files, ex = setup(...)`) lost its element types inside the method on the pinned Spinel. In `test/use_cases_plugins.rb` the C did not compile; in `test/use_cases_plugin_files.rb` and `test/domain_grammar.rb` spinel-doctor reported unresolved calls on poly receivers. The three helpers return a small class with typed readers, and the callers read its members; a minimal three-value example kept its types, so the trigger is recorded in the backlog rather than reported upstream yet. In the runner alone, the line `test/lint.rb` passes to its `lines_mutation?` helper is untyped (another test's use of `each_line.with_index` widens what the block receives), so it is converted with `to_s`, the convention `analysis-speed` set for values crossing into typed code.

### Development builds: `-O 0` and `--incremental`

`-O 0` is the documented optimization flag (the C compile of the runner is 9 seconds against 30 at `-O 1`, the level `spin test` used, and 46 at `-O 2`), and tests check answers, which Spinel documents as the same. `spin build --debug` would add `-g` and line maps, a larger and slower compile for a debugger nobody attaches in a test run, so the plain `-O 0` is used; `TEST_OPT` changes it. `--incremental` adds nothing on a cold build and saves the C compile on a warm one (about 8 seconds), and its units are compiled `--jobs` at a time by Spinel itself, which is the only parallelism used. The cache lives in `build/spinel-cache` (`make clean` removes it). The release binary is never built this way: `make build` keeps `spin build` at `-O 2`, and `make bench` and `make bench-budget` keep their `-O 2` build, since the benchmark measures the release code. spinel-doctor's build leg gets `-O 0` through its `--` flags, since its binary is thrown away.

### The analysis budget comes from the runner's own compile

`make test-build` compiles the runner with `SP_TIMING=1`, keeps the report in `build/test/run_all.timing`, shows the compiler's other output, and checks the report with `tools/analysis_budget.sh --check`. The runner holds the library and every test's calls into it, which is where the budget's regression showed (`test/domain_buffer.rb`), so the check is wider than before and costs nothing. `make analysis-budget` stays for both roots on demand, compiled one after another instead of in background processes, and leaves `make check` and CI; `bin/carat.rb` needed 2 rounds before and after the regression the budget was made for.

### `make diagnose` on the real roots; `make check` runs the legs that can fail

Every test is part of the runner, so `make diagnose` runs on `bin/*.rb` and the runner: three roots instead of 52, 136 seconds instead of 2,397. In `make check`, spinel-doctor skips the build leg, because `make build` and `make test-build` have just compiled the same programs, and the inference and advice legs, which report at info severity, never change its exit status, and cost a second analysis of each root (`--emit-rbs`); the legs that can fail it, unsupported, unresolved, and requires, still run from its `-c` run. That takes `make diagnose` inside `make check` from 79 to 40 seconds and `make check` warm from 125 to 88. `make diagnose` and `make diagnose-one` keep every leg but behavior, and `make types` prints the inferred signatures. `DIAGNOSE_SKIP` holds the list, a target-specific value on `check`.

### The generator writes only what changed

`bin/carat-gen-config.rb` wrote both generated files on every run, so every `make check` left them newer than the editor binary and the next `make build` recompiled it (28 seconds). It now compares the text first and writes only a change; CI's check that the generated config is current is unchanged.

### CI

- A concurrency group per ref cancels a superseded run of the same pull request or of `main`.
- `tools/ci_scope.sh` decides whether the checks run, and the job always runs, so a required check named `spin` passes when they are skipped. A path filter at the workflow level (`paths-ignore`) was rejected: a workflow that does not run leaves a required check pending forever. Documentation is a Markdown file other than `docs/actions.md` and `docs/compatibility.md`, which the action and ex tests read, or a file under `openspec/` or `.claude/`; the files compared are those of the checked out commit against its first parent (the base, for a pull request's merge commit).
- A push to `main` skips the checks when the API names a pull request for the commit whose head has the same tree and whose `spin` check run succeeded: the tests already ran on exactly these files. Running CI on pull requests only was rejected because caches saved by pull requests are visible to that pull request alone, so `main` would never hold a toolchain or compile cache for the next pull request. Anything the script cannot establish runs the checks.
- The compile cache is `build/spinel-cache` under the key `spinel-units-OS-SPINELREV-OTEST_OPT-HASH`, where `HASH` is the hash of the Ruby sources, with the fallback `spinel-units-OS-SPINELREV-OTEST_OPT-`, so a run restores the newest entry of the same compiler, level, and OS and saves its own. A push to `main` compiles the runner even when it skips the checks, so `main` keeps a warm entry for pull requests to restore. `TEST_OPT` is set once in the job's environment, which the `Makefile` reads.
- The test step is split into Compile the tests (`make test-build`) and Test (`make test-run`), so the log shows each.

## Risks / Trade-offs

- [A new test file is not added to the runner] → `make test-run` fails it by name ("unknown test"), and `CLAUDE.md` says to add the two lines.
- [A test's top-level code depended on running at load time] → None did; the runner runs only `main`, and a constant with side effects would run at program start for every test, which the convention avoids.
- [One program means one test's untyped value widens the library for all tests] → The budget is checked on exactly that program on every `make test`, so the cost shows at once; the convention of typed values stays.
- [The incremental cache grows with stale units] → It is under `build/`, removed by `make clean`; CI starts from the newest entry and saves per change, and GitHub evicts old entries.
- [`make check` no longer prints the inference and advice legs] → `make diagnose` and `make types` print them; they never failed `make check`.
- [The scope script skips a run that was needed] → It skips only on a tree identical to a passed head or on Markdown no test reads; an API failure runs the checks. A new test reading another document must add it to the exceptions.
- [Cold `make check` is just over two minutes (121 seconds)] → The target is warm; a cold run pays the release build (28 seconds) and the runner's C compile (9) once.

## Migration Plan

None for users. Developers run `make test-one T=test/NAME.rb` instead of `spin test test/NAME.rb`. Rolling back is reverting the squash commit; the snapshots are unchanged either way.
