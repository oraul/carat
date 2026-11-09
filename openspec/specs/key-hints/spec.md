# key-hints Specification

## Purpose
The key hints of normal, visual, and operator-pending modes: after a key that begins longer bindings waits, a float lists what may follow, so a user finds a command by pressing its group's key and reading the list.

## Requirements

### Requirement: A waiting prefix shows the next keys
In normal, visual, and operator-pending mode, when the keys typed so far begin at least one longer binding of the mode's keymap and are not bound themselves (so they wait with no time limit), and no further key arrives for `option.keyhints.delay` milliseconds, the editor SHALL show a bordered float titled with the keys typed so far and the prefix's group name when it has one, at the bottom right of the editor above the message row, with one row per key that may follow, in the keymap's order.

#### Scenario: Leader hints
- **WHEN** the default configuration is loaded on "a.txt" in a 24-row terminal, Space is typed, and the delay passes with no key
- **THEN** a float shows rows such as "w  windows", "q  quit", "f  files", "b  buffers", and "d  docs"

#### Scenario: Group hints list actions
- **WHEN** Space and "w" are typed and the delay passes
- **THEN** the float lists "s  Split window" and "v  Split window vertically" among the window keys, with the descriptions the actions are registered with

#### Scenario: No hint before the delay
- **WHEN** Space is typed and the next key arrives before the delay passed
- **THEN** no float ever shows

### Requirement: Each hint row names what its key does
Each hint row SHALL show the key in Vim notation, then the description of the action it runs, the group name of a key that begins more bindings (`+` and the count of its bindings when no group names it), or the replayed keys of a key-sequence binding. A list taller than the room above the message row SHALL fill several columns, and what does not fit SHALL be left out.

#### Scenario: A group without a name
- **WHEN** the configuration binds `<leader>xa` and `<leader>xb` with no group line for `<leader>x`, Space is typed, and the delay passes
- **THEN** the leader hints show "x  +2"

#### Scenario: Ctrl-W in columns
- **WHEN** `<C-w>` is typed in a 12-row terminal and the delay passes
- **THEN** the float lists every `<C-w>` key in more than one column

### Requirement: The next key closes the hints
The hints float SHALL close on the next key, which is then handled as it would be with no float: it completes, continues, or cancels the binding, and Esc cancels the pending keys. When the keys still begin a longer binding after it, the hints SHALL show again for the longer keys once the delay passes.

#### Scenario: A key completes the binding
- **WHEN** the leader hints show and "w", then "s" are typed
- **THEN** the hints float is gone and two windows show

#### Scenario: Esc cancels
- **WHEN** the leader hints show and Esc is typed
- **THEN** no float shows, no key is pending, and the editor is in normal mode

#### Scenario: The next level shows after the delay
- **WHEN** the leader hints show, "w" is typed, and the delay passes again
- **THEN** a float titled with the leader, "w", and "windows" lists the window keys

### Requirement: A bound prefix waits for timeoutlen without hints
Keys that are bound and also begin a longer binding SHALL show no hints; `timeoutlen` SHALL resolve them as before.

#### Scenario: Bound prefix
- **WHEN** the configuration binds `<leader>x` and `<leader>xa`, Space and "x" are typed, and `timeoutlen` passes
- **THEN** no float showed and the action of `<leader>x` ran

### Requirement: keyhints.delay sets the wait
`option.keyhints.delay` SHALL take a number of milliseconds from 0 to 10000, 300 by default; 0 SHALL turn the hints off. A value of another kind or outside the range SHALL be reported as `file:line: option.keyhints.delay takes a number from 0 to 10000` and leave the value before it.

#### Scenario: Off
- **WHEN** the configuration holds `option.keyhints.delay 0`, Space is typed, and a second passes with no key
- **THEN** no float shows

#### Scenario: Out of range
- **WHEN** a configuration line is `option.keyhints.delay 20000`
- **THEN** the problem `.caratrc:1: option.keyhints.delay takes a number from 0 to 10000` is reported and the delay stays 300

### Requirement: keymap.group names a prefix
A configuration line `keymap.group <keys> <name>` SHALL name the normal-mode prefix the keys spell, in Vim notation with `<leader>`, for the hints; a later line for the same keys wins, and a project file's group line SHALL be read, as it binds nothing: a group line SHALL NOT change what any key looks up. A line without exactly keys and a name SHALL be reported as `file:line: keymap.group takes keys and a name`.

#### Scenario: A user names a group
- **WHEN** the user file holds `keymap.group <leader>w panes` and Space is typed and the delay passes
- **THEN** the leader hints show "w  panes"

#### Scenario: A group under a bound key
- **WHEN** `j` is bound to `cursor.down` and a configuration line is `keymap.group jk x`
- **THEN** `j` still matches at once, with no wait for a second key

#### Scenario: A malformed group line
- **WHEN** a configuration line is `keymap.group <leader>w`
- **THEN** the problem `.caratrc:1: keymap.group takes keys and a name` is reported

### Requirement: The defaults name the shipped groups
The default configuration SHALL name the leader groups `w` windows, `q` quit, `f` files, `b` buffers, `d` docs, and the prefixes `g` goto, `z` view, and `<C-w>` window.

#### Scenario: Shipped groups
- **WHEN** `g` is typed with the default configuration and the delay passes
- **THEN** the float's title is "g goto" and the leader hints, opened later, show "w  windows"

### Requirement: Hints cost nothing while none shows
A key typed while no hints float shows and no key is pending SHALL allocate nothing more than before this capability, and the editor SHALL read the clock for the hints only when a key is pending.

#### Scenario: Benchmark held
- **WHEN** `make bench` runs the `lh` and `j` scenarios
- **THEN** their allocations per key equal main's recorded figures

### Requirement: A hint row is cut by display cells

Each hint row SHALL be cut at a character boundary to at most the float's width in terminal cells, so text of wide characters never reaches past the float's box, and a combining mark SHALL stay with the character before it.

#### Scenario: A remap of wide characters

- **WHEN** `<leader>xa` is remapped to a text of fifty wide characters on an 80-column screen and the user waits after `<Space>x`
- **THEN** the hints float shows the `a` row cut to at most 78 cells, its box no wider than 78 cells, and the editor keeps running
