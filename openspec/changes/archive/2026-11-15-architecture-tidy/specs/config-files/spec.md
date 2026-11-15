## ADDED Requirements

### Requirement: A formatter line is answered as not supported yet
No language service runs a formatter yet, so the shipped defaults SHALL set no `language.<name>.formatter` line, and such a line in the user file SHALL be reported as "language setting formatter is not supported yet" and ignored; in the project file it SHALL be reported as a language command a project file may not set, as every `language.*` line there is.

#### Scenario: A language setting not supported yet
- **WHEN** the user file's first line is "language.ruby.formatter rubocop"
- **THEN** "~/.config/carat/caratrc:1: language setting formatter is not supported yet" is reported and no formatter command is kept

#### Scenario: The defaults ship no formatter
- **WHEN** the editor starts with neither a user file nor a project file
- **THEN** no `language.ruby.formatter` line is set and nothing is reported
