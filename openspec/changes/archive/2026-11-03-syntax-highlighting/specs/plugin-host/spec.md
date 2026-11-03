# Spec Delta

## MODIFIED Requirements

### Requirement: The host refuses a newer major API version
The API SHALL have a version in `major.minor` form, 1.3 since the syntax highlighting change added tokenizers. A manifest written against a different major version, or against the host's major version with a newer minor, SHALL be refused with a message naming the plugin, the version it needs, and the version the host has; a manifest with the same major and the host's minor or an older one SHALL be accepted.

#### Scenario: Newer major
- **WHEN** a plugin's manifest names API version "2.0"
- **THEN** the plugin is disabled and the host records that the plugin needs API 2.0 and the host has 1.3

#### Scenario: Older major
- **WHEN** a plugin's manifest names API version "0.9"
- **THEN** the plugin is disabled and the host records that it needs API 0.9

#### Scenario: Newer minor
- **WHEN** a plugin's manifest names API version "1.4"
- **THEN** the plugin is disabled and the host records that it needs API 1.4 and the host has 1.3

#### Scenario: Older minor
- **WHEN** a plugin's manifest names API version "1.2"
- **THEN** the plugin is accepted

## ADDED Requirements

### Requirement: A plugin declares the filetypes it tokenizes
A manifest SHALL list the filetypes the plugin tokenizes, each lowercase letters, digits, and underscores starting with a letter, or none; another value SHALL refuse the plugin with the rule it broke. When two enabled plugins declare one filetype, the one registered first tokenizes it.

#### Scenario: Malformed filetype
- **WHEN** a manifest lists the filetype `Ruby Script`
- **THEN** the plugin is disabled with a reason naming the filetype

#### Scenario: Two plugins for one filetype
- **WHEN** two enabled plugins declare `ruby`
- **THEN** the plugin registered first tokenizes Ruby buffers

### Requirement: A tokenizer is called per line with the state before it
The host SHALL tokenize a line by calling the plugin with the filetype, a copy of the line's text, and the state at the start of the line (0 for the first line), and the plugin SHALL append its tokens to an integer array as (start column, length, group id) triples in code point columns and return the state at the end of the line, a non-negative integer.

#### Scenario: Tokens and state
- **WHEN** a plugin appends 0, 3, and the Define id for the line `def x` and returns 0
- **THEN** the cells of `def` are in the Define group and the next line starts in state 0

### Requirement: Malformed tokens and states are ignored
A token with a negative start, a length below one, or an id outside the syntax groups SHALL be ignored, and a returned state that is not a non-negative integer SHALL count as 0.

#### Scenario: A token out of range
- **WHEN** a plugin appends a token with the group id 9999
- **THEN** the token is ignored and the line is drawn in the normal group

#### Scenario: A negative state
- **WHEN** a plugin returns -5 as the end state of a line
- **THEN** the next line is tokenized starting in state 0

### Requirement: A plugin resolves highlight group names through the host
`syntax_group(name)` SHALL answer the id of a syntax group by its name, as a successful response whose number is the id, and fail with `No highlight group named <name>` for any other name.

#### Scenario: Resolving a group
- **WHEN** a plugin asks for `String` while activating
- **THEN** the response succeeds and its number is the String group's id

### Requirement: A tokenizer that raises disables its plugin
A tokenizer call SHALL be guarded like every plugin call: a plugin whose tokenizer raises SHALL be disabled with its message in the message row, and every buffer it tokenized SHALL be drawn in the normal group from the same frame on.

#### Scenario: Raising tokenizer
- **WHEN** a plugin's tokenizer raises while a buffer of its filetype is drawn
- **THEN** the message row shows `Plugin <name> disabled: <message>` and the buffer is drawn in the normal group
