## ADDED Requirements

### Requirement: A plugin runs a program through the host
The request `run_program(argv)` (API 2.7) SHALL run the program the first word names, looked up on the `PATH`, with the other words as its arguments, without a shell, and answer a copy of its standard output, at most 64 KiB, cut before a character the limit would split. The program SHALL get no input, its error output discarded, and the editor's working directory.

#### Scenario: run_program answers the program's output
- **WHEN** a plugin runs `git symbolic-ref --short -q HEAD` and the program prints "main"
- **THEN** the response succeeds with the text "main" and the process port received the four words as given

#### Scenario: The driver runs a program without a shell
- **WHEN** the process runner captures the words `printf`, `%s`, and `a;b`, and then a program that is not installed
- **THEN** the first answers "a;b", the semicolon reaching printf as text, and the second answers nothing

### Requirement: The host refuses a program it should not run
The request SHALL fail without starting anything for an empty command, an empty word, a word holding a NUL character, or a first word holding a `/`, and SHALL fail when the program cannot start, runs past 2 seconds, when it is stopped, or answers bytes that are not UTF-8.

#### Scenario: run_program refuses a path or an empty command
- **WHEN** a plugin runs an empty command, or `./git status`
- **THEN** the response fails and nothing is started

#### Scenario: run_program fails when the program cannot start
- **WHEN** a plugin runs a program that is not installed
- **THEN** the response fails with "cannot run" and the program's name
