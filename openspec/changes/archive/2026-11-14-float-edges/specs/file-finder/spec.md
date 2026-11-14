## ADDED Requirements

### Requirement: The finder's boxes share an edge or keep a gap
The finder's list box SHALL start one column from the screen's left edge. With a border style that draws an edge, the list box alone SHALL end one column before the screen's right edge, and with the preview the preview box SHALL start in the column after the list box, sharing its edge, and end one column before the screen's right edge. Under `option.winborder none` each box SHALL lose its two edge columns and keep its padding, so the boxes stand two columns apart and never overlap.

#### Scenario: The finder boxes share an edge
- **WHEN** the screen is 120 columns wide under the shipped border and the finder opens on a project with a file
- **THEN** the list box spans columns 1 to 59 and the preview box columns 60 to 118, the list's right border in column 59 and the preview's left border in column 60

#### Scenario: The finder boxes keep a gap without an edge
- **WHEN** the screen is 120 columns wide under `option.winborder none` and the finder opens on a project with a file
- **THEN** the list box spans columns 1 to 57 and the preview box starts at column 60, with columns 58 and 59 showing the window under them
