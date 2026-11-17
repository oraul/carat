# Design

## Context

See proposal.md, Why. The workflow script cannot run git or the shell: it builds command lines of fixed words and commits, which an agent runs exactly as given. In the merge loop it takes the merger's `sha` as the merged commit for `state.merged`, the merge phase line, the close's `closeAt`, and the close prompt. `tools/run_state.sh` (`merged_at`, since merge-record-check) refuses a merge phase other than the pull request's squash commit, which is right, but the close's record line joins every line with `&&`, so the refusal also drops the retro and report phases and the metric line. The merger's step 7 writes `merged` through the same check, so the run state's `merged` already holds the squash commit when the merger returns a wrong sha.

## Goals / Non-Goals

Goals: the merge, retro, and report phases are recorded at the squash commit whatever sha the merger returned, a disagreement noted with both values; a refused close record line costs only itself, reported with its refusal.

Non-Goals: rewriting old records; the pre-push `flush()`; a new writer of `merged`; `tools/rules.sh`.

## Decisions

- The squash commit is resolved where git runs: `tools/run_state.sh phase` accepts the word `merged` in place of a commit for `merge`, `retro`, and `report` (`squash_of_change`). With `pr` recorded, it is `squash_commit PR`, and a recorded `merged` must resolve to the same commit, else the phase is refused naming both; without `pr`, the recorded `merged` checked by `merged_at`; with neither, refused. The workflow names no agent's sha in a phase line any more. merge-record-check rejected letting `phase merge` find the squash commit itself, so that a mismatch stops naming both values; this brief asks the opposite (record the squash commit, note the mismatch), and the explicit-commit form keeps its refusal for a hand-run record.
- The disagreement note is written by `phase` itself: `phase CHANGE merge merged REPORTED` adds a `merge-disagreement` note, "the merged commit reported, REPORTED, is not the squash commit on main, SQUASH, recorded instead", when REPORTED does not resolve to the squash commit, since only the script knows the squash commit. The workflow passes the merger's sha as REPORTED when it is 7 to 40 hexadecimal digits, and notes the sha it was given beside "recorded at the run state's squash commit".
- `state.merged` in the workflow becomes the word `merged` on a merge in this start (a resume keeps the run state's commit, also resolved through the word), and `closeAt` is the word whenever the change merged, so the retro and report phase lines name it too. `queue` accepts the word as a commit and `CLOSABLE` accepts `phase CHANGE (merge|retro|report) merged` and `phase CHANGE merge merged COMMIT`; the guard's close profile accepts the same forms, nothing else.
- The close's lines are built by `closeLines(looking)` (the closable queued lines, this start's own phase lines, the metric line) and joined by `recordLine(lines)`: each `LINE || echo refused: N`, joined with `; `. Every line runs; a refused one prints its refusal (each run_state refusal names its command) and `refused: N`. `echo` is a form of every guard profile and `||` and `;` are operators the guard reads. The line now always exits 0, so `recorded` is defined as no `refused: N` printed, and the close returns `refused`, the positions, which the workflow maps back to their lines in one note with `record_output`.
- A late-finding note queued after the merge phase stays refused when `merged` names no commit on main, but now costs only itself.
- sprint-planning.js needs no change: its records change runs through deliver-change.js's close, and its report line already reads `get <records> merged`.

## Risks / Trade-offs

- The close agent reports the refused positions; a misreported list affects only the note, never the records, which run_state wrote or refused itself.
- A merger that returns no sha while merging still gets the phases recorded at the squash commit, with no disagreement note.
