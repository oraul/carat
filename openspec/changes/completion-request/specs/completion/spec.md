## ADDED Requirements

### Requirement: The language server is the editor's completion source
When the current buffer's language server runs and advertised a completion provider, typing a word in insert mode SHALL ask that server for the word's completions without making any key wait: the request SHALL be sent at an idle tick once no other word was wanted for 0.1 seconds, after the server was told the buffer's text, and the popup SHALL fill from the answer when it arrives, with no key pressed. With no completing server, typing SHALL behave and cost as without completion.

#### Scenario: The answer fills the popup with no key
- **WHEN** ruby-lsp completes, "fi" is typed in a Ruby buffer, the editor stays idle, and the server answers "file_name", "filter", and "final"
- **THEN** the popup shows all three, "final" first, without another key

#### Scenario: An answer between keys
- **WHEN** a completion request is in flight and its answer arrives 0.1 seconds after a key, before the next key
- **THEN** the popup shows before the next key is read

#### Scenario: Requests are debounced
- **WHEN** "a b c" is typed with less than 0.1 seconds between the words
- **THEN** one completion request is sent, for the word "c"

#### Scenario: No completing server
- **WHEN** the server advertised no completion provider and "fi" is typed
- **THEN** no completion request is sent and no popup shows

### Requirement: A stale completion request is cancelled
When another word is wanted while a completion request is in flight, the editor SHALL send `$/cancelRequest` for it and SHALL drop its answer; an answer to no request in flight SHALL change nothing.

#### Scenario: Typing another word cancels
- **WHEN** a request for "fi" is in flight and " ba" is typed
- **THEN** a cancel for the first request is sent and its answer, when it arrives, opens no popup

### Requirement: A server's completions are bounded and untrusted
The editor SHALL read at most 200 items of an answer, and SHALL drop escape sequences and controls from each label, detail, and insert text and cut them to their limits before keeping them; an item without a string label SHALL be skipped and an unknown kind SHALL read as text.

#### Scenario: An escape-laden, oversized item
- **WHEN** the server answers an item whose label holds an escape sequence and is 5,000 bytes long
- **THEN** the popup's label holds no escape character and is at most 80 bytes

#### Scenario: Too many items
- **WHEN** the server answers 300 items
- **THEN** 200 are kept
