## MODIFIED Requirements

### Requirement: A plugin reads the first rows of a file through the host
The request `read_file(path, rows)` (API 2.5) SHALL answer the first `rows` lines of the regular file at path, without their line endings, reading at most 256 KiB; it SHALL fail with the file system's message for a directory, a special file, a missing file, or a longer file, and fail for `rows` below 1 or above 262,144 (above 1000 before API 2.10), so a file within the read limit can be read whole.

#### Scenario: read_file answers the first rows
- **WHEN** a plugin reads two rows of a file of three lines
- **THEN** the response lists the first two lines

#### Scenario: read_file refuses a directory
- **WHEN** a plugin reads a directory
- **THEN** the response fails with `Is a directory`

#### Scenario: read_file answers rows past the 1000th
- **WHEN** a plugin reads 2000 rows of a file of 2000 lines
- **THEN** the response lists all 2000 lines, line 1500 the 1500th

#### Scenario: read_file refuses more rows than the read limit holds
- **WHEN** a plugin reads 0 rows or 262,145 rows
- **THEN** the response fails with `rows must be 1 to 262144`
