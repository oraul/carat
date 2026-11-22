## MODIFIED Requirements

### Requirement: Space f f and Ctrl-P open the finder
In normal mode `<leader>ff` and `<C-p>` SHALL open the finder: the command line SHALL show the prompt `> ` and a bordered float titled `Files N/M` (N matching, M listed) SHALL list the project's files below the working directory, the first row highlighted with a leading `▎ `. The keys SHALL be default bindings of the plugin, which the configuration may replace.

#### Scenario: Space f f opens the finder
- **WHEN** the user presses `<Space>ff` in a project with three files
- **THEN** the mode is command-line, the prompt reads `> `, and a float titled `Files 3/3` lists the three paths, the first marked `▎ `

#### Scenario: Ctrl-P opens the finder
- **WHEN** the user presses `<C-p>` in normal mode
- **THEN** the finder opens as with `<Space>ff`

### Requirement: A wide screen previews the grep row's file around its line
When the screen is at least 100 columns wide the grep picker SHALL show a second bordered float beside its list, titled with the highlighted row's path, showing as many lines of that file as the float is high with the row's line in the middle, from the text the picker read when it opened and never from a new file read. The row's line SHALL start with the list's highlight mark `▎ ` and every other line with two spaces. A narrower screen SHALL show no preview.

#### Scenario: A wide screen previews the matched line
- **WHEN** the screen is 120 columns wide on 24 rows and the highlighted row is line 20 of a file of 40 lines
- **THEN** a float titled with the file's path shows lines 11 to 28 with line 20 marked

#### Scenario: A narrow screen shows no grep preview
- **WHEN** the screen is 99 columns wide and the user types a query that matches a line
- **THEN** only the list float shows

#### Scenario: The preview is built from the stored text
- **WHEN** a matched file changes on the disk after the picker opened and the highlight moves to its row
- **THEN** the preview shows the text the picker read when it opened

### Requirement: Space f b opens the buffer picker
In normal mode `<leader>fb` SHALL open the finder's picker over the listed file buffers, in the order `:ls` shows them, scratch and unnamed buffers left out: the prompt `> ` and a bordered float titled `Buffers N/M`. Typing, the highlight keys, the preview, Enter, the split, vertical split, and tab keys, and Esc SHALL work as in the file finder. The key SHALL be a default binding of the plugin, which the configuration may replace.

#### Scenario: Space f b lists the open buffers
- **WHEN** `lib/alpha.rb` and then `lib/beta.rb` are open and the user presses `<Space>fb`
- **THEN** the mode is command-line and a float titled `Buffers 2/2` lists `lib/alpha.rb` marked `▎ ` and `lib/beta.rb`

#### Scenario: The buffer picker filters and opens the pick
- **WHEN** the user types `alp` in the buffer picker and presses Enter
- **THEN** the float was titled `Buffers 1/2` and `lib/alpha.rb` is shown in normal mode

#### Scenario: Unnamed buffers are not listed
- **WHEN** `:new` opened an unnamed buffer beside `lib/alpha.rb` and the user presses `<Space>fb`
- **THEN** the float is titled `Buffers 1/1` and lists only `lib/alpha.rb`

#### Scenario: A deleted buffer leaves the buffer picker
- **WHEN** `lib/beta.rb` was deleted with `:bd` and the user presses `<Space>fb`
- **THEN** the float lists only `lib/alpha.rb`

### Requirement: The pickers are drawn in both carat themes and in ASCII
The buffer and recent files pickers SHALL be drawn as the file finder's float is: the same rows under `carat-dark` and `carat-light`, the edge in each theme's `FloatBorder` color and the title in its `FloatTitle` color, and under `option.icons ascii` the edge drawn with `+`, `-`, and `|`; the highlighted row SHALL keep its `▎ ` mark there.

#### Scenario: The buffer picker's rows in both themes
- **WHEN** the buffer picker lists two buffers under `option.theme carat-dark` and under `option.theme carat-light`
- **THEN** both frames show the same rows, the top edge holding the title `Buffers 2/2`, the edge cells in that theme's `FloatBorder` color and the title cells in its `FloatTitle` color

#### Scenario: The recent files picker's rows in ASCII
- **WHEN** `option.icons ascii` is set and the user presses `<Space>fr`
- **THEN** the float's top edge starts with `+`, holds `Recent` and runs in `-`, its sides are `|`, and its bottom edge is `+` and `-`

## ADDED Requirements

### Requirement: The highlighted row is the sapphire bar, the selection fill, and a bold label
In every picker of the finder the highlighted row SHALL start with `▎ `, the others with two spaces, no row with `> `. It SHALL be drawn in the selection fill (`PmenuSel`), its `▎` in `PmenuMarkSel` and its label in `PmenuLabelSel`, the other rows in `Pmenu`, at every color depth, under `NO_COLOR`, under `option.icons ascii`, and after every refill. An empty list SHALL show no highlighted row.

#### Scenario: The selected row under truecolor
- **WHEN** the user presses `<Space>ff` in a project with three files on a 24-bit terminal
- **THEN** the first row reads `▎ docs/guide.md`, its `▎` cell is in `PmenuMarkSel` in the theme's sapphire on the selection color and bold, its label cells in `PmenuLabelSel`, bold on the selection color, the float's padding on that row in `PmenuSel`, and the second row in `Pmenu` with no `>` on any row

#### Scenario: The selected row at 16 colors
- **WHEN** the same finder is drawn at 16 colors
- **THEN** the `▎` and label cells carry their groups, whose 16-color attributes are reverse and bold

#### Scenario: The selected row under NO_COLOR
- **WHEN** `NO_COLOR` is set and the user presses `<Space>ff`
- **THEN** the first row reads `▎ docs/guide.md`, its `▎` cell in `PmenuMarkSel` and its label in `PmenuLabelSel`, bold

#### Scenario: The selected row under option.icons ascii
- **WHEN** `option.icons ascii` is set and the user presses `<Space>fr` after opening `lib/beta.rb`
- **THEN** the edge is drawn in `+`, `-`, and `|`, the first row reads `▎ lib/beta.rb` with its `▎` in `PmenuMarkSel` and its label in `PmenuLabelSel`

#### Scenario: The style follows the highlight
- **WHEN** the user presses `<Space>ff` and then `<C-n>`
- **THEN** the second row is the one in `PmenuMarkSel` and `PmenuLabelSel` and the first is in `Pmenu`, reading `  docs/guide.md`

#### Scenario: A grep row is styled as a file row
- **WHEN** the user presses `<Space>fg` and types a word one line holds
- **THEN** the highlighted grep row starts with `▎ ` and is drawn in `PmenuMarkSel` and `PmenuLabelSel`

#### Scenario: No match shows no highlighted row
- **WHEN** the typed text matches no file
- **THEN** the float reads `No match` in `NormalFloat`
