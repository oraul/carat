# Design

## Context

See proposal.md for motivation. What was established on a fresh clone of the pinned Spinel commit before this change:

- Spinel's Makefile has a rule for `lib/spinel_rt_responds_generated.h` whose recipe runs `ruby tools/gen_respond_to_tables.rb`. The header is listed in Spinel's `.gitignore`, so a fresh checkout does not have it, and with no `ruby` on the `PATH` the build stops at that rule. Its prerequisites are five tracked files (`src/builtin_ops.c`, `src/builtin_zero_ops.inc`, `tools/gen_respond_to_tables.rb`, `tools/builtin_row_gen.rb`, `lib/spinel_rt.h`), so a copy of the header made after the checkout is newer than all of them and make leaves it alone.
- The header is a pure function of those sources: 5001 bytes, identical on every machine for a given commit. It cannot be produced by Spinel itself because the generator is a CRuby script.
- Spinel's Makefile also probes `ruby -rprism` to locate Prism, with the error output discarded and a fallback to the Prism tree `make deps` fetches with `curl`, so a `ruby` that fails is harmless there.
- With the header in place, `make deps`, `make`, and `make install` complete with zero Ruby invocations, and so does carat's `make check` afterwards.
- Spinel's `make install PREFIX=...` places `spinel`, `spin`, and `spinel-doctor` under `PREFIX/bin`, as absolute symlinks into `PREFIX/lib/spinel`, so an installed toolchain cannot be moved; it is reinstalled instead.
- `spin` scopes a project by walking from the directory that holds `spin.toml`. Its C census walks every directory except `build`, `vendor`, `test`, and hidden ones and reports every `.c` that no `[package] sources` entry names; `[package] exclude` can prune a directory from that census. Separately, if any `.rbs` exists anywhere under the root, including inside `tmp/`, it passes `--rbs <root>` to the compiler, whose extractor reads every `.rbs` under the root except in hidden directories; nothing in the manifest limits that glob. Found while applying this change: with the checkout at a visible `tmp/spinel`, `spin build` printed about 150 census lines and then failed on conflicting declarations in the `.rbs` fixtures of Spinel's own tests, even with `exclude = ["tmp"]` in the manifest. With the same trees at `tmp/.spinel` and `tmp/.toolchain`, `spin build` was clean with no manifest change.

The Makefile is a command map and builds nothing itself; the change keeps it that way.

## Goals / Non-Goals

**Goals:**

- Everything `make toolchain` fetches or installs lives under `tmp/`, ignored by git and removed by one target.
- A clone, `make toolchain`, and `make check` work on a machine with a C compiler, `make`, `git`, and `curl` and nothing else, and the user never edits `PATH`.
- CI proves the Ruby-free property on every cold build rather than assuming it.

**Non-Goals:**

- Changing how Spinel is built or installed beyond supplying the one header.
- Reorganizing `build/` or `dist/`, which `spin` owns.
- Any editor behavior.

## Decisions

