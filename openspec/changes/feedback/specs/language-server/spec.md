# Spec Delta

## ADDED Requirements

### Requirement: Server messages as notifications

A `window/showMessage` notification from a running server SHALL show its message as a notification: type 1 as an error, 2 as a warning, and 3, 4, or any other value as info. The message SHALL be cut to one line of at most 200 characters with control characters removed, and kept in the message history.

#### Scenario: An error from the server

- **WHEN** the server sends `window/showMessage` with type 1 and message `Bundle failed`
- **THEN** an error notification `Bundle failed` shows at the top right and `:messages` lists `Bundle failed`

#### Scenario: Control characters are removed

- **WHEN** the server sends a message holding an escape character and a newline
- **THEN** the notification shows it on one line without the escape character

### Requirement: Server progress on the status bar

A `$/progress` report of the current buffer's server SHALL fill the progress segment: `begin` with its `title`, `message`, and `percentage`, `report` with its `message` and `percentage`, keeping the title and the last percent. The segment SHALL go when every begun report has ended or the server stops or crashes.

#### Scenario: Indexing with a title

- **WHEN** the server begins progress titled `Indexing` and reports 42 percent with the message `3/7 files`
- **THEN** the progress segment reads `Indexing 3/7 files` followed by a bar of four done cells, and the segment goes after the end
