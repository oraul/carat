# Backlog: carat/plugins/finder/plugin.rb

## A resize with the finder open is untested

- Where: `carat/plugins/finder/plugin.rb` line 102, which re-lays the floats on a resize and turns the preview on or off at 100 columns. Quality review of `file-finder`.
- Why it matters: the preview's width threshold on a resize has no row.
- Fix outline: add a `test/editor_finder.rb` row that resizes the harness from 80 to 120 columns with the finder open and expects the preview float.
- Also: test/editor_finder.rb
- Category: plugins
- Added: 2026-11-10

## The finder re-reads its preview on every key

- Where: `carat/plugins/finder/plugin.rb` line 276, `refresh`, which reads the highlighted file (up to 256 KiB) through `read_file` on every keystroke and highlight move. Quality review of `file-finder`.
- Why it matters: typing a query re-reads the same file when the highlighted path does not change.
- Fix outline: keep the last previewed path, height, and lines, and read again only when the path or the height changed.
- Category: plugins
- Added: 2026-11-10

## The finder's open with no file window replaces the explorer's tree

- Where: `carat/plugins/finder/plugin.rb:319` against `carat/plugins/explorer/plugin.rb:284`. Periodic quality at ce6abdb; queue item `finder-grep`.
- Why it matters: `open_path` passes `editing_window` 0, which resolves to the current window, so with only the tree shown the file replaces the tree's scratch buffer; the open-by-how dispatch is copied in both plugins and untested.
- Fix outline: handle target 0 as the explorer does, with a `test/editor_finder.rb` row; consider one shared plugin API helper.
- Also: carat/plugins/explorer/plugin.rb, test/editor_finder.rb
- Category: plugins
- Added: 2026-11-10

### Quality advisory: finder FRAME literal ignores winborder (carat/plugins/finder/plugin.rb:32)

- Location: carat/plugins/finder/plugin.rb:32
- Why: FRAME = 4 restates FloatWindow.frame_width(1) as a literal, so under winborder none the finder keeps a 3-column right margin and a 2-column gap.
- Fix: expose the frame width through PluginApi in float-placement and derive the finder's sizes from it.
- Category: plugins
- Added: 2026-11-14

### The finder copies the explorer and the explorer loses a followed file

- Location: carat/plugins/finder/plugin.rb:321, 336, 177 and carat/plugins/explorer/plugin.rb:420 (sprint-4 sweep, quality).
- Why: open_path, report, and ignored repeat the explorer's; finish_rename moves @followed only on an exact match, so a file inside a renamed directory keeps its old path.
- Fix: add the shared helpers to PluginApi; rewrite @followed on a path-plus-slash prefix with a test.
- Also: carat/plugins/explorer/plugin.rb
- Category: plugins
- Added: 2026-11-14

### The finder lists hidden .ruby-lsp files the explorer hides
- Location: carat/plugins/finder/plugin.rb
- Why: a ruby-lsp project shows .ruby-lsp/Gemfile and .gitignore first in Ctrl-P while plugin.explorer.show_hidden false hides them
- Fix: apply the explorer's hidden and ignore rules to the finder's file list
- Also: .gitignore
- Category: plugins
- Added: 2026-11-16

### The finder's tab pick repeats the open_file call of its default branch
- Location: carat/plugins/finder/plugin.rb:332 (open_path, the when :tab branch)
- Why: the :tab branch's target == 0 arm repeats the else branch's host.open_file(target, path) inside a ternary, so the default open lives in two places and can drift (two quality advisories, duplication and simplicity, merged here)
- Fix: before the case, map how to the default when it is :tab and target is 0 (or guard so :tab reaches open_as_tab only when target != 0), leaving when :tab to call open_as_tab alone and the zero case to fall through to the one open_file call
- Category: plugins
- Added: 2026-11-18

### The grep picker reads every listed file synchronously on the editor (sprint-20 review security Low (3), plugin.rb:186)

- Location: `carat/plugins/finder/plugin.rb:186`
- Why: In this change: the grep picker reads every listed file synchronously on the editor thread when it opens (up to MAX_FILES files of up to READ_LIMIT bytes each). Pressing <leader>fg in a very large or hostile repository can freeze the editor for a long time; it is a local denial of service that only the user can trigger.
- Fix: Cap the total bytes read across files (stop when MAX_LINES fills or a byte budget is spent), read only what FILE_ROWS needs, or load in steps between keys so Esc stays responsive.
- Category: security
- Added: 2026-11-19

### The file finder builds its empty lists with Grep.no_strings (sprint-20 sweep quality, plugin.rb:70)

- Location: `carat/plugins/finder/plugin.rb:70`
- Why: the file finder builds its empty lists with Grep.no_strings (lines 70, 196, 296, 350), so the path picker depends on the grep index for a typed-empty-array helper
- Fix: move no_strings and no_ints to a neutral place in the finder (Matcher or a small helper module) or build them locally
- Merged: ### Coupling (sprint-20 sweep quality, plugin.rb:70)
- Location: `carat/plugins/finder/plugin.rb:70`
- Why: coupling: the plugin builds its own typed empty lists through Grep.no_strings (70, 195, 296, 350), and Grep exposes the general helpers no_strings, no_ints, and utf8_size as public class methods of the content index
- Fix: give the plugin its own private typed-empty helper (or one small Finder module both require) and make Grep's helpers private
- Category: plugins
- Added: 2026-11-19

### The action descriptions of plugin.finder.next, previous, open_split, (sprint-20 sweep quality, plugin.rb:89)

