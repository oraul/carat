## Why

Carat has no `:s`, `:&`, `&`, or `g&`, and its ex grammar reads no range, so `:%s/a/b/g` and `:'<,'>s/x/y/` answer E492 (`docs/backlog.md` "The ex grammar parses no ranges"). This change delivers the substitute part of roadmap item 6, `search-and-substitute` (`docs/architecture.md` section 12), after `buffer-search` delivered the search part; the planner split the item by the size rule, so `:g`, `:g!`, and `:v` follow as `buffer-global`.

## What Changes

- The ex grammar reads a range before the command name: `%`, `.`, `$`, a line number, and the marks `'<` and `'>` of the last visual selection, one address or two joined by `,`. A range out of the buffer is `E16: Invalid range`, a backwards one `E493: Backwards range given`, `'<` with no selection `E20: Mark not set`, a range on a command that takes none `E481: No range allowed`, and an address Carat does not read yet (`+`, `-`, `;`, a pattern, another mark) `Not implemented: range x`.
- A range with no command moves the cursor to its last line, keeping the column as `G` does (`:12`, `:$`), where a bare number answered E492 before.
- `:` in the visual modes leaves the mode and opens the command line holding `'<,'>`.
- `:[range]s[ubstitute]/{pattern}/{string}/[flags] [count]` replaces matches line by line: the first in each line, or all with `g`; any ASCII delimiter that is not a letter, a digit, `\`, `"`, or `|`; an empty pattern uses the last search pattern; `:s [flags] [count]` and `:[range]&[&]` repeat the last substitute, `&&` keeping its flags.
- Flags `&`, `e`, `g`, `i`, `I`, `n`, `r`, `p`, and `#` as in Vim; `c` and `l` answer Not implemented. A trailing count runs from the range's last line.
- The replacement's special characters: `&` and `\0` (the match), `\1` to `\9` (the groups `\(\)` capture), `~` (the previous replacement), `\u`, `\U`, `\l`, `\L`, `\e`, `\E` (case), `\r` (a line break), `\t`, `\\`, `\&`, `\~`, and any other escaped character as itself; `\=` and `\n` answer Not implemented. `~` in a substitute pattern matches the previous replacement.
- `&` repeats the last substitute on the current line without its flags, on count lines with a count; `g&` repeats it on every line with its flags and the last search pattern.
- Vim's messages: `N substitutions on M lines` above two substitutions, `N matches on M lines` with `n`, `E486: Pattern not found: pat` (not with `e`), `E33: No previous substitute regular expression`, `E35: No previous regular expression`, `E146`, `E488: Trailing characters`, and `E939: Positive count required`.
- A substitute is one undo step, is not repeated by `.` (as in Vim), leaves the cursor on the first non-blank of the last line it changed, and makes its pattern the last search pattern, the `/` register, and a search history entry, showing its matches again under `hlsearch`.
- Patterns go through the search translation and its size cap, and every line's scan and every replacement's text are charged to one work budget per command; when it runs out the command changes nothing and reports `E363`, so no pattern or replacement can crash or hang the editor.

## Capabilities

### New Capabilities

- `substitute`: the substitute commands `:s`, `:&`, `&`, and `g&`: their pattern and replacement syntax, flags, counts, messages, memory of the last substitute, undo, and the bounds on untrusted patterns and replacements.

### Modified Capabilities

- `command-line-mode`: the ex grammar reads ranges, a range alone moves the cursor, a range on a command that takes none is refused, and `:` in a visual mode opens the command line with `'<,'>`.

## Impact

- Domain: `ExCommand` gains `range`; `ExGrammar` reads the range and the `&` name; new `ExRange` (resolution), `SubstituteArgs` (the parsed arguments), `LastSubstitute` (the memory), `Replacement` (the replacement string), and `Substitution` (one line under the budget); `VimPattern` gains a substitute mode with capturing groups and `~`.
- Use cases: new `SubstituteLines`, `SubstituteCommandHandler` (`:s`, `:&`), and `SubstituteHandler` (`&`, `g&`); `ExecuteEx` resolves ranges and moves the cursor for a bare range; `ExHandler` gains `ranged?`; `EnterCommandLine` prefills `'<,'>` from a visual mode.
- Adapters: `EditorAssembly` builds `LastSubstitute` and the new use case and handlers.
- Configuration: `&` and `g&` in the normal map and `:` in the three visual maps of `config/default.caratrc`, regenerated with `make gen-config`.
- Docs: `docs/compatibility.md`, `docs/actions.md`, `docs/codebase-map.md`, `docs/backlog.md`, `docs/queue.md`, `README.md`, and the status line of `CLAUDE.md`.
- Out of scope: `:g`, `:g!`, and `:v` (`buffer-global`, next); the `c` confirm and `l` list flags; `\=` expressions; `\n` in a replacement; addresses with `+`, `-`, `;`, a pattern, or a mark other than `'<` and `'>`; a count before `:`; `:~`; command chaining with `|`; `~` in a `/` or `?` pattern, which still answers E33 (recorded in `docs/backlog.md`).
- Assumptions: a backwards range is refused with E493 rather than asking to swap, since Carat has no confirmation prompt; the `report` option is fixed at Vim's default 2; when the work budget runs out nothing is changed, where Vim, which has no budget, would have changed the lines before an interrupt.
