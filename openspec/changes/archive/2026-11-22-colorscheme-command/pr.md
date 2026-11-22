feat(ex): switch the palette at once with :colorscheme

## Summary

Adds `:colo[rscheme]` and lets `:set theme=` and `:set background=` take a value, so the palette switches at once and every highlight group is repainted in the new colors at the terminal's depth. A theme change used to need a restart, since the palette was read once at startup and both options answered Not implemented.

---

## Changes

- Add the `:colo[rscheme] [name]` ex command: a shipped name switches the palette at once, another name answers `E185: Cannot find color scheme 'name'` and keeps the palette, and no name shows the current one
- Change `:set` so `theme` and `background` (`bg`) are word options like `winborder`, with `?`, the bare name, `&`, and `E474` for a value the configuration would refuse, a change repainting at once
- Change the screen presenter to rebuild its color table and draw the next frame in full when the options name another palette or background than the one it was built with
- Add Tab completion of the shipped palette names after `:colorscheme`, in their shipped order
- Add a table-driven test of each shipped name, an unknown name, no name, and both `:set` forms, checking the frame's groups repainted, and extend the screen presenter, completion, set options, and syntax tests
- Update the color-themes, set-command, syntax-highlighting, and command-line-mode specs and archive the change
- Document the `:colo[rscheme]` row, the `:set` word row, and the Themes paragraph in docs/compatibility.md, the options and colors sections of the README, the roadmap and screen lines of docs/architecture.md, and docs/codebase-map.md
- Record the planned queue, the metrics history row, and the plan's findings for this lane

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low finding
- Run the check stages at the implementation head (dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, docs-lint, metrics), all pass
- Run the benchmark review against main's recorded figures, pass with nothing blocking
- Run the quality review of the diff, four findings, all four fixed
- Run make spec-validate after the archive, all 56 specs pass
- Run make gates and make docs-lint before the push, both pass

---

## Notes

A bang on `:colorscheme` is ignored as `:syntax` ignores it, where Neovim refuses it with E477; this is recorded as a difference in docs/compatibility.md. Carat's `background` keeps its own words, theme and terminal, rather than Neovim's dark and light. Tab completes the names after `:colorscheme` only, not after `:set theme=`. User themes, `:highlight`, and the ColorScheme event are out of scope.