- `SPINEL_SRC ?= $(CURDIR)/tmp/.spinel` and `PREFIX ?= $(CURDIR)/tmp/.toolchain`, with `?=` so a command line or environment override still wins. `$(CURDIR)` rather than a relative path, because the toolchain target runs `make -C` inside the checkout, where a relative `PREFIX` would resolve against the wrong directory. Alternative: keep the home-directory defaults and only document them; rejected because the request is to centralize the dependencies in the repository.
- The two directories under `tmp/` are hidden, `.spinel` and `.toolchain`, because that is the one convention `spin` honours in every scan it makes: the C census, the modification-time scan, the `.rbs` glob, and the extractor all skip entries that start with a dot. Alternatives: visible names plus `exclude = ["tmp"]` in `spin.toml`, which silences the census but not the `.rbs` glob, so the build still fails; deleting Spinel's `test/` tree or its `.rbs` files from the checkout after the build, which leaves a dirty checkout that the next `make toolchain` would have to repair and depends on where Spinel keeps its fixtures; a hidden top-level directory such as `.tmp/`, which is not the `tmp/` folder the request named. The `tmp/` folder itself stays visible, as asked, and `make help` prints both paths.
- `export PATH := $(PREFIX)/bin:$(PATH)` at the top of the Makefile, after `PREFIX` is set, so every recipe line and every `$(shell)` sees the installed toolchain first. One line covers every target, including ones added later. Alternative: prefix each `spin` and `spinel` call with `$(PREFIX)/bin/`; rejected because `spin` itself invokes `spinel` and `spinel-doctor` by name and must find them on the `PATH` anyway.
- The vendored header lives at `tools/spinel/spinel_rt_responds_generated.h`, named exactly as Spinel names it, and is copied with `cp` (not `cp -p`) after the checkout and before `make deps`, so its modification time is the copy time and newer than the checked-out prerequisites. A comment block above the toolchain target records that it is generated by Spinel's `tools/gen_respond_to_tables.rb` at the pinned commit, why it is vendored, and that a `SPINEL_REF` bump regenerates it in the same pull request. Alternative: patch Spinel's Makefile rule out in the checkout; rejected because it edits a third-party tree and breaks on the next bump. Alternative: ask the user to install Ruby once; rejected because it is the rule the project exists to avoid.
- The post-build message is a run of plain `@echo` lines, the form the file already uses for its other messages, and is built from `$(CURDIR)` so the alias is absolute wherever the repository is. It names `~/.bashrc`, `~/.zshrc`, and `~/.config/fish/config.fish`, gives the bash and zsh form `alias carat='.../build/bin/carat'` and the fish form `alias carat '.../build/bin/carat'`, and closes with the `make install` alternative. Alternative: a separate `make alias` target; rejected because the request is for the message to follow a build.
- `make install` passes `--prefix "$(PREFIX)/bin"`, because `spin install` copies the executables straight into the directory `--prefix` names (its default is `~/.local/bin`), and the old `--prefix "$(PREFIX)"` put `carat` beside `bin/` rather than in it; verified by running the target. With the default `PREFIX` the binary lands in `tmp/.toolchain/bin/carat`, on the `PATH` the Makefile exports, and the `@echo` after it names that path and says that `PREFIX=dir` installs into `dir/bin`.
- `toolchain-clean` is `rm -rf tmp` with its own `## ` help line; `clean` is unchanged, so a routine `make clean` never deletes a three-minute toolchain build.
- CI: the cache path becomes `tmp/.toolchain` with the same key; the `PATH` step goes away; a step before the toolchain step writes a `ruby` stub into `$RUNNER_TEMP/noruby/ruby` that prints a message and exits 127, and the toolchain step runs `PATH="$RUNNER_TEMP/noruby:$PATH" make toolchain` with no overrides, so a cold build fails if anything in the toolchain build invokes Ruby. The stub is scoped to that one step's command line so the later steps see the runner's normal `PATH`. Alternative: uninstall the runner's Ruby; rejected as slow and as a change to the runner image rather than a proof about the Makefile.
- The architecture document's statement that no CRuby is required gains the sentence that explains how it is guaranteed: the one generated header Spinel needs Ruby for is vendored, and CI builds the toolchain with a failing `ruby` on the `PATH`.

## Risks / Trade-offs

- [The vendored header silently goes stale after a `SPINEL_REF` bump] → The Makefile comment and the `CLAUDE.md` bump instruction both require regenerating it in the bump's pull request, and CI's Ruby-free cold build fails loudly if the copy is missing; a stale copy with the same prerequisites would be caught by the C compile of Spinel's runtime.
- [A file copied with an older timestamp would trigger Spinel's generator and fail] → `cp` without `-p` stamps the copy with the current time, which is later than the checkout; the toolchain target is verified with a failing `ruby` first on the `PATH`.
- [`make -C` inside Spinel inherits the exported `PATH` with a `tmp/.toolchain/bin` that does not exist yet] → A missing directory on the `PATH` is ignored by every shell; nothing in Spinel's build looks for `spinel` on the `PATH`.
- [Users who already ran `make toolchain` with the old defaults have a toolchain under `~/.local`] → Their `make` still works because `PATH` is prepended, not replaced; a fresh `make toolchain` builds under `tmp/` and they may remove the old copy by hand.
- [`tmp/` under the repository is scanned by `spin`] → The checkout and the installed toolchain sit in hidden directories, which every `spin` scan skips; `make check` is verified with both in place. A future Spinel that stops skipping hidden directories would show up as census lines or an `--rbs` failure in `make build` on the bump's pull request.
