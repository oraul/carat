# Tasks

## 1. The bump

- [x] 1.1 Set `SPINEL_REF` in the `Makefile` to 6b43fe94de957419fd6a670fae365987b40d4f1a and regenerate `tools/spinel/spinel_rt_responds_generated.h` with `make spinel-header` using the f34005bf toolchain; verify the diff is the generator's output only and `make -s spinel-rev` prints the new commit.
- [x] 1.2 Build the new toolchain with `make toolchain` with the stub first on the `PATH`; verify it installs `spinel`, `spin`, and `spinel-doctor` and `make doctor` reports `ruby: refused (stub)`.

## 2. Carat at the new pin

- [ ] 2.1 Run every stage of `make check` (`CHECK_STAGES`) on the new toolchain, fixing only what fails at the new pin, each fix commented and recorded in `docs/spinel-notes.md`; verify `make check` passes and compare allocations per key, rounds, and analysis time with main's figures in `docs/metrics.tsv`.
- [x] 2.2 Start every `byteindex` with an offset at a character boundary through a new `Domain::Utf8.boundary` (`text_lines.rb`, `ex_range.rb`, `markdown_text.rb`, `rpc_framer.rb`, `vim_pattern.rb`, `file_requests.rb`; inlined in `PluginApi::Paths.segments`), recorded in `docs/spinel-notes.md`; verify with the new rows of `test/domain_utf8.rb`, `domain_vim_pattern.rb`, `domain_rpc_framer.rb`, and `use_cases_plugin_files.rb` through `make snapshots` (diff read), and the failing `domain_buffer.rb` and `domain_utf8.rb` passing.

## 3. Report

- [ ] 3.1 Name any carat Spinel workaround the new pin makes removable (left for `spinel-workarounds`) in the change's notes; verify with `make docs-lint`, `make gates`, and `make spec-validate`.
