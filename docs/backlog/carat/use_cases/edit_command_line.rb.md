# Backlog: carat/use_cases/edit_command_line.rb

### The command-line edit and erase use cases repeat an end-of-line branch (sprint-25 review quality)
- Location: `carat/use_cases/edit_command_line.rb:25`, `carat/use_cases/erase_command_line.rb:28`
- Why: the end-of-line branch (cmdline_after = 0) duplicates what the general splice and `cmdline_position=` already give at the end (after = length - position = 0), in 2 files.
- Fix: drop the branch in both, always splice then set the position; accepted when the cmdline editing tests pass unchanged.
- Category: quality
