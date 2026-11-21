# Backlog: carat/domain/global_args.rb

## GlobalArgs restates the delimiter rules DelimitedPattern owns

- Where: the class comment of `GlobalArgs` in `carat/domain/global_args.rb` (line 5 at 76fa78b). Quality advisory of `buffer-global`.
- Why it matters: the comment restates the delimiter rules (any ASCII character but a letter, where the pattern ends) that `DelimitedPattern` now owns, so the prose can drift from the code as the two parsers could before.
- Fix outline: say the pattern and the command are read by `DelimitedPattern` and drop the restated rules; `SubstituteArgs` keeps only the characters it excludes before the call. Queued in `global-tidy`.
- Category: editor
- Added: 2026-11-05

### GlobalArgs.parse keeps a blank-only check no caller can reach
- Location: carat/domain/global_args.rb:33
- Why: the only caller passes ExCommand#literal, which already has its leading blanks removed, so a blank-only text never arrives and text.strip.empty? acts as text.empty?; the comment states a rule that no test covers. Left in place because removing it would change what a direct call of GlobalArgs.parse with " " returns.
- Fix: keep text.empty? and drop the blank-only clause from the comment, or add a test/domain_global.rb row for a blank-only text.
- Also: test/domain_global.rb
- Category: editor
- Added: 2026-11-18
