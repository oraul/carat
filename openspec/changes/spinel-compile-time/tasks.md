# Tasks

## 1. The pin

- [ ] 1.1 Set `SPINEL_REF` in the `Makefile` to 6af548c9be5683902cb1abc8c2cb6f307b7e7a74 and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the 6b43fe94 toolchain. Verify that the diff is only the generator's output and that `make -s spinel-rev` prints the new commit.
- [ ] 1.2 Build the new toolchain with `make toolchain`. Verify that `make doctor` reports the stub refusing `ruby`.

## 2. Carat at the new pin

- [ ] 2.1 Run every stage of `make check` (`CHECK_STAGES`) on the new toolchain, fixing only what fails at the new pin, each fix named. Verify that `make check` passes, that test-build and diagnose take about 125 to 175 s, and compare allocations per key and rounds with main's figures in `docs/metrics.tsv`.
- [ ] 2.2 Record 2440954d1 as the compile-time regression in `docs/spinel-notes.md` (Analysis, tests, and the runner), and move the `byteindex` note in Language and library to 84aa303b1. Verify with `make docs-lint` and `make gates`.
