# editor-startup Specification

## Purpose
Editor startup is how `carat FILE` becomes a running editor on a terminal and how it hands the terminal back when it ends. It covers the command line of the executable, opening the file, the terminal requirement, and the signals the process answers.

## Requirements

### Requirement: The executable takes exactly one file argument
`carat` SHALL take one argument, the path of the file to edit. With no argument or more than one it SHALL print "usage: carat FILE" to standard error and exit with status 1 without touching the terminal.

#### Scenario: No argument
- **WHEN** `carat` is run without arguments
- **THEN** standard error reads "usage: carat FILE" and the exit status is 1

### Requirement: The editor opens the file or starts a new one
On start the editor SHALL load the file into the buffer when it exists and show the message with its line and byte counts, and SHALL start an empty unmodified buffer with that path and show the "[New]" message when it does not.

#### Scenario: Existing file
- **WHEN** `carat notes.txt` is run and notes.txt holds "a\nb\n"
- **THEN** the screen shows lines "a" and "b" and the message row reads "\"notes.txt\" 2L, 4B"

#### Scenario: New file
- **WHEN** `carat fresh.txt` is run and fresh.txt does not exist
- **THEN** the screen shows one empty line and the message row reads "\"fresh.txt\" [New]"

### Requirement: The editor requires a terminal
When standard input is not a terminal the editor SHALL print "carat: standard input is not a terminal" to standard error and exit with status 1.

#### Scenario: Piped input
- **WHEN** `carat FILE` is run with standard input redirected from a file
- **THEN** standard error reads "carat: standard input is not a terminal" and the exit status is 1

### Requirement: The terminal is in raw mode only while the editor runs
The editor SHALL put the terminal into raw mode for the whole run, so Ctrl-C arrives as a key, and SHALL restore the terminal settings and the main screen when it ends, including when it ends by an error.

#### Scenario: Normal quit
- **WHEN** `carat FILE` runs in a pseudo-terminal and ":q" Enter is typed
- **THEN** the process exits with status 0 and its output ends with the alternate-screen disable sequence

### Requirement: Editing in a real terminal
In a pseudo-terminal the editor SHALL accept insert-mode text, write it on ":wq", and exit, so the whole key path from terminal bytes to disk works end to end.

#### Scenario: Insert, write, quit
- **WHEN** `carat FILE` runs in a pseudo-terminal on a new file and "ihello" Escape ":wq" Enter are typed
- **THEN** the process exits with status 0 and FILE contains "hello\n"

### Requirement: SIGTERM ends the editor cleanly
On `SIGTERM` the editor SHALL stop its loop at the next iteration and restore the terminal, exiting without writing the buffer.

#### Scenario: Terminated
- **WHEN** a running editor receives SIGTERM
- **THEN** it exits and its output ends with the alternate-screen disable sequence
