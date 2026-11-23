# file-finder Specification

## Purpose
The file finder opens any file of the project by typing a few letters of its path: a fuzzy-filtered list over the project's files with a preview, opening the pick in the current window, a split, or a tab page.

## Requirements

### Requirement: Space f f and Ctrl-P open the finder
In normal mode `<leader>ff` and `<C-p>` SHALL open the finder: a bordered float titled `Files N/M` (N matching, M listed) SHALL show the query on its first row, the prompt `> ` and the typed text, where the cursor stands as a bar while the command-line row stays blank, and SHALL list the project's files below the working directory on the rows after it, the first highlighted with a leading `▎ `. The keys SHALL be default bindings of the plugin, which the configuration may replace.

#### Scenario: Space f f opens the finder
- **WHEN** the user presses `<Space>ff` in a project with three files
- **THEN** the mode is command-line, the float's first row reads `> `, the message row is blank, and the float titled `Files 3/3` lists the three paths after it, the first marked `▎ `

#### Scenario: Ctrl-P opens the finder
- **WHEN** the user presses `<C-p>` in normal mode
- **THEN** the finder opens as with `<Space>ff`

### Requirement: Typing filters the files best match first
Every change of the typed text SHALL filter the listed files again. The text is terms between spaces, and a file SHALL match when its relative path matches every term, in any order, ignoring ASCII case. A text with no term (empty, or only spaces) SHALL list every file in listing order. The highlight SHALL return to the first row. With no match the float SHALL read `No match`.

#### Scenario: Typing filters the files
- **WHEN** the finder lists `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` and the user types `bet`
- **THEN** the float is titled `Files 1/3` and lists only `lib/beta.rb`

#### Scenario: No file matches
- **WHEN** the user types a text no path matches
- **THEN** the float is titled `Files 0/M` and reads `No match`

#### Scenario: A query of spaces lists every file in listing order
- **WHEN** the user types only spaces
- **THEN** every file is listed in listing order

#### Scenario: Ten thousand files are listed and filtered
- **WHEN** the project holds 10,000 files and the user types two letters
- **THEN** the finder lists all 10,000 and shows the matches of the two letters

### Requirement: Matches are ranked best first
Matches SHALL be ordered best first. Every path that holds the term as a substring SHALL rank above every path that holds it only as runs. Among substring matches the order is: inside the file name starting at a segment or word, inside the file name elsewhere, in a directory starting at a segment or word, elsewhere. Among run matches fewer runs rank higher. With several terms a path ranks by its worst term, then by all its terms together. A shorter path breaks a tie, then the listing order.

#### Scenario: The file name match ranks first
- **WHEN** the finder lists `plugins/finder/x.rb` and `lib/plugin.rb` and the user types `plugin`
- **THEN** `lib/plugin.rb` is the first row

#### Scenario: A word start in the file name ranks above a middle byte of it
- **WHEN** the finder lists `lib/alpha.rb` and `lib/beta.rb` and the user types `a`
- **THEN** `lib/alpha.rb` is the first row

#### Scenario: A substring ranks above initials
- **WHEN** the finder lists `a/b.rb` and `x/zzabz/y.rb` and the user types `ab`
- **THEN** `x/zzabz/y.rb` is the first row

#### Scenario: Fewer runs rank above more
- **WHEN** the finder lists `a/b/c/x.rb` and `a/bc/x.rb` and the user types `abc`
- **THEN** `a/bc/x.rb` is the first row

#### Scenario: Explorer in a file name ranks above initials
- **WHEN** the finder lists `tools/explain_pl_or_err.sh`, `carat/plugins/explorer/plugin.rb`, and `test/editor_explorer.rb` and the user types `explorer`
- **THEN** the rows are `test/editor_explorer.rb`, `carat/plugins/explorer/plugin.rb`, and `tools/explain_pl_or_err.sh`

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
When the screen is at least 100 columns wide a second bordered float, right of the list and titled with the highlighted path, SHALL show the first rows of the highlighted file, following the highlight; a file that cannot be read SHALL show its message as the only row. A narrower screen SHALL show no preview. The grep picker's preview is its own requirement.

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

