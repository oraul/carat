# Design

## Context

The procedure is the one spinel-bump (archived 2026-11-10) introduced and spinel-rebump and spinel-compile-time (archived 2026-11-14) ran again: regenerate the vendored header with the installed toolchain, then build the new one, then `make check`. Part a (archived 2026-11-15) measured at b582d53e with a separate toolchain under `tmp/.spinel-new` and `tmp/.toolchain-new`, whose header the port generated after adding the nine Symbol false positives by hand: 125 rebuilds, `cg_methods` 20.0 s, 2 min 52 s in all.

Between 6af548c9 and 93d7883b, Spinel's `tools/builtin_row_gen.rb` is unchanged and `tools/gen_respond_to_tables.rb` changes only its `SYMBOL_FALSE_POSITIVE` list and comment; its inputs `src/builtin_ops.c` and `lib/spinel_rt.h` change, which the regenerated header follows.

## Goals / Non-Goals

**Goals:**

- Pin Spinel's newest commit with every stage green, allocations and rounds equal to main's, and compile time near the old pin's.
- Record the new pin's figures in `docs/spinel-notes.md`.

**Non-Goals:**

- Removing more untyped reads, FileUtils' rebuilds, or Spinel workarounds.
- Making Spinel warnings fatal.

## Decisions

- Pin 93d7883b, the remote's head when the change starts, rather than b582d53e: the brief asks for the newest commit and b582d53e only if it still is. Alternative: b582d53e, whose figures part a measured, rejected because it is not the newest; the figures are measured again at 93d7883b.
- Port the generator's change as Spinel made it: add the nine names to `SYMBOL_FALSE_POSITIVE` in the same order, so the port stays a line-for-line reading of Spinel's script.
- Regenerate the header with the 6af548c9 toolchain, then build the new one: the header must exist before the new toolchain can build (spinel-bump's decision).
- Measure the runner as `make test-build` compiles it, its `SP_TIMING` lines (`phase=an_elab_points ... builds=N`, `cg_methods`, analysis), and the stage seconds `make check` reports, against the figures in the regression entry.

## Risks / Trade-offs

- [The newest Spinel breaks something unrelated to untyped calls, or compile time stays far above the old pin's] → stop and ask with the numbers instead of bumping, as the brief says.
- [The new commit prints warnings] → reported in the pull request, not made fatal.
- [The seconds are machine dependent] → given beside the deterministic rebuild count.

## Migration Plan

None: squash-merged as one commit; CI's toolchain and compile caches miss once on the new rev and rebuild.

## Open Questions

None.
