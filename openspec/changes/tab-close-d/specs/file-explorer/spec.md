## MODIFIED Requirements

### Requirement: Files open in splits and tab pages
`s` and `v` on a file SHALL open it in a new window split horizontally or vertically from the previously used file window. `t` SHALL open it as the tab the top row shows: under `option.gt buffers` a buffer tab in that file window, the focus in it and the tree kept, and under `option.gt tabpages` a new tab page. When no window of the tab page shows a file, `t` SHALL open the file as `l` does, in a new window beside the tree, under either value, so no tab page is left holding only the tree. On a directory they SHALL do nothing. A file name holding a space or a `|` SHALL open as it is named, since the tree opens files without building an ex command line.

#### Scenario: Horizontal split
- **WHEN** `s` is pressed on "b.rb" with the tree and one file window
- **THEN** there are three windows and the current one shows "b.rb"

#### Scenario: Vertical split
- **WHEN** `v` is pressed on "b.rb"
- **THEN** there are three windows side by side and the current one shows "b.rb"

#### Scenario: t opens a buffer tab
- **WHEN** "a.md" is shown beside the tree and `t` is pressed on "b.rb"
- **THEN** one tab page remains, the top row shows "a.md" and "b.rb", the file window shows "b.rb" and is current, the tree stays open, and `gT` then shows "a.md" in the file window

#### Scenario: t on a listed file shows its tab
- **WHEN** "a.md" and "b.rb" are listed, "b.rb" is shown beside the tree, and `t` is pressed on "a.md"
- **THEN** the file window shows "a.md", the listed buffers are still "a.md" and "b.rb", and one tab page remains

#### Scenario: Tab page
- **WHEN** `option.gt tabpages` is set and `t` is pressed on "b.rb"
- **THEN** there are two tab pages and the current one shows "b.rb"

#### Scenario: t from a lone tree opens a file window
- **WHEN** the file window was closed with `<C-w>c`, leaving only the tree, and `t` is pressed on "alpha.txt"
- **THEN** one tab page remains, holding the tree and a file window that shows "alpha.txt" and is current

#### Scenario: t from a lone tree under tab pages opens a file window
- **WHEN** `option.gt tabpages` is set, the file window was closed with `<C-w>c`, leaving only the tree, and `t` is pressed on "alpha.txt"
- **THEN** one tab page remains, holding the tree and a file window that shows "alpha.txt" and is current

#### Scenario: A name with a space in a split
- **WHEN** `s` is pressed on "my notes.md"
- **THEN** there are three windows and the current one shows "my notes.md" with its text

#### Scenario: A name with a bar in a tab page
- **WHEN** `option.gt tabpages` is set and `t` is pressed on "a|b.md"
- **THEN** there are two tab pages and the current one shows "a|b.md" with its text
