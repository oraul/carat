## MODIFIED Requirements

### Requirement: Moving to the neighbour window
`<C-w>h`, `<C-w>j`, `<C-w>k`, and `<C-w>l` SHALL make the window to the left, below, above, or to the right of the current one the current window, choosing the neighbour that overlaps the cursor's screen row or column, and SHALL do nothing when there is none. A count SHALL repeat the move, stopping at the edge.

#### Scenario: Down and up
- **WHEN** a window is split with `<C-w>s` and `<C-w>j` is pressed
- **THEN** the bottom window is current, and after `<C-w>k` the top window is current again

#### Scenario: Right and left
- **WHEN** a window is split with `<C-w>v` and `<C-w>l` is pressed
- **THEN** the right window is current, and after `<C-w>h` the left window is current again

#### Scenario: No neighbour
- **WHEN** a window is split with `<C-w>s` and `<C-w>k` is pressed in the top window
- **THEN** the top window stays current

#### Scenario: Count stops at the edge
- **WHEN** three windows are stacked, the top one is current, and "5<C-w>j" is typed
- **THEN** the bottom window is current

#### Scenario: Neighbour by layout rectangles
- **WHEN** a window is split with `<C-w>v`, the right window is split with `<C-w>s`, and in the left window `<C-w>l` is pressed with the cursor on the first row, or in another editor with the cursor on a row below the upper right window's rectangle
- **THEN** the upper right window is current, or the lower right window, since each is the window whose layout rectangle abuts the left window's and overlaps the cursor's screen row; from either right window `<C-w>h` makes the left window current
