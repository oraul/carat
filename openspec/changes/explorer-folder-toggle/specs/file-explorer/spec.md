## RENAMED Requirements

- FROM: `### Requirement: Enter and l open a file or expand a directory`
- TO: `### Requirement: Enter toggles a directory and l expands one, both open a file`

## ADDED Requirements

### Requirement: A toggled directory keeps the cursor
After `<CR>`, `l`, `h`, or `o` expands or collapses a directory, the cursor SHALL stay on that directory's line, for a directory nested in another too and when the tree was made current with a window command.

#### Scenario: A nested directory
- **WHEN** "lib" is expanded and `<CR>` is pressed twice on "deep" inside it
- **THEN** "deep" is expanded after the first and collapsed after the second, "lib" stays expanded, and the cursor is on the line of "deep" after each

#### Scenario: The tree reached with Ctrl-W
- **WHEN** the tree is left with `<C-w>l`, entered again with `<C-w>h`, and `<CR>` is pressed twice on "docs"
- **THEN** "docs" is expanded after the first and collapsed after the second, and the cursor is on the line of "docs"

## MODIFIED Requirements

### Requirement: Enter toggles a directory and l expands one, both open a file
`<CR>` and `l` on a file SHALL show it in the previously used window that shows a file, or the first such window in layout order, make that window current, and show the opened message; when no window of the tab page shows a file, it SHALL be shown in a new window beside the tree, which keeps its width. On a collapsed directory both SHALL expand it; on an expanded one `<CR>` SHALL collapse it and `l` SHALL leave it expanded. `o` SHALL act as `<CR>`. On the root line all three SHALL do nothing.

#### Scenario: Open a file
- **WHEN** the cursor in the tree is on "b.rb" and `<CR>` is pressed
- **THEN** the file window shows "b.rb", is current, and the tree is still open

#### Scenario: Enter toggles a directory
- **WHEN** `<CR>` is pressed twice on "docs"
- **THEN** "docs" is expanded after the first and collapsed after the second, and the cursor is on the line of "docs" after each

#### Scenario: l leaves an expanded directory expanded
- **WHEN** `l` is pressed twice on "docs"
- **THEN** "docs" is expanded after each, and the cursor is on the line of "docs"

#### Scenario: Expand and collapse with o
- **WHEN** `o` is pressed twice on "docs"
- **THEN** "docs" is expanded after the first and collapsed after the second

#### Scenario: Only the tree is left
- **WHEN** the file window was closed with `<C-w>c`, leaving only the tree, and `<CR>` is pressed on "b.rb"
- **THEN** there are two windows, the tree is 30 columns wide, and the other window shows "b.rb"

### Requirement: h collapses or moves to the parent
`h` on an expanded directory SHALL collapse it and keep the cursor on its line; on a file or a collapsed directory it SHALL move the cursor to the line of its parent directory; on the root line it SHALL do nothing.

#### Scenario: Collapse
- **WHEN** "docs" is expanded and `h` is pressed on it
- **THEN** "docs" is collapsed and the cursor is on its line

#### Scenario: Parent
- **WHEN** the cursor is on "guide.md" inside "docs" and `h` is pressed
- **THEN** the cursor is on the line of "docs"

#### Scenario: Parent of a collapsed directory
- **WHEN** "lib" is expanded, the cursor is on the collapsed "deep" inside it, and `h` is pressed
- **THEN** the cursor is on the line of "lib" and "deep" stays collapsed

### Requirement: Refresh, close, and help
`R` SHALL list the directories again from disk, `q` SHALL close the tree window, and `?` SHALL show a one-line summary of the tree's keys in the message row. Every other key SHALL fall through to the normal keymap, so `j`, `k`, `gg`, and `G` move the cursor in the tree.

#### Scenario: Refresh
- **WHEN** a file "z.rb" is written to the root outside the tree and `R` is pressed
- **THEN** "z.rb" is listed

#### Scenario: Close
- **WHEN** `q` is pressed in the tree
- **THEN** the tree window is gone

#### Scenario: Help
- **WHEN** `?` is pressed in the tree
- **THEN** the message row starts with "<CR>/o toggle"

#### Scenario: Movement falls through
- **WHEN** `j` is pressed on the root line
- **THEN** the cursor is on row 1 of the tree
