# Proposal

## Why

Sprint 23 item 1 of the backlog lane gathers syntax-highlighting debts. Its fix outline says to split the change at its start and take the bugs first. This first part fixes the ones a test can show broken today. Ruby percent literals and interpolations nested deeper than the line state encodes close too early on the same line, so the rest of the line is drawn wrong. `Filetype.program_type` counts characters but reads bytes, so a version after a multi-byte program name is not cut off. The byte basename is cut in three places, one of them by characters, and `Buffer#name_start` disagrees with `PluginApi::Paths.basename` on the root. The change is outside the closed roadmap of `docs/architecture.md` section 12. It tidies the delivered syntax-highlighting item (area 14) and the Ruby plugin.

## What Changes

- The Ruby tokenizer counts the nesting depth of a paired delimiter, and the brace depth in an interpolation, in full within a line. The depth is held to the field's largest value (7 pairs, 3 braces) only when the line's state is packed, in `Tokenizer#frame_bits`. The `LineState` header says so.
- `Filetype.program_name` cuts the version digits and dots off a program name by bytes. `program_type` looks that name up, so it no longer mixes `length` with `getbyte`.
- `Filetype.from_name` and `from_shebang` use `PluginApi::Paths.basename`, and `Filetype.base` is removed. `Buffer#name_start` is the path's byte size less its basename's. The three copies become one helper, and the root `/` now starts its name at byte 0, as `Paths.basename` keeps `/` whole.
- `docs/codebase-map.md` area 14 names `program_type` and `program_name`, and notes that the state packing clamps the depth.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ruby-syntax`: MODIFIED requirements "Interpolation is code inside the string" and "Percent literals take any delimiter", each gaining a scenario for nesting deeper than the state holds. ADDED requirement "A nesting deeper than the state holds is clamped at the end of the line".

## Out of scope

- Split off and recorded in `docs/findings/syntax-tidy.md`:
  - "G on a large file tokenizes every row above the end once". Any fix trades exact colors for speed (a sync point above the window, or tokenizing spread over idle frames). That changes the specified behavior "Only visible rows and the rows above them are tokenized" and the test that the last row keeps the state carried from the top, so the choice is the user's.
  - "The cursor line doubles the highlight group-id space". No behavior is broken: every frame id stays below `Highlight::LIMIT`, and a float cell is never lifted onto the cursor line. Shrinking the id space means redesigning how `Frame`, `Themes.from_palette`, and `SgrTable` carry the layers, which is a design change and not a bug fix.
- The other five headings of the queue line, which the plan queued separately: the security marks of `tools/run_state.sh`, `:set`'s options and its boolean switches, themes at runtime, and semantic highlighting.
- No `tools/rules.sh` edit, no plugin API change (no version bump), and no file of the feature lane.
- Assumption: since `PROGRAMS` holds only ASCII `ruby`, the mixed indexes never changed a detected filetype. The fix is proved through the new `program_name`, which `program_type` uses.

## Impact

- README.md: unchanged, its highlighting paragraph names percent literals and nested interpolation without a depth, and that still holds.
- docs/architecture.md: unchanged, its `Filetype` entry describes detection, which keeps its behavior, and no section names the Ruby state's depth field.
- docs/codebase-map.md: area 14 (the `Filetype` and `LineState` entries).
- docs/compatibility.md, docs/actions.md: unchanged, since no command or action changes.
- Performance: the tokenizer drops two comparisons per bracket and adds two per packed frame. `Buffer#name_start` builds the basename string on each call (in the tab bar, once per tab per frame), as `icon_of` already does when a buffer is renamed.
