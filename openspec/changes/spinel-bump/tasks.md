# Tasks

## 1. CRuby-free header regeneration

- [ ] 1.1 Add `tools/spinel/gen_respond_to_tables.rb`, the reading part of Spinel's generator as a Spinel program; verify it compiles with the installed `spinel` and writes the committed header byte for byte from the 001419ff checkout.
- [ ] 1.2 Add `make spinel-header` to the `Makefile` (help, `.PHONY`) and share the checkout steps with `make toolchain` through one canned recipe; verify with `make -n toolchain` and `make spinel-header`.

## 2. The bump

- [ ] 2.1 Set `SPINEL_REF` to f34005bf and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header`; verify the diff is the generator's output only.
- [ ] 2.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`, and confirm no `ruby` was reached.
- [ ] 2.3 Run `make check` on the new toolchain and compare allocations per key, rounds, and analysis time with main's figures (lh 27.0, j 28.0, insert 35.0; rounds 2 and 2; 46.2 s and 119.1 s).

## 3. Defect re-test

- [ ] 3.1 Compile the reduced probes of `private_constant`, the string returns, the empty array append, and the destructuring at both pins, and read the slab release in the new runtime; record each result in `docs/spinel-notes.md` and its `docs/backlog.md` entry.

## 4. Documentation

- [ ] 4.1 Update the Makefile comment, `CLAUDE.md` Commands, `README.md`, `docs/architecture.md` where it describes the header, `docs/spinel-notes.md` Toolchain, and `docs/codebase-map.md` area 2; verify with `make docs-lint` and `make gates`.
