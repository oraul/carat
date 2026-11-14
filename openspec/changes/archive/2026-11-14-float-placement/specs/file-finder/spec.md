## REMOVED Requirements

### Requirement: The finder's boxes share an edge or keep a gap
**Reason**: The finder now reads the float frame from the host, so its boxes share an edge under every border style and the gap under `option.winborder none` is gone.
**Migration**: None; the requirement "The finder's boxes share an edge" replaces it.

## ADDED Requirements

### Requirement: The finder's boxes share an edge
The finder SHALL size its boxes from the float frame the host answers, so under every border style the list box starts one column from the screen's left edge, the list box alone ends one column before the screen's right edge, and with the preview the preview box starts in the column after the list box, sharing its edge, and ends one column before the screen's right edge. The boxes SHALL never overlap and never leave a column of the window under them between them.

#### Scenario: The finder boxes share an edge
- **WHEN** the screen is 120 columns wide under the shipped border and the finder opens on a project with a file
- **THEN** the list box spans columns 1 to 59 and the preview box columns 60 to 118, the list's right border in column 59 and the preview's left border in column 60

#### Scenario: The finder boxes share an edge without a border
- **WHEN** the screen is 120 columns wide under `option.winborder none` and the finder opens on a project with a file
- **THEN** the list box spans columns 1 to 59 and the preview box columns 60 to 118, no column between them
