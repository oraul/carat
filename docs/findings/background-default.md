### Advisory-only rework rounds cost half of facet-palette's output
- Location: `.claude/workflows/deliver-change.js` (the rework loop after the first check pass); backlog queue item `rework-review-repeat`
- Why: facet-palette rework 2 with 0 blocking in all 3 quality and security reviews (5, 1, 0 advisories); output at the check passes 204,127, 332,067, 573,120 of 736,922, about 369,000 (50 percent) after the first pass; guide-colors advisory-only rework 1, +83,604 (facet-palette retro 10).
- Fix: an advisory-only round counts no rework and reruns only what its fix touched; accepted when the next 5 runs whose reviews block nothing record rework 0 and spend under 15 percent of their output after the first check pass. Fold into `rework-review-repeat`.

### A re-review re-raised an advisory declined for the brief's reason
- Location: `.claude/agents/quality-reviewer.md`, `.claude/workflows/deliver-change.js` (notes handed to a later round); facet-palette note 6 repeating note 1
- Why: the PANEL_DIM advisory, declined in round 1 because the brief pins #a4aabd / #5c6173, came back word for word; round 2 grew output from 332,067 to 573,120 (+241,053, 33 percent of 736,922); quality first pass 93/166 (facet-palette retro 11).
- Fix: an advisory declined with a recorded reason goes to the findings file, not to a new round; accepted when no run has a later-round advisory repeating a declined note that drives a round of its own. Fold into `rework-review-repeat`.

### facet-palette dropped the brief's PANEL_DIM
- Location: `carat/domain/themes.rb` (no PANEL_DIM role, no #a4aabd, at caf4532ac051; DIM 0x5c6173 at line 269)
- Why: facet-palette's brief pinned PANEL_DIM #a4aabd / #5c6173 and its acceptance asked theme rows pinning each value; round 2 removed it on a re-raised advisory (retro 11), so the merged palette misses a value the user's Facet plan named.
- Fix: restore the PANEL_DIM role on carat-dark and carat-light with the pinned values; accepted when theme rows pin both. Queued with `ui-groups`.

### The check and merge phases spend a third of a feature run's output waiting
- Location: `.claude/agents/checker.md`, `.claude/agents/merger.md`, `.claude/workflows/deliver-change.js:126` (mergerCap); backlog queue item `merge-output-cap`
- Why: facet-palette check 123,463 output in 6 calls (16.8 percent, 3 passes all green first), merge 101,948 in 13 calls (13.8 percent, ci_wait_calls 6), together 30.6 percent of output for 8.4 percent of calls; guide-colors merge 26,423 in 11 calls (facet-palette retro 12).
- Fix: the checker and merger read the stage and CI results the run state holds and generate little; accepted when check stays under 10,000 output per pass and merge under 30,000 over the next 5 feature runs with first passes unchanged. Fold into `merge-output-cap`.

### Background delta spec removes and re-adds the requirement instead of modifying it
- Location: openspec/changes/archive/2026-11-18-background-default/specs/color-themes/spec.md:1 (quality advisory, raised at openspec/changes/background-default/specs/color-themes/spec.md:1)
- Why: one clear way: the delta removes 'The background option chooses who paints the background' and adds a renamed copy repeating three of its four scenarios word for word, where only the default and one scenario changed, so the history reads as a new requirement rather than a changed default.
- Fix: a MODIFIED block under the existing header with the new default, the painted-by-default scenario in place of Transparent by default, and the two named-kept scenarios; the contributor tried a MODIFIED block in a scratch copy and openspec validate refused it for dropping 'Transparent by default' (design.md records it), so a follow-up first checks whether the validator allows a modified requirement to drop a scenario, else closes this finding.
