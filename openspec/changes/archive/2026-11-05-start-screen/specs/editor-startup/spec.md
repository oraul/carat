## MODIFIED Requirements

### Requirement: The executable takes exactly one file argument
`carat` SHALL take at most one argument, the path of the file or directory to edit. With more than one it SHALL print "usage: carat [FILE]" to standard error and exit with status 1 without touching the terminal. With none it SHALL start on an empty buffer with no name.

#### Scenario: No argument
- **WHEN** `carat` is run without arguments in a pseudo-terminal and ":q" Enter is typed after the start screen
- **THEN** the screen showed the start screen and the process exits with status 0

#### Scenario: Two arguments
- **WHEN** `carat a.txt b.txt` is run
- **THEN** standard error reads "usage: carat [FILE]" and the exit status is 1