- Location: `carat/plugins/finder/plugin.rb:89`
- Why: the action descriptions of plugin.finder.next, previous, open_split, open_vsplit, and open_tab still say 'file' though they now also move over and open the grep picker's line rows
- Fix: say 'row' (the highlighted row) in the manifest and the matching docs/actions.md rows
- Merged: ### Stale descriptions (sprint-20 sweep quality, plugin.rb:89)
- Location: `carat/plugins/finder/plugin.rb:89`
- Why: stale descriptions: plugin.finder.next, previous, open_split, open_vsplit, and open_tab say file, but the same actions move and open grep lines on <leader>fg
- Fix: describe them as the highlighted row or match (and the rows in docs/actions.md)
- Also: docs/actions.md
- Category: plugins
- Added: 2026-11-19

### The file finder shows paths as the file lists them
- Location: carat/plugins/finder/plugin.rb, `list_lines` and the file finder's preview title in `refresh`
- Why: the grep rows and the grep preview's title show a path through `Grep#safe`, but the file finder's rows and preview title show the listed path as it is, so a file name with a control byte or a bidirectional override reaches the terminal there.
- Fix: pass the file finder's row text and preview title through the same safe-text path (make it a public `Finder` helper shared with `Grep`); accepted when a test lists a file named with a tab and an escape and shows spaces in the list and the title.
- Category: plugins
- Added: 2026-11-20

### File finder rows and preview title show the listed path unsanitized
- Location: carat/plugins/finder/plugin.rb:333 (the preview title and the rows, through selected_path)
- Why: the grep path now goes through Grep#safe, but the file finder still shows the listed path raw; in an untrusted repository a checked-in file name holding a bidirectional override (U+202E) or a zero-width character can make the finder show a different path than the one it opens. C0 controls are already shown as ^X by the frame presenter, so no escape sequence reaches the terminal. Security Low (confidence 5); the behavior predates this change.
- Fix: move Grep#safe into a shared helper in carat/plugins/finder/ and apply it to the file finder's rows and preview title wherever selected_path is shown, keeping the raw path for open_path; add a test with a path holding U+202E and a control byte.
- Category: security
- Added: 2026-11-20

## Findings of finder-grep-preview after its package step

- security Low (5) carat/plugins/finder/plugin.rb:333 The file finder's preview title and rows still show the listed path without sanitizing it. A file name checked into an untrusted repository can contain U+202E or a zero-width character and make the finder display a different path from the one it opens. C0 control bytes are already shown as X by the frame presenter, so no escape sequence reaches t
- quality advisory docs/findings/finder-grep-preview.md:35 duplication: the entries at lines 35, 40, and 45 repeat the entries at lines 1, 6, and 11 verbatim (the retro notes appended twice); fix: drop lines 35 to 48
- quality advisory docs/findings/finder-grep-preview.md:31 duplication: the entry 'File finder rows and preview title show the listed path unsanitized' restates the entry at line 26 ('The file finder shows paths as the file lists them') with the same fix; fix: merge the two into one entry, keeping the security rating and the U+202E test outline
- Category: security
- Added: 2026-11-20

### Space f w takes no word to the right of a blank cursor
- Location: carat/plugins/finder/plugin.rb `word_under_cursor`, carat/plugins/finder/matcher.rb `word_at`.
- Why: Neovim's cword takes the next word to the right on the line when the cursor is on a blank; the queue entry asks for the empty grep on a blank, so this change opens it empty, which differs from Neovim for a user who expects the nearest word.
- Fix: when word_at finds no word at the column, scan right on the same line for the first keyword byte and return its run; add a table row and a spec scenario, and change the compatibility row.
- Also: carat/plugins/finder/matcher.rb
- Category: plugins
- Added: 2026-11-22

### The grep preview's matched line has the bar but no fill or color
- Location: carat/plugins/finder/plugin.rb (preview_lines, the grep preview passing MARK to Grep#preview), carat/plugins/finder/grep.rb:174
- Why: design section 5 marks a selected row with the sapphire bar, the selection fill, and a bold label; the preview's matched line now starts with the same `▎ ` but in plain NormalFloat text, so the bar is not sapphire there and the line carries no fill, which may read as a second selected row or as a mark without its color.
- Fix: decide in docs/design.md how the preview marks its matched line (a sapphire bar alone, or the fill); then style the preview float after each fill with style_float, a PmenuMarkSel span on the bar and, if the fill is chosen, the line as its selected row, with a test under truecolor, 16 colors, and NO_COLOR.
- Also: carat/plugins/finder/grep.rb, docs/design.md
- Category: plugins
- Added: 2026-11-22

### The finder's rows lack the dim folder and the sapphire matched letters
- Location: carat/plugins/finder/plugin.rb (list_lines, style_list), docs/design.md section 8 (Finder)
- Why: the Finder note of design section 8 draws the folder dim, the file name bright, and the matched letters sapphire; the rows now carry the selected row's look only, so the folder and the matched letters still read in the row's text color.
- Fix: have Matcher and Grep report the matched columns, and add PmenuMatch spans for them and a dim span for the folder part of each row in style_list, keeping the finder within PICKER_BUDGETS, with snapshots at every color depth.
- Also: docs/design.md
- Category: plugins
- Added: 2026-11-22

### The finder styles its rows with group ids it never checks
- Location: carat/plugins/finder/plugin.rb (activate, style_list)
- Why: activate keeps the number of syntax_group("PmenuMarkSel") and syntax_group("PmenuLabelSel") without checking the response; on a host that refused the names the ids would be 0 and every style_float would fail with "No float group 0", leaving the highlighted row with no fill. It cannot arise today, since the finder is compiled with the host at API 2.15, so it was recorded rather than given an untestable branch.
- Fix: when either response fails, style the row with no spans (the selection fill alone), and test it with a host double that refuses the names.
none
- Category: plugins
- Added: 2026-11-22
