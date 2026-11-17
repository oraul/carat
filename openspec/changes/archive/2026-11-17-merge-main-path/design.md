# Design

## Context

The merge loop (`.claude/workflows/deliver-change.js`, the Merge phase) stops on any green result that did not merge (`not merged: PROBLEM`). `push_branch` allows one push plus one per CI fix (needs `ci` red) and one review fix (a resume past the push); `gate_pushes` in `tools/gates.sh`, which main's merge gates run, holds the same rule. `merge_main` already merges a moved `origin/main`, keeps the appended records by union, and on another conflict aborts and names the files.

## Decisions

- The merger says why: a new `main_moved` boolean in the MERGE schema, true when the pull request conflicts with main or GitHub refuses the merge because the branch is behind main or conflicts with it. The `problem` text alone was the only channel and is free prose.
- One path, `mainMoved(m, used)`: on CI green, not merged, `main_moved`, and no main-moved push yet (the run state's `main_moved` plus this start's), a `moved` contributor start runs `merge-main` (the `movedTask` prompt), `verify()` reruns the check and whatever blocks takes the usual fix rounds, then a `push` start pushes with `--main-moved` and the loop continues to CI and the merge. It costs no fix round (`rework` counts `fix` starts only). A second refusal stops with its reason; a red CI with `main_moved` goes to the CI fix loop, whose fix start already runs `merge-main` first.
- The reviews rerun only when the merge changed files of the change. The workflow cannot run git, so the checker, which never edits, runs `tools/run_state.sh moved CHANGE COMMIT` once the check passed and returns its line verbatim (`moved` in CHECK). COMMIT is the commit both of this start's reviews passed at (`carryFrom`); the files of the change are those it touches at COMMIT or at HEAD against their merge bases with `origin/main`, outside the records-only paths (`RECORDS_RE`), and the merge changed one when `git diff COMMIT HEAD` names it. On the same-change line (`carried`, naming the head and COMMIT) the workflow records both reviews passed at the head (summary `blocking=0 carried=1`), which the merge gates read like any pass; otherwise `reviews()` finds no pass at the head and runs them. The comparison waits for the check's pass, so a fix round after the merge is compared too. A resumed start never carries: `carryFrom` reads only this start's records.
- `push --main-moved` needs a recorded push other than HEAD that does not hold BASE (`origin/main`) and a HEAD that does, so it pushes only a merge of a main that moved past the pushed head; counted as `main_moved`, written only when used, so a run state written before reads 0 in `count` and in `gate_pushes` (`${moved:-0}`).
- `first.ci` needs no change: `verdict` keeps the first result, the green before the move; a case proves it.
- An unresolvable conflict: `merge_main` names the files and exits 1; the `moved` start returns `stopped` with the question naming each file where both sides changed the same logic, which `contributor()` turns into the run's stop.

## Risks

- Main's workflow and gates judge this run and lack the path; until it merges a moved main still stops a run.
- Carrying the reviews trusts the checker's verbatim line as it trusts its check verdict.
