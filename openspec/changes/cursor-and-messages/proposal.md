# Proposal

## Why

The Facet plan styles the cursor line, the line numbers, and the cursor shapes as one surface. Today the cursor line is lifted only from the end of the gutter, so the sign column, the number, and the gap sit outside it; every number is DIM; and the command line, where the user types, shows a block cursor where a bar belongs. This change delivers parts 1 to 3 of the queue line; parts 4 and 5 (the command line and message styling) are split off as `message-styling` by the size rule.

## What Changes

- Lift the cursor line from window column 0 to the window's right edge, the gutter included, in the focused window only; the selection keeps its own background.
- Draw line numbers in a new group `LineNrFifth` (DIM) on every fifth relative number and in `LineNr` (now FAINT in every palette) otherwise; the cursor row's number stays `CursorLineNr`, bold on the cursor line.
- Show a steady bar cursor on the command line, which every query prompt shares; block, bar, and underline stay for normal-like, insert, and replace modes.
- Hold `LineNr` to 3:1 contrast as a decoration, since FAINT sits below the 4.5:1 text floor.

Assumptions: the cursor shapes were already steady, so only the command line changes; NO_COLOR keeps the bold of the cursor row's number, which the attribute columns of the group rows carry.

Out of scope: the command line's own text colors, pending keys, the match count, the message styling, the `-- More --` and `Question` painting, and the removal of the mode indicator (the `message-styling` change).

## Capabilities

### New Capabilities

### Modified Capabilities
- `screen-rendering`: the cursor line covers the gutter, the numbers' groups, and the command line's bar cursor.

## Impact

- Code: `carat/adapters/frame_presenter.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`.
- Tests: `test/adapters_frame_presenter.rb`, `test/adapters_screen_presenter.rb`, `test/domain_theme.rb`, `test/editor_syntax.rb`, and their snapshots.
- Docs: `docs/compatibility.md`, `docs/architecture.md` section 8, `docs/codebase-map.md` area 13.
- README.md: unchanged, it does not describe the cursor line or the cursor shapes.
- docs/architecture.md: changed, the group count and the Highlight paragraph name `LineNrFifth`.
