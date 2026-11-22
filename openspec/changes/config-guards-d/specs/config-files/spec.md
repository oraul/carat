## ADDED Requirements

### Requirement: A project file cannot leave a text-entry mode
A project file's keymap line in the insert, replace, cmdline, or completion mode SHALL bind only an insert or completion action, an arrow's cursor action, or a page scroll; any other action, `mode.normal` included, SHALL be reported as "<action> is not bound in <mode> mode from a project file" and ignored. Such a mode's keys the defaults or the user file bind to another action, or to `completion.close`, SHALL be held.

#### Scenario: The project file binds insert-mode Enter to normal mode
- **WHEN** the project file's first line is "keymap.insert <CR> mode.normal" and its second "keymap.insert <C-k> cursor.down"
- **THEN** ".caratrc:1: mode.normal is not bound in insert mode from a project file" is reported, `<CR>` still splits the line, and the second line is kept

#### Scenario: The project file unbinds insert-mode Escape
- **WHEN** the project file's first line is "keymap.insert <Esc> none"
- **THEN** ".caratrc:1: <Esc> runs mode.normal, which a project file may not unbind or rebind" is reported and `<Esc>` still leaves insert mode

### Requirement: A project file cannot open a prompt from keys typed while editing text
A keymap line in the project file binding `mode.cmdline` or `palette.open` to keys none of which is a function key, an Alt key, or a control key other than Tab, Enter, Backspace, and Escape SHALL be reported as "<keys> is typed while editing text, so a project file may not bind it to <action>" and ignored; keys holding a function, control, or Alt key SHALL be kept.

#### Scenario: The project file binds a prompt to keys typed while editing text
- **WHEN** the project file's first line is "keymap.normal ; mode.cmdline", its second "keymap.normal <Space>x palette.open", and its third "keymap.normal <C-k>p palette.open"
- **THEN** ".caratrc:1: ; is typed while editing text, so a project file may not bind it to mode.cmdline" and ".caratrc:2: <Space>x is typed while editing text, so a project file may not bind it to palette.open" are reported, and the third line is kept
