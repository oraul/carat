# Backlog: carat/use_cases/discovery/follow_palette.rb

### carat/use_cases/discovery/follow_palette.rb:177 styles re-derives the palette row layout

Duplication: styles re-derives the layout rows already built (room at 159 and 180, the name cut again, the description column's start from the padding arithmetic). Fix: build each row's tokens in the rows loop from the cells it just padded, or share one column helper.
- Category: editor
- Added: 2026-11-14

### carat/use_cases/discovery/follow_palette.rb:235 private code point count in a use case

Duplication: char_count re-implements the code point count Domain::MarkdownText.char_count and Domain::Utf8.size_at already give, in a use case. Fix: add a prefix count to Domain::Utf8 (or call MarkdownText.char_count on the byteslice) and drop the private copy.
- Category: editor
- Added: 2026-11-14

### carat/use_cases/discovery/follow_palette.rb:193 ex command colon skip in mark untested

Test gap: the skip path of mark for an ex command's leading colon (a match on :write, offset by one character) has no test. Fix: add an editor_palette case typing an ex name and checking the marked cells start after the colon.
- Category: editor
- Added: 2026-11-14

### carat/use_cases/discovery/follow_palette.rb:94 score and field repeat one comparison

Simplicity: score and field each repeat the a >= b comparison. Fix: one if a >= b branch setting both.
- Category: editor
- Added: 2026-11-14

## Palette tokens shift on a description that is not UTF-8

- Where: `char_count` in `carat/use_cases/discovery/follow_palette.rb:240`. Sprint-3 quality review.
- Why it matters: `char_count` counts every byte that is not a continuation byte, while the frame decodes token columns with `Utf8`, which counts a lone continuation byte or a broken sequence as one replacement character each, so a plugin description holding such bytes shifts its `PmenuMatch` and `PmenuExtra` tokens by one or more columns.
- Fix outline: count characters the way the decoder does (one shared count beside `Utf8.size_at`), with a palette test whose description is not UTF-8. Queue item `palette-tidy`.
- Category: editor
- Added: 2026-11-14

### FollowPalette#pad keeps a ternary ljust makes unneeded (sprint-13 quality)
- Location: carat/use_cases/discovery/follow_palette.rb:306.
- Why: ljust returns a copy when the width is not larger than the length (sp_str_ljust returns sp_str_dup), so the ternary adds nothing.
- Fix: cell.ljust(cell.length + width - used). Queue item `ui-code-tidy`.
- Category: editor
- Added: 2026-11-17

### The palette's PmenuExtra token may give an end column as its length
- Location: carat/use_cases/discovery/follow_palette.rb `styles`, the `tokens << char_count(line, Domain::DisplayWidth.bytes_within(line, room + NAME_WIDTH))` line
- Why: a `SyntaxLine` token is (start column, length, group), but this pushes the column where the name's column ends, so the run reaches past the name into the key column, which would then draw in PmenuExtra; no test reads a key cell's group.
- Fix: push that end column less `from` as the length, and add a palette test reading a key cell's group.
- Category: editor
- Added: 2026-11-20

### styles pushes the name column end, char_count(line, bytes_within(line, room at carat/use_cases/discovery/follow_palette.rb:212 (sprint-26 sweep quality, note 15)

- Location: carat/use_cases/discovery/follow_palette.rb:212
- Why: styles pushes the name column end, char_count(line, bytes_within(line, room + NAME_WIDTH)), as the token length, but SyntaxLine tokens are (start, length, group) triples, so the PmenuExtra run starts at the name column and runs room further, over the key column, against the comment that it ends at the key; test/editor_palette.rb checks only name and description cells
- Fix: push that end minus from, and add a test that the key column keeps Pmenu or PmenuSel
- Also: test/editor_palette.rb
- Category: editor
- Added: 2026-11-22

### char_count re-implements the count of UTF-8 lead bytes that at carat/use_cases/discovery/follow_palette.rb:274 (sprint-26 sweep quality, note 16)

- Location: carat/use_cases/discovery/follow_palette.rb:274
- Why: char_count re-implements the count of UTF-8 lead bytes that json_rpc_language_gateway.rb:1175 and visit_target.rb:210 also hand-roll
- Fix: one Utf8.char_count(text, bytes) in carat/domain/utf8.rb used by all three
- Also: carat/domain/utf8.rb
- Category: editor
- Added: 2026-11-22
- Merged: ### carat/use_cases/discovery/follow_palette.rb:274: duplication: char_count re-implements the UTF-8 character count of a (sprint-22 sweep quality)
- Location: `carat/use_cases/discovery/follow_palette.rb:274`
- Why: duplication: char_count re-implements the UTF-8 character count of a byte prefix that Domain::Utf8 should own (also open-coded in json_rpc_language_gateway.rb:1175 and visit_target.rb:210)
- Fix: a Utf8 module function used by all three
