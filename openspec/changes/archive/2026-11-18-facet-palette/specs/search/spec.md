## MODIFIED Requirements

### Requirement: Matches are highlighted
With "hlsearch" on, every match of the last pattern in the visible rows SHALL be drawn in the `Search` group, the cursor's in `CurSearch`, until ":noh[lsearch]" hides it; the next search, "n", or ":set hlsearch" SHALL show it again. With "incsearch" on, the cursor SHALL move to the first match of the pattern being typed, drawn in `IncSearch`, while the other matches of that pattern are drawn in `Search` when "hlsearch" is on; Escape SHALL put the cursor back. An empty match SHALL not be drawn.

#### Scenario: hlsearch draws every match
- **WHEN** "/", "a", Enter are pressed on ["a b a"]
- **THEN** the cells of the first "a" are in the `Search` group, the second "a", where the cursor is, in `CurSearch`, and the "b" in neither

#### Scenario: noh hides the highlight
- **WHEN** "/", "a", Enter are pressed on ["a b a"], then ":noh" is run
- **THEN** no cell is in the `Search` group

#### Scenario: incsearch previews the match
- **WHEN** "/", "b" are pressed on ["a b"] with the cursor at row 0, column 0
- **THEN** the cursor of the buffer is at row 0, column 2 and that cell is in the `IncSearch` group

## ADDED Requirements

### Requirement: The match under the cursor stands out
While "hlsearch" shows the matches, the match holding a window's cursor SHALL be drawn in `CurSearch`, bold, in place of `Search`, in every window.

#### Scenario: The current match is bold
- **WHEN** "a" is the last pattern with "hlsearch" on and the cursor is on the first "a" of ["a ba"]
- **THEN** that cell is in `CurSearch`, which is bold, and the other "a" is in `Search`
