# Proposal

## Why

Carat has a modal editor with one window, but normal mode only moves the cursor one step at a time and every editing key beyond insert mode reports "Not implemented". Roadmap item 3 of `docs/architecture.md`, `command-grammar`, gives normal mode Neovim's `[register] [count] operator [count] (motion | text-object)` grammar, so that counts, operators, the full motion set, text objects, and the first registers work together through one parser, and so that undo, the dot command, visual mode, and search have a `Command` value and an operator pipeline to build on.

## What Changes

This change delivers roadmap item 3, `command-grammar`.

- Add `CommandGrammar`, a state machine over normal-mode keys that parses an optional `"x` register prefix, counts before and after an operator (multiplied), an operator followed by a motion or a text object, a doubled operator acting linewise over count lines, and standalone actions with a count; it produces a `Command` value (register, count, operator, action, character argument, linewise flag, and the keys that formed it) and never touches a buffer.
- Add operator-pending mode: pressing an operator switches to it, its own keymap in `config/default.json` binds the motions, the text objects, and the operators themselves for doubling, Escape or any unbound key cancels, and the keys typed so far are shown at the right of the message row until the command completes.
- Add `Motions`, pure functions from the editor state and a count to a target with a kind and an inclusive flag, serving both cursor movement and operator ranges: left-right (`h l 0 ^ $ f F t T ; ,`), up-down (`j k G gg + - _`), word (`w W b B e E ge gE`), sentence and paragraph (`( ) { }`), and screen (`H M L`). The nine foundation motions keep their `cursor.*` action names and now take counts; the new ones are `motion.*` actions.
- Add `TextObjects`: `iw aw iW aW is as ip ap` and the pair objects for `()` (also `b`), `[]`, `{}` (also `B`), `<>`, and the three quotes, as `textobject.*` actions bound in operator-pending mode.
- Add `Operators` and the `Operate` use case: `d c y > <` over a motion, a text object, or a doubled operator, and the standalone `x s S C D Y J p P`, every edit running through the buffer primitives; `c`, `s`, `S`, and `C` end in insert mode.
- Add `Registers`, a minimal record with the unnamed register and the named registers `a` to `z` with uppercase append; every delete, change, and yank writes the unnamed register and the named one when `"x` was given, and `p` and `P` read them, with Vim's `E353` message when the register is empty.
- Change `HandleKey` to feed normal-mode and operator-pending keys through the grammar before the keymap, `Dispatcher` to receive a `Command` instead of a bare action name, and `Move` to run every motion through `Motions`.
- Change `config/default.json`: `d c y > <` become `operator.delete`, `operator.change`, `operator.yank`, `operator.indent`, `operator.dedent`; the `dd` and `yy` sequences are removed because doubling is a grammar rule; the new motions, the standalone operators, `"` as `register.select`, and the whole operator-pending map are added; the generated mirror is regenerated.
- Extend `docs/compatibility.md` with one row per command implemented, each backed by a table-driven test row, and `docs/actions.md` with every new action name; update `CLAUDE.md` and the README.
- Add `docs/backlog.md`, the list of known items left for later changes, seeded with two findings, and add a security review phase to the contributor agent between its Test and Archive phases, both asked for by the main session while this change was in flight.

Out of scope, delivered by later roadmap items: the numbered registers with shifting, the black hole and read-only registers, undo and redo, the dot command (the `Command#keys` field is filled for it but nothing replays it), visual mode, the search motions `n N * #`, mark motions, the remaining operators `= ~ g~ gu gU gq r`, counts before `i a I A o O` and `:`, and the `o_v` and `o_V` motion-force prefixes. Keys bound to those actions keep showing "Not implemented".

Assumptions recorded here rather than asked:

