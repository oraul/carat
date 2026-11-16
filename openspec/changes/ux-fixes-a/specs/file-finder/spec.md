## MODIFIED Requirements

### Requirement: A pick opens in the window, a split, a vertical split, or a tab page
`<CR>` SHALL close the finder and open the highlighted file in the editing window; `<C-x>` and `<C-s>` in a horizontal split of it, `<C-v>` in a vertical split, and `<C-t>` in a new tab page. The mode SHALL be normal afterwards and the floats gone. `<CR>` with no match SHALL keep the finder open on the typed text: the prompt with the same text, the float reading `No match`, and nothing opened, so a typo costs only the keys that fix it.

#### Scenario: Enter opens the file
- **WHEN** the user types `bet` and presses `<CR>`
- **THEN** the current buffer is `lib/beta.rb`, in the same window, in normal mode, and no float shows

#### Scenario: Ctrl-X opens it in a split
- **WHEN** the user presses `<C-x>` on a highlighted file
- **THEN** the window is split and the new, current window shows the file

#### Scenario: Ctrl-V opens it in a vertical split
- **WHEN** the user presses `<C-v>` on a highlighted file
- **THEN** the window is split side by side and the new, current window shows the file

#### Scenario: Ctrl-T opens it in a tab page
- **WHEN** the user presses `<C-t>` on a highlighted file
- **THEN** a second tab page is current and shows the file

#### Scenario: Enter with no match opens nothing
- **WHEN** nothing matches and the user presses `<CR>`
- **THEN** no file is opened and the current buffer is unchanged

#### Scenario: Enter with no match keeps the finder open
- **WHEN** the user presses `<C-p>`, types `zzqx`, which no file matches, and presses `<CR>`
- **THEN** the mode is still command-line with the prompt reading `> zzqx`, the float reads `No match`, and the current buffer is unchanged

#### Scenario: The query is kept for a correction
- **WHEN** after `<C-p>zzqx<CR>` the user presses `<BS>` four times and types `bet`, then `<CR>`
- **THEN** the current buffer is `lib/beta.rb` and no float shows
