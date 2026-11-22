## ADDED Requirements

### Requirement: StatusLineDim reads on the bar in every palette
Every palette SHALL give `StatusLineDim`, the last UI group, the `PANEL_DIM` role as its foreground on the `PANEL` background of `StatusLine`, no attributes, and `PANEL_DIM` SHALL reach 4.5:1 on that background at 24 bits, at 256 colors, and at 16 colors under xterm's default colors, where `StatusLineDim` is the weight beside the bold `StatusLine`. `carat-dark`'s `PANEL_DIM` SHALL be `#a4aabd` and `carat-light`'s `#5c6173`.

#### Scenario: StatusLineDim is the bar's quiet text in every palette
- **WHEN** `StatusLineDim` is looked up in each shipped palette on either background choice
- **THEN** its foreground is the palette's `PANEL_DIM`, its background the bar's, it is not bold, its contrast on the bar is at least 4.5:1 at every depth, `StatusLine` is bold at 16 colors where it is not, and its name is `StatusLineDim`
