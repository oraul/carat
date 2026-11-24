# Backlog: carat/domain/themes.rb

## Themes are chosen only at startup and cannot be tuned

- Where: `Carat::Domain::Themes` in `carat/domain/themes.rb` holds the four palettes since `theme-tokens`, chosen once at startup by the `option.theme` and `option.background` lines; there is no `:colorscheme`, no `:highlight`, no `:set background`, and no theme lines in the configuration.
- Why it matters: users expect to switch or tune a color scheme without restarting or rebuilding; the user and project configuration files can only name a shipped palette.
- Fix outline: read `theme.<name>.<group>` lines from the configuration files (foreground, background, 256-color and 16-color values, and attributes as words, applied over a shipped palette), add `:colorscheme name` and `:set background=` that rebuild the screen presenter's SGR table and redraw, and `:highlight Group guifg=... ctermfg=...` for single groups.
- Category: editor
- Added: 2026-11-05

### Themes.find hand-rolls a linear search
- Location: carat/domain/themes.rb:470
- Why: find hand-rolls a linear search and recomputes DEFAULT's index on every call, where Array#index already serves this under carat/ (plugin_ui.rb:84); quality advisory (simplicity) from carat-palette-b.
- Fix: index = NAMES.index(name), falling back to NAMES.index(DEFAULT) when nil, and drop the while loop.
- Category: editor
- Added: 2026-11-15

### facet-palette dropped the brief's PANEL_DIM
- Location: `carat/domain/themes.rb` (no PANEL_DIM role, no #a4aabd, at caf4532ac051; DIM 0x5c6173 at line 269)
- Why: facet-palette's brief pinned PANEL_DIM #a4aabd / #5c6173 and its acceptance asked theme rows pinning each value; round 2 removed it on a re-raised advisory (retro 11), so the merged palette misses a value the user's Facet plan named.
- Fix: restore the PANEL_DIM role on carat-dark and carat-light with the pinned values; accepted when theme rows pin both. Queued with `ui-groups`.
- Category: editor
- Added: 2026-11-18

### light_plus LineNrFifth is the teal accent
- Location: carat/domain/themes.rb:482 (LIGHT_PLUS DIM 0x1f6b82, FAINT gray)
- Why: LineNrFifth maps to DIM, so in light_plus every fifth number is an accent color rather than a dim gray step.
- Fix: map LineNrFifth to a gray in light_plus or record the choice in the design.
- Category: editor
- Added: 2026-11-19

### LineNrFifth has no 16-color or NO_COLOR distinction
- Location: carat/domain/themes.rb (the LineNrFifth row)
- Why: under 16 colors and NO_COLOR every fifth relative number looks like the others.
- Fix: give it a bold attribute or a basic-index accent there.
- Category: editor
- Added: 2026-11-19

### At 16 colors StatusLine and StatusLineDim differ only by bold
- Location: `carat/domain/themes.rb` (the `STATUS` and `STATUS_DIM` rows), `carat/adapters/sgr_table.rb`
- Why: the bytes at `TERM=xterm-color` are `\e[0;1;30;47m` and `\e[0;30;47m`, the same foreground and background; a terminal that draws bold as bright, as xterm does by default, shows the file name in a lighter color than the quiet text, the reverse of the design's order
- Fix: give `STATUS_DIM` a 16-color foreground of its own (bright black on the bar's background, as `TabLine` has) and add a sequence row for it in `test/adapters_screen_presenter.rb`
- Also: carat/adapters/sgr_table.rb, test/adapters_screen_presenter.rb
- Category: editor
- Added: 2026-11-24
