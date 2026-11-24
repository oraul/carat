# Backlog: carat/use_cases/search/jump_to_match.rb

### the pattern echo is written to the message row with at carat/use_cases/search/jump_to_match.rb:32 (sprint-32 sweep quality, note 13)
- Location: carat/use_cases/search/jump_to_match.rb:32
- Why: the pattern echo is written to the message row with state.show_output inside a use case, beside the outcome, while concerns/reporting.rb says Reporting is the one place an outcome reaches the row
- Fix: carry the echo as an Outcome that is not kept (as printed is a flag) and let Reporting choose show or show_output, or reword Reporting's comment
- Category: quality
