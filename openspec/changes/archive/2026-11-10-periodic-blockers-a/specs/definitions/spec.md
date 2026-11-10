## ADDED Requirements

### Requirement: gd knows a file under any spelling of its path
A definition target SHALL be the current file, or a listed buffer's file, when their absolute paths are equal once `.` and `..` segments and repeated slashes are resolved.

#### Scenario: A target in the current file named with dot segments moves the cursor
- **WHEN** the current buffer is named `./a.rb` or `lib/../a.rb`, modified or not, and the answer is one location in `/project/a.rb`
- **THEN** the cursor moves in that buffer with no E37 and no second buffer listed

#### Scenario: A target in a listed buffer named with dot segments shows that buffer
- **WHEN** a modified buffer named `./b.rb` is listed and hidden, the current buffer is `a.rb`, and the answer is one location in `/project/b.rb`
- **THEN** gd shows the listed buffer with its unsaved text and lists no second buffer, and a peek shows the listed buffer's unsaved lines, not the file's on disk
