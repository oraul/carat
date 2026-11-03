# Design

## Context

See proposal.md, Why, and the design of `test-build` for the setup this change starts from: the test runner is one program compiled with `-O 0 --incremental`, its units of C cached under `build/spinel-cache` and in CI under the key `spinel-units-OS-SPINELREV-OTEST_OPT-HASH` with the fallback `spinel-units-OS-SPINELREV-OTEST_OPT-`; the release binary is `spin build` at `-O 2`; the benchmark is compiled at `-O 2` for the allocation budget.

Documented facts this design relies on, at the pinned `SPINEL_REF`:

- `docs/profiling.md`, Incremental builds: a body edit that keeps its types misses the one unit that holds its class, a changed type misses the callers' units too, and an added instance variable or class misses every unit of the program but none of the runtime's, which are shared by every program built with the same flags. `--cache-stats` and the `cc_compile` line of `SP_TIMING=1` give the units and misses.
- `docs/limitations.md`: an `--incremental` build is a development build whose answers are the same as a release build's; `-O LEVEL` is the C optimization level.
- `spinel --help`: a plain build already splits a unit of 4 MB or more into `--jobs` parts (the editor's release build is compiled in 4 parts); `--unit-bytes` sets the unit size of an incremental build, and another size shares no cached object; `--no-inline-hot` stops forcing small leaf methods inline.
- `tools/spin.rb`, `cmd_build`: `spin build` takes a binary in `build/bin` as up to date when it is newer than every input, whatever compiled it; `spin run NAME` builds only that target.

## Measurements

CI, the `spin` job (step wall times from the run, analysis from the runner's phase report):

| Run | Compile cache | Build | Compile the tests (analysis) | Test | Allocation budget | Job |
| --- | --- | --- | --- | --- | --- | --- |
| #25 pull request | miss (no entry) | 33 s | 45 s (25.3 s) | 17 s | 31 s | 2:16 |
| #25 push to main | miss | skipped | 50 s (29.4 s) | skipped | skipped | 0:59 |
| #26 pull request | fallback hit on #25's entry, 141 of 145 units missed | 40 s | 55 s (33.5 s) | 19 s | 38 s | 2:40 |
| #26 push to main | fallback hit on #25's entry | skipped | 41 s (25.9 s) | skipped | skipped | 0:49 |

The miss count of #26 is reproduced locally: the runner compiled at 52dc571 (#25) into an empty cache, then at 0b563a3 (#26) with `--cache-stats`, gives `units=145 hit=4 miss=141 rt=4/4 program=0/18 tagged=0/123`: every program unit missed, the runtime units hit. #26 added classes and instance variables, which miss every unit by Spinel's design, so its compile step paid the cold C compile; the analysis of 33.5 s against 25 to 29 on the other runs is the runner machine's variance. The cache key does not defeat reuse: a pull request restores `main`'s newest entry of the same compiler, level, and OS through the fallback key. Two gaps remain: the logs did not show the cache result, and the key did not hash `bench/`.

On this four-core machine, wall seconds, analysis and C compile in milliseconds:

| Build | Wall | Analysis | C compile | Units, misses |
| --- | --- | --- | --- | --- |
| `bin/carat.rb` at `-O 2` (release, 4 parts) | 31.0 | 14,038 | 14,997 | |
| `bin/carat-gen-config.rb` at `-O 2` | 3.2 | 38 | 3,106 | |
| `bin/carat.rb` `-O 0 --incremental`, cold | 18.1 | 13,648 | 2,514 | 32, 32 |
| `bin/carat.rb` `-O 0 --incremental`, warm | 16.5 | 14,451 | 0 | 32, 0 |
| `bench/keys.rb` at `-O 2` | 29.6 | 14,667 | 12,940 | |
| `bench/keys.rb` `-O 0 --incremental`, runtime units warm | 20.0 | 15,707 | 2,124 | 34, 30 |
| `bench/keys.rb` `-O 0 --incremental`, warm | 17.4 | 15,270 | 0 | 34, 0 |
| runner `-O 0 --incremental`, cold, default 256K units | 47.7 | 32,966 | 8,136 | 145, 145 |
| the same with `--no-inline-hot` | 46.5 | 32,294 | 7,908 | 145, 145 |
| the same with `--unit-bytes=128K` | 49.0 | 32,741 | 9,849 | 230, 230 |
| the same with `--unit-bytes=512K` | 46.0 | 32,822 | 7,061 | 84, 84 |
| the same with `--unit-bytes=1M` | 43.6 | 31,670 | 5,946 | 46, 46 |
| runner after this change's edit of `test/smoke_editor.rb` | 38 | 31,410 | 882 | 145, 14 |

Allocations per key, `bench/run.sh` over all 30 scenarios, the benchmark built at `-O 2` and at `-O 0 --incremental`: identical in objects and in bytes for every scenario (for example `lh` 27.0 objects and 1,616 bytes, `ddp` 59.7 and 3,574, `G-ruby` 141.4 and 7,356). Spinel decides what a program allocates when it generates the C; the C optimization level does not change it. The budget step runs only `lh`, twice, so the slower `-O 0` code costs under a second there.

The smoke test passes on the development build of the editor (12 seconds, its snapshot unchanged).

## Decisions

### The compile cache: keep the key, cover every development build, show the result

The key stays: the Spinel commit, the level, and the OS each change the objects, and the source hash makes each change save its own entry while the fallback restores the newest one. What made #26 slow was its own change, not the key. The hash now covers `bench/**/*.rb`, since the benchmark is a development build too, and a push to `main` compiles all three development builds, so `main`'s entry holds every unit a pull request compiles. `make test-build`, `make dev-build`, and `make bench-budget` print one line from their phase report, `analysis ms=..., C compile ms=... units=N miss=M jobs=4`, so every log states the cache result. Alternatives: a key per run that always saves (rejected: a pull request whose sources match `main`'s entry compiles nothing new, and every save costs upload time and storage); `--cache-stats` (rejected: one line per miss, 141 lines on #26).

### The allocation budget at `-O 0`

The counts are identical at both levels for every scenario, so `make bench-budget` builds `build/bench/keys-budget` with the development flags and the compile cache: its C compile goes from 13 seconds to 2 cold and none warm, while its analysis, about 15 seconds, stays. `make bench` and `make profile` measure time and keep `-O 2` in their own binaries.

### The smoke test on a development build on pull requests, the release build on `main`

The release build was compiled on every pull request only for the smoke test. A pull request now compiles `bin/carat.rb`, the real editor root analysed as its own program, with the development flags into `build/dev/carat` (`make dev-build`), and the smoke test runs it through `CARAT_BIN`. So a pull request still analyses and compiles the editor's own program, catches every refusal or unresolved call in it, and runs the binary in a pseudo-terminal; what it no longer does is compile that program's C at `-O 2`. Every push to `main` and every run by hand builds the release binary with `make build` and runs the smoke test on it, so a failure that only the `-O 2` build shows still surfaces on the commit that brought it, one run later. `make test` and `make check` locally keep building and smoke testing the release binary.

The development binary lives in `build/dev/`, not `build/bin/`, because `spin build` takes any newer binary in `build/bin` as an up to date release build. With the release build gone from pull requests, `make gen-config` compiles only the small generator, `spin run carat-gen-config`, about 3 seconds.

Alternatives: the release build on pull requests with `--jobs` (it already compiles in 4 parts); running the editor from the test runner (rejected: the editor would be analysed inside the runner's program, with the tests' types, so the real root would no longer be compiled anywhere on a pull request); running the release build in a second job (rejected: parallel jobs are the kind of parallelism the user ruled out).

### Left at their defaults

`--no-inline-hot` saves about 0.2 seconds of a cold C compile at `-O 0`. `--unit-bytes=1M` saves about 2 seconds of a cold compile and 512K about 1, while each miss after a body edit would recompile a unit four or two times larger, and a new size starts the cache cold. Neither pays for itself.

## Risks / Trade-offs

- [A failure only an `-O 2` build shows passes a pull request] → `main` builds and smoke tests the release binary on every push; Spinel documents the same answers at every level, and the pull request still compiles and runs the editor's own program.
- [The allocation counts differ at `-O 0` one day] → They come from the generated C, which is the same at every level; `make bench` at `-O 2` prints the counts beside the times, so a difference would show there.
- [The cache entry grows] → Spinel removes objects no build has used for 14 days, once a day; the three programs share their runtime units.
- [A pull request that adds a class misses every program unit] → That is Spinel's documented behavior; the cost is the cold C compile of the three programs at `-O 0`, which the measurements above bound.

## Migration Plan

None for users or developers: `make test` and `make check` are unchanged. `make bench-budget` writes `build/bench/keys-budget` instead of `build/bench/keys`. Rolling back is reverting the squash commit.
