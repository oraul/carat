# Design

## Context

See proposal.md, Why. `spin` is a compiled program, but its `test` command shells out to `ruby` in two places: `spin test --regen`, which this project never uses, and the comparison of a test program that has no `.expected` file, where it runs `ruby <program>`, writes both output streams to `build/test/<name>.cruby`, and compares the Spinel binary's output against that. The `ruby` it runs is whatever `sh` finds on the `PATH`. Every `make` target already runs with an exported `PATH` that puts `tmp/.toolchain/bin` first. Spinel's own Makefile calls `ruby` twice: a `$(shell ruby -rprism ...)` probe whose errors are discarded and whose empty result is handled, and the header generator, which the vendored header keeps from running.

## Goals / Non-Goals

**Goals:**

- No `make` target can start a CRuby, whatever is installed on the machine.
- A missing snapshot fails the test run loudly, with a message that names the cause.
- One cheap, repeatable command proves the guard, locally and in CI.

**Non-Goals:**

- Guarding shells outside `make`; the documentation forbids calling `spin test` directly instead.
- Patching `spin`.

## Decisions

- A stub on the `PATH` rather than removing `ruby` from the `PATH`. Filtering the `PATH` would have to drop whole directories such as `/usr/local/bin` or `/usr/bin` that hold the C compiler and other tools; a stub that sorts first shadows any `ruby` without touching anything else, and it is the mechanism CI already used for the toolchain step.
- The stub exits 127, the shell's "command not found" status, so callers that test for a missing `ruby` treat it as absent, and it writes to standard error only. Writing its message to standard error matters for `spin test`: that stream is captured into the `.cruby` file, so the refusal becomes the "expected" text in the failure report and names the cause where the developer is looking. A test program's own output can never equal that text, so the run cannot pass by accident.
- The stub is committed under `tools/noruby/`, next to the vendored Spinel header under `tools/spinel/`, and is referenced with `$(CURDIR)` so it is absolute and survives `$(MAKE) -C` into Spinel's checkout, which inherits the exported `PATH`.
- It goes ahead of `$(PREFIX)/bin` so that even a toolchain directory that one day contains a `ruby` cannot win. The assignment becomes `override export PATH := ...`, so a `PATH=...` given on the `make` command line is still prefixed with the stub and the toolchain instead of replacing them.
- `make doctor` runs the resolved `ruby` only when it is the stub's own path, so the check itself never starts a CRuby.
- `make doctor` checks the resolved path with `command -v ruby` against the stub's absolute path and runs it once to see exit status 127, so it fails both when another `ruby` sorts first and when the stub has lost its executable bit or been edited to succeed. It prints the ok line in the same column format as the other tools.
- `make no-cruby` creates its project with `mktemp -d` under `TMPDIR` (default `/tmp`), outside the repository, so no throwaway file can be committed and `spin` does not treat it as part of carat. The project holds a `spin.toml` and `test/probe.rb` printing one line, a program a CRuby would run with identical output, so with a real `ruby` reachable the run would pass; the target requires the run to fail and its report to contain the stub's message, then removes the directory through an `EXIT` trap. A Spinel test program in `test/` was considered and rejected: `spin test` would need to run `spin test` recursively, and a committed probe without a snapshot would break the rule that every test program has one.
- CI relies on the Makefile alone instead of also adding the stub to `GITHUB_PATH`, so CI exercises exactly the path a developer's `make` takes; `make doctor` and `make no-cruby` fail the job if that path ever stops reaching the stub.

## Risks / Trade-offs

- [A future target calls a tool that needs CRuby] → It fails at once with the stub's message naming the arguments, which is the intended outcome; such a tool is not allowed in this project.
- [`make run` starts the editor with the stub first on its `PATH`] → The editor starts no Ruby process today; roadmap item 10 decides how `ruby-lsp` is found when it lands.
- [Spinel's Makefile starts depending on the `ruby -rprism` probe] → `make toolchain` would fail with the stub's message on a cold build, which CI runs on every Spinel bump; the bump pull request handles it.

## Migration Plan

None. The next `make` invocation picks up the new `PATH`. Rolling back is reverting the commit.
