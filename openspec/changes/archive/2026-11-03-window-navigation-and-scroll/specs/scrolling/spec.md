# Spec Delta

## Purpose

Scrolls the current window through its buffer without editing it: by a page, by half a page, by a line, or so that the cursor line sits at the top, middle, or bottom, keeping the cursor in view as Neovim does.

## ADDED Requirements

### Requirement: Scrolling keeps the view inside the buffer and the cursor in view
After a scroll command the first shown line SHALL stay between the first line and the line that fills the window to the last line, and the cursor SHALL be moved onto the nearest line inside the window that honors `scrolloff`, keeping its wanted column. A command that cannot scroll SHALL change nothing.

#### Scenario: Cursor pushed down by the view
- **WHEN** a window of 10 text rows shows lines 1 to 10 of 100 with `scrolloff` 2, the cursor on line 1, and `<C-e>` is pressed
- **THEN** the window shows lines 2 to 11 and the cursor is on line 4

#### Scenario: Wanted column kept
- **WHEN** the cursor is in column 5 of a long line, the view scrolls past it, and the line it lands on has 3 characters
- **THEN** the cursor is on the last character of that line, and moving back to a long line returns it to column 5

#### Scenario: Nothing to scroll
- **WHEN** the window shows the first line and `<C-y>` is pressed
- **THEN** the view and the cursor are unchanged

### Requirement: Page scrolling
`<C-f>` and `<PageDown>` SHALL scroll forward, and `<C-b>` and `<PageUp>` backward, by count pages, a page being the window's text rows minus two (at least one). `<C-f>` with the last line already shown SHALL move the cursor to the last line. These keys SHALL work in normal mode and the visual modes, and `<PageDown>` and `<PageUp>` also in insert mode.

#### Scenario: Forward a page
- **WHEN** a window of 10 text rows shows lines 1 to 10 of 100 with `scrolloff` 0, the cursor on line 1, and `<C-f>` is pressed
- **THEN** the window shows lines 9 to 18 and the cursor is on line 9

#### Scenario: Back a page
- **WHEN** after that `<PageUp>` is pressed
- **THEN** the window shows lines 1 to 10 and the cursor stays on line 9

#### Scenario: Two pages
- **WHEN** the window shows lines 1 to 10 of 100 and `2<PageDown>` is typed
- **THEN** the window shows lines 17 to 26

#### Scenario: At the end
- **WHEN** the window shows the last 10 of 100 lines with the cursor on line 91 and `<C-f>` is pressed
- **THEN** the view is unchanged and the cursor is on line 100

### Requirement: Page keys break the insert
`<PageDown>` and `<PageUp>` in insert mode SHALL break the insert as an arrow key does: undo SHALL take back the text typed before and after the key separately, and the dot command SHALL repeat only the text typed after it.

#### Scenario: Undo after a page key
- **WHEN** `ifoo<PageDown>bar<Esc>` is typed on the first line of 100 and then `u`
- **THEN** only `bar` is taken back and `foo` stays on the first line

#### Scenario: Dot after a page key
- **WHEN** `ifoo<PageDown>bar<Esc>` is typed on the first line of 100 and then `.`
- **THEN** `bar` alone is inserted at the cursor

### Requirement: Half-page scrolling
`<C-d>` SHALL scroll down and `<C-u>` up by the `scroll` option's number of lines, half the window's text rows when it is 0, and SHALL move the cursor by the same number of lines; when the view cannot scroll further the cursor SHALL still move, stopping at the first or last line. A count SHALL first set the `scroll` option to the count.

#### Scenario: Down and up half a page
- **WHEN** a window of 10 text rows shows lines 1 to 10 of 100 with `scrolloff` 0, the cursor on line 2, and `<C-d>` is pressed
- **THEN** the window shows lines 6 to 15 and the cursor is on line 7, and after `<C-u>` the window shows lines 1 to 10 with the cursor on line 2

#### Scenario: A count sets the scroll option
- **WHEN** `3<C-d>` is typed and then `<C-d>` is pressed
- **THEN** each scrolls by 3 lines and the `scroll` option is 3

#### Scenario: Cursor moves at the end
- **WHEN** the window shows the last 10 of 100 lines with the cursor on line 92 and `<C-d>` is pressed
- **THEN** the view is unchanged and the cursor is on line 97

### Requirement: Line scrolling
`<C-e>` SHALL scroll the view down and `<C-y>` up by count lines, the cursor staying on its line unless it would leave the window.

#### Scenario: Cursor stays on its line
- **WHEN** a window of 10 text rows shows lines 1 to 10 of 100 with `scrolloff` 0, the cursor on line 5, and `3<C-e>` is typed
- **THEN** the window shows lines 4 to 13 and the cursor is still on line 5

#### Scenario: Cursor pulled up
- **WHEN** the window shows lines 6 to 15 with `scrolloff` 0, the cursor on line 15, and `<C-y>` is pressed
- **THEN** the window shows lines 5 to 14 and the cursor is on line 14

### Requirement: Placing the cursor line
`zt`, `zz`, and `zb` SHALL scroll so the cursor line is at the top, the middle, or the bottom of the window, with `scrolloff` lines of context where the buffer allows, keeping the cursor's column; with a count the cursor SHALL first go to that line.

#### Scenario: Top, middle, bottom
- **WHEN** a window of 10 text rows over 100 lines with `scrolloff` 0 has the cursor on line 51
- **THEN** `zt` shows lines 51 to 60, `zz` shows lines 47 to 56, and `zb` shows lines 42 to 51

#### Scenario: With a count
- **WHEN** `20zt` is typed
- **THEN** the cursor is on line 20 and the window shows lines 20 to 29

#### Scenario: Near the end
- **WHEN** the cursor is on line 98 of 100 and `zt` is pressed
- **THEN** the window shows lines 91 to 100
