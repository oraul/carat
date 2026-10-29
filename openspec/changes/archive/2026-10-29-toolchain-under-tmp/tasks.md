# Tasks

## 1. Vendor the generated header

- [x] 1.1 Copy `lib/spinel_rt_responds_generated.h` from a checkout of the pinned Spinel commit to `tools/spinel/spinel_rt_responds_generated.h`; verify the source checkout's `HEAD` equals `SPINEL_REF` in the `Makefile` and that `cmp` reports the two files identical

## 2. Makefile

- [x] 2.1 Default `SPINEL_SRC` to `$(CURDIR)/tmp/.spinel` and `PREFIX` to `$(CURDIR)/tmp/.toolchain` (hidden, because `spin` scans every visible directory under the repository), export `PATH` with `$(PREFIX)/bin` first, and add the comment block and the header copy step to the `toolchain` target between the checkout and `make deps`, with a closing message that names the install location and says the targets find it automatically; verify with `make toolchain` run with a failing `ruby` stub first on the `PATH`, which must complete and leave `spinel`, `spin`, and `spinel-doctor` under `tmp/.toolchain/bin` with no Ruby invocation
- [x] 2.2 Add the `toolchain-clean` target with its `## ` help line and keep `clean` as `spin clean`; verify `make help` lists it, `make toolchain-clean` removes `tmp/`, and `make clean` leaves `tmp/` in place
- [x] 2.3 Add the alias message to the `build` target and the install location line to the `install` target; verify `make build` prints the absolute path of `build/bin/carat`, the three profile names, the bash and zsh alias line, the fish alias line, and the `make install` line, and that `make help` still renders every target
- [x] 2.4 Add `tmp/` to `.gitignore`; verify `git status` shows nothing under `tmp/` after `make toolchain`

## 3. Continuous integration

- [x] 3.1 In `.github/workflows/ci.yml`, cache `tmp/.toolchain` under the existing key, add the step that writes the failing `ruby` stub into `$RUNNER_TEMP`, run plain `make toolchain` with that stub first on the `PATH` on a cache miss, and remove the step that edits the runner's `PATH`; verify by reading the workflow against the Makefile and by running the stub script it writes locally, which must print its message and exit non-zero

## 4. Documentation

- [x] 4.1 Update `CLAUDE.md`: the Stack bullet on CRuby says how the guarantee holds, the Commands entries for `make toolchain` and its bump instruction mention `tmp/` and the vendored header, `make toolchain-clean` is listed, and the Layout names `tmp/` in `.gitignore`, `tools/spinel/`, and the new CI steps; verify by reading the file against the Makefile and the workflow
- [x] 4.2 Update `docs/architecture.md` wherever it describes the toolchain location, the CI build, the install prefix, or the CRuby rule, and the repository layout block; verify by reading the sections against the Makefile
- [x] 4.3 Update `README.md` with the prerequisites (a C compiler, `make`, `git`, and `curl`), the `make toolchain` then `make build` sequence, and the `make toolchain-clean` row; verify the documented commands run as written

## 5. Verify

- [x] 5.1 Run `make doctor` and `make check` with a `PATH` that holds neither another Spinel toolchain nor a real `ruby`, so the Makefile's exported `PATH` is what finds `tmp/.toolchain/bin`; verify every check passes and `git status` shows no `tmp/` entry

## Workflow follow-up

- Archive the change with `--skip-specs` before the commit, open the pull request, and merge it once the `spin` check is green on a cold cache.
