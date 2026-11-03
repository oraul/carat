# config-files Specification

## Purpose
The configuration files tell Carat its options, key bindings, plugin settings, and language commands, one setting per line in a `.caratrc` format: the shipped defaults, then the user's file, then the project's, with every problem reported by file and line.

## Requirements

### Requirement: A configuration line is a dotted key and a value
Every non-blank line of a configuration file SHALL be a key followed by its value, separated by spaces or tabs. The key SHALL be two or more segments of lowercase letters, digits, and underscores joined by dots, the first segment being the scope. The value SHALL be the rest of the line split into words at spaces and tabs: one word is a word, a number, or `true` or `false`, and several words are a list.

#### Scenario: A word value
- **WHEN** a file holds the line "option.theme carat-dark"
- **THEN** the key is "option.theme" and the value is the one word "carat-dark"

#### Scenario: A list value
- **WHEN** a file holds the line "plugin.explorer.ignore .git build tmp"
- **THEN** the value is the list ".git", "build", "tmp"

#### Scenario: Carriage return
- **WHEN** a file's lines end in a carriage return and a newline
- **THEN** they read as if the carriage return were not there

### Requirement: Quotes keep spaces inside a word
A word that starts with a double quote SHALL run to the next unescaped double quote, keeping the spaces inside it, with `\"` standing for a double quote and `\\` for a backslash. A double quote inside a word that does not start with one SHALL be an ordinary character.

#### Scenario: A quoted word
- **WHEN** a file holds the line `language.ruby.formatter rubocop "--config my file.yml"`
- **THEN** the value is the list "rubocop", "--config my file.yml"

#### Scenario: Escapes inside quotes
- **WHEN** a file holds the line `keymap.normal "\"" register.select`
- **THEN** the value is the list `"`, "register.select"

#### Scenario: A quote inside a word
- **WHEN** a file holds the line `keymap.operator_pending i" textobject.inner_double_quote`
- **THEN** the value is the list `i"`, "textobject.inner_double_quote"

### Requirement: Comments and blank lines are ignored
A `#` at the start of a word SHALL start a comment that runs to the end of the line, and blank lines and comment lines SHALL be ignored.

#### Scenario: Comments and blank lines
- **WHEN** a file holds a comment line, a blank line, and the line "option.tabstop 4 # four columns"
- **THEN** the file sets only tabstop, to 4

### Requirement: Malformed lines are reported and skipped
A line that cannot be read SHALL be reported as `file:line: message` and skipped, and every other line of the file SHALL still load: a bad key reports "invalid key", a double quote with no closing one "unterminated quote", a closing double quote followed by anything but a space, a tab, or the end of the line "text after a closing quote", and a control character other than a tab "control character".

#### Scenario: Unterminated quote
- **WHEN** the project file's third line is `option.clipboard "unnamed`
- **THEN** ".caratrc:3: unterminated quote" is reported and the other lines load

#### Scenario: Invalid key
- **WHEN** the project file's first line is "Option.Tabstop 4"
- **THEN** ".caratrc:1: invalid key" is reported

### Requirement: An empty value is a list or a wrong kind
A key with no value SHALL be the empty list for a setting that takes a list, and a value of the wrong kind for any other setting.

#### Scenario: Missing value
- **WHEN** the project file's first line is "option.tabstop"
- **THEN** ".caratrc:1: option.tabstop takes a number" is reported and tabstop keeps its value

#### Scenario: Empty list
- **WHEN** the project file holds the line "plugin.explorer.ignore"
- **THEN** the explorer ignores no entry and nothing is reported

### Requirement: Three files load in order and later lines win
The editor SHALL read the shipped defaults, then `~/.config/carat/caratrc` in the user's home directory when it exists, then `.caratrc` in the working directory when it exists, and SHALL apply their lines in that order, so a later line of the same setting replaces an earlier one.

#### Scenario: The user file overrides the defaults
- **WHEN** the user file holds "option.tabstop 4"
- **THEN** tabstop is 4

#### Scenario: The project file overrides the user file
- **WHEN** the user file holds "option.tabstop 4" and the project file holds "option.tabstop 3"
- **THEN** tabstop is 3

#### Scenario: Later lines of one file win
- **WHEN** the project file holds "option.number false" and later "option.number true"
- **THEN** line numbers are shown

