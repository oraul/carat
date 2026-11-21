# Backlog: openspec/changes/archive/2026-11-06-periodic-review-caps/design.md

## The periodic review caps design names the wrong owner of the overrun notes

- Where: `openspec/changes/archive/2026-11-06-periodic-review-caps/design.md` line 20, against `.claude/workflows/periodic-review.js` lines 96 to 97 and `.claude/workflows/deliver-change.js`. Quality advisory of `periodic-review-caps`.
- Why it matters: the decision says the periodic result returns the cap and the delivery workflow notes overruns with its `overCap`, but the periodic workflow writes the overrun notes itself and returns `over`, and the delivery workflow only logs them, so the archived record misleads the next change to this code.
- Fix outline: add a note to the next change touching the periodic workflow's caps that corrects the decision (the archived design is not edited), or move the noting into the delivery workflow so the design holds.
- Also: .claude/workflows/periodic-review.js, .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-07
