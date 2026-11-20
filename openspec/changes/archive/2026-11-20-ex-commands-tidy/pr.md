fix(ex): stop a too-deep :normal and fix the substitute flags

## Summary

Stops every running `:normal` once one is refused as too deep, and fixes three substitute flaws: `n` and `N` after `:s` with `i` or `I` now take case from the options, a refused `c` or `l` flag keeps no string for a later `&`, and a replacement group is inserted by one block. A binding running `:%normal` with its own key nested to the depth limit on every line of every level, since E192 refused only the innermost call, so two lines already meant 2 to the 100th runs and the editor hung (security Low (6)).

---

## Changes

- Fix `:normal` so an E192 refusal stops every enclosing `:normal` from feeding its remaining keys and lines, the flag cleared by the outermost call, so a recursive binding over a range ends at once with E192.
- Fix `:s` with `c` or `l` to refuse before the pattern and replacement are kept, so a refused command changes nothing a later `&`, `:&`, or `:s` reuses.
- Fix `:s` with `i` or `I` to compile the last search pattern under the case options, so the flag applies to that substitute alone as in Vim.
- Refactor `Replacement.expand` to insert `&` and `\0` to `\9` through one block read by a new `Replacement.group_at`, called only at an ampersand or backslash, with `recase` returning its text unchanged when nothing is recased.
- Change `LastSubstitute` to hold `case_mode` as `:options`, `:ignore`, or `:match` and `print` as `:none`, `:line`, or `:number` instead of integer codes.
- Add tests for the recursive `:normal` stop, the refused flags keeping no string, `n` and `N` after the case flags, `group_at`, and the symbol flags, with their snapshots.
- Document the `:normal` stop in `docs/compatibility.md`, the `i`, `I`, `c`, and `l` flags in README.md, and the new scenarios in the line-commands and substitute specs, with the archived OpenSpec change.
- Record the backlog lane's plan, its metrics row, and one quality advisory in `docs/findings/ex-commands-tidy.md`.

---

## Testing

- Run the security review of the committed diff, pass with no High, Medium, or Low finding.
- Run the quality review, pass with no blocking finding and one advisory, recorded in the findings file.
- Run the checker's stages at the reviewed head (docs-lint, dev-build, test-build, diagnose, bench-budget, tools-test, test-run, gates, metrics), all pass.
- Run the benchmark review against main's recorded figures, pass with no blocking finding.
- Run make spec-validate after the archive, 54 passed and 0 failed.

---

## Notes

This is the first part of the split ex-commands-tidy; ex-commands-tidy-b in the backlog pool takes the rest: ex range arithmetic, patterns, and marks, the ExRange member no caller reads, OpenFile's two port calls, the containment check and act of ResolveInside, and the two 64 MiB strings of the command-line test. The `c` and `l` flags stay refused, and a chain of distinct bindings that never reaches the depth limit still runs as Vim runs it.
