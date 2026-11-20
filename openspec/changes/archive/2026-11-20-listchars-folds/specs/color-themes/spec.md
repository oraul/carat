# Spec Delta

## MODIFIED Requirements

### Requirement: Text groups meet WCAG AA contrast
In every shipped palette, drawn with the theme's background, every group that carries text SHALL have a contrast ratio of at least 4.5:1, and every decoration group (`NonText`, `EndOfBuffer`, `WinSeparator`, `FloatBorder`, `Whitespace`, `SignColumn`, the file-icon groups) at least 3:1, at 24-bit colors and the 256 written. `TabLineFill`, `PmenuSbar`, and `PmenuThumb` are exempt; the guides, Carat's `Whitespace`, and float borders have their own rules.

#### Scenario: Every palette passes
- **WHEN** the contrast of every group of `carat-dark`, `carat-light`, `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured
- **THEN** no text group is below 4.5:1 and no decoration group below 3:1

#### Scenario: Comments are readable
- **WHEN** the contrast of `carat-dark`'s Comment is measured
- **THEN** it is at least 4.5:1

## ADDED Requirements

### Requirement: Whitespace marks take the guides' color
Every palette SHALL color `Whitespace` with the color role of `IblIndent`, so the marks of `option.list` are as quiet as the indent guides: #30364b in `carat-dark`, #d8dce8 in `carat-light`, and basic color 8 at 16 colors in every palette. In `carat-dark` and `carat-light` it SHALL recede with `IblIndent` below `Comment`, and in the other palettes keep the decorations' 3:1.

#### Scenario: The whitespace marks take the guide color
- **WHEN** each shipped palette is drawn
- **THEN** `Whitespace` has `IblIndent`'s color at 24 bits and at 16 colors, #30364b on `carat-dark` and #d8dce8 on `carat-light`, basic color 8 at 16 colors

#### Scenario: The other palettes' whitespace marks keep 3:1
- **WHEN** the contrast of `Whitespace` of `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured on the background and on the cursor line, at 24-bit colors and at 256 colors
- **THEN** it is not below 3:1
