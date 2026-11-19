# Proposal

## Why

The mid-tier contributor trial's first deliveries showed two defects that reached main past the reviewers: a findings entry recorded in a fix round was dropped from its findings file, and a pull request body claimed command-line and message styling that the diff does not contain. Both are checked by nobody mechanically, only by trusting the contributor's word.

## What Changes

- A `findings` gate in `tools/gates.sh`, in `static` (so `make gates` and the push gates run it) and in `merge`: it fails when a `### ` heading under `docs/findings/` at the fork point of the base and HEAD, or in a commit of the branch added by a non-merge commit, is missing at HEAD (a merged main that groomed an entry passes; a moved main not yet merged is ignored). A `sprint-N-records` change, whose `groom` folds and prunes the findings, passes it.
- A pull request text review in `.claude/workflows/deliver-change.js`: after the package step pushes `pr.md`, a capped quality-reviewer start of the session model compares its Summary and Changes with the committed diff and the archived proposal's Out of scope. A claim not in the diff, or work the proposal moved out, blocks; the contributor's `body` mode rewrites `pr.md` and pushes it with the new `push --pr-text` kind, and the text is reviewed once more, a second block stopping the run.
- Tools-test cases for both, and the `findings` line in the gates' usage text, the Makefile `gates` description, and README.md.
- Two findings appended: the dropped `LineNrFifth` entry back in `docs/findings/cursor-and-messages.md`, and the claim of the squash body of #223 in `docs/findings/delivery-guards.md`.

Out of scope: the result contract (a contributor result whose head is not the lane's HEAD gets one restart) and the `self-check-mismatch` note, both queued as `delivery-guards-b`; any edit of `tools/rules.sh`.

Assumptions: the review of `pr.md` runs after the push because the package start writes `pr.md` and pushes in one start, so the rewrite is a `body`-mode start and a `--pr-text` push rather than a second package start, and the push is `--pr-text`; a review that returns no result is noted and does not stop the run.

- README.md: updated, the gates list names the append-only findings
- CLAUDE.md: unchanged, it is at its size budget and the gates list and the workflow phases it points to are described in the gate header and README.md
- docs/architecture.md: unchanged, it does not list the gates or the workflow's phases at this level

## Capabilities

### New Capabilities

None: pipeline tooling only (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`tools/gates.sh`, `tools/tools_test.sh`, `.claude/workflows/deliver-change.js`, `Makefile` (a description), `README.md`, `docs/findings/`.
