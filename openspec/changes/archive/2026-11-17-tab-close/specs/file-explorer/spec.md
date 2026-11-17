## ADDED Requirements

### Requirement: The explorer toggle hides a tree that is the last window
`<leader>e` in the tree window SHALL hide the tree also when it is the editor's last window: a file window showing the first listed file buffer, or a new empty buffer when none is listed, SHALL take its place, focused, instead of the refusal E444.

#### Scenario: The explorer toggle in a lone tree opens a file window
- **WHEN** the tree is open, ":only" is run in it, and `<leader>e` is pressed
- **THEN** one window remains, showing "a.md", and no message is shown