### Requirement: Space f g opens the grep picker
In normal mode `<leader>fg` SHALL open the finder's content picker: the prompt `> ` and a bordered float titled `Grep F of M files, L of N lines` (F files shown in the rows, M files with a matching line, L matching lines, N lines stored), reading `Type to search the files' lines` until text is typed. The key SHALL be a default binding of the plugin, which the configuration may replace, and the action SHALL be listed in the palette.

#### Scenario: Space f g opens the picker
- **WHEN** the user presses `<Space>fg`
- **THEN** the mode is command-line and a float titled `Grep 0 of 0 files, 0 of N lines` reads `Type to search the files' lines`

### Requirement: The picker reads the finder's files once and within bounds
The picker's files SHALL be the finder's listing, each read once when the picker opens. A file that cannot be read, holds a NUL byte, or is over the host's read limit SHALL add no line; every line of a file within the read limit SHALL be stored, a line SHALL be cut at the last character boundary at or under 400 bytes, and at most 400,000 lines SHALL be stored. Each key SHALL search the stored lines within the per-key bound of the requirement Each key searches a bounded number of lines.

#### Scenario: The picker stores only bounded lines of each file
- **WHEN** a file holds 1200 lines, a line holds 500 bytes, a line holds a multi-byte character the cut would split, or more than 400,000 lines are stored
- **THEN** all 1200 lines of the file are stored, the line is cut at a character boundary at or under 400 bytes, and the title marks the store cap with `+`

#### Scenario: A match past the 1000th line is found
- **WHEN** a file of 2000 lines holds the typed text only on line 1500 and the user presses Enter on its row
- **THEN** the row shows the file's path and line 1500, and the file opens with the cursor on line 1500

#### Scenario: A tree the size of this repository is searched whole
- **WHEN** the project holds 150,001 lines in files of at most 1000 lines each
- **THEN** every line is stored and the title's stored count has no `+`, a key checks 30,000 of them, and keys that extend the text continue through the rest

#### Scenario: Files that cannot be searched are left out
- **WHEN** the project holds a binary file, a file over the read limit, an empty file, and an ignored directory
- **THEN** none of them adds a line to the count or a row

### Requirement: Typing lists the matching lines best first
Every change of the typed text SHALL list again, among the stored lines the key checks within its per-key bound, the lines that hold every term of the text as a substring, in any order, ignoring ASCII case; the terms are the runs of bytes between spaces, and a text with no term lists nothing. Each row SHALL show the file's path, the line number, and the line's text. With no match the float SHALL read `No match`. Letters that appear in order but not together SHALL NOT match.

#### Scenario: Typing lists the matching lines best first
- **WHEN** the user types `hello`
- **THEN** the rows run from the line holding it as a whole word on the shorter path to the lines on longer paths, equal paths in listing order

#### Scenario: Scattered letters do not match
- **WHEN** the user types `wrt` and no line holds those three bytes together
- **THEN** the float reads `No match`

#### Scenario: Two terms match in any order
- **WHEN** the user types `open explorer` or `explorer open` and a line reads `explorer open`
- **THEN** the line is listed for both, and a line holding only one of the terms is not listed

#### Scenario: Case is ignored in the query
- **WHEN** the user types `EXPLORER`
- **THEN** the same rows are listed as for `explorer`

#### Scenario: A query of only spaces lists nothing
- **WHEN** the user types spaces only
- **THEN** the float reads `Type to search the files' lines`

#### Scenario: No line matches
- **WHEN** the user types a text no line holds
- **THEN** the float reads `No match`

