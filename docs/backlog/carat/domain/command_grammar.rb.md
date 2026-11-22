# Backlog: carat/domain/command_grammar.rb

## A typed count grows without a cap

- Where: `digit` in `carat/domain/command_grammar.rb` line 103 and `take` line 191; `Operators.put` in `carat/domain/operators.rb` line 44; the two `MAX_COUNT` copies in `RegisterCount` and `SubstituteArgs`; at 3895e21. Periodic quality blocking. Queue item `editing-counts`. Raised again at 9a92265 (#99 note 35), which adds `carat/use_cases/visual/put_over_selection.rb` line 124.
- Why it matters: the count is multiplied by the operator count with no limit, so a long count before `p` freezes the editor or exhausts memory, and past 19 digits the 64-bit count wraps.
- Fix outline: cap counts at Vim's 999999999 through one shared constant replacing both `MAX_COUNT` copies; refuse a put past a limit as Neovim's E1240 does; `domain_grammar` and put rows.
- Also: carat/domain/operators.rb, carat/use_cases/visual/put_over_selection.rb
- Category: editor
- Added: 2026-11-09

### accept_visual repeats accept's preamble

- Location: carat/domain/command_grammar.rb:163 and :138 (sprint-4 sweep, quality advisory).
- Why: the want check, remember, and search branch are copied.
- Fix: a shared private preamble returning the early result.
- Category: editor
- Added: 2026-11-14

### accept_visual repeats the prelude of accept

- Location: carat/domain/command_grammar.rb:158 against :134 to :143. Sprint-6 sweep, quality advisory. Queue item `input-core-tidy`.
- Why: duplication: the want check, remember, and search prelude are copied line for line.
- Fix outline: one private prelude returning the early result or nil, called by both.
- Category: editor
- Added: 2026-11-15

### A count grows without bound

- Location: carat/domain/command_grammar.rb:97 (sprint-8 sweep, quality); queued in `core-correctness-b`.
- Why: digit grows count without a cap and take multiplies the operator count, so a long digit run passes Vim's 999999999 and the 64-bit range, and a huge count can stall an insert repeat.
- Fix: clamp the count and the product at 999_999_999, with a test in test/domain_grammar.rb.
- Also: test/domain_grammar.rb
- Category: editor
- Added: 2026-11-16

### The typed count has no cap and MAX_COUNT is written twice
- Location: carat/domain/command_grammar.rb:98; carat/domain/register_count.rb:15; carat/domain/substitute_args.rb:27
- Why: CommandGrammar#digit accumulates with no cap, so a long count overflows Integer, while RegisterCount and SubstituteArgs stop at a duplicated 1_000_000_000. Folded into input-core-tidy.
- Fix: one domain count limit applied in digit too, with a grammar test.
- Also: carat/domain/register_count.rb, carat/domain/substitute_args.rb
- Category: editor
- Added: 2026-11-17

### The normal-mode count has no upper bound (sprint-20 sweep quality, command_grammar.rb:98)

- Location: `carat/domain/command_grammar.rb:98`
- Why: the normal-mode count has no upper bound: digit grows count*10 on every typed digit and take multiplies operator_count*count (line 186), so a long run of digits overflows the integer, while RegisterCount and SubstituteArgs cap ex counts at MAX_COUNT
- Fix: cap the count as they do (stop growing past 1_000_000_000 and clamp the product in take), with a domain_grammar row for a 20-digit count
- Category: editor
- Added: 2026-11-19

### Accept_visual repeats accept's opening (sprint-20 sweep quality, command_grammar.rb:158)

- Location: `carat/domain/command_grammar.rb:158`
- Why: accept_visual repeats accept's opening (the want reset to :cancel, remember, and the :search branch to :prompt)
- Fix: share one private prologue that both call before their mode-specific part
- Category: editor
- Added: 2026-11-19

### carat/domain/command_grammar.rb:98: the count grows without bound (count * 10 + (sprint-22 sweep quality)

- Location: `carat/domain/command_grammar.rb:98`
- Why: the count grows without bound (count * 10 + digit), unlike SubstituteArgs and RegisterCount, which stop at MAX_COUNT 1_000_000_000; a long typed count overflows the Integer or drives a motion or put loop for ever
- Fix: stop accumulating at a shared MAX_COUNT, as Vim caps counts, with a grammar test of an over-long count
- Category: editor
- Added: 2026-11-20

### carat/domain/command_grammar.rb:133: duplication: accept and accept_visual (:158) repeat the want-reset cancel (sprint-22 sweep quality)

- Location: `carat/domain/command_grammar.rb:133`
- Why: duplication: accept and accept_visual (:158) repeat the want-reset cancel and the :search prompt prefix
- Fix: one private prelude returning the symbol or nil, both methods keeping only their mode-specific tail
- Category: editor
- Added: 2026-11-20

### The last-key doubled rule could replace the g~~ guu gUU bindings

- Location: `carat/domain/command_grammar.rb`, `LAST_KEY_DOUBLED`, and `config/default.caratrc`, the `keymap.operator_pending ~`, `u`, and `U` lines.
- Why: two mechanisms give a multi-key operator its doubled form: the grammar's last-key rule for `gc` and operator_pending bindings of `~`, `u`, and `U` for the case operators; one rule would be simpler, but changing the case operators was outside the comment-operator brief (quality self-review).
- Fix: add the case operators to `LAST_KEY_DOUBLED` (or make the rule hold for every operator of more than one key), drop the three operator_pending lines, and keep the `editor_case_operators` rows for `g~~`, `guu`, and `gUU` passing.
- Also: config/default.caratrc
- Category: editor
- Added: 2026-11-21

### accept and accept_visual repeat the same opening (the want at carat/domain/command_grammar.rb:144 (sprint-26 sweep quality, note 11)

- Location: carat/domain/command_grammar.rb:144
- Why: accept and accept_visual repeat the same opening (the want reset to :cancel, remember, and the :search prompt branch)
- Fix: one private helper for the shared start that both call
- Category: editor
- Added: 2026-11-22

### accept_visual repeats accept's prelude at carat/domain/command_grammar.rb:171 (sprint-28 sweep quality, note 6)

- Location: carat/domain/command_grammar.rb:171, :145 to :154
- Why: the want reset, remember, and search branch are written twice.
- Fix: one private prelude both call, returning :cancel, :prompt, or nil.
- Category: editor
- Added: 2026-11-22
