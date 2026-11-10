## ADDED Requirements

### Requirement: gd knows a file under any spelling of its path
A definition target SHALL be the current file, or a listed buffer's file, when their absolute paths are equal once `.` and `..` segments and repeated slashes are resolved.

#### Scenario: A target in the current file named with dot segments moves the cursor
- **WHEN** the current buffer is named `./a.rb` or `lib/../a.rb`, modified or not, and the answer is one location in `/project/a.rb`
- **THEN** the cursor moves in that buffer with no E37 and no second buffer listed
