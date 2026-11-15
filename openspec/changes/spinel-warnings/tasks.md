# Tasks

## 1. Remove the warnings

- [ ] 1.1 Remove the two ivar pins from the empty body of `carat/use_cases/windows/tab_request.rb`; proved by `make dev-build` printing no warning and `make test-run` passing
- [ ] 1.2 Name `boundary` and `scalar?` with a `public_class_method` line at the end of `Carat::Domain::Utf8` (`carat/domain/utf8.rb`), with a comment giving the reason; proved by `make gen-config` printing no warning and `test/domain_utf8.rb` passing unchanged

## 2. Fail the builds on a warning

- [ ] 2.1 Add `tools/spinel_warnings.sh` with its `check` mode and its compiler-wrapper mode; proved by the `spinel warnings` cases of `tools/tools_test.sh`
- [ ] 2.2 Make `dev-build`, `test-build`, `build`, `diagnose`, and `diagnose-one` in the `Makefile` fail on a Spinel warning; proved by the `tools/tools_test.sh` cases driving each with a stub toolchain, and by `make dev-build`, `make test-build`, and `make build` passing on the tree

## 3. Documents

- [ ] 3.1 Name `tools/spinel_warnings.sh` in area 1 of `docs/codebase-map.md` and in the `tools-test` description; checked by `make lint` and `make docs-lint`
- [ ] 3.2 Record the pruned-method warning in `docs/spinel-notes.md` and the failing targets in `docs/architecture.md` section 10; checked by `make docs-lint`
