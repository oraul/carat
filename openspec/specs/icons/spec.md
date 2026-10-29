# icons Specification

## Purpose
Icons are the glyphs the editor and its plugins show for folders, files, file types, and diagnostics, chosen by name from one of three sets so a terminal without a Nerd Font still shows something sensible.

## Requirements

### Requirement: The icons option selects the icon set
The option "icons" SHALL take the values "nerd", "unicode", and "ascii", "nerd" being the default, and SHALL be read from the configuration's options; any other value SHALL keep the default.

#### Scenario: Default set
- **WHEN** the shipped configuration is loaded
- **THEN** the icons option is "nerd"

#### Scenario: Invalid value
- **WHEN** the configuration sets icons to "emoji"
- **THEN** the icons option stays "nerd"

### Requirement: The icon table maps names to one glyph per set
The table SHALL hold, for each set, a glyph for the names folder_closed, folder_open, file, symlink, modified, error, warning, info, hint, ruby, json, markdown, toml, makefile, shell, c, yaml, git, lock, and default. The nerd set SHALL use Nerd Font code points in the private use areas, the unicode set SHALL use triangles, bullets, and geometric shapes outside the private use areas, and the ascii set SHALL use ASCII characters only. An unknown name SHALL yield the empty string.

#### Scenario: Every name in every set
- **WHEN** each listed name is looked up in each set
- **THEN** each yields a non-empty glyph, the nerd glyphs are in the private use areas, the ascii glyphs are ASCII, and the unicode glyphs are neither

#### Scenario: Ascii folder
- **WHEN** "folder_closed" is looked up in the ascii set
- **THEN** the glyph is "+"

#### Scenario: Unknown name
- **WHEN** "nope" is looked up
- **THEN** the glyph is ""

### Requirement: Plugins get icons by name through the host
A plugin SHALL ask the host for an icon by name and receive the glyph of the configured set, never choosing a code point itself, so changing the option switches every icon in the editor.

#### Scenario: Switching the set
- **WHEN** the hello plugin greets with icons "nerd" and again with icons "ascii"
- **THEN** the first message starts with the nerd info glyph and the second with "i"

### Requirement: Private use area glyphs are one cell wide
Code points U+E000 to U+F8FF and U+F0000 to U+FFFFD SHALL have display width 1, so a Nerd Font glyph takes one cell in the frame.

#### Scenario: Nerd glyph width
- **WHEN** the display width of U+F07B and of U+F0001 is computed
- **THEN** both are 1
