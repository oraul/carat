# Proposal

## Why

Neovim's case operators `g~`, `gu`, and `gU` are missing in normal mode: only the single-character `~` and the visual `~ u U` change case, so a word, a text object, or a counted range cannot be recased with an operator, and the Neovim grammar `[count] operator [count] motion` has three holes. This is the user's order of 2026-11-19 (queue item 1 of Sprint 22, feature lane); it is outside the numbered roadmap of `docs/architecture.md` section 12, which closed, and extends the delivered `command-grammar` and `visual-modes` items.

## What Changes

- Three pending operators, `operator.swap_case` (`g~`), `operator.lowercase` (`gu`), and `operator.uppercase` (`gU`), bound in normal, operator_pending, visual, visual_line, and visual_block by keymap lines in `config/default.caratrc` (mirrored by `make gen-config`). In operator_pending the doubled forms are `g~~ g~g~`, `guu gugu`, and `gUU gUgU`, so `~`, `u`, and `U` are bound there too.
- `OperatorHandler` registers the three names; in normal mode `Operate` applies them over a motion, a text object, or `count` lines through the new `Operators.recase_range`, writing no register, the cursor going to the start of the range as after a yank; in a visual mode they act on the selection at once through `RecaseSelection`, as `~ u U` do.
- `Operators.recase` changes each letter by itself, as Neovim's simple case mapping does: `ß` stays under toggle and lower and becomes `SS` under upper, `İ` becomes `i` when lowered, a letter whose case form is several characters (a ligature) stays, and a final sigma lowers as `σ`. It serves `~` and the visual `~ u U` too, so they now match Neovim for those letters.
- Docs: `docs/compatibility.md` rows and its differences sentence, `docs/actions.md` rows, the code map, the README's operator list, and the `CLAUDE.md` wording that the visual modes complete "the five operators" at once.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `operators`: ADDED requirement "Case operators".

## Out of scope

- `g?` (rot13), `=`, `gq`, and `tildeop`; `X`.
- Changing the visual `~ u U` bindings, which stay `visual.*` actions; `g~ gu gU` in a visual mode are the operator actions, which share their use case.
- No `tools/rules.sh` edit; no file of the backlog lane.
- Assumption: the brief's "~ u U in the 5 visual modes" is read as the five binding modes of CLAUDE.md, since `~ u U` already work in the three visual modes; the tests cover them in all three, with multibyte letters.

## Impact

- README.md: changed, the operator list names `g~ gu gU`.
- docs/architecture.md: unchanged, no section names the operator set or the case functions; the roadmap is closed.
- CLAUDE.md: changed, one word: the visual modes complete the operators at once, no longer "the five".
- docs/codebase-map.md: area 7 (eight operators, `recase_range`, `recase_letter`, the new test).
- docs/compatibility.md and docs/actions.md: the rows and the differences sentence.
- Performance: no hot path changes; `recase` of ASCII text keeps the whole-string call, so only text with multibyte characters takes the per-letter path.
