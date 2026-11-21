# Backlog: test/editor_explorer.rb

## Three explorer test rows spell out the DOCS tree inline

- Where: the rows 'Enter expands a directory', 'l expands it too', and 'h on a file goes to its parent' of `test/editor_explorer.rb` (lines 199, 200, and 224 at 136cc84) repeat the literal of the `DOCS` constant (line 88). Quality advisory of `explorer-folder-toggle`.
- Why it matters: a change to the tree's rendering must be made in four places instead of one, and a missed copy reads as a different expected tree.
- Fix outline: use `DOCS` in the three rows; the snapshot does not change.
- Category: code-quality
- Added: 2026-11-05

## Explorer and icon tests pass raw table cells

- Where: `test/editor_explorer.rb` lines 114, 188, 235, 257, 297; `test/plugins_explorer.rb` lines 152 and 162; `test/domain_icons.rb` lines 53 and 89, at 5e4c140. Periodic quality. Queue item 38 (test hygiene).
- Why it matters: the CLAUDE.md typed-table rule; line 137 of the first file already converts.
- Fix outline: convert each cell with `.to_s`, `.to_i`, or `== true` before it reaches the library.
- Also: test/plugins_explorer.rb, test/domain_icons.rb, CLAUDE.md
- Category: code-quality
- Added: 2026-11-09
