# Spec Delta

## ADDED Requirements

### Requirement: A line with an illegal byte is reported and skipped
A line of any configuration file, or a plugin manifest's configuration line, that holds a byte outside a well-formed UTF-8 sequence SHALL be reported as `file:line: illegal byte` and skipped, a comment included, and every other line SHALL still load. The editor SHALL start whatever bytes a file holds.

#### Scenario: Illegal byte in the project file
- **WHEN** the project file's first line is "option.theme caf" followed by the byte E9
- **THEN** ".caratrc:1: illegal byte" is reported and the theme keeps its value

#### Scenario: Illegal byte in the user file's binding
- **WHEN** the user file's first line binds "x" in normal mode to a value holding the byte FF and its second line is "option.tabstop 4"
- **THEN** "~/.config/carat/caratrc:1: illegal byte" is reported, "x" is not bound, and tabstop is 4

#### Scenario: Valid UTF-8 is not refused
- **WHEN** the project file's first line is "option.tabstop 4 # quatre espaces, é"
- **THEN** tabstop is 4 and nothing is reported

### Requirement: Only regular files of bounded size are read
The user and project files SHALL be read only when they are regular files of at most 1048576 bytes. The project file SHALL not be read when it is a symbolic link. A refused file SHALL be reported as `source: reason` in load order, the other files SHALL still load, and startup SHALL neither hang nor read more than the limit. A directory SHALL still be skipped silently.

#### Scenario: Project file that is a symbolic link
- **WHEN** `.caratrc` in the working directory is a symbolic link, to `/dev/zero` or to a regular file
- **THEN** ".caratrc: is a symbolic link, not read" is reported and none of its lines apply

#### Scenario: Project file that is a FIFO
- **WHEN** `.caratrc` in the working directory is a FIFO with no writer
- **THEN** the editor starts and ".caratrc: is not a regular file, not read" is reported

#### Scenario: Oversized file
- **WHEN** the user file holds more than 1048576 bytes
- **THEN** "~/.config/carat/caratrc: is larger than 1048576 bytes, not read" is reported and the project file still loads

#### Scenario: A linked user file is read
- **WHEN** the user file is a symbolic link to a regular file holding "option.tabstop 4"
- **THEN** tabstop is 4

### Requirement: tabstop and shiftwidth are bounded
`option.tabstop` SHALL take a number from 1 to 9999 and `option.shiftwidth` a number from 0 to 9999, 0 meaning the tabstop. A value outside SHALL be reported as `file:line: option.tabstop takes a number from 1 to 9999` (or `option.shiftwidth takes a number from 0 to 9999`) and the earlier value SHALL be kept.

#### Scenario: Huge tabstop
- **WHEN** the project file's first line is "option.tabstop 999999999"
- **THEN** ".caratrc:1: option.tabstop takes a number from 1 to 9999" is reported and tabstop keeps its value

#### Scenario: Zero tabstop
- **WHEN** the project file's first line is "option.tabstop 0"
- **THEN** ".caratrc:1: option.tabstop takes a number from 1 to 9999" is reported

#### Scenario: Largest values
- **WHEN** the project file sets tabstop to 9999 and shiftwidth to 9999
- **THEN** both are 9999 and nothing is reported

#### Scenario: Huge shiftwidth
- **WHEN** the project file's first line is "option.shiftwidth 10000"
- **THEN** ".caratrc:1: option.shiftwidth takes a number from 0 to 9999" is reported
