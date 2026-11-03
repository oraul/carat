# ruby-syntax Specification

## Purpose
Defines what the built-in `ruby` plugin highlights in Ruby 4 source and how constructs that span lines keep their highlight from one line to the next.

## Requirements

### Requirement: The ruby plugin tokenizes the ruby filetype
A built-in plugin named `ruby`, enabled by the shipped configuration, SHALL declare the filetype `ruby` and tokenize its lines; disabling it in the configuration leaves Ruby files plain.

#### Scenario: Shipped and enabled
- **WHEN** the editor starts with the shipped configuration and opens `a.rb`
- **THEN** the buffer is highlighted by the ruby plugin

### Requirement: Comments and documentation are Comment
A `#` outside a literal SHALL start a Comment to the end of the line, with the words `TODO`, `FIXME`, `XXX`, `NOTE`, `HACK`, `OPTIMIZE`, and `REVIEW` in it in Todo; a `=begin` line at column 0 SHALL start a Comment block through the next `=end` line at column 0; a line `__END__` SHALL make it and every following line Comment.

#### Scenario: Todo in a comment
- **WHEN** a line reads `x = 1 # TODO: later`
- **THEN** `# ` and `: later` are Comment, `TODO` is Todo, and `1` is Number

#### Scenario: Block comment across lines
- **WHEN** lines read `=begin`, `def x`, `=end`, `y`
- **THEN** the first three lines are Comment and `y` is not

#### Scenario: Data after __END__
- **WHEN** a line `__END__` is followed by `def x`
- **THEN** both lines are Comment

### Requirement: Keywords have their groups
Keywords SHALL be highlighted by kind: `def`, `undef`, and `alias` Define; `class` and `module` Structure; conditionals Conditional; loops Repeat; `return`, `break`, `next`, `redo`, `retry`, and `yield` Statement; `begin`, `rescue`, `ensure`, `raise`, and `fail` Exception; `true` and `false` Boolean; `nil`, `self`, and the `__FILE__` family Constant; `and`, `or`, and `not` Operator; the require and include family Include; attribute and visibility methods Macro; other keywords Keyword.

#### Scenario: Control flow
- **WHEN** a line reads `return nil unless ok and true`
- **THEN** `return` is Statement, `nil` Constant, `unless` Conditional, `and` Operator, and `true` Boolean

### Requirement: Definitions and names have their groups
The name after `def` SHALL be Function, the names after `class` and `module` and every constant Type, and instance, class, and global variables Identifier; a keyword after a `.` is a method name and not highlighted.

#### Scenario: A method definition
- **WHEN** a line reads `def self.call(x) = @x`
- **THEN** `def` is Define, `self` Constant, `call` Function, and `@x` Identifier

#### Scenario: A class
- **WHEN** a line reads `class Foo::Bar < Base`
- **THEN** `class` is Structure and `Foo::Bar` and `Base` are Type

#### Scenario: A keyword as a method name
- **WHEN** a line reads `x.class.end`
- **THEN** neither `class` nor `end` is highlighted

### Requirement: Literals have their groups
Numbers in every form (decimal, hexadecimal, octal, binary, with underscores, with a rational or imaginary suffix) SHALL be Number, and those with a fraction or an exponent Float; symbols (`:name`, `:"text"`, `:+`) and hash labels (`key:`) Constant; character literals (`?a`) Character; strings, percent literals, regular expressions, and heredoc bodies String, with escapes in SpecialChar and the delimiters of an interpolation, a regular expression, and a heredoc in Delimiter.

#### Scenario: Numbers
- **WHEN** a line reads `[0x1F, 0b10, 0o17, 1_000, 2r, 3i, 1.5, 1e3, 1.5r]`
- **THEN** the first six are Number and the last three Float

#### Scenario: Symbols and labels
- **WHEN** a line reads `f(:a, :"b c", d: 1)`
- **THEN** `:a`, `:"b c"`, and `d:` are Constant

#### Scenario: Escapes
- **WHEN** a line reads `"a\tb"`
- **THEN** `\t` is SpecialChar and the rest of the string String

### Requirement: Interpolation is code inside the string
`#{` in a double-quoted string, a backtick string, an interpolating percent literal, a regular expression, or an interpolating heredoc SHALL open code highlighted as code until its matching `}`, with braces inside it counted and strings inside it highlighted as strings with their own interpolation, also across lines.

#### Scenario: Nested interpolation
- **WHEN** a line reads `"a #{b("c #{d}")} e"`
- **THEN** `"a `, `"c `, the `"` before `)`, and ` e"` are String, both `#{` and both `}` Delimiter, and `b`, `d`, and `)` not highlighted

#### Scenario: Interpolation across lines
- **WHEN** lines read `"a #{`, `  x }`, `b"`
- **THEN** `x` is not highlighted, `}` is Delimiter, and `b"` is String

### Requirement: Percent literals take any delimiter
`%w`, `%W`, `%i`, `%I`, `%q`, `%Q`, `%r`, `%s`, `%x`, and `%` SHALL open a literal with any punctuation delimiter, counting nested `()`, `[]`, `{}`, and `<>` pairs, interpolating for `%W %I %Q %r %x %` and not for the others, which also span lines; `%i` and `%s` literals are Constant.

#### Scenario: Words with brackets
- **WHEN** a line reads `%w[a [b] c].size`
- **THEN** `%w[a [b] c]` is String and `.size` is not highlighted

#### Scenario: Another delimiter
- **WHEN** a line reads `%q|a b| + x`
- **THEN** `%q|a b|` is String and `x` is not highlighted

### Requirement: Heredocs are carried across lines
`<<ID`, `<<-ID`, and `<<~ID`, with the identifier bare or in single, double, or back quotes, SHALL start a heredoc whose body begins on the next line and ends at a line holding only the identifier (indented for `-` and `~`); several on one line SHALL follow each other. The bodies SHALL be String, with interpolation and escapes unless the identifier is single-quoted, and the opener and terminator Delimiter.

#### Scenario: One heredoc
- **WHEN** lines read `x = <<~SQL`, `  select #{a}`, `  SQL`, `y`
- **THEN** `<<~SQL` and the terminator are Delimiter, the body String with `#{` and `}` Delimiter, and `y` is not highlighted

#### Scenario: Two heredocs on one line
- **WHEN** lines read `f(<<~A, <<~'B')`, `a #{x}`, `A`, `b #{x}`, `B`
- **THEN** both bodies are String, `#{` is Delimiter in the first body and String in the second

### Requirement: A slash is a regular expression or a division by what precedes it
A `/` SHALL start a regular expression at the start of a line or after an operator, a keyword, an opening bracket, or a comma, and after a method name when a space precedes it and none follows; after a value it SHALL be a division. The same rule SHALL decide whether `%` starts a percent literal and `?` a character literal.

#### Scenario: Regular expression
- **WHEN** a line reads `x =~ /a+b/i`
- **THEN** `/a+b/i` is String with its slashes and flags Delimiter

#### Scenario: Division
- **WHEN** a line reads `a = b / c / 2`
- **THEN** no part of the line is String

### Requirement: The state is an integer that degrades gracefully
The state at the end of a line SHALL be a non-negative integer that encodes the open constructs: the block comment and data mode, up to two pending heredocs, and up to two nested strings with their interpolation depth; a construct the encoding cannot hold SHALL be dropped at the end of the line, highlighting the following lines less precisely, never raising.

#### Scenario: Deep nesting
- **WHEN** a line opens three nested strings through interpolation and does not close them
- **THEN** the tokenizer returns a state and the next line is tokenized without an error
