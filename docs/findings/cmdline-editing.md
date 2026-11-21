### A direct write of the command line text keeps the old cursor count
- Location: carat/domain/editor_state.rb (`cmdline_after`, `replace_cmdline`)
- Why: the cursor is the count of characters after it, so a text assigned with `state.cmdline =` after a cursor move keeps that count and the cursor lands inside the new text; every shipped writer uses `replace_cmdline`, but nothing forbids a later one
- Fix: have test/lint.rb refuse `.cmdline =` outside `carat/domain/editor_state.rb`, or make the writer reset the count
