# Proposal

## Why

A theme change needs a restart: the palette is read once when the editor starts, `:set theme=` and `:set background=` answer `Not implemented`, and there is no `:colorscheme`. The design council of 2026-11-21 (decision 2, the basics) asked for `:colorscheme`; this is part 3 of the set-options brief, split by the planner after `:set` (#287) and `hidden` (#288) merged, which left `theme` and `background` the last options `:set` does not take. Roadmap: item 9, `options-and-config` (`docs/architecture.md` section 12), whose "left" list names `theme` and `background`.

## What Changes

- `:colo[rscheme] name` sets the palette to a shipped one at once: the next frame is drawn in full, every highlight group in the new palette's colors at the terminal's depth (24-bit, 256, or 16 colors), as at startup; another name answers `E185: Cannot find color scheme 'name'` and keeps the palette; `:colorscheme` alone shows the current palette's name.
- `<Tab>` after `:colorscheme ` completes the shipped palette names, in their shipped order, as path completion does after a file command.
- `:set theme=name` and `:set background=word` (`bg`) are word options like `winborder`: `?` and the bare name show the value, `&` resets it to the shipped one, a value the `option.theme` or `option.background` line would refuse is `E474`, and a change repaints every group at once as `:colorscheme` does.
- The screen presenter rebuilds its color table when the options name another palette or background than the one it was built with, and forgets its last frame so the next is drawn in full.
- Docs: the `:colo[rscheme]` row and the `:set` word row of `docs/compatibility.md`, its syntax and Themes paragraphs and `:set` Differences, the README's options and colors sections, `docs/architecture.md` (the roadmap item 9 line and the `ScreenPresenter` and `SgrTable` lines), and `docs/codebase-map.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `color-themes`: ADDED requirement "The colorscheme command switches the palette at once".
- `set-command`: MODIFIED "Word options are set with set" (`theme` and `background` join the words, a change repainting at once).
- `syntax-highlighting`: MODIFIED "The filetype and syntax are set with set" (theme and background no longer answer `Not implemented`; the scenario "An option set does not handle yet" goes).
- `command-line-mode`: ADDED requirement "Tab completes a color scheme name".

## Out of scope

- User themes, `:highlight`, Neovim's `ColorScheme` event, and `g:colors_name`.
- Neovim's `background` meaning (`dark` or `light`): Carat's `background` keeps its own words, `theme` and `terminal`.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: a bang on `:colorscheme` is ignored, as `:syntax` ignores it; Neovim refuses it with `E477`, recorded as a difference.
- Assumption: `:colorscheme` of the current palette succeeds silently, as Neovim's does, and repaints nothing.
- Assumption: Tab completes the names after `:colorscheme` only, not after `:set theme=`.

## Impact

- README.md: the options section stops listing `theme` and `background` among the options `:set` leaves out, and the colors section names `:colorscheme`.
- docs/architecture.md: the roadmap item 9 "left" list drops `theme` and `background`; the `ScreenPresenter` and `SgrTable` lines say the table is built again when the palette changes.
- docs/codebase-map.md: the new handler file and test file, the changed lines of the set handler, the completion use case, and the screen presenter, and area 14's Rules line.
- CLAUDE.md: unchanged, no process change.
- Performance: `render` compares two short strings per frame; no allocation on a frame whose palette is unchanged.
