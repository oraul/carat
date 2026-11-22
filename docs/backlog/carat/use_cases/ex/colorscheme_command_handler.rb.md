# Backlog: carat/use_cases/ex/colorscheme_command_handler.rb

### validates the name with Themes.known? and assigns options.theme directly at carat/use_cases/ex/colorscheme_command_handler.rb:26 (sprint-26 sweep quality, note 36)

- Location: carat/use_cases/ex/colorscheme_command_handler.rb:26
- Why: validates the name with Themes.known? and assigns options.theme directly, while :set theme validates through Options#problem (carat/use_cases/ex/set_command_handler.rb:155), two rules for one option that can drift
- Fix: check the name with options.problem("theme", "theme", name) and keep E185 as the message
- Also: carat/use_cases/ex/set_command_handler.rb
- Category: editor
- Added: 2026-11-22
