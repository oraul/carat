## MODIFIED Requirements

### Requirement: Untrusted patterns and replacements are bounded
A substitute pattern SHALL be translated and capped as a search pattern is, and every scan of a line and every character of replacement text SHALL be charged to one work budget per command, each replacement charged before it is built, so a replacement the budget cannot pay for is never built. When the budget runs out the command SHALL change nothing and report "E363: search stopped, pattern too costly here".

#### Scenario: A costly command stops
- **WHEN** a substitute would produce more replacement text than its budget allows
- **THEN** the message is "E363: search stopped, pattern too costly here" and the text is unchanged

#### Scenario: A replacement past the budget is never built
- **WHEN** a substitute's one replacement would be gigabytes long, as `&` repeated on a long match
- **THEN** the command stops at once, without building it, changing nothing
