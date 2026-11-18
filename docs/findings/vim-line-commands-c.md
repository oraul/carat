### Global :p copies every earlier printed line per match
- Location: carat/use_cases/search/global_command.rb:174
- Why: each :p in a global copies every earlier printed line into a new string, quadratic in the lines printed (:g/./p on a large file).
- Fix: append the printed lines to one mutable string or array and build the Outcome.from_print once after the loop.

### place_cursor clamps by the mode's max_col, not as in normal mode
- Location: carat/use_cases/ex/line_command_handler.rb:57
- Why: place_cursor now clamps through EditorState#max_col, which allows the column past the last character in insert and visual modes, where the old code always clamped as in normal mode (a line command run by a plugin's run_ex in insert mode or a : binding in visual mode); the new comment's '(the end of the line for a wanted column past it, -1)' is garbled.
- Fix: keep the normal-mode clamp or state the mode dependence and reword the comment.

### Doubled comma in the join handler's header comment
- Location: carat/use_cases/ex/join_command_handler.rb:18
- Why: the header comment reads 'what ExRange gives,, a bad count', a typo reported by two review passes (at bd2f7aad933d and 460a4404420f), merged here.
- Fix: drop the extra comma.

### Ragged wiring comment around HandleKey in EditorAssembly
- Location: carat/adapters/editor_assembly.rb:191
- Why: the edited comment reads 'registered afterwards, after HandleKey, which :normal receives, the core ex commands before the', a broken wrap with stacked clauses that leaves a short ragged line, reported by two review passes, merged here.
- Fix: rewrap the paragraph and say HandleKey is built before the ex handlers because :normal receives it.

### :normal runs HandleKey's follow for every key it feeds
- Location: carat/use_cases/ex/normal_command_handler.rb:99
- Why: each key :normal feeds goes through HandleKey#call, whose follow runs the completion, float, palette, and plugin observers and ArrangeView per key, so :%normal on a large buffer pays them for every key of every line.
- Fix: note it as a known cost or give HandleKey a path that defers follow to the end of the :normal.

### The :p row gives its bang refusal as a bare E477
- Location: docs/compatibility.md:1
- Why: the :p row names its bang refusal as a bare E477 while its other errors and the :normal row give the full text.
- Fix: write E477: No ! allowed.

