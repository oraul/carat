# Spec Delta

## ADDED Requirements

### Requirement: Window commands wait for their second key
`<C-w>` SHALL wait for the key that completes the window command however long it takes to arrive, so `<C-w>h j k l w W p` typed slowly move focus exactly as typed together.

#### Scenario: A slow second key
- **WHEN** a window is split with `<C-w>v`, `<C-w>` is pressed, more than timeoutlen passes, and "l" is pressed
- **THEN** the right window is current and the cursor has not moved

#### Scenario: A slow second key for the next window
- **WHEN** a window is split with `<C-w>s`, `<C-w>` is pressed, more than timeoutlen passes, and "w" is pressed
- **THEN** the bottom window is current

### Requirement: Moving between the file tree and the file windows
The window commands SHALL treat the file tree's window as any other window: `<C-w>h j k l w W p` SHALL move focus out of the tree into the file windows and back into the tree, also when the second key comes after timeoutlen, and the tree's own keys SHALL not run in place of the window command.

#### Scenario: Out of the tree and back, slowly
- **WHEN** the tree is opened at the left with `<leader>e`, `<C-w>` is pressed, more than timeoutlen passes, "l" is pressed, then `<C-w>`, a wait, and "h"
- **THEN** the file window is current after "l", the tree is current after "h", and no tree entry was opened or collapsed

#### Scenario: Cycling through the tree
- **WHEN** the tree is open beside one file window and focused, and `<C-w>w` is pressed twice
- **THEN** the file window is current after the first press and the tree after the second, and `<C-w>p` returns to the file window
