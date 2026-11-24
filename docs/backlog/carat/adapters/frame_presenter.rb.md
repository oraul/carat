# Backlog: carat/adapters/frame_presenter.rb

## Slot headers mark the shown view by title

- Where: `carat/adapters/frame_presenter.rb` line 717 and `Slot#add_view` in `carat/domain/slot.rb` line 84, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: views are listed and marked by title only, so two plugins opening views with the same title in one slot show one header entry.
- Fix outline: record each view by owner and title, or by buffer, and mark the shown one by identity, with an `editor_slots` row of two plugins sharing a title.
- Also: carat/domain/slot.rb
- Category: editor
- Added: 2026-11-09

## The presenter and explorer comments omit the slots

- Where: the class comment of `carat/adapters/frame_presenter.rb` line 27 and `carat/plugins/explorer/plugin.rb` line 7, at b76b722. Periodic quality. Queue item `slots-tidy`.
- Why it matters: the presenter comment lists every frame part but not the slot header rows `paint_headers` adds, and the explorer still calls its tree a fixed-width side window though it opens in a sidebar slot.
- Fix outline: add a sentence on the slot headers and say left or right sidebar slot in the explorer comment.
- Also: carat/plugins/explorer/plugin.rb
- Category: editor
- Added: 2026-11-09

## FramePresenter's class comment breaks its wrap width

- Where: the class comment of `carat/adapters/frame_presenter.rb` line 40 at the `breadcrumbs` change; quality advisory of `breadcrumbs`.
- Why it matters: the edit left a three-word line mid-sentence, which reads as a broken paragraph.
- Fix outline: rewrap the paragraph.
- Category: editor
- Added: 2026-11-09

## The notice painter's comments and narrow guard

- Where: `carat/adapters/frame_presenter.rb` line 429 (a comment line not wrapped like its block) and line 439 (the `cols < NOTICE_NARROWEST` guard after the widths it makes moot), and `carat/domain/editor_state.rb` line 13 (an unwrapped comment line), at the `feedback` change. Quality advisory of `feedback`.
- Why it matters: style drift and widths computed for nothing on a narrow screen.
- Fix outline: rewrap both comments and move the guard to the top of `add_notice_boxes`.
- Also: carat/domain/editor_state.rb
- Category: editor
- Added: 2026-11-09

## Feedback's naming, wrap, and plugin docs drift

- Where: `carat/adapters/frame_presenter.rb` line 507 (a group id in a local named `text`), `carat/adapters/status_bar.rb` line 16 (a class comment past the wrap width), `docs/plugins.md` line 69 (the `set_segment` row omits the progress segment at 35 and its place before `lsp`), at 31919d9. Periodic quality. Queue item `messages-tidy`.
- Why it matters: a misleading name, style drift, and a plugin author misreading where a segment lands.
- Fix outline: rename the local, rewrap the paragraph, and add the progress to the row's priorities.
- Also: carat/adapters/status_bar.rb, docs/plugins.md
- Category: editor
- Added: 2026-11-09

## FramePresenter keeps two dead width wrappers

- Where: `display_col` and `display_width` in `carat/adapters/frame_presenter.rb` line 299, called only by `test/adapters_frame_presenter.rb` line 317, at 5e4c140. Periodic quality. Queue item 38 (dead public methods).
- Why it matters: public surface the paint path never uses.
- Fix outline: delete both and have the test call `DisplayWidth.column(line, line.length, 4)`.
- Also: test/adapters_frame_presenter.rb
- Category: editor
- Added: 2026-11-09

## The visual cursor cell ignores documentation styles

- Where: the visual-mode cursor cell in `FramePresenter` (`token_group` over `buffer.syntax_cache.lookup`, `carat/adapters/frame_presenter.rb` near line 692), which reads only the syntax cache, at the `quick-docs-styles` change.
- Why it matters: in the pinned `[docs]` split, the cell under the cursor in visual mode takes the plain text's group instead of its markup group, unlike the cells around it.
- Fix outline: fall back to `buffer.style_at(row, line)` when the cache is inactive and the buffer is styled, as `paint_window` does, with a row in `test/adapters_hover.rb`.
- Also: test/adapters_hover.rb
- Category: editor
- Added: 2026-11-09

