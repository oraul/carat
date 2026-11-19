### light_plus LineNrFifth is the teal accent
- Location: carat/domain/themes.rb:482 (LIGHT_PLUS DIM 0x1f6b82, FAINT gray)
- Why: LineNrFifth maps to DIM, so in light_plus every fifth number is an accent color rather than a dim gray step.
- Fix: map LineNrFifth to a gray in light_plus or record the choice in the design.
### LineNrFifth has no 16-color attribute of its own
- Location: carat/domain/themes.rb:164
- Why: LineNrFifth (DIM) and LineNr (FAINT) share basic index 8 with no attribute at 16 colors and under NO_COLOR; documented in docs/compatibility.md as needing 256 colors.
- Fix: give LineNrFifth a basic color or attribute of its own in every palette.