### Requirement: Missing files are skipped and files are named in reports
A missing user or project file SHALL be skipped silently; one that exists but cannot be read SHALL be reported with its name. Reports SHALL name the defaults `config/default.caratrc`, the user file `~/.config/carat/caratrc`, and the project file `.caratrc`.

#### Scenario: No user or project file
- **WHEN** neither the user file nor the project file exists
- **THEN** the shipped defaults apply and nothing is reported

#### Scenario: Unreadable project file
- **WHEN** `.caratrc` exists in the working directory but reading it fails
- **THEN** a problem starting with ".caratrc: cannot be read" is reported

### Requirement: Every setting is validated and problems are reported by file and line
Every line SHALL be checked when the files load: its scope SHALL be one of `option`, `keymap`, `plugin`, and `language`, and its setting SHALL be known with a value of its kind. Every problem SHALL be reported as `file:line: message`, the line SHALL be skipped, and every other line SHALL still load.

#### Scenario: Unknown scope
- **WHEN** the project file's first line is "editor.font mono"
- **THEN** ".caratrc:1: unknown setting editor.font" is reported

#### Scenario: Unknown option
- **WHEN** the project file's first line is "option.tabsize 4"
- **THEN** ".caratrc:1: unknown option tabsize" is reported

#### Scenario: Value of the wrong kind
- **WHEN** the project file's first line is "option.tabstop wide"
- **THEN** ".caratrc:1: option.tabstop takes a number" is reported and tabstop keeps its value

#### Scenario: A flag
- **WHEN** the project file's first line is "option.number yes"
- **THEN** ".caratrc:1: option.number takes true or false" is reported

#### Scenario: Unknown language setting
- **WHEN** the user file's first line is "language.ruby.linter rubocop"
- **THEN** "~/.config/carat/caratrc:1: unknown language setting linter" is reported

### Requirement: The first problem is shown after startup
After startup the message row SHALL show the first problem in file and line order as an error, followed by " (and N more)" when there are others.

#### Scenario: Problems in file order
- **WHEN** the user file has a problem on line 2 and the project file one on line 1, and the editor starts on "a.txt"
- **THEN** the message row shows the user file's problem followed by " (and 1 more)"

#### Scenario: The shipped defaults are clean
- **WHEN** the editor starts with the shipped defaults alone
- **THEN** no configuration problem is reported

### Requirement: Options are set with option lines
The options `number`, `relativenumber`, `expandtab`, `autoindent`, `ignorecase`, `smartcase`, `hlsearch`, `incsearch`, and `wrap` SHALL take `true` or `false`; `tabstop`, `shiftwidth`, `scrolloff`, `timeoutlen`, and `undolevels` SHALL take a number; `clipboard`, `icons`, and `theme` SHALL take one word. A setting no file names SHALL keep Vim's default.

#### Scenario: Shipped options
- **WHEN** the editor starts with the shipped defaults
- **THEN** tabstop is 2, timeoutlen is 500, and line numbers are shown

#### Scenario: timeoutlen from a line
- **WHEN** the project file holds "option.timeoutlen 100"
- **THEN** an ambiguous key prefix waits 100 milliseconds

### Requirement: A project file cannot choose programs to run
A `language.*` line in the project file SHALL be reported as "language commands are not read from a project file" and ignored, because it names a program to run; the same line in the defaults or the user file SHALL be accepted.

#### Scenario: Language command in the project file
- **WHEN** the project file's first line is "language.ruby.lsp ./evil"
- **THEN** ".caratrc:1: language commands are not read from a project file" is reported and the Ruby language command stays the one the defaults name

#### Scenario: Language command in the user file
- **WHEN** the user file holds "language.ruby.lsp ruby-lsp --debug"
- **THEN** nothing is reported

### Requirement: A project file cannot bind keys to key sequences
A keymap line in the project file whose action is a key sequence to replay SHALL be reported as "key sequences are not read from a project file" and ignored, because a replay can run any ex command, a write to any path included. The same line in the defaults or the user file SHALL be accepted, and the project file SHALL still bind keys to action names and `none`.

#### Scenario: Key sequence in the project file
- **WHEN** the project file's first line is "keymap.normal j :e<Space>.git/config<CR>"
- **THEN** ".caratrc:1: key sequences are not read from a project file" is reported and "j" still moves down

#### Scenario: Action binding in the project file
- **WHEN** the project file holds "keymap.normal K cursor.down"
- **THEN** "K" moves down and nothing is reported
