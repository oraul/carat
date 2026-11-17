### moved compares the change's files through unquoted, magic-capable pathspecs
- Location: tools/run_state.sh:2762 (moved_change)
- Why: Security Low (confidence 6). It passes `git diff --name-only` output back to git as pathspecs; with the default core.quotePath a name with non-ASCII or control characters comes out quoted, and a name starting with ':' is read as pathspec magic (a file named ':(exclude)*' becomes an exclude), so files of the change drop out of the at..HEAD comparison and `moved` can report the change the same after a main-moved merge altered it, carrying the quality and security passes to a head no review saw.
- Fix: List the files with `git -c core.quotePath=false diff -z --name-only` (read NUL-separated) and run the final `git diff` with `--literal-pathspecs` (or GIT_LITERAL_PATHSPECS=1), or compare `git diff old_base at` with `git diff new_base HEAD` over non-records paths without pathspecs; add tools_test cases with a quoted name and a ':(exclude)*' name.

### A carried review rests only on the moved line the checker copies back
- Location: .claude/workflows/deliver-change.js:935 (carryReviews)
- Why: Security Low (confidence 5). It records quality and security as passed at the merged head from the line the checker agent returns as `moved`, never running `moved` itself, and neither the run state nor the merge gate keeps an independent record, so a misreported or invented 'the change is the same' line gets a security pass recorded at a head no review saw, which the merge gate accepts.
- Fix: Have `tools/run_state.sh moved` write its verdict to the run state (for example `moved.<head> <from> same`) and have `run_state.sh review ... carried` or the merge gate refuse a carried review unless that record names the same head and from commit, or have the queued record command re-run `moved` before writing the carried pass.

### Reviews rerun after a main-moved merge read every commit of the moved main
- Location: .claude/workflows/deliver-change.js:855 (narrowedFrom)
- Why: Correctness. When the reviews run again after a main-moved merge, narrowedFrom returns the pre-merge pass, so the quality and security reviews read `git diff <pass> HEAD`, which holds every commit main gained, and can block the change on main's code or spend the review on code that is not the change's.
- Fix: Skip the narrowing and review the whole branch diff (origin/main...HEAD) when the check that preceded the reviews ran with movedFrom set; add a tools_test or workflow case that asserts the review range after a main-moved merge.
