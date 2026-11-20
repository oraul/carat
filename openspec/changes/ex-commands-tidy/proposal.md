# Proposal

## Why

A binding that runs `:%normal` with its own key nests to the depth limit on every line of every level: E192 refuses only the innermost call, and each enclosing `:normal` goes on with its next line, so two lines already make 2 to the 100th runs and the editor hangs (vim-line-commands-c security Low (6)). Three substitute flaws sit beside it: `n` and `N` after `:s` with the `i` or `I` flag keep the flag's case instead of the options', `:s` with the refused `c` or `l` flag still keeps its string for the next `&`, and `Replacement.expand` inserts a group in two copies of the same block while `LastSubstitute` holds case and print as integer codes.

This is outside the roadmap of `docs/architecture.md` section 12: backlog item 1 of Sprint 22, the first part of the split ex-commands-tidy; part b (Pool 13, ex-commands-tidy-b) takes the other five headings.

## What Changes

- `:normal`: once a `:normal` is refused as too deep, every `:normal` running stops feeding its keys and lines, so a recursive binding over a range ends with E192 at once (`carat/use_cases/ex/normal_command_handler.rb`).
- `:s` with `i` or `I`: the last search pattern `n` and `N` repeat is compiled with the case options, as a typed search is; the flag applies to the substitute alone, as in Vim (`carat/use_cases/search/substitute_lines.rb`).
- `:s` with `c` or `l`: the refusal comes before the string is kept, so a refused command changes nothing a later `&`, `:&`, or `:s` reuses.
- `Replacement.expand`: one block inserts a group, `&` or `\0` to `\9`, read by a new `Replacement.group_at`; `recase` answers the text itself when nothing is recased, keeping the fast path that block had.
- `LastSubstitute`: `case_mode` is `:options`, `:ignore`, or `:match`, and `print` `:none`, `:line`, or `:number`, instead of 0, 1, and 2.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `line-commands`: adds `A :normal refused as too deep ends every :normal running`.
- `substitute`: `Wrong flags are refused` adds that a refused flag keeps no string; `A substitute is one undo step and sets the last search` adds that `n` and `N` read case from the options.

## Out of scope

- The five headings of part b: ex range arithmetic, patterns, and marks, ExRange's `given` member, OpenFile's two port calls, ResolveInside's check and act, and the two 64 MiB strings of `test/editor_cmdline.rb`.
- A budget of work across nested `:normal` commands that never reach the depth limit: a chain of distinct bindings a user wrote is run as Vim runs it.
- The `c` and `l` flags themselves stay refused. No `tools/rules.sh` edit; no file of the feature lane.

## Impact

- README.md: unchanged, it lists `:normal` and `:s` without their refusals or flag details.
- docs/architecture.md: unchanged, no layer, port, or module changes; the behavior is in the specs.
- docs/compatibility.md: the `:normal` row notes that E192 ends every `:normal` running.
- docs/codebase-map.md: unchanged, no file is added, moved, or removed.
- CLAUDE.md: unchanged, no process changes.
- Performance: `Replacement.expand` keeps its no-recase path free of a copy; `:s` with `i` or `I` compiles its pattern once more for the last search.
