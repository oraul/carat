# Design

## The card in two places

The workflow script reads no file, so the card is a one-line constant `CONTRIBUTOR_CARD` in `deliver-change.js` and a block at the top of `contributor.md` (its header line through its tenth rule). `tools/tools_test.sh` extracts both and compares them byte for byte, so neither drifts. `contributorTask` appends it after the brief, detail, and self-check, so every mode's prompt (implement, fix, package, wait, push, moved, body) carries it and still starts with `Mode: ...`.

## Budget

contributor.md was 6,995 of 6,999 bytes. The card and the named checklist points are paid for by moving the push-mode conflict rules and the checklist's examples to `docs/contributor-notes.md`, which the agent reads when a push meets a conflict or before it self-checks. No rule is dropped and no budget is raised.

## Not done

Parts C and D of the widened brief (tier routing, high effort) are a separate change, `contributor-tier-routing`, since it edits the workflow's agent options and the run state.
