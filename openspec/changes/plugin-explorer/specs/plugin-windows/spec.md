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

### Requirement: A plugin focuses a window and opens a file in it
A plugin SHALL make window number n of the current tab page current, and SHALL open a file in window n as ":e" would there, the window numbers being the layout order counted from 1 with 0 meaning the current window; a number past the last window SHALL fail. A modified file buffer the window showed SHALL stay in the buffer list, hidden, rather than being dropped, and opening the file the window already shows SHALL leave its buffer as it is. When window n showed a scratch buffer, the window SHALL lose its fixed width.

#### Scenario: Open in the file window
- **WHEN** the side window is window 1 and the plugin opens "b.txt" in window 2
- **THEN** window 2 shows "b.txt" and is current

#### Scenario: Focus a missing window
- **WHEN** the plugin focuses window 9 with two windows
- **THEN** the response is failed and the current window is unchanged

#### Scenario: Modified buffer stays hidden
- **WHEN** "a.txt" is modified in window 2 and the plugin opens "b.txt" there
- **THEN** window 2 shows "b.txt" and "a.txt" is still listed and modified

#### Scenario: The same file is left alone
- **WHEN** window 2 shows "b.txt" with unsaved changes and the plugin opens "b.txt" there
- **THEN** window 2 is current and the buffer keeps its changes

#### Scenario: Side window becomes a file window
- **WHEN** the plugin opens "b.txt" in its own side window
- **THEN** that window shows "b.txt" and is no longer fixed-width

## ADDED Requirements

### Requirement: A side window shows no line numbers
A window showing a scratch buffer SHALL have no line number column whatever the `number` and `relativenumber` options say, as Neovim's tree plugins set `nonumber`; its sign column SHALL still appear while the buffer has signs.

#### Scenario: No numbers
- **WHEN** the `number` option is on and a plugin opens a side window with the lines ["l0", "l1"]
- **THEN** the side window's rows start with "l0" and "l1" at its first column
