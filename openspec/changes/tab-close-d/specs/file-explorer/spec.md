## ADDED Requirements

### Requirement: t from a lone tree opens a file window
When no window of the tab page shows a file, `t` on a file SHALL open it as `l` does, in a new window beside the tree that becomes current, under `option.gt buffers` and `option.gt tabpages` alike, so no tab page is left holding only the tree.

#### Scenario: t from a lone tree opens a file window
- **WHEN** the file window was closed with `<C-w>c`, leaving only the tree, and `t` is pressed on "alpha.txt"
- **THEN** one tab page remains, holding the tree and a file window that shows "alpha.txt" and is current

#### Scenario: t from a lone tree under tab pages opens a file window
- **WHEN** `option.gt tabpages` is set, the file window was closed with `<C-w>c`, leaving only the tree, and `t` is pressed on "alpha.txt"
- **THEN** one tab page remains, holding the tree and a file window that shows "alpha.txt" and is current
