## ADDED Requirements

### Requirement: Quit and :LspRestart end only the server carat started
On quit and on `:LspRestart` the editor SHALL send `shutdown` and `exit` to each language server it started and end that server's process by signalling that process itself, and SHALL end no other process: not another child, not the server's process group, and not a process that took the number of a child already reaped.

#### Scenario: Stopping a server ends only that server
- **WHEN** two server processes run and the first is stopped
- **THEN** the first process ends and the second keeps running until it is stopped

#### Scenario: Quit stops only the started server
- **WHEN** ruby-lsp runs and the editor quits
- **THEN** `shutdown` and `exit` are sent and only ruby-lsp's process is stopped

#### Scenario: LspRestart stops only the old server
- **WHEN** ruby-lsp runs and `:LspRestart` is entered
- **THEN** only the old server's process is stopped and one new server is started

### Requirement: A language's server command is settled once
The editor SHALL settle whether a language names a server command, and the program it names, the first time it needs them and keep them for the session, so an idle tick while the current buffer's language has no server reads no configuration line; the full command is read when a server starts.

#### Scenario: An idle tick with no server reads no configuration line
- **WHEN** a Ruby buffer waits for `:LspStart` in an untrusted directory, so no server runs, for one idle tick, and a configuration line naming another Ruby server command is read afterward
- **THEN** the next idle tick still shows "ruby-lsp untrusted :LspStart" on the bar and starts nothing
