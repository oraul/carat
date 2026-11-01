## MODIFIED Requirements

### Requirement: Plugin ex commands are routed by name or abbreviation
An ex command a plugin declares SHALL be run by the plugin when typed as its abbreviation, its full name, or any spelling between them that starts the full name, with its bang and arguments, after the core ex commands and before the unknown-command check; when two plugins' commands accept the typed name, the plugin registered first SHALL run it. Its result message SHALL be shown as another ex command's is.

#### Scenario: Full name
- **WHEN** ":Hello Ada" is run
- **THEN** the message row ends with "Hello, Ada! 1 buffer opened"

#### Scenario: Abbreviation
- **WHEN** ":Hel" is run
- **THEN** the hello plugin greets as ":Hello" does

#### Scenario: Between the abbreviation and the full name
- **WHEN** ":Hell" is run
- **THEN** the hello plugin greets as ":Hello" does

#### Scenario: Shorter than the abbreviation
- **WHEN** ":He" is run
- **THEN** the message is "E492: Not an editor command: He"
