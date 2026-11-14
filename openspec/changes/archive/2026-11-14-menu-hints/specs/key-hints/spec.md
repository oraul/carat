## MODIFIED Requirements

### Requirement: A waiting prefix shows the next keys
In normal, visual, and operator-pending mode, when the keys typed so far begin a longer binding of the mode's keymap and are not bound themselves, and no key arrives for `option.keyhints.delay` milliseconds, the editor SHALL show a bordered float titled with the keys and the prefix's group name, centered at the bottom of the editor above the message row, with one row per key that may follow, in the keymap's order.

#### Scenario: Leader hints
- **WHEN** the default configuration is loaded on "a.txt" in a 24-row terminal, Space is typed, and the delay passes with no key
- **THEN** a float shows rows such as "w  windows", "q  quit", "f  files", "b  buffers", and "d  docs"

#### Scenario: Group hints list actions
- **WHEN** Space and "w" are typed and the delay passes
- **THEN** the float lists "s  Split window" and "v  Split window vertically" among the window keys, with the descriptions the actions are registered with

#### Scenario: No hint before the delay
- **WHEN** Space is typed and the next key arrives before the delay passed
- **THEN** no float ever shows

#### Scenario: The hints are a centered bottom panel
- **WHEN** Space is typed on an 80 by 24 screen and the delay passes, then the screen is resized to 60 columns
- **THEN** the hints box has as many columns on its left as on its right, give or take one, its bottom border is on the row above the margin over the message row, and after the resize it is centered on the 60 columns

### Requirement: Each hint row names what its key does
Each hint row SHALL show the key in Vim notation, then the description of the action it runs, the group name of a key that begins more bindings, or the replayed keys of a key-sequence binding. A list taller than the room above the message row SHALL fill several columns, and what does not fit SHALL be left out.

#### Scenario: A group without a name
- **WHEN** the configuration binds `<leader>xa` to `cursor.up` and `<leader>xb` to `cursor.down` with no group line for `<leader>x`, Space is typed, and the delay passes
- **THEN** the leader hints show "x  cursor"

#### Scenario: Ctrl-W in columns
- **WHEN** `<C-w>` is typed in a 12-row terminal and the delay passes
- **THEN** the float lists every `<C-w>` key in more than one column

## ADDED Requirements

### Requirement: An unnamed group is named by its actions
A key that begins more bindings and that no `keymap.group` line names SHALL show, in its hint row, the first dotted segment shared by every action bound under it, or `group` when the actions share none or a key sequence is bound under it.

#### Scenario: A group of mixed actions
- **WHEN** the configuration binds `<leader>xa` to `cursor.up` and `<leader>xb` to `window.split`, or `<leader>xa` to the keys `:w<CR>`, with no group line, Space is typed, and the delay passes
- **THEN** the leader hints show "x  group"
