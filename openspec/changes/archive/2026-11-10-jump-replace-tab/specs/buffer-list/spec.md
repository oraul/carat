## ADDED Requirements

### Requirement: A buffer a jump left is unlisted
A buffer that lost its tab to a jump SHALL be unlisted as in Neovim: loaded, with its number and cursor, left out of `:ls` and of `:bn`, `:bp`, and the buffer `:bd` shows next; `:ls!` SHALL show it with `u` in the first flag column, and the `u` filter SHALL keep it. Opening it again by any command, `:b N` included, SHALL list it again with its tab.

#### Scenario: The listing hides an unlisted buffer and the bang shows it
- **WHEN** `gd` went from `a.rb` to `/project/b.rb` and `:ls`, then `:ls!`, are run
- **THEN** `:ls` lists only `b.rb`, and `:ls!` also lists `a.rb` as buffer 1 flagged `u` and `h`

#### Scenario: :bn skips an unlisted buffer
- **WHEN** `gd` went from `a.rb` to `/project/b.rb` and `:bn` is run
- **THEN** `b.rb` stays current

#### Scenario: :b N lists an unlisted buffer again
- **WHEN** `gd` went from `a.rb` to `/project/b.rb` and `:b 1` is run
- **THEN** `a.rb` is current and the tabs are `b.rb` then `a.rb`
