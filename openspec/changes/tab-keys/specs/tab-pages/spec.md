## REMOVED Requirements

### Requirement: Moving between tab pages
**Reason**: `gt` and `gT` follow the buffer tabs by default; the tab pages move by `<C-PageDown>`, `<C-PageUp>`, `g<Tab>`, and the ex commands.
**Migration**: "Moving between tab pages by keys and commands" below holds the requirement; `option.gt tabpages` gives `gt` and `gT` their tab-page meaning back.

## ADDED Requirements

### Requirement: Moving between tab pages by keys and commands
":tabn", ":tabnext", and `<C-PageDown>` SHALL make the next tab page current, wrapping from the last to the first; ":tabp", ":tabprevious", ":tabN", ":tabNext", and `<C-PageUp>` SHALL make the previous one current, wrapping; ":tabfir", ":tabfirst", ":tabl", and ":tablast" SHALL go to the first and the last. "{count}`<C-PageDown>`" SHALL go to tab page number count, or do nothing when there is none; "{count}`<C-PageUp>`" SHALL go count tab pages back, wrapping.

#### Scenario: Ctrl-PageDown and Ctrl-PageUp wrap
- **WHEN** two tab pages exist, the second is current, and `<C-PageDown>` is pressed
- **THEN** the first is current, and after `<C-PageUp>` the second is current again

#### Scenario: Ex next and previous
- **WHEN** two tab pages exist, the first is current, and ":tabn" is run, then ":tabp", then ":tabN", then ":tabnext"
- **THEN** the current tab page is the second, the first, the second, and the first in turn

#### Scenario: First and last
- **WHEN** three tab pages exist and ":tabl" is run, then ":tabfir"
- **THEN** the third is current after ":tabl" and the first after ":tabfir"

#### Scenario: Counted Ctrl-PageDown
- **WHEN** three tab pages exist, the first is current, and "3`<C-PageDown>`" is typed
- **THEN** the third is current, and "5`<C-PageDown>`" keeps it current

#### Scenario: Counted Ctrl-PageUp
- **WHEN** three tab pages exist, the first is current, and "2`<C-PageUp>`" is typed
- **THEN** the second is current

### Requirement: g Tab goes to the last accessed tab page
`g<Tab>` SHALL make current the tab page that was current before the current one, and SHALL do nothing when that tab page was closed or no other tab page was current before.

#### Scenario: g Tab goes to the last accessed tab page
- **WHEN** three tab pages exist, the third is current, ":tabfir" is run, and `g<Tab>` is pressed twice
- **THEN** the third is current after the first `g<Tab>` and the first after the second

#### Scenario: g Tab with no tab page to go back to does nothing
- **WHEN** `g<Tab>` is pressed with one tab page, or after ":tabnew" and ":tabclose"
- **THEN** the current tab page stays and no message shows

### Requirement: option.gt tabpages gives gt and gT their tab-page meaning
With `option.gt tabpages`, "gt", "gT", and their counts SHALL do what `<C-PageDown>` and `<C-PageUp>` do, as in Vim.

#### Scenario: option.gt tabpages gives gt and gT the tab pages back
- **WHEN** `option.gt tabpages` is set, three tab pages exist, the first is current, and "gt", "3gt", "gT", and "2gT" are typed in turn
- **THEN** the current tab page is the second, the third, the second, and the third in turn, and the buffers the windows show do not change

### Requirement: The tab ex commands take a tab page argument
":tabn N" and ":tabnext N" SHALL go to tab page N; ":tabp N", ":tabprevious N", ":tabN N", and ":tabNext N" SHALL go N tab pages back, wrapping; ":tabc N" and ":tabclose N" SHALL close tab page N, the current one staying current when it is another; ":tabo N" and ":tabonly N" SHALL make tab page N current and close every other one.

#### Scenario: tabn N goes to tab page N
- **WHEN** three tab pages exist, the first is current, and ":tabn 3" is run
- **THEN** the third is current

#### Scenario: tabp N goes N tab pages back
- **WHEN** three tab pages exist, the first is current, and ":tabp 2" is run
- **THEN** the second is current

#### Scenario: tabc N closes tab page N
- **WHEN** three tab pages exist, the third is current, and ":tabc 1" is run
- **THEN** two tab pages remain and the one that was third is current

#### Scenario: tabo N keeps only tab page N
- **WHEN** three tab pages exist, the first is current, and ":tabo 2" is run
- **THEN** one tab page remains, the one that was second

### Requirement: A tab ex argument that names no tab page is refused
For ":tabn", ":tabc", and ":tabo", 0 SHALL be "E16: Invalid range" and a word or a number past the last tab page "E475: Invalid argument: ARG"; for ":tabp" and ":tabN" anything but a positive number SHALL be "E475: Invalid argument: ARG"; an argument to ":tabfir" or ":tabl" SHALL be "E488: Trailing characters: ARG". A refused command SHALL change no tab page, and with one tab page ":tabc" and ":tabo" SHALL answer as without an argument.

#### Scenario: A tab argument that names no tab page is refused
- **WHEN** three tab pages exist and ":tabn 4", ":tabo x", ":tabc 0", ":tabp 0", or ":tabl x" is run
- **THEN** the message is "E475: Invalid argument: 4", "E475: Invalid argument: x", "E16: Invalid range", "E475: Invalid argument: 0", or "E488: Trailing characters: x", and the current tab page and the count of tab pages stay

#### Scenario: One tab page answers before reading the argument
- **WHEN** one tab page exists and ":tabc 2" or ":tabo x" is run
- **THEN** the message is "E784: Cannot close last tab page" or "Already only one tab page"

## MODIFIED Requirements

### Requirement: Each tab page keeps its own windows
Windows split in one tab page SHALL NOT appear in another, and switching back to a tab page SHALL show its windows and current window as they were left.

#### Scenario: Layouts are independent
- **WHEN** `<C-w>s` splits the window, ":tabnew" is run, and `<C-PageDown>` returns to the first tab page
- **THEN** the second tab page had one window and the first again shows two
