# Design

## Context

`moved_change` (`tools/run_state.sh`) took the files of the change as the union of `git diff --name-only OLD_BASE COMMIT` and `git diff --name-only NEW_BASE HEAD`, outside `RECORDS_RE`, and passed them as pathspecs to `git diff --name-only COMMIT HEAD -- FILES`; an empty result printed the same-change line and returned 0. A main-only file the merge reverted is in the second diff but unchanged from COMMIT to HEAD (both hold main's old text), so it carried. The workflow cannot run git: the checker runs `moved` and returns its last line, and `carryReviews` queues `review CHANGE KIND pass "blocking=0 carried=1" HEAD` for both kinds when the line matches `CARRIED`.

## Decisions

- Three name lists, each read with its own status checked: REVIEWED (`OLD_BASE..COMMIT`), CURRENT (`NEW_BASE..HEAD`), and MOVED (`COMMIT..HEAD`). A failing `git diff` exits 1 with its own line, so no empty list stands for a failure.
- The change is the same only when (a) no name of MOVED is in REVIEWED or CURRENT (outside the records-only paths) and (b) every name of CURRENT is in REVIEWED (outside the records-only paths): HEAD matches the new main in every file the reviewed change never touched. (a) keeps its existing line, so the file of the change edited after the review is reported as before; (b) gets its own line. The records-only paths stay out of both, since the package step commits the archive, the findings, and the history rows after the reviews, and the merge gates read the records apart.
- The lists are compared as text with `grep -F -x -e` with the newline-separated list, never passed to git, so a name is literal whatever it holds (`:(exclude)...`, a glob, a quoted name). The same process formats every list, so a quoted name matches its quoted twin.
- The exit status decides the record: `moved` drops the `moved` key when it starts (when a run state exists) and writes `moved` = "HEAD COMMIT" (full shas) before its same-change line, so a die, a failed diff, or a changed file leaves none; without a run state the write fails and `moved` exits 1. `review` refuses a summary with the word `carried=1` unless the `moved` record's head is the review's COMMIT and its reviewed commit differs from that head and is the commit the existing `review.KIND` record passed at, read before `review` overwrites it. The read profile may run `moved` (the checker returns its line), so the record is tied to the reviewed commit: `moved CHANGE HEAD` always exits 0, comparing a commit with itself, and would otherwise back a carry of reviews that never saw the head; the guard also limits that profile to `moved CHANGE COMMIT`. Agents cannot write the record otherwise: `set` refuses `moved`, the guard keeps `review` off the agents, and only the workflow's record start runs `review`. A checker that returns a forged same-change line therefore gets the workflow to queue a carry that the record start's `review` refuses, which stops the run (`the run state records failed`) with no review recorded.
- The workflow keeps its regex: it still decides whether the reviews run again now; its comments say the shell backs the record.

## Risks

- A forged line now stops the run instead of running the reviews again; acceptable, since it needs a checker misreporting, and nothing passes.
- Records-only paths a merge reverted are not compared, as before; they hold no code and the merge gates compare the records.
