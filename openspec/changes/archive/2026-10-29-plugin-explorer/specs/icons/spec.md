# Spec Delta

## MODIFIED Requirements

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
