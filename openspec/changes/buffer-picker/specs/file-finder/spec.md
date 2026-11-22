## ADDED Requirements

### Requirement: Space f b opens the buffer picker
In normal mode `<leader>fb` SHALL open the finder's picker over the listed file buffers, in the order `:ls` shows them, scratch and unnamed buffers left out: the prompt `> ` and a bordered float titled `Buffers N/M`. Typing, the highlight keys, the preview, Enter, the split, vertical split, and tab keys, and Esc SHALL work as in the file finder. The key SHALL be a default binding of the plugin, which the configuration may replace.

#### Scenario: Space f b lists the open buffers
- **WHEN** `lib/alpha.rb` and then `lib/beta.rb` are open and the user presses `<Space>fb`
- **THEN** the mode is command-line and a float titled `Buffers 2/2` lists `lib/alpha.rb` marked `> ` and `lib/beta.rb`

#### Scenario: The buffer picker filters and opens the pick
- **WHEN** the user types `alp` in the buffer picker and presses Enter
- **THEN** the float was titled `Buffers 1/2` and `lib/alpha.rb` is shown in normal mode

#### Scenario: Unnamed buffers are not listed
- **WHEN** `:new` opened an unnamed buffer beside `lib/alpha.rb` and the user presses `<Space>fb`
- **THEN** the float is titled `Buffers 1/1` and lists only `lib/alpha.rb`

#### Scenario: A deleted buffer leaves the buffer picker
- **WHEN** `lib/beta.rb` was deleted with `:bd` and the user presses `<Space>fb`
- **THEN** the float lists only `lib/alpha.rb`

### Requirement: Space f r opens the recent files picker
In normal mode `<leader>fr` SHALL open the finder's picker over the recent files, most recent first: every file shown in a window since the editor started, also after its buffer was deleted, at most 100, a file shown again moving to the top; the float SHALL be titled `Recent N/M` and work as the file finder does. The key SHALL be a default binding of the plugin.

#### Scenario: Space f r lists the recent files most recent first
- **WHEN** `lib/alpha.rb`, `lib/beta.rb`, and `docs/guide.md` were opened in that order and the user presses `<Space>fr`
- **THEN** a float titled `Recent 3/3` lists `docs/guide.md`, `lib/beta.rb`, and `lib/alpha.rb`

#### Scenario: A file shown again moves to the top
- **WHEN** after those three the user shows `lib/alpha.rb` again and presses `<Space>fr`
- **THEN** the float lists `lib/alpha.rb` first, then `docs/guide.md` and `lib/beta.rb`

#### Scenario: A deleted buffer stays recent
- **WHEN** `lib/beta.rb` was deleted with `:bd` and the user presses `<Space>fr`
- **THEN** the float still lists `lib/beta.rb`, and Enter on it opens it again

### Requirement: Space f R resumes the last search
In normal mode `<leader>fR` SHALL reopen the last picker the finder closed, by Esc or by a pick, the file finder, the grep picker, the buffer picker, or the recent files picker, with its typed text on the prompt and its list read again and filtered by it, the highlight on the row it was on, or on the last row when fewer rows match. With no picker closed yet it SHALL show the message `No search to resume` and stay in normal mode.

#### Scenario: Space f R resumes the file finder after Esc
- **WHEN** the user typed `a` in the file finder, moved the highlight to the second row, pressed Esc, and then presses `<Space>fR`
- **THEN** the prompt reads `> a` and the float titled `Files 2/3` has `lib/beta.rb` marked

#### Scenario: Space f R resumes after a pick
- **WHEN** the user opened `lib/beta.rb` from the buffer picker with `bet` and Enter, and then presses `<Space>fR`
- **THEN** the buffer picker opens again with the prompt `> bet` and the float titled `Buffers 1/2`

#### Scenario: Space f R resumes the grep picker
- **WHEN** the user typed `b` in the grep picker, pressed Esc, and then presses `<Space>fR`
- **THEN** the grep picker opens again with the prompt `> b` and lists the matching line of `lib/beta.rb`

#### Scenario: The resumed highlight is clamped
- **WHEN** the highlight was on the second row of the buffer picker, Esc closed it, `:bd` deleted that buffer, and the user presses `<Space>fR`
- **THEN** the float titled `Buffers 1/1` has its one row marked

#### Scenario: Nothing to resume
- **WHEN** no picker was closed yet and the user presses `<Space>fR`
- **THEN** the mode stays normal, no float opens, and the message reads `No search to resume`

### Requirement: The pickers are drawn in both carat themes and in ASCII
The buffer and recent files pickers SHALL be drawn as the file finder's float is: the same rows under `carat-dark` and `carat-light`, the edge in each theme's `FloatBorder` color and the title in its `FloatTitle` color, and under `option.icons ascii` the edge drawn with `+`, `-`, and `|`.

#### Scenario: The buffer picker's rows in both themes
- **WHEN** the buffer picker lists two buffers under `option.theme carat-dark` and under `option.theme carat-light`
- **THEN** both frames show the same rows, the top edge holding the title `Buffers 2/2`, the edge cells in that theme's `FloatBorder` color and the title cells in its `FloatTitle` color

#### Scenario: The recent files picker's rows in ASCII
- **WHEN** `option.icons ascii` is set and the user presses `<Space>fr`
- **THEN** the float's top edge starts with `+`, holds `Recent` and runs in `-`, its sides are `|`, and its bottom edge is `+` and `-`
