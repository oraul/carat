## ADDED Requirements

### Requirement: The command line keeps a history
Each command line run at the ":" prompt SHALL be added to the command history, the newest last, without duplicates and at most 50 entries. At the ":" prompt "<Up>" SHALL replace the text with the next older entry that starts with what was typed before the first recall, and "<Down>" with the next newer one, returning to the typed text after the newest; with no such entry the text SHALL stay.

#### Scenario: Recall the last command
- **WHEN** ":set ft?" is run, then ":", "<Up>" are pressed
- **THEN** the command line shows "set ft?"

#### Scenario: Down returns to the typed text
- **WHEN** ":set ft?" is run, then ":", "s", "<Up>", "<Down>" are pressed
- **THEN** the command line shows "s"