### Requirement: The rows are capped and the title says so
At most 200 rows SHALL be kept, and the title SHALL count the files the rows show, the files with a matching line, and the matching lines, so a count of lines above 200 shows the cap.

#### Scenario: The rows are capped and the title says so
- **WHEN** 250 lines of one file match
- **THEN** 200 rows are kept and the title reads `Grep 1 of 1 files, 250 of 250 lines`

#### Scenario: The title counts files and lines
- **WHEN** 250 lines of one file and one line of another match
- **THEN** the title reads `Grep 2 of 2 files, 251 of 251 lines`

### Requirement: Rows are shown safely
A row SHALL show each control character, each bidirectional embedding, override, isolate, or mark (U+061C, U+200E, U+200F, U+202A to U+202E, U+2066 to U+2069), each zero-width character (U+200B to U+200D, U+FEFF), and the line and paragraph separators (U+2028, U+2029) as a space and each byte of invalid UTF-8 as a question mark, and a CRLF line SHALL show without its carriage return.

#### Scenario: Lines are shown safely
- **WHEN** a matching line holds an escape character, a bell, or the bytes FF and FE
- **THEN** the row holds spaces and question marks in their place

#### Scenario: Invisible format and separator characters show as spaces
- **WHEN** a matching line holds one of U+061C, U+200B to U+200F, U+2028 to U+202E, U+2066 to U+2069, or U+FEFF
- **THEN** the row holds a space in its place

### Requirement: Picking a row opens the file at its line and column
Enter SHALL open the highlighted row's file in the editing window, and the finder's split, vertical split, and tab keys SHALL open it in a horizontal split, a vertical split, or a tab, each with the cursor on the row's line and at the column, counted in characters, of the first byte of the first hit of the query's first term in the line. With no row Enter SHALL keep the prompt open, and Esc SHALL open nothing.

#### Scenario: Picking a row opens the file at its line and column
- **WHEN** the user types `x = 1` and presses Enter on a line `café x = 1`
- **THEN** that file is open with the cursor on its first line at column 5

#### Scenario: The column is the first byte of the first term's hit
- **WHEN** the user types `explorer` and picks a line `e x p l o r e r and later Explorer here`, or types `open explorer` and picks `explorer open`
- **THEN** the cursor is at column 26 of the first line, and at column 9 of the second

#### Scenario: The split, vertical split, and tab picks open at the line
- **WHEN** the user picks a row with the split, vertical split, or tab key
- **THEN** the file opens in a split, a vertical split, or a tab with the cursor on the row's line

### Requirement: Matching lines rank by whole words, then hits, then path
Rows SHALL list each matching file's best line before any file's second best line, then every file's second best line before any third, and so on. Within each such round, and among the lines of one file, rows SHALL rank by the terms found as a whole word, a term holding a word start before it and a word end after it, more such terms first; then by more hits of the terms in the line; then by a shorter path; then by listing order, so a file's lines of equal rank keep their line order.

#### Scenario: A whole-word hit ranks above a part-word hit
- **WHEN** the user types `explorer` and one line holds it as a whole word once while a line on a shorter path holds it three times inside longer words
- **THEN** the whole-word line is listed first

#### Scenario: A file with one hit is listed beside a file with more hits than the row cap
- **WHEN** one file holds 250 matching lines and a file on a longer path holds one
- **THEN** the second row is the one-hit file's line, ahead of the first file's second line

#### Scenario: Lines of equal rank keep their order in each file
- **WHEN** two files of equal path length each hold three lines of equal rank
- **THEN** the rows are the first lines of both files in listing order, then their second lines, then their third

### Requirement: Each key searches a bounded number of lines
A key SHALL check at most 30,000 stored lines from where its search starts. When the typed text only extends the previous one, every previous term found inside a new term, the key SHALL check again the lines the previous key matched and continue from the first line it did not check, within 30,000 lines less those it kept; any other text SHALL start again from the first stored line. While stored lines remain unchecked the title SHALL mark the counts of files and of matching lines with `+`.

