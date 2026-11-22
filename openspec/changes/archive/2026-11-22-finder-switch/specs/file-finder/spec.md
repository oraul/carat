## ADDED Requirements

### Requirement: Ctrl-G switches between the file finder and the grep picker
While a picker's prompt is open, `<C-g>` SHALL close the picker and open the file finder when it was the grep picker, or the grep picker when it was the file finder, the buffer picker, or the recent files picker. The new picker SHALL show the text typed so far on its prompt, list its rows filtered by it, and highlight the first row. The key SHALL be one of the prompt's keys, which answer before the command-line keymap. No float of the closed picker SHALL remain.

#### Scenario: Ctrl-G switches the file finder to the grep picker
- **WHEN** the user typed `b` in the file finder and presses `<C-g>`
- **THEN** the prompt reads `> b` and the float is the grep picker's, listing the line of `lib/beta.rb`

#### Scenario: Ctrl-G switches the grep picker to the file finder
- **WHEN** the user typed `b` in the grep picker and presses `<C-g>`
- **THEN** the prompt reads `> b` and the float titled `Files 2/3` lists the files matching it

#### Scenario: Ctrl-G switches back and forth keeping the query
- **WHEN** the user typed `bet` in the file finder and presses `<C-g>` twice
- **THEN** the file finder is open on the prompt `> bet` with one float

#### Scenario: Ctrl-G with the empty prompt
- **WHEN** the user presses `<C-g>` in the file finder before typing
- **THEN** the grep picker opens on the empty prompt

#### Scenario: Ctrl-G from the buffer picker opens the grep picker
- **WHEN** the user typed `bet` in the buffer picker and presses `<C-g>`
- **THEN** the grep picker opens on the prompt `> bet`

#### Scenario: A switched picker is picked from as any other
- **WHEN** the user typed `bet`, pressed `<C-g>` twice, and presses Enter
- **THEN** `lib/beta.rb` opens in the editing window

#### Scenario: A switched picker is the one resumed
- **WHEN** the user typed `bet` in the file finder, pressed `<C-g>` and Esc, and presses `<Space>fR`
- **THEN** the grep picker opens again on the prompt `> bet`

### Requirement: Space f w greps the word under the cursor
In normal mode `<leader>fw` SHALL open the grep picker with the word under the cursor typed on its prompt, its rows filtered by it. The word SHALL be the run of ASCII letters, digits, underscores, and non-ASCII characters around the cursor's character column. With the cursor on no such character, or on a word that is not valid UTF-8, the grep picker SHALL open on the empty prompt. The key SHALL be a default binding of the plugin, which the configuration may replace.

#### Scenario: Space f w on a word opens the grep picker with it
- **WHEN** the cursor is on the `w` of `hello world` and the user presses `<Space>fw`
- **THEN** the grep picker opens on the prompt `> world` and lists the line

#### Scenario: Space f w takes the whole word
- **WHEN** the cursor is on the first character of `hello world` and the user presses `<Space>fw`
- **THEN** the prompt reads `> hello`

#### Scenario: Space f w on a multi-byte word
- **WHEN** the cursor is on the `é` of `café x` and the user presses `<Space>fw`
- **THEN** the prompt reads `> café`

#### Scenario: Space f w keeps underscores in the word
- **WHEN** the cursor is on `foo_bar baz` at its first character and the user presses `<Space>fw`
- **THEN** the prompt reads `> foo_bar`

#### Scenario: Space f w on a blank opens the grep picker empty
- **WHEN** the cursor is on the space of `hello world` and the user presses `<Space>fw`
- **THEN** the grep picker opens on the empty prompt

#### Scenario: Space f w in an empty buffer or on an empty line
- **WHEN** the buffer is empty, or the cursor is on an empty line, and the user presses `<Space>fw`
- **THEN** the grep picker opens on the empty prompt

#### Scenario: Space f w on the last character of the last line
- **WHEN** the cursor is on the last character of `hello world`, the last line, and the user presses `<Space>fw`
- **THEN** the prompt reads `> world`

#### Scenario: Ctrl-G after Space f w switches on the word
- **WHEN** the user pressed `<Space>fw` on `hello` and presses `<C-g>`
- **THEN** the file finder opens on the prompt `> hello`
