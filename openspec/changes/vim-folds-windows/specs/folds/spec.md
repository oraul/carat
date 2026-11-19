## ADDED Requirements

### Requirement: Insert mode opens the closed folds under the cursor
Entering insert or replace mode SHALL open every closed fold holding the cursor, as Neovim's foldOpenCursor does when an insert session starts, so the edited line is shown.

#### Scenario: zfjiX opens the fold and edits its first line
- **WHEN** "zfjiX<Esc>" is typed on the lines "a", "b", "c", "d", "e"
- **THEN** the first line is "Xa" and the fold covers rows 0 and 1, open
