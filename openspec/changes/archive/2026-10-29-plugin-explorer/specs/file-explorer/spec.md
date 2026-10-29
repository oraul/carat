# Spec Delta

## Purpose

The file explorer is the built-in file tree plugin: a side window listing the working directory as a tree with icons, from which the user opens, creates, renames, and deletes files with keys that follow common Neovim tree plugin conventions.

## ADDED Requirements

### Requirement: The explorer is a built-in plugin enabled by default
The `explorer` plugin SHALL be compiled into the editor and enabled by the shipped configuration with the options `width` 30, `side` "left", `show_hidden` false, and `ignore` [".git", "build", "tmp"]. Its default binding SHALL be `<leader>e` in normal mode for `plugin.explorer.toggle`, given by the plugin, so a user binding of the same keys replaces it.

#### Scenario: Enabled with its options
- **WHEN** the editor starts with the shipped configuration
- **THEN** the explorer plugin is enabled and its `width` option reads "30"

#### Scenario: Disabled by the configuration
- **WHEN** the configuration sets plugins.explorer.enabled to false and `<leader>e` is pressed
- **THEN** no tree window opens

### Requirement: Toggling opens, focuses, or closes the tree
`<leader>e` and `:Explorer` SHALL open the tree in a side window of the configured width at the configured side when it is not shown in the current tab page and make it current, SHALL make it current when it is shown but another window is current, and SHALL close it when it is current. `plugin.explorer.focus` SHALL open or focus it and never close it.

#### Scenario: Open
- **WHEN** the editor shows "a.txt" in an 80-column terminal and `<leader>e` is pressed
- **THEN** a 30-column window at the left shows the tree and is current, and the other window shows "a.txt"

#### Scenario: Focus from the file window
- **WHEN** the tree is open, `<C-w>l` moves to the file window, and `<leader>e` is pressed
- **THEN** the tree window is current again and there are still two windows

#### Scenario: Close from the tree
- **WHEN** the tree is current and `<leader>e` is pressed
- **THEN** the tree window closes and one window remains

#### Scenario: Ex command toggles
- **WHEN** ":Explorer" is run twice
- **THEN** the tree opens and then closes

#### Scenario: Right side
- **WHEN** the configuration sets the `side` option to "right" and the tree is opened
- **THEN** the tree window is at the right edge

### Requirement: The tree lists the root and its entries in order
The first line SHALL be the open folder icon and the name of the root, which is the working directory when the tree first opens. Each entry of an expanded directory SHALL follow it on its own line, indented two spaces per level below the root, as the entry's icon, a space, and its name; directories SHALL come before files, and each group SHALL be sorted by name ignoring case. Every line SHALL start with a one-cell marker column.

#### Scenario: Top level
- **WHEN** the working directory "proj" holds "b.rb", "Lib/", "a.md", and "docs/", and the tree is opened with the ascii icon set
- **THEN** the lines are " - proj", "   + docs", "   + Lib", "   m a.md", and "   r b.rb"

#### Scenario: Nested
- **WHEN** "docs" is expanded and holds "guide.md"
- **THEN** the line after "   - docs" is "     m guide.md"

### Requirement: Hidden and ignored entries are filtered
Entries whose name starts with "." SHALL be hidden unless the `show_hidden` option is true or `H` toggled them on, and entries whose name is in the `ignore` option SHALL never be shown. `H` SHALL toggle hidden entries and redraw the tree.

#### Scenario: Hidden by default
- **WHEN** the root holds ".env", ".git/", and "a.rb"
- **THEN** only "a.rb" is listed

#### Scenario: Toggle hidden
- **WHEN** `H` is pressed in the tree
- **THEN** ".env" is listed and ".git" is still not

