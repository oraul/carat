# Backlog: carat/use_cases/plugins/plugin_syntax.rb

### A filetype plugin activated while highlighting is arranged and delivered only on the next key (plugin-lazy-activate quality)
- Location: carat/use_cases/plugins/plugin_syntax.rb:48, carat/use_cases/docs/format_docs.rb:56
- Why: a filetype trigger activates the plugin from HighlightView inside EditorAssembly#render, after ArrangeView and outside any PluginHost flush, so windows, a segment, or events the plugin's activate causes are neither arranged nor delivered until the next key; FormatDocs also activates it from hover docs, a trigger the plugin-host spec ("a buffer of its filetype is highlighted") does not name.
- Fix: activate filetype providers in PluginHost#resized, before arrange and then flush, for the visible buffers' syntaxes, and keep the provider a pure lookup.
- Also: carat/use_cases/docs/format_docs.rb
- Category: plugins
- Added: 2026-11-18

### A tokenizer's token length reaches the painter uncut
- Location: carat/use_cases/plugins/plugin_syntax.rb `copied_tokens` and carat/adapters/frame_presenter.rb `paint_tokens`
- Why: `copied_tokens` keeps any length of 1 or more, and `paint_tokens` adds it to the start column before cutting at the line's size, so a plugin token with a length near the integer limit makes that sum overflow if Spinel's integers are fixed width; `style_float` cuts its span lengths to `LONGEST_SPAN` for this reason, the tokenizer path does not.
- Fix: cut the length in `copied_tokens` (or compare `from + length` as `length > size - from` in `paint_tokens`), with a test of a token whose length is 1 << 40.
- Also: carat/adapters/frame_presenter.rb
- Category: plugins
- Added: 2026-11-20

### The span bound and clamp are written twice at carat/use_cases/plugins/plugin_syntax.rb:82 (sprint-30 review quality)

- Location: carat/use_cases/plugins/plugin_syntax.rb:82, :84; carat/use_cases/plugins/window_requests.rb:422, :460
- Why: plugin-host-lows bounded a span's start by Domain::SyntaxLine::LONGEST_SPAN and cut its length to it in both request paths by copying the same two expressions, so a change to the bound must land in four places.
- Fix: one SyntaxLine helper (a start test and a cut length) both files call; accepted when the existing plugin syntax and style_float rows pass unchanged.
- Also: carat/use_cases/plugins/window_requests.rb
- Category: plugins
- Added: 2026-11-23
