# Proposal

## Why

`make toolchain` clones Spinel into `~/Repositories/spinel` and installs it under `~/.local`, outside the repository, and then asks the user to edit their shell `PATH` before any other target works. Worse, building Spinel at the pinned commit runs `ruby tools/gen_respond_to_tables.rb` to produce a header that is not in Spinel's git, so a machine without a Ruby interpreter cannot build the toolchain at all, which contradicts the project's rule that no CRuby is needed anywhere; the gap went unnoticed because GitHub's Ubuntu runner ships Ruby.

## What Changes

- `make toolchain` fetches Spinel into `tmp/.spinel` and installs `spinel`, `spin`, and `spinel-doctor` under `tmp/.toolchain`, both inside the repository and both still overridable with `SPINEL_SRC` and `PREFIX`, so every dependency the project fetches lives under one ignored directory. The two are hidden because `spin` treats every visible directory under the repository as project source; see design.md.
- The Makefile exports `PATH` with `$(PREFIX)/bin` first for every target, so after `make toolchain` the other targets (`doctor`, `build`, `run`, `test`, `check`, `snapshots`, `diagnose`, `types`, `gen-config`, `install`, `pack`) find the toolchain with no shell setup; the toolchain target's closing message says where the toolchain is and that the targets find it on their own.
- A new `make toolchain-clean` removes `tmp/`; `make clean` stays `spin clean` and never touches `tmp/`.
- The header Spinel's build generates with Ruby, `lib/spinel_rt_responds_generated.h`, is vendored at `tools/spinel/spinel_rt_responds_generated.h`, generated at the pinned commit, and the toolchain target copies it into the checkout before building, so the toolchain builds with no Ruby interpreter on the machine. Bumping `SPINEL_REF` now also regenerates that file in the same pull request.
- `make build` ends with a message that gives the absolute path of `build/bin/carat`, the alias line for bash and zsh and the one for fish to add to a shell profile, and that `make install` puts it on the `PATH` instead; `make install` says where it put the binary.
- `.gitignore` ignores `tmp/`.
- CI caches `tmp/.toolchain` under the same key, drops the step that edits the runner's `PATH`, and on a cache miss runs plain `make toolchain` with a stub `ruby` first on the `PATH` that fails when invoked, so every cold CI build proves the toolchain needs no Ruby.
- `CLAUDE.md`, `docs/architecture.md`, and the README describe the new locations, the automatic `PATH`, the vendored header, and the prerequisites, which are a C compiler, `make`, `git`, and `curl` only.

No editor behavior changes. No binding, message, or rendering is different.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a tooling change; `skip_specs` is set for this change.

## Impact

- `Makefile`: `SPINEL_SRC` and `PREFIX` defaults, the exported `PATH`, the `toolchain`, `toolchain-clean`, `build`, and `install` targets, and the help text.
- `tools/spinel/spinel_rt_responds_generated.h`: new, vendored, byte for byte the output of Spinel's generator at the pinned commit.
- `.gitignore`, `.github/workflows/ci.yml`.
- `CLAUDE.md` (Stack, Commands, Layout), `docs/architecture.md` (sections 2 and 11 and the testing section's CI line), `README.md` (prerequisites and build instructions).
- No Ruby source under `carat/`, `bin/`, or `test/` changes; no snapshot changes.

This change is outside the roadmap of `docs/architecture.md` section 12: it is tooling for the toolchain that item 1, `project-skeleton`, introduced, done now because the Ruby-free build the architecture promises was not actually true for the toolchain itself.

Out of scope: any container or image based build, changing the pinned Spinel commit, changing what `spin install` does, `make pack`, and the release work of roadmap item 15.

Assumptions recorded here instead of asked: `spinel-doctor` is installed by Spinel's `make install` alongside `spinel` and `spin`, as it is in the toolchain this change was verified with; the `PATH` export applies to every target, including the OpenSpec ones, where it is harmless; the vendored header is copied with a fresh modification time so Spinel's own rule sees it as up to date and does not run the generator; the checkout and the installed toolchain use hidden names under `tmp/` because `spin` scans every visible directory under the repository, and a visible `tmp/spinel` made `spin build` fail on the `.rbs` sidecars in Spinel's tests.