#### Scenario: A key checks at most 30,000 lines
- **WHEN** the project holds 150,001 lines that all match and the user types `x`
- **THEN** 30,000 lines are checked and the title's counts of files and matching lines carry `+`, the stored count none

#### Scenario: An extended query continues the search
- **WHEN** the project holds 40,000 lines holding `ab` and, after them, one line holding `abc`, and the user types `a`, `b`, then `c`
- **THEN** after `c` the line holding `abc` is the one row and the title carries no `+`

#### Scenario: A backspace starts the search again
- **WHEN** the user then presses Backspace
- **THEN** the search starts from the first line, 30,000 lines are checked, and the counts carry `+`

### Requirement: A path matches a term as a substring or as runs at word starts
A path SHALL match a term in one of two ways and in no other: the term is a contiguous substring of the path, or it is at most four contiguous runs, in order, each run after the first starting at a segment or word start (the first byte, after `/`, `_`, `-`, `.`, or a space, or an uppercase letter after a lowercase one), as initials do. A run that starts inside a word SHALL NOT match.

#### Scenario: Initials match
- **WHEN** the finder lists `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` and the user types `la`
- **THEN** the float is titled `Files 1/3` and lists only `lib/alpha.rb`

#### Scenario: A run that starts mid-word does not match
- **WHEN** the finder lists `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` and the user types `ibh`
- **THEN** the float is titled `Files 0/3` and reads `No match`

#### Scenario: A scattered path is not listed
- **WHEN** the finder lists `ezzzxpzzzlzzzozzzrzzezrrr` and the user types `explorer`
- **THEN** that path is not listed

#### Scenario: Two terms match in any order
- **WHEN** the finder lists `lib/beta.rb` and the user types `beta lib` or `lib beta`
- **THEN** `lib/beta.rb` is listed, and a path that lacks one of the terms is not

#### Scenario: A multi-byte path matches by its bytes
- **WHEN** the finder lists `src/café.rb` and `src/cafe.rb` and the user types `café`
- **THEN** only `src/café.rb` is listed

#### Scenario: Case is ignored
- **WHEN** the finder lists `lib/beta.rb` and the user types `BET`
- **THEN** the float lists `lib/beta.rb`

### Requirement: The grep list is sized as the file finder's list
The grep list SHALL use the width and the place the file finder's list has beside its preview, and its preview the width and the place of the file finder's.

#### Scenario: The grep list is sized as the file finder's list
- **WHEN** the screen is 120 columns wide and the user types a query that matches a line
- **THEN** the list and the preview float have the width and the column of the file finder's list and preview

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

### Requirement: The grep preview is centred and clamped at the file's ends
The preview window SHALL start at the row's line number less half the float's height, moved to start at line 1 when that is lower, and to end at the file's last line when it would end later; a file with fewer lines SHALL show whole. A line the picker did not store because it is empty SHALL show as an empty line, the empty lines at the file's end included, and the window SHALL cover no line past the last the picker read of a file.

#### Scenario: The preview is centred on the matched line
- **WHEN** the highlighted row is line 50 of a file of 100 lines on a 24-row screen
- **THEN** the preview shows lines 41 to 58 with line 50 the tenth

#### Scenario: The preview is clamped at the file's start and end
- **WHEN** the highlighted row is line 3, or line 38 of 40, or line 1195 of a file of 1200 lines
- **THEN** the preview shows lines 1 to 18, 23 to 40, or 1183 to 1200

#### Scenario: The preview ends at the file's last line
- **WHEN** the highlighted row's file ends in empty lines after its last non-empty line
- **THEN** the preview shows those empty lines below it

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

### Requirement: The finder keeps its floats across keys
While the finder is open and its boxes keep their size, every key that changes the typed text or moves the highlight SHALL show the new rows and title in the same list float, and the new preview in the same preview float while a preview shows; the preview float SHALL close when no preview shows and open again when one does, and a resize that changes a box SHALL open that float again at its new box.

