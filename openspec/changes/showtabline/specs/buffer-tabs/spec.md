## MODIFIED Requirements

### Requirement: Buffer tabs take the top row from two buffers or two tab pages
Under `option.showtabline` 2, row 0 SHALL always be the buffer tabs row; under 1, when two or more file buffers are listed or two or more tab pages exist, and not otherwise; under 0, never. When the row shows the windows SHALL be laid out from row 1, otherwise from row 0. Scratch buffers, such as the file tree, SHALL get no tab. The row SHALL be filled in `TabLineFill`.

#### Scenario: A second file shows the row
- **WHEN** "a.txt" is shown under `option.showtabline 1` and ":e b.txt" is run
- **THEN** row 0 is the buffer tabs row and the first text row of the window is row 1

#### Scenario: One file has no row under 1
- **WHEN** only "a.txt" is listed in one tab page under `option.showtabline 1`
- **THEN** row 0 is the first text row

#### Scenario: One file has the row under 2
- **WHEN** only "a.txt" is listed in one tab page under `option.showtabline 2`
- **THEN** row 0 reads "  • a.txt   │" from column 0 and the first text row of the window is row 1

#### Scenario: The open file's modified mark follows its name under 2
- **WHEN** only "a.txt", modified, is listed under `option.showtabline 2`
- **THEN** row 0 reads "  • a.txt ● │" from column 0

#### Scenario: Never hides the row
- **WHEN** two files are listed under `option.showtabline 0`
- **THEN** row 0 is the first text row of the window

#### Scenario: Always shows the row with no file
- **WHEN** no file is listed under `option.showtabline 2`
- **THEN** row 0 is the buffer tabs row and the first text row of the window is row 1
