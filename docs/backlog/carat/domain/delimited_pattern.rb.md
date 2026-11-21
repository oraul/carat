# Backlog: carat/domain/delimited_pattern.rb

### DelimitedPattern.typed is an alternate constructor not named from_x (sprint-15 review quality)

- Location: carat/domain/delimited_pattern.rb:42; callers find_match.rb:73, preview_search.rb:40.
- Why: the naming rule names an alternate constructor from_x.
- Fix outline: rename it from_prompt(text, forward) at both callers; cut stays public.
- Category: editor
- Added: 2026-11-17