### Requirement: Icons come from the icon table by name
Each line SHALL use the configured icon set: folder_closed or folder_open for a directory by its state, symlink for a symbolic link, and for a file the icon of its type: ruby for ".rb", json for ".json", markdown for ".md", toml for ".toml", makefile for "Makefile", shell for ".sh", c for ".c" and ".h", yaml for ".yml" and ".yaml", git for ".gitignore", ".gitattributes", and ".gitmodules", lock for ".lock", and default otherwise.

#### Scenario: Unicode set
- **WHEN** the icons option is "unicode" and the root holds "a.rb" and "src/"
- **THEN** the lines are " ▾ proj", "   ▸ src", and "   ◈ a.rb"

#### Scenario: Nerd set
- **WHEN** the icons option is "nerd" and the root holds "Makefile"
- **THEN** its line holds the makefile glyph of the nerd set before " Makefile"

#### Scenario: Symlink
- **WHEN** the root holds a symbolic link "link"
- **THEN** its line uses the symlink icon

### Requirement: The current file is marked and revealed
The line of the file shown in the current window SHALL carry the `current` icon in the marker column, and the directories between the root and that file SHALL be expanded, when the tree opens and whenever another file becomes current. A file outside the root, an unnamed buffer, or a plugin window SHALL change nothing.

#### Scenario: Revealed on open
- **WHEN** the editor shows "lib/deep/x.rb" and the tree is opened with the ascii set
- **THEN** "lib" and "deep" are expanded, the line of "x.rb" starts with ">", and the tree's cursor is on it

#### Scenario: Follows another file
- **WHEN** the tree is open and ":e docs/guide.md" is run in the file window
- **THEN** "docs" is expanded and the line of "guide.md" is marked

### Requirement: Enter and l open a file or expand a directory
`<CR>` and `l` on a file SHALL show it in the previously used window that shows a file, or the first such window in layout order, make that window current, and show the opened message; on a directory they SHALL expand it. `o` SHALL toggle a directory and open a file as `<CR>` does. When no window of the tab page shows a file, the file SHALL be shown in a new window beside the tree, which keeps its width.

#### Scenario: Open a file
- **WHEN** the cursor in the tree is on "b.rb" and `<CR>` is pressed
- **THEN** the file window shows "b.rb", is current, and the tree is still open

#### Scenario: Expand and collapse with o
- **WHEN** `o` is pressed twice on "docs"
- **THEN** "docs" is expanded after the first and collapsed after the second

#### Scenario: Only the tree is left
- **WHEN** the file window was closed with `<C-w>c`, leaving only the tree, and `<CR>` is pressed on "b.rb"
- **THEN** there are two windows, the tree is 30 columns wide, and the other window shows "b.rb"

### Requirement: h collapses or moves to the parent
`h` on an expanded directory SHALL collapse it; on a file or a collapsed directory it SHALL move the cursor to the line of its parent directory; on the root line it SHALL do nothing.

#### Scenario: Collapse
- **WHEN** "docs" is expanded and `h` is pressed on it
- **THEN** "docs" is collapsed

#### Scenario: Parent
- **WHEN** the cursor is on "guide.md" inside "docs" and `h` is pressed
- **THEN** the cursor is on the line of "docs"

### Requirement: Files open in splits and tab pages
`s` and `v` on a file SHALL open it in a new window split horizontally or vertically from the previously used file window, and `t` SHALL open it in a new tab page; on a directory they SHALL do nothing.

#### Scenario: Horizontal split
- **WHEN** `s` is pressed on "b.rb" with the tree and one file window
- **THEN** there are three windows and the current one shows "b.rb"

#### Scenario: Vertical split
- **WHEN** `v` is pressed on "b.rb"
- **THEN** there are three windows side by side and the current one shows "b.rb"

#### Scenario: Tab page
- **WHEN** `t` is pressed on "b.rb"
- **THEN** there are two tab pages and the current one shows "b.rb"

