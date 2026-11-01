# Spec Delta

## Purpose

Lets the user take back changes and bring them again, through a tree of the buffer's text states that keeps every branch, as Neovim's undo does.

## ADDED Requirements

### Requirement: Every change becomes one undo state
Every normal-mode, visual-mode, or command-line command that changes a file buffer, every insert session from the command that entered insert mode to leaving it, and every plugin edit request SHALL become one undo state of that buffer, numbered from 1 in the order the changes were made. A command that changes nothing SHALL make no state.

#### Scenario: An insert session is one state
- **WHEN** "o", "a", "b", Escape are pressed on the lines ["x"], then "u"
- **THEN** the lines are ["x"]

#### Scenario: A count is one state
- **WHEN** "3dd" is pressed on the lines ["a", "b", "c", "d"], then "u"
- **THEN** the lines are ["a", "b", "c", "d"]

#### Scenario: A visual block insert is one state
- **WHEN** "<C-v>jI", "-", Escape are pressed at (0, 0) of ["ab", "cd"], then "u"
- **THEN** the lines are ["ab", "cd"]

### Requirement: u undoes and Ctrl-R redoes
Pressing "u" SHALL undo count states along the current branch and "<C-r>" SHALL redo count states, the most recently undone first. With nothing to undo the message SHALL be "Already at oldest change", with nothing to redo "Already at newest change", and the text SHALL stay unchanged.

#### Scenario: Undo and redo a delete
- **WHEN** "x" is pressed at (0, 0) of ["abc"], then "u", then "<C-r>"
- **THEN** the line is "abc" after "u" and "bc" after "<C-r>"

#### Scenario: Counts
- **WHEN** "x", "x", "x" are pressed at (0, 0) of ["abcd"], then "2u"
- **THEN** the line is "bcd"

#### Scenario: Nothing to undo
- **WHEN** "u" is pressed in a buffer that was not changed
- **THEN** the message is "Already at oldest change"

#### Scenario: Nothing to redo
- **WHEN** "x" is pressed, then "<C-r>"
- **THEN** the message is "Already at newest change"

### Requirement: Undo and redo report what changed
After an undo or redo the message SHALL be the count and "more lines", "more line", "line less", or "fewer lines" from the net lines put back or taken out, or the lines changed and "changes" or "change" when the count is the same; then "; before #N" with the last undone state or "; after #N" with the last redone one; then two spaces and how long ago that state was made, as "N seconds ago" or "1 second ago".

#### Scenario: Undoing a deleted line
- **WHEN** "dd" is pressed on row 1 of ["a", "b", "c"], then "u"
- **THEN** the message is "1 more line; before #1  0 seconds ago"

#### Scenario: Redoing it
- **WHEN** "dd" is pressed on row 1 of ["a", "b", "c"], then "u", then "<C-r>"
- **THEN** the message is "1 line less; after #1  0 seconds ago"

#### Scenario: A change within a line
- **WHEN** "x" is pressed, five seconds pass, and "u" is pressed
- **THEN** the message is "1 change; before #1  5 seconds ago"

### Requirement: The cursor goes to the change
After an undo or redo the cursor SHALL be on the first changed line, at the position it had before the change when that change started on that line, and on the first non-blank character otherwise.

#### Scenario: Undo puts the cursor back
- **WHEN** "x" is pressed at (0, 2) of ["abcd"], "0" is pressed, and then "u"
- **THEN** the cursor is at (0, 2)

#### Scenario: Undo of an opened line
- **WHEN** "o", "x", Escape are pressed at (0, 1) of ["ab", "cd"], then "u"
- **THEN** the lines are ["ab", "cd"] and the cursor is at (0, 1)

### Requirement: A change after undo starts a new branch
A change made after an undo SHALL start a new branch beside the undone states, and "<C-r>" SHALL then follow the newest branch.

#### Scenario: Redo after a new branch
- **WHEN** "x" is pressed at (0, 0) of ["abc"], then "u", then "$x", then "u", then "<C-r>"
- **THEN** the line is "ab"

### Requirement: g- and g+ move through the states in time order
Pressing "g-" SHALL go count states back in the order they were made and "g+" count states forward, crossing branches, so every branch can be reached. At the first state "g-" SHALL say "Already at oldest change" and at the last "g+" "Already at newest change".

#### Scenario: Reaching an abandoned branch
- **WHEN** "x" is pressed at (0, 0) of ["abc"], then "u", then "$x", then "g-"
- **THEN** the line is "bc"