#### Scenario: Typing keeps the list float
- **WHEN** the finder is open on an 80-column screen and the user types `bet` and three backspaces
- **THEN** the tab page holds one float, the list float the finder opened with, titled `Files 3/3`

#### Scenario: Moving the highlight keeps both floats
- **WHEN** the finder is open on a 120-column screen and the user presses `<C-n>`
- **THEN** the list and the preview are the floats the finder opened with, the preview titled `lib/alpha.rb`

#### Scenario: The preview closes and returns
- **WHEN** on a 120-column screen the user types `zzz`, then three backspaces
- **THEN** after `zzz` only the list float shows, and after the backspaces the list float is the one the finder opened with and a preview shows again

#### Scenario: A resize opens the floats at the new size
- **WHEN** the finder is open on a 120-column screen and the screen narrows to 80 columns
- **THEN** one list float shows, as wide as the list the finder opens on an 80-column screen

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

### Requirement: Space f r opens the recent files picker
In normal mode `<leader>fr` SHALL open the finder's picker over the recent files, most recent first: every file shown in a window since the editor started and every file an earlier run kept, also after its buffer was deleted, at most 100, a file shown again moving to the top; the float SHALL be titled `Recent N/M` and work as the file finder does. The key SHALL be a default binding of the plugin.

#### Scenario: Space f r lists the recent files most recent first
- **WHEN** `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` were opened in that order and the user presses `<Space>fr`
- **THEN** a float titled `Recent 3/3` lists `docs/guide.md`, `lib/beta.rb`, and `lib/alpha.rb`

#### Scenario: A file shown again moves to the top
- **WHEN** after those three the user shows `lib/alpha.rb` again and presses `<Space>fr`
- **THEN** the float lists `lib/alpha.rb` first, then `docs/guide.md` and `lib/beta.rb`

#### Scenario: A deleted buffer stays recent
- **WHEN** `lib/beta.rb` was deleted with `:bd` and the user presses `<Space>fr`
- **THEN** the float still lists `lib/beta.rb`, and Enter on it opens it again

#### Scenario: The recent files survive a restart
- **WHEN** an editor opened `lib/alpha.rb` and `lib/beta.rb` and ended, and a new editor in the same directory opens `docs/guide.md` and the user presses `<Space>fr`
- **THEN** a float titled `Recent 3/3` lists `docs/guide.md`, `lib/beta.rb`, and `lib/alpha.rb`

### Requirement: Space f R resumes the last search
In normal mode `<leader>fR` SHALL reopen the last picker the finder closed, by Esc or by a pick, the file finder, the grep picker, the buffer picker, or the recent files picker, with its typed text on the prompt and its list read again and filtered by it, the highlight on the row it was on, or on the last row when fewer rows match. With no picker closed yet it SHALL show the message `No search to resume` and stay in normal mode.

#### Scenario: Space f R resumes the file finder after Esc
- **WHEN** the user typed `a` in the file finder, moved the highlight to the second row, pressed Esc, and then presses `<Space>fR`
- **THEN** the prompt reads `> a` and the float titled `Files 2/3` has `lib/beta.rb` marked

#### Scenario: Space f R resumes after a pick
- **WHEN** with `lib/beta.rb` open the user opened `lib/alpha.rb` from the buffer picker with `alp` and Enter, and then presses `<Space>fR`
- **THEN** the buffer picker opens again with the prompt `> alp` and the float titled `Buffers 1/2`

#### Scenario: Space f R resumes the grep picker
- **WHEN** the user typed `b` in the grep picker, pressed Esc, and then presses `<Space>fR`
- **THEN** the grep picker opens again with the prompt `> b` and lists the matching line of `lib/beta.rb`

