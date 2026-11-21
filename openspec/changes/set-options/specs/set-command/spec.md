## ADDED Requirements

### Requirement: Number options are set with set
`:se[t]` SHALL take the number options `tabstop` (`ts`), `shiftwidth` (`sw`), `scroll` (`scr`), `scrolloff` (`so`), `timeoutlen` (`tm`), `undolevels` (`ul`), and `showtabline` (`stal`) as `name=N`, `name+=N` (add), `name-=N` (subtract), and `name^=N` (multiply); `name?` and the bare name SHALL show `  name=N`.

#### Scenario: Setting a number
- **WHEN** `:set ts=4` is run
- **THEN** `:set ts?` shows `  tabstop=4`

#### Scenario: Adding, subtracting, and multiplying a number
- **WHEN** `:set sw=2`, then `:set sw+=3`, `:set sw-=1`, and `:set sw^=2` are run
- **THEN** `:set sw?` shows `  shiftwidth=5`, then `  shiftwidth=4`, then `  shiftwidth=8`

### Requirement: A refused number keeps the old value
A value that is not a number SHALL be refused with `E521: Number required after =: <argument>`, and a result the option's `option.*` line would refuse with `E474: Invalid argument: <argument>`; either SHALL keep the option's value.

#### Scenario: A number out of range keeps the old value
- **WHEN** `:set ts=0` or `:set stal=3` is run
- **THEN** the message row shows `E474: Invalid argument: ts=0` or `E474: Invalid argument: stal=3` and the option keeps its value

#### Scenario: A value that is not a number
- **WHEN** `:set ts=x` is run
- **THEN** the message row shows `E521: Number required after =: ts=x` and `tabstop` keeps its value

### Requirement: Flag options take Vim's boolean forms
`:se[t]` SHALL take the flags `number` (`nu`), `relativenumber` (`rnu`), `expandtab` (`et`), `autoindent` (`ai`), `list`, `startscreen`, and `reducedmotion` in Vim's boolean forms: `name` turns it on, `noname` off, `invname` and `name!` switch it, and `name?` shows `  name` or `noname`. A value (`name=x`) SHALL be refused with `E474: Invalid argument: <argument>`, and a `no` or `inv` prefix or a trailing `!` on an option that is not a flag likewise.

#### Scenario: Turning a flag on, off, and over
- **WHEN** `:set nonu`, then `:set nu`, then `:set invnu`, then `:set nu!` are run
- **THEN** `:set nu?` shows `nonumber`, then `  number`, then `nonumber`, then `  number`

#### Scenario: A value for a flag
- **WHEN** `:set et=1` is run
- **THEN** the message row shows `E474: Invalid argument: et=1`

#### Scenario: A flag prefix on a number
- **WHEN** `:set nots` is run
- **THEN** the message row shows `E474: Invalid argument: nots`

### Requirement: Word options are set with set
`:se[t]` SHALL take the word options `listchars` (`lcs`), `winborder`, `icons`, and `breadcrumbs` as `name=value`; `name?` and the bare name SHALL show `  name=value`. A backslash before a blank or a backslash SHALL keep it in the value. A value the option's `option.*` line would refuse SHALL be refused with `E474: Invalid argument: <argument>` and keep the value. `name+=`, `name-=`, and `name^=` on a word option SHALL answer `Not implemented: :set <argument>`.

#### Scenario: Setting a word
- **WHEN** `:set winborder=single` is run
- **THEN** `:set winborder?` shows `  winborder=single`

#### Scenario: A word the configuration refuses
- **WHEN** `:set icons=emoji` is run
- **THEN** the message row shows `E474: Invalid argument: icons=emoji` and `icons` keeps its value

#### Scenario: A blank kept by a backslash
- **WHEN** `:set lcs=tab:>\ ,trail:-` is run
- **THEN** `:set lcs?` shows `  listchars=tab:> ,trail:-`

### Requirement: An option is reset to its shipped default
`:se[t] name&` SHALL set an option `:set` handles to the value the shipped configuration gives it.

#### Scenario: Resetting an option
- **WHEN** `:set ts=7` and then `:set ts&` are run
- **THEN** `:set ts?` shows `  tabstop=2`, the shipped value

### Requirement: Set lists the options
A bare `:se[t]` SHALL list, under `--- Options ---`, every option `:set` handles whose value differs from its shipped default, and the current buffer's `filetype` and `syntax` when they are not empty; `:set all` SHALL list every option `:set` handles. Each is shown as `name?` shows it, in alphabetical order, one per line.

#### Scenario: A bare set lists the changed options
- **WHEN** `:set ts=4 nonu` and then `:set` are run in a buffer with no filetype
- **THEN** the message shows `--- Options ---`, `nonumber`, and `  tabstop=4`, and no other option

#### Scenario: Set all lists every option
- **WHEN** `:set all` is run
- **THEN** the message shows `--- Options ---` and a line for every option `:set` handles, `  tabstop=2` among them

### Requirement: A set option shows at once
An option changed by `:set` SHALL take effect from the next key: the frame is drawn with it, the number column appears or goes, a tab is drawn at the new `tabstop`, and a new `undolevels` limits the undo states recorded after it. An option read only when the editor starts, `startscreen`, SHALL answer `Not implemented: :set startscreen live` to every form that would change it and keep its value.

#### Scenario: The number column follows set number
- **WHEN** `:set nonu` and then `:set nu` are run in a window of a file
- **THEN** the first row starts with the text after the first command and with the line number after the second

#### Scenario: A tab is drawn at the new tabstop
- **WHEN** `:set ts=4` is run in a buffer whose first line is a tab and `x`
- **THEN** `x` is drawn four columns after the start of the text

#### Scenario: Fewer undo levels
- **WHEN** `:set ul=1` is run and three changes are made
- **THEN** `u` twice undoes only the last change and shows Neovim's oldest-change message

#### Scenario: startscreen is read only at startup
- **WHEN** `:set nostartscreen` is run
- **THEN** the message row shows `Not implemented: :set startscreen live` and `:set startscreen?` shows `  startscreen`
