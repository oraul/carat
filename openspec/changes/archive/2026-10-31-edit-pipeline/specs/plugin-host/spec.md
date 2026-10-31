## MODIFIED Requirements

### Requirement: Events are delivered as values after the key that caused them
After a key has been handled, the host SHALL deliver to every subscribed plugin, in registration order, the events the key caused, in this order: `buffer_open` for each buffer that entered the list, `buffer_change` when the current buffer's text changed, `cursor_move` when the cursor or the current buffer changed, `mode_change` when the mode changed, `window_focus` when the current window or tab page changed, and `quit` when the editor is about to end.

#### Scenario: Opening a file
- **WHEN** a test plugin subscribed to every event is active and ":e b.txt" is run
- **THEN** it receives buffer_open for the new buffer, then cursor_move, in that order

#### Scenario: Editing
- **WHEN** "x" is pressed in a buffer with text
- **THEN** the plugin receives buffer_change then cursor_move, and no mode_change

#### Scenario: Reloading the current buffer
- **WHEN** a test plugin subscribed to every event is active and ":e!" is run on the current buffer
- **THEN** the plugin receives buffer_change

#### Scenario: Entering insert mode
- **WHEN** "i" is pressed
- **THEN** the plugin receives mode_change with the detail "insert"

#### Scenario: Quitting
- **WHEN** ":q" is run on a clean buffer
- **THEN** the plugin receives quit and then its deactivate is called

#### Scenario: Unsubscribed events are not delivered
- **WHEN** the hello plugin, subscribed only to buffer_open, is active and "x" is pressed
- **THEN** the hello plugin receives nothing
