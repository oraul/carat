# Spec Delta

## MODIFIED Requirements

### Requirement: The theme option selects a shipped theme
The `option.theme` line of the configuration SHALL select the theme, `carat-dark` (the default) or `carat-light`; an unknown name SHALL be reported as `file:line: unknown theme NAME` and keep the theme set before it. A theme gives every group a foreground and a background (or the terminal's own) and any of bold, italic, underline, and reverse; `Normal` keeps the terminal's own colors in both themes.

#### Scenario: Default theme
- **WHEN** the editor starts with the shipped configuration
- **THEN** the colors are those of `carat-dark`

#### Scenario: Light theme
- **WHEN** a configuration line is "option.theme carat-light"
- **THEN** the Comment group is written with `carat-light`'s comment color

#### Scenario: Unknown theme
- **WHEN** the project file's first line is "option.theme solarized"
- **THEN** ".caratrc:1: unknown theme solarized" is reported and the colors are those of `carat-dark`