#### Scenario: Back to the original and forward again
- **WHEN** "x" is pressed at (0, 0) of ["abc"], then "u", then "$x", then "g-", "g-", then "g+", "g+"
- **THEN** the line is "abc" after the second "g-" and "ab" after the second "g+"

### Requirement: Undo ex commands
":u" or ":undo" SHALL undo one state and ":undo N" SHALL go to the text after state N, 0 being the original text, or say "E830: Undo number N not found". ":red" or ":redo" SHALL redo one state. ":earlier N" and ":later N" SHALL move N states back or forward in time order as "g-" and "g+" do, one without a count.

#### Scenario: Undo to a state number
- **WHEN** "x", "x", "x" are pressed at (0, 0) of ["abcd"], then ":undo 1" is run
- **THEN** the line is "bcd" and the message is "2 changes; after #1  0 seconds ago"

#### Scenario: Back to the original
- **WHEN** "x", "x" are pressed at (0, 0) of ["abc"], then ":undo 0" is run
- **THEN** the line is "abc"

#### Scenario: An unknown state
- **WHEN** ":undo 7" is run with two states
- **THEN** the message is "E830: Undo number 7 not found"

#### Scenario: Earlier and later
- **WHEN** "x", "x", "x" are pressed at (0, 0) of ["abcd"], then ":earlier 2", then ":later"
- **THEN** the line is "bcd" after ":earlier 2" and "cd" after ":later"

#### Scenario: A time argument is not supported
- **WHEN** ":earlier 10s" is run
- **THEN** the message is "Not implemented: :earlier 10s"

### Requirement: undolist lists the leaves
":undol" or ":undolist" SHALL list, under the line "number changes  when               saved", one line per state without later states on its branch, in number order: the state number right-aligned in six columns, a space, the changes from the original right-aligned in seven, two spaces, how long ago it was made, and the write number when it was written. With no state it SHALL say "Nothing to undo".

#### Scenario: Two branches
- **WHEN** "x" is pressed at (0, 0) of ["abc"], then "u", then "$x", then ":undolist" is run
- **THEN** the message lines are "number changes  when               saved", "     1       1  0 seconds ago", and "     2       1  0 seconds ago"

#### Scenario: Nothing to undo
- **WHEN** ":undolist" is run before any change
- **THEN** the message is "Nothing to undo"

### Requirement: U undoes all recent changes on one line
Pressing "U" SHALL put back the last changed line as it was before the latest run of changes on it, as a new change that "u" undoes and another "U" reverses, with the cursor at the column it had when that run started.

#### Scenario: U after two changes
- **WHEN** "x", "x" are pressed at (0, 0) of ["abcd"], then "U"
- **THEN** the line is "abcd"

#### Scenario: U undoes U
- **WHEN** "x", "x" are pressed at (0, 0) of ["abcd"], then "U", then "U"
- **THEN** the line is "cd"

#### Scenario: u undoes U
- **WHEN** "x" is pressed at (0, 0) of ["abc"], then "U", then "u"
- **THEN** the line is "bc"

### Requirement: Undo history is limited by undolevels
A buffer SHALL keep at most the number of states the "undolevels" option names, 1000 by default, dropping the oldest first, after which those changes can no longer be undone.

#### Scenario: Three levels
- **WHEN** "undolevels" is 3 and "x" is pressed five times at (0, 0) of ["abcdef"], then "10u"
- **THEN** the line is "cdef"

### Requirement: Undo history shares the text with the buffer
An undo state SHALL keep only the lines its change removed and inserted, sharing them with the buffer, so the memory history takes grows with the lines changed and not with the buffer's size.

#### Scenario: A change on a large buffer
- **WHEN** "x" is pressed on one line of a buffer of 100,000 lines
- **THEN** the undo state holds one removed and one inserted line, and the inserted line is the buffer's own line

### Requirement: Arrow keys in insert mode split the undo state
Moving the cursor with an arrow key in insert mode SHALL end the undo state made so far; text typed after it SHALL be a state of its own.

#### Scenario: Undo after an arrow key
- **WHEN** "i", "a", "<Right>", "b", Escape are pressed at (0, 0) of ["x"], then "u"
- **THEN** the line is "ax"

### Requirement: Plugin buffers keep no undo history
A buffer a plugin owns SHALL keep no undo states, so "u" in it SHALL say "Already at oldest change" and leave its lines alone.

#### Scenario: u in a plugin window
- **WHEN** a plugin's side window is focused and "u" is pressed
- **THEN** its lines are unchanged and the message is "Already at oldest change"
