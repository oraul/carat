# Proposal

## Why

With `cursorline` on and the shipped `option.background terminal`, a cell on the cursor line whose group has no foreground of its own, Normal text first, keeps the terminal's own foreground over the palette's fixed CursorLine stripe: on a light terminal with the default `carat-dark` that is dark text on a dark stripe, and the contrast table checks only `background theme`, so nothing catches it. Around it, `Themes.palette` repeats `NAMES` as an if chain whose last line silently returns `carat-dark` for any name it misses, `line_bg16` is a branch no palette reaches, `from_palette` keeps the 256-color indexes of the BG and FG roles when the terminal paints them, the theme test lists the palettes a second time in five hand-written contrast tables, the Alias scenario calls `carat-light` an alias it no longer is, and a comment runs past the comment width.

## What Changes

- On the cursor line, a cell whose foreground would be the terminal's own while its background is a palette color (the CursorLine stripe or a background of its own) takes the palette's text color at 24 bits and at 256 colors, so with `option.background terminal` every cell on the line pairs two colors the palette chose; at 16 colors the line keeps the underline and the colors the cell has off the line, as before.
- With the terminal's background, `from_palette` clears the 256-color indexes of the BG and FG roles as it already clears their 24-bit and 16-color ones.
- `Themes` gains `PALETTES`, the palettes in the order of `NAMES`, and `find` looks a name up in that one table; the if chain, `palette`, `canonical`, and the dead `line_bg16` go. An unknown name still gives `carat-dark`, as `find`'s contract and its test say.
- `test/domain_theme.rb` iterates `Themes::NAMES` for every palette loop and contrast table instead of its own `PALETTES` list, checks the cursor line on both backgrounds at both depths (a cell with one color the palette chose and one the terminal's fails), and fails when `NAMES` and `PALETTES` differ in length or two names share a palette.
- The Alias scenario is reworded: it no longer calls `carat-light` a name that was once an alias of `one_light`, and says `carat-light` is no alias, its colors differing from `one_light`'s.
- `themes.rb` gets the missing blank line and a comment for `background?`, and its reflowed comment is wrapped within the comment width.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `color-themes`: the cursor-line contrast requirement covers both backgrounds and says what a cell with the terminal's foreground takes on the line; the theme option's Alias scenario no longer says `carat-light` was an alias.

## Impact

- `carat/domain/themes.rb` (`PALETTES`, `find`, `from_palette`, comments).
- `test/domain_theme.rb` and its snapshot.
- README.md: unchanged, it already says every text color is readable on the cursor line at WCAG AA contrast and names the palettes as before; this change makes that hold on the terminal's background too.
- docs/architecture.md: unchanged, section 4.2 describes `Themes` as palettes per role and one group table building the theme for the background choice, which stays true; the cursor-line layer in section 6 is still drawn over CursorLine's background.
- CLAUDE.md: unchanged, no command, agent, workflow, or rule changes.
- `docs/queue.md`: the package step applies the planner's queue with the user's four instructions.

Roadmap: outside the numbered roadmap, a user now-request carried from sprint 6 that fixes the color-themes capability of section 12's syntax-highlighting item.

## Out of scope

- Visual, ColorColumn, and other groups with a background of their own but no foreground, off the cursor line under `option.background terminal`: they keep the terminal's foreground over the palette's background as today; only the cursor line changes here.
- New palettes, user themes, and any palette color change.
- Reading or editing `docs/backlog.md` beyond the package step's appends.

Assumptions recorded here instead of asked: the Alias scenario keeps its name, since OpenSpec's archive refuses a MODIFIED requirement that drops a scenario by name, and its text now says the opposite of an alias. Also: "lit cells take the palette's foreground over the terminal's background" is read as: with `option.background terminal` (the terminal's background option), lit cells take the palette's text color over the stripe; keeping the stripe off the line under `terminal` would hide the cursor line at 24 bits and 256 colors. "No silent fallback" is read as the palette lookup's: a name missing from the table can no longer reach another palette, and `find`'s documented carat-dark for an unknown name, which `Options` reports at the configuration line, stays.
