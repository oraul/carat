# Design

## Context

`Themes.from_palette` builds three layers of group ids: the base groups, the cursor-line layer (`id + Highlight::CURSOR_LINE_LAYER`), and the float layer. Without a painted background it clears the BG and FG roles' 24-bit and 16-color values, so a group whose foreground role is FG, or NONE, has the terminal's foreground (-1). The cursor-line layer copies each group's foreground and gives every group without a background of its own the palette's CursorLine color, so under `option.background terminal` Normal on the line is the terminal's foreground over a color the palette chose for its own text. `Themes.find` canonicalizes a name and then asks `palette`, an if chain over the names of `NAMES` that returns `CARAT_DARK` for anything it does not list.

## Goals / Non-Goals

**Goals:**
- Every cell of the cursor-line layer at 24 bits and 256 colors pairs two palette colors under either background, measured by the same contrast table.
- One table names the palettes; a name without its palette fails a test instead of drawing another palette.

**Non-Goals:**
- Groups off the cursor line, and the 16-color cursor line, which keeps its underline and the cell's own colors.

## Decisions

- The lit layer's fallback foreground: when a lit cell's foreground is the terminal's (-1) and its 24-bit background is a palette color, it takes the palette's FG color and FG's 256-color index, saved before the terminal's background clears them. Under `theme` no lit cell has a -1 foreground, so the painted theme is unchanged; under `terminal` the lit layer at 24 bits and 256 colors becomes exactly the painted one's, which the existing cursor-line table already proves at 4.5:1. Alternative considered: leave the lit layer on the terminal's background under `terminal`; that hides the cursor line at the two depths that have no underline, so it was rejected.
- At 16 colors nothing changes: no palette gives CursorLine a 16-color index, so `line_bg16` was always -1 and its branch dead; `bgs16[lit]` is now simply the base cell's. A palette wanting a 16-color stripe would add the branch back with the test that needs it.
- The 256-color BG and FG indexes are cleared with the 24-bit and 16-color ones under `terminal`. Every shipped palette gives -1 there today, so nothing drawn changes, but a palette giving one would otherwise paint the terminal's own colors at 256 colors only.
- `PALETTES = [CARAT_DARK, CARAT_LIGHT, ONE_DARK, ONE_LIGHT, DARK_PLUS, LIGHT_PLUS]` sits beside `NAMES`, in its order; `find` takes the index of the name in `NAMES` (the index of `DEFAULT` for an unknown name) and passes `NAMES[index]` and `PALETTES[index]`. Two parallel arrays rather than one mixed array of names and palettes, because Spinel types an array by its elements and a String beside an Array[Integer] would be untyped. The test asserts the lengths agree and no two names share a palette, so a name added without a palette fails.
- The test file drops its own `PALETTES` and iterates `D::Themes::NAMES`; the five contrast tables become loops of `assert_equal([], ...)` with labels built from the name and the depth, as the file's other palette loops already are. `low_contrast` reports a cell with one color set and the other the terminal's as "NAME unpaired", which makes the old terminal cursor line fail.

## Risks / Trade-offs

- [The test labels change, so the snapshot changes] → `make snapshots` and a read of the diff: the same checks, plus the terminal rows.
- [A palette added later with a light text color on a light terminal] → out of scope: off the cursor line the terminal background was always assumed to suit the palette, as the README's "for a dark terminal" says.
