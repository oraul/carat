# Tasks

## 1. The pin

- [x] 1.1 Set `SPINEL_REF` in the `Makefile` to 6af548c9be5683902cb1abc8c2cb6f307b7e7a74 and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the 6b43fe94 toolchain. Verify that the diff is only the generator's output and that `make -s spinel-rev` prints the new commit.
  - Result: `make spinel-header` with the 6b43fe94 toolchain writes a header identical to the committed one, so `tools/spinel/spinel_rt_responds_generated.h` is unchanged; `make -s spinel-rev` prints 6af548c9be5683902cb1abc8c2cb6f307b7e7a74. The comments of `Utf8.boundary` and `PluginApi::Paths.segments` now name 84aa303b1, the commit that brings the rule, after the pin.
- [x] 1.2 Build the new toolchain with `make toolchain`. Verify that `make doctor` reports the stub refusing `ruby`.

## 2. Carat at the new pin

- [x] 2.1 Run every stage of `make check` (`CHECK_STAGES`) on the new toolchain, fixing only what fails at the new pin, each fix named. Verify that `make check` passes, that test-build and diagnose take about 125 to 175 s, and compare allocations per key and rounds with main's figures in `docs/metrics.tsv`.
  - Result: every stage of `CHECK_STAGES` passes at 6af548c9 with a cold compile cache and no carat change: 104 of 104 tests, 1141 of 1141 tool tests. Seconds per stage on four cores: build 102, dev-build 61, test-build 157 (6b43fe94: 583 to 736; before #120: 125 to 158), test-run 44, diagnose 171 (6b43fe94: 602 to 659; before #120: 148 to 175), bench-budget 61, metrics 18, tools-test 79. Rounds 2 and 2, analysis 47.2 s (carat) and 106.7 s (runner). Allocations per key equal main's recorded figures: lh 26.0, j 27.0, insert 32.0, ddp 58.0, undo 52.0, dot-ciw 78.0, lh-ruby 26.0, open-ruby 24.0. CI's compile_the_tests is measured by the first CI run.
- [x] 2.2 Record 2440954d1 as the compile-time regression in `docs/spinel-notes.md` (Analysis, tests, and the runner), and move the `byteindex` note in Language and library to 84aa303b1. Verify with `make docs-lint` and `make gates`.
