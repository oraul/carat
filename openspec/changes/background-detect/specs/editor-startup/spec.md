## ADDED Requirements

### Requirement: The editor asks the terminal for its background without waiting
On start the editor SHALL ask the terminal for its background color with the OSC 11 query and SHALL draw the first frame without waiting for an answer. The answer SHALL be read as untrusted input within a fixed bound: a reply naming a light color SHALL report the background light, one naming a dark color dark, and a malformed reply or none SHALL leave it unknown. No byte of a reply SHALL reach the keys; the keys typed around it SHALL arrive unchanged.

#### Scenario: The first frame waits for no reply
- **WHEN** the editor starts on a terminal that has not answered
- **THEN** the query is written and the first frame follows at once, the background unknown

#### Scenario: A dark reply
- **WHEN** the terminal answers with a dark color between typed keys
- **THEN** the background is dark and only the typed keys arrive

#### Scenario: A light reply
- **WHEN** the terminal answers with a light color, whole or split across two reads
- **THEN** the background is light and no reply byte arrives as a key

#### Scenario: A malformed reply
- **WHEN** the answer is too long, cut short, or in another format
- **THEN** the background stays unknown and no reply byte arrives as a key

#### Scenario: No reply
- **WHEN** the terminal never answers
- **THEN** the background stays unknown and every typed key arrives unchanged
