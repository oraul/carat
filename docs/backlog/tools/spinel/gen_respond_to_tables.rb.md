# Backlog: tools/spinel/gen_respond_to_tables.rb

## gen_respond_to_tables.rb repeats work and types its rows loosely

- Where: `tools/spinel/gen_respond_to_tables.rb:95` (three `if`s map array names to arrays inside the family loop), line 101 (a second `uniq` after `family_names` already dedups), and lines 111, 138, and 156 (rows typed `Array[untyped]` where `Array[Row]` holds). Quality advisory at spinel-bump.
- Why it matters: the port is read at every Spinel bump; the repeated lookups and loose types make it harder to compare with upstream and hide a wrong row from the analysis.
- Fix outline: build one name-to-array hash before the loop, drop the second `uniq`, and type the rows `Array[Row]`.
- Category: pipeline
- Added: 2026-11-10

### gen_respond_to_tables types Row arrays as untyped

- Location: tools/spinel/gen_respond_to_tables.rb:114, :141, :159 (sweep, quality).
- Why: Array[untyped] where every element is a Row.
- Fix outline: Array[Row].
- Category: pipeline
- Added: 2026-11-17

### Nothing checks the vendored Spinel header against its generator

- Location: tools/spinel/gen_respond_to_tables.rb, docs/codebase-map.md:78 (sweep, quality).
- Why: a drift shows only at the next SPINEL_REF bump.
- Fix outline: a tools-test case or a CI step on a SPINEL_REF change running make spinel-header and diffing the header.
- Also: docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-17
