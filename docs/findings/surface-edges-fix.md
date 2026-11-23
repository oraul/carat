### The head reuses three existing groups
- Location: `carat/adapters/tab_bar.rb`, `paint_head` (Normal, NonText, MsgDim lifted onto the sidebar layer)
- Why: the groups are named for other uses, so a theme author cannot restyle the head alone; the council's `one-accent` item adds a bold no-fill group the head could take.
- Fix: when `one-accent` adds its groups, give the head its own (project, dot, branch) and drop the reuse; the tests name the groups by id, so they change with it.

### The project name is the base directory of the last opened file
- Location: `carat/adapters/tab_bar.rb`, `paint_head` (reads `BufferList#base`)
- Why: `base` is set at startup and by `OpenFile`, not by `:cd`, so after a directory change the head can name the old project until a file is opened; the explorer's root row follows the working directory.
- Fix: have the working-directory change set `BufferList#base`, or give the presenter the working directory through the state, with a test that `:cd` renames the head.

### The right sidebar and the panel keep their title rows, and the tab row still spans a right sidebar
- Location: `carat/domain/slot.rb`, `headed?`; `carat/adapters/frame_presenter.rb`, `paint_tab_head`
- Why: the brief's head and one-view rule are the left sidebar's; with the explorer on the right (`plugin.explorer.side right`) the tab row starts at column 0 and runs over the sidebar's width, and the sidebar keeps its `explorer` title row.
- Fix: decide the right sidebar's look in a design item (head, or the tab row ending at its edge), then extend `headed?` and `paint_tab_head` to it with a test.

### Neighbouring tabs are three cells apart, not two
- Location: `carat/adapters/tab_bar.rb`, `paint_tab` (`FRAME_CELLS`)
- Why: removing the separator leaves the trailing space and the next tab's two leading spaces; the council's spec is two blank cells, with the icon gone and the padding space, name, space, mark, space.
- Fix: in `one-accent`, which removes the icon, set the padding to the spec, `FRAME_CELLS` to 3, and update the expected rows of `adapters_tab_bar`, `editor_tabs`, and `editor_tab_flows`.

### A narrow sidebar cuts the head silently
- Location: `carat/adapters/tab_bar.rb`, `paint_head`
- Why: below about 14 columns the project is cut at the sidebar's edge with no ellipsis, and the branch is dropped first; the council defers the rules for narrow widths.
- Fix: in the narrow-widths item, cut the project with an ellipsis and drop the branch below a width, with a table-driven test of the widths.
