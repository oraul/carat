# Tasks

## 1. CRuby-free header regeneration

- [x] 1.1 Add `tools/spinel/gen_respond_to_tables.rb`, the reading part of Spinel's generator as a Spinel program; verify it compiles with the installed `spinel` and writes the committed header byte for byte from the 001419ff checkout.
- [x] 1.2 Add `make spinel-header` to the `Makefile` (help, `.PHONY`) and share the checkout steps with `make toolchain` through one canned recipe; verify with `make -n toolchain` and `make spinel-header`.

## 2. The bump

- [x] 2.1 Set `SPINEL_REF` to f34005bf and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header`; verify the diff is the generator's output only.
- [x] 2.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`, and confirm no `ruby` was reached.
- [x] 2.3 Run `make check` on the new toolchain and compare allocations per key, rounds, and analysis time with main's figures (lh 27.0, j 28.0, insert 35.0; rounds 2 and 2; 46.2 s and 119.1 s).
  - Result with section 5: `make check` passes; rounds 2 and 2, analysis 38.9 s (carat) and 80.7 s (runner), against 46.2 s and 119.1 s; allocations per key lh 28.0, j 29.0, insert 36.0, one more than main's each, traced in 5.6 to Spinel 59044ad58; after 5.6, lh 26.0, j 27.0, insert 34.0.

## 3. Defect re-test

- [x] 3.1 Compile the reduced probes of `private_constant`, the string returns, the empty array append, and the destructuring at both pins, and read the slab release in the new runtime; record each result in `docs/spinel-notes.md` and its `docs/backlog.md` entry.

## 4. Documentation

- [x] 4.1 Update the Makefile comment, `CLAUDE.md` Commands, `README.md`, `docs/architecture.md` where it describes the header, `docs/spinel-notes.md` Toolchain, and `docs/codebase-map.md` area 2; verify with `make docs-lint` and `make gates`.

## 5. Carat at f34005bf (the user's option b)

- [x] 5.1 Type `PluginEntry#link` as `PluginApi::Host?`, stored through `PluginEntry#attach`; verify with `make build` and `make test-build`.
- [x] 5.2 Rewrite `Mode.visual_kind` with guard returns; verify `make test-run` passes all 103 tests.
- [x] 5.3 Make `Host#icon`, `Host#stat`, and `FilePort#stat` answer typed values; verify `make diagnose-one T=test/runner/run_all.rb` is clean.
- [x] 5.4 Bisect the `when` probe between 001419ff and f34005bf (Spinel ade8cfe2) and record the three miscompilations in `docs/spinel-notes.md` with a `docs/backlog.md` entry.
- [x] 5.5 Remove the 001419ff inline RBS warnings in `search.rb`, `replacement.rb`, `search_pattern.rb`, `testing.rb`, and `bench/keys.rb`; verify with `make lint`, the build, test-build, and bench logs.
- [x] 5.6 Trace the extra allocation per key: build the bench of this branch with the 001419ff toolchain (main's figures, so the pin causes it), find the site with a per-call trace (`Symbol#to_s` in `Mode.name_of`, Spinel 59044ad58), answer `Symbol#name` there, and record it in `docs/spinel-notes.md`; verify with `make bench SCENARIOS="lh j insert"`, `make lint`, and `make test-one T=test/domain_keymap.rb`.
- [x] 5.7 Name the three port bases that answer a failure value at f34005bf (`FilePort#stat`, `PluginApi::Host#stat`, `Host#icon`) in `docs/architecture.md` section 6, pointing at `docs/spinel-notes.md` Known miscompilations, within its budget; verify with `make docs-lint` and `make gates`.

## Blocker found in 2.3 (resolved by section 5)

- `make check` with f34005bf stops at `make build`: the C of `PluginRegistry#activate_all` (`carat/use_cases/plugins/plugin_registry.rb:231`) passes an `sp_Host *` where each plugin's `activate` expects `sp_PluginLink *`, and test roots fail on `@files.cwd` read as void (`carat/use_cases/files/delete_path.rb:36`, `rename_path.rb:37`, `ui_requests.rb:131`). Main's code compiles at 001419ff, so these are new miscompilations at the head; the run stopped for the user's choice (pin the newest commit that passes, work around them here, or hold the bump).
