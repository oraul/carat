# Design

## Context

`Domain::MarkdownText.rows` turns documentation into plain strings in one pass and wraps them; nothing of the markup survives it. `ShowHover` and `ShowCompletionDocs` put those rows in a `Buffer` inside a `FloatWindow`; `PinHover` copies them into a scratch split. `FramePresenter#paint_float_row` paints a float row through `paint_text` and fills it with one group per row; only window rows reach `paint_tokens`, which fills (start, length, group) triples in code point columns. `HighlightView` tokenizes layout leaves only. A group without a background of its own is drawn on the terminal's or the theme's background, so a token painted inside a float would cut a hole in NormalFloat's background. The cursor line already solves the same problem with a layer of ids (`CURSOR_LINE_LAYER`).

## Goals / Non-Goals

**Goals:** markup spans that survive wrapping; fenced code through the plugin tokenizers; one group table and one contrast test covering the float background; nothing more per key with no float shown.

**Non-Goals:** a markdown filetype or tokenizer for buffers; styling the signature label; per-heading-level groups.

## Decisions

### 1. The reader keeps spans in a DocsText record and wraps after

`MarkdownText.parse(text)` reads the document into a `Domain::DocsText` (a `Struct`): the logical rows, a flat list of (row, start, length, group) quads in code point columns, and per row the fence's language and block number (0 outside code). `MarkdownText.wrap(doc, width)` wraps each row as before and cuts its quads at the same character boundaries into a new `DocsText`. `rows(text, width)` is `wrap(parse(text), width).lines`, so the text the floats show is unchanged and the existing tests hold. Spans are counted in characters while the inline pass appends, which is the unit `paint_tokens` takes. Flat integer quads rather than an array per row, because Spinel pins `Array[Integer]` but not nested arrays (`docs/spinel-notes.md`, Signatures), and because a method filling an array returns it (the empty-literal append miscompilation). A heading span goes before the inline spans of its row, and a fenced row's `@markup.raw.block` span before its tokens, so later spans paint over earlier ones. Alternative: return styled rows from a second reader; rejected as two parsers to keep in step.

### 2. Fenced code is tokenized in a use case before wrapping

`UseCases::FormatDocs#call(state, text, width)` parses, then for each fenced row whose language an enabled plugin tokenizes (`PluginSyntax#provider`) and with `syntax_on`, tokenizes the row's code (without its two-space indent) from the state the previous row of the same block ended in, and adds the valid tokens shifted by two columns; a failing tokenizer is disabled by the guard and the block stays `@markup.raw.block`. Then it wraps. Tokenizing before the wrap gives the tokenizer whole source lines. The domain cannot call a plugin, so this sits in the use-case layer, built once in `EditorAssembly` and shared by `ShowHover` and `ShowCompletionDocs`. Alternative: tokenize floats in `HighlightView`; rejected because the rows of a float are not source lines once wrapped and the markup spans would still need the reader.

### 3. The buffer keeps its styles by line identity

`Buffer` gains `styles`, an `Array[untyped]` of `SyntaxLine` (empty by default) with a typed `style_at(row, line)` that answers the row's entry only when its text is the very string at that row, else `SyntaxLine::NONE`. An edit replaces the line string, so an edited or shifted row loses its styles rather than showing wrong ones. `PinHover` copies the float buffer's styles with its lines (the same strings). The paint path reads them where a cache has no tokens: `paint_float_row` paints the row's tokens on the float layer after the NormalFloat fill, and `paint_window` uses `style_at` only when the buffer's syntax cache is inactive and the buffer is styled. `FramePresenter#plain` (NO_COLOR) skips both. With no float shown and no styled buffer the added work per row is one `active?` and one `empty?`, no allocation. Alternative: fill the scratch buffer's `SyntaxCache`; rejected because `HighlightView` drops an inactive cache every frame and the cache's generations turn per frame.

### 4. A float layer of ids

`Highlight::FLOAT_LAYER = 2 * COUNT`, `LIMIT = 3 * COUNT`. `Themes.from_palette` fills each group's float id with its foreground (NormalFloat's when it has none), attributes, and, unless it has a background of its own, NormalFloat's background at every depth; `SgrTable` builds sequences up to `LIMIT` at start. `Highlight.base` strips either layer. The markup groups are ids 92 to 97, after the file-icon groups, so no existing id moves and `token?` covers them. The contrast test adds a table over the float layer for the syntax and markup groups at 4.5:1.

### 5. Group colors

Roles already held to 4.5:1 on the background are reused: heading BLUE bold (Title's), strong and italic FG with the attribute, code span STRING, link CYAN underlined, raw block DIM. Neovim links `@markup.raw` to Comment; a string color separates a code span from prose more clearly without italics.

## Risks / Trade-offs

- [A palette's syntax color fails 4.5:1 over its float background] → the float-layer contrast table fails in `make test`; the palette's role or FLOAT color is adjusted in this change.
- [More SGR sequences at start, 98 more strings] → built once; per-key allocations are unchanged, checked with `make bench` on `lh` and `lh-float`.
- [A long fenced line wraps mid-token] → tokens are cut at the same boundary as the text, so each piece keeps its colors.
