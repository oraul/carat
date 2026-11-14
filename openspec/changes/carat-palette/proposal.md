# Proposal

## Why

Carat ships only other editors' palettes (`one_dark`, the default, `one_light`, `dark_plus`, `light_plus`, `carat/domain/themes.rb:25`), with `carat-dark` and `carat-light` mere aliases of the One palettes. Text drawn on the cursor line is held to 3:1 only, and in every palette some of it falls below 4.5:1 there (one_dark's keywords at 4.42:1, dark_plus's errors, comments, and dim text at 4.24 to 4.43:1, the light palettes' green at 4.05:1 at 256 colors). The theme build names a 16-color background index `lit16`, like the group id `lit` beside it; `docs/compatibility.md` still says the editor knows 41 UI groups where it knows 56; and the group comment of `test/domain_theme.rb` omits the markup groups. This is part a of the split of `carat-palette` (sprint 4 item 1 of `docs/queue.md`), a user now-request; it refines the themes of roadmap item 8 (`syntax-highlighting`, `docs/architecture.md` section 12) and delivers no new roadmap item.

It covers these backlog headings:

- "## Text on the cursor line falls below 4.5:1 in every palette"
- "## A 16-color background index is named like a group id in the theme build"
- "## The UI highlight group count is stale"
- "## The theme test's group comment is out of date"

## What Changes

- Add Carat's own palettes `carat-dark` and `carat-light`, with a sapphire accent, as full palettes rather than aliases; `carat-dark` becomes the default, in `Themes::DEFAULT` and in the shipped `option.theme` line, and an unknown theme name falls back to it.
- Hold every text group on the cursor line to 4.5:1 and every decoration group to 3:1, at 24 bits and at the 256 colors written, in all six palettes, drawn with the theme's background; adjust the four existing palettes where they fall short (one_dark's purple a step lighter, dark_plus's cursor line a step darker and its red a step lighter, the light palettes' green given its own 256-color index).
- Rename the theme build's `lit16` to `line_bg16`, so a 16-color index is not named like a group id.
- Correct the UI group count in `docs/compatibility.md` and the group comment of `test/domain_theme.rb`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `color-themes`: the shipped palettes and the default, the six palettes in each contrast requirement, and 4.5:1 text on the cursor line.

## Impact

- Code: `carat/domain/themes.rb`, `config/default.caratrc` and its generated mirror `carat/domain/default_config.rb`.
- Tests: `test/domain_theme.rb` (the palette list, the contrast tables, the default), `test/domain_options_config.rb` (the shipped defaults), and the snapshots of tests drawn with the default theme.
- Docs: `docs/compatibility.md` (Themes), `docs/codebase-map.md` (the themes line).
- README.md: changed, the theme paragraph and the configuration example name `carat-dark` as the default.
- docs/architecture.md: changed, the `Themes` entry and the configuration example name the six palettes and the default.

Assumptions:

- "A gem accent" is the accent role (`BLUE`) of the two Carat palettes, a sapphire blue, which colors the selected tab, the normal mode pill, titles, and functions; ruby, amethyst, and gold color the other syntax roles. No role or group is added.
- With `carat-dark` and `carat-light` now palettes, the alias table is removed: the two names keep working, now naming Carat's palettes, and no other alias existed.
- The cursor-line contrast is measured with the theme's background, as every other contrast table is; the cursor line under `background terminal` is `carat-palette-b`.

Out of scope: the cursor line under `option.background terminal` ("## The default cursor line keeps the terminal's foreground over a dark stripe"), queued as `carat-palette-b`; user themes; new highlight groups.
