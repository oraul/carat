# Design

## Context

Spinel 2440954d1 added a check to the call plan (`ct_main_stopped`) that asks the load record for the point of a call (`elab_point_of`). The record is rebuilt whenever the node table changed since it was last built (`elab_fresh`), and code generation appends nodes as it goes, so from that commit on a question asked during code generation after an append walks the whole program again. `SP_TIMING` reports the count as `spinel-timing: phase=an_elab_points ms=... builds=N`: 39 for the runner at 6af548c9, 4,501 at 6b43fe94, where those walks take 244 of the 413 s of `cg_methods`.

To see which carat code asks, the measurement toolchain (6b43fe94, built with `make toolchain SPINEL_REF=... SPINEL_SRC=tmp/.spinel-new PREFIX=tmp/.toolchain-new`) carries a local trace in `elab_fresh`, printed only under `SP_ELAB_TRACE`, naming for each rebuild the method being generated and the call that asked. Every rebuild from carat comes in a pair, the call `[]` and then a `new`, once per `[]` whose receiver is `untyped`. A typed receiver costs nothing, whatever the element type: `(Array[untyped], Integer) -> untyped` reads make no rebuild, and a `.to_i` after `pair[0]` does not help, since the receiver is what matters.

The trace of the runner at 6b43fe94 before this change: `Testing#table` 2,260; the test modules' own code 1,887, most of it the table blocks' `input[i]`; `JsonRpcLanguageGateway` 210; FileUtils (bundled) 24; the rest under 20 each.

## Goals / Non-Goals

**Goals:**

- Remove the main cause, the untyped table rows, so the runner's rebuilds at 6b43fe94 fall by most of the 4,501, with behavior and every snapshot unchanged, and every stage green at 6af548c9.
- Name the construct to avoid in `docs/spinel-notes.md`.

**Non-Goals:**

- The JSON reads of the language gateway and the language-server tests, and the test helpers and loops outside table blocks (the second part, see the proposal).
- Changing Spinel or `SPINEL_REF`.

## Decisions

- `table` reads its rows with `cell(row, i)`, the element reader `lint` already allows. Its body is generated once per call of `table` (226 calls), so this removes about half of the rebuilds with one file changed. Alternative: typed row records (`Row.new(label:, input:, expected:)`) at each of the 226 calls, rejected as a rewrite of every table for the same effect.
- The tables whose inputs are arrays move to a second method, `cases`, rather than `table` yielding a typed array: the block's parameter takes the type the yield gives it, and many tables yield a String or a Symbol, which an `Array[untyped]` signature would misdescribe (Spinel trusts it unverified). `cases` yields `list(row, 1)`, `(Array[untyped], Integer) -> Array[untyped]`, so it may only be called with array inputs.
- The tables were moved by a script, not by hand: a table moves when every row is a single line whose input is an array literal (`["label", [`) and its block (a `do` block or a one-line brace block) indexes its parameter. 91 of the 226 table calls matched; the others keep `table`. The script stays out of the repository: the change is the moved calls.
- A wrongly moved table would fail, not pass silently: its snapshot would differ or the runner would not compile, and `make test` runs every one at the pinned 6af548c9.

## Risks / Trade-offs

- [`cases` with a non-array input is a type lie] → The comment of `cases` says so, `docs/examples.md` names when to use it, and the tests catch a mistake by their snapshots.
- [The figures depend on the Spinel commit] → The rebuild count is deterministic for a commit and the source; the seconds are machine dependent and given only beside it.

## Migration Plan

None: tests only, squash-merged as one commit.

## Open Questions

None.
