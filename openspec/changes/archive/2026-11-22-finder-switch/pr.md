feat(finder): switch pickers with Ctrl-G and grep the word under the cursor

## Summary

Adds Ctrl-G in the finder prompt to switch between the file finder and the grep picker keeping the typed query, and Space f w to grep the word under the cursor. Moving between files and grep lost the query, and grepping the word under the cursor, the commonest grep, needed it typed again. Both use the existing `live_prompt`, `close_prompt`, and `read_buffer` requests, so the plugin API and its version stay.

---

## Changes

- Add the `plugin.finder.switch` action on Ctrl-G in the finder prompt keys: it opens the file picker from the grep picker, or the grep picker from the file, buffer, or recent picker, with the typed text on the prompt and the list filtered by it.
- Add the `plugin.finder.word` action on Space f w in normal mode: it opens the grep picker with the word under the cursor, or the empty prompt on a blank, an empty line, or an empty buffer.
- Add `Matcher.word_at` and `keyword_byte?` in the finder matcher, reading the word at a code point column across letters, digits, underscores, and multi-byte characters.
- Add tests in `test/editor_finder.rb` and `test/plugins_finder_matcher.rb` for switching both ways keeping the query, the empty prompt, resume after a switch, and the word rows including multi-byte and non-UTF-8 text, each delta spec scenario named beside its test.
- Add the file-finder requirements to the main spec through the archived change, and document both actions in `docs/actions.md`, `docs/compatibility.md`, `docs/plugins.md`, the code map, and the README.
- Trim a few words of `docs/architecture.md` to keep it within its docs-lint budget.
- Record the plan, the queue, and the metrics history of the feature lane.

---

## Testing

- Run the security review on the committed diff, pass with no High, Medium, or Low findings.
- Run the benchmark review, pass with no blocking finding.
- Run the quality review of the diff, three findings, one fixed and two recorded in the findings file.
- Run the check stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, metrics) at the implementation commit, all pass.
- Run make spec-validate after the archive, 56 items pass.

---

## Notes

On a blank Neovim's word under the cursor also takes the next word to the right, while this change opens the empty prompt as the queue entry says; the word is the keyword run around the cursor only, and every non-ASCII character counts as a word character. Both are recorded as follow-ups in the findings file.
