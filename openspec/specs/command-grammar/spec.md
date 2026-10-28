# command-grammar Specification

## Purpose
The command grammar turns the keys typed in normal mode into one command: an optional register, a count, an operator with its motion or text object, or a standalone action. It owns operator-pending mode, cancelling, and the display of the keys typed so far.

## Requirements

### Requirement: A count multiplies a motion
In normal mode the digits "1" to "9" SHALL start a count and "0" to "9" SHALL extend it while no multi-key binding is in progress. The count SHALL apply to the motion or action that follows: a motion with a count SHALL move count times. With no count typed, "0" SHALL remain the line-start motion.

#### Scenario: Count before a motion
- **WHEN** the cursor is at (0, 0) of "abcdef" and "3l" is pressed
- **THEN** the cursor is at (0, 3)

#### Scenario: Two-digit count
- **WHEN** the cursor is at (0, 0) of "abcdefghijklmnop" and "12l" is pressed
- **THEN** the cursor is at (0, 12)

#### Scenario: Zero without a count
- **WHEN** the cursor is at (0, 3) of "abcdef" and "0" is pressed
- **THEN** the cursor is at (0, 0)

#### Scenario: Zero inside a count
- **WHEN** the cursor is at (0, 0) of twelve lines and "10j" is pressed
- **THEN** the cursor is on row 10

### Requirement: An operator waits for a motion or text object
Pressing an operator key in normal mode SHALL switch the editor to operator-pending mode. The next keys SHALL be resolved through the operator-pending keymap, and a motion or text object SHALL complete the command, apply the operator to the range between the cursor and the motion target or to the object, and return to normal mode unless the operator itself enters insert mode.

#### Scenario: Operator then motion
- **WHEN** "d" is pressed on "one two" at (0, 0)
- **THEN** the mode is operator_pending, and after "w" the line is "two", the cursor is at (0, 0), and the mode is normal

#### Scenario: Operator then text object
- **WHEN** "d" then "i" then "w" are pressed on "one two" at (0, 5)
- **THEN** the line is "one " and the mode is normal

### Requirement: Counts before and after an operator multiply
A count typed before the operator and a count typed after it SHALL be multiplied, and the product SHALL be the motion's count. A count on one side only SHALL be used as it is.

#### Scenario: Count on both sides
- **WHEN** "2d3w" is pressed at the start of "a b c d e f g"
- **THEN** the line is "g"

#### Scenario: Count after the operator
- **WHEN** "d2w" is pressed at the start of "a b c"
- **THEN** the line is "c"

### Requirement: A doubled operator acts linewise over count lines
Pressing the operator key again while that operator is pending SHALL complete the command linewise over count lines starting at the cursor line, where count is the product of the counts before and after the operator and 1 when none was typed.

#### Scenario: dd deletes one line
- **WHEN** "dd" is pressed on row 1 of ["a", "b", "c"]
- **THEN** the lines are ["a", "c"]

#### Scenario: Counted doubled operator
- **WHEN** "2dd" is pressed on row 0 of ["a", "b", "c"]
- **THEN** the lines are ["c"]

#### Scenario: Count after the first operator key
- **WHEN** "d2d" is pressed on row 0 of ["a", "b", "c"]
- **THEN** the lines are ["c"]

#### Scenario: A different operator cancels
- **WHEN** "yd" is pressed on ["a", "b"]
- **THEN** the lines are unchanged and the mode is normal

### Requirement: A register prefix selects the register for the command
Pressing the register key followed by a register name SHALL select that register for the command that follows; the name SHALL be the unnamed register, a letter "a" to "z", or a letter "A" to "Z". Any other name SHALL drop the register prefix, and the keys after it SHALL form a new command. The register prefix MAY be followed by a count.

#### Scenario: Named register with a count
- **WHEN** the quote key, "a", "2", "d", "d" are pressed on ["a", "b", "c"]
- **THEN** the lines are ["c"] and register "a" holds "a" and "b" as lines

#### Scenario: Invalid register name
- **WHEN** the quote key then "1" then "x" are pressed at (0, 0) of "ab"
- **THEN** the register prefix is dropped, "x" runs as a new command, and the line is "b"

### Requirement: A motion that takes a character argument reads the next key
A motion that needs a character, such as "f", SHALL read the next key as its argument before completing, and SHALL take that key literally even when it is bound.

#### Scenario: Find a bound key
- **WHEN** "fj" is pressed at (0, 0) of "abjk"
- **THEN** the cursor is at (0, 2)

### Requirement: Escape and unbound keys cancel a pending command
Escape in operator-pending mode SHALL cancel the pending operator, count, and register and return to normal mode. An unbound key in normal mode SHALL discard a pending count and register. Neither SHALL change the buffer.

#### Scenario: Escape cancels an operator
- **WHEN** "d" then Escape then "j" are pressed on row 0 of ["ab", "cd"]
- **THEN** the lines are unchanged, the mode is normal, and the cursor is on row 1

#### Scenario: Unbound key discards a count
- **WHEN** "3", an unbound key, then "l" are pressed at (0, 0) of "abcdef"
- **THEN** the cursor is at (0, 1)

### Requirement: A standalone action receives the count and register
An action that is not an operator or a motion SHALL complete the command at once with the count and register typed before it.

#### Scenario: Counted delete-character
- **WHEN** "3x" is pressed at (0, 0) of "abcdef"
- **THEN** the line is "def"

### Requirement: The keys of a pending command are shown
While a register, count, operator, or multi-key binding is pending in normal or operator-pending mode, the message row SHALL show the keys typed so far at its right edge, and SHALL clear them when the command completes or is cancelled.

#### Scenario: Pending operator with a count
- **WHEN** the quote key, "a", "2", "d" are pressed
- **THEN** the message row ends with "\"a2d"

#### Scenario: Cleared after completion
- **WHEN** "2dd" has been pressed
- **THEN** the message row shows no pending keys
