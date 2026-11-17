# file-finder Specification

## Purpose
The file finder opens any file of the project by typing a few letters of its path: a fuzzy-filtered list over the project's files with a preview, opening the pick in the current window, a split, or a tab page.

## Requirements

### Requirement: Space f f and Ctrl-P open the finder
In normal mode `<leader>ff` and `<C-p>` SHALL open the finder: the command line SHALL show the prompt `> ` and a bordered float titled `Files N/M` (N matching, M listed) SHALL list the project's files below the working directory, the first row highlighted with a leading `> `. The keys SHALL be default bindings of the plugin, which the configuration may replace.

#### Scenario: Space f f opens the finder
- **WHEN** the user presses `<Space>ff` in a project with three files
- **THEN** the mode is command-line, the prompt reads `> `, and a float titled `Files 3/3` lists the three paths, the first marked `> `

#### Scenario: Ctrl-P opens the finder
- **WHEN** the user presses `<C-p>` in normal mode
- **THEN** the finder opens as with `<Space>ff`

### Requirement: Typing filters the files best match first
Every change of the typed text SHALL filter the listed files again: a file SHALL match when every typed byte appears in its relative path in order, ignoring ASCII case. The highlight SHALL return to the first row. With no match the float SHALL read `No match`.

#### Scenario: Typing filters the files
- **WHEN** the finder lists `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` and the user types `bet`
- **THEN** the float is titled `Files 1/3` and lists only `lib/beta.rb`

#### Scenario: No file matches
- **WHEN** the user types a text no path contains in order
- **THEN** the float is titled `Files 0/M` and reads `No match`

#### Scenario: Ten thousand files are listed and filtered
- **WHEN** the project holds 10,000 files and the user types two letters
- **THEN** the finder lists all 10,000 and shows the matches of the two letters

### Requirement: Matches are ranked best first
Matches SHALL be ordered by score, higher first: a match inside the file name scores above one across directories, a byte at the start of a path segment or word and a byte right after the previous match score more, and a shorter path breaks a tie, then the listing order.

#### Scenario: The file name match ranks first
- **WHEN** the finder lists `plugins/finder/x.rb` and `lib/plugin.rb` and the user types `plugin`
- **THEN** `lib/plugin.rb` is the first row

### Requirement: The listing respects the ignore list and the project's bounds
The finder SHALL never list nor enter an entry whose name is in `plugin.finder.ignore` (default `.git build tmp`). A symbolic link whose target, every link resolved, lies outside the working directory SHALL be skipped; a link to a directory SHALL never be entered; a link to a file inside the project SHALL be listed.

#### Scenario: Ignored directories are not listed
- **WHEN** the project holds `.git/HEAD`, `build/out.o`, and `a.rb`
- **THEN** the finder lists only `a.rb`

#### Scenario: A link leaving the project is skipped
- **WHEN** the project holds a link `out.rb` to a file outside the working directory and a link `in.rb` to a file inside it
- **THEN** the finder lists `in.rb` and not `out.rb`

#### Scenario: A linked directory is not entered
- **WHEN** the project holds a link `alias` to its own `lib` directory
- **THEN** the files of `lib` are listed once, under `lib/`

### Requirement: The highlight moves in the prompt
`<C-n>` and `<Down>` SHALL move the highlight one row down and `<C-p>` and `<Up>` one row up, stopping at the first and the last match.

#### Scenario: Ctrl-N and Ctrl-P move the highlight
- **WHEN** the finder lists three files and the user presses `<C-n><C-n><C-n><C-p>`
- **THEN** the second row is highlighted

### Requirement: A pick opens in the window, a split, a vertical split, or a tab page
`<CR>` SHALL close the finder and open the highlighted file in the editing window; `<C-x>` and `<C-s>` in a horizontal split of it, `<C-v>` in a vertical split, and `<C-t>` as a tab, as the next requirement says. The mode SHALL be normal afterwards and the floats gone. `<CR>` with no match SHALL keep the finder open on the typed text: the prompt with the same text, the float reading `No match`, and nothing opened, so a typo costs only the keys that fix it.

