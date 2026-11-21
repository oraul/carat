# Design

## Context

`make toolchain` fetches `SPINEL_REF` into `tmp/.spinel`, copies the vendored `tools/spinel/spinel_rt_responds_generated.h` into its `lib/`, and builds with `tools/noruby/` first on the `PATH`. `make spinel-header` compiles `tools/spinel/gen_respond_to_tables.rb` with the installed `spinel` and runs it on the checkout. The procedure is the one spinel-bump (archived 2026-11-10) introduced and spinel-catchup (2026-11-19) ran last; this change runs it again from 0d1a7ca33a6e.

## Goals / Non-Goals

**Goals:**

- Build and test carat at the newest upstream commit that passes, with no CRuby, keeping every stage of `make check` green and `make diagnose` clean.
- Compare with main at 0d1a7ca3, measured on the same machine before the bump: rounds and allocations per key (`make metrics`, `metrics-compare`), time per key (`make bench`), analysis time (the `analysis-budget` lines of `make test-build` and `make dev-build`), and the release binary's size (`make build`).
- Recheck the open miscompilations of `docs/spinel-notes.md` that a reduced probe can decide, and say which the new pin no longer shows.

**Non-Goals:**

- Removing the workarounds those notes describe, unless the change is trivial and a test proves it.

## Decisions

- Measure main first: the baseline runs with the 0d1a7ca3 toolchain in this worktree before the checkout moves, so before and after come from one machine and one load.
- Regenerate the header with the 0d1a7ca3 toolchain, then build the new one: the header must exist before the new toolchain can build, and the generator's inputs are text. When Spinel's generator scripts changed between the pins, the port follows them first.
- Pin the full 40-digit commit, not a branch name, so `make spinel-rev` answers it without the remote and CI's cache keys change with it.
- On a failure that carat cannot fix small and local, bisect upstream's first-parent line between the pins and pin the newest passing commit, naming the skipped commits; otherwise stop and name the stage and log lines.

## Risks / Trade-offs

- [The new pin miscompiles carat] → `make check` finds it; a small local fix in carat's code, else an earlier pin or a stop.
- [The new pin regresses allocations, rounds, or analysis time] → `bench-budget` and `metrics` in `make check`, `metrics-compare` against the baseline, the benchmark phase, and CI's `metrics-compare`; the accepted allocations (lh 26, j 27, insert 26) must hold.
- [CI's first run builds the toolchain cold] → expected: its cache key is the new `spinel-rev`.

## Migration Plan

None beyond running `make toolchain` after pulling: the old toolchain in `tmp/.toolchain` is replaced at the new pin.
