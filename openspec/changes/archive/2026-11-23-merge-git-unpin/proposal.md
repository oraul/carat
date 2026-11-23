# Proposal

## Why

Deliveries stalled around the merge of a moved main. Two causes: `merge_main` ran its merge, queue checkout, add, commit, and abort through the pinned git that #328 added, and a conflict where both sides changed the same logic ended the main-moved start (and the rule text the implement and fix starts follow) in a stop. The user asks to remove the pinned git only, and to send every conflict the merge meets to the contributor to fix.

## What Changes

- Change `tools/run_state.sh`: `merge_main` runs its merge, queue checkout, add, commit, and abort with plain git; its fetch and the check clone keep `pinned_git`. The conflict message no longer offers a stop, and the `merge-main` header says only the fetch is pinned.
- Change `.claude/workflows/deliver-change.js`: the main-moved start's task has the contributor resolve every conflict, the same-logic case included, and commit the merge, without stopping to ask; the workflow then checks again, reviews when the change's files changed, and makes the one main-moved push, as before.
- Change `docs/contributor-notes.md` (Conflicts with main), the rules the implement, fix, push, and moved starts follow, and `README.md`: a conflict where both sides changed the same logic is resolved by the contributor, never a stop.
- Change `tools/tools_test.sh`: remove the two hook cases of #328 (merge-main past a global hooks path and a repository hook, and that neither hook ran); add a case that `merge_main` names `pinned_git` only on its fetch, and one that the main-moved start's task has no stop for a same-logic conflict (replacing the case that required it).
- Record the reopened finding (merge_main runs git with global configuration and hooks again) in `docs/findings/merge-git-unpin.md`.

Assumptions: the user's decision lifts #328's hook pin on `merge_main` only, so the finding is recorded, not fixed; the record step's runner, ci-stages, and the rest of #328 stay; `.claude/agents/contributor.md` needs no edit, it points to the conflict rules in `docs/contributor-notes.md`.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Code: `tools/run_state.sh`, `.claude/workflows/deliver-change.js`.
- Tests: `tools/tools_test.sh`.
- Docs: `docs/contributor-notes.md`, README.md (the conflict rules and the main-moved path).
- docs/architecture.md: unchanged, no spec changed and it does not describe the merge of main.
- docs/codebase-map.md: unchanged, no file added, moved, or removed, and its merge_main entry does not name the pin.
- CLAUDE.md: unchanged, it names `merge-main` without the pin or the same-logic stop.
- No edit of `tools/rules.sh`.
