# Tasks

## 1. The stub and the make PATH

- [x] 1.1 Add `tools/noruby/ruby`, an executable POSIX `sh` script that prints the refusal and its arguments to standard error and exits 127; verify that running it directly exits 127 with the message and no standard output.
- [x] 1.2 Put `$(CURDIR)/tools/noruby` first on the exported `PATH` in the `Makefile`, ahead of `$(PREFIX)/bin`; verify that `make -s` of a recipe calling `command -v ruby` resolves to the stub and that `make build` still succeeds.
- [x] 1.3 Make `make doctor` print `ok       ruby: refused (stub)` when the resolved `ruby` is the stub and exits 127, and fail otherwise; verify with `make doctor`, and verify the failure path, without running the other `ruby`, by running the `Makefile` with `-f` from a scratch directory that has no `tools/noruby`, so the resolved `ruby` is the machine's and no committed file changes.

## 2. The proof target

- [x] 2.1 Add `make no-cruby` to the `Makefile` (and to `.PHONY`, the help text, and `check`): a temporary project outside the repository with a one-line `test/probe.rb` and no snapshot, `spin test` run in it through the make `PATH`, success only when that run fails and its report contains the stub's refusal; verify with `make no-cruby` while `/usr/local/bin/ruby` exists, and verify that no file is left in the repository or the temporary directory.

## 3. CI

- [x] 3.1 In `.github/workflows/ci.yml`, remove the inline stub step and the `PATH` prefix of the toolchain step, and add a `make no-cruby` step after `make doctor`; verify that the workflow still parses and that every step's `make` command passes locally; the pull request's job log, checked before merge, shows `ruby: refused (stub)` and the `no-cruby` proof.

## 4. Documentation

- [x] 4.1 Update `CLAUDE.md` (the Ruby 4 hard rule, Stack, Commands with `make doctor`, `make no-cruby`, and `make check`, Layout with `tools/noruby/ruby` and the CI line) so tests, snapshots, and benchmarks run only through `make`, never `spin test` directly; verify by reading the sections against the Makefile.
- [x] 4.2 Update `docs/architecture.md` (section 2's development loop and tests, section 10's CI line, section 11's layout) and the README's build section and command table to match; verify by reading them against the Makefile.

## 5. Integration

- [ ] 5.1 Run `make doctor` and `make check` with `/usr/local/bin/ruby` present and confirm both pass and that the stub, not CRuby, is what `spin` reached.
- [ ] 5.2 Confirm `make toolchain` still builds with the stub first on the `PATH` by building into a scratch `SPINEL_SRC` and `PREFIX` outside the repository, so the installed toolchain is not disturbed.

## Workflow follow-up

- Run the security review on the committed branch diff.
- Archive with `--skip-specs`, then open, check, and squash-merge the pull request.
