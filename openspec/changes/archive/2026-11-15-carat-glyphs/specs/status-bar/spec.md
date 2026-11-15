## MODIFIED Requirements

### Requirement: Progress without a percent and plain progress

Without a percent the progress bar SHALL show three done cells that move one cell for each report; with `option.reducedmotion true` such a bar SHALL be left out and only the title shown. With `option.icons ascii`, done cells SHALL be `#` and the rest `-`, the done cells still in `StatusLineLspReady`. With `NO_COLOR` set and not empty, done cells SHALL be `#` and the rest `-`, all in `StatusLine`.

#### Scenario: Reduced motion leaves out a bar without a percent

- **WHEN** `option.reducedmotion` is true and work titled `Indexing` reports no percent
- **THEN** the segment reads ` Indexing `

#### Scenario: An ascii bar

- **WHEN** `option.icons` is "ascii" and work titled `Indexing` reports 40 percent
- **THEN** the segment reads ` Indexing ####------ ` with four done cells in `StatusLineLspReady`

#### Scenario: Plain bar under NO_COLOR

- **WHEN** `NO_COLOR` is set and work titled `Indexing` reports 40 percent
- **THEN** the segment reads ` Indexing ####------ ` in `StatusLine`

#### Scenario: A narrow bar drops the segment before the file type

- **WHEN** the bar is too narrow for every segment
- **THEN** the progress segment (35) is dropped after the file type (30) and before the branch (40)
