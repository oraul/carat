### Comments.toggle copies a row's indent up to four times

- Location: `carat/domain/comments.rb`, `toggle`, `blank?`, and `commented?`.
- Why: each helper calls `Buffer#indent_of`, which copies the leading blanks, so a toggle allocates up to four strings per row; one toggle runs per command and is no hot path, so it was left in the comment-operator change (quality self-review).
- Fix: compute the indent width once per row in `toggle` and pass it to `blank?`, `commented?`, and `uncommented`.

### The last-key doubled rule could replace the g~~ guu gUU bindings

- Location: `carat/domain/command_grammar.rb`, `LAST_KEY_DOUBLED`, and `config/default.caratrc`, the `keymap.operator_pending ~`, `u`, and `U` lines.
- Why: two mechanisms give a multi-key operator its doubled form: the grammar's last-key rule for `gc` and operator_pending bindings of `~`, `u`, and `U` for the case operators; one rule would be simpler, but changing the case operators was outside the comment-operator brief (quality self-review).
- Fix: add the case operators to `LAST_KEY_DOUBLED` (or make the rule hold for every operator of more than one key), drop the three operator_pending lines, and keep the `editor_case_operators` rows for `g~~`, `guu`, and `gUU` passing.
