# Design

## Context

`Domain::Themes` (`carat/domain/themes.rb`) holds each palette as rows of a role, its 24-bit color, its 256-color index (-1 for the nearest), and its 16-color index, and one `GROUPS` table naming each group's roles; `from_palette` resolves them into a `Theme`, adding the cursor-line and float layers. `test/domain_theme.rb` measures every group's WCAG ratio per palette and depth with `low_contrast`, which held the cursor-line layer to 3:1 for every group.

## Goals / Non-Goals

Goals: Carat's own dark and light palettes, `carat-dark` the default; 4.5:1 text and 3:1 decorations on the cursor line in every palette at 24 bits and 256 colors; the naming and comment fixes of the four headings.

Non-goals: the cursor line under `background terminal` (`carat-palette-b`), user themes, new roles or groups.

## Decisions

- Two new palettes, `CARAT_DARK` and `CARAT_LIGHT`, use the existing 38 roles, so `GROUPS` and `from_palette` are unchanged: a blue-black background (`0x1b1d26`) or a cool white (`0xfbfbfd`), a sapphire accent in the `BLUE` role, ruby in `RED` and `IDENTIFIER`, amethyst in `PURPLE` and the keyword roles, gold in `YELLOW` and `TYPE`. Their 16-color indexes follow one_dark's and one_light's role for role, so the 16-color checks (the plain groups, the selected tab's other basic color, the selected row's reverse video) hold as they do there. No 256-color index is needed: the nearest color keeps every ratio.
- `NAMES` lists the Carat palettes first and `DEFAULT` is `carat-dark`; `palette(key)` falls back to `CARAT_DARK`. `ALIASES` is removed, since its two names are now palettes; `known?` and `canonical` read `NAMES` alone.
- `low_contrast` holds a group on the cursor line to the same threshold as off it: 4.5:1 for text, 3:1 for decorations. Where an existing palette fell short, the smallest color step that passes was taken, keeping each palette's look: one_dark's purple `0xc678dd` to `0xc97fe0` (its keywords at 4.42:1), dark_plus's cursor line `0x2a2a2a` to `0x262626` and red `0xf55252` to `0xf65c5c` (dim text, comments, and errors at 4.24 to 4.47:1), and one_light's and light_plus's green 256-color index 22 instead of the nearest 28 (4.05:1 on the cursor line).
- The values were chosen with a scratch model of `low_contrast`, `float_low_contrast`, and `SgrTable.index_256` and are proven only by `test/domain_theme.rb`.
- `lit16` becomes `line_bg16`: `lit` is a group id on the cursor-line layer, the other a 16-color background index.

## Risks / Trade-offs

- Every snapshot drawn with the default theme changes its colors; the diff of `make snapshots` is read to confirm only color sequences change.
- A user whose configuration names `carat-dark` or `carat-light` now gets Carat's palettes instead of the One palettes; both are dark or light as before.
