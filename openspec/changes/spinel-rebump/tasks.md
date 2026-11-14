# Tasks

## 1. The bump

- [ ] 1.1 Set `SPINEL_REF` in the `Makefile` to 6b43fe94de957419fd6a670fae365987b40d4f1a and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the f34005bf toolchain; verify the diff is the generator's output only and `make -s spinel-rev` prints the new commit.
- [ ] 1.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`; verify it installs `spinel`, `spin`, and `spinel-doctor` and `make doctor` reports `ruby: refused (stub)`.

## 2. Carat at the new pin

- [ ] 2.1 Run every stage of `make check` (`CHECK_STAGES`) on the new toolchain, fixing only what fails at the new pin, each fix commented and recorded in `docs/spinel-notes.md`; verify `make check` passes and compare allocations per key, rounds, and analysis time with main's figures in `docs/metrics.tsv`.

## 3. Report

- [ ] 3.1 Name any carat Spinel workaround the new pin makes removable (left for `spinel-workarounds`) in the change's notes; verify with `make docs-lint`, `make gates`, and `make spec-validate`.
