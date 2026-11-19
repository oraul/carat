## MODIFIED Requirements

### Requirement: A wide screen previews the highlighted file
When the screen is at least 100 columns wide a second bordered float, right of the list and titled with the highlighted path, SHALL show the first rows of the highlighted file, following the highlight; a file that cannot be read SHALL show its message as the only row. A narrower screen SHALL show no preview. The grep picker's preview is its own requirement.

#### Scenario: A wide screen shows the preview
- **WHEN** the screen is 120 columns wide and the highlighted file is `lib/beta.rb` holding `b = 2`
- **THEN** a float titled `lib/beta.rb` shows `b = 2`

#### Scenario: A narrow screen shows no preview
- **WHEN** the screen is 80 columns wide and the finder opens
- **THEN** only the list float shows

## REMOVED Requirements

### Requirement: The grep list uses the whole width
**Reason**: The grep picker now shows a preview beside its list, so its list no longer uses the whole width.
**Migration**: The requirement The grep list is sized as the file finder's list replaces it.

## ADDED Requirements

### Requirement: The grep list is sized as the file finder's list
The grep list SHALL use the width and the place the file finder's list has beside its preview, and its preview the width and the place of the file finder's.

#### Scenario: The grep list is sized as the file finder's list
- **WHEN** the screen is 120 columns wide and the user types a query that matches a line
- **THEN** the list and the preview float have the width and the column of the file finder's list and preview

### Requirement: A wide screen previews the grep row's file around its line
When the screen is at least 100 columns wide the grep picker SHALL show a second bordered float beside its list, titled with the highlighted row's path, showing as many lines of that file as the float is high with the row's line in the middle, from the text the picker read when it opened and never from a new file read. The row's line SHALL start with the list's highlight mark `> ` and every other line with two spaces. A narrower screen SHALL show no preview.

#### Scenario: A wide screen previews the matched line
- **WHEN** the screen is 120 columns wide on 24 rows and the highlighted row is line 20 of a file of 40 lines
- **THEN** a float titled with the file's path shows lines 11 to 28 with line 20 marked

#### Scenario: A narrow screen shows no grep preview
- **WHEN** the screen is 99 columns wide and the user types a query that matches a line
- **THEN** only the list float shows

### Requirement: The grep preview is centred and clamped at the file's ends
The preview window SHALL start at the row's line number less half the float's height, moved to start at line 1 when that is lower, and to end at the file's last stored line when it would end later; a file with fewer lines SHALL show whole. A line the picker did not store because it is empty SHALL show as an empty line, and the window SHALL cover no line past the first 1000 of a file.

#### Scenario: The preview is centred on the matched line
- **WHEN** the highlighted row is line 50 of a file of 100 lines on a 24-row screen
- **THEN** the preview shows lines 41 to 58 with line 50 the tenth

#### Scenario: The preview is clamped at the file's start and end
- **WHEN** the highlighted row is line 3, or line 38 of 40, or line 995 of a file of 1200 lines
- **THEN** the preview shows lines 1 to 18, 23 to 40, or 983 to 1000

### Requirement: The grep preview follows the highlight and the query
The preview SHALL show the highlighted row's file and line after each move of the highlight and each change of the query, and no preview SHALL show while no row does, with the empty query or a query that matches nothing.

#### Scenario: The preview follows the highlight and the query
- **WHEN** the highlight moves to a row of another file, or the query changes so another line is first
- **THEN** the preview shows that row's file around its line

#### Scenario: An empty result shows no preview
- **WHEN** the query matches no line
- **THEN** only the list float shows

### Requirement: The grep preview shows its text safely
Each preview line and the preview's title SHALL show each control character, each bidirectional and invisible format or separator character a row shows as a space, and each byte of invalid UTF-8 as a question mark, and a line over 400 bytes SHALL show cut at 400 bytes.

#### Scenario: The preview shows its text safely
- **WHEN** a previewed file holds an escape character, a bell, the bytes FF and FE, or U+202E, and a path holds a tab
- **THEN** the preview holds spaces and question marks in their place
