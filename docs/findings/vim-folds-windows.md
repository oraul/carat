### Replace mode cannot be entered, so its fold opening has no test
- Location: carat/use_cases/arrange_view.rb (typing), carat/domain/mode.rb REPLACE
- Why: no key or handler enters Mode::REPLACE (R is unbound), so the replace branch that opens closed folds cannot be proved by a table row; the quality advisory asked for zfjRX<Esc>.
- Fix: when R is implemented, add the row zfjRX<Esc> expecting [[0, 1, false]] and the lines X b c d e.
