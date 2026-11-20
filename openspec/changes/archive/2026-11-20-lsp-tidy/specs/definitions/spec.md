## ADDED Requirements

### Requirement: A target path with a dot segment is dropped
A definition target whose file URI, its percent escapes decoded, holds a `.` or `..` path segment SHALL be dropped as a relative or malformed target is, so no path that reads as inside the project names a file outside it.

#### Scenario: A target with a dot segment is dropped
- **WHEN** the answer is one location whose URI path holds a `..` segment, written as is or as `%2E%2E`, or a `.` segment
- **THEN** the cursor and the current buffer stay where `gd` was typed
