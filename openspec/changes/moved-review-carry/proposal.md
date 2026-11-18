# Proposal

## Why

After a merge of a moved main, `tools/run_state.sh moved` decides whether the quality and security reviews carry to the merged head, and it can say "the change is the same" when it is not (security Medium, found in merge-main-path, #198). It compares only the change's own files from the reviewed commit to HEAD, so a merge that puts a main-only file back to its old text, undoing a landed security fix, carries both reviews. The file names reach `git diff -- FILES` as pathspecs, so a file named `:(exclude)carat` empties the comparison, and a failing `git diff` leaves the list of changed files empty, which also carries. The workflow records the carried reviews when the checker's returned `moved` text matches a regex; nothing in the shell checks that `moved` exited 0.

## What Changes

- `tools/run_state.sh` `moved`: the reviews stand only when no file of the change changed from the reviewed commit to HEAD and HEAD matches the new main in every file the reviewed change never touched (outside the records-only paths, as before); a file HEAD differs from main in that the change never touched prints `moved: HEAD differs from BASE in files the change never touched: FILES; the reviews run again at HEAD` and exits 1. The names are compared as text, never passed to git as pathspecs, and a failing `git diff` prints `moved: git diff failed ...; the reviews run again` and exits 1.
- `moved` drops the run state's `moved` record when it starts and writes `moved` = "HEAD COMMIT" (full shas) only on its exit-0 path; `set` refuses the `moved` key.
- `review CHANGE KIND RESULT SUMMARY COMMIT` refuses a summary carrying `carried=1` unless the run state's `moved` record names COMMIT as its head, so a carried review is recorded only after `moved` exited 0 at that head, whatever line the checker returned.
- `.claude/workflows/deliver-change.js`: comments of `carried` and `carryReviews` say the shell backs the carry; the behavior is unchanged (a matching line still decides whether the reviews run again, and the record now needs the `moved` record).
- `tools/tools_test.sh`: cases for a merge reverting a main-only file, a `:(exclude)carat` file name, and a failing `git diff`, each exiting 1 with no `moved` record and a carried review refused; a carried review recorded after `moved` exits 0; `set` refusing `moved`.

Out of scope: the narrowed re-review after a main-moved merge (merge-main-path quality note 3, recorded in its findings); the merge gates (`tools/gates.sh`) and `tools/rules.sh`, which this change does not edit; main's workflow and gates judge this run as they are.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None: the merge loop and the run state are the delivery pipeline's, which no spec under `openspec/specs/` describes (`skip_specs: true`).

## Impact

- `tools/run_state.sh`, `.claude/workflows/deliver-change.js`, `tools/tools_test.sh`.
- README.md: changed, the main-moved paragraph says what `moved` compares and that the shell backs a carried review.
- docs/codebase-map.md: changed, the `run_state.sh` entry names the `moved` record and `set` refusing it; no file is added, moved, or removed.
- CLAUDE.md: unchanged, it does not describe how the reviews carry after a main-moved merge (README.md does).
- docs/architecture.md: unchanged, it does not describe the merge loop or the run state's records.
- docs/compatibility.md and docs/actions.md: unchanged, no editor behavior.
- `tools/rules.sh`: not edited.

Outside the roadmap of `docs/architecture.md` section 12: a T0 security fix of the delivery pipeline, before sprint-16's records change.
