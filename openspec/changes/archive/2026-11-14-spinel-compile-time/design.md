# Design

## Context

`make toolchain` fetches `SPINEL_REF` into `tmp/.spinel`, copies the vendored `tools/spinel/spinel_rt_responds_generated.h` into its `lib/`, and builds with `tools/noruby/` first on the `PATH`. `make spinel-header` compiles `tools/spinel/gen_respond_to_tables.rb` with the installed `spinel` and runs it on the checkout. The procedure is the one spinel-bump (archived 2026-11-10) introduced and spinel-rebump (archived 2026-11-14) ran again. This change runs it toward an older commit.

6af548c9 lies between f34005bf and 6b43fe94, 240 commits before 6b43fe94. 84aa303b1, the `byteindex` rule #120 met with `Utf8.boundary`, is not an ancestor of 6af548c9.

## Goals / Non-Goals

**Goals:**

- Build and test carat at 6af548c9 with no CRuby, with every stage of `make check` green.
- Bring test-build, diagnose, and CI compile_the_tests back to within about 25% of the figures from before #120.
- Record 2440954d1 in `docs/spinel-notes.md` as the compile-time regression.

**Non-Goals:**

- Typing carat's untyped `[]` calls so it compiles fast past 2440954d1 (`untyped-elephant`).
- Reverting #120's `Utf8.boundary` call sites.

## Decisions

- Pin 6af548c9, the parent of 2440954d1, not f34005bf. It is the newest commit without the regression, so the pin goes back only 240 commits, and it keeps the fixes up to 6af548c9 that #120 checked.
- Regenerate the header with the installed 6b43fe94 toolchain, then build the new one. The header must exist before the new toolchain can build, and Spinel's generator scripts (`tools/gen_respond_to_tables.rb`, `tools/builtin_row_gen.rb`) are identical at both pins, so the port needs no change.
- Keep `Utf8.boundary`. It builds at 6af548c9 and changes no answer, its tests pass there, and a later bump past 84aa303b1 needs it. The note in `docs/spinel-notes.md` names 84aa303b1 instead of the pin, so it stays true at both commits.
- Record the regression under "Analysis, tests, and the runner", because it is an analysis-time cost of the one-runner compile like the `untyped` widening note beside it. It gives the figures and the probe, so a later bump compares compile time and not only rounds.

## Risks / Trade-offs

- [6af548c9 lacks a fix carat relies on] → `make check` finds it; a minimal change is recorded, or the run stops for the user's choice.
- [Allocations or rounds change against main's 6b43fe94 figures] → `bench-budget`, `metrics`, and CI's `metrics-compare`; the benchmark phase compares.
- [CI's first run builds the toolchain cold] → expected, since the cache key is the new `spinel-rev`.

## Migration Plan

Run `make toolchain` after pulling: it replaces the toolchain in `tmp/.toolchain` with one built at the new pin.
