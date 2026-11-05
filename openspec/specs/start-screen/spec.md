# start-screen Specification

## Purpose
The start screen is what the editor shows when it starts without a file to edit: a short animation of a gem forming, then the wordmark and key hints, until the first key.

## Requirements

### Requirement: The start screen shows when there is no file to edit
When the editor starts with no argument, or with a directory, and the `startscreen` option is on, it SHALL show the start screen over the current window's text area, leaving the status line and the message row as they are.

#### Scenario: No argument
- **WHEN** the editor starts with no argument on a 24 by 80 terminal
- **THEN** the window shows a point at the centre of where the gem will be and nothing else

#### Scenario: A directory
- **WHEN** the editor starts with the argument `src`, a directory
- **THEN** the start screen shows and the buffer is empty with no name

#### Scenario: A file
- **WHEN** the editor starts with the argument `a.txt`
- **THEN** no start screen shows

### Requirement: The gem forms in six frames
The start screen SHALL show six frames 0.125 seconds apart: a point; the gem's table; its crown; its pavilion, completing the gem; a sparkle at its top; and the wordmark `c a r a t` with the key hints under it. The last frame SHALL stay until a key arrives.

#### Scenario: Frames on the clock
- **WHEN** the start screen starts and the clock moves on by 0.125 seconds at a time
- **THEN** each move shows the next frame, the last at 0.625 seconds, and later moves change nothing

#### Scenario: Hints
- **WHEN** the last frame shows
- **THEN** under the wordmark three hints read `i` insert text, `:e file` open a file, and `:q` quit

### Requirement: Any key ends the start screen
A key typed while the start screen shows, during the animation or after it, SHALL end the start screen and SHALL be handled as it would be without it.

#### Scenario: A key during the animation
- **WHEN** `i` is typed while the second frame shows
- **THEN** the start screen is gone, the editor is in insert mode, and the window shows the empty buffer

#### Scenario: A key after the animation
- **WHEN** `:` is typed after the last frame
- **THEN** the start screen is gone and the command line reads `:`

### Requirement: The startscreen option turns it off
`option.startscreen` SHALL take true or false, true by default; with false the editor SHALL start on the empty buffer with no start screen.

#### Scenario: Off
- **WHEN** the configuration holds `option.startscreen false` and the editor starts with no argument
- **THEN** the window shows the empty buffer

#### Scenario: Not a bool
- **WHEN** the configuration holds `option.startscreen yes`
- **THEN** the problem reads `option.startscreen takes true or false`

### Requirement: Reduced motion shows the last frame
With `option.reducedmotion true` (false by default) the start screen SHALL show its last frame at once and no other.

#### Scenario: Reduced motion
- **WHEN** the configuration holds `option.reducedmotion true` and the editor starts with no argument
- **THEN** the first frame drawn shows the gem, the sparkle, the wordmark, and the hints, and moving the clock changes nothing

### Requirement: NO_COLOR gives plain glyphs
When the environment variable `NO_COLOR` is set and not empty the start screen SHALL draw with ASCII glyphs only and in the `Normal` group only.

#### Scenario: Plain
- **WHEN** the editor starts with no argument and `NO_COLOR=1`
- **THEN** every cell of the start screen holds an ASCII character in the `Normal` group

### Requirement: A small window shows only the wordmark
When the current window's text area is smaller than 20 columns or 15 rows the start screen SHALL show only the wordmark, centred and cut at the window's edge.

#### Scenario: Small terminal
- **WHEN** the editor starts with no argument on a 10 by 40 terminal
- **THEN** the window shows `c a r a t` on its middle row and no gem

### Requirement: The gem takes the theme's colors
The start screen's cells SHALL carry the theme's groups: `Operator`, `Function`, and `Keyword` for the facets, `Type` for the point and the sparkle, `Title` for the wordmark, `Special` for the hint keys, and `Comment` for the hint text.

#### Scenario: Colors
- **WHEN** the last frame shows on a 256-color terminal with the default theme
- **THEN** the wordmark's cells carry `Title` and the sparkle's `Type`
