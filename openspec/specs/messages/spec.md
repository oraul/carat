# messages Specification

## Purpose
Keeps what the editor told the user readable after it left the message row, and shows asynchronous news in short-lived notifications at the top right of the screen.

## Requirements

### Requirement: Message history

The editor SHALL keep every non-empty one-line message shown on the message row, informational or error, and every notification, in the order shown, dropping the oldest past 500 entries. A message of several lines (a listing such as `:registers` or `:ls`) and the output of `:messages` SHALL NOT be kept.

#### Scenario: An error is kept after the next key

- **WHEN** the user types `:foo<CR>`, then `l`, then `:messages<CR>`
- **THEN** the message row reads `E492: Not an editor command: foo`

#### Scenario: A listing is not kept

- **WHEN** the user types `:registers<CR>`, then Enter, then `:messages<CR>`
- **THEN** the message row is empty

#### Scenario: The oldest entry is dropped

- **WHEN** 501 one-line messages have been shown
- **THEN** the history holds 500 entries and the first shown is not among them

### Requirement: The messages command

`:mes[sages]` SHALL show the history: one entry on the message row, several as a listing over the bottom rows with the hit-enter prompt, none as nothing. `:messages clear` SHALL empty the history. Any other argument SHALL be refused with `E474: Invalid argument`.

#### Scenario: Several entries are listed

- **WHEN** two errors have been shown and the user types `:mes<CR>`
- **THEN** both are listed in the order shown, followed by `Press ENTER or type command to continue`

#### Scenario: Clear empties the history

- **WHEN** the user types `:messages clear<CR>` and then `:messages<CR>`
- **THEN** the message row is empty

#### Scenario: Another argument is refused

- **WHEN** the user types `:messages all<CR>`
- **THEN** the message row reads `E474: Invalid argument` as an error

### Requirement: Notifications

A notification SHALL be a bordered box of three rows at the top right, from the row under the buffer tabs, its right edge one column from the screen's, its text plus four wide within half the screen and at least 20. Its top border SHALL name its severity (`Error`, `Warning`, or `Info`) in that severity's group, centered with a blank on each side as a float title, its text in `NormalFloat`. A box reaching the status bar SHALL NOT be drawn; no box changes a buffer, cursor, or mode.

#### Scenario: A warning shows at the top right

- **WHEN** a warning notification `disk almost full` arrives on a 60-column screen
- **THEN** rows 0 to 2 end one column before the right edge with a box whose top border holds `Warning` and whose middle row holds `disk almost full`

#### Scenario: A notification title is centered like a float title

- **WHEN** `option.winborder double` is set and a warning notification `disk almost full` arrives on a 60-column screen
- **THEN** its top border reads `╔════ Warning ═════╗`, the title and its blanks in the warning's group

### Requirement: Notification stacking and expiry

At most three notifications SHALL show, stacked downward oldest first; a fourth SHALL replace the oldest. A notification SHALL leave after 3 seconds (info), 5 seconds (warning), or 8 seconds (error), with no key needed. Notifications SHALL NOT animate, with or without `option.reducedmotion`.

#### Scenario: Expiry by severity

- **WHEN** an info, a warning, and an error notification arrive together and the clock advances 4 seconds, then 2 more, then 3 more
- **THEN** two boxes remain after 4 seconds, one after 6, and none after 9

#### Scenario: A fourth replaces the oldest

- **WHEN** four notifications arrive
- **THEN** three boxes show and the first notification's text is not drawn

#### Scenario: Keys go on under a notification

- **WHEN** a notification shows and the user types `lh`
- **THEN** the cursor moves as without it and the box is still drawn

### Requirement: Plain notifications under NO_COLOR

With `NO_COLOR` set and not empty, a notification box SHALL be drawn with `+`, `-`, and `|` and every cell of it in the `Normal` group.

#### Scenario: A plain box

- **WHEN** `NO_COLOR` is set and an error notification arrives
- **THEN** its box corners read `+`, its top border holds `Error`, and its cells are in `Normal`