- The foundation motions keep their `cursor.*` names, since the architecture's configuration example uses them and insert mode binds the arrow keys to them; the grammar treats both the `cursor.` and the `motion.` namespaces as motions.
- Count digits are read by the grammar before the keymap: `1` to `9` start a count and `0` to `9` extend one whenever no multi-key binding is in progress, so `0` stays the line-start motion when no count has been typed. Counts are not bindable, as in Neovim.
- The operator-pending keymap lists every motion again rather than falling back to the normal map, because the keymap specification says each mode is served by its own map and nothing else; a doubled operator is recognized when the operator-pending map resolves a key to the operator already pending, and any other operator or standalone action cancels the command, as Vim beeps on `yd`.
- Register names accepted in this change are `"`, `a` to `z`, and `A` to `Z`; any other name drops the register prefix and the keys after it start a new command, as they do after Vim's beep. Every delete, change, and yank writes the unnamed register, as in Vim, even though only `d y p P` were required to.
- `Y` yanks to the end of the line, following Neovim's default mapping rather than Vim's linewise `Y`. `startofline` is off, as in Neovim: `G`, `gg`, `H`, `M`, `L`, and linewise yanks keep the wanted column; `+`, `-`, `_`, and a linewise delete go to the first non-blank; `>` and `<` put the cursor on the first non-blank of the first shifted line; `cc` keeps the indent of the first line when `autoindent` is on.
- Vim's two exclusive-motion adjustments are implemented: an exclusive motion ending in column 0 of a later line ends at the end of the previous line inclusively, and becomes linewise when it started at or before the first non-blank; `w` under an operator stops at the end of the line when the last word moved over ends there, and `cw` on a non-blank character behaves as `ce`.
- Keyword characters for word motions are ASCII letters, digits, underscore, and every code point from U+00C0 upward; the `iskeyword` option arrives with the options change.
- Sentence boundaries are `.`, `!`, or `?` followed by optional closing `)`, `]`, `"`, or `'` and then a space, a tab, or the end of the line; an empty line is a paragraph boundary and therefore a sentence boundary. Lines containing only blanks are not paragraph boundaries, as in Vim.
- Quote objects work on the current line only and pair quotes from the start of the line; when the cursor is before the first quote the first quoted string after it is used. The counts `2i"` and `2i(` have no special meaning yet. An inner bracket object whose brackets stand alone at the ends of their lines becomes linewise over the lines between them.
- `H`, `M`, and `L` honor `scrolloff` when they move the cursor and ignore it under an operator, as Vim does; the window records its height at each render for them.
- `J` joins with Neovim's defaults: one space, none when the line ends in a blank or the next line starts with `)` or is empty, and `joinspaces` off.
- `p` leaves the cursor on the last character of single-line charwise text, on the first character of multi-line charwise text, and on the first non-blank of the first line of linewise text.

## Capabilities

### New Capabilities

- `command-grammar`: parsing register prefixes, counts, operators, doubled operators, motions, text objects, and character arguments into a command; operator-pending mode, cancelling, and the display of the keys typed so far.
- `motions`: every cursor motion of this change as a function from the state and a count to a target position, with its kind and inclusive flag, used for cursor movement and operator ranges.
- `text-objects`: the word, sentence, paragraph, bracket, and quote objects as ranges around the cursor.
- `operators`: `d c y > <` over ranges, the doubled forms, and the standalone editing commands `x s S C D Y J p P`, with the cursor and mode each leaves behind.
- `registers`: the unnamed register and the named registers with append, written by deletes and yanks and read by puts.

### Modified Capabilities

- `normal-mode`: the requirement that unimplemented actions report themselves is replaced by one with the same behavior whose scenario uses `u`, which undo implements later, instead of `dd`, which now deletes a line.

## Impact

- New entities under `carat/domain/`: `command.rb`, `command_grammar.rb`, `motions.rb`, `text_objects.rb`, `operators.rb`, `registers.rb`; `editor_state.rb` gains the registers, the grammar, and the last `f`/`t` search; `window.rb` records its height; `buffer.rb` gains read helpers for ranges.
- New use case `carat/use_cases/operate.rb`; `handle_key.rb`, `dispatcher.rb`, `move.rb`, and `editor_assembly.rb` change; `frame_presenter.rb` paints the pending command and records the window height.
- `config/default.json` and the generated `carat/domain/default_config.rb`; `carat.rb`'s require graph.
- Tests: `test/domain_grammar.rb`, `test/domain_registers.rb`, `test/editor_motions.rb`, `test/editor_text_objects.rb`, `test/editor_operators.rb`, `test/editor_registers.rb`, `test/editor_grammar.rb` with their snapshots; `test/editor_normal.rb` and `test/domain_keymap.rb` adjusted for the new bindings.
- Docs: `docs/compatibility.md`, `docs/actions.md`, `CLAUDE.md`, `README.md`.
- No new dependencies and no new ports.
