# Tasks

## 1. Generator and header

- [ ] 1.1 `tools/spinel/gen_respond_to_tables.rb`: add the nine Symbol false positives Spinel's generator lists at 93d7883b to `SYMBOL_FALSE_POSITIVE`. Proven by `make spinel-header` at the new commit passing the Symbol check.
- [ ] 1.2 `Makefile`: `SPINEL_REF` to 93d7883bd8d85ebbce768445c41c03d9a4bc9e92; `tools/spinel/spinel_rt_responds_generated.h` regenerated with `make spinel-header` by the installed 6af548c9 toolchain. Proven by `make spinel-rev` printing the new commit and the header's `git diff --stat`.

## 2. Toolchain and checks

- [ ] 2.1 `make toolchain` at the new commit, then `make doctor` and `make no-cruby`. Proven by both passing and `spinel` reporting the new build.
- [ ] 2.2 `make check` at the new commit: every stage green, every snapshot unchanged, allocations and rounds equal main's; the runner's rebuilds, `cg_methods` and analysis seconds, and the `test-build` and `diagnose` seconds measured, and any warning the new Spinel prints noted.

## 3. Document

- [ ] 3.1 `docs/spinel-notes.md`: the regression entry names the new pin and its figures. Verify with `make docs-lint`, `make gates`, and `make spec-validate`.
