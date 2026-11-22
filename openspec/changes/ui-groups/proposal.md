# Proposal

## Why

`docs/design.md` (section 3's PANEL_DIM row, section 8's Status bar note) describes a status bar whose file name and position lead and whose branch, server, file type, and encoding step back in the quiet PANEL_DIM text, with groups three cells apart. Today every segment is drawn in `StatusLine` (bold, `PANEL_FG`) and neighbouring segments are two cells apart, and no PANEL_DIM role or group exists in the code. The message row's visual mode indicators are drawn in `Normal`, so they are as loud as the text above them. The change is the design council's decision 4 (after float-painter, before window-surfaces) from the feature queue, the user's request.

## What Changes

- Add the `PANEL_DIM` color role to every palette, the design's `#a4aabd` (carat-dark) and `#5c6173` (carat-light) and a value of at least 4.5:1 on the bar's `PANEL` background in the other four palettes, with the bar's own text color as its basic color at 16 colors.
- Add the `StatusLineDim` highlight group, the last UI group after `Folded`, moving the syntax, file-icon, and markup ids up by one: `PANEL_DIM` on `PANEL`, no attributes, so at 16 colors it differs from the bold `StatusLine` by its weight.
- Draw the branch, the file type, the encoding, and the `lsp` slot while it shows no state (stopped, untrusted) in `StatusLineDim`; the file, the position, the percent, the plugins' segments, and the progress label stay in `StatusLine`; the pill keeps its mode's group, the one sapphire fill.
- Put one more cell before each segment that starts an independent group (every one but the file and the percent), so the pill and the file and the position and the percent are two cells apart and the other groups three, with no separator glyph.
- Draw the three visual mode indicators of the message row (`-- VISUAL --`, `-- VISUAL LINE --`, `-- VISUAL BLOCK --`) in `MsgDim` instead of `Normal`.

Out of scope, recorded in the findings file: the design's "folder" segment and "server state is one dot" (the bar has no folder segment, and the `lsp` slot keeps its text label), the progress bar's undone cells and the percent in the quiet text, `MESSAGE_MODE` and `MESSAGE_MORE` (no code draws them), and the other sapphire fills of `docs/design.md` section 5 (the selected tab, owned by `one-accent`).

Assumptions: the "groups" of the design are the bar's segments, the pill and the file and the position and the percent being label and detail; the design's two cells between a pill and the next group and its three between independent groups are counted between the texts; the `lsp` slot keeps its state colors (starting, ready, crashed) and is quiet only without a state; the diagnostics counts are one group, so they stay one cell apart inside it; `StatusLineDim` is a UI group, so a plugin token or a float span cannot carry it; the 256-color index of `PANEL_DIM` is the nearest one, which the contrast test measures; NO_COLOR keeps the groups, as the message row and the progress bar do, and the terminal side chooses the colors, so no driver changes.

## Capabilities

### New Capabilities

### Modified Capabilities
- `status-bar`: the segments' spacing, the quiet group of the branch, file type, encoding, and a stateless server.
- `color-themes`: the `PANEL_DIM` role and the `StatusLineDim` group in every palette.
- `screen-rendering`: the visual mode indicators of the message row are dim.

## Impact

- Code: `carat/adapters/status_bar.rb`, `carat/adapters/frame_presenter.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`.
- Tests: `test/adapters_status_bar.rb`, `test/adapters_frame_presenter.rb`, `test/domain_theme.rb` and their snapshots, the width and spacing expectations of the status bar text in other tests.
- Docs: `docs/compatibility.md` (the segment table, the UI group count), `docs/codebase-map.md` (areas 13 and 14), `docs/architecture.md` (the `Highlight` count), README.md (the status bar sentence).
- docs/design.md: unchanged, it already describes the target look (section 3's PANEL_DIM row, section 8's Status bar note) and its Known drift table names no row this change closes; the two parts of the note not drawn (a folder segment, the server as one dot) are recorded in the findings file.
