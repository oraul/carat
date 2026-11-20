# editor-startup Specification

## Purpose
Editor startup is how `carat FILE` becomes a running editor on a terminal and how it hands the terminal back when it ends. It covers the command line of the executable, opening the file, the terminal requirement, and the signals the process answers.

## Requirements

### Requirement: The executable takes exactly one file argument
`carat` SHALL take at most one argument, the path of the file or directory to edit. With more than one it SHALL print "usage: carat [FILE]" to standard error and exit with status 1 without touching the terminal. With none it SHALL start on an empty buffer with no name.

#### Scenario: No argument
- **WHEN** `carat` is run without arguments in a pseudo-terminal and ":q" Enter is typed after the start screen
- **THEN** the screen showed the start screen and the process exits with status 0

#### Scenario: Two arguments
- **WHEN** `carat a.txt b.txt` is run
- **THEN** standard error reads "usage: carat [FILE]" and the exit status is 1

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

### Requirement: Every exit restores the terminal's cursor
However the editor ends, by ":q", ":wq", closing the last window, `SIGTERM`, `SIGINT`, or an error after it entered the screen, opening the file included, it SHALL restore the terminal's own cursor shape, show the cursor, and leave the alternate screen as the last bytes it writes.

#### Scenario: Quit by a command
- **WHEN** `carat FILE` runs in a pseudo-terminal, "i" is typed so the cursor is a bar, and ":wq" Enter ends it after Escape
- **THEN** its output ends with the reset of the cursor shape to the terminal's default, the cursor shown, and the alternate-screen disable sequence

#### Scenario: Quit by a signal
- **WHEN** a running editor receives SIGTERM, or SIGINT
- **THEN** it exits with status 0 and its output ends with the same three sequences

### Requirement: The editor asks the terminal for its background without waiting
On start the editor SHALL ask the terminal for its background color with the OSC 11 query and SHALL draw the first frame without waiting for an answer. The answer is untrusted input, read within a fixed bound: a light color SHALL report the background light, a dark one dark, and a malformed reply or none SHALL leave it unknown. No byte of a reply SHALL reach the keys, except the rest of a reply whose held start a read timeout dropped; keys typed around it SHALL arrive unchanged.

#### Scenario: The first frame waits for no reply
- **WHEN** the editor starts on a terminal that has not answered
- **THEN** the first frame is drawn at once and the query follows it, the background unknown

#### Scenario: A dark reply
- **WHEN** the terminal answers with a dark color between typed keys
- **THEN** the background is dark and only the typed keys arrive

#### Scenario: A light reply
- **WHEN** the terminal answers with a light color, whole or split across two reads
- **THEN** the background is light and no reply byte arrives as a key

#### Scenario: A malformed reply
- **WHEN** the answer is too long, cut short, or in another format
- **THEN** the background stays unknown and no reply byte arrives as a key

#### Scenario: A reply delayed past a timeout
- **WHEN** a read times out while the start of a reply is held and its rest arrives later
- **THEN** the held start is dropped as cut short, the background stays unknown, and the rest arrives as keys

#### Scenario: No reply
- **WHEN** the terminal never answers
- **THEN** the background stays unknown and every typed key arrives unchanged