## A styled float row reads its line and decoded tokens twice

- Where: `carat/adapters/frame_presenter.rb` line 639, `paint_float_row`, which calls `buffer.line(row)` and `@cache.fetch` once for `paint_text` and again for `paint_tokens` on a styled row. Quality advisory of `float-frame`.
- Why it matters: duplicated work per row in the presenter's hot path, which the `float-frame` proposal set out to tidy.
- Fix outline: fetch the line and its decoded form once into locals before the branch and reuse them for the tokens; confirm with `make bench`. Queue item `float-placement`.
- Category: editor
- Added: 2026-11-10

## Float borders keep their colors under NO_COLOR

- Where: `carat/adapters/frame_presenter.rb:691` (`paint_border_row`, `paint_title` at 705) against the notification boxes at 504 and 508. Periodic quality at bd86828.
- Why it matters: the floating-windows spec says the two boxes share a border, yet under NO_COLOR they differ.
- Fix outline: one rule for both, or the reason recorded, with an `editor_floats` NO_COLOR row. Queue item `float-placement`.
- Category: editor
- Added: 2026-11-11

## The frame presenter's class comment wraps unevenly (float-placement, quality advisory)

- Where: `carat/adapters/frame_presenter.rb:90`.
- Why it matters: style: the class comment line ending "in FloatTitle. The notifications follow at the top right in the same" runs past the file's wrap width while the next lines break short.
- Fix outline: rewrap the paragraph.
- Category: editor
- Added: 2026-11-14

### Quality: the slot header's shown view shares the accent without a word in the docs, carat/adapters/frame_presenter.rb:916

- Why: undocumented side effect; the slot header row's shown view also uses `TabLineSel` and so becomes the bold blue block, but the proposal, design, and README list only the tabs, the tab-page numbers, and the winbar as sharing the accent.
- Fix: name the slot header in the design and README, or confirm it is intended.
- Category: editor
- Added: 2026-11-14

### FramePresenter#call is 116 lines

- Location: carat/adapters/frame_presenter.rb:200 (sprint-4 sweep, quality).
- Why: one method sizes, keys floats, draws chrome, the start screen, dirty marks, and places the cursor.
- Fix: move the float-key block (226-239) and the chrome dirtiness loop (289-298) into private methods.
- Category: editor
- Added: 2026-11-14

## Quality: the ascii icon set is tested three times in carat/adapters/frame_presenter.rb:266

- Location: carat/adapters/frame_presenter.rb:266, beside :217 and :859 (found reviewing carat-glyphs).
- Why: options.icons == "ascii" is evaluated at :217 for the border, again at :266 for the separators and winbars, and once per window at :859 in paint_window, so the one decision is duplicated and repeated per window.
- Fix: compute ascii once at the top of call, reuse it for the border, and pick both separator glyphs there (or keep the row glyph in the one place call already chooses the column glyph).
- Category: editor
- Added: 2026-11-15

### The frame presenter still paints floats, menus, and messages itself (architecture-review M2)

Location: `carat/adapters/frame_presenter.rb` (1,274 lines); `TabBar`, `StatusBar`, `Winbar`, `IndentGuides`, and `PaintedRows` were split out already. Why: floats, the completion menu, the message area, notifications, and the diagnostic line are painted inline, so each new overlay grows the file. Fix outline: move float and menu painting and the message rows into painters on the pattern of `StatusBar`, the presenter keeping the frame swap and the window rows.
- Category: editor
- Added: 2026-11-15

### Insert mode is shown twice, in the pill and on the message row

- Location: `carat/adapters/frame_presenter.rb:1255`.
- Why: the status bar's `INSERT` pill and `-- INSERT --` on the message row say the same thing and take the message row while typing (ux-pass review finding 6). Reproduction: start on a file, `i`, `openspec/changes/archive/*-ux-pass/screens/time-insert-char.txt`, rows 23 and 24.
- Fix: drop the message-row mode text while the status bar shows the mode pill, or add a `showmode` option defaulting to off.
- Category: editor
- Added: 2026-11-15

### The completion popup is the only float without a border

- Location: `carat/adapters/frame_presenter.rb:661` (borders only for an edged float), the completion float.
- Why: hover, the finder, the palette, and the key-hint menu share a rounded `#6c7286` border with a bold title; the completion popup has neither, and no rule says when a float is borderless (ux-pass review finding 8). Reproduction: start on a Ruby file with a language server, `8G`, `o`, `gre`, `openspec/changes/archive/*-ux-pass/screens/float-completion-lsp.txt` against `float-hover.txt`.
- Fix: decide the rule (every float bordered, or inline lists near the cursor borderless), record it in `docs/architecture.md` with the float style, and make the completion popup follow it.
- Also: docs/architecture.md
- Category: editor
- Added: 2026-11-15

### FramePresenter compares the float key twice in a row
- Location: carat/adapters/frame_presenter.rb:236
- Why: same_ints?(@float_key, back.floats) runs twice. Folded into ui-code-tidy.
- Fix: compute it once into a local.
- Category: editor
- Added: 2026-11-17

### A notice box covers the whole row on narrow screens
- Location: carat/adapters/frame_presenter.rb:460
- Why: the comment says half the screen, but NOTICE_MIN_WIDTH overrides it below 40 columns and from 8 to 21 columns the box clamps to left 0 across the row. Folded into ui-code-tidy.
- Fix: cap the width at cols - 2, or correct the comment and the map.
- Category: editor
- Added: 2026-11-17

### The Visual cursor cell loses a documentation buffer's markup

- Location: carat/adapters/frame_presenter.rb:742, :826 (sweep, quality).
- Why: place_cursor reads the group from syntax_cache.lookup while paint_window paints a styled buffer from style_at, so the cursor cell shows Normal.
- Fix outline: one private helper choosing the entry as paint_window does.
- Category: editor
- Added: 2026-11-17

### FramePresenter exposes test-only wrappers

- Location: carat/adapters/frame_presenter.rb:318, :1235, docs/codebase-map.md:462 (sweep, quality).
- Why: public display_col and display_width wrap DisplayWidth.column for one test; diagnostic_group is a public class method under private.
- Fix outline: test DisplayWidth.column directly, make them private, update the map entry.
- Also: docs/codebase-map.md
- Category: editor
- Added: 2026-11-17

### Replace mode shows no mode message

- Location: carat/adapters/frame_presenter.rb:1256 (sweep, quality, Neovim compatibility).
- Why: paint_message shows -- INSERT -- and the visual modes but nothing in Replace, where Neovim prints -- REPLACE --.
- Fix outline: add the branch with a frame presenter test and a docs/compatibility.md note.
- Also: docs/compatibility.md
- Category: editor
- Added: 2026-11-17

### Class comments in the UI adapters are ragged

- Location: carat/adapters/frame_presenter.rb:43, :90, status_bar.rb:16, set_command_handler.rb:17, highlight.rb:6, frame.rb:15, :31 (sweep, quality).
- Why: later edits left them past or short of the 72-column wrap.
- Fix outline: rewrap them.
- Category: editor
- Added: 2026-11-17

### Replace mode shows no mode message (sprint-16 sweep quality)

- Location: carat/adapters/frame_presenter.rb:1260 (paint_message).
- Why: Neovim's showmode prints -- REPLACE -- in replace mode; carat prints nothing, a compatibility gap.
- Fix outline: add the REPLACE branch and a row in test/adapters_frame_presenter.rb and docs/compatibility.md. Pool item `frame-presenter-tidy`.
- Also: test/adapters_frame_presenter.rb, docs/compatibility.md
- Category: editor
- Added: 2026-11-18

### FramePresenter's public surface is wider than its callers (sprint-16 sweep quality)

- Location: carat/adapters/frame_presenter.rb:320 (display_col, display_width), :1252 (self.diagnostic_group).
- Why: public wrappers used only by place_cursor, paint_diagnostic, and one test widen the class's surface.
- Fix outline: make them private, the test calling DisplayWidth.column directly. Pool item `frame-presenter-tidy`.
- Category: editor
- Added: 2026-11-18

### The bracket pair key multiplies by a bare number (sprint-19 review quality)

- Location: `carat/adapters/frame_presenter.rb:1246`
- Why: pair_key multiplies by 1_000_003 and the column bound it assumes is written only in the archived design.md, so a reader cannot see why it is safe.
- Fix: a private constant (PAIR_KEY_STRIDE) with a comment that columns stay below it. Queued in `render-tidy`.
- Category: editor
- Added: 2026-11-19

### frame_presenter class comment leaves a short line
- Location: carat/adapters/frame_presenter.rb:57
- Why: the rewrapped class comment leaves a line ending in 'column. With' before 'indentguides' on the next line, which reads badly
- Fix: reflow lines 57 to 59 so the sentence 'With indentguides ...' continues the paragraph
- Category: editor
- Added: 2026-11-19

### Find_pair bounds the search by window.top + window.height buffer lines, (sprint-20 sweep quality, frame_presenter.rb:1203)

- Location: `carat/adapters/frame_presenter.rb:1203`
- Why: find_pair bounds the search by window.top + window.height buffer lines, which under a closed fold is not the range the window shows: a partner drawn below a fold is never matched and hidden folded rows are scanned
- Fix: bound it by the last buffer row the window shows (the fold-aware bottom ArrangeView computes) and add a MatchParen row with a fold to test/adapters_frame_presenter.rb
- Also: test/adapters_frame_presenter.rb
- Category: editor
- Added: 2026-11-19

### The message row still shows the visual mode indicators the pill already shows
- Location: carat/adapters/frame_presenter.rb, `paint_message`, the VISUAL, VISUAL_LINE, and VISUAL_BLOCK branches; openspec/specs/visual-mode/spec.md, the requirement of the message row's visual indicator
- Why: the brief drops `-- INSERT --` because the status bar's pill shows the mode; `-- VISUAL --`, `-- VISUAL LINE --`, and `-- VISUAL BLOCK --` repeat the pill the same way and stay unstyled in `Normal`, so the row is inconsistent between insert and visual mode.
- Fix: drop the three branches, change the visual-mode and screen-rendering requirements and the tests of editor_visual and adapters_frame_presenter (the keys of a pending count stay at the right edge), or paint them in `ModeMsg` if they are kept.
- Also: openspec/specs/visual-mode/spec.md
- Category: editor
- Added: 2026-11-20

### carat/adapters/frame_presenter.rb:1203: find_pair bounds the MatchParen search by window.top + window.height (sprint-22 sweep quality)

- Location: `carat/adapters/frame_presenter.rb:1203`
- Why: find_pair bounds the MatchParen search by window.top + window.height, not window.shown_end as HighlightView does (highlight_view.rb:69), so with a closed fold a partner shown below the fold is not matched and one hidden inside the fold is
- Fix: bound by window.shown_end and pass over rows inside closed folds
- Category: editor
- Added: 2026-11-20

### A token span on a float's selected row leaves a NormalFloat hole in the PmenuSel bar
- Location: carat/adapters/frame_presenter.rb:682 (paint_tokens on the float layer), carat/domain/themes.rb:657
- Why: a syntax or file-icon span on a plugin float's selected row is painted as its group on the float layer, whose background is NormalFloat's when the group has none of its own, so an icon or Comment span breaks the PmenuSel bar and loses PmenuSel's REVERSE in 16 colors; the picker's icons on its selected row will show it. Not fixed in picker-styles-b: it changes painting, new behavior beyond a fix round.
- Fix: on a menu's selected row give a token group without its own background the row's PmenuSel background (a selected-row layer or a background override in paint_tokens), with a test reading a Comment span's background on the selected row.
- Merged: ### A token span on a float's selected row breaks the PmenuSel bar (still present at the package head)
- Location: carat/adapters/frame_presenter.rb:682 (paint of a float's syntax and file-icon spans), carat/domain/themes.rb:657 (a float group without its own background takes NormalFloat's)
- Why: a syntax or file-icon span on a float's selected row is painted as its group on the float layer, so an icon or Comment span leaves a NormalFloat hole in the PmenuSel bar and loses PmenuSel's REVERSE in 16 colors; the spec's drawn-as-tokens wording allows it, but the picker's icons on its selected row will show it; raised by the quality review twice in this run (the fix round's entry above and again at the head), merged here as one finding
- Fix: on a menu's selected row give a token group without its own background the row's PmenuSel background (a selected-row layer or a background override in paint_tokens), with a test reading a Comment span's background on the selected row
- Also: carat/domain/themes.rb
- Category: editor
- Added: 2026-11-20

### The frame presenter's guide local packs the marks bit (sprint-24 review quality)

- Location: `carat/adapters/frame_presenter.rb:872`, `:900`, `:907`, `:917`
- Why: the local named guide now holds `(key * 2) + mark`, the repaint input passed to PaintedRows, so its name misleads.
- Fix: rename it to `repaint_key` wherever it is passed.
- Category: editor
- Added: 2026-11-21

### 1469 lines and 60 methods paint windows, headers, winbars at carat/adapters/frame_presenter.rb:1 (sprint-26 sweep quality, note 35)

- Location: carat/adapters/frame_presenter.rb:1
- Why: 1469 lines and 60 methods paint windows, headers, winbars, separators, floats and their borders, notifications, the message row, diagnostics, and the bracket pair in one class
- Fix: extract float and notification painting into collaborators as StatusBar, Winbar, and TabBar were, keeping the hot window path explicit
- Category: editor
- Added: 2026-11-22

### The float key's layout is read in two classes at carat/adapters/frame_presenter.rb
- Location: `carat/adapters/frame_presenter.rb` `forget_rows`, `compare_boxes`, `covers?` (walking by `FloatPainter::STRIDE`), and `carat/adapters/float_painter.rb` `build_float_key`, `add_notice_boxes`.
- Why: the presenter reads the box rows and columns at offsets 0 to 3 of each `STRIDE` group the float painter writes, so a change of the key's layout must be made in both files.
- Fix: give `FloatPainter` the box queries over a key (`covers?`, and a row range per box the presenter iterates for `forget_rows` and `compare_boxes`), so only it knows the offsets.
- Also: carat/adapters/float_painter.rb
- Category: editor
- Added: 2026-11-22

### float_key is read before build_key fills it at carat/adapters/frame_presenter.rb:246 (sprint-27 review quality, note 6)

- Location: carat/adapters/frame_presenter.rb:246
- Why: float_key = @float_painter.key is taken before @float_painter.build_key refills it; it works only because FloatPainter#key is one array cleared and refilled in place, and it reads like a stale copy.
- Fix: read the key after build_key, or say in a comment that it is the painter's live array.
- Category: editor
- Added: 2026-11-22

### The bottom panel is not on the darker surface
- Location: `carat/adapters/frame_presenter.rb`, `paint_window` (the sidebar layer is chosen by `window.fixed_width`, which the bottom panel's window does not set)
- Why: `docs/design.md` section 1 lists the panels (row 0, sidebars, the bottom panel) as one surface level behind the status bar; the panel still draws on `Normal` with a separator row above it, so only the sidebars follow the Edges-by-background rule.
- Fix: give the panel window the sidebar layer (a `Window#fixed_height` test beside `fixed_width`), draw no row of `─` where the panel meets the editor unless `plain` or `basic_colors`, and extend the two screen-rendering scenarios.
none
- Also: docs/design.md
- Category: editor
- Added: 2026-11-22

### Two comments overflow the wrap width at carat/adapters/frame_presenter.rb:45 (sprint-29 review quality)

- Location: carat/adapters/frame_presenter.rb:45 (91 columns), carat/adapters/float_painter.rb:263 (82 columns)
- Why: window-surfaces' comment edits left lines past the files' 72 to 75 column wrap, as the entry "Four comments of bars break their file's wrap width" records for other files.
- Fix: rewrap both paragraphs.
- Also: carat/adapters/float_painter.rb
- Category: editor
- Added: 2026-11-22

### Match highlighting still walks the matches left of the horizontal scroll
- Location: carat/adapters/frame_presenter.rb, paint_matches (the walk starts at code point 0 of the row).
- Why: each match left of the scroll is an engine call charged to the frame's budget, so a long line scrolled far right spends the budget on matches nobody sees. Starting the walk at the scroll column instead changes which matches are found when matches overlap (the pattern aa on aaa), so the highlight would differ from Neovim's, which walks from the line start; the delivery fixed only the stale stamp of rows painted after the stop.
- Fix: keep the walk from 0 but skip the engine call chain left of the scroll when the pattern cannot match twice at overlapping offsets (a literal with no repeated prefix), or cache the match starts per decoded line in LineCache and read them per frame.
- Category: editor
- Added: 2026-11-23

### paint_row takes 17 positional parameters (paint_window at 571 takes at carat/adapters/frame_presenter.rb:817 (sprint-30 sweep quality, note 41)

- Location: carat/adapters/frame_presenter.rb:817
- Why: paint_row takes 17 positional parameters (paint_window at 571 takes 10), grown by #318 when three instance variables became arguments, so a call site is read by counting
- Fix: group the per-row inputs (row, current, number_hl, number, sign, sign_group) in a small reused record or keep them as presenter state set once per window
- Category: editor
- Added: 2026-11-23

### FramePresenter repeats Slot#headed?'s left-sidebar rule at carat/adapters/frame_presenter.rb:765 (sprint-31 review quality)
- Location: carat/adapters/frame_presenter.rb:765, carat/domain/slot.rb:78
- Why: paint_header tests `slot.side == :left && slot.views.length < 2` itself while ArrangeView reserves the row by Slot#headed?, so the rule lives in two places and a change to one (the right sidebar's head, surface-edges-fix's finding) leaves a header row painted that was never reserved, or the reverse.
- Fix: one Slot predicate for "headed by the project" that both read, with the slot test holding its cases.
- Also: carat/domain/slot.rb
- Category: editor
- Added: 2026-11-23

### FramePresenter reads the branch through the status bar at carat/adapters/frame_presenter.rb:715 (sprint-31 review quality)
- Location: carat/adapters/frame_presenter.rb:715 and :766 (`@status_bar.slots.branch`)
- Why: the tab row's head takes the branch from another adapter's internals, so the head depends on StatusBar keeping its slots public and on the status bar being built first.
- Fix: give the presenter the StatusSlots it shares, or pass the branch in, so neither bar reaches into the other.
- Category: editor
- Added: 2026-11-23

### The current row's icon loses its file-type color
- Location: `carat/adapters/frame_presenter.rb` (`paint_marked_row`)
- Why: the fill puts the whole row in `PmenuSel`, so the icon cell is drawn in the selection group, not its `DevIcon` group; a cell holds one group and no selection layer exists.
- Fix: a selection layer beside the cursor-line and sidebar layers in `Highlight` and `Themes.from_palette`, so any group keeps its foreground over the selection background.
- Category: editor
- Added: 2026-11-24

### The current row's label is not bold
- Location: `carat/adapters/frame_presenter.rb` (`paint_marked_row`)
- Why: `docs/design.md` section 5 gives a selected row a bold label; only the fill and the bar are drawn.
- Fix: also fill the cells after the icon with `PmenuLabelSel`, or fold it into the `one-accent` change that unifies the four selection marks.
- Also: docs/design.md
- Category: editor
- Added: 2026-11-24

### public display_col and display_width wrap Domain::DisplayWidth, used only at line at carat/adapters/frame_presenter.rb:334 (sprint-32 sweep quality, note 41)
- Location: carat/adapters/frame_presenter.rb:334
- Why: public display_col and display_width wrap Domain::DisplayWidth, used only at line 517 and by test/adapters_frame_presenter.rb:599
- Fix: make them private (or inline) and have the test call Domain::DisplayWidth.column
- Category: quality

### The marked-row test repeats the mark test beside it at carat/adapters/frame_presenter.rb:642 (sprint-32 review quality)
- Location: carat/adapters/frame_presenter.rb:639 (@mark_here) and :642 (here)
- Why: both test row < count && fold < 0 on adjacent lines, so a change to which rows draw marks can leave the marked row's rule behind.
- Fix: one local for a shown, unfolded row both read.
- Category: quality
