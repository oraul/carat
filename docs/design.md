# carat's look: Facet

This is the one binding description of how carat looks. Every UI change reads it and follows it; a change that must depart from it edits this file first, through a proposal. It is written from the user's decided design: the look, R1 to R7, accepted "All yes" on 2026-11-18, with the Facet rules and the element notes that came with it, and from the AI's round only the marks that belong to the AI. Where `tmp/briefs/ui-polish.md` (the early council notes) or any older text disagrees, this file wins: float titles sit on the left of the top border, not centered; no diamond marks the focused float or the active tab.

Facet means: calm, readable, carat's own personality, never a copy of another editor. The theme names are `carat-dark` and `carat-light`; section 3 gives their values. Section 7 lists where shipped code still differs and the queued item that closes each gap. Keys are in Vim notation; the screens draw `⏎` for `<CR>`, `␣` for `<leader>`, and `^X` for `<C-x>`.

## 1. The rules

- One cell of padding. Every surface keeps one cell of space inside its edges: tabs, tree rows, gutter, floats, status bar, winbar. Text never touches a border or the screen edge.
- Edges by background. Two surfaces meet where their backgrounds change (the sidebar is darker than the editor), with no glyph. A line is drawn only between two windows of the same color, in the quiet BORDER tone.
- Quiet frames. A float has rounded corners `╭╮╰╯` in BORDER, a tone quieter than its text; its title sits on the left of the top border with a dim count (`Files 2069`); the keys that matter sit in the bottom border; a query lives inside the float, on its first row, never on the command line. Panes inside one frame are joined by `├ ┤ ┬ ┴`. Heavy `┃` is only a scrollbar thumb. No double lines, no shadows.
- Alignment. Numbers are right-aligned; the sign column is always present, so text never shifts; two cells separate the gutter and the code; git letters and keycaps are right-aligned in the last cells.
- Hierarchy by tone. Bright, dim, and faint carry importance. Bold is only for the one thing that leads (the file name, the position, the selected row). A long name ends in a dim `…`.
- One meaning per mark. Section 4 is the table. A mark never says two things; a dot before a name is what it is (its file type), a dot after a name is its state.
- Spacing. One cell of padding inside every surface. Two cells between a pill and the next group, between a label and its detail, and between the gutter and the code; three cells between independent groups. No padding rows in lists or floats; blank rows only in reading surfaces (the start screen, the markdown view, between hover blocks). A float keeps one cell from the screen edge and never covers the cursor row.
- Surfaces, back to front. The editor (BG); panels (row 0, sidebars, the bottom panel); the status bar and keycaps (PANEL); floats (FLOAT); and, behind a modal float, the dimmed backdrop. Modal floats (finder, palette, pick lists) dim the screen behind them; non-modal ones (completion, hover, hints, notifications) do not.
- Focus. The focused window shows the cursor line across the gutter, the cursor's number bold, and its winbar file name bright. An unfocused window loses the cursor line; its code is never dimmed, since windows are read side by side.
- Motion. None, except the start screen's gem reveal and a 4 fps spinner in its own status cell; reduced motion freezes both.
- Cursor and pills. The cursor is the main mode signal (steady block in normal, visual, and operator-pending; bar in insert, the command line, and every prompt; underline in replace; no blink); the mode pill is the second, and the pills differ in lightness as well as hue.

## 2. Decisions R1 to R7

- R1, background. carat paints its theme background and picks `carat-dark` or `carat-light` from the background the terminal reports (OSC 11); `carat-dark` when it reports none.
- R2, padding. One cell sideways now; responsive padding later, as its own change.
- R3, the AI's mark. A gold `✦` means the AI: its shape and place, not its color. Types and warnings keep yellow; search stops being gold. The AI round narrows it: `✦` and `◈` are the AI's only, and `◇` is any suggestion.
- R4, search. A soft tint on every match with the text keeping its own color, a strong bold current match, and the count `[3/12]` at the right of the command line. Incremental search looks the same while typing.
- R5, sign column. Always on, one cell (`option.signcolumn yes`); git and diagnostics share it, the most important wins: error, review, warning, AI, info, suggestion, git.
- R6, diagnostic messages. After the code, on the cursor line only, dim and cut with `…`; other lines get the sign and a plain underline (errors and warnings only; curly and colored underlines are not reliable in the macOS terminal).
- R7, order. Foundation and defects first, then the elements seen on every keystroke, then floats, lists, and screens; the queues in `docs/queue-feature.md` and `docs/queue-backlog.md` carry the order.

