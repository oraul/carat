## MODIFIED Requirements

### Requirement: Message history

The editor SHALL keep every non-empty one-line message shown on the message row, and every notification, in the order shown, dropping the oldest past 500 entries. An error of several lines SHALL be kept whole. A listing, the output of `:messages`, and the pattern echo of a search that finds its match SHALL NOT be kept; the wrap message and the error of a search that finds nothing SHALL be.

#### Scenario: An error is kept after the next key

- **WHEN** the user types `:foo<CR>`, then `l`, then `:messages<CR>`
- **THEN** the message row reads `E492: Not an editor command: foo`

#### Scenario: A listing is not kept

- **WHEN** the user types `:registers<CR>`, then Enter, then `:messages<CR>`
- **THEN** the message row is empty

#### Scenario: The oldest entry is dropped

- **WHEN** 501 one-line messages have been shown
- **THEN** the history holds 500 entries and the first shown is not among them

#### Scenario: The echo of a search is not kept

- **WHEN** the user types `/line 2<CR>`, then `n`, then `:messages<CR>`
- **THEN** the message row is empty, and the same holds after `N`, `*`, `#`, and `?`

#### Scenario: The wrap message of a search is kept

- **WHEN** the cursor is on the last line and the user types `/line 1 of<CR>`, then `:messages<CR>`
- **THEN** the message row reads `search hit BOTTOM, continuing at TOP`

#### Scenario: The refusal of a quit over an unsaved buffer is kept whole

- **WHEN** a buffer with changes is hidden behind another, the user types `:qa<CR>`, then `:messages<CR>`
- **THEN** the listing holds the `E37` line and the `E162` line naming the buffer, followed by `Press ENTER or type command to continue`
