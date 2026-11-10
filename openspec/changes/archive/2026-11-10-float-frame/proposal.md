# Proposal

## Why

The user's now-request is a pleasant UI and UX, in carat's Facet design language (`docs/goals.md` goal 1, queue item A). Today every float draws its text against the border with no padding, the title is pushed against the top-left corner in `Title` on the editor's background (so its cells break the float's background), the border is always rounded with no ASCII form outside the notices, and a user who prefers Neovim's other borders has no option. This change gives floats a frame: padding, a centered title in its own group, and Neovim's `winborder`. It is outside the numbered roadmap of `docs/architecture.md` section 12; it is the first of the user's UI items, the planner's split of item A.

## What Changes

- Every float has one column of padding inside each side of its edge, painted in the float's group; a menu's selected row (`PmenuSel`) spans its padding. The completion popup and its documentation stay borderless, with padding only, as Neovim's popup menu; the popup moves one column left so its text stays under the typed word.
- A new `option.winborder` takes Neovim's `none`, `single`, `double`, `rounded`, or `solid`, `rounded` by default; an unknown word is reported as `file:line: unknown border style WORD` and the value before it stays. `none` draws bordered floats with no edge and no title; `solid` draws the edge as blank cells.
- Under `option.icons ascii`, and under `NO_COLOR`, every style with lines draws `+`, `-`, and `|`.
- The title is centered on the top edge between the corners, with one blank cell on each side, in a new UI group `FloatTitle` (Neovim's name), colored as `Title` over the float's background; it is cut when the edge is too short.
- The notifications' boxes are drawn by the same border painter with the same glyphs (`none` leaving their edge blank, since their geometry needs it); the duplicated painter and the double fill of a float row go (backlog entries of `bars-tidy` folded here).
- The finder, the palette, and the key hints size their floats for the padding, so the finder's list and preview still tile the screen and the palette stays centered.
- A palette-filtering bench scenario joins `lh-float` and `finder` as the measure of a float's paint.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `floating-windows`: floats get padding, a centered title in `FloatTitle`, and the border style of `option.winborder` with its ASCII form.
- `color-themes`: the UI groups gain `FloatTitle`, 52 in all.

## Impact

- Code: `carat/domain/float_window.rb` (the edge and padding of the box), a new `carat/domain/border_style.rb`, `carat/domain/options.rb`, `carat/domain/highlight.rb` and `carat/domain/themes.rb` (`FloatTitle`), `carat/adapters/frame_presenter.rb` (one border painter, padding, centered title), `carat/use_cases/arrange_view.rb`, the completion, palette, and key hints use cases, and `carat/plugins/finder/plugin.rb`.
- Configuration: `config/default.caratrc` gains `option.winborder rounded`, mirrored by `make gen-config`.
- Plugin API: no request or member changes and the version stays 2.5: `FloatOptions` keeps its members, its sizes stay the text's, and the host draws the padding inside the box as it draws the border; the comment of `FloatOptions` says so. A plugin that tiles floats must leave two more columns per float, which the in-tree finder does. The decision on new members (margin, centering, a border per float) is `float-placement`'s, the next item, where the brief places it.
- README.md: changed, the `option.winborder` option is listed with the options.
- docs/architecture.md: unchanged, it names no border, padding, or float group; the float painting it describes stays in the same layers.
- Tests: snapshots of every float (editor_floats, completion, palette, key hints, finder, hover, signature, definitions, explorer where it opens floats) move by the padding and the centered title; new rows for each style, the ASCII form, padding, and the option.

## Out of scope

- A margin from the screen edges and the bars, centering at show time and on resize, and any `FloatOptions` member or host request: `float-placement`.
- The focus gem `◆` in titles, counts on the right of the top edge, key hints on the bottom edge, and menu rows in columns: `menu-hints` and later items.
- The palette of colors (`carat-palette`) and the tab line and winbar (`top-rows`).
- Any key behavior; prompts stay on the command line.
