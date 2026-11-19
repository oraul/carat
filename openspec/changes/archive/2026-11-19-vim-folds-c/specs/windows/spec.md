## MODIFIED Requirements

### Requirement: Closing a window drops its folds
Closing a window or a tab page SHALL drop the folds of each closed window, so the buffer tracks only the fold lists of windows that remain. Quitting the only window of a tab page SHALL also drop the folds of the hidden view windows of its kept slots.

#### Scenario: Closing a split leaves one fold list
- **WHEN** "zfj<C-w>s<C-w>c" is typed on a buffer
- **THEN** the buffer tracks one fold list and the remaining window keeps its closed fold

#### Scenario: Quitting a second tab page's only window drops its hidden slot window's folds
- **WHEN** ":q" is typed in the only window of a second tab page beside a hidden slot window with a fold
- **THEN** the buffer no longer tracks the slot window's fold list
