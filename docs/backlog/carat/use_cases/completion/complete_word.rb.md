# Backlog: carat/use_cases/completion/complete_word.rb

## CompleteWord copies ShowCompletion's word-before-cursor step

- Where: `carat/use_cases/completion/complete_word.rb` line 47 at eb0b1ae (head, word start, prefix, column) against `ShowCompletion#refresh` in `carat/use_cases/completion/show_completion.rb` lines 74 to 77. Quality advisory in `word-completion`. Raised again at ce6abdb (`show_completion.rb:74`, `complete_word.rb:47`; periodic quality): one domain prefix helper for both.
- Why it matters: the two copies decide what the word before the cursor is; a fix to one (a multibyte boundary, a keyword character option) misses the other, and the keyword and server popups then disagree on the prefix.
- Fix outline: one domain step answering a small `Data` record of the prefix, its byte start, and its column, called by both use cases, with their existing rows unchanged. Queued in `completion-tidy`.
- Also: carat/use_cases/completion/show_completion.rb
- Category: ide
- Added: 2026-11-10
