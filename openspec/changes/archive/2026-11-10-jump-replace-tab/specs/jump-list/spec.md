## ADDED Requirements

### Requirement: Ctrl-O and Ctrl-I follow the jump's tab rule
With `option.jumptab replace`, `Ctrl-O` and `Ctrl-I` to a buffer that has no tab SHALL show it in the tab of the buffer they leave, at the same position, that buffer losing its tab, so going back and forth never changes the number of tabs. A walk to a buffer that has a tab SHALL select it and change no other tab.

#### Scenario: Ctrl-O gives the buffer gd left its tab back
- **WHEN** `gd` went from `a.rb` alone to `/project/b.rb`, then `Ctrl-O` is pressed, then `Ctrl-I`
- **THEN** after `Ctrl-O` one tab remains, `a.rb`'s, with the cursor where `gd` left it, and after `Ctrl-I` one tab remains, `b.rb`'s

#### Scenario: Back and forth keeps the tab's position
- **WHEN** `lib/x.rb` was opened with `:e`, `:bp` went back to `a.rb`, `gd` went to `/project/b.rb`, and `Ctrl-O` is pressed
- **THEN** the tabs are `a.rb` then `x.rb`, the `a.rb` tab selected
