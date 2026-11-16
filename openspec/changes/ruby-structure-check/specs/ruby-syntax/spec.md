## ADDED Requirements

### Requirement: An unclosed block opener is marked without a language server
In a buffer whose file name is a Ruby file name, the ruby plugin SHALL place the `error` sign on the row of the innermost block opener that no `end` closes, without a language server: when the buffer opens, after every change made outside insert, replace, and completion modes, and when one of those modes ends. A buffer whose openers are all closed SHALL show no sign of the plugin.

#### Scenario: The mark appears on open and follows edits
- **WHEN** `a.rb` holding `def go` is opened, then `oend<Esc>` is typed
- **THEN** the first row shows the `error` sign after the open, the sign stays while `end` is typed in insert mode, and none shows after `<Esc>`

### Requirement: Openers are counted as Ruby reads them
Openers SHALL be `def` other than an endless definition, `class`, `module`, `begin`, `case`, `for`, `do` other than the `do` of a `while`, `until`, or `for` on its line, and `if`, `unless`, `while`, and `until` when they start an expression rather than follow a value as a modifier; each `end` SHALL close the innermost open opener. Keywords inside strings, comments, heredocs, symbols, and labels, and words after a dot, SHALL NOT count.

#### Scenario: An unclosed opener of each kind is marked
- **WHEN** a Ruby buffer's lines are `x = 1` then `def go`, or `class A`, `module M`, `items.each do |i|`, or `if ready`, with no `end`
- **THEN** the opener's row, the second, is the one marked

#### Scenario: A modifier if or while is not an opener
- **WHEN** a Ruby buffer reads `return if done`, `x = 1 if y`, and `x += 1 while x < 5`
- **THEN** no row is marked

#### Scenario: A closed file shows no mark
- **WHEN** a Ruby buffer reads `class A`, `  def go`, `    while x do`, `    end`, `  end`, `  def one = 1`, `end`
- **THEN** no row is marked

#### Scenario: Openers in literals do not count
- **WHEN** a Ruby buffer reads `s = "def"`, `# class`, `x.class`, `h = {if: 1}`, `:do`
- **THEN** no row is marked
