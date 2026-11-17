## ADDED Requirements

### Requirement: A root's language command names a root and a command
A `language.<name>.lsp.root` line in the defaults or the user file SHALL be accepted when it holds a root and at least one word of a command; a line with fewer words SHALL be reported as "language.<name>.lsp.root needs a root and a command" and ignored.

#### Scenario: Root command in the user file
- **WHEN** the user file holds "language.ruby.lsp.root /work docker compose exec app ruby-lsp"
- **THEN** nothing is reported and the line is kept with its words

#### Scenario: Root command without a command
- **WHEN** the user file's first line is "language.ruby.lsp.root /work"
- **THEN** line 1 is reported as "language.ruby.lsp.root needs a root and a command" and ignored

## MODIFIED Requirements

### Requirement: A project file cannot choose programs to run
A `language.*` line in the project file SHALL be reported as "language commands are not read from a project file" and ignored, because it names a program to run; the same line in the defaults or the user file SHALL be accepted.

#### Scenario: Language command in the project file
- **WHEN** the project file's first line is "language.ruby.lsp ./evil"
- **THEN** ".caratrc:1: language commands are not read from a project file" is reported and the Ruby language command stays the one the defaults name

#### Scenario: Language command in the user file
- **WHEN** the user file holds "language.ruby.lsp ruby-lsp --debug"
- **THEN** nothing is reported

#### Scenario: Root command in the project file
- **WHEN** the project file's first line is "language.ruby.lsp.root / ./evil"
- **THEN** ".caratrc:1: language commands are not read from a project file" is reported and no root command is kept
