## MODIFIED Requirements

### Requirement: Space f r opens the recent files picker
In normal mode `<leader>fr` SHALL open the finder's picker over the recent files, most recent first: every file shown in a window since the editor started and every file an earlier run kept, also after its buffer was deleted, at most 100, a file shown again moving to the top; the float SHALL be titled `Recent N/M` and work as the file finder does. The key SHALL be a default binding of the plugin.

#### Scenario: Space f r lists the recent files most recent first
- **WHEN** `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` were opened in that order and the user presses `<Space>fr`
- **THEN** a float titled `Recent 3/3` lists `docs/guide.md`, `lib/beta.rb`, and `lib/alpha.rb`

#### Scenario: A file shown again moves to the top
- **WHEN** after those three the user shows `lib/alpha.rb` again and presses `<Space>fr`
- **THEN** the float lists `lib/alpha.rb` first, then `docs/guide.md` and `lib/beta.rb`

#### Scenario: A deleted buffer stays recent
- **WHEN** `lib/beta.rb` was deleted with `:bd` and the user presses `<Space>fr`
- **THEN** the float still lists `lib/beta.rb`, and Enter on it opens it again

#### Scenario: The recent files survive a restart
- **WHEN** an editor opened `lib/alpha.rb` and `lib/beta.rb` and ended, and a new editor in the same directory opens `docs/guide.md` and the user presses `<Space>fr`
- **THEN** a float titled `Recent 3/3` lists `docs/guide.md`, `lib/beta.rb`, and `lib/alpha.rb`

## ADDED Requirements

### Requirement: The recent files picker names each file by the working directory
The recent files picker SHALL show each path relative to the working directory when it lies below it and absolute otherwise, so a pick opens the file the row names whatever the working directory is.

#### Scenario: The recent files keep naming their files after the working directory changes
- **WHEN** an editor in `/p` opened `lib/alpha.rb` and `lib/beta.rb` and ended, a new editor in `/q` opens `x.rb`, the user presses `<Space>fr`, moves the highlight to the second row, and presses Enter
- **THEN** the float lists `x.rb`, `/p/lib/beta.rb`, and `/p/lib/alpha.rb`, and Enter opens the file `/p/lib/beta.rb`, not a file of that name under `/q`

#### Scenario: A path inside the working directory is shown relative
- **WHEN** an editor in `/p` opened `lib/alpha.rb` and ended, and a new editor in `/p/lib` opens `beta.rb` and the user presses `<Space>fr`
- **THEN** the float lists `beta.rb` and `alpha.rb`
