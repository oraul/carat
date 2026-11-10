## MODIFIED Requirements

### Requirement: The definition target has a tab
The buffer a `gd` jump shows SHALL have a tab in the tab row like any file buffer's, wherever its file lies: shown, selected while it is current, reached by `:bn`, `:bp`, and `:b N`, and closed by `:bd`. With `option.jumptab keep` the buffer the jump left SHALL keep its tab too, as in Vim.

#### Scenario: gd to another project file shows its tab, selected
- **WHEN** `option.jumptab keep` is set and the answer is one location in `/project/b.rb`
- **THEN** `b.rb` is current and its tab is the selected one

#### Scenario: gd outside the project shows the target's tab, selected
- **WHEN** `option.jumptab keep` is set, the editor is on `a.rb`, and the answer is one location in `/gems/c.rb`
- **THEN** row 0 is the tab row with a tab for `a.rb` and one for `c.rb`, the `c.rb` tab selected, and two buffers are listed

#### Scenario: gd to a project file linked out of the project shows its tab, selected
- **WHEN** `option.jumptab keep` is set, `/project/out.rb` is a link to `/gems/c.rb`, and the answer is one location in `/project/out.rb`
- **THEN** a read-only buffer named `out.rb` is current and its tab is the selected one

#### Scenario: gd to an outside file already listed shows that buffer and its tab
- **WHEN** `option.jumptab keep` is set, `/gems/c.rb` was opened with `:e` and `:bp` went back to `a.rb`, and the answer is one location in `/gems/c.rb`
- **THEN** the listed buffer is shown with its tab selected and no second buffer is listed

#### Scenario: The read-only target's tab selects and closes like the others
- **WHEN** `option.jumptab keep` is set, `gd` showed `/gems/c.rb`, and `:bp`, `:bn`, and `:bd` are run in turn
- **THEN** `:bp` shows `a.rb` with its tab selected and the `c.rb` tab kept, `:bn` shows `c.rb` again with its tab selected, and `:bd` closes it, leaving one buffer listed

## ADDED Requirements

### Requirement: A definition jump takes over the tab it leaves
With `option.jumptab replace`, the shipped default, a `gd` jump or a pick-list choice to a target with no tab SHALL show it in the tab of the buffer it leaves, at its position, and that buffer SHALL lose its tab, still loaded. A target with a tab SHALL be selected, no other tab changing. A buffer another window shows SHALL keep its tab.

#### Scenario: gd to a project file takes over the tab it leaves
- **WHEN** the editor is on `a.rb` alone and the answer is one location in `/project/b.rb`
- **THEN** one tab remains, `b.rb`'s, and `b.rb` is current

#### Scenario: The target takes the tab's position and a tab opened with :e stays
- **WHEN** `lib/x.rb` was opened with `:e` and `:bp` went back to `a.rb`, and the answer is one location in `/project/b.rb`
- **THEN** the tabs are `b.rb` then `x.rb`, the `b.rb` tab selected

#### Scenario: A jump to a buffer with its own tab selects it and keeps both
- **WHEN** `b.rb` was opened with `:e` and `:bp` went back to `a.rb`, and the answer is one location in `/project/b.rb`
- **THEN** the tabs are `a.rb` then `b.rb`, the `b.rb` tab selected

#### Scenario: A buffer shown in a second window keeps its tab
- **WHEN** `a.rb` shows in two windows after `:split` and the answer is one location in `/project/b.rb`
- **THEN** the tabs are `a.rb` then `b.rb`

#### Scenario: option.jumptab keep keeps both tabs
- **WHEN** `option.jumptab keep` is set and the answer is one location in `/project/b.rb`
- **THEN** the tabs are `a.rb` then `b.rb`

#### Scenario: A target outside the project takes over the tab, read-only
- **WHEN** the answer is one location in `/gems/c.rb`
- **THEN** one tab remains, `c.rb`'s, and its buffer is read-only

#### Scenario: A target picked from the list takes over the tab
- **WHEN** the answer is two locations, in `/project/b.rb` and `/project/lib/x.rb`, and Enter picks the first
- **THEN** one tab remains, `b.rb`'s

### Requirement: option.jumptab takes replace or keep
`option.jumptab` SHALL take `replace` or `keep`; any other word SHALL be reported as `file:line: unknown jumptab mode WORD` and keep the earlier value.

#### Scenario: An unknown jumptab mode is refused and keeps the earlier value
- **WHEN** the configuration holds `option.jumptab sometimes`
- **THEN** the report reads `.caratrc:1: unknown jumptab mode sometimes` and the option keeps its value
