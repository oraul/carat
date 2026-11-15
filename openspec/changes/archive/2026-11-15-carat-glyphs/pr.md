feat(icons): default to unicode and draw ascii separators

## Summary

Makes unicode the default icon set and draws the window separators and the progress bar in plain ASCII under option.icons ascii. The nerd default showed boxes on any terminal without a Nerd Font, and the ascii set still drew box drawing separators and progress cells, so neither default nor fallback worked on a plain terminal.

---

## Changes

- Change the default of option.icons to unicode in config/default.caratrc, its generated mirror, a fresh Options, and the unknown-set fallback of Icons.glyph, keeping nerd selectable by a configuration line
- Change the window separators to a pipe between side-by-side windows and a hyphen under stacked windows when option.icons is ascii
- Change the progress bar to hash marks for done cells and hyphens for the rest when option.icons is ascii, keeping the StatusLineLspReady group unless NO_COLOR is set
- Add a table-driven test that every glyph of the default set is one character, one cell wide, and outside the private use areas
- Add a test that draws a frame under option.icons ascii with both splits, two tabs, a modified buffer, and a progress bar, and finds no byte above 127
- Update the tests and snapshots whose expectations held a nerd glyph under the default configuration
- Document unicode as the default and the ascii separators and progress bar in the README, the default configuration comments, and docs/plugins.md
- Archive the OpenSpec change and sync the icons, screen-rendering, and status-bar specs

---

## Testing

- Run the security review of the committed diff, pass with no high, medium, or low findings
- Run the quality review, pass with no blocking findings and two advisories recorded in docs/backlog.md
- Run the checker stages docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, and gates, all pass
- Run the benchmark comparison against the recorded main figures, pass with no added allocations or rounds
- Run make spec-validate after the archive, all 51 items pass

---

## Notes

The unknown-set fallback of Icons.glyph now reads unicode so it agrees with the default; the option itself still refuses an unknown set. NO_COLOR alone keeps the box drawing separators as before. This change also commits the planner's queue and the metrics row of the previous merged change.
