# Backlog: carat/domain/cmdline_menu.rb

### CmdlineMenu#initialize repeats every assignment of clear (sprint-25 review quality)
- Location: `carat/domain/cmdline_menu.rb:28`
- Why: the constructor and `clear` hold the same assignments, so a new member must be added twice.
- Fix: call `clear` after `super()`; accepted when `make types` shows every member still pinned and the tests pass.
- Category: quality
