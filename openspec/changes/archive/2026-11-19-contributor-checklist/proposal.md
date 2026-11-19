# Proposal

## Why

Quality fails first on 78 of 176 runs, from findings a checklist catches (a stale test expectation, an untested raise branch, an unhandled edge case), and the contributor now runs on the mid tier, which forgets rules buried in a long agent file. A short rules card at the top of the agent file, repeated verbatim in every start's prompt, and an edge-case checklist with a self-review of the diff against the quality reviewer's instructions keep the rules in front of it. Pipeline change, T1, outside the roadmap of `docs/architecture.md` section 12.

## What Changes

- `.claude/agents/contributor.md` opens with a ten-rule card, and its implement self-check names the edge cases, the test per behavior change, the helper search, the comment, doc, and spec match, and the self-review with `.claude/agents/quality-reviewer.md`.
- `.claude/workflows/deliver-change.js` appends the same card, byte for byte, to every contributor start's prompt (`CONTRIBUTOR_CARD` in `contributorTask`).
- `docs/contributor-notes.md` holds the prose moved out of contributor.md (the push-mode conflict rules) and the edge-case checklist with its points; the code map places it.
- `tools/tools_test.sh` proves the card is identical in the agent file and in every mode's prompt, and that the self-check names each point.

Out of scope: tier routing for critical places and the high effort for the mid tier (queued as `contributor-tier-routing`); making rules 1, 2, and 7 mechanical (`delivery-guards-b`, `contributor-checklist-b`); any edit of `tools/rules.sh`; any budget raise.

Assumptions: the card lives in both files and a test keeps them equal, since the workflow reads no file.

- README.md: updated, the contributor step names the rules card and the checklist
- docs/architecture.md: unchanged, no layer, port, or roadmap change
- CLAUDE.md: unchanged, its Agents section already describes the contributor's self-check; the card repeats its hard rules

## Capabilities

### New Capabilities

None: pipeline text only (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/agents/contributor.md`, `.claude/workflows/deliver-change.js`, `docs/contributor-notes.md`, `docs/codebase-map.md`, `tools/tools_test.sh`.
