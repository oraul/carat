### A tokenizer's token length reaches the painter uncut
- Location: carat/use_cases/plugins/plugin_syntax.rb `copied_tokens` and carat/adapters/frame_presenter.rb `paint_tokens`
- Why: `copied_tokens` keeps any length of 1 or more, and `paint_tokens` adds it to the start column before cutting at the line's size, so a plugin token with a length near the integer limit makes that sum overflow if Spinel's integers are fixed width; `style_float` cuts its span lengths to `LONGEST_SPAN` for this reason, the tokenizer path does not.
- Fix: cut the length in `copied_tokens` (or compare `from + length` as `length > size - from` in `paint_tokens`), with a test of a token whose length is 1 << 40.

### The palette's PmenuExtra token may give an end column as its length
- Location: carat/use_cases/discovery/follow_palette.rb `styles`, the `tokens << char_count(line, Domain::DisplayWidth.bytes_within(line, room + NAME_WIDTH))` line
- Why: a `SyntaxLine` token is (start column, length, group), but this pushes the column where the name's column ends, so the run reaches past the name into the key column, which would then draw in PmenuExtra; no test reads a key cell's group.
- Fix: push that end column less `from` as the length, and add a palette test reading a key cell's group.
