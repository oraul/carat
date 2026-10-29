# Spec Delta

## MODIFIED Requirements

### Requirement: Reopening a shown scratch buffer focuses it
A request to open a scratch buffer whose title the plugin already shows in the current tab page SHALL replace that buffer's lines and make its window current instead of opening another window. When the buffer is shown only in another tab page, the request SHALL open a side window in the current tab page showing that same buffer with the new lines, so both tab pages show one buffer.

#### Scenario: Reopening focuses
- **WHEN** the plugin opens "list" again from the other window with new lines
- **THEN** there are still two windows, the side window is current, and it shows the new lines

#### Scenario: Another tab page
- **WHEN** "list" is shown in tab page 1 and the plugin opens it from tab page 2
- **THEN** tab page 2 has a side window showing "list", the buffer list holds one "list" buffer, and tab page 1 still shows it

## ADDED Requirements

### Requirement: Opening a file from a plugin keeps unsaved work
When a plugin opens a file in a window, a modified file buffer the window showed SHALL stay in the buffer list, hidden, rather than being dropped, and opening the file the window already shows SHALL leave its buffer as it is. When the window showed a scratch buffer, the window SHALL lose its fixed width.

#### Scenario: Modified buffer stays hidden
- **WHEN** "a.txt" is modified in window 2 and the plugin opens "b.txt" there
- **THEN** window 2 shows "b.txt" and "a.txt" is still listed and modified

#### Scenario: The same file is left alone
- **WHEN** window 2 shows "b.txt" with unsaved changes and the plugin opens "b.txt" there
- **THEN** window 2 is current and the buffer keeps its changes

#### Scenario: Side window becomes a file window
- **WHEN** the plugin opens "b.txt" in its own side window
- **THEN** that window shows "b.txt" and is no longer fixed-width

### Requirement: A side window shows no line numbers
A window showing a scratch buffer SHALL have no line number column whatever the `number` and `relativenumber` options say, as Neovim's tree plugins set `nonumber`; its sign column SHALL still appear while the buffer has signs.

#### Scenario: No numbers
- **WHEN** the `number` option is on and a plugin opens a side window with the lines ["l0", "l1"]
- **THEN** the side window's rows start with "l0" and "l1" at its first column
