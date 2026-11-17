# Proposal

## Why

Sprint 13, item 1 of `docs/queue-feature.md`: below about 14 cells of float text a palette row shows only its key, because the label's column is `width - KEY_WIDTH` once the name is left out (`carat/use_cases/discovery/follow_palette.rb:166`), so at the narrowest float the 12-cell key takes every cell and the readable label, the one part of a row that says what the entry does, vanishes. Three small findings sit in the same file and map entry: `styles` takes a `cut` it never reads (`:187`, called at `:144`), `pad` appends its padding one space per loop pass (`:296`), and `docs/codebase-map.md:169` says the columns are fit by `DisplayWidth.fit`, which the file never calls.

## What Changes

- When the label would get under 12 cells beside the key's 12-cell column (a float text under 24 cells), the key is left out as the name already is under 62 cells, and the label takes the whole row, so a row at the smallest screen the palette opens on still shows its label.
- `FollowPalette#styles` drops its unused `cut` parameter.
- `FollowPalette#pad` pads a cell in one step.
- The `follow_palette.rb` entry of `docs/codebase-map.md` names what the file calls (`DisplayWidth.cut`, `bytes_within`, `text_width`) and the key left out at the narrowest width.

Out of scope: the column widths at 24 cells and up (unchanged), the name's own threshold, a key column that shrinks rather than drops, the palette's order and filtering.

Roadmap: outside the roadmap of `docs/architecture.md` section 12: fixes of findings of the delivered palette, queued for Sprint 13.

Assumptions: the smallest screen the palette opens on is 8 columns (`show` returns below), a float text of 2 cells under an edged border and 4 under `option.winborder none`; the threshold of 12 label cells equals the key's column, so the label never gets fewer cells than the key; leaving the key out mirrors the name's rule rather than shrinking it, since a key cut to a few cells reads as nothing; a label of 2 cells shows one character and its padding space, the same cut rule as every column; the recorded allocation figures hold, since `pad` builds no more strings and only narrow floats change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `command-palette`: a palette too narrow to keep 12 label cells beside the key leaves the key out, so a row shows its label at every width.

## Impact

`carat/use_cases/discovery/follow_palette.rb` (`rows`, `styles`, `label_room`, a `keyed?` predicate, `pad`, the class comment); `test/editor_palette.rb` and its snapshot; `docs/codebase-map.md` (the `follow_palette.rb` entry); README.md. No dependency, no API change, no new file.

- README.md: changed, the palette row leaves the key out on the narrowest screen.
- docs/architecture.md: unchanged, it names `FollowPalette` without its row layout, which the spec holds.