## 3. Color roles

Accents carry meaning only: sapphire is focus or "this one", green is added or insert, cyan is changed or a query, red is error or delete, yellow is warning, purple is visual. Red never fills; an error is a red glyph, a bold red code, and normal text. The mode pills are fixed at 9 cells: NORMAL sapphire, INSERT green, VISUAL purple, REPLACE red, COMMAND and the pickers that take a query cyan.

The roles the design added or changed, with both palettes' values and the contrast each is held to:

| Role | carat-dark | carat-light | Used for |
| --- | --- | --- | --- |
| GUIDE | `#30364b` | `#d8dce8` | Indent guides, whitespace marks, the dimmed backdrop text |
| GUIDE_SCOPE | `#46506e` | `#a9b4d6` | The cursor's indent block |
| BORDER (new) | `#3b4157`, 1.77:1 on floats | `#c9cdd9`, 1.37 to 1.41:1 on floats | Float frames, splits, joints; exempt from the 3:1 test like the guides |
| PANEL_DIM (new) | `#a4aabd`, 5.4:1 | `#5c6173` | Quiet status bar text |
| SEARCH (softened) | `#4a4129` | `#f7e3a1`, 1.23:1 | Every match; the bold current match carries the strong fill |
| Panels | sidebar `#111319`, float `#15171e` | `#eceef3` for both | A visible step to the editor, in daylight too |
| SELECTION | `#323a55` | `#c2ccef` | The visual selection, the current list row |
| Panel pin at 256 colors | index 233 | as today | Keeps the edge between the sidebar and the editor |

Contrast targets: code text 10.5:1 on dark and 12.2:1 on light; quiet text (PANEL_DIM) at least 4.5:1, aimed at 5.4:1; the guides and BORDER are exempt from 3:1 because they are meant to be quiet. At 16 colors a pair is chosen for contrast first (reverse where a fill would vanish), and at 256 colors the sidebar and the editor must stay two colors.

Open questions, each to be settled by its own queued change with a measured value:

- Light BORDER: `#c9cdd9` holds only 1.37 to 1.41:1 on the light floats and may need to be darker.
- Light SEARCH: `#f7e3a1` is 1.23:1 against the light background and the bold current match carries it; a stronger value may be needed.

## 4. Glyphs

One meaning per glyph. The AI owns `✦` and `◈`; nothing else uses them.

| Glyph | Meaning | Rule |
| --- | --- | --- |
| `✦` | The AI: insights, the status bar while a request waits, the file segment while the panel has focus (`✦ AI`) | AI only; shape and place, not color |
| `◈` | The AI | AI only; the ruby and class icons give it up (section 7) |
| `◇` | Any suggestion, language-server hints included | |
| `✖` | Error | Shape first; the status bar's counts and the sign cell both read `✖ ▲ ◆ ◇` (error, warning, information, hint) |
| `▲` | Warning | Not `⚠`, which can turn into an emoji on the Mac |
| `◆` | Information | The constant icon gives it up |
| `▎` sapphire | This row: the selected row of every list | Full-width selection fill, bold label; its clash with the git sign is open until the glyph audit (below) |
| `│` solid | The cursor's indent block (GUIDE_SCOPE); a split between two windows of one color (BORDER) | Never a row mark |
| `┊` | An indent guide (GUIDE) | Faint everywhere |
| `┃` | A scrollbar thumb | Nothing else is heavy |
| `●` after a name | State: a tab's modified mark, the language server, the AI | After the label |
| `●` before a name | Type: the explorer's file-type dot (Ruby red, Markdown sapphire, data cyan, shell green, others faint) | Before the label; a tab has no type dot |
| `M A ? D` | Git state, right-aligned: M cyan, A green, ? dim, D red; a folder with changes shows a cyan dot | |
| `▎` green or cyan, `▁▔` red | Git signs in the sign column: added, changed, deleted | A diagnostic glyph wins the cell; the `▎` is the open clash with the selected row, settled by the glyph audit (below); the deleted sign ships as `▁` alone, a Known drift row |
| `▸` `▾` | A fold's closed gap; the chevrons of the tree | Faint |
| `⋯` | A closed fold's count (`⋯ 12 lines`, dim) | |
| `›` | A separator in the winbar (faint), the lead of a query, the user's words in the AI panel (sapphire) | Never a selection mark |
| `…` | Cut text, dim; a slow request while loading | |
| `↪` | A wrapped row | Faint |
| `→` `·` `␣` | Whitespace marks, off by default | GUIDE |
| `⌫` | Back, in the key hints' border | |
| `▀` | The start screen's gem, two colored halves per cell | Sapphire sparkle |