#### Scenario: The resumed highlight is clamped
- **WHEN** the highlight was on the second row of the buffer picker, Esc closed it, `:bd` deleted that buffer, and the user presses `<Space>fR`
- **THEN** the float titled `Buffers 1/1` has its one row marked

#### Scenario: Nothing to resume
- **WHEN** no picker was closed yet and the user presses `<Space>fR`
- **THEN** the mode stays normal, no float opens, and the message reads `No search to resume`

### Requirement: The pickers are drawn in both carat themes and in ASCII
The buffer and recent files pickers SHALL be drawn as the file finder's float is: the same rows under `carat-dark` and `carat-light`, the edge in each theme's `FloatBorder` color and the title in its `FloatTitle` color, and under `option.icons ascii` the edge drawn with `+`, `-`, and `|`; the highlighted row SHALL keep its `▎ ` mark there.

#### Scenario: The buffer picker's rows in both themes
- **WHEN** the buffer picker lists two buffers under `option.theme carat-dark` and under `option.theme carat-light`
- **THEN** both frames show the same rows, the top edge holding the title `Buffers 2/2`, the edge cells in that theme's `FloatBorder` color and the title cells in its `FloatTitle` color

#### Scenario: The recent files picker's rows in ASCII
- **WHEN** `option.icons ascii` is set and the user presses `<Space>fr`
- **THEN** the float's top edge starts with `+`, holds `Recent` and runs in `-`, its sides are `|`, and its bottom edge is `+` and `-`

### Requirement: Ctrl-G switches between the file finder and the grep picker
While a picker's prompt is open, `<C-g>` SHALL close the picker and open the file finder when it was the grep picker, or the grep picker when it was the file finder, the buffer picker, or the recent files picker. The new picker SHALL show the text typed so far on its prompt, list its rows filtered by it, and highlight the first row. The key SHALL be one of the prompt's keys, which answer before the command-line keymap. No float of the closed picker SHALL remain.

#### Scenario: Ctrl-G switches the file finder to the grep picker
- **WHEN** the user typed `b` in the file finder and presses `<C-g>`
- **THEN** the prompt reads `> b` and the float is the grep picker's, listing the line of `lib/beta.rb`

#### Scenario: Ctrl-G switches the grep picker to the file finder
- **WHEN** the user typed `b` in the grep picker and presses `<C-g>`
- **THEN** the prompt reads `> b` and the float titled `Files 2/3` lists the files matching it

#### Scenario: Ctrl-G switches back and forth keeping the query
- **WHEN** the user typed `bet` in the file finder and presses `<C-g>` twice
- **THEN** the file finder is open on the prompt `> bet` with one float

#### Scenario: Ctrl-G with the empty prompt
- **WHEN** the user presses `<C-g>` in the file finder before typing
- **THEN** the grep picker opens on the empty prompt

#### Scenario: Ctrl-G from the buffer picker opens the grep picker
- **WHEN** the user typed `bet` in the buffer picker and presses `<C-g>`
- **THEN** the grep picker opens on the prompt `> bet`

#### Scenario: A switched picker is picked from as any other
- **WHEN** the user typed `bet`, pressed `<C-g>` twice, and presses Enter
- **THEN** `lib/beta.rb` opens in the editing window

#### Scenario: A switched picker is the one resumed
- **WHEN** the user typed `bet` in the file finder, pressed `<C-g>` and Esc, and presses `<Space>fR`
- **THEN** the grep picker opens again on the prompt `> bet`

### Requirement: Space f w greps the word under the cursor
In normal mode `<leader>fw` SHALL open the grep picker with the word under the cursor typed on its prompt, its rows filtered by it. The word SHALL be the run of ASCII letters, digits, underscores, and non-ASCII characters around the cursor's character column. With the cursor on no such character, or on a word that is not valid UTF-8, the grep picker SHALL open on the empty prompt. The key SHALL be a default binding of the plugin, which the configuration may replace.

