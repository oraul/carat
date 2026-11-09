## ADDED Requirements

### Requirement: Markup groups for documentation
The group table SHALL hold six markup groups after the file-icon groups, named as Neovim's tree-sitter captures, which every shipped palette SHALL color and each SHALL show at 16 colors by a basic color or an attribute. A plugin token MAY carry a markup group.

#### Scenario: The markup groups by name
- **WHEN** the group names after the file-icon groups are listed
- **THEN** they are `@markup.heading`, `@markup.strong`, `@markup.italic`, `@markup.raw`, `@markup.link.label`, and `@markup.raw.block`, and a plugin token may name each

#### Scenario: The markup groups' looks
- **WHEN** `one_dark` is drawn
- **THEN** `@markup.heading` is blue and bold, `@markup.strong` the text color and bold, `@markup.italic` the text color and italic, `@markup.raw` the string color, `@markup.link.label` cyan and underlined, and `@markup.raw.block` dim gray

### Requirement: Groups in a float stay readable over its background
A syntax or markup group drawn inside a float SHALL keep its foreground and attributes and take NormalFloat's background unless it has a background of its own. In every shipped palette, drawn with the theme's background, every syntax and markup group that carries text SHALL have a contrast of at least 4.5:1 over that background, at 24-bit colors and at the 256 colors written for them.

#### Scenario: Every palette passes in a float
- **WHEN** the contrast of every syntax and markup group of `one_dark`, `one_light`, `dark_plus`, and `light_plus` is measured over the float background
- **THEN** none is below 4.5:1