#### Scenario: Enter opens the file
- **WHEN** the user types `bet` and presses `<CR>`
- **THEN** the current buffer is `lib/beta.rb`, in the same window, in normal mode, and no float shows

#### Scenario: Ctrl-X opens it in a split
- **WHEN** the user presses `<C-x>` on a highlighted file
- **THEN** the window is split and the new, current window shows the file

#### Scenario: Ctrl-V opens it in a vertical split
- **WHEN** the user presses `<C-v>` on a highlighted file
- **THEN** the window is split side by side and the new, current window shows the file

#### Scenario: Ctrl-T opens it in a tab page
- **WHEN** `option.gt tabpages` is set and the user presses `<C-t>` on a highlighted file
- **THEN** a second tab page is current and shows the file

#### Scenario: Enter with no match opens nothing
- **WHEN** nothing matches and the user presses `<CR>`
- **THEN** no file is opened and the current buffer is unchanged

#### Scenario: Enter with no match keeps the finder open
- **WHEN** the user presses `<C-p>`, types `zzqx`, which no file matches, and presses `<CR>`
- **THEN** the mode is still command-line with the prompt reading `> zzqx`, the float reads `No match`, and the current buffer is unchanged

#### Scenario: The query is kept for a correction
- **WHEN** after `<C-p>zzqx<CR>` the user presses `<BS>` four times and types `bet`, then `<CR>`
- **THEN** the current buffer is `lib/beta.rb` and no float shows

### Requirement: Esc closes the finder
`<Esc>` in the prompt SHALL close the finder with its floats, return to normal mode, and open nothing.

#### Scenario: Esc closes the finder
- **WHEN** the finder is open and the user presses `<Esc>`
- **THEN** the mode is normal, no float shows, and the current buffer is unchanged

### Requirement: A wide screen previews the highlighted file
When the screen is at least 100 columns wide a second bordered float, right of the list and titled with the highlighted path, SHALL show the first rows of the highlighted file, following the highlight; a file that cannot be read SHALL show its message as the only row. A narrower screen SHALL show no preview.

#### Scenario: A wide screen shows the preview
- **WHEN** the screen is 120 columns wide and the highlighted file is `lib/beta.rb` holding `b = 2`
- **THEN** a float titled `lib/beta.rb` shows `b = 2`

#### Scenario: A narrow screen shows no preview
- **WHEN** the screen is 80 columns wide and the finder opens
- **THEN** only the list float shows

### Requirement: The finder's boxes share an edge
The finder SHALL size its boxes from the float frame the host answers, so under every border style the list box starts one column from the screen's left edge, the list box alone ends one column before the screen's right edge, and with the preview the preview box starts in the column after the list box, sharing its edge, and ends one column before the screen's right edge. The boxes SHALL never overlap and never leave a column of the window under them between them.

#### Scenario: The finder boxes share an edge
- **WHEN** the screen is 120 columns wide under the shipped border and the finder opens on a project with a file
- **THEN** the list box spans columns 1 to 59 and the preview box columns 60 to 118, the list's right border in column 59 and the preview's left border in column 60

#### Scenario: The finder boxes share an edge without a border
- **WHEN** the screen is 120 columns wide under `option.winborder none` and the finder opens on a project with a file
- **THEN** the list box spans columns 1 to 59 and the preview box columns 60 to 118, no column between them

### Requirement: Ctrl-T opens the pick as the tab the top row shows
`<C-t>` SHALL open the highlighted file as the explorer's `t` does: under `option.gt buffers` a buffer tab in the editing window, and under `option.gt tabpages` a new tab page. When no window of the tab page shows a file, it SHALL open the file as `<CR>` does, under either value, so no tab page is left without a file window.

#### Scenario: Ctrl-T opens a buffer tab
- **WHEN** `option.gt buffers` is set and the user presses `<C-t>` on a highlighted file
- **THEN** one tab page remains and its window, current, shows the file as a buffer tab

#### Scenario: Ctrl-T from a lone tree
- **WHEN** the explorer's file window was closed with `<C-w>c`, leaving only the tree, and the user presses `<C-t>` on a highlighted file, under `option.gt buffers` or `option.gt tabpages`
- **THEN** one tab page remains and its current window shows the file
