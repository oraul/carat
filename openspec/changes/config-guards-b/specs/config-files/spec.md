## MODIFIED Requirements

### Requirement: A project file cannot bind keys to key sequences
A keymap line in the project file whose action is a key sequence to replay SHALL be reported as "key sequences are not read from a project file" and ignored, because a replay can run any ex command, a write to any path included. The same line in the defaults or the user file SHALL be accepted, and the project file SHALL still bind keys to the action names a project file may bind and `none`.

#### Scenario: Key sequence in the project file
- **WHEN** the project file's first line is "keymap.normal j :e<Space>.git/config<CR>"
- **THEN** ".caratrc:1: key sequences are not read from a project file" is reported and "j" still moves down

#### Scenario: Action binding in the project file
- **WHEN** the project file holds "keymap.normal K cursor.down"
- **THEN** "K" moves down and nothing is reported

### Requirement: A project file cannot bind keys to a write, a quit, or the command line
A keymap line in the project file, in any mode, SHALL bind only an action a project file may bind: a cursor, motion, operator, text object, visual, insert, completion, fold, scroll, search, history, register, jump, buffer, tab, tabline, layout, docs, definition, palette, float, message, substitute, or mode action, or a window action but `window.quit`. Any other action SHALL be reported as "<action> is not bound from a project file" and ignored; the defaults and the user file SHALL bind it.

#### Scenario: A write or quit binding in the project file
- **WHEN** the project file's first line is "keymap.normal j file.save" and its second "keymap.insert x quit.write_all"
- **THEN** ".caratrc:1: file.save is not bound from a project file" and ".caratrc:2: quit.write_all is not bound from a project file" are reported, and neither binding is kept

#### Scenario: A command-line binding in any mode
- **WHEN** the project file's first line is "keymap.cmdline <Space> cmdline.execute" and its second "keymap.normal k cmdline.history_older"
- **THEN** both lines are reported as not bound from a project file and neither binding is kept

#### Scenario: A plugin's file action in the project file
- **WHEN** the project file's first line is "keymap.normal x plugin.explorer.delete"
- **THEN** ".caratrc:1: plugin.explorer.delete is not bound from a project file" is reported and "x" still deletes a character

#### Scenario: The user file binds a write, the project file unbinds one
- **WHEN** the user file holds "keymap.normal Q quit.all" and the project file holds "keymap.normal ZZ none" and "keymap.normal K cursor.down"
- **THEN** all three lines are kept and nothing is reported

## ADDED Requirements

### Requirement: A project file cannot take a key from a write, a quit, or the command line
A keymap line in the project file, `none` included, whose keys the defaults or the user file bind to an action or key sequence a project file could not bind, or to `mode.cmdline`, SHALL be reported as "<keys> runs <action>, which a project file may not unbind or rebind" and ignored, keys comparing by the keys they spell under the leader. The project file SHALL still unbind or rebind any other key.

#### Scenario: The project file unbinds the command line
- **WHEN** the project file's first line is "keymap.normal : none"
- **THEN** ".caratrc:1: : runs mode.cmdline, which a project file may not unbind or rebind" is reported and ":" still opens the command line

#### Scenario: The project file takes the user's quit or the leader's save
- **WHEN** the user file holds "keymap.normal Q quit.all" and the project file holds "keymap.normal Q none" and "keymap.normal <Space>fs cursor.down"
- **THEN** ".caratrc:1: Q runs quit.all, which a project file may not unbind or rebind" and ".caratrc:2: <Space>fs runs file.save, which a project file may not unbind or rebind" are reported, and "Q" and "<leader>fs" keep their actions

#### Scenario: A key the user freed
- **WHEN** the user file holds "keymap.normal <C-s> none" and the project file "keymap.normal <C-s> cursor.down"
- **THEN** both lines are kept and nothing is reported

### Requirement: A project file binds a prompt only in normal and visual modes
A keymap line in the project file binding `mode.cmdline` or `palette.open`, whose prompt runs what is typed next, SHALL be kept only in the normal, visual, visual_line, and visual_block modes; in any other mode it SHALL be reported as "<action> is not bound in <mode> mode from a project file" and ignored.

#### Scenario: The project file binds a prompt outside normal and visual
- **WHEN** the project file's first line is "keymap.insert <CR> mode.cmdline" and its second "keymap.visual_line <F2> palette.open"
- **THEN** ".caratrc:1: mode.cmdline is not bound in insert mode from a project file" is reported and the second line is kept

### Requirement: A project file cannot bind keys around a held key
A keymap line in the project file, `none` excepted, whose keys start with keys held from the project file, or are a proper prefix of them, SHALL be reported as "<keys> overlaps keys that run <action>, which a project file may not unbind or rebind" and ignored, since it would make the held keys a prefix or wait on them.

#### Scenario: The project file binds keys around a held key
- **WHEN** the project file's first line is "keymap.normal :w cursor.down", its second "keymap.normal <Space>q cursor.down", and its third "keymap.normal <C-w>qa none"
- **THEN** ".caratrc:1: :w overlaps keys that run mode.cmdline, which a project file may not unbind or rebind" and ".caratrc:2: <Space>q overlaps keys that run quit.all, which a project file may not unbind or rebind" are reported, and the third line is kept
