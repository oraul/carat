# Proposal

## Why

`SPINEL_REF` stays at 6af548c9 because from Spinel 2440954d1 on each `[]` generated on an `untyped` receiver rebuilds the load record during code generation. Part a (spinel-untyped-bump, #134) removed carat's own untyped reads: at Spinel b582d53e the test runner's rebuilds fell from 731 to 125 and code generation from 103.6 s to 20.0 s. The user asked for the bump to Spinel's newest commit; this second part moves the pin. Spinel's newest commit is now 93d7883b (2026-11-15), past the b582d53e part a measured, so the pin goes to 93d7883b.

## What Changes

- `Makefile`: `SPINEL_REF` moves from 6af548c9 to 93d7883bd8d85ebbce768445c41c03d9a4bc9e92, the full commit, so `make spinel-rev` and CI's toolchain and compile cache keys change with it.
- `tools/spinel/gen_respond_to_tables.rb`: `SYMBOL_FALSE_POSITIVE` gains the nine names Spinel's own generator lists from this range on (`b`, `scrub`, `encode`, `strip`, `lstrip`, `rstrip`, `chomp`, `chop`, `to_str`), so the port's Symbol check passes at the new commit, as Spinel's `tools/gen_respond_to_tables.rb` does.
- `tools/spinel/spinel_rt_responds_generated.h`: regenerated with `make spinel-header` at the new commit.
- `docs/spinel-notes.md`: the regression entry records the new pin and its figures (rebuilds, code generation, `make test-build`, `make diagnose`), and no longer says the pin stays at 6af548c9.

No editor behavior changes: every test and snapshot is expected unchanged, and allocations and analysis rounds equal main's.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. No behavior changes, so `skip_specs` is set.

## Impact

- `Makefile`: the `SPINEL_REF` value only.
- `tools/spinel/`: the generator's Symbol list and the vendored header.
- `docs/spinel-notes.md`: the regression entry.
- CLAUDE.md: unchanged, the Makefile change is a value, no command, target, agent, workflow, or rule changes.
- README.md: unchanged, no command, option, or user-visible behavior changes.
- docs/architecture.md: unchanged, no layer, port, or module changes; the Spinel commit is pinned only in the Makefile.
- docs/codebase-map.md: unchanged, no file added, moved, or removed.

Outside the roadmap of `docs/architecture.md` section 12: toolchain upkeep the user asked for, the second part of the Spinel bump.

## Out of scope

- Making Spinel warnings fatal (`spinel-warnings`, not in the queue yet): this change only reports any warning the new Spinel prints.
- The bundled FileUtils' rebuilds and the rebuilds Spinel asks without a carat `[]`.
- Workarounds for known miscompilations the new commit may fix (`spinel-workarounds` in the queue).
- The queue's order.

Assumptions recorded here instead of asked: "Spinel's newest commit" is the remote's head when this change starts, 93d7883b, since b582d53e is no longer the newest; the nine Symbol false positives are the nine names Spinel's generator added to its own list between 6af548c9 and 93d7883b, the only change to the generator scripts in that range.
