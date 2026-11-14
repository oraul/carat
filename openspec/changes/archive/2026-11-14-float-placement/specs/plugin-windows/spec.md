## MODIFIED Requirements

### Requirement: A plugin's float requests are checked
An unknown anchor, a size below one row or column, a z order outside 0 to 1000, a row or column offset outside -10000 to 10000, a full tab page, an unknown id, and another plugin's float SHALL fail with a message and change nothing; an offset out of range SHALL be refused when a float opens and when it moves.

#### Scenario: Refused requests
- **WHEN** a plugin opens a float with the anchor "window", or closes a float another plugin opened
- **THEN** the request fails with a message and every float stays as it was

#### Scenario: An offset out of range is refused
- **WHEN** a plugin opens a float at column 10001, or moves its float to row -10001
- **THEN** the request fails with "No offset 10001: -10000 to 10000" or "No offset -10001: -10000 to 10000" and every float stays as it was

#### Scenario: API version
- **WHEN** a plugin declares API 2.6
- **THEN** it is accepted, as a plugin declaring 2.1 is

## ADDED Requirements

### Requirement: A plugin reads the float frame
A plugin SHALL ask the host for the frame of a float it would open, bordered or not: the border cells on each side under the current `option.winborder`, the padding on each side, and the margin the host keeps from the screen's edges, with the box width of a text width. The request SHALL change nothing.

#### Scenario: The frame under each border
- **WHEN** a plugin asks for the frame of a bordered float under the shipped border, under `option.winborder none`, and of a float without a border
- **THEN** the answers have an edge of 1, 0, and 0 cells, a padding of 1, and a margin of 1, and a 10-column text makes a box 14, 12, and 12 columns wide
