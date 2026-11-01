# Proposal

## Why

`spin test` compares a test program against CRuby when its `.expected` snapshot is missing: it runs `ruby` from the `PATH` and takes that output as the expected one. Developer machines and GitHub's Ubuntu runner both have a CRuby on the `PATH`, so a new test program run before its snapshot exists is silently judged by Ruby 3, which breaks the hard rule that nothing in this project ever runs a CRuby interpreter; it happened once while a change was in progress and only care kept it out of the repository. CI proves the toolchain build Ruby-free with a stub `ruby` on the path of that one step, but no other target, and no other CI step, has the same guarantee.

## What Changes

- A committed stub interpreter, `tools/noruby/ruby`, a POSIX `sh` script that prints to standard error that carat never runs a CRuby interpreter, names the arguments it was called with, and exits 127.
- The Makefile puts `$(CURDIR)/tools/noruby` first on the exported `PATH` of every recipe, ahead of the toolchain directory, so `spin test`, `spin run`, `make snapshots`, `make bench`, `make bench-budget`, `make profile`, `make toolchain`, and every other target reach the stub whenever they call `ruby`, never a CRuby installed on the machine.
- `make doctor` reports `ruby: refused (stub)` as an ok line when the `ruby` the make `PATH` resolves is the stub and it refuses with exit status 127, and fails when any other `ruby` would be reached.
- A new `make no-cruby` target proves the guard end to end: it writes a throwaway one-line test program with no snapshot into a temporary project outside the repository, runs `spin test` on it through the make `PATH`, and passes only when that run fails with the stub's refusal as the expected output, which shows that `spin` reached the stub instead of comparing against a CRuby. The temporary project is removed afterwards. `make check` runs it after the tests.
- CI drops its inline stub step and the `PATH` prefix of the toolchain step, since the Makefile now applies the committed stub to every target, including `make toolchain` on a cache miss, and runs `make no-cruby` after `make doctor`.
- `CLAUDE.md` (hard rules, Stack, Commands, Layout), `docs/architecture.md`, and the README say that tests, snapshots, and benchmarks run only through `make`, never by calling `spin test` directly, because `spin test` falls back to a `ruby` on the `PATH` when a snapshot is missing, and describe the stub and the new target.

No editor behavior changes. No binding, message, rendering, or snapshot is different.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a tooling change; `skip_specs` is set for this change.

## Impact

- `tools/noruby/ruby`: new, executable.
- `Makefile`: the exported `PATH`, the `doctor` target, the new `no-cruby` target, `check`, the help list, and `.PHONY`.
- `.github/workflows/ci.yml`: the stub step removed, the toolchain step simplified, a `make no-cruby` step added.
- `CLAUDE.md`, `docs/architecture.md` (sections 2, 10, and 11), `README.md` (build section and command table).
- No Ruby source under `carat/`, `bin/`, `test/`, or `bench/` changes.

This change is outside the roadmap of `docs/architecture.md` section 12: it is tooling that makes the project's existing rule, Ruby 4 through Spinel only, hold for every target, done now because the gap was hit while delivering the previous change.

Out of scope: changing Spinel or `spin` itself (the fallback stays in the tool; the project only makes it unreachable), a `ruby` guard for commands run outside `make`, which the documentation forbids instead, the `spin test --regen` option, which the project already never uses, and the language services of roadmap item 10, which will start `ruby-lsp` as a subprocess of the editor and will decide then how the editor finds it.

Assumptions recorded here instead of asked: the stub also applies to `make run`, which starts the editor with the make `PATH`; the editor starts no Ruby process today, and roadmap item 10 will revisit this when it adds `ruby-lsp`. `make no-cruby` belongs in `make check` because it costs one compile of a one-line program and is the only proof that the guard works. Spinel's own Makefile probes `ruby -rprism` for a Prism location with its errors discarded; with the stub that probe finds nothing and the build uses the Prism sources `make deps` fetches, as it already does in CI.