#### Scenario: Space f w on a word opens the grep picker with it
- **WHEN** the cursor is on the `w` of `hello world` and the user presses `<Space>fw`
- **THEN** the grep picker opens on the prompt `> world` and lists the line

#### Scenario: Space f w takes the whole word
- **WHEN** the cursor is on the first character of `hello world` and the user presses `<Space>fw`
- **THEN** the prompt reads `> hello`

#### Scenario: Space f w on a multi-byte word
- **WHEN** the cursor is on the `é` of `café x` and the user presses `<Space>fw`
- **THEN** the prompt reads `> café`

#### Scenario: Space f w keeps underscores in the word
- **WHEN** the cursor is on `foo_bar baz` at its first character and the user presses `<Space>fw`
- **THEN** the prompt reads `> foo_bar`

#### Scenario: Space f w on a blank opens the grep picker empty
- **WHEN** the cursor is on the space of `hello world` and the user presses `<Space>fw`
- **THEN** the grep picker opens on the empty prompt

#### Scenario: Space f w in an empty buffer or on an empty line
- **WHEN** the buffer is empty, or the cursor is on an empty line, and the user presses `<Space>fw`
- **THEN** the grep picker opens on the empty prompt

#### Scenario: Space f w on the last character of the last line
- **WHEN** the cursor is on the last character of `hello world`, the last line, and the user presses `<Space>fw`
- **THEN** the prompt reads `> world`

#### Scenario: Ctrl-G after Space f w switches on the word
- **WHEN** the user pressed `<Space>fw` on `hello` and presses `<C-g>`
- **THEN** the file finder opens on the prompt `> hello`

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

### Requirement: Every picker shows its query in its list float
The file, grep, buffer, and recent files pickers SHALL each show the typed text on the first row of their list float, the prompt `> ` then the text, with the cursor after the text before the command line's cursor in that row and the command-line row blank, the list on the rows after it, the highlight on its row of the list. Enter with no match SHALL open the prompt again on the same text with the cursor in the float. Closing the picker SHALL leave no float and no attachment.

#### Scenario: The query is the list float's first row (the finder)
- **WHEN** `<Space>ff` and "be" are typed, then Left and "x"
- **THEN** the float's first row reads `> be`, then `> bxe`, the cursor is in that row after the text before the command line's cursor, the message row is blank, and the title reads `Files 1/3`

#### Scenario: The query row is above the highlight
- **WHEN** `<Space>ff` and `<C-n>` are typed
- **THEN** the second file is the highlighted row, the third of the float, the query row being the first

#### Scenario: Enter with no match keeps the query in the float
- **WHEN** "zzz" and Enter are typed at the finder's prompt
- **THEN** the mode is command-line, the float's first row reads `> zzz`, and the cursor is in it after the text

#### Scenario: The prompt leaves the float when the finder closes
- **WHEN** the finder is open and Esc is typed
- **THEN** no float remains, the mode is normal, and the prompt is no longer attached to a float

### Requirement: The recent files picker names each file by the working directory
The recent files picker SHALL show each path relative to the working directory when it lies below it and absolute otherwise, so a pick opens the file the row names whatever the working directory is.

#### Scenario: The recent files keep naming their files after the working directory changes
- **WHEN** an editor in `/p` opened `lib/alpha.rb` and `lib/beta.rb` and ended, a new editor in `/q` opens `x.rb`, the user presses `<Space>fr`, moves the highlight to the second row, and presses Enter
- **THEN** the float lists `x.rb`, `/p/lib/beta.rb`, and `/p/lib/alpha.rb`, and Enter opens the file `/p/lib/beta.rb`, not a file of that name under `/q`

#### Scenario: A path inside the working directory is shown relative
- **WHEN** an editor in `/p` opened `lib/alpha.rb` and ended, and a new editor in `/p/lib` opens `beta.rb` and the user presses `<Space>fr`
- **THEN** the float lists `beta.rb` and `alpha.rb`
