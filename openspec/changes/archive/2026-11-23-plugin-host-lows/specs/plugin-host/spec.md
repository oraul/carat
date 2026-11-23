## ADDED Requirements

### Requirement: A program runs only from an absolute PATH directory
The process runner SHALL resolve the first word of a program the host runs, or of a language server it starts, against the directories of the `PATH` that are absolute, take the first holding an executable regular file of that name, and start it by that absolute path. A relative or empty `PATH` entry, which is the working directory, SHALL never be searched, and a name no absolute entry holds SHALL start nothing.

#### Scenario: A relative PATH entry never runs a program
- **WHEN** a program named in a directory reached by a relative or an empty `PATH` entry is run through `capture` or `spawn`
- **THEN** nothing is started, and the same program in an absolute `PATH` entry runs

### Requirement: A span's start is bounded
`style_float` SHALL refuse a span starting past 1 << 30 as it refuses a negative start, and the token copy SHALL drop a token starting past 1 << 30 and cut a length past it to it, so a painter's column plus length stays small.

#### Scenario: A float span starting past the longest span is refused
- **WHEN** a plugin styles a float with a span at column 1,073,741,825
- **THEN** the response fails with "No span at column 1073741825 length 2"

#### Scenario: A token starting past the longest span is dropped
- **WHEN** a tokenizer answers a token starting at 1,073,741,825 and one of length 9,000,000,000
- **THEN** the first is dropped and the second is kept with a length of 1,073,741,824

### Requirement: A plugin's view in a hidden slot is let go
A scratch buffer a hidden slot of a tab page keeps SHALL leave the buffer list, and the slot SHALL be emptied, when the plugin that owns it closes it with `close_scratch` or is disabled.

#### Scenario: close_scratch lets go of a hidden slot's view
- **WHEN** a plugin's side window is hidden by the slot toggle and the plugin closes its scratch buffer
- **THEN** the response succeeds, the buffer is no longer listed, and the slot is empty

#### Scenario: A disabled plugin leaves no hidden slot's view
- **WHEN** a plugin whose side window is hidden raises and is disabled
- **THEN** its buffer is no longer listed and the slot is empty
