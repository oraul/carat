# Tasks

## 1. Generator and header

- [x] 1.1 `tools/spinel/gen_respond_to_tables.rb`: add the nine Symbol false positives Spinel's generator lists at 93d7883b to `SYMBOL_FALSE_POSITIVE`. Proven by `make spinel-header` at the new commit passing the Symbol check.
- [x] 1.2 `Makefile`: `SPINEL_REF` to 93d7883bd8d85ebbce768445c41c03d9a4bc9e92; `tools/spinel/spinel_rt_responds_generated.h` regenerated with `make spinel-header` by the installed 6af548c9 toolchain. Proven by `make spinel-rev` printing the new commit and the header's `git diff --stat`.

## 2. Toolchain and checks

- [x] 2.1 `make toolchain` at the new commit, then `make doctor` and `make no-cruby`. Proven by both passing and `spinel` reporting the new build.
  - Result: `make toolchain` 10 min 42 s; `spinel` reports 93d7883b; `make doctor` and `make no-cruby` pass.
- [x] 2.2 `make check` at the new commit: every stage green, every snapshot unchanged, allocations and rounds equal main's; the runner's rebuilds, `cg_methods` and analysis seconds, and the `test-build` and `diagnose` seconds measured, and any warning the new Spinel prints noted.
  - Result: `make check` passes every stage in 14 min 23 s. The runner: 125 builds, `an_elab_points` 10.9 s, `cg_methods` 19.3 s, analysis 138.6 s (fixpoint 4 rounds, re-narrowing 2); `make check-stage S=test-build` 169 s, `S=diagnose` 219 s. Rounds carat=2, runner=2, allocations lh=26, j=27, insert=32, ddp=58, undo=52, dot-ciw=78, lh-ruby=26, open-ruby=24, equal to main's row. Warnings: the inline RBS warnings on `carat/use_cases/windows/tab_request.rb:9-10`, printed at 6af548c9 too, and two new ones on `carat/domain/utf8.rb:53` and `:63` (`its declaration became a NilNode before types were read`) while building `carat-gen-config`; none made fatal.

## 3. Document

- [x] 3.1 `docs/spinel-notes.md`: the regression entry names the new pin and its figures. Verify with `make docs-lint`, `make gates`, and `make spec-validate`.
