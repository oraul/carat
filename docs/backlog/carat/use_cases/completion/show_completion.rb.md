# Backlog: carat/use_cases/completion/show_completion.rb

## Scratch floats of plain lines are built seven ways

- Where: `carat/use_cases/completion/show_completion.rb` line 151, `carat/use_cases/completion/show_completion_docs.rb` line 106, `carat/use_cases/docs/show_hover.rb` line 86, `carat/use_cases/docs/show_signature.rb` line 66, `carat/use_cases/plugins/window_requests.rb` line 235, at c1b3a12 (periodic quality), and `carat/use_cases/discovery/show_key_hints.rb` line 137 and `carat/use_cases/discovery/follow_palette.rb` line 124 at d828abb (quality advisories in `discoverability`). Queued in `hover-tidy`.
- Why it matters: each builds the same buffer, owner, window, and float steps, so a change to an owned float must be made seven times.
- Fix outline: one alternate constructor of a float from lines, owner, and spec, used by the seven.
- Also: carat/use_cases/completion/show_completion_docs.rb, carat/use_cases/docs/show_hover.rb, carat/use_cases/docs/show_signature.rb, carat/use_cases/plugins/window_requests.rb, carat/use_cases/discovery/show_key_hints.rb, carat/use_cases/discovery/follow_palette.rb
- Category: ide
- Added: 2026-11-09

## Completion docs lag the word-completion change

- Where: the class comment of `carat/use_cases/completion/show_completion.rb` line 25 at eb0b1ae runs past the file's wrap width; the section 5.1 completion list of `docs/architecture.md` line 167 names `CompleteWord` but not the shared `OpenCompletionPopup`. Quality advisories in `word-completion`.
- Why it matters: the long line breaks the file's style, and a reader of section 5.1 cannot find the use case that opens the popup float both completion paths share.
- Fix outline: rewrap the paragraph, and add `OpenCompletionPopup` to the 5.1 list as the popup float `ShowCompletion` and `CompleteWord` share. Queued in `completion-tidy`.
- Also: docs/architecture.md
- Category: ide
- Added: 2026-11-10

## Typing after Ctrl-P selects the farthest match

- Where: `carat/use_cases/completion/show_completion.rb` line 98 at 8f486e0, which refilters the reversed word list of a Ctrl-P menu and selects row 0. Quality advisory in `word-completion`.
- Why it matters: the Ctrl-P popup selects the nearest match, but after one typed character the selection jumps to the farthest one.
- Fix outline: keep the last row selected when the menu was filled backward, through a direction flag on the menu set by `CompleteWord`, with a row for Ctrl-P followed by a typed character. Queued in `completion-tidy`.
- Category: ide
- Added: 2026-11-10
