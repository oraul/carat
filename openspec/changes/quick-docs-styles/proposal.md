# Proposal

## Why

The hover and completion documentation floats, and the `[docs]` split the pin key opens, show their markdown as uncolored rows: a heading, a strong word, a code span, a link, and a fenced block all look like the paragraph around them, so the shape of the documentation is lost once its markers are taken out. This is queue item 1, a T5 user request.

## What Changes

- Add six markup highlight groups with Neovim's tree-sitter names, `@markup.heading`, `@markup.strong`, `@markup.italic`, `@markup.raw`, `@markup.link.label`, and `@markup.raw.block`, colored by every shipped palette.
- Change the markdown reader to keep, beside each row's text, the span of each heading, strong and italic run, code span, link text, and fenced code row, wrapped with the rows, and the language a fence names.
- Add a float layer of group ids, each group drawn over NormalFloat's background unless it has its own, so a styled cell keeps the float's background; the contrast test holds every syntax and markup group to 4.5:1 on it, at 24 bits and at 256 colors, in every palette.
- Highlight fenced code whose fence names a language through the plugin tokenizer that declares it, as a buffer of that filetype is highlighted, unless `:syntax off`.
- Draw the styles in the hover and completion documentation floats and keep them in the pinned `[docs]` split; draw none under `NO_COLOR`.
- Record the plan's bookkeeping: the twelve planned backlog entries, the stale `NO_COLOR` entry rewritten to name what honours it now, and the diagnostics URI entry's location updated.

Out of scope: the signature float, which shows the server's one-line label with its active parameter marked and no markdown (it keeps that look); styling block quotes, bullets, and rules; the markdown preview plugin (queue item `markdown-preview`); user-defined group colors.

Roadmap: outside the roadmap order of `docs/architecture.md` section 12; it extends the delivered quick-docs and completion-docs features at the user's request.

Assumptions: a fence's language is the first word of its info string, matched as written against the filetypes the plugins declare (`ruby`); an unknown language shows the code in `@markup.raw.block` only. Emphasis and code spans inside link text keep the link group only. A heading's inline runs are drawn over the heading group. Editing a pinned `[docs]` row drops that row's styles, as the styles belong to the row's text.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `hover-docs`: the documentation float and the pinned split draw headings, emphasis, code spans, link text, and fenced code in their own groups, fenced code through the syntax highlighter, and plain under `NO_COLOR`.
- `completion`: the documentation beside the popup is styled the same way.
- `color-themes`: the markup groups exist in every palette, and syntax and markup groups drawn in a float meet 4.5:1 over the float's background.

## Impact

`carat/domain/markdown_text.rb`, a new `carat/domain/docs_text.rb`, `carat/domain/highlight.rb`, `carat/domain/themes.rb`, `carat/domain/buffer.rb`, a new `carat/use_cases/docs/format_docs.rb`, `ShowHover`, `ShowCompletionDocs`, `PinHover`, `EditorAssembly`, and `FramePresenter`; tests in `test/domain_markdown_text.rb`, `test/domain_theme.rb`, `test/adapters_hover.rb`, and `test/editor_completion.rb`. No dependency is added; with no float shown a key allocates nothing more.
