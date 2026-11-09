# Spec Delta

## ADDED Requirements

### Requirement: Progress segment

While long work runs, the status bar SHALL show a progress segment before the `lsp` slot, at priority 35: a space, the work's title followed by its message when it has one (cut to 40 bytes), a space, a ten-cell bar, and a space. With a percent the bar SHALL show one done cell per ten percent, done cells `━` in `StatusLineLspReady` and the rest `─` in `StatusLine`. The segment SHALL go when the work ends.

#### Scenario: A bar at a percent

- **WHEN** work titled `Indexing` reports 40 percent
- **THEN** the bar reads ` Indexing ━━━━────── ` with four done cells in `StatusLineLspReady`

### Requirement: Progress without a percent and plain progress

Without a percent the progress bar SHALL show three done cells that move one cell for each report; with `option.reducedmotion true` such a bar SHALL be left out and only the title shown. With `NO_COLOR` set and not empty, done cells SHALL be `#` and the rest `-`, all in `StatusLine`.

#### Scenario: Reduced motion leaves out a bar without a percent

- **WHEN** `option.reducedmotion` is true and work titled `Indexing` reports no percent
- **THEN** the segment reads ` Indexing `

#### Scenario: Plain bar under NO_COLOR

- **WHEN** `NO_COLOR` is set and work titled `Indexing` reports 40 percent
- **THEN** the segment reads ` Indexing ####------ ` in `StatusLine`

#### Scenario: A narrow bar drops the segment before the file type

- **WHEN** the bar is too narrow for every segment
- **THEN** the progress segment (35) is dropped after the file type (30) and before the branch (40)
