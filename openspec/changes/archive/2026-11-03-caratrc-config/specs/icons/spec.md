# Spec Delta

## MODIFIED Requirements

### Requirement: The icons option selects the icon set
The option "icons" SHALL take the values "nerd", "unicode", and "ascii", "nerd" being the default, and SHALL be read from the `option.icons` line of the configuration; any other value SHALL be reported as `file:line: unknown icon set NAME` and keep the set before it.

#### Scenario: Default set
- **WHEN** the shipped configuration is loaded
- **THEN** the icons option is "nerd"

#### Scenario: Invalid value
- **WHEN** the project file's first line is "option.icons emoji"
- **THEN** the icons option stays "nerd" and ".caratrc:1: unknown icon set emoji" is reported
