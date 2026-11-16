# Design

## Context

`make toolchain` fetches `SPINEL_REF` into `tmp/.spinel`, copies the vendored `tools/spinel/spinel_rt_responds_generated.h` into its `lib/`, and builds with `tools/noruby/` first on the `PATH`. `make spinel-header` compiles `tools/spinel/gen_respond_to_tables.rb` with the installed `spinel` and runs it on the checkout. The procedure is the one spinel-bump (archived 2026-11-10) introduced and spinel-rebump and spinel-untyped-bump ran again; this change runs it once more.

## Goals / Non-Goals

**Goals:**

- Build and test carat at c0502112 with no CRuby, keep every stage of `make check` green and `make diagnose` clean, and hold allocations per key and analysis rounds or explain any change.

**Non-Goals:**

- Removing workarounds of defects the new pin may fix, and re-testing every open defect of `docs/spinel-notes.md`.

## Decisions

- Regenerate the header with the 93d7883b toolchain, then build the new one: the header must exist before the new toolchain can build, and the generator's inputs are text. Spinel's generator scripts are unchanged between the pins (`git diff --stat` of `tools/gen_respond_to_tables.rb` and `tools/builtin_row_gen.rb` is empty), so the port needs no change.
- Pin the full 40-digit commit, not a branch name, so `make spinel-rev` answers it without the remote and CI's cache keys change with it.
- A carat change is made only where a stage fails at the new pin, as a fix of carat's code rather than a workaround, each one commented where the reason is not obvious and recorded in `docs/spinel-notes.md` when it is a new pitfall.

## Risks / Trade-offs

- [The new pin miscompiles carat] → `make check` finds it; the fix goes into carat's code, or, where none is small, the run stops for the user's choice.
- [The new pin regresses allocations, rounds, or analysis time] → `bench-budget` and `metrics` in `make check`, `metrics-compare` in CI, and the benchmark phase compare with main's recorded figures.
- [CI's first run builds the toolchain cold] → expected: its cache key is the new `spinel-rev`.

## Migration Plan

None beyond running `make toolchain` after pulling: the old toolchain in `tmp/.toolchain` is replaced at the new pin.
