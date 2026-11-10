# Proposal

## Why

`SPINEL_REF` pins Spinel at 001419ff (2026-10-28), and upstream has moved on: its head is now f34005bf. The user asked for the bump in its own pull request, with the vendored `tools/spinel/spinel_rt_responds_generated.h` regenerated without CRuby, `make toolchain` and `make check` passing, no regression in allocations per key, rounds, or analysis time, and each Spinel defect the notes record re-tested. Until now the only documented way to regenerate the header was to run Spinel's generator, a CRuby script, "on a machine that has CRuby", which the hard rules forbid; that path is what this change replaces.

## What Changes

- `SPINEL_REF` moves to f34005bfded9f66dc094ac0aae85efd541cef789, upstream head when the change was made.
- A new `tools/spinel/gen_respond_to_tables.rb`, a Spinel program, is the part of Spinel's `tools/gen_respond_to_tables.rb` and `tools/builtin_row_gen.rb` that reads text: the bop_rows rows, the families that serve them, the hand-kept arrays of `lib/spinel_rt.h`, the same exclusions and coverage checks, and the same output. Compiled with the installed Spinel at the old pin and run on the 001419ff checkout, it wrote the header CRuby wrote byte for byte.
- A new `make spinel-header` target fetches `SPINEL_REF`, compiles that program with the installed `spinel`, and writes the vendored header; the fetch steps are shared with `make toolchain` through one canned recipe.
- The vendored header is regenerated at f34005bf with it: Integer's and Float's arrays gain `singleton_method_added`.
- Each Spinel defect is re-tested at the new pin, and `docs/spinel-notes.md` and its `docs/backlog.md` entry record the result: the four open Known miscompilations and the array destructuring note.
- `CLAUDE.md` (Commands, the toolchain line), `README.md`, `docs/architecture.md` where it describes the header, `docs/codebase-map.md` area 2, and the Makefile comment describe the CRuby-free regeneration.

- carat compiles and passes `make check` at f34005bf through workarounds of three miscompilations new at that pin, each commented and recorded in `docs/spinel-notes.md` with a `docs/backlog.md` entry: `PluginEntry#link` is typed as the API's `Host` and stored through `PluginEntry#attach`; `Mode.visual_kind` compares with `==` instead of a `case` on constants; `Host#icon`, `Host#stat`, and `FilePort#stat` answer a failed or missing value from their base instead of raising.
- The inline RBS warnings carat had at 001419ff are gone: the `MatchData` methods of `Search` and `Replacement` are typed by parameter lines, the `Regexp` member of `SearchPattern` is left to inference, `Testing` drops the block types Spinel does not seed, and `bench/keys.rb` drops the signatures on top-level methods, which Spinel never applied.
- `Mode.name_of` answers `Symbol#name` rather than `to_s`, which allocates a new String at each call since Spinel 59044ad58, so the keymap lookup allocates no more per key than on main.

No editor behavior changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a toolchain change; `skip_specs` is set.

## Impact

- `Makefile`: `SPINEL_REF`, the toolchain comment, the shared checkout recipe, the `spinel-header` target, `.PHONY`.
- `tools/spinel/gen_respond_to_tables.rb`: new. `tools/spinel/spinel_rt_responds_generated.h`: regenerated.
- `docs/spinel-notes.md`, `docs/backlog.md`: the re-test results. The new miscompilations and their workarounds: `carat/use_cases/plugins/plugin_entry.rb`, `plugin_host.rb`, `carat/domain/mode.rb`, `carat/plugin_api.rb`, `carat/ports/file_port.rb`. The warnings: `carat/domain/search.rb`, `replacement.rb`, `search_pattern.rb`, `carat/testing.rb`, `bench/keys.rb`.
- `CLAUDE.md`: changed (Commands names `spinel-header`, the bump instruction). `README.md`: changed (the command list). `docs/architecture.md`: changed where it describes the vendored header, and section 6 names the three port bases that answer a failure value at f34005bf. `docs/codebase-map.md`: area 2.

Outside the roadmap of `docs/architecture.md` section 12: a toolchain bump the user asked for, done in its own pull request as the Makefile requires.

Out of scope: dropping the code workarounds of the defects the new pin fixes, which is the queued `spinel-workarounds` item (the plan split it from this one); reporting the open defects upstream; changing Spinel itself.

Assumptions recorded here instead of asked: "the head" is the upstream head when the change was made (f34005bf), not 9aa36c3 named in the queue when it was checked. A small Spinel port of the generator counts as "regenerated with no CRuby": it runs on the Spinel-built binary only, matches the CRuby output at the old pin byte for byte, and Spinel's generator files are identical at both pins. A defect whose reduced probe does not reproduce at the old pin either (it showed only inside the whole program) is recorded as not re-testable by a probe and stays open, its workaround reverted and tested by `spinel-workarounds`.
