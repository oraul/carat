# Design

## Context

`NormalCommandHandler#call` refuses a call at `MAX_DEPTH` nested `:normal` commands with E192 and otherwise runs its keys once at the cursor or once per line of its range (line 62). The refusal is local: the caller's key loop and row loop go on. HandleKey counts remaps per key, and each line of a range counts its own (`A remap per line of a long range`), so the remap limit does not bound the product of the lines across levels either. A user binding `Q :%normal<Space>Q<CR>` over two lines runs 2 to the 100th levels.

`SubstituteLines#remember` hands the last search the pattern compiled for the substitute, under the case the `i` or `I` flag chose. `call` keeps the typed string before it refuses `c` and `l`. `Replacement.expand` has one block for `\0` to `\9` and a copy of it for `&`. `LastSubstitute` holds `case_mode` and `print` as 0, 1, and 2.

## Decisions

### E192 ends every :normal running

The handler keeps one flag, `@stopping`, set when a call is refused as too deep; while it is set, `run` feeds no further key and the row loop takes no further line, so each enclosing call returns after the key it was feeding. The outermost call, the one that brings `normal_depth` back to 0, clears it. The flag sits on the handler, as HandleKey keeps its remap count: one `NormalCommandHandler` is registered, and the nesting is one call stack on it. Neovim goes on with the enclosing calls until Ctrl-C, which Carat has no way to send while keys run; `docs/compatibility.md` records the difference. Alternative: a budget of runs across a stack; rejected, since a top-level `:%normal` over a long file is legitimate linear work and any fixed budget either refuses it or still lets an exponential stack run for minutes. A chain of distinct bindings that never reaches the limit is the user's own and runs as in Vim (out of scope).

### n and N read the options' case

When the substitute's case is not the options' (`case_mode` not `:options`), `remember` lets the last search recompile the pattern with `LastSearch#recompile(options, memory)`, as `:set ignorecase` does, so `n` and `N` match as a typed search with that pattern would. The memory's previous string is still the one the substitute compiled with, since `keep_previous` runs after `remember`. Without a flag the compiled substitute pattern is kept as before, so the common path compiles once.

### A refused flag keeps nothing

`call` checks for a string to reuse first (E33 stays the answer to `:&c` with none), refuses `c` and `l` next, and only then keeps the typed string. The refusal already came before the flags, the pattern, and the previous string were kept.

### One block inserts a group

`Replacement.group_at(text, i, n)` answers the group the item at byte i names: 0 for `&`, 0 to 9 for a backslash and a digit, -1 for anything else. `expand` asks it first and inserts the group in one block, advancing 1 byte for `&` and 2 for the escape. `recase` answers its text itself when `one` and `all` are both 0, so that block keeps the copy-free path the first copy had. The new method is public like the module's other helpers, and `test/domain_substitute.rb` reads it directly.

### Symbols for case and print

`case_mode` is `:options`, `:ignore`, or `:match`, `print` `:none`, `:line`, or `:number`, compared with `==` (no `when` on a constant, `docs/spinel-notes.md`). The member names stay, so the readers in `SubstituteLines` and the flag table of `test/domain_substitute.rb` change only their values.

## Risks

- The flag must be cleared on every way out of the outermost call: `call` has no early return after `normal_depth` is raised, and no `begin` and `ensure` (Spinel's 64 exception frames), so the clear sits beside the decrement.
