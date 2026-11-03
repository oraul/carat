## ADDED Requirements

### Requirement: A name that is not UTF-8 is listed
An entry whose name is not valid UTF-8 SHALL be listed in its place with each byte outside a well-formed sequence drawn as one U+FFFD cell, and the explorer SHALL stay enabled.

#### Scenario: Hostile names in the tree
- **WHEN** the working directory holds "caf\xE9.md" and "\xF4\x90\x80\x80.md" and the tree is opened with the ascii icon set
- **THEN** the tree lists both names, the screen shows them as "caf\u{FFFD}.md" and "\u{FFFD}\u{FFFD}\u{FFFD}\u{FFFD}.md", and the explorer plugin is still enabled
