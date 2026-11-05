# Proposal

## Why

`CLAUDE.md` is at 30,682 of its 30,720-byte budget (38 bytes left) and `docs/architecture.md` at 88,054 of 88,064 (10 left), so the next change that must keep either in sync with the code fails `make docs-lint` or pays for a trim it did not plan; the periodic quality review at eb0f1be made this blocking, and the item was pushed back 5 times. Both documents have also drifted: section 5.1 names a `Substitute` use case that is `SubstituteLines` and omits `DeleteLines` and the other use cases added since; two Git rules lost "explicitly" in an earlier trim; the `run_state.sh` bullet of `CLAUDE.md` says `restore` checks out the backup (it only creates the branch) and does not name `abandon` (periodic quality blocking at d386c74, `CLAUDE.md` line 233). `CLAUDE.md` is read at every agent start, so its bytes are paid in every run. This is item 1 of `docs/queue.md`, outside the editor roadmap of `docs/architecture.md` section 12: it changes documents only.

## What Changes

- `CLAUDE.md` drops to at most 27,648 bytes by moving reference detail out, never by changing a rule: the Commands bullets keep every target's name and every rule (bump the pin in its own pull request, `make diagnose` must be clean, a test without a snapshot fails), and leave each target's description and variables to `make help`; the `sh tools/run_state.sh` bullet points to the script's header, which lists every command, and keeps the commands the rules name. The rest comes from detail that lives in `docs/architecture.md` or the map (the Layout list, the Status line's roadmap items, the `lint` detail of the use case rule) and a few descriptive clauses (design.md lists them).
- `CLAUDE.md` says `restore BRANCH` recreates a missing branch from its backup and names `abandon CHANGE`, which deletes a stopped run's backup refs.
- The Git workflow rule and the Pull requests rule read "unless explicitly asked" again.
- `docs/architecture.md` frees at least 1,000 bytes: section 11 keeps the repository's directory tree and points to `docs/codebase-map.md`, which places every file, for the per-file lists of the layers.
- Section 5.1 names `SubstituteLines` instead of `Substitute` and adds the use cases it omits: `DeleteLines`, `OpenSearchPrompt`, `PreviewSearch`, and `RecallHistory`; section 5.3 adds `ScrollWindow`.
- The planner's bookkeeping in `docs/backlog.md`: the four entries this change fixes are removed; the seven entries of `build/plan/backlog.md` are added (among them the refused backup push, the user's decision recorded as a backlog entry rather than a change); the secret-pattern and binary-file entries are queued in `content-gate-gaps` and the close-note entry in `backup-records`; the delivered-changes entry is restated with the current gaps; the review-area entry names the backlog-items change instead of an item number. The `start-screen` decision is in the planner's queue, which the package step commits.

Assumption: the queue's acceptance ("`CLAUDE.md` at most 27,648") is met under the unchanged budgets of `tools/docs_lint.sh`; no budget is raised or lowered.

Out of scope: any change to a rule's meaning, to code, to the budgets, and the other drifts the quality reviews recorded (the README's targets and keys and the delivered-changes list, queued in `docs-index`).

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the change touches documents only and no editor behavior, so it sets `skip_specs: true`.

## Impact

- `CLAUDE.md` (Project, Git workflow, Pull requests, Agents, Stack, Commands, Layout, Coding conventions), `.claude/workflows/deliver-change.js` (the agent tier rule in its header), `README.md` (the same rule beside the pipeline), `docs/architecture.md` (sections 5.1, 5.3, and 11), `docs/backlog.md`; `docs/queue.md` and `docs/metrics.tsv` at the package step.
