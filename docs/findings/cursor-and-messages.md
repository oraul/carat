### light_plus LineNrFifth is the teal accent
- Location: carat/domain/themes.rb:482 (LIGHT_PLUS DIM 0x1f6b82, FAINT gray)
- Why: LineNrFifth maps to DIM, so in light_plus every fifth number is an accent color rather than a dim gray step.
- Fix: map LineNrFifth to a gray in light_plus or record the choice in the design.