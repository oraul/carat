# Design

## Context

`Domain::MarkdownText.parse(text)` reads documentation into a `DocsText` (rows, spans, fence languages) with at most `RAW_LIMIT` (16,384) bytes read and `ROW_LIMIT` (100) rows kept, and `wrap(doc, width)` wraps it with its spans. `UseCases::FormatDocs#call(state, text, width)` parses, tokenizes fenced code through `PluginSyntax`, and wraps; `ShowHover` and `ShowCompletionDocs` put the rows and styles in a float buffer, `PinHover` copies them into a scratch split loaded with `BufferList#load`. A scratch buffer shows no line numbers, and `FramePresenter#paint_window` draws a styled buffer's `style_at` spans when no syntax cache is active, so a layout window already draws documentation rows with their styles. The bullet, bar, and rule are the constants `BULLET`, `BAR`, and `RULE`, whatever `option.icons`; `prefix_size` compares a row's start against the first two. `MarkdownText.rows` is called only by `test/domain_markdown_text.rb`.

## Goals / Non-Goals

**Goals:** a bound toggle showing a Markdown file as reading text in its window and back; the markers within the icon set everywhere the reader draws them; a bounded view; the reader's comment current and its surface reduced to what the program calls.

**Non-Goals:** a live view following edits or resizes; a Markdown filetype or tokenizer; a new rendering path in the presenter.

## Decisions

### 1. The reading view is a scratch buffer, not a presenter mode

`UseCases::ToggleReading` (`use_cases/docs/`) builds the view once per press: the source buffer's lines joined with `"\n"`, formatted by `FormatDocs` at the measure (the window's width capped at `MEASURE`, 80), shown with `BufferList#load` in a scratch buffer owned by `OWNER` (`"reading"`) and titled `[reading] PATH`, its `styles` set from the formatted rows. The presenter, the status bar, the cursor motions, scrolling, and search all work on it unchanged, and `load` releases it when the window leaves it, so nothing accumulates. Pressed in the reading view (owner `OWNER`), it takes the source path from the title and loads `BufferList#for_path(path)`, whose cursor `load` restores. Alternative: a per-window flag that makes `paint_window` draw reading rows instead of buffer lines; rejected because the cursor, motions, scrolling, and search would each need a mapping between the two row sets, and every frame would pay a branch for a rare view.

### 2. The reader takes the icon set and its caps as arguments

`parse(text, set, raw_limit, row_limit)` and `wrap(doc, width, set, row_limit)` replace the one-argument forms. `bullet(set)`, `bar(set)`, and `rule(set)` answer `ASCII_BULLET` (`"* "`), `ASCII_BAR` (`"| "`), and `ASCII_RULE` (twenty `-`) for `"ascii"` and the existing constants for any other set, as `Icons.table` maps an unknown set to unicode; `prefix_size(row, set)` compares against the set's bullet and bar. `FormatDocs#call(state, text, width, reading)` passes `state.options.icons` and the docs caps (`RAW_LIMIT`, `ROW_LIMIT`) or the reading caps (`READING_RAW_LIMIT`, 262,144 bytes, and `READING_ROW_LIMIT`, 10,000 rows) by `reading`, so ShowHover and ShowCompletionDocs pass `false` and ToggleReading `true`. Arguments rather than a module-level setting, because the domain holds no state and Spinel pins each parameter's type. Alternative: read the glyphs from `Icons.glyph`; rejected because the table's `markdown` name is the file-type icon and the three markers are layout, not icons a plugin asks for by name.

### 3. The caps bound the work of one press

The reading caps are sixteen times the docs caps in bytes and a hundred times in rows: a README of a few hundred lines fits, and a megabyte file costs one pass over 256 KiB and at most 10,000 row strings, once per press. The view is cut silently at the cap, as the floats are.

### 4. `rows` leaves; the test reads as the program does

The test's `rows` helper becomes `MarkdownText.wrap(MarkdownText.parse(text, set, RAW_LIMIT, ROW_LIMIT), 40, set, ROW_LIMIT).texts`, so every existing expectation holds unchanged under `unicode`, and an `ascii` table proves the plain markers.

## Risks / Trade-offs

- [A large Markdown file makes one press slow] → bounded by the reading caps; nothing runs per key otherwise.
- [A text line starting with `* ` or `| ` under ascii is taken as a prefix when it wraps] → only the wrap point moves (the prefix is not counted as text), the text is unchanged.
- [The source closed while the reading view shows] → the toggle refuses with `The Markdown file is closed` and the view stays.
