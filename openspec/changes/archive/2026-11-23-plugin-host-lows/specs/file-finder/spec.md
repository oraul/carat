## ADDED Requirements

### Requirement: The file finder shows a listed path safely
The rows of the file finder, and the title of its preview, SHALL show each listed path with a control character, a bidirectional mark, a zero-width character, and a line or paragraph separator as a space and a byte of invalid UTF-8 as a question mark, the sanitizer the grep rows use.

#### Scenario: A listed path is shown safely
- **WHEN** the file finder lists a path holding U+202E
- **THEN** its row and the preview title show a space in its place

### Requirement: The grep reads are bounded by their bytes
The grep picker SHALL stop reading the listed files once the files read hold 16 MiB, whatever lines they store, and the title SHALL mark the store as cut.

#### Scenario: The files read are bounded by their bytes
- **WHEN** the listed files hold more than 16 MiB and the last holds the query
- **THEN** the last file is never read, the query matches nothing, and the title marks the stored lines with a plus
