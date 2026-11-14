# Tasks

## 1. The bump

- [x] 1.1 Set `SPINEL_REF` in the `Makefile` to 6b43fe94de957419fd6a670fae365987b40d4f1a and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the f34005bf toolchain; verify the diff is the generator's output only and `make -s spinel-rev` prints the new commit.
- [x] 1.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`; verify it installs `spinel`, `spin`, and `spinel-doctor` and `make doctor` reports `ruby: refused (stub)`.

## 2. Carat at the new pin

- [x] 2.1 Run every stage of `make check` (`CHECK_STAGES`) on the new toolchain, fixing only what fails at the new pin, each fix commented and recorded in `docs/spinel-notes.md`; verify `make check` passes and compare allocations per key, rounds, and analysis time with main's figures in `docs/metrics.tsv`.
  - Result with 2.2: `make check` passes, 104 of 104 tests and 1123 of 1123 tool tests; rounds 2 and 2; allocations per key lh 26.0, j 27.0, insert 32.0, ddp 58.0, undo 52.0, dot-ciw 78.0, lh-ruby 26.0, open-ruby 24.0, against main's 26.0, 27.0, 34.0, 58.0, 52.0, 82.0, 26.0, 24.0 (none higher). Analysis 54.7 s (carat) and 112.9 s (runner) on this machine, above the 45 s warning, which is machine dependent and not a failure. The first run's only failures were `domain_buffer.rb` and `domain_utf8.rb` (2.2).
- [x] 2.2 Start every `byteindex` with an offset at a character boundary through a new `Domain::Utf8.boundary` (`text_lines.rb`, `ex_range.rb`, `markdown_text.rb`, `rpc_framer.rb`, `vim_pattern.rb`, `file_requests.rb`; inlined in `PluginApi::Paths.segments`), recorded in `docs/spinel-notes.md`; verify with the new rows of `test/domain_utf8.rb`, `domain_vim_pattern.rb`, `domain_rpc_framer.rb`, and `use_cases_plugin_files.rb` through `make snapshots` (diff read), and the failing `domain_buffer.rb` and `domain_utf8.rb` passing.

## 3. Report

- [x] 3.1 Name any carat Spinel workaround the new pin makes removable (left for `spinel-workarounds`) in the change's notes; verify with `make docs-lint`, `make gates`, and `make spec-validate`.
  - Result: none is named removable. The `when CONST` probe (two modules defining `VISUAL`, a `case` on one) still answers `none` at 6b43fe94, so `Mode.visual_kind` keeps its `==` guards. A reduced versioned-entry probe (a raising base `stat`, an override, a reopened class) answers correctly, but the f34005bf toolchain was replaced, so it cannot show the probe reproduced there and decides nothing; `PluginEntry#attach` and the three port bases stay for `spinel-workarounds`. The log of the 878 commits names none of the open defects. New warning, not a failure: the `carat-gen-config` build warns that the annotations of `Utf8.scalar?` and `Utf8.boundary` are not applied, since that root never calls them (Spinel 7bc3fe018 leaves out a method nothing names).
