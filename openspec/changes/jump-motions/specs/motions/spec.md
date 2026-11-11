## ADDED Requirements

### Requirement: The match-pair motion
`%` SHALL go to the bracket matching the first `(`, `[`, `{`, `)`, `]`, or `}` at or after the cursor on its line, counting nested pairs of that kind across lines, as an inclusive motion; it SHALL fail when the line holds none after the cursor or the bracket has no match. `{count}%` SHALL go linewise to the line at count percent of the buffer, rounded up, keeping the wanted column, and fail for a count over 100.

#### Scenario: Percent goes to the matching bracket
- **WHEN** the cursor is before `(a (b) c)` on its line and `%` is typed
- **THEN** the cursor is on the closing `)` of the outer pair

#### Scenario: Percent goes back from a closing bracket
- **WHEN** the cursor is on a `}` closing a block that opened two lines above and `%` is typed
- **THEN** the cursor is on the `{`

#### Scenario: Percent without a bracket does nothing
- **WHEN** the rest of the line holds no bracket and `%` is typed
- **THEN** the cursor stays

#### Scenario: A count goes to that percent of the buffer
- **WHEN** the buffer has 10 lines and `50%` is typed
- **THEN** the cursor is on line 5

#### Scenario: Percent under an operator is inclusive
- **WHEN** the cursor is on `(` of `f(a, b) x` and `d%` is typed
- **THEN** the line is `f x`
