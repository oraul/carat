## MODIFIED Requirements

### Requirement: The tree lists the root and its entries in order
The root, which is the working directory when the tree first opens, SHALL have no line of its own, the tab row's head naming it: the first line SHALL be the first entry of the root. Each entry SHALL be on its own line, indented two spaces per level below the root's entries, as the entry's icon, a space, and its name; directories SHALL come before files, and each group SHALL be sorted by name ignoring case. Every line SHALL start with a one-cell marker column.

#### Scenario: Top level
- **WHEN** the working directory "proj" holds "b.rb", "Lib/", "a.md", and "docs/", and the tree is opened with the ascii icon set
- **THEN** the lines are " + docs", " + Lib", " m a.md", and " r b.rb"

#### Scenario: Nested
- **WHEN** "docs" is expanded and holds "guide.md"
- **THEN** the line after " - docs" is "   m guide.md"

#### Scenario: The tree starts at the root's entries
- **WHEN** the tree is opened on "proj" holding "docs/" and "a.md" with the unicode icon set
- **THEN** the head above the tree names "proj", the first tree row is " ▸ docs", and no line of the tree is the root

### Requirement: Icons come from the icon table by name
Each line SHALL use the configured icon set: folder_closed or folder_open for a directory by its state, symlink for a symbolic link, and for a file the icon of its type: ruby for ".rb", json for ".json", markdown for ".md", toml for ".toml", makefile for "Makefile", shell for ".sh", c for ".c" and ".h", yaml for ".yml" and ".yaml", git for ".gitignore", ".gitattributes", and ".gitmodules", lock for ".lock", and default otherwise.

#### Scenario: Unicode set
- **WHEN** the icons option is "unicode" and the root holds "a.rb" and "src/"
- **THEN** the lines are " ▸ src" and " ◈ a.rb"

#### Scenario: Nerd set
- **WHEN** the icons option is "nerd" and the root holds "Makefile"
- **THEN** its line holds the makefile glyph of the nerd set before " Makefile"

#### Scenario: Symlink
- **WHEN** the root holds a symbolic link "link"
- **THEN** its line uses the symlink icon

### Requirement: The current file is marked and revealed
The line of the file shown in the current window SHALL carry the `current` icon, the bar, in the marker column and SHALL be the current row, drawn as a full-width highlight (the host's `mark_scratch_row`) with the bar in its marker cell, and the directories between the root and that file SHALL be expanded, when the tree opens and whenever another file becomes current. A file outside the root, an unnamed buffer, or a plugin window SHALL change nothing.

#### Scenario: Revealed on open
- **WHEN** the editor shows "lib/deep/x.rb" and the tree is opened with the ascii set
- **THEN** "lib" and "deep" are expanded, the line of "x.rb" starts with "|", and the tree's cursor is on it

#### Scenario: Follows another file
- **WHEN** the tree is open and ":e docs/guide.md" is run in the file window
- **THEN** "docs" is expanded and the line of "guide.md" is marked

#### Scenario: The current row is a full-width highlight
- **WHEN** the tree is open with the unicode icon set and "a.md" is the current file
- **THEN** the cells of the "a.md" row across the window are in the selection fill, the first holds "▎" in the bar's group, and the other rows are not

#### Scenario: The highlight follows the current file
- **WHEN** ":e b.rb" is run in the file window
- **THEN** the highlight and the bar are on the "b.rb" row and the "a.md" row has neither

### Requirement: Enter toggles a directory and l expands one, both open a file
`<CR>` and `l` on a file SHALL show it in the previously used window that shows a file, or the first such window in layout order, make that window current, and show the opened message; when no window of the tab page shows a file, it SHALL be shown in a new window beside the tree, which keeps its width. On a collapsed directory both SHALL expand it; on an expanded one `<CR>` SHALL collapse it and `l` SHALL leave it expanded. `o` SHALL act as `<CR>`.

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
`h` on an expanded directory SHALL collapse it and keep the cursor on its line; on a file or a collapsed directory it SHALL move the cursor to the line of its parent directory; on a top-level entry, whose directory is the root, it SHALL do nothing.

#### Scenario: Collapse
- **WHEN** "docs" is expanded and `h` is pressed on it
- **THEN** "docs" is collapsed and the cursor is on its line

#### Scenario: Parent
- **WHEN** the cursor is on "guide.md" inside "docs" and `h` is pressed
- **THEN** the cursor is on the line of "docs"

#### Scenario: Parent of a collapsed directory
- **WHEN** "lib" is expanded, the cursor is on the collapsed "deep" inside it, and `h` is pressed
- **THEN** the cursor is on the line of "lib" and "deep" stays collapsed

#### Scenario: Top-level entry
- **WHEN** the cursor is on a top-level entry and `h` is pressed
- **THEN** the cursor and the tree are unchanged

### Requirement: a creates a file or a directory
`a` SHALL prompt for a name in the command-line row and create, under the directory of the entry under the cursor (the entry itself when it is a directory, else its directory, the root for a top-level file), an empty file, or a directory when the name ends with "/"; the tree SHALL be redrawn with that directory expanded and the cursor on the new entry. An empty name, Escape, or a refusal from the host SHALL create nothing, a refusal showing its message as an error.

#### Scenario: Create a file
- **WHEN** `a` is pressed on the top-level file "a.md" and "new.rb" Enter is typed
- **THEN** "new.rb" exists on disk and is listed

#### Scenario: Create a directory
- **WHEN** `a` is pressed and "pkg/" Enter is typed
- **THEN** the directory "pkg" exists and is listed among the directories

#### Scenario: Prompt cancelled
- **WHEN** `a` is pressed and Escape is pressed
- **THEN** nothing is created and the mode is normal

#### Scenario: Name taken
- **WHEN** `a` is pressed and "b.rb" Enter is typed while "b.rb" exists
- **THEN** the message row shows "Already exists: b.rb" as an error

### Requirement: r renames an entry
`r` SHALL prompt for a new name with the current name as the initial text and rename the entry in its directory; an open buffer of the renamed file SHALL show the new path. A name with a path separator, an empty name, or an existing name SHALL be refused with a message.

#### Scenario: Rename an open file
- **WHEN** "b.rb" is open in the file window and `r` is pressed on it, the text is cleared, and "c.rb" Enter is typed
- **THEN** "c.rb" exists, "b.rb" does not, and the file window's buffer path is "c.rb"

#### Scenario: Separator refused
- **WHEN** a rename to "x/y.rb" is typed
- **THEN** the message is "Name contains a path separator: x/y.rb" and nothing changed on disk

### Requirement: The root moves up and down
`-` SHALL make the parent of the root the new root, keeping the old root expanded; `C` SHALL make the directory under the cursor, or the directory of the file under the cursor, the new root.

#### Scenario: Up
- **WHEN** the root is "/home/ada/proj" and `-` is pressed
- **THEN** the first line is "proj", listed expanded, with its entries below it

#### Scenario: Into a directory
- **WHEN** `C` is pressed on "docs"
- **THEN** the first line is the first entry of "docs"

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
- **WHEN** `j` is pressed on the first row
- **THEN** the cursor is on the second row of the tree
