# Spec Delta

## Purpose

Colors the text of a buffer by its language: the filetype of a buffer chooses a tokenizer plugin, the visible rows are highlighted from its tokens, and edits re-highlight only what they change.

## ADDED Requirements

### Requirement: The filetype is detected from the name and the first line
Every buffer SHALL have a filetype, empty when none is detected, taken from its file name when the buffer is opened or renamed: `ruby` for the extensions `.rb`, `.rake`, `.gemspec`, and `.ru` and the names `Gemfile`, `Rakefile`, and `config.ru`, or, when the name says nothing, a first line starting with `#!` whose interpreter is `ruby` directly or through `env`.

#### Scenario: Extension
- **WHEN** `lib/a.rb` is opened
- **THEN** the buffer's filetype is `ruby`

#### Scenario: Special name
- **WHEN** `Gemfile` is opened
- **THEN** the buffer's filetype is `ruby`

#### Scenario: Shebang
- **WHEN** a file `tool` whose first line is `#!/usr/bin/env ruby` is opened
- **THEN** the buffer's filetype is `ruby`

#### Scenario: Unknown file
- **WHEN** `notes.txt` is opened
- **THEN** the buffer's filetype is empty and the buffer is drawn in the normal highlight

### Requirement: The visible rows of a buffer are highlighted from its tokenizer
While syntax highlighting is on, a buffer whose syntax names a filetype that an enabled plugin tokenizes SHALL show each character of its visible rows in the highlight group of the token covering it and in the normal group elsewhere; the line number, sign column, selection, and cursor keep their own highlights.

#### Scenario: Ruby keywords and strings
- **WHEN** a file `a.rb` holding `def go = "hi" # note` is opened with the ruby plugin enabled
- **THEN** the cells of `def` are in the Define group, `go` in Function, `"hi"` in String, and `# note` in Comment

#### Scenario: Selection over a highlighted line
- **WHEN** `v` and `e` are pressed on a highlighted line
- **THEN** the selected cells are in the Visual group and the cells after the selection keep their token groups

### Requirement: Only visible rows and the rows above them are tokenized
A buffer SHALL be tokenized only as far as the last visible row of a window showing it: opening a file tokenizes its first screen, and a row further down is tokenized when a window shows it or a row below it, starting from the last row whose end state is known, never again from the top.

#### Scenario: Opening a large file
- **WHEN** a Ruby file of 100,000 lines is opened in a 60-row terminal
- **THEN** fewer than 100 rows are tokenized for the first frame

#### Scenario: Jumping to the end twice
- **WHEN** `G` is pressed, then `gg`, then `G` again
- **THEN** the second `G` tokenizes at most the rows of one screen

### Requirement: Edits re-highlight from the changed row until the state settles
After an edit, an undo, or a redo, the rows from the first changed row on SHALL be tokenized again until a row ends in the same state it ended in before the edit, below the last changed row; the rows after it keep their highlights without being tokenized.

#### Scenario: Typing inside a heredoc
- **WHEN** a character is typed in a line of a heredoc body
- **THEN** one row is tokenized and the rows after it keep their String highlight

#### Scenario: Opening a string
- **WHEN** a `"` is typed in front of a word on a code line followed by code lines
- **THEN** the rows after it are drawn in the String group up to the next `"`

#### Scenario: Undo restores the highlight
- **WHEN** the `"` is removed with `u`
- **THEN** the following rows are drawn with their code highlights again

### Requirement: Syntax highlighting is switched with the syntax command
`:sy[ntax] on` and `:syntax enable` SHALL turn highlighting on for every buffer and `:syntax off` SHALL turn it off, drawing every buffer in the normal group; highlighting starts on. Another argument SHALL be refused with `E410: Invalid :syntax subcommand: <argument>`, and `:syntax` alone SHALL answer `Not implemented: :syntax list`.

#### Scenario: Turning it off and on
- **WHEN** `:syntax off` is run in a highlighted Ruby buffer and then `:syntax on`
- **THEN** the buffer is drawn in the normal group after the first command and highlighted again after the second

#### Scenario: Unknown subcommand
- **WHEN** `:syntax clear` is run
- **THEN** the message row shows `E410: Invalid :syntax subcommand: clear`

### Requirement: The filetype and syntax are set with set
`:se[t]` SHALL accept `filetype=<name>` or `ft=<name>`, which sets the current buffer's filetype and its syntax, and `syntax=<name>` or `syn=<name>`, which sets its syntax alone (`OFF` for none, `ON` for its filetype); `<option>?` and the bare name SHALL show `  filetype=<name>` or `  syntax=<name>`. Several arguments may be given. Other option names SHALL be answered with `Not implemented: :set <argument>` for an option Carat has and `E518: Unknown option: <name>` otherwise.

#### Scenario: Setting the filetype
- **WHEN** `:set ft=ruby` is run in a buffer of `notes.txt` holding `def go`
- **THEN** `def` is drawn in the Define group

#### Scenario: Asking for the filetype
- **WHEN** `:set ft?` is run in a buffer of `a.rb`
- **THEN** the message row shows `  filetype=ruby`

#### Scenario: Turning one buffer's syntax off
- **WHEN** `:set syntax=OFF` is run in a buffer of `a.rb`
- **THEN** that buffer is drawn in the normal group and `:set syntax?` shows `  syntax=`

#### Scenario: An option set does not handle yet
- **WHEN** `:set number` is run
- **THEN** the message row shows `Not implemented: :set number`

#### Scenario: An unknown option
- **WHEN** `:set bogus` is run
- **THEN** the message row shows `E518: Unknown option: bogus`

### Requirement: A buffer without a tokenizer is plain
A buffer SHALL be drawn in the normal group when its syntax is empty, when no enabled plugin tokenizes its syntax, or when the plugin that did is disabled, with no message beyond the plugin's own disable message.

#### Scenario: Plugin disabled in the configuration
- **WHEN** the configuration disables the ruby plugin and `a.rb` is opened
- **THEN** the buffer is drawn in the normal group

#### Scenario: Tokenizer raises
- **WHEN** a plugin whose tokenizer raises is the tokenizer of the buffer's filetype
- **THEN** the message row shows that the plugin is disabled and the buffer is drawn in the normal group
