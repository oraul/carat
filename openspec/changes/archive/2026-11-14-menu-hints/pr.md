feat(hints): center the key hints panel and name every group

## Summary

Shows the key hints as a panel centered at the bottom of the editor and names every prefix row by what its keys do, instead of a bottom-right float with a bare count. The float sat away from where the eye rests and an unnamed prefix read as `+N`, which said nothing about the keys under it; the change also clears four small faults in the hints code.

---

## Changes

- Change the key hints float to a horizontally centered panel standing on the row above the message row less the float margin, at show and after a resize
- Change an unnamed prefix row to show the first dotted action segment every binding under it shares, or `group` when they share none, instead of `+` and a count
- Add `Domain::Mode.grammar?` as the one grammar-mode test, read by `HandleKey` and `ShowKeyHints`
- Change `ShowKeyHints` to close a shown hints float through `HideKeyHints` instead of its own close
- Change `HandleKey#call` to ask `KeyHints#showing?` before hiding the hints, and build the default delay from `Options::KEYHINTS_DELAY`
- Add key hints tests for the centered placement, the resize, and the group names, with their snapshots
- Update the key-hints spec, the archived OpenSpec change, the README, the compatibility notes, and the code map
- Document six non-blocking review advisories in the backlog, and record the planner's queue and the metrics history

---

## Testing

- Run the security review of the committed diff, pass with no findings
- Run the quality review, pass with no blocking finding and six advisories recorded in the backlog
- Run the benchmark review, pass with no allocation or round regression
- Run the checker's stages (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass
- Run make spec-validate after the archive, all 51 items pass

---

## Notes

This is part a of queue item `menu-hints`; the palette rows, match spans, selected-row contrast, and the completion popup's padding follow as `palette-rows`. The guard against a screen under 6 columns in `ShowKeyHints` stays for `discoverability-tidy`.
