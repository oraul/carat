# Backlog: test/editor_folds.rb

### A fold test label repeats keys instead of naming the behavior
- Location: test/editor_folds.rb:127
- Why: the label 'zf3jzozfj nests a fold at the outer fold's first row' repeats the keys of the drawing row at line 88 instead of naming the behavior it proves.
- Fix: label it by the state it proves, for example 'zf at an open fold's first row adds a closed fold nested in it'.
- Category: code-quality
- Added: 2026-11-18
