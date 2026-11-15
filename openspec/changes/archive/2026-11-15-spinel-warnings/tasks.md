# Tasks

## 1. Remove the warnings

- [x] 1.1 Remove the two ivar pins from the empty body of `carat/use_cases/windows/tab_request.rb`; proved by `make dev-build` printing no warning and `make test-run` passing
- [x] 1.2 Name `boundary` and `scalar?` with a `public_class_method` line at the end of `Carat::Domain::Utf8` (`carat/domain/utf8.rb`), with a comment giving the reason; proved by `make gen-config` printing no warning and `test/domain_utf8.rb` passing unchanged
- [x] 1.3 Require `carat/domain/json` in `test/lint.rb`, which calls `Carat::Json.element`; proved by `make lint` compiling without a warning and passing against its unchanged snapshot

## 2. Fail the builds on a warning

- [x] 2.1 Add `tools/spinel_warnings.sh` with its `check` mode and its compiler-wrapper mode; proved by the `spinel warnings` cases of `tools/tools_test.sh`
- [x] 2.2 Make `dev-build`, `test-build`, `build`, `diagnose`, and `diagnose-one` in the `Makefile` fail on a Spinel warning; proved by the `tools/tools_test.sh` cases driving each with a stub toolchain, and by `make dev-build`, `make test-build`, and `make build` passing on the tree
- [x] 2.3 Make `test-one` (and so `lint`), `bench`, `bench-budget`, `types`, and `gen-config` fail on a Spinel warning through the same check, keeping Spinel's standard error beside their output; proved by the `tools/tools_test.sh` cases driving each with a stub toolchain, and by `make test-one T=test/domain_utf8.rb`, `make lint`, `make bench SCENARIOS=lh`, `make bench-budget`, `make types`, and `make gen-config` passing on the tree

## 3. Documents

- [x] 3.1 Name `tools/spinel_warnings.sh` in area 1 of `docs/codebase-map.md` and in the `tools-test` description; checked by `make lint` and `make docs-lint`
- [x] 3.2 Record the pruned-method warning and every failing target in `docs/spinel-notes.md` (`docs/architecture.md` stays unchanged, at its budget); checked by `make docs-lint`
