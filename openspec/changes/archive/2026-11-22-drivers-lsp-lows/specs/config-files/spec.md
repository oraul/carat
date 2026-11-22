## ADDED Requirements

### Requirement: A file read is judged on its opened descriptor
A configuration or plugin file read SHALL judge the kind of what it opened on the opened descriptor, never by its path again, and SHALL refuse a FIFO at once, without waiting for a writer, even while a language server's threads run.

#### Scenario: A FIFO is refused at once while threads run
- **WHEN** a FIFO with no writer is read while another thread runs
- **THEN** the read raises "Not a regular file" without waiting for the writer
