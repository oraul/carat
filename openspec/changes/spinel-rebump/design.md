# Design

## Context

`make toolchain` fetches `SPINEL_REF` into `tmp/.spinel`, copies the vendored `tools/spinel/spinel_rt_responds_generated.h` into its `lib/`, and builds with `tools/noruby/` first on the `PATH`. `make spinel-header` compiles `tools/spinel/gen_respond_to_tables.rb` with the installed `spinel` and runs it on the checkout. The procedure is the one spinel-bump (archived 2026-11-10) introduced; this change only runs it again.

## Goals / Non-Goals

**Goals:**

- Build and test carat at 6b43fe94 with no CRuby, and keep every stage of `make check` green.

**Non-Goals:**

- Removing workarounds of defects the new pin may fix, and re-testing every open defect: `spinel-workarounds` reverts each workaround in the whole program, the only test that decides it.

## Decisions

- Regenerate the header with the f34005bf toolchain, then build the new one: the header must exist before the new toolchain can build, and the generator's inputs are text, so the old compiler reads the new sources the same way. Spinel's generator scripts are unchanged between the pins (`git diff --stat` of `tools/gen_respond_to_tables.rb` and `tools/builtin_row_gen.rb` is empty), so the port needs no change.
- Pin the full 40-digit commit, not a branch name, so `make spinel-rev` answers it without the remote and CI's cache keys change with it.
- A carat change is made only where a stage fails at the new pin, each one commented with the Spinel commit that needs it and recorded in `docs/spinel-notes.md`; a workaround that becomes removable is named in the pull request's Notes and left.

## Risks / Trade-offs

- [The new pin miscompiles carat] → `make check` finds it; a minimal workaround is recorded as above, or, where none is small, the run stops for the user's choice.
- [The new pin regresses allocations, rounds, or analysis time] → `bench-budget` and `metrics` in `make check`, `metrics-compare` in CI, and the benchmark phase compare with main's recorded figures.
- [CI's first run builds the toolchain cold] → expected: its cache key is the new `spinel-rev`; the cold build is the check that it builds with no Ruby.

## Migration Plan

None beyond running `make toolchain` after pulling: the old toolchain in `tmp/.toolchain` is replaced at the new pin.
