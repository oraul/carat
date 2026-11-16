# Proposal

## Why

No key shows a Markdown buffer as readable text: a README is read through its raw markers (`#`, `-`, `>`, backticks), at whatever width the window has. The markdown reader that lays out documentation for the hover and completion floats draws its bullet, quote bar, and rule as `•`, `│`, and `─` whatever `option.icons` says, although the README promises that `ascii` draws plain characters so the whole screen is ASCII. Its module comment still says it makes plain rows and omits the spans `parse` keeps, and `MarkdownText.rows` is public surface only a test calls. This is sprint 9's first item, a T2 user now-request, part a.

## What Changes

- Add the `docs.toggle_reading` action, bound to `<leader>dr` in normal mode: in a window showing a Markdown file (`.md` or `.markdown`) it shows the file as reading text in a scratch buffer titled `[reading] PATH`, at a measure of at most 80 columns, headings, emphasis, code spans, links, and fenced code styled as the documentation floats style them, lists as bullets and quotes as bars; pressed again in the reading view it shows the file again with its cursor where it was. A buffer that is not Markdown is refused with a message.
- Change the markdown reader to draw its bullet, quote bar, and rule from the icon set: `ascii` draws `* `, `| `, and a rule of `-`; `unicode` and `nerd` keep `•`, `│`, and `─`. The hover and completion documentation floats follow the same set.
- Bound the reading view as the floats are bounded, with larger caps: at most 262,144 bytes of the file are read and at most 10,000 rows kept, escape sequences and controls dropped.
- Remove `MarkdownText.rows`; the test reads through `parse` and `wrap` as the program does. Bring the module comment current: rows with their spans, the icon set, the two sets of caps.
- Document the action in `docs/actions.md`, the binding in `config/default.caratrc` and its generated mirror, the feature in the README, and the files in the map.

Out of scope: rewrapping the reading view when its window is resized (toggle twice to rewrap); following edits made to the file while the reading view shows (toggle again to refresh); a Markdown filetype or tokenizer for buffers; tables, numbered-list renumbering, and images beyond their text; part b of the item (`markdown-reading-b`), queued separately.

Roadmap: outside the roadmap order of `docs/architecture.md` section 12; it extends the delivered hover-docs feature at the user's request.

Assumptions: a buffer is Markdown when its path ends in `.md` or `.markdown`, in any case; the reading view is a scratch buffer, so it shows no line numbers, is not written, and leaves the buffer list when no window shows it; the measure is the window's width capped at 80 columns, as the hover float caps its width at 80; a document over the caps is cut silently at the cap, as the floats cut theirs; the source is found again by its path, and a source closed meanwhile is refused with a message.

## Capabilities

### New Capabilities

- `markdown-reading`: the reading toggle of a Markdown buffer, its view within the icon set, and its bounds.

### Modified Capabilities

- `hover-docs`: the documentation float's bullet, quote bar, and rule follow the icon set.

## Impact

`carat/domain/markdown_text.rb`, `carat/use_cases/docs/format_docs.rb`, `ShowHover`, `ShowCompletionDocs`, a new `carat/use_cases/docs/toggle_reading.rb`, `DocsHandler`, `EditorAssembly`, `carat.rb`, `config/default.caratrc` and `carat/domain/default_config.rb`; tests in `test/domain_markdown_text.rb` and a new `test/use_cases_toggle_reading.rb`. No dependency is added; nothing runs per key unless the toggle is pressed.

- README.md: changed, the reading toggle and the ascii glyphs of the documentation.
- docs/architecture.md: unchanged, its layer rules and ports hold as they are (the toggle adds a use case and no port), the map places `ToggleReading`, and the file is 97 bytes short of room for another name on its docs use cases line.
