# Design

## Context

#328 pinned git (no global or system configuration, no hook) on every git call of `merge_main`, and the conflict rules let a contributor stop where both sides changed the same logic. Deliveries stalled at the merge of a moved main.

## Goals / Non-Goals

**Goals:**
- `merge_main`'s merge, checkout, add, commit, and abort run with plain git.
- Every conflict goes to the contributor to resolve and commit; the delivery goes on.

**Non-Goals:**
- Changing the fetch's pin, the check clone's pinned git, the record step's runner, or ci-stages.

## Decisions

- Only the calls after the fetch change; `pinned_git` stays defined, since the fetch and the check clone use it.
- The stop is removed where it is stated: the conflict message of `merge_main`, the main-moved start's task, and the conflict rules of `docs/contributor-notes.md` with the README paragraph repeating them. The implement and fix starts reach the same rule through their merge-main step, so no workflow change is needed there.
- The reopened hook finding is recorded rather than fixed: it is the user's decision.
