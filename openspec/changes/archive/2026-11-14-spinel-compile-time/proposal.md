# Proposal

## Why

Since #120 moved `SPINEL_REF` from f34005bf to 6b43fe94, every compile of carat takes about four times as long: `make test-build` 583 to 736 s against 125 to 158 s before, `make diagnose` 602 to 659 s against 148 to 175 s, and CI's compile_the_tests 519 to 613 s against 86 to 134 s. This run measured the cause as Spinel 2440954d1: the runner compiles in 125 s at its parent 6af548c9 and in 412 s at 2440954d1, with 4,501 code generation rebuilds against 39. At 2440954d1 each `[]` on an untyped receiver rebuilds the position map, so the cost grows with the untyped calls times the record classes. The user chose to move the pin back to 6af548c9, the last commit before it, and to remove carat's untyped `[]` calls in the next change.

## What Changes

- `SPINEL_REF` moves from 6b43fe94de957419fd6a670fae365987b40d4f1a to 6af548c9be5683902cb1abc8c2cb6f307b7e7a74, the parent of 2440954d1, in its own pull request as the Makefile and `CLAUDE.md` require.
- `tools/spinel/spinel_rt_responds_generated.h` is regenerated at the new pin with `make spinel-header`, run with the 6b43fe94 toolchain before `make toolchain`. Spinel's generator scripts are identical at both pins.
- #120's carat changes stay as they are. Its only carat change, `Domain::Utf8.boundary` at the `byteindex` call sites, still builds at 6af548c9 but is not strictly needed there: the `IndexError` it avoids is Spinel 84aa303b1, which comes after 6af548c9. It stays because it is the smallest change: it alters no answer for any ASCII needle, its tests pass at both pins, and the next bump past 84aa303b1 needs it again. Removing it would be a revert with its own tests to remove.
- `docs/spinel-notes.md` records 2440954d1 as the compile-time regression, so a later bump past it is checked for compile time, and its `byteindex` note now names 84aa303b1, after the pin, as the commit that brings the rule.

No editor behavior changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a toolchain change, so `skip_specs` is set.

## Impact

- `Makefile`: `SPINEL_REF`.
- `tools/spinel/spinel_rt_responds_generated.h`: regenerated (left unchanged if the generator's output is the same).
- `docs/spinel-notes.md`: the compile-time entry and the `byteindex` note.
- CI: unchanged. Its toolchain and compile caches are keyed on `make spinel-rev`, so the first run builds a fresh toolchain.
- CLAUDE.md: unchanged, the commands and the bump procedure stay the same and only the pinned value moves.
- README.md: unchanged, no command, option, or user-visible behavior changes.
- docs/architecture.md: unchanged, it names `SPINEL_REF` without its value.

Outside the roadmap of `docs/architecture.md` section 12: a toolchain pin the user chose to fix the compile time, made in its own pull request as the Makefile requires.

Out of scope: changing carat's untyped `[]` calls (the queued `untyped-elephant` item); removing `Utf8.boundary` or any other workaround; changing Spinel; the planner's queue decisions in the brief, which the planner and the package step write.

Assumptions recorded here instead of asked: "keep whatever #120's carat changes still need and nothing else" is read as keep the code that builds and stays green, so `Utf8.boundary` stays as the smallest change, named above, and is not reverted.
