# Proposal

## Why

In the reading view (`<leader>dr`) an indented code block inside a quote (`>     x = 1`, `>     y = 2`) flows into one quote row and loses its line breaks: the four-space check of `MarkdownText.flow_key` counts only the spaces before the quote markers. `flow_key`, `marker_end`, and `block` each scan a line's spaces and `>` markers their own way, so a joined line can be cut at another byte than the block that classified it, and `flow_key` keeps an indent cap that can never run. The user's reading-view request names four parts; this change takes two of them, headings and framed code blocks: fenced code still reads as two-space indented rows with nothing around them. It folds three backlog entries: "MarkdownText flow_key copies block's scan and keeps a dead indent cap", "An indented code block inside a quote still flows into one quote row", and "marker_end can disagree with the quote-marker scans of flow_key and block".

## What Changes

- Read a line's leading spaces and quote markers in one scan (`MarkdownText.markers`) that `flow_key`, `marker_end`, and `block` all use, so all three cut a line at the same byte; the content's indentation is counted after the last marker, less the one space the marker takes, and spaces before or between markers only place the markers.
- Keep an indented code line inside a quote (four or more spaces after the marker's own space) its own row behind its bars, as an indented code line outside a quote already is.
- Drop `flow_key`'s dead indent cap: a flowing line's indentation is below four spaces, so its key is `depth * 2 + indent / 2`.
- Draw a fenced code block in the reading view in a frame from the icon set (box-drawing under `unicode` and `nerd`, `+`, `-`, `|` under `ascii`), as wide as its widest line up to the measure, a longer line continued on the next framed row; its text keeps `@markup.raw.block` and the fence language's tokens. The documentation floats keep their two-space indented code.
- Prove that a heading in the reading view reads as its text alone in `@markup.heading`, which it already does.

Out of scope: rules and list gaps, the user's other two reading-view parts (`markdown-reading-e`); frames in the documentation floats (hover and completion), whose spec keeps code indented by two columns; heading underlines or level-dependent heading styles, which the request does not name.

Roadmap: outside the roadmap order of `docs/architecture.md` section 12; it extends the delivered reading view at the user's request.

Assumptions: "headings drawn" is met by the existing heading span, which the reading view already draws in `@markup.heading`, so the heading part adds a test row and no new drawing; a quote line indented one to three spaces before its first `>` now reads as a plain quote (CommonMark), where it read one indentation level deeper; a quoted line with two or three spaces after its marker reads one indentation level in, as an unquoted line with two or three leading spaces does; a blank line inside a fenced block is a blank framed row; a frame needs five columns, so a narrower measure keeps the indented code; the allocations held are those `make bench SCENARIOS="lh j insert"` measures, which no markdown runs in.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `markdown-reading`: fenced code framed in the reading view, its heading and code each in its style, and an indented code line inside a quote kept on its own row.

## Impact

`carat/domain/markdown_text.rb` (the one marker scan, the frame drawn by `wrap`), `carat/use_cases/docs/format_docs.rb` and its callers `show_hover.rb`, `show_completion_docs.rb`, `toggle_reading.rb` (whether code is framed); tests in `test/domain_markdown_text.rb` and `test/use_cases_toggle_reading.rb`; `docs/codebase-map.md`; README. No dependency, port, action, binding, or file is added.

- README.md: changed, the reading view frames fenced code.
- docs/architecture.md: unchanged, its layers, ports, and docs use cases are as they were; the change adds no file, port, or action.
