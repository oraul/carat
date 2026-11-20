## MODIFIED Requirements

### Requirement: Interpolation is code inside the string
`#{` in a double-quoted string, a backtick string, an interpolating percent literal, a regular expression, or an interpolating heredoc SHALL open code highlighted as code until its matching `}`, with braces inside it counted to any depth within a line and strings inside it highlighted as strings with their own interpolation, also across lines.

#### Scenario: Nested interpolation
- **WHEN** a line reads `"a #{b("c #{d}")} e"`
- **THEN** `"a `, `"c `, the `"` before `)`, and ` e"` are String, both `#{` and both `}` Delimiter, and `b`, `d`, and `)` not highlighted

#### Scenario: Interpolation across lines
- **WHEN** lines read `"a #{`, `  x }`, `b"`
- **THEN** `x` is not highlighted, `}` is Delimiter, and `b"` is String

#### Scenario: Braces nested deep in interpolation
- **WHEN** a line reads `"#{[{a: {b: {c: {d: 1}}}}]}!"`, four braces deep inside the interpolation
- **THEN** only the `}` after `]` closes the interpolation and is Delimiter, and `!"` is String

### Requirement: Percent literals take any delimiter
`%w`, `%W`, `%i`, `%I`, `%q`, `%Q`, `%r`, `%s`, `%x`, and `%` SHALL open a literal with any punctuation delimiter, counting nested `()`, `[]`, `{}`, and `<>` pairs to any depth within a line, interpolating for `%W %I %Q %r %x %` and not for the others, which also span lines; `%i` and `%s` literals are Constant.

#### Scenario: Words with brackets
- **WHEN** a line reads `%w[a [b] c].size`
- **THEN** `%w[a [b] c]` is String and `.size` is not highlighted

#### Scenario: Another delimiter
- **WHEN** a line reads `%q|a b| + x`
- **THEN** `%q|a b|` is String and `x` is not highlighted

#### Scenario: Nesting deeper than the state holds
- **WHEN** a line reads `%w(a ((((((((b)))))))) c) + 1`, eight pairs deep inside the literal
- **THEN** `%w(a ((((((((b)))))))) c)` is String and `1` is Number

## ADDED Requirements

### Requirement: A nesting deeper than the state holds is clamped at the end of the line
At the end of a line the state SHALL hold the nesting depth of paired delimiters up to seven pairs and the brace depth in an interpolation up to three braces, a deeper one held to that most, so the following lines are highlighted less precisely and never raise.

#### Scenario: A depth past seven is held to seven across lines
- **WHEN** lines read `%w(((((((((a` and `))))))) b) + 1`, the first ending eight pairs deep
- **THEN** the second line's literal closes at the `)` after `b`, seven pairs later, and `1` is Number
