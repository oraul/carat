# search Specification

## Purpose
Pattern search in a buffer as Neovim does it: the search prompt, repeating a search, searching for the word under the cursor, search as a motion, the pattern language Carat supports, and the highlighting of matches, with every pattern treated as untrusted input.

## Requirements

### Requirement: Slash and question mark search for a typed pattern
Pressing "/" or "?" in normal, operator-pending, or a visual mode SHALL open the command line with "/" or "?" as its prompt. Enter SHALL move the cursor to the start of the next match after the cursor ("/") or the previous match before it ("?"), remember the pattern and its direction, and show the prompt and the pattern. An empty pattern SHALL reuse the last pattern. Escape, or Backspace on an empty prompt, SHALL return to the mode the prompt came from.

#### Scenario: Search forward
- **WHEN** "/", "b", "a", "r", Enter are pressed on ["foo bar", "bar"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 4, the mode is normal, and the message row shows "/bar"

#### Scenario: Search backward
- **WHEN** "?", "f", "o", "o", Enter are pressed on ["foo", "x foo"] with the cursor at row 1, column 2
- **THEN** the cursor is at row 0, column 0

#### Scenario: Empty pattern reuses the last one
- **WHEN** "/", "o", Enter, then "/", Enter are pressed on ["foo"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 2

#### Scenario: Empty pattern with no last pattern
- **WHEN** "/", Enter are pressed
- **THEN** the message is the error "E35: No previous regular expression"

#### Scenario: Escape cancels the search
- **WHEN** "/", "b", Escape are pressed on ["ab"] with the cursor at row 0, column 0
- **THEN** the mode is normal and the cursor is at row 0, column 0

### Requirement: n and N repeat the last search
"n" SHALL repeat the last search in its direction and "N" in the opposite one, showing the pattern with the direction's prompt character. With no last pattern both SHALL show "E35: No previous regular expression" and leave the cursor.

#### Scenario: n repeats forward
- **WHEN** "/", "a", Enter, "n" are pressed on ["a a a"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 4

#### Scenario: N reverses
- **WHEN** "/", "a", Enter, "n", "N" are pressed on ["a a a"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 2 and the message row shows "?a"

#### Scenario: n before any search
- **WHEN** "n" is pressed
- **THEN** the message is the error "E35: No previous regular expression"

### Requirement: Star and hash search for the word under the cursor
"*" SHALL search forward and "#" backward for the keyword under or after the cursor as a whole word, and "g*" and "g#" for the same text without word boundaries. With no keyword the non-blank text there SHALL be used, and with none "E348: No string under cursor" SHALL be shown. The pattern SHALL become the last pattern and a history entry, and these searches SHALL ignore "smartcase".

#### Scenario: Star finds the next whole word
- **WHEN** "*" is pressed on ["foo food foo"] with the cursor at row 0, column 1
- **THEN** the cursor is at row 0, column 9

#### Scenario: g star finds part of a word
- **WHEN** "g", "*" are pressed on ["foo food foo"] with the cursor at row 0, column 1
- **THEN** the cursor is at row 0, column 4

#### Scenario: Hash searches backward from the start of the word
- **WHEN** "#" is pressed on ["foo x foo"] with the cursor at row 0, column 7
- **THEN** the cursor is at row 0, column 0

#### Scenario: No string under the cursor
- **WHEN** "*" is pressed on ["   "]
- **THEN** the message is the error "E348: No string under cursor"

### Requirement: Searches take a count
A count before "/", "?", "n", "N", "*", "#", "g*", or "g#" SHALL move to the count-th match in the search's direction.

#### Scenario: Count with n
- **WHEN** "/", "a", Enter, "2", "n" are pressed on ["a a a a"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 6

#### Scenario: Count with slash
- **WHEN** "3", "/", "a", Enter are pressed on ["a a a a"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 6

### Requirement: A search wraps around the buffer
A search that passes the end of the buffer SHALL continue at its start, and one that passes the start at its end, showing "search hit BOTTOM, continuing at TOP" or "search hit TOP, continuing at BOTTOM". A pattern with no match SHALL leave the cursor and show the error "E486: Pattern not found: " followed by the pattern.

#### Scenario: Wrap at the bottom
- **WHEN** "/", "a", Enter are pressed on ["a", "b", "x"] with the cursor at row 2, column 0
- **THEN** the cursor is at row 0, column 0 and the message is "search hit BOTTOM, continuing at TOP"

#### Scenario: Wrap at the top
- **WHEN** "?", "x", Enter are pressed on ["a", "b", "x"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 2, column 0 and the message is "search hit TOP, continuing at BOTTOM"

#### Scenario: Pattern not found
- **WHEN** "/", "z", Enter are pressed on ["abc"]
- **THEN** the cursor is unchanged and the message is the error "E486: Pattern not found: z"

### Requirement: A search is an exclusive motion
Under an operator, "/" with its pattern, "?", "n", "N", "*", "#", "g*", and "g#" SHALL be exclusive charwise motions, and a delete or change over them SHALL write register 1 as the motions Vim lists do. The dot command SHALL repeat the operator with the same pattern. In a visual mode a search SHALL move the cursor end of the selection.

#### Scenario: Delete up to a match
- **WHEN** "d", "/", "b", "a", "r", Enter are pressed on ["foo bar"] with the cursor at row 0, column 0
- **THEN** the line is "bar"

#### Scenario: Change to the next match
- **WHEN** "/", "x", Enter, "0", "c", "n", "Y", Escape are pressed on ["ab x"] with the cursor at row 0, column 0
- **THEN** the line is "Yx"

#### Scenario: Visual extends to a match
- **WHEN** "v", "/", "c", Enter, "d" are pressed on ["abcd"] with the cursor at row 0, column 0
- **THEN** the line is "d"

### Requirement: Magic patterns are translated and malformed ones reported
A pattern SHALL be read as Vim's magic pattern with the items `docs/compatibility.md` lists: wildcards, multis, collections, anchors, groups, alternation, word boundaries, class escapes, case flags, and the four magic modes; every other character SHALL match itself. A malformed pattern SHALL show Vim's error for it, and an unsupported item SHALL show "Not implemented: " followed by the item and " in a pattern"; neither SHALL move the cursor.

#### Scenario: Magic characters
- **WHEN** "/", "b", ".", "\", "+", "d", Enter are pressed on ["a bcccd"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 2

#### Scenario: Unmatched group
- **WHEN** "/", "\", "(", "a", Enter are pressed on ["a"]
- **THEN** the message is the error "E54: Unmatched \("

#### Scenario: Nested multi
- **WHEN** "/", "a", "*", "*", Enter are pressed on ["a"]
- **THEN** the message is the error "E61: Nested *"

#### Scenario: Back reference
- **WHEN** "/", "\", "(", "a", "\", ")", "\", "1", Enter are pressed on ["aa"]
- **THEN** the message is the error "Not implemented: \1 in a pattern"

### Requirement: Case follows ignorecase and smartcase
With "ignorecase" off a pattern SHALL match case. With it on a pattern SHALL ignore case, unless "smartcase" is on and the typed pattern holds an uppercase letter. "\c" anywhere SHALL ignore case and "\C" SHALL match it, whatever the options. The options SHALL be set from the configuration and by ":set".

#### Scenario: Ignorecase
- **WHEN** ":set ic" is run, then "/", "F", "O", "O", Enter are pressed on ["x foo"]
- **THEN** the message is the error "E486: Pattern not found: FOO" because smartcase is on in the default configuration

#### Scenario: Smartcase off
- **WHEN** ":set ic noscs" is run, then "/", "F", "O", "O", Enter are pressed on ["x foo"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 2

#### Scenario: Backslash c
- **WHEN** "/", "\", "c", "F", "O", "O", Enter are pressed on ["x foo"] with the cursor at row 0, column 0
- **THEN** the cursor is at row 0, column 2

### Requirement: An untrusted pattern never crashes or hangs the editor
A pattern SHALL only reach the matching engine in a form it matches without backtracking, and one whose compiled size passes the limit SHALL show "E363: pattern uses more memory than 'maxmempattern'". A search SHALL stop with an error before its work passes its budget, every match it tries counted at no less than its line's length, and a frame SHALL stop highlighting when its own budget is spent. A line that is not valid UTF-8 SHALL be searched with each illegal byte as U+FFFD.

#### Scenario: Illegal byte in the line
- **WHEN** "/", "b", Enter are pressed on a line holding "a", the byte 0xFF, and "b"
- **THEN** the cursor is at row 0, column 2

#### Scenario: Oversized pattern
- **WHEN** "/", "\", "(", "a", "\", "{", "9", "9", "9", "}", "\", ")", "\", "{", "9", "9", "9", "}", Enter are pressed
- **THEN** the message is the error "E363: pattern uses more memory than 'maxmempattern'"

#### Scenario: Many matches on a long line searched backward
- **WHEN** "é" is searched backward from the end of a line of 200,000 "é"
- **THEN** the search stops with "E363: search stopped, pattern too costly here" instead of trying every match

### Requirement: The search history is recalled on the command line
Each pattern entered at a search prompt and each "*", "#", "g*", or "g#" pattern SHALL be added to the search history, the newest last, without duplicates and at most 50 entries. At a search prompt "<Up>" SHALL replace the text with the next older entry that starts with what was typed before the first recall, and "<Down>" with the next newer one, returning to the typed text after the newest.

#### Scenario: Recall the last pattern
- **WHEN** "/", "a", Enter, then "/", "b", Enter, then "/", "<Up>" are pressed
- **THEN** the command line shows "b"

#### Scenario: Recall by prefix
- **WHEN** "/", "a", "x", Enter, then "/", "b", Enter, then "/", "a", "<Up>" are pressed
- **THEN** the command line shows "ax"

### Requirement: Matches are highlighted
With "hlsearch" on, every match of the last pattern in the visible rows SHALL be drawn in the `Search` group until ":noh[lsearch]" hides it; the next search, "n", or ":set hlsearch" SHALL show it again. With "incsearch" on, the cursor SHALL move to the first match of the pattern being typed, drawn in `IncSearch`, while the other matches of that pattern are drawn in `Search` when "hlsearch" is on; Escape SHALL put the cursor back. An empty match SHALL not be drawn.

#### Scenario: hlsearch draws every match
- **WHEN** "/", "a", Enter are pressed on ["a b a"]
- **THEN** the cells of both "a" are in the `Search` group and the "b" is not

#### Scenario: noh hides the highlight
- **WHEN** "/", "a", Enter are pressed on ["a b a"], then ":noh" is run
- **THEN** no cell is in the `Search` group

#### Scenario: incsearch previews the match
- **WHEN** "/", "b" are pressed on ["a b"] with the cursor at row 0, column 0
- **THEN** the cursor of the buffer is at row 0, column 2 and that cell is in the `IncSearch` group
