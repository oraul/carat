## ADDED Requirements

### Requirement: Icons are drawn in their file type's color
Each line's icon SHALL be drawn in the file-icon group of its kind: `DevIconFolder` for a directory, `DevIconSymlink` for a symbolic link, the group of its file type for a file (`DevIconRb`, `DevIconJson`, `DevIconMd`, `DevIconToml`, `DevIconMakefile`, `DevIconSh`, `DevIconC`, `DevIconYml`, `DevIconGitIgnore`, `DevIconLock`), and `DevIconDefault` otherwise; the rest of the line SHALL keep the normal group.

#### Scenario: A Ruby file and a directory
- **WHEN** the icons option is "unicode", the root holds "b.rb" and "docs/", and the tree is shown
- **THEN** the cell of "▸" on the "docs" line is in DevIconFolder, the cell of "◈" on the "b.rb" line is in DevIconRb, and the cells of "b.rb" are in the normal group

#### Scenario: Syntax off
- **WHEN** `:syntax off` is run with the tree shown
- **THEN** every icon cell is in the normal group

### Requirement: The icon colors follow the syntax switch
The tree's icons SHALL be drawn plain while syntax highlighting is off.

#### Scenario: Syntax on again
- **WHEN** `:syntax on` follows `:syntax off` with the tree shown
- **THEN** the cell of "◈" on the "b.rb" line is in DevIconRb again
