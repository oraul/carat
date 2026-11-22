# Tasks

## 1. The word

- [x] 1.1 Add `Matcher.word_at` and `keyword_byte?` (`carat/plugins/finder/matcher.rb`); prove it in `test/plugins_finder_matcher.rb` (the word rows: a word's start, middle, and end, a blank, past the line, an empty line, trailing blanks, a carriage return, an underscore, punctuation, multi-byte columns, bytes that are not UTF-8)
- [x] 1.2 Add `plugin.finder.word` and its `<leader>fw` binding (`carat/plugins/finder/plugin.rb`); prove it in `test/editor_finder.rb` (Scenario: Space f w on a word opens the grep picker with it, Space f w takes the whole word, Space f w on a multi-byte word, Space f w keeps underscores in the word, Space f w on a blank opens the grep picker empty, Space f w in an empty buffer or on an empty line, Space f w on the last character of the last line)

## 2. The switch

- [x] 2.1 Add `plugin.finder.switch` and its `<C-g>` prompt key (`carat/plugins/finder/plugin.rb`); prove it in `test/editor_finder.rb` (Scenario: Ctrl-G switches the file finder to the grep picker, Ctrl-G switches the grep picker to the file finder, Ctrl-G switches back and forth keeping the query, Ctrl-G with the empty prompt, Ctrl-G from the buffer picker opens the grep picker, A switched picker is picked from as any other, A switched picker is the one resumed, Ctrl-G after Space f w switches on the word)

## 3. Docs

- [x] 3.1 Add the two rows to `docs/actions.md` and `docs/compatibility.md`, a paragraph to `docs/plugins.md`, and update `docs/codebase-map.md` (area 15) and README.md
