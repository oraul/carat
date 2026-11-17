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

### The quality review fails its first pass most often, and its round costs most (plugin-lazy-activate retro)
- Location: the contributor's self-check in `.claude/agents/contributor.md` and the implement phase of `.claude/workflows/deliver-change.js`
- Why: status shows quality 85/153 first passes against check 150/153 and security 147/153; plugin-lazy-activate failed quality with 2 blocking findings (a test expectation edited against plugin-host spec.md:100 and :115 left in force; a new raise branch at `carat/use_cases/plugins/plugin_syntax.rb:48` without its test), its rework round costing 104,027 of 343,926 output tokens (30 percent); lsp-container-b and vim-folds-a also failed quality first.
- Fix: the contributor returns work the quality reviewer passes first, without a new phase; accepted when quality passes first on 8 or more of the next 10 feature runs with neither blocking kind above.

### A check start returns a pass at a commit other than the lane head (sprint-size-six retro)
- Location: the check phase of `.claude/workflows/deliver-change.js` and `check` in `tools/run_state.sh`
- Why: sprint-size-six's first check verdict passed at the base 25604e0ec359, not the head 2d4d9a8ffa16, so the check reran (1 of 2) with no fix round: check 40,322 output tokens in 8 calls, 22.2 percent of 181,434 and more than implement's 38,917; 4 of the last 20 backlog rows spent over 35,000 on the check.
- Fix: a check start reaches its verdict at the head on the first start; accepted when a check can no longer return a pass at another commit and the next 5 runs with no fix round each spend under 12,000 check output tokens.

### Two lanes' exception lines against one uncounted exception (sprint-size-six retro)
- Location: `SPRINT_EXCEPTIONS` in `tools/run_state.sh` (`:408`, the sprint_state branch at `:2005`)
- Why: SPRINT_EXCEPTIONS=1 against 2 exception lines (one per lane) leaves sprint-size-six counted, so review-due prints 4 of 5 against the user's "Sprint 16 finishes as planned"; the planner and the contributor noted it twice with 0 decisions changed, and sprint-16 now closes with tab-close-d and vim-folds-b left over.
- Fix: each lane's exception line leaves its change uncounted, or the conflict stops the run for the user's answer before the merge; accepted when review-due over such a history names both changes beyond the sprint.
