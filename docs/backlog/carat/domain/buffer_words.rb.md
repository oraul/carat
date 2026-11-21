# Backlog: carat/domain/buffer_words.rb

## BufferWords repeats the menu's cap and exposes more than it needs

- Where: `carat/domain/buffer_words.rb` at eb0b1ae: `LIMIT = 200` (line 24) repeats `CompletionList::LIMIT`; `done?` (line 52) is public though only `BufferWords` calls it; `collect` (line 38) on a `Struct` subclass shadows `Enumerable#collect`, which `Struct` includes, with an unrelated signature. Quality advisories in `word-completion`.
- Why it matters: the two caps can drift so the scan keeps more or fewer words than the menu shows; the public `done?` widens the surface the backlog already trims; a reader expecting `Enumerable#collect` meets a different method, and a later caller of the block form gets the wrong one.
- Fix outline: use `CompletionList::LIMIT` in `done?` and `scan_line` and drop the constant; move `done?` under `private` and drop it from its map entry; rename `collect` (for example `gather` or `scan_from`) in `CompleteWord` and the map. Queued in `completion-tidy`.
- Category: editor
- Added: 2026-11-10

## BufferWords slices every match before the duplicate check

- Where: `take` in `carat/domain/buffer_words.rb` line 133 at eb0b1ae. Quality advisory in `word-completion`.
- Why it matters: the byteslice of every match is allocated before it is compared with the kept words, so an empty prefix over a large buffer allocates one string per word occurrence up to the byte bound, though few of them are new.
- Fix outline: compare the candidate's bytes against the kept words before slicing, or bound the duplicate case, with a benchmark row for Ctrl-N on an empty prefix over a large buffer. Queued in `completion-tidy`.
- Category: editor
- Added: 2026-11-10

## Keyword completion skips the word right after the cursor on an empty prefix

- Where: `carat/domain/buffer_words.rb` line 64 at 8f486e0, where the scan of the cursor's line starts at `start + 1` and the final `0...start` slice ends before `start`. Quality advisory in `word-completion`.
- Why it matters: with no word before the cursor, the word starting at the cursor column is never offered from that spot, though the completion spec says every word matches with an empty prefix.
- Fix outline: scan from `start` rather than `start + 1` when the prefix is empty (or narrow the spec wording to match Neovim), with a table row for a cursor placed before a word. Queued in `completion-tidy`.
- Category: editor
- Added: 2026-11-10

## Ctrl-N and Ctrl-P scan unlisted buffers

- Where: `carat/domain/buffer_words.rb:45` skips only scratch buffers, against its class comment (line 11). Periodic quality advisory at d0d783c.
- Why it matters: Neovim's 'complete' `b` scans only listed buffers; words from buffers a jump left unlisted leak into completion.
- Fix outline: skip buffers that are not listed, with a `test/editor_word_completion.rb` row after a replace jump. Queue item `buffer-list-tidy`.
- Also: test/editor_word_completion.rb
- Category: editor
- Added: 2026-11-11