### Requirement: a creates a file or a directory
`a` SHALL prompt for a name in the command-line row and create, under the directory of the entry under the cursor (the entry itself when it is a directory, the root on the root line), an empty file, or a directory when the name ends with "/"; the tree SHALL be redrawn with that directory expanded and the cursor on the new entry. An empty name, Escape, or a refusal from the host SHALL create nothing, a refusal showing its message as an error.

#### Scenario: Create a file
- **WHEN** `a` is pressed on the root line and "new.rb" Enter is typed
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
`r` SHALL prompt for a new name with the current name as the initial text and rename the entry in its directory; an open buffer of the renamed file SHALL show the new path. A name with a path separator, an empty name, an existing name, or the root line SHALL be refused with a message.

#### Scenario: Rename an open file
- **WHEN** "b.rb" is open in the file window and `r` is pressed on it, the text is cleared, and "c.rb" Enter is typed
- **THEN** "c.rb" exists, "b.rb" does not, and the file window's buffer path is "c.rb"

#### Scenario: Separator refused
- **WHEN** a rename to "x/y.rb" is typed
- **THEN** the message is "Name contains a path separator: x/y.rb" and nothing changed on disk

### Requirement: d deletes after confirmation
`d` SHALL ask "Delete <name>? (y/n): " and delete a file or an empty directory when the answer is "y" or "yes" in any case; any other answer or Escape SHALL show "Delete cancelled" and delete nothing. A non-empty directory SHALL be refused with "Directory not empty: <path>". An open buffer of the deleted file SHALL stay and become modified.

#### Scenario: Confirmed
- **WHEN** `d` is pressed on "a.md" and "y" Enter is typed
- **THEN** "a.md" no longer exists and is not listed

#### Scenario: Declined
- **WHEN** `d` is pressed on "a.md" and "n" Enter is typed
- **THEN** "a.md" still exists and the message is "Delete cancelled"

#### Scenario: Non-empty directory
- **WHEN** `d` is pressed on "docs", which holds a file, and "y" Enter is typed
- **THEN** "docs" still exists and the message is "Directory not empty: docs"

#### Scenario: Open buffer becomes modified
- **WHEN** "a.md" is open in the file window and is deleted from the tree
- **THEN** the buffer is still listed and is modified

### Requirement: The root moves up and down
`-` SHALL make the parent of the root the new root, keeping the old root expanded; `C` SHALL make the directory under the cursor, or the directory of the file under the cursor, the new root.

#### Scenario: Up
- **WHEN** the root is "/home/ada/proj" and `-` is pressed
- **THEN** the first line names "ada" and "proj" is listed expanded

#### Scenario: Into a directory
- **WHEN** `C` is pressed on "docs"
- **THEN** the first line names "docs"

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
- **THEN** the message row starts with "<CR>/l open"

#### Scenario: Movement falls through
- **WHEN** `j` is pressed on the root line
- **THEN** the cursor is on row 1 of the tree

### Requirement: ExplorerFind reveals the current file
`:ExplorerFind` SHALL open the tree when it is not shown, reveal and mark the current file, make the tree current, and put its cursor on that file's line.

#### Scenario: Find from the file window
- **WHEN** the tree is open but collapsed, the file window shows "lib/deep/x.rb", and ":ExplorerFind" is run
- **THEN** the tree is current with its cursor on the line of "x.rb"

### Requirement: The tree window keeps its width and quits with the editor
The tree window SHALL keep its width on `<C-w>=` and on terminal resizes, `<C-w>h` and `<C-w>l` SHALL move between it and the file window, ":q" in the tree SHALL close only the tree, and ":q" in the last file window SHALL end the editor even while the tree is open.

#### Scenario: Equalize
- **WHEN** the tree is open, the file window is split vertically, and `<C-w>=` is pressed
- **THEN** the tree is still 30 columns wide

#### Scenario: Quit with the tree open
- **WHEN** the tree is open, `<C-w>l` moves to the file window, and ":q" is run on an unmodified buffer
- **THEN** the editor ends
