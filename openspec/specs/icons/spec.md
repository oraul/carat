# icons Specification

## Purpose
Icons are the glyphs the editor and its plugins show for folders, files, file types, and diagnostics, chosen by name from one of three sets so a terminal without a Nerd Font still shows something sensible.

## Requirements

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

### Requirement: The icon table maps names to one glyph per set
The table SHALL hold, for each set, a glyph for the names folder_closed, folder_open, file, symlink, modified, current, error, warning, info, hint, ruby, json, markdown, toml, makefile, shell, c, yaml, git, lock, and default. The nerd set SHALL use Nerd Font code points in the private use areas, the unicode set SHALL use triangles, bullets, and geometric shapes outside the private use areas, and the ascii set SHALL use ASCII characters only. An unknown name SHALL yield the empty string.

#### Scenario: Every name in every set
- **WHEN** each listed name is looked up in each set
- **THEN** each yields a non-empty glyph, the nerd glyphs are in the private use areas, the ascii glyphs are ASCII, and the unicode glyphs are neither

#### Scenario: Ascii folder
- **WHEN** "folder_closed" is looked up in the ascii set
- **THEN** the glyph is "+"

#### Scenario: Current marker
- **WHEN** "current" is looked up in the ascii set
- **THEN** the glyph is ">"

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

### Requirement: The icon table holds the completion kinds
The table SHALL also hold, in each set and under the same rules for each set, a glyph for the completion kind names kind_text, kind_method, kind_function, kind_constructor, kind_field, kind_variable, kind_class, kind_module, kind_property, kind_keyword, kind_snippet, and kind_constant.

#### Scenario: Every kind in every set
- **WHEN** each kind name is looked up in each set
- **THEN** each yields a non-empty glyph, the nerd glyphs are in the private use areas, the ascii glyphs are ASCII, and the unicode glyphs are neither

#### Scenario: A completion kind
- **WHEN** "kind_function" is looked up in the ascii set
- **THEN** the glyph is "f"

### Requirement: The default set's glyphs take one cell in any font
Every glyph of the default set, "unicode", SHALL be a single character of display width 1 outside the private use areas, so a terminal font without Nerd Font glyphs draws every icon in one cell.

#### Scenario: Every default glyph is one cell outside the private use areas
- **WHEN** each icon name is looked up in the default set
- **THEN** each glyph is one character whose display width is 1 and whose code point is in neither private use area

### Requirement: The icon table holds the branch counts
The table SHALL hold, for each set, a glyph for the names `ahead` and `behind`: a Nerd Font arrow in the private use areas in the nerd set, `↑` and `↓` in the unicode set, and `+` and `-` in the ascii set.

#### Scenario: The ahead and behind glyphs per set
- **WHEN** "ahead" and "behind" are looked up in the unicode and the ascii sets
- **THEN** they are "↑" and "↓", then "+" and "-"
