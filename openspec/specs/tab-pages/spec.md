# tab-pages Specification

## Purpose
Tab pages hold independent window layouts that the user switches between with ex commands and gt and gT; the tab line at the top of the screen lists them whenever there is more than one.

## Requirements

### Requirement: Opening a tab page
":tabnew" SHALL open a new tab page after the current one with one window showing a new empty buffer with no name and make it current; ":tabe file" and ":tabedit file" SHALL do the same showing the file, opened as ":e file" does; ":tabe" and ":tabedit" without a file SHALL behave as ":tabnew".

#### Scenario: Tab new
- **WHEN** ":tabnew" is run while "a.txt" is shown
- **THEN** there are two tab pages, the second is current, its window shows an unnamed empty buffer, and the first still shows "a.txt"

#### Scenario: Tab edit a file
- **WHEN** ":tabe b.txt" is run and "b.txt" holds "zz"
- **THEN** the new tab page is current and its window shows ["zz"] for "b.txt"

#### Scenario: Tab edit without a file
- **WHEN** ":tabedit" is run
- **THEN** the new tab page shows an unnamed empty buffer

#### Scenario: New tab after the current one
- **WHEN** three tab pages exist, the first is current, and ":tabnew" is run
- **THEN** the new tab page is the second of four and is current

### Requirement: Closing tab pages
":tabc" and ":tabclose" SHALL close the current tab page and make the one before it current, or the first when the first was closed; on the last tab page the message SHALL be "E784: Cannot close last tab page". ":tabo" and ":tabonly" SHALL close every other tab page; with one tab page the message SHALL be "Already only one tab page". A modified buffer shown only in a closed tab page SHALL stay hidden in the buffer list.

#### Scenario: Tab close
- **WHEN** ":tabnew" then ":tabclose" are run
- **THEN** one tab page remains and it shows "a.txt"

#### Scenario: Close the first of three
- **WHEN** three tab pages exist, the first is current, and ":tabc" is run
- **THEN** two remain and the first of them is current

#### Scenario: Last tab page
- **WHEN** ":tabclose" is run with one tab page
- **THEN** the message is "E784: Cannot close last tab page"

#### Scenario: Tab only
- **WHEN** ":tabnew" is run twice and ":tabonly" is run
- **THEN** one tab page remains, the one that was current

#### Scenario: Already only one tab page
- **WHEN** ":tabo" is run with one tab page
- **THEN** the message is "Already only one tab page"

#### Scenario: Hidden buffer after tab close
- **WHEN** ":tabe b.txt" is run, "x" is pressed, ":tabclose" is run, and ":qa" is run
- **THEN** the editor stays and the message is "E37: No write since last change (add ! to override)"

### Requirement: Closing the last window of a tab page closes it
":q", `<C-w>q`, and `<C-w>c` on the only window of a tab page SHALL close that tab page when another tab page exists, and SHALL end the editor or report E444 as they do for the last window only when it is the last window of the last tab page.

#### Scenario: Quit closes the tab page
- **WHEN** ":tabnew" then ":q" are run
- **THEN** one tab page remains, showing "a.txt", and the editor is still running

#### Scenario: Close closes the tab page
- **WHEN** ":tabnew" then `<C-w>c` are run
- **THEN** one tab page remains and the editor is still running

### Requirement: Moving between tab pages
":tabn", ":tabnext", and "gt" SHALL make the next tab page current, wrapping from the last to the first; ":tabp", ":tabprevious", ":tabN", ":tabNext", and "gT" SHALL make the previous one current, wrapping from the first to the last; ":tabfir", ":tabfirst", ":tabl", and ":tablast" SHALL go to the first and the last. "{count}gt" SHALL go to tab page number count, or do nothing when there is no such tab page; "{count}gT" SHALL go count tab pages back, wrapping.

#### Scenario: gt and gT wrap
- **WHEN** two tab pages exist, the second is current, and "gt" is pressed
- **THEN** the first is current, and after "gT" the second is current again

#### Scenario: Ex next and previous
- **WHEN** two tab pages exist, the first is current, and ":tabn" is run, then ":tabp", then ":tabN", then ":tabnext"
- **THEN** the current tab page is the second, the first, the second, and the first in turn

#### Scenario: First and last
- **WHEN** three tab pages exist and ":tabl" is run, then ":tabfir"
- **THEN** the third is current after ":tabl" and the first after ":tabfir"

#### Scenario: Counted gt
- **WHEN** three tab pages exist, the first is current, and "3gt" is typed
- **THEN** the third is current, and "5gt" keeps it current

#### Scenario: Counted gT
- **WHEN** three tab pages exist, the first is current, and "2gT" is typed
- **THEN** the second is current

### Requirement: Each tab page keeps its own windows
Windows split in one tab page SHALL NOT appear in another, and switching back to a tab page SHALL show its windows and current window as they were left.

#### Scenario: Layouts are independent
- **WHEN** `<C-w>s` splits the window, ":tabnew" is run, and "gt" returns to the first tab page
- **THEN** the second tab page had one window and the first again shows two

### Requirement: The tab line lists the tab pages when there are several
When more than one tab page exists the top row of the screen SHALL be the tab line and the windows SHALL use the rows below it; with one tab page there SHALL be no tab line. Each label SHALL be a space, the tab number, a space, the file name of its current window's buffer or "[No Name]", " [+]" when that buffer is modified, and a space; the current label SHALL use the selected tab line highlight, the others the tab line highlight, and the rest of the row the fill highlight.

#### Scenario: Two tab pages
- **WHEN** "a.txt" is shown and ":tabe b.txt" is run
- **THEN** row 0 reads " 1 a.txt  2 b.txt " and the first text row of the window is row 1

#### Scenario: Modified marker and unnamed buffer
- **WHEN** ":tabnew" is run and "x" is pressed in the first tab page, which shows "a.txt"
- **THEN** the tab line reads " 1 a.txt [+]  2 [No Name] "

#### Scenario: One tab page has no tab line
- **WHEN** ":tabnew" then ":tabclose" are run
- **THEN** row 0 is the first text row of the window
