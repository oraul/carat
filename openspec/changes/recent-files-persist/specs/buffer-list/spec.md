## ADDED Requirements

### Requirement: The recent files are absolute paths
The buffer list SHALL keep the recent files as absolute paths, most recent first, at most 100, each file once: the path of a file shown in a window is resolved against the working directory it was opened in, so a later change of the working directory never renames it.

#### Scenario: The recent files keep absolute paths
- **WHEN** files are shown in a window under different working directories, one by a path that is already absolute and one by a `./` path
- **THEN** the recent files hold each as the normalized absolute path of the directory it was opened in, and a path shown with no working directory known as given

### Requirement: The recent files are kept between runs
The editor SHALL write the recent files to a state file, `.local/state/carat/recent_files` under the home directory, one path per line, when it ends, creating the directories above it, and SHALL read it when it starts, adding its paths after the files the run has already shown, up to the bound. The state file SHALL never be read from or written to the project directory, and with no home directory nothing SHALL be read or written.

#### Scenario: The recent files take the paths an earlier run kept
- **WHEN** the paths an earlier run kept are restored after the files this run showed
- **THEN** the list holds this run's files first, then the earlier paths normalized, each once

#### Scenario: The recent files stay bounded across restarts
- **WHEN** a state file holds 150 paths and the editor opens one file and ends
- **THEN** the state file holds 100 paths, the opened file first and the oldest dropped

### Requirement: The state file is untrusted and its failures are silent
A missing file, a file that is not a regular file or holds more than 1 MiB, and a line that is not a usable path (not absolute, over 4096 bytes, not UTF-8, or holding a control character) SHALL read as no paths. A file or directory that cannot be made or written SHALL be skipped without a message or a failure of the editor.

#### Scenario: A missing or unreadable state file is read as empty
- **WHEN** the editor starts with no state file, with a directory in its place, with no home directory, or with a file of relative paths, paths holding control characters, empty lines, and repeats
- **THEN** only the usable paths, if any, join the recent files and the editor starts as usual

#### Scenario: A state file that cannot be written does not stop the editor
- **WHEN** the editor ends with the state file unwritable or a directory above it a file
- **THEN** nothing is written, no message or error follows, and the file that was in the way is unchanged
