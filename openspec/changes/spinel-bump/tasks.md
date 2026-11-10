# Tasks

## 1. CRuby-free header regeneration

- [x] 1.1 Add `tools/spinel/gen_respond_to_tables.rb`, the reading part of Spinel's generator as a Spinel program; verify it compiles with the installed `spinel` and writes the committed header byte for byte from the 001419ff checkout.
- [x] 1.2 Add `make spinel-header` to the `Makefile` (help, `.PHONY`) and share the checkout steps with `make toolchain` through one canned recipe; verify with `make -n toolchain` and `make spinel-header`.

## 2. The bump

- [x] 2.1 Set `SPINEL_REF` to f34005bf and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header`; verify the diff is the generator's output only.
- [x] 2.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`, and confirm no `ruby` was reached.
- [ ] 2.3 Run `make check` on the new toolchain and compare allocations per key, rounds, and analysis time with main's figures (lh 27.0, j 28.0, insert 35.0; rounds 2 and 2; 46.2 s and 119.1 s).

## 3. Defect re-test

- [ ] 3.1 Compile the reduced probes of `private_constant`, the string returns, the empty array append, and the destructuring at both pins, and read the slab release in the new runtime; record each result in `docs/spinel-notes.md` and its `docs/backlog.md` entry.

## 4. Documentation

- [x] 4.1 Update the Makefile comment, `CLAUDE.md` Commands, `README.md`, `docs/architecture.md` where it describes the header, `docs/spinel-notes.md` Toolchain, and `docs/codebase-map.md` area 2; verify with `make docs-lint` and `make gates`.

## Blocker found in 2.3

- `make check` with f34005bf stops at `make build`: the C of `PluginRegistry#activate_all` (`carat/use_cases/plugins/plugin_registry.rb:231`) passes an `sp_Host *` where each plugin's `activate` expects `sp_PluginLink *`, and test roots fail on `@files.cwd` read as void (`carat/use_cases/files/delete_path.rb:36`, `rename_path.rb:37`, `ui_requests.rb:131`). Main's code compiles at 001419ff, so these are new miscompilations at the head; the run stopped for the user's choice (pin the newest commit that passes, work around them here, or hold the bump).
