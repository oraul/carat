## MODIFIED Requirements

### Requirement: The icons option selects the icon set
The option "icons" SHALL take the values "unicode", "nerd", and "ascii", "unicode" being the default, and SHALL be read from the `option.icons` line of the configuration; "nerd" SHALL stay selectable by that line; any other value SHALL be reported as `file:line: unknown icon set NAME` and keep the set before it.

#### Scenario: Default set
- **WHEN** the shipped configuration is loaded
- **THEN** the icons option is "unicode"

#### Scenario: Nerd stays selectable
- **WHEN** the project file's first line is "option.icons nerd"
- **THEN** the icons option is "nerd", no problem is reported, and "folder_closed" yields the nerd glyph U+F07B

#### Scenario: Invalid value
- **WHEN** the project file's first line is "option.icons emoji"
- **THEN** the icons option stays "unicode" and ".caratrc:1: unknown icon set emoji" is reported

## ADDED Requirements

### Requirement: The default set's glyphs take one cell in any font
Every glyph of the default set, "unicode", SHALL be a single character of display width 1 outside the private use areas, so a terminal font without Nerd Font glyphs draws every icon in one cell.

#### Scenario: Every default glyph is one cell outside the private use areas
- **WHEN** each icon name is looked up in the default set
- **THEN** each glyph is one character whose display width is 1 and whose code point is in neither private use area
