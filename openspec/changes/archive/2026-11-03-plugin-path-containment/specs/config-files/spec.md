# Spec Delta

## ADDED Requirements

### Requirement: Many problems are reported in order without slowing startup
However many problems the files hold, every one SHALL be reported, in file and then line order, two problems of one line in the order they were found, and the time to order them SHALL grow no faster than their count times its logarithm, so a hostile project file of many bad lines cannot make startup quadratic.

#### Scenario: Interleaved problems from two readers
- **WHEN** the project file has 20,000 lines alternating "option.tabstop wide" and "editor.font mono"
- **THEN** 20,000 problems are reported, line 1's first and line 20,000's last, each line's problem in line order

#### Scenario: Problems noted out of order
- **WHEN** a reader notes the problem of line 2 before that of line 1
- **THEN** the problem of line 1 is reported first
