# Tasks

## 1. The bump

- [x] 1.1 Set `SPINEL_REF` in the `Makefile` to c0502112d8cf8c6f57bc7e1ef5a2af1732407036 and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the 93d7883b toolchain; verify the diff is the generator's output only and `make -s spinel-rev` prints the new commit.
  - Result: `make -s spinel-rev` prints c0502112d8cf8c6f57bc7e1ef5a2af1732407036. The header loses 58 lines, the same 29 Enumerable names (`chain` to `uniq`) from the Array and the Hash arrays: upstream's `lib/spinel_rt.h` now lists them in its shared `enumm[]` array, whose names the generator leaves out of each class's own array, so `respond_to?` still answers them.
- [x] 1.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`; verify it installs `spinel`, `spin`, and `spinel-doctor` and `make doctor` reports `ruby: refused (stub)`.
  - Result: installed under `tmp/.toolchain/bin`; the header the build used is byte-identical to the vendored one; `make doctor` reports `ruby: refused (stub)`.

## 2. Carat at the new pin

- [x] 2.1 Run every stage of `make check` (`CHECK_STAGES`) on the new toolchain, fixing in carat's code only what fails at the new pin, each fix named here and any new pitfall recorded in `docs/spinel-notes.md`; verify `make check` passes, `make diagnose` is clean, and compare allocations per key and rounds with main's figures in `docs/metrics.tsv`.
  - Result: `make check` passes on the first run with no carat change, so no fix is named and `docs/spinel-notes.md` gains no pitfall. 107 of 107 tests pass; `make diagnose` reports clean for `bin/carat-gen-config.rb`, `bin/carat.rb`, and `test/runner/run_all.rb`, with no Spinel warning. Rounds 2 and 2, as on main. Allocations per key lh 26.0, j 27.0, insert 26.0, ddp 58.0, undo 52.0, dot-ciw 66.0, lh-ruby 26.0, open-ruby 24.0, against main's 26.0, 27.0, 32.0, 58.0, 52.0, 78.0, 26.0, 24.0: none higher; insert and dot-ciw fall by 6 and 12, from the new compiler, not traced to one upstream commit. Analysis 66.1 s (carat) and 138.6 s (runner) in the first run: the runner within the 112.5 to 138.7 s this machine measured at 93d7883b in earlier runs' stage logs, carat 1.3 s over their 51.9 to 64.8 s; the checker's run measured 62.1 s and 131.3 s, both within, so the difference is run-to-run noise.

## 3. Report

- [x] 3.1 Record the old and new commit, their distance, and any carat fix in the change's notes; verify with `make docs-lint`, `make gates`, and `make spec-validate`.
  - Result: 93d7883bd8d85ebbce768445c41c03d9a4bc9e92 to c0502112d8cf8c6f57bc7e1ef5a2af1732407036, 193 commits apart (`git rev-list --count`, the old pin an ancestor of the new); no carat fix. The open notes of `docs/spinel-notes.md` are not rechecked here (out of scope, as the proposal says).