Completion kinds become letters, so the kind icons stop sharing the marks above. The open clashes the glyph audit settles, one meaning for each:

- `◆` information versus the constant icon.
- `◈` the ruby icon and the class icon, now also the AI's.
- `▸` the folder icon versus the property icon.
- `◇` a hint versus the keyword icon, and `▣` the JSON icon versus the module icon.
- `+` in the ascii set: the closed folder, ahead, and added.
- `▎` the selected row versus the git sign.
- `┃` the scrollbar thumb versus the git added sign, which ships as `┃`.

## 5. One accent

Sapphire marks "this one", and it fills only the mode pill. Everywhere else it is a mark or a text color.

- The mode pill is the only sapphire fill.
- The active tab takes the editor's background; its name is followed by the modified `●` and it carries no type dot. Other tabs sit on the panel. An overflow shows a count.
- Tab-page numbers: the current one bold, the others dim, no fill.
- The sidebar head reads `carat · main` (the project and branch); with two views, the shown one is bright, not filled.
- The winbar: folders dim, `›` faint, the file bright (dim when the window is unfocused), the symbol last, cut from the left with `…`; the focused name is bright, not filled.
- The matching bracket is bold sapphire and underlined, with no background.
- A selected list row is the sapphire `▎`, the SELECTION fill, and a bold label; no row also takes a `>` or `›`.
- The mode pill color follows the mode; a picker that takes a query uses cyan, like COMMAND, and the AI's marks stay the AI's.

## 6. Empty and loading states

An empty surface says one dim sentence and names one key (`Empty folder`, `no matches` with the key that leaves). A surface that is waiting shows a dim `…` after its label (`Reading…`); a slow request shows the dim `…`, never a progress bar, and the spinner lives in its own status cell. Nothing else fills the space: no art, no padding rows. A failure is the error rule of section 3: a red glyph, a bold red code, normal text.

## 7. Known drift

Where the shipped code differs from this file at `6bb8f2a`, and the item that closes it. `finder-rows`, `explorer-rows`, and `float-polish` are in `docs/queue-feature.md`; `one-accent` and `glyph-audit` are planned items, which reach the queue through the planner's plan and are named here until then. A row leaves this table in the change that closes it.

