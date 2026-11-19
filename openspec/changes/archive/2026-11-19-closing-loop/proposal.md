# Proposal

## Why

About 94 findings were added and 10 removed overnight, roughly 7 per merge, most of them quality advisories each run leaves at the round limit, since a non-blocking finding never holds a merge. The user asked for one last contributor loop that closes the ones the run itself can close, as an exception beyond the sprint. Pipeline change, T1, outside the roadmap of `docs/architecture.md` section 12.

## What Changes

- `.claude/workflows/deliver-change.js` runs `closeAdvisories` once a run, after `verify` passes in the package step and before the package start: one contributor start in the new mode `close-advisories` is offered the advisories still open and fixes those in the change's own files that need no new behavior. When it commits, the check and the reviews run again through `verify`: the quality review scoped to the commits since its pass, the security review at once unless the commit changed only records (the existing settle path). Advisories that round raises are recorded for the findings file, never offered again; a blocking finding goes through the normal fix rounds. A run with no open advisory skips the loop.
- The loop is not a rework round: its figures `advisories_closed` and `advisories_left` are metric lines of the run state, and `tools/run_state.sh history` writes them as two columns after `weighted_phases`; older rows hold none.
- `.claude/agents/contributor.md` names the mode; `docs/contributor-notes.md` holds its rules (Closing).
- `tools/tools_test.sh` proves the one closing start with its re-review and figures, the skip, the absent second loop, the security review of a code-changing commit, and the history columns.

Out of scope: the related pool items `rework-review-repeat`, `advisory-findings-auto`, and `package-no-fix`, to be rechecked against the recorded figures; any edit of `tools/rules.sh`; any budget raise.

Assumptions: the user's "as exception" means beyond the sprint size, so the queue's exception line stays after delivery. The contributor decides from the files the change edits which advisories qualify, since the workflow holds only the findings' text. The existing history files keep their 22-column header; new rows carry 24 fields.

- README.md: updated, the round-limit step names the closing loop and its figures
- docs/architecture.md: unchanged, no layer, port, or roadmap change; the pipeline is described in README.md
- CLAUDE.md: unchanged, 30,713 of 30,720 bytes leaves no room, and its Agents section already names fixing own-file findings in place; the closing loop is described in README.md and `docs/contributor-notes.md`

## Capabilities

### New Capabilities

None: pipeline only (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

`.claude/workflows/deliver-change.js`, `.claude/agents/contributor.md`, `docs/contributor-notes.md`, `docs/codebase-map.md`, `README.md`, `tools/run_state.sh`, `tools/tools_test.sh`.
