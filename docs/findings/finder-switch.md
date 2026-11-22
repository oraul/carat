### Space f w takes no word to the right of a blank cursor
- Location: carat/plugins/finder/plugin.rb `word_under_cursor`, carat/plugins/finder/matcher.rb `word_at`.
- Why: Neovim's cword takes the next word to the right on the line when the cursor is on a blank; the queue entry asks for the empty grep on a blank, so this change opens it empty, which differs from Neovim for a user who expects the nearest word.
- Fix: when word_at finds no word at the column, scan right on the same line for the first keyword byte and return its run; add a table row and a spec scenario, and change the compatibility row.

### word_at counts every non-ASCII character as a word character
- Location: carat/plugins/finder/matcher.rb `word_byte?` (bytes of 0x80 or more), used by `word_at`.
- Why: a typographic quote, a non-breaking space, or CJK punctuation next to a word joins it, so Space f w can put the punctuation on the prompt; the grep picker's whole-word match shares the rule, so changing one alone would make them disagree.
- Fix: classify code points by Unicode letter and number classes through a table in Matcher for both word_at and the whole-word match, with rows for each class.

### docs/architecture.md stood over its docs-lint budget on main
- Location: docs/architecture.md, the configuration section's trust bullet and the line-check bullet; tools/docs_lint.sh BUDGETS.
- Why: the merge of the project-file trust fix left the file 8 bytes over its 88064-byte budget, so make docs-lint, a stage of the check, failed for every later change; this change trimmed 9 bytes of wording to get under it.
- Fix: keep the file under budget by trimming wording at the change that grows it, and have the merge gate run docs-lint on the pull request's head so a budget overrun fails before the merge.