| Gap | Where | Closing item |
| --- | --- | --- |
| The active tab is a sapphire fill | `carat/adapters/tab_bar.rb:126`, the TabLineSel row `carat/domain/themes.rb:109` | `one-accent` |
| The tab-page number is a sapphire fill | `carat/adapters/tab_bar.rb:115` | `one-accent` |
| The sidebar header is a sapphire fill | `carat/adapters/frame_presenter.rb:992` | `one-accent` |
| The focused winbar name is a sapphire fill | `carat/adapters/winbar.rb:39` | `one-accent` |
| The tab carries a type icon | `carat/adapters/tab_bar.rb:129` | `one-accent` |
| Four selection marks: the palette band (PmenuSel) | `carat/adapters/frame_presenter.rb:714` | `one-accent` |
| Four selection marks: the tab fill | `carat/adapters/tab_bar.rb:126` | `one-accent` |
| Four selection marks: the finder's `> ` | `carat/plugins/finder/plugin.rb:32` | `finder-rows` |
| Four selection marks: the explorer's `›` | `carat/plugins/explorer/tree.rb:167`, the icon `current` at `carat/domain/icons.rb:63` | `explorer-rows` |
| Float titles are centered | `carat/adapters/frame_presenter.rb:737`, `:744` | `float-polish` |
| Notice titles are centered | `carat/adapters/frame_presenter.rb:550` | `float-polish` |
| `◆` is information and constant | `carat/domain/icons.rb:66`, `:90` | `glyph-audit` |
| `◈` is ruby and class | `carat/domain/icons.rb:68`, `:85` | `glyph-audit` |
| `▸` is folder and property | `carat/domain/icons.rb:58`, `:87` | `glyph-audit` |
| `◇` is hint and keyword | `carat/domain/icons.rb:67`, `:88` | `glyph-audit` |
| `▣` is JSON and module | `carat/domain/icons.rb:69`, `:86` | `glyph-audit` |
| The git signs ship `┃` added and `┇` changed, while `┃` is the scrollbar thumb only | `carat/domain/icons.rb:93`, `:94` | `glyph-audit` |
| The deleted git sign ships `▁` alone, where the table decides `▁▔` | `carat/domain/icons.rb:95` | `glyph-audit` |
| `+` is the closed folder, ahead, and added in ascii | `carat/domain/icons.rb:99`, `:132`, `:134` | `glyph-audit` |
| TabLine and TabLineSel fall below the contrast target at 16 colors | `carat/domain/themes.rb:108`, `:109` | `one-accent` |

## 8. Elements

The element notes of the decided design, for a change that touches one.

- Start screen. The gem is drawn with `▀`, two colored halves per cell, from a small table in Ruby; no image. The sparkle is sapphire; the six-step reveal stays; the version is dim; the hints sit in two columns; the triangles stay at 16 colors.
- Editor and explorer. The explorer is 36 columns by default and sits on a darker panel, with no line beside it. Rows keep one cell of padding, long names end in `…`, tree guides are faint, the current row is a full-width highlight with the sapphire `▎`, and git state is right-aligned. The tab row heads the explorer's column with the project and branch.
- Tab row. The open file always has a tab (the queued `showtabline` may hide the row itself), the active tab takes the editor's background, the modified `●` follows the name.
- Gutter. A sign column that is always there, the line number right-aligned and faint (the cursor's bold; relative mode brightens every fifth), then two cells before the code. The cursor line runs from column 0 across the gutter in the focused window only; a selection wins over it.
- Winbar. The path and the symbol, separators dimmed, the file bright when focused, dim when not; the lower window's winbar is the edge of a horizontal split.
- Status bar. The file name and the position lead; folder, branch, server, type, and encoding step back in PANEL_DIM; zero counts are hidden; warnings show `▲`; groups are three cells apart with no separator glyphs; the server state is one dot.
- Finder. One frame holds the query row, the list, and the preview, joined by `┬` and `┴`, titled on the left with the file count (`Files 2069`), with `⏎ open ^s split ^v vsplit ^t tab` in the bottom border. Rows: the folder dim, the file name bright, the matched letters sapphire, the selected row marked as in section 5. The screen behind is dimmed.
- Key hints. Docked at the bottom above the status bar, four columns, titled `␣ leader` on the left with `⌫ back Esc close` in the border; groups (`+files`) in sapphire, single actions in plain text, short labels; pending keys show dim at the right of the command line. Two key styles: bold when the surface waits for that key, plain when it is only available.
- Messages and prompts. A confirmation shows the destructive verb in bold red, `y` and `n` in sapphire, nothing preselected, Enter alone meaning no. The command line prompt is dim in column 1 with a bar cursor; the match count and pending keys are dim at the right.
- Vertical marks. Reduce to the guide `┊`, scope and splits `│`, and the row `▎`.
