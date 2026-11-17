## MODIFIED Requirements

### Requirement: The host refuses a program it should not run
The request SHALL fail without starting anything for an empty command, an empty word, a word holding a NUL character, or a first word holding a `/`, and SHALL fail when the program cannot start, runs past 2 seconds, when it is stopped, or answers bytes that are not UTF-8. A program that ran past 2 seconds SHALL fail with its name and "ran past 2 seconds", and one that cannot start with "cannot run" and its name, so a plugin can tell a slow program from a missing one.

#### Scenario: run_program refuses a path or an empty command
- **WHEN** a plugin runs an empty command, or `./git status`
- **THEN** the response fails and nothing is started

#### Scenario: run_program fails when the program cannot start
- **WHEN** a plugin runs a program that is not installed
- **THEN** the response fails with "cannot run" and the program's name

#### Scenario: run_program says a program ran past its deadline
- **WHEN** a plugin runs a program that runs past 2 seconds
- **THEN** the response fails with the program's name and "ran past 2 seconds"
