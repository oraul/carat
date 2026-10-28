# Design

## Context

See proposal.md for motivation. The foundation gives us a keymap trie per mode, `HandleKey` dispatching an action name as soon as a sequence matches, `Move` with nine motions as a `case`, `Buffer` with four primitives, `Range` with a kind and an inclusive flag that nothing exercises yet beyond exclusive charwise, `EditorState#pending_keys` for the keymap wait, and the harness that types Vim notation. `docs/architecture.md` section 4 fixes the grammar, the `Command` value, and that motions and text objects are pure functions from state and count to a range; the Spinel facts recorded by the three archived designs still hold: `Data` and `Struct` subclass forms, member pins, no `Hash[Integer, T]`, `[cp].pack("U")` for code points, empty array literals stored through writers, frame reuse.

Two probe programs compiled with the pinned Spinel commit, kept outside the repository, established what this change relies on beyond those facts:

- An empty array literal passed as an argument whose parameter is pinned `Array[String]` compiles and runs (`set_lines(from, to, [])`), unlike the same literal passed to `super`; a local `result = []` that is only ever pushed strings is inferred `Array[String]`; `Array#uniq` over `Data` values, `while true` with `break`, `String#match?` with a character class, and `String#ord` on a multi-byte character all behave as in CRuby.
- A method defined on a `Data` subclass that takes another instance and returns a new one works when the receiver is statically typed, but a value read from a `Hash[String, T]` member with a program class `T` is `untyped` (the pin widens, as the Struct change recorded), and a method of a `Data` instance cannot be reached by dynamic dispatch: the call raises `NoMethodError` at run time. `Registers` therefore combines entries through `RegisterEntry.joined(first, second)`, a class method whose typed parameters make the call static. A `Struct` instance read from such a hash is dispatched fine, as `Keymap` already relies on.
- `Array[T]` with a program class `T` in an inline signature is reported as a type Spinel cannot pin and the signature is dropped with a warning, and an `Array[untyped]` of `Data` values leaks `untyped` into everything built from its elements, which `spinel-doctor` then reports as unresolved calls on polymorphic receivers. The sentence starts and the word runs are therefore `Struct` records over parallel `Array[Integer]` members (`SentenceStarts`, `Runs`), read through methods with return signatures, because an indexed element is nullable to the compiler.
- A local that holds an `Integer` in one branch and a `Position` in another is a union for the whole method, and passing it to `Position.new` widened `Position#row` to `untyped` for the entire program; `Operate#operand` names its row local `last_row` for that reason. A nullable local stays nullable after a nil check, so `Position.sure` returns the same value typed as never nil before its members are read into another value.
- `make types` and `spinel-doctor` are the tools that find these: `make types` on `main` was diffed against the branch for every new `untyped` member, and a stubbed copy of the program per suspect, compiled in parallel outside the repository, located the construction that widened the member.

## Goals / Non-Goals

**Goals:**

- One parser produces every normal-mode command as a value; `HandleKey` stays the only place keys are read, and `Operate` the only place operators run, so the dot command and visual mode later reuse both without a second key path.
- Motions and text objects are usable with no editor around them: a function of `EditorState` and a count, with no I/O and no mode changes, so the table-driven tests read as Vim sessions and the compatibility record is honest.
- Every binding, including the operator-pending map and the text objects, is data in `config/default.json`.

**Non-Goals:**

- Transactions. Every operator still runs through the buffer primitives directly; the undo change wraps them without changing the operator code.
- Visual-mode operands, the `o_v` forcing prefixes, and the `.` replay, although `Command#keys` records what a replay would need.
- A beep. A motion or operand that fails simply changes nothing, as the foundation does for a motion at an edge.

## Decisions

### The grammar sits between the keymap and the dispatcher

`HandleKey` keeps resolving keys through the keymap, and in normal and operator-pending modes hands each resolved action to `CommandGrammar#accept(action, keys)`. The grammar classifies the action by its name: `operator.delete`, `operator.change`, `operator.yank`, `operator.indent`, and `operator.dedent` are the five pending operators; `cursor.*` and `motion.*` are motions; `textobject.*` are text objects; `register.select` and the four find motions want one more key; everything else is a standalone action that completes at once. Before the keymap, and only when no multi-key binding is in progress, the grammar takes digits as a count and, when it wants a character, takes the next key literally. The alternative, a grammar that reads raw keys and owns a table of which key is which, would hard-code bindings in Ruby, which the architecture forbids. Classifying by namespace keeps the grammar free of key codes and lets a user rebind any motion or operator in JSON.

### The grammar is a Struct record owned by the editor state

`CommandGrammar < Struct.new(:register, :count, :operator, :operator_count, :want, :linewise, :keys, :typed)` lives in `EditorState#grammar`, because its fields persist between keys and every use case that cancels a command (Escape, an unbound key) resets it through the state. `accept` returns a symbol, `:pending`, `:operator`, `:complete`, or `:cancel`, and `take` returns the finished `Command` and resets. `HandleKey` switches the mode to `operator_pending` on `:operator` and back to `normal` before dispatching on `:complete`, so an operator that enters insert mode is the last word. The pending-keys display is `EditorState#showcmd`, the grammar's `typed` text plus the keymap's pending keys formatted, read by the frame presenter and painted at the right edge of the message row. Alternative: keep the grammar inside `HandleKey` as instance variables; rejected because the state is per editor, not per key path, and because the presenter needs to read it.

