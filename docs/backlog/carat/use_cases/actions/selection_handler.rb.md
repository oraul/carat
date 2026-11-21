# Backlog: carat/use_cases/actions/selection_handler.rb

### Misleading flag (sprint-20 sweep quality, selection_handler.rb:81)

- Location: `carat/use_cases/actions/selection_handler.rb:81`
- Why: misleading flag: every variant is registered with repeat: true, including swap_ends, swap_corner, and yank_lines, which never change text; only the dispatcher's edit check (dispatcher.rb:142) keeps them out of the dot command, while action_handler.rb:15 documents repeat as a change the dot command repeats; also drop the historical 'as before' in the :66 comment
- Fix: pass repeat per variant, false for the swaps and the yank
- Category: editor
- Added: 2026-11-19
