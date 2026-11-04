## MODIFIED Requirements

### Requirement: The editor's own highlights are groups too
The editor SHALL draw its own parts in the groups `Normal`, `LineNr`, `SignColumn`, `StatusLine`, `StatusLineNC`, `TabLine`, `TabLineSel`, `TabLineFill`, `Visual`, `NonText`, `ErrorMsg`, `Search`, and `IncSearch`, which a theme colors like the syntax groups and which a plugin cannot use for tokens.

#### Scenario: A plugin asks for an editor group
- **WHEN** a plugin asks for the group `StatusLine`
- **THEN** the request fails with `No highlight group named StatusLine`

#### Scenario: The search groups have colors
- **WHEN** either shipped theme is chosen
- **THEN** `Search` and `IncSearch` have a background color in both color depths
