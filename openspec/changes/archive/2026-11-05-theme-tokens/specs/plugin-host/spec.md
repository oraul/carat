## MODIFIED Requirements

### Requirement: The host refuses a newer major API version
The API SHALL have a version in `major.minor` form, 2.1 since the theme tokens let a plugin's tokens carry the file-icon groups and a plugin's scratch buffer take the plugin's filetype. A manifest written against a different major version, or against the host's major version with a newer minor, SHALL be refused with a message naming the plugin, the version it needs, and the version the host has; a manifest with the same major and the host's minor or an older one SHALL be accepted.

#### Scenario: Newer major
- **WHEN** a plugin's manifest names API version "3.0"
- **THEN** the plugin is disabled and the host records that the plugin needs API 3.0 and the host has 2.1

#### Scenario: Older major
- **WHEN** a plugin's manifest names API version "1.3"
- **THEN** the plugin is disabled and the host records that it needs API 1.3

#### Scenario: Newer minor
- **WHEN** a plugin's manifest names API version "2.2"
- **THEN** the plugin is disabled and the host records that it needs API 2.2 and the host has 2.1

#### Scenario: Older minor
- **WHEN** a plugin's manifest names API version "2.0", the host's major with a minor older than the host's
- **THEN** the plugin is accepted

### Requirement: Malformed tokens and states are ignored
A token with a negative start, a length below one, or an id outside the syntax groups and the file-icon groups SHALL be ignored, and a returned state that is not a non-negative integer SHALL count as 0.

#### Scenario: A token out of range
- **WHEN** a plugin appends a token with the group id 9999
- **THEN** the token is ignored and the line is drawn in the normal group

#### Scenario: A token in an editor group
- **WHEN** a plugin appends a token with the StatusLine id
- **THEN** the token is ignored

#### Scenario: A negative state
- **WHEN** a plugin returns -5 as the end state of a line
- **THEN** the next line is tokenized starting in state 0

### Requirement: A plugin resolves highlight group names through the host
`syntax_group(name)` SHALL answer the id of a syntax group or a file-icon group by its name, as a successful response whose number is the id, and fail with `No highlight group named <name>` for any other name, the UI groups included.

#### Scenario: Resolving a group
- **WHEN** a plugin asks for `String` while activating
- **THEN** the response succeeds and its number is the String group's id

#### Scenario: Resolving a file-icon group
- **WHEN** a plugin asks for `DevIconRb`
- **THEN** the response succeeds and its number is the DevIconRb group's id

## ADDED Requirements

### Requirement: A plugin's scratch buffer takes the plugin's filetype
A scratch buffer opened by a plugin whose manifest declares a filetype equal to the plugin's name SHALL have that syntax, so the plugin tokenizes its own scratch lines; any other scratch buffer SHALL have none.

#### Scenario: The explorer tokenizes its tree
- **WHEN** the explorer, which declares the filetype `explorer`, opens its tree
- **THEN** the tree buffer's syntax is `explorer`

#### Scenario: A plugin without its own filetype
- **WHEN** a plugin that declares no filetype opens a scratch buffer
- **THEN** `:set syntax?` in it shows an empty syntax
