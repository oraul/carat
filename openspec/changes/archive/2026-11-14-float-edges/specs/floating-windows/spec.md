## ADDED Requirements

### Requirement: A float's text fits the screen beside its frame
A float's frame SHALL be its padding, one column on each side, and, when it is bordered and `option.winborder` draws an edge, its border, one column on each side. The floats the editor opens (the command palette, the documentation float, the signature float, the definition peek and pick list, and the key hints) SHALL lay their rows out no wider than the screen less that frame, so the screen cuts none of their rows and every row keeps its right padding and border at the box's edge.

#### Scenario: The palette keeps its right border while the filter shrinks
- **WHEN** the screen is 120 by 36 or 60 by 24 and "<Space>p" is typed and then a filter one key at a time until nothing matches
- **THEN** after each key every row of the palette's box ends with its right border in the box's last column, and each row is shown whole up to the padding before that border

#### Scenario: Without an edge the palette uses the border columns
- **WHEN** `option.winborder none` is set, the screen is 60 by 24, and "<Space>p" is typed
- **THEN** the palette's text is 58 columns wide, the screen less its padding, and each row is shown whole

#### Scenario: An 80-column hover row shows its last word
- **WHEN** the screen is 80 columns wide and `K` shows documentation of one paragraph longer than the screen
- **THEN** the float's rows are wrapped at 76 columns and the last word of each row is drawn inside the box, before its right padding and border

#### Scenario: The signature and the peek fit a narrow screen
- **WHEN** the screen is 40 columns wide and a signature label or a peeked definition line is longer than the screen
- **THEN** the float's text is 36 columns wide and shown whole, its right border in the screen's last column

#### Scenario: The key hints use the border columns without an edge
- **WHEN** the screen is 36 by 6 and "<Space>x" shows nine hints of 10 cells, or a hint longer than the screen, once under `rounded` and once under `none`
- **THEN** the hints' text is at most 32 columns wide under `rounded`, fitting 2 columns of hints, and at most 34 under `none`, fitting 3, the long hint cut to that width

#### Scenario: The frame rule
- **WHEN** a float's widest text is asked for a 40-column screen, bordered under `rounded`, bordered under `none`, and without a border
- **THEN** it is 36, 38, and 38 columns, and a placed box is never wider than the screen it is placed in
