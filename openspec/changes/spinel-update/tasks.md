# Tasks

## 1. The bump

- [ ] 1.1 Set `SPINEL_REF` in the `Makefile` to c0502112d8cf8c6f57bc7e1ef5a2af1732407036 and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the 93d7883b toolchain; verify the diff is the generator's output only and `make -s spinel-rev` prints the new commit.
- [ ] 1.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`; verify it installs `spinel`, `spin`, and `spinel-doctor` and `make doctor` reports `ruby: refused (stub)`.

## 2. Carat at the new pin

- [ ] 2.1 Run every stage of `make check` (`CHECK_STAGES`) on the new toolchain, fixing in carat's code only what fails at the new pin, each fix named here and any new pitfall recorded in `docs/spinel-notes.md`; verify `make check` passes, `make diagnose` is clean, and compare allocations per key and rounds with main's figures in `docs/metrics.tsv`.

## 3. Report

- [ ] 3.1 Record the old and new commit, their distance, and any carat fix in the change's notes; verify with `make docs-lint`, `make gates`, and `make spec-validate`.
