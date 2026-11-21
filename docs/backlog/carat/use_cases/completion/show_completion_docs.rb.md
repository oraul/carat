# Backlog: carat/use_cases/completion/show_completion_docs.rb

## ShowCompletionDocs recomputes the cursor's screen row

- Where: `carat/use_cases/completion/show_completion_docs.rb` line 88 at 925d759, which computes the row as `ShowCompletion#row_offset` does, and takes `below = popup.row > 0`, and line 102, which computes the column through `DisplayWidth.column` where `ArrangeView#place_floats` uses the line cache. Quality advisory in `completion-docs`, raised again at d46ecff. At c1b3a12 the cursor's screen row is recomputed at seven sites (periodic note at `carat/use_cases/completion/show_completion.rb` line 167), the hover and signature floats included.
- Why it matters: the two copies and the sign convention couple the documentation float to the popup's layout, so a change to one silently misplaces the other.
- Fix outline: derive the documentation float's vertical placement from the popup spec alone (row and height), or share one helper for the cursor's screen cell with `ArrangeView` and `ShowCompletion`. Queued in `completion-docs-tidy`.
- Also: carat/use_cases/completion/show_completion.rb
- Category: ide
- Added: 2026-11-07

## The documentation float's keep test and close are copied

- Where: the five-condition keep test in `carat/use_cases/completion/show_completion_docs.rb` line 66 reaching four `CompletionMenu` docs members, and `CloseCompletion#call` (`close_completion.rb` line 24) repeating `ShowCompletionDocs#close`, at b0dd342. Periodic quality. Queued in `completion-docs-tidy`.
- Why it matters: a change to when the float is kept or closed must be made in two places.
- Fix outline: one `CompletionMenu` question for the keep test and one owner of closing the docs float, the `floats.index_of` check kept at the call site.
- Category: ide
- Added: 2026-11-07

## The docs float repeats the completion popup's row arithmetic

- Where: `carat/use_cases/completion/show_completion_docs.rb` line 88 and `ShowCompletion#row_offset` in `show_completion.rb` line 167 at 847851d. Periodic quality. Queue item `completion-docs-tidy`.
- Why it matters: the unexplained 2 already in the backlog lives in two places.
- Fix outline: one domain helper for the cursor's screen row and the rows free below it, the 2 named.
- Category: ide
- Added: 2026-11-09

## The docs float lands under a shifted completion popup

- Where: `carat/use_cases/completion/show_completion_docs.rb:107`. Periodic quality.
- Why it matters: with the cursor near the right edge the docs float is partly hidden beneath the popup.
- Fix outline: clamp the popup box as `place` does before choosing the side, with a right-edge row in `test/editor_completion.rb`. Queue item `completion-docs-tidy`.
- Also: test/editor_completion.rb
- Category: ide
- Added: 2026-11-10

## Two comments are unwrapped or incomplete

- Where: `carat/use_cases/completion/show_completion_docs.rb:25` (119 columns); `carat/use_cases/files/save_all.rb:8` (omits E45 for a modified read-only buffer). Periodic quality.
- Why it matters: comment wraps and currency.
- Fix outline: rewrap the first, add the read-only case to the second. Backlog batches (comment wraps).
- Also: carat/use_cases/files/save_all.rb
- Category: ide
- Added: 2026-11-10