### Counts are optional, not defaulted

`Command#count` is 0 when no count was typed, because `G`, `gg`, and `$` behave differently with and without one. `Command#count_or(1)` serves the motions that do not care. The product rule gives `2d3w` a count of 6 and `d3w` a count of 3; a doubled operator uses `count_or(1)` lines.

### Motions return a target with its kind, never a range

`Motions.call(state, action, count, char, pending) -> Motion?` returns `Motion < Data.define(:target, :linewise, :inclusive, :want)`, where `want` says what happens to the wanted column: `:set` for horizontal motions, `:keep` for vertical ones, `:end` for `$`. `nil` means the motion failed. `Move` applies a motion to the cursor; `Operate` turns it into a `Range` by ordering the cursor and the target, applying the inclusive flag and the two exclusive adjustments from the motions spec, and widening a linewise motion to whole rows while keeping the real positions in `from` and `to` so a yank can place the cursor. The `pending` flag is what lets `l` step past the last character and `w` stop at the end of the line only under an operator. Alternative: motions returning ranges directly; rejected because the same function must move the cursor, and because the exclusive adjustments depend on the operator context, not the motion.

`;` and `,` need the last `f`, `F`, `t`, or `T`: `EditorState#last_find` holds a `Find < Data.define(:char, :forward, :till)` or nil. `H`, `M`, and `L` need the window height: `Window#height` is set by the frame presenter at every render and is 0 before the first one, in which case the whole buffer counts as visible.

Word classes are a function of one character: blank, keyword (ASCII letters, digits, underscore, code points from U+00C0), or other. Word motions walk the buffer character by character with an explicit `(row, col)` iterator that treats the end of each line as a blank and an empty line as its own word, which is the shape of Vim's `fwd_word`, `bck_word`, `end_word`, and `bckend_word`.

### Text objects return a range

`TextObjects.call(state, action, count) -> Range?`. Word and sentence objects are charwise; paragraph objects are linewise; bracket objects are charwise unless the inner form stands between brackets that end their lines, when it is linewise over the lines between. The bracket search walks backward from the cursor counting nesting, treats the cursor on an opening bracket as that pair and on a closing bracket as the pair it closes, then walks forward for the match; a count repeats the backward step. Quote objects pair the unescaped quotes of the cursor line from its start.

### Operators are functions over ranges; Operate owns cursor, mode, and registers

`Operators` holds the buffer work: `extract(buffer, range)` reads the text of a charwise or linewise range into a `RegisterEntry`, `delete`, `put`, `join`, and `shift` write through the primitives. `Operate#call(state, command)` resolves the operand, writes the register, calls the operator, and places the cursor and mode. The standalone commands are the same code with a fixed operand: `x` is `dl`, `s` is `cl`, `S` is `cc`, `C` is `c$`, `D` is `d$`, `Y` is `y$`, `p`, `P`, and `J` have no operand. `RegisterEntry < Data.define(:text, :linewise)` and `Registers < Struct.new(:unnamed, :named)` with `write(name, entry)` and `read(name)`; append joins text or lines as the registers spec says.

### Dispatcher receives a Command

`Dispatcher#call(state, command)` replaces the action-name form, because counts and registers belong to every action. Insert and command-line modes still dispatch through it with a bare `Command.plain(action)`. Operators and the standalone editing commands go to `Operate`; motions go to `Move`; the rest is the existing `case`.

### Bindings

`config/default.json` binds the five operators, the standalone commands, `"` as `register.select`, and the full motion set in `normal`, and binds the same motions, the operators (for doubling), the text objects, and Escape in `operator_pending`. The `dd` and `yy` sequences disappear; `operator.delete_line`, `operator.yank_line`, `motion.word_forward`, `motion.word_backward`, and `motion.word_end` were reserved names and are replaced by the names in `docs/actions.md`. `test/domain_keymap.rb` and `test/editor_normal.rb` follow.

## Risks / Trade-offs

- [The grammar reads digits before the keymap, so a binding on "1" to "9" can never fire] → Documented in the proposal; Neovim has the same rule for counts.
- [Vim's word, sentence, and bracket edge cases are many] → Each implemented rule is a scenario in the specs and a row in a table test; anything not listed is not claimed in `docs/compatibility.md`.
- [A long `case` in `Motions` and `TextObjects` over action strings] → Each arm is one call to a named function, and `make diagnose` keeps every slot typed; the shape matches `Dispatcher` and `ExecuteEx`, which Spinel already compiles well.
- [Operators that run many primitives per command on a large buffer] → Linewise work uses one `set_lines` per operator; charwise deletes are one `delete`; a put is one `insert` or one `set_lines`.
- [Changing `Dispatcher#call`'s signature touches every use case test] → Only `HandleKey` and the harness call it; the test programs type keys.
