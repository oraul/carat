# Spec Delta

## ADDED Requirements

### Requirement: A keymap value with an illegal byte never stops the editor
Deciding whether a keymap value names an action SHALL read its bytes and SHALL never fail, whatever bytes the value holds, when the configuration loads, when a plugin's bindings are checked, and when a bound key is pressed. A value holding a byte outside a well-formed UTF-8 sequence is not an action name.

#### Scenario: Illegal byte in a trusted binding
- **WHEN** the user file binds "x" in normal mode to "a" followed by the byte FF and ".b", and the editor starts on "a.txt"
- **THEN** the editor starts, the message row shows "~/.config/carat/caratrc:1: illegal byte" as an error, and the rest of the configuration loads

#### Scenario: Illegal byte asked of the action check
- **WHEN** the value "plugin." followed by the byte FF is checked as an action name
- **THEN** it is not an action name and nothing is raised
