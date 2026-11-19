## 1. Implementation

- [x] 1.1 Add Finder::Grep: the once-per-open read, the search, the counts, the safe row text, the column
- [x] 1.2 Wire plugin.finder.grep into the finder plugin: manifest action and `<leader>fg`, the shared prompt and picks, the cursor move after the open

## 2. Tests and docs

- [x] 2.1 Add test/editor_finder_grep.rb with its snapshot
- [x] 2.2 Document the picker in README.md, docs/actions.md, docs/plugins.md, and the code map

## 3. Review fixes

- [x] 3.1 Size the grep list full width on a wide screen (no preview beside it); test at 120 columns
- [x] 3.2 Show only invalid UTF-8 bytes as question marks and cut lines at a character boundary; tests with valid and invalid bytes and a cut inside a character
- [x] 3.3 Mark the title capped when a file is cut at the line cap; test past 100,000 lines
- [x] 3.4 Test the 1000-line file bound and the 400-byte cut
- [x] 3.5 Remove Grep#more? and the repeated index reset in open; score lines without the file-name bonus
