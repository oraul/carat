# Design

## Context

See proposal.md, Why. `make toolchain` fetches `SPINEL_REF` into `tmp/.spinel`, copies the vendored header into `lib/`, and builds with `tools/noruby/` first on the `PATH`; Spinel's rule for the header (`ruby tools/gen_respond_to_tables.rb`) sees a newer copy and never runs. The header is a pure function of `src/builtin_ops.c`, `src/builtin_zero_ops.inc`, `lib/spinel_rt.h`, and the two generator scripts. Spinel's generator requires `builtin_row_gen.rb`, which loads prism, json, digest, and timeout for its probe machinery and uses `extend` and multiple assignment Spinel refuses; compiled whole, even with `--defer-refusals`, its C does not build.

## Goals / Non-Goals

Goals: a repeatable, CRuby-free regeneration that a later bump runs with one target; the bump itself; a recorded re-test of each defect.

Non-Goals: removing workarounds (`spinel-workarounds`); a check that compares the vendored header with the checkout on every `make check` (it needs the checkout, which CI's toolchain cache does not keep).

## Decisions

- Port the reading part of the generator to a Spinel program instead of compiling Spinel's script: only `rows`, `families_of`, `method_list`, and `INTERNAL_NAME` of `builtin_row_gen.rb` reach the header, all text scanning. The port keeps the same patterns (the bop_rows and BZ_ patterns, the quoted-literal and strcmp scans), the same exclusions, and the four coverage checks that refuse a header Spinel's build would also refuse. Alternatives: a shell and awk port (a second language for one file, and not a Spinel program as the hard rule asks of generators); a patched copy of Spinel's script with a stub `builtin_row_gen.rb` (its `ROOT` comes from `__dir__`, so it would have to be copied into the checkout, and the stub is a port anyway).
- Validate the port where CRuby's answer is known: at 001419ff it reproduces the committed header byte for byte. Spinel's two generator files are identical at 001419ff and f34005bf, so the same port is valid at the new pin.
- Avoid the shapes the notes warn about in the port: no look-around regex (`INTERNAL_NAME` is a string test), no `gsub` with a back reference (a loop unescapes), no destructuring, no `Struct`.
- `make spinel-header` compiles with whatever `spinel` is installed, which during a bump is the old pin's: the header must exist before the new toolchain can build. It writes through a temporary file in `build/spinel/` and prints the diff stat.
- The checkout steps move into one `define` used by both targets, so the two cannot drift.
- Defects are re-tested with reduced probes compiled at both pins: a probe that reproduces at 001419ff and answers correctly at f34005bf marks the defect fixed; one that reproduces at both stays open; one that does not reproduce at 001419ff cannot decide, and the defect stays open for `spinel-workarounds`, which reverts the workaround in the whole program. The slab release is read in the runtime source.

- The user chose to stay on f34005bf and fix carat (option b). The entry's link is typed as `PluginApi::Host`, the type every plugin's `activate` takes, since nothing reads it as a `PluginLink`; the store goes through a typed parameter because the Struct writer does not upcast. `Mode.visual_kind` uses guard returns. The raising bases that a second override turns into a versioned entry answer the failure value their overrides already use (`TextResponse.failure`, `FileInfo.missing`, `PathInfo.missing`), only where `make diagnose` reports it, the smallest workaround; changing every raising base of the 36 Host and 12 port methods is a contract change for its own proposal.
- The `cwd` error the stopped run saw in test roots does not appear once the link compiles: the runner builds, runs, and diagnoses clean, so `FilePort#cwd` keeps its raising base.
- The 001419ff warnings: Spinel cannot pin `Regexp` or `MatchData`, so those annotations were never applied; parameter lines type what it can and inference the rest, which is what it did before.

## Risks / Trade-offs

- [Spinel's generator changes in a later bump] → the port would silently diverge. The Makefile comment and the port's header say a bump whose generator files changed ports the change in the same pull request; `git diff OLD NEW -- tools/gen_respond_to_tables.rb tools/builtin_row_gen.rb` in the checkout shows it.
- [The new pin regresses allocations, rounds, or analysis time] → `make check` (bench-budget, metrics) and the benchmark phase compare with main's figures; a regression stops the change.
- [A `.rb` file under `tools/`] → `spin` reads visible directories, but builds only the roots it is given; `make check` proves no target picks it up.
