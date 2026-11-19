## ADDED Requirements

### Requirement: Closing a window drops its folds
Closing a window or a tab page SHALL drop the folds of each closed window, so the buffer tracks only the fold lists of windows that remain.

#### Scenario: Closing a split leaves one fold list
- **WHEN** "zfj<C-w>s<C-w>c" is typed on a buffer
- **THEN** the buffer tracks one fold list and the remaining window keeps its closed fold
