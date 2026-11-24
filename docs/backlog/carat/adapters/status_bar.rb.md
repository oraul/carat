# Backlog: carat/adapters/status_bar.rb

## Bar and frame findings of the periodic review at 186ddfb

- Where: `carat/adapters/status_bar.rb` line 1 requires `../plugin_api` and names none of it; `carat/adapters/frame_presenter.rb` line 299 `display_col` and `display_width` are public but used only inside; `NO_NAME` is defined in `status_bar.rb` line 47, `tab_bar.rb` line 23, and `winbar.rb` line 214. Periodic quality at 186ddfb, queued in `bars-tidy`, the `NO_NAME` triplicate in `top-rows` (the notice border folded into `float-frame`, which drew both boxes through one painter).
- Why it matters: a dead require, a wide public surface, and three constants to keep in step.
- Fix outline: drop the require; move `display_width` below `private` and drop `display_col` (update the area 13 entry); one `[No Name]` on `Domain::Buffer`.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-10

## Quality: the icon set name "ascii" is a string literal in four places, carat/adapters/status_bar.rb:254

- Location: carat/adapters/status_bar.rb:254, carat/adapters/frame_presenter.rb:217, :266, and :859, beside carat/adapters/options.rb:156 (found reviewing carat-glyphs).
- Why: the set name is compared as a string literal at each site, so a rename or a new set has to find them all.
- Fix: add an Options#ascii_icons? predicate (or an Icons::ASCII_SET constant) and use it at each site so the set name lives in one place.
- Also: carat/adapters/frame_presenter.rb
- Category: editor
- Added: 2026-11-15

### StatusBar requires plugin_api without using it
- Location: carat/adapters/status_bar.rb:1
- Why: the only adapter requiring it, naming no PluginApi constant. Folded into ui-code-tidy.
- Fix: remove the require.
- Category: editor
- Added: 2026-11-17

### Three bars define [No Name]

- Location: carat/adapters/status_bar.rb:47, tab_bar.rb:22, winbar.rb:18 (sweep, quality).
- Why: three copies of one constant.
- Fix outline: one domain constant the three read.
- Category: editor
- Added: 2026-11-17

### The No Name label is spelled in five files (sprint-16 sweep quality)

- Location: carat/adapters/status_bar.rb:47, tab_bar.rb:22, winbar.rb:18, carat/use_cases/buffers/list_buffers.rb:22, carat/domain/messages.rb:22.
- Why: architecture section 5 puts a constant several files need in the domain.
- Fix outline: one Domain::Messages::NO_NAME read by all five.
- Also: carat/use_cases/buffers/list_buffers.rb, carat/domain/messages.rb
- Category: editor
- Added: 2026-11-18

### Comments break their wrap width at carat/adapters/status_bar.rb:17 (sprint-28 review quality note 5, sweep notes 39, 58)

- Location: carat/adapters/status_bar.rb:8, :17, :25; .github/workflows/ci.yml:26, :161; .claude/workflows/deliver-change.js:124, :130; tools/gates.sh:517
- Why: overlong and one-word comment lines left by ui-groups and earlier edits.
- Fix: rewrap.
- Also: .github/workflows/ci.yml, .claude/workflows/deliver-change.js, tools/gates.sh
- Category: editor
- Added: 2026-11-22

### Server states differ only by the dot's color
- Location: `carat/adapters/status_bar.rb` (`paint_lsp`, `lsp_group`)
- Why: starting, indexing, ready, and stopped are the same dot, so at 16 colors and under NO_COLOR, where the group colors collapse, they read alike; the crash and untrusted hints still name themselves.
- Fix: in the terminal-byte proof of NO_COLOR and 16 colors (`ui-groups-c`), decide whether the dot needs a second glyph for stopped.
- Category: editor
- Added: 2026-11-23

### The folder cannot be dropped on a narrow bar
- Location: `carat/adapters/status_bar.rb` (`paint_file_name`, `fit`)
- Why: the folder is part of the file entry, which is never dropped, so a long path takes the width a narrow bar's other segments need before the file is cut.
- Fix: draw only the last segment of the path when the bar is narrow, or give the folder its own entry of low priority.
- Category: editor
- Added: 2026-11-23

### The lsp group is computed twice per paint
- Location: `carat/adapters/status_bar.rb` (`paint_entry`, `paint_lsp`)
- Why: `paint_lsp` and the closing space in `paint_entry` each call `lsp_group`, a small duplication kept because returning the column and the group together would allocate each frame.
- Fix: keep the group in an integer instance variable that `paint_lsp` sets and `paint_entry` reads.
- Category: editor
- Added: 2026-11-23

### The server state dot is the modified icon at carat/adapters/status_bar.rb:346 (sprint-30 review quality)

- Location: carat/adapters/status_bar.rb:346 (paint_lsp), :360 (lsp_width), beside :255 (the modified file mark)
- Why: since #321 the bar draws the language server state with Icons.glyph("modified"), whose ASCII form is `*`, the same glyph the bar puts after a modified file name, so under the ascii icon set `ruby-lsp *` reads as a modified marker; the icon is named for another meaning.
- Fix: add a named icon for the state dot to Domain::Icons with its nerd, unicode, and ascii forms and use it in paint_lsp and lsp_width; accepted when an ascii status bar snapshot shows the state glyph apart from the modified mark.
- Category: editor
- Added: 2026-11-23
- Merged: ### The server state dot borrows the modified icon at carat/adapters/status_bar.rb:346 (sprint-31 review quality)
- Location: carat/adapters/status_bar.rb:346 and :360 (`Icons.glyph("modified", set)` in paint_lsp and lsp_width)
- Why: the lsp slot draws its state dot with the glyph named for the buffer's modified mark, so a change to the modified icon restyles the server state too, and the name hides what the dot means.
- Fix: an icon name of its own for the state dot in Icons, with the status bar test reading it.

