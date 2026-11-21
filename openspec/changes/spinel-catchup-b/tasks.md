# Tasks

## 1. Baseline and bump

- [ ] 1.1 Measure main at 0d1a7ca3 in this worktree before the checkout moves: `make dev-build test-build bench-budget metrics` (rounds, analysis, allocations and time per key into `build/metrics/current.tsv`, kept as the base), `make build` (release binary size), and `make bench` (time per key).
- [ ] 1.2 Set `SPINEL_REF` in the `Makefile` to the new commit and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the 0d1a7ca3 toolchain; verify the diff is the generator's output only and `make -s spinel-rev` prints the new commit.
- [ ] 1.3 Build the new toolchain with `make toolchain`; verify it installs `spinel`, `spin`, and `spinel-doctor`, the header the build used is the vendored one, and `make doctor` reports `ruby: refused (stub)`.

## 2. Carat at the new pin

- [ ] 2.1 Run every stage of `make check` on the new toolchain, fixing in carat's code only what fails at the new pin and is small and local, each fix named here with the test that proves it; verify `make check` passes and `make diagnose` is clean.
- [ ] 2.2 Compare with the baseline: `make metrics-compare BASE_METRICS=` the 1.1 measurement (allocations per key and rounds), `make bench` (time per key), the analysis lines, and the release binary size.

## 3. Notes

- [ ] 3.1 Recheck the open notes of `docs/spinel-notes.md` (Known miscompilations and the other `Open:` notes) with reduced probes at the new pin and record each result there; each workaround the pin makes unnecessary whose removal is not trivial and tested goes to `docs/findings/spinel-catchup-b.md`; verify with `make docs-lint`, `make gates`, and `make spec-validate`.
