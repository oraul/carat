## ADDED Requirements

### Requirement: A project file is refused when it is a link at the open
The project file SHALL be opened without following a symbolic link, so a project file that is a link when it is opened, after a check that found a regular file, SHALL be reported as ".caratrc: cannot be read" and not read. The user file MAY be a link and SHALL still be read through it.

#### Scenario: A project file swapped for a link after the check
- **WHEN** the project file is a regular file holding "option.tabstop 3" when it is checked and a symbolic link when it is opened
- **THEN** ".caratrc: cannot be read" is reported and tabstop keeps the value before it

#### Scenario: A link is refused by the open
- **WHEN** a path that is a symbolic link to a regular file is read without following links
- **THEN** the read raises, while the plain read gives the file's text

### Requirement: A project file cannot bind keys to a write, a quit, or the command line
A keymap line in the project file, in any mode, whose action writes the buffer or quits (`file.save`, `quit.all`, `quit.write_all`, `window.quit`) or is a command-line action SHALL be reported as "write, quit, and command-line actions are not bound from a project file" and ignored. The same line in the defaults or the user file SHALL be accepted, and the project file SHALL still unbind those keys with `none` and bind keys to other action names.

#### Scenario: A write or quit binding in the project file
- **WHEN** the project file's first line is "keymap.normal j file.save" and its second "keymap.insert x quit.write_all"
- **THEN** ".caratrc:1: write, quit, and command-line actions are not bound from a project file" and the same for line 2 are reported, and neither binding is kept

#### Scenario: A command-line binding in any mode
- **WHEN** the project file's first line is "keymap.cmdline <Space> cmdline.execute" and its second "keymap.normal k cmdline.history_older"
- **THEN** both lines are reported with the same message and neither binding is kept

#### Scenario: The user file binds a write, the project file unbinds one
- **WHEN** the user file holds "keymap.normal Q quit.all" and the project file holds "keymap.normal ZZ none" and "keymap.normal K cursor.down"
- **THEN** all three lines are kept and nothing is reported

### Requirement: A project file cannot set the leader
A `keymap.leader` line in the project file SHALL be reported as "keymap.leader is not read from a project file" and ignored, so the `<leader>` bindings of the defaults and the user file, `<leader>fs file.save` and `<leader>qw quit.write_all` among them, keep the leader the defaults or the user file set. The same line in the defaults or the user file SHALL be accepted.

#### Scenario: A project leader leaves the leader bindings where they were
- **WHEN** the user file holds "keymap.leader ," and the project file "keymap.leader d"
- **THEN** ".caratrc:1: keymap.leader is not read from a project file" is reported and the leader stays ",", so `<leader>fs` and `<leader>qw` stay `,fs` and `,qw`

### Requirement: Line, wait, and undo numbers are bounded
`option.scroll` and `option.scrolloff` SHALL take a number of lines from 0 to 9999, `option.timeoutlen` a number of milliseconds from 0 to 10000, and `option.undolevels` a number from 0 to 10000. A value outside its range SHALL be reported as `file:line: option.<name> takes a number from <low> to <high>` and leave the value before it.

#### Scenario: Numbers past the limits
- **WHEN** the project file sets scroll to 10000, scrolloff to 999999999, timeoutlen to 10001, and undolevels to 999999999
- **THEN** each line is reported with its range and each option keeps the value before it

#### Scenario: The limits themselves
- **WHEN** the project file sets scroll and scrolloff to 9999, timeoutlen to 10000, and undolevels to 10000
- **THEN** the options take those values and nothing is reported
