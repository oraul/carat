# Spec Delta

## Purpose

The text buffer is the editor's store for the text of one file: its lines, whether it has unsaved changes, and the line ending it was read with. Every edit the editor makes goes through the buffer's four primitives so later changes can record and undo them.

## ADDED Requirements

### Requirement: Buffer holds lines without line terminators
A buffer SHALL hold the text of one file as an ordered list of lines without their line terminators, and SHALL always hold at least one line, so an empty file is one empty line.

#### Scenario: Text with a trailing newline
- **WHEN** a buffer is loaded from the text "one\ntwo\n"
- **THEN** it has two lines, "one" and "two"

#### Scenario: Text without a trailing newline
- **WHEN** a buffer is loaded from the text "one\ntwo"
- **THEN** it has two lines, "one" and "two"

#### Scenario: Empty text
- **WHEN** a buffer is loaded from the empty text
- **THEN** it has exactly one line, which is empty

### Requirement: Buffer detects and preserves the line ending
A buffer SHALL record the line ending of the text it was loaded from, "\r\n" when the first line terminator is "\r\n" and "\n" otherwise, and SHALL use that line ending when producing the file text. The produced text SHALL end with one line ending.

#### Scenario: Windows line endings round-trip
- **WHEN** a buffer is loaded from "a\r\nb\r\n" and its file text is produced
- **THEN** the file text is "a\r\nb\r\n"

#### Scenario: A missing final newline is added
- **WHEN** a buffer is loaded from "a\nb" and its file text is produced
- **THEN** the file text is "a\nb\n"

### Requirement: Insert primitive
The buffer SHALL insert text at a position given as a row and a code-point column. Text containing newlines SHALL split the line at that position into as many lines as the text has. The buffer SHALL be marked modified.

#### Scenario: Insert within a line
- **WHEN** "ab" is inserted at row 0, column 1 of the lines ["xy"]
- **THEN** the lines are ["xaby"] and the buffer is modified

#### Scenario: Insert a newline
- **WHEN** "\n" is inserted at row 0, column 1 of the lines ["xy"]
- **THEN** the lines are ["x", "y"]

#### Scenario: Insert multi-line text
- **WHEN** "1\n2\n3" is inserted at row 0, column 1 of the lines ["xy"]
- **THEN** the lines are ["x1", "2", "3y"]

### Requirement: Delete primitive
The buffer SHALL delete a charwise range given by a start position and an end position where the end is exclusive. A range spanning lines SHALL join the remaining head of the first line with the remaining tail of the last. The buffer SHALL be marked modified.

#### Scenario: Delete within a line
- **WHEN** the range from (0, 1) to (0, 3) is deleted from the lines ["abcd"]
- **THEN** the lines are ["ad"]

#### Scenario: Delete across lines
- **WHEN** the range from (0, 1) to (2, 1) is deleted from the lines ["ab", "cd", "ef"]
- **THEN** the lines are ["af"]

#### Scenario: Delete a line break
- **WHEN** the range from (0, 2) to (1, 0) is deleted from the lines ["ab", "cd"]
- **THEN** the lines are ["abcd"]

### Requirement: Replace primitive
The buffer SHALL replace a charwise range with text in one step, equivalent to deleting the range and inserting the text at its start.

#### Scenario: Replace within a line
- **WHEN** the range from (0, 1) to (0, 3) of the lines ["abcd"] is replaced with "XYZ"
- **THEN** the lines are ["aXYZd"]

### Requirement: Set lines primitive
The buffer SHALL replace the lines from a start row up to an exclusive end row with a given list of lines, which may be longer, shorter, or empty, and SHALL keep at least one line afterwards.

#### Scenario: Replace two lines with one
- **WHEN** rows 0 to 2 of the lines ["a", "b", "c"] are set to ["z"]
- **THEN** the lines are ["z", "c"]

#### Scenario: Insert lines without removing any
- **WHEN** rows 1 to 1 of the lines ["a", "b"] are set to ["x", "y"]
- **THEN** the lines are ["a", "x", "y", "b"]

#### Scenario: Removing every line leaves one empty line
- **WHEN** rows 0 to 2 of the lines ["a", "b"] are set to []
- **THEN** the lines are [""] and the buffer is modified

### Requirement: Modified flag follows edits and saves
A freshly loaded buffer SHALL not be modified; any primitive SHALL set modified; saving the buffer SHALL clear it.

#### Scenario: Load, edit, save
- **WHEN** a buffer is loaded, then text is inserted, then it is marked saved
- **THEN** it is unmodified after loading, modified after the insert, and unmodified after the save
