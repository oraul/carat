## Purpose

The signature of the call the cursor is in while typing in insert mode, asked of the buffer's language server, shown in a float above the cursor with the active parameter marked, following the cursor through the call and closed outside it, its untrusted text bounded.

## ADDED Requirements

### Requirement: Typing an open parenthesis or a comma asks for the call's signature
In insert mode, typing `(` or `,` SHALL ask the running language server of the current buffer's file type for the signature help at the cursor, when that server advertised signature help, the buffer has a path, and an unclosed `(` precedes the cursor on its row; the innermost such `(` is the call followed.

#### Scenario: The answer opens a float above the cursor
- **WHEN** a server with signature help runs for a Ruby buffer, `foo(` is typed in insert mode on its third row, and the server answers the signature `foo(a, b)` with parameters `a` and `b`, the first active
- **THEN** a bordered float of one row above the cursor reads `foo(a, b)`, its `a` drawn in `Visual`, before any other key

#### Scenario: No server gives signature help
- **WHEN** `foo(` is typed in a buffer whose server does not advertise signature help
- **THEN** no request is sent and no float opens

#### Scenario: Other characters ask nothing
- **WHEN** `foo` is typed in insert mode
- **THEN** no signature request is recorded

### Requirement: The signature request never makes a key wait
The request SHALL be sent at an idle moment once no newer ask was recorded for 0.1 seconds, and its answer SHALL open the float at the next idle moment with no key pressed. Any other typed character SHALL cost no lookup or allocation while no call is followed.

#### Scenario: The first idle tick only starts the debounce
- **WHEN** `foo(` is typed and one idle tick passes
- **THEN** no request is sent until 0.1 seconds passed

### Requirement: The float follows the cursor through the call
While a call is followed, a key that leaves the cursor inside it at another column, or inside another unclosed `(` on the row, SHALL ask again, and the answer SHALL replace the float with the new active parameter marked. The float SHALL close and the call SHALL stop being followed when the cursor is no longer after an unclosed `(` on the row it was on, when the window or buffer changes, when insert mode is left, and when the server answers with no signature.

#### Scenario: A comma moves the mark to the next parameter
- **WHEN** the float shows `foo(a, b)` with `a` marked and `x, ` is typed, and the server answers with the second parameter active
- **THEN** the float shows `foo(a, b)` with `b` drawn in `Visual`

#### Scenario: Closing the call closes the float
- **WHEN** the float shows and `)` is typed after the arguments
- **THEN** the float is closed after that key

#### Scenario: Esc closes the float
- **WHEN** the float shows and `<Esc>` is typed
- **THEN** insert mode is left and the float is closed

#### Scenario: An empty answer closes the float
- **WHEN** the server answers null or an empty list of signatures
- **THEN** no float shows and no message is shown

### Requirement: Only the answer to the newest request is shown
At most one signature request SHALL be in flight. A newer ask SHALL cancel the request in flight with `$/cancelRequest`, and a request unanswered two seconds after it was sent SHALL be cancelled. An answer SHALL be shown only when it answers the request in flight and no newer ask was recorded since that request was sent; any other answer SHALL be dropped.

#### Scenario: An older answer arriving after a newer request was sent
- **WHEN** a request is in flight, the cursor moves within the call, the newer request is sent, and the answer to the older request then arrives
- **THEN** the older request was cancelled, its answer is dropped, and the float does not change

#### Scenario: An older answer arriving before the newer request is sent
- **WHEN** a request is in flight, the cursor moves within the call, and the answer to the older request arrives before the newer request is sent
- **THEN** the answer is dropped and the newer request is sent once the debounce passed

#### Scenario: A silent server
- **WHEN** a request is unanswered two seconds after it was sent
- **THEN** it is cancelled with `$/cancelRequest` and the services stop waiting

### Requirement: The signature text is untrusted
The label SHALL be shown with escape sequences and control characters removed and at most 1,024 bytes kept, cut at a character boundary. An active signature or parameter index outside its list SHALL read as the first signature or as no marked parameter, a parameter given as a pair of offsets SHALL be marked only when both fall within the label in order, and a parameter given as text SHALL be marked only where that text occurs in the label.

#### Scenario: A hostile label
- **WHEN** the server answers a label holding escape sequences and 5,000 bytes, its parameter offsets past the label's end
- **THEN** the float shows no escape byte, at most 1,024 bytes, and no marked parameter
