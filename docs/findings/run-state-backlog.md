
## agent_hooks misses frontmatter keys that widen an agent's authority

- Location: tools/run_state.sh agent_hooks
- Why: closed as gone by run-state-backlog: No agent_hooks function exists in tools/, .claude/, or the Makefile, and review-due no longer counts guard changes.
- Fix: a search of the three

## A compile pass is cached whatever make command ran it

- Location: tools/run_state.sh compiled_same, stage_key
- Why: closed as fixed by run-state-backlog: The cached line is keyed by the code key and the make command, so only a pass by the same command skips a later run.
- Fix: tools-test: a compile pass under one make command is not skipped under another

## The run state header omits the compiled-KEY stage suffix

- Location: tools/run_state.sh, the run state header
- Why: closed as fixed by run-state-backlog: The stage.NAME line of the header names the compiled-KEY suffix beside carried-from-COMMIT.
- Fix: the header text

## dev-build's code key changes with test/ and bench/

- Location: tools/run_state.sh code_key, stage_key
- Why: closed as fixed by run-state-backlog: The key of dev-build leaves out test/ and bench/, which it never compiles.
- Fix: tools-test: dev-build keeps its code key across a commit to test/ and bench/, and test-build runs again

## check_lost and check_wait re-read the run state and the pid file inline

- Location: tools/run_state.sh check_lost, check_wait
- Why: closed as fixed by run-state-backlog: check_lost reads the running stage records through keys_under, and the lost-runner branch of check_wait no longer removes the pid file, which the code after the branch removes.
- Fix: the killed-runner cases of tools-test run through both

## An interrupted stage is recorded at the runner's head, not its start commit

- Location: tools/run_state.sh stages_stop
- Why: closed as already fixed by run-state-backlog: The killed record is written with job_at, the commit the stage started on, from the runner's job table, not the runner's head.
- Fix: stages_stop reads job_load; the superseded and killed cases of tools-test

## Recording merged deletes refs on origin from the generic key writer

- Location: tools/run_state.sh set merged
- Why: closed as gone by run-state-backlog: set writes no ref deletion; the code holds no git push --delete and the only ls-remote is main_moved's.
- Fix: a search of tools/run_state.sh

## drop_backup joins the ref names by unquoted word splitting

- Location: tools/run_state.sh drop_backup
- Why: closed as gone by run-state-backlog: The function is gone with the backup command.
- Fix: tools-test: backup is no longer a command

## abandon reports no backup left when origin is unreachable

- Location: tools/run_state.sh abandon
- Why: closed as gone by run-state-backlog: The abandon command and drop_backup are gone.
- Fix: tools-test: restore is no longer a command; backup is no longer a command

## The backup's base record outlives the backup

- Location: tools/run_state.sh backup
- Why: closed as gone by run-state-backlog: The backup command and its base record are gone.
- Fix: tools-test: backup is no longer a command

## The backup runs the branch's own gates

- Location: tools/run_state.sh backup
- Why: closed as gone by run-state-backlog: The backup command is gone; a run keeps its unpushed commits on its local branch.
- Fix: tools-test: backup is no longer a command

## The run_state.sh bullet reads as if it listed every command

- Location: CLAUDE.md
- Why: closed as fixed by run-state-backlog: The run_state.sh bullet says the header lists every command and names those an agent runs.
- Fix: docs-lint

## run_state.sh became executable in run-budgets

- Location: tools/run_state.sh file mode
- Why: closed as fixed by run-state-backlog: The mode is back to 100644.
- Fix: tools-test: run_state.sh is a plain file, never executable

## spent_line repeats budget_line's budget lookup

- Location: tools/run_state.sh budget_line, spent_line
- Why: closed as fixed by run-state-backlog: One budget_of helper holds the lookup of a size's total-token budget.
- Fix: the budget and spent cases of tools-test run through it

## A pipeline fix rode in the hover pull request

- Location: a hover pull request at 41297d6
- Why: closed as not fixed by run-state-backlog: A one-time process note about a CI fix of the tooling that rode a feature pull request, with nothing in tools/run_state.sh to change; the push step already names such a fix in the pull request's Notes.
- Fix: none

## A link planted in the check clone's build directory survives

- Location: tools/run_state.sh clone_drop, clone_make
- Why: closed as fixed by run-state-backlog: Links are removed from the carry on the way out and again when the carry is copied into the next clone.
- Fix: tools-test: a link a stage plants in build/ reaches no carry

## The runner's wait is longer than it says, in two copies

- Location: tools/run_state.sh runner_finish, check_wait
- Why: closed as fixed by run-state-backlog: One runner_wait helper, bounded by the clock at 30 seconds, replaces the two loops of 150 pauses.
- Fix: tools-test: the runner's wait is one helper bounded by the clock, not 150 pauses

## A run_state.sh paragraph splits its Usage list

- Location: tools/run_state.sh, the usage header
- Why: closed as fixed by run-state-backlog: The paragraph on refused keys follows the command list.
- Fix: tools-test: the usage keeps every write refusal paragraph after the command list

## A failed backup is retried by every start and never recorded

- Location: tools/run_state.sh backup
- Why: closed as gone by run-state-backlog: The backup command, retried by no start, is gone.
- Fix: tools-test: backup is no longer a command

## drop_key repeats write_key's rewrite

- Location: tools/run_state.sh write_key, drop_key
- Why: closed as fixed by run-state-backlog: Both call state_rewrite, the one rewrite of the state file.
- Fix: every run state case of tools-test writes through it

## pr-by-tag quality advisory at tools/run_state.sh:716

- Location: tools/run_state.sh CHECK_BIN, docs/codebase-map.md
- Why: closed as fixed by run-state-backlog: As the entry above.
- Fix: tools-test: CHECK_BIN is the Makefile's DEV_BIN

### Check clone's binary path not named in the map (late `pr-by-tag` quality advisory)

- Location: tools/run_state.sh CHECK_BIN, docs/codebase-map.md
- Why: closed as fixed by run-state-backlog: The map names CHECK_BIN beside in_clone, its comment names the Makefile's DEV_BIN as the one source, and a case fails when the two differ.
- Fix: tools-test: CHECK_BIN is the Makefile's DEV_BIN

### Stale comment on who runs ci-stages (`ci-time` quality advisory)

- Location: tools/run_state.sh ci_stages comment
- Why: closed as fixed by run-state-backlog: The comment says the record or closing start runs ci-stages once CI finished.
- Fix: the comment

### ci-stages step name can exceed 32 characters (`ci-time` quality advisory)

- Location: tools/run_state.sh ci_stages
- Why: closed as fixed by run-state-backlog: A name still over 32 characters after the cut at the last underscore is cut at 32.
- Fix: tools-test: ci-stages cuts a long step name with no underscore at 32 characters

### Path-scope helpers split the stage-list comments in run_state.sh

- Location: tools/run_state.sh scope_paths, out_of_scope, main_stages, check_stages
- Why: closed as fixed by run-state-backlog: The helpers sit above main_stages, and each stage-list comment sits above the function it describes.
- Fix: the diff; the check cases of tools-test

### merged_on_main repeats supported

- Location: tools/run_state.sh merged_on_main, supported
- Why: closed as fixed by run-state-backlog: Both call on_head_or_base, which takes the base.
- Fix: the merged and trusted cases of tools-test

### unmerged_list duplicates pending_list's loop

- Location: tools/run_state.sh pending_list, unmerged_list
- Why: closed as fixed by run-state-backlog: One merged_rows loop classifies each run state once and the two functions filter it.
- Fix: the pending, history, and unmerged cases of tools-test

### EXCEPTION_MARK names clash with the user-approved exception

- Location: tools/run_state.sh BEYOND_SPRINT_MARK
- Why: closed as fixed by run-state-backlog: EXCEPTION_MARK is renamed BEYOND_SPRINT_MARK; exception_item and sprint_exceptions no longer exist, queue_class and sprint_uncounted replaced them.
- Fix: the review-due cases of tools-test

### plan_needed lists run states differently from pending_list

- Location: tools/run_state.sh plan_needed
- Why: closed as fixed by run-state-backlog: plan_needed lists the review runs through review_runs, which globs the state directory as pending_list does.
- Fix: the plan-needed cases of tools-test run through it

### Unwrapped comment lines in run_state.sh

- Location: tools/run_state.sh plan_needed comment
- Why: closed as fixed by run-state-backlog: The unwrapped comment lines are rewrapped to the width of the block.
- Fix: the comment

### planned_commits re-implements the run-state key parsing of read_key

- Location: tools/run_state.sh planned_commits
- Why: closed as fixed by run-state-backlog: planned_commits reads the three keys through read_key, so the run state has one parser.
- Fix: the merged_since and plan-needed cases of tools-test

### plan_needed and merged_since comments run past the comment wrap

- Location: tools/run_state.sh plan_needed, merged_since comments
- Why: closed as fixed by run-state-backlog: Both comments are wrapped at the width of the block.
- Fix: the comment

### plan_needed lists review runs by parsing ls output

- Location: tools/run_state.sh plan_needed, passed_since
- Why: closed as fixed by run-state-backlog: The review runs come from review_runs, a glob of the state directory, not parsed ls output.
- Fix: the plan-needed cases of tools-test

### plan-needed wording says no change merged since though a merge planned before the review no longer counts

- Location: tools/run_state.sh plan_needed, .claude/workflows/deliver-change.js
- Why: closed as fixed by run-state-backlog: The plan-needed line and the planReview comment say no change planned after the review has merged since; the README step already says whose planner read the review runs after the review was recorded.
- Fix: tools-test: plan-needed names a failing periodic security review no merge followed

### Review-run listing and reviewed-commit resolution are repeated

- Location: tools/run_state.sh merged_since, passed_since, supported
- Why: closed as fixed by run-state-backlog: review_runs and full_commit hold the repeated listing and commit resolution.
- Fix: the periodic review cases of tools-test

### plan-needed needed line omits the later passing review condition

- Location: tools/run_state.sh plan_needed
- Why: closed as fixed by run-state-backlog: The needed line says no change planned after it has merged since, nor has a later whole-tree security review passed.
- Fix: tools-test: plan-needed names a failing periodic security review no merge followed

### run_state.sh header plan-needed line and plan_needed comment have over-long lines

- Location: tools/run_state.sh plan_needed comment
- Why: closed as fixed by run-state-backlog: The over-long lines of the plan_needed comment are rewrapped; the usage line is within the width.
- Fix: the comment

### Review runs and full commits are looked up in several places of run_state.sh

- Location: tools/run_state.sh merged_since, passed_since, plan_needed, supported
- Why: closed as fixed by run-state-backlog: review_runs and full_commit are the one place of each lookup.
- Fix: the periodic review cases of tools-test

### merge_main hides a merge failure that is not a conflict

- Location: tools/run_state.sh merge_main
- Why: closed as fixed by run-state-backlog: git's output is kept; with no unmerged file it is printed and only a merge in progress is aborted.
- Fix: tools-test: merge-main shows git's message when a merge fails with no conflicted file

### lane_open and lane_close remove a worktree by different steps

- Location: tools/run_state.sh lane_open, lane_close
- Why: closed as fixed by run-state-backlog: Both remove a worktree through lane_remove, links first.
- Fix: tools-test: lane-open and lane-close remove a worktree by one step

### lane_of prints the shell's error for a missing queue file

- Location: tools/run_state.sh lane_of
- Why: closed as fixed by run-state-backlog: The redirection wraps the command, so a missing queue file prints no shell error.
- Fix: tools-test: lane prints the shell's error for no queue file

### The init usage line still says it refuses any merged run

- Location: tools/run_state.sh, the init usage
- Why: closed as fixed by run-state-backlog: The usage says init refuses a change the close recorded as merged (phase.retro) or with a lane history row, and resumes a merged run with no phase.retro.
- Fix: tools-test: the usage says init refuses a merged run the close recorded

### Two lanes share one writable toolchain and compile cache (sprint-10 security Low (3), disputed)

- Location: tools/run_state.sh LANE_LINKS
- Why: closed as not fixed by run-state-backlog: The entry is disputed: the lanes share one toolchain and compile cache by design (parallel-lanes-b), a per-lane copy doubles the install and the cache, and the part a branch could steer, a committed link at those paths, is refused by lane-open; it closes only as fixed.
- Fix: none

### lane_open checks the branch with a line-wise grep and a third copy of the pattern

- Location: tools/run_state.sh lane_open, tools/rules.sh
- Why: closed as not fixed by run-state-backlog: The line-wise grep is replaced by valid in this change, which refuses a multi-line branch; the shared BRANCH_RE of tools/rules.sh and its copies in open_pr.sh and agent_guard.sh need an edit of the merge gate's rules, which goes first and alone.
- Fix: tools-test: lane-open refuses a branch whose first line is a Conventional Branch

### The package step appends the planner's findings twice

- Location: tools/run_state.sh plan_apply
- Why: closed as fixed by run-state-backlog: An entry whose heading the findings file already holds is not appended again.
- Fix: tools-test: a second plan-apply appends no entry twice

## Groom folds a findings file without a trailing newline as is

- Location: tools/run_state.sh file_entries
- Why: closed as already fixed by run-state-backlog: Every entry is written after a blank line, whatever the findings file ended with, and groom adds a newline after each file.
- Fix: tools-test: groom folds two changes' findings into the backlog

### The branch pattern and the trailer are spelled three times each

- Location: tools/rules.sh, tools/open_pr.sh, tools/agent_guard.sh, tools/gates.sh, tools/scan_text.sh
- Why: closed as not fixed by run-state-backlog: One BRANCH_RE and one TRAILER in tools/rules.sh is an edit of the merge gate's rules, which goes first and alone.
- Fix: none

### A stage's branch code can forge its pass record through the runner's job files (security Medium, confidence 6)

- Location: tools/run_state.sh stage_launch, stages_reap
- Why: closed as already fixed by run-state-backlog: The runner keeps each job's pid, start second, and commit in its job_table and reads the status with wait on its own child; no job file exists for a stage to write.
- Fix: tools-test: a stage that rewrites a stage record by an absolute path fails the check

### A failing stage's log excerpt reaches the terminal unfiltered (security Low, confidence 4)

- Location: tools/run_state.sh visible_text
- Why: closed as already fixed by run-state-backlog: The excerpt of a failing log passes visible_text, which turns every control byte, and the C1 controls, into a question mark.
- Fix: tools-test: a failing stage's excerpt holds no escape byte

### stages_stop does not record a passed compile stage as compiled

- Location: tools/run_state.sh stages_stop, compile_passed
- Why: closed as fixed by run-state-backlog: stages_reap and stages_stop note a passed compile stage through one compile_passed.
- Fix: tools-test: a compile stage that passed while the check stopped is skipped on the same code

### Groom output needs a hand edit and draws the records runs' quality advisories

- Location: tools/run_state.sh groom, fold_clean, removed_refs
- Why: closed as fixed by run-state-backlog: Groom's fold drops placeholder lines and writes references to the findings files it removes as the removed file; file_entries already separates every entry by a blank line and drops a title line.
- Fix: tools-test: the fold cases, and groom's findings fold

## Folded backlog headings follow the previous entry with no blank line

- Location: tools/run_state.sh file_entries
- Why: closed as already fixed by run-state-backlog: file_entries prints a blank line before every entry it files.
- Fix: tools-test: groom folds two changes' findings into the backlog

### groom output needs a hand edit after each records run (sprint-12-records retro note 5)

- Location: tools/run_state.sh groom, fold_clean, removed_refs
- Why: closed as fixed by run-state-backlog: As the entry above: no hand edit of a removed findings path, no folded title, a blank line before each entry.
- Fix: tools-test: the fold cases

### A check stage can fake a sibling stage's pass through the job files (sprint-13 security Medium (6))

- Location: tools/run_state.sh stage_launch, stages_reap
- Why: closed as already fixed by run-state-backlog: As the entry above: no job files, the status comes from wait.
- Fix: tools-test: a stage that rewrites a stage record by an absolute path fails the check

### The failing stage's log excerpt reaches the terminal unfiltered (sprint-13 security Low (4))

- Location: tools/run_state.sh visible_text
- Why: closed as already fixed by run-state-backlog: As the entry above.
- Fix: tools-test: a failing stage's excerpt holds no escape byte

### A doubled blank line before check_wait (sprint-13 quality)

- Location: tools/run_state.sh before check_wait
- Why: closed as fixed by run-state-backlog: The doubled blank line is removed.
- Fix: the diff

### moved compares the change's files through unquoted, magic-capable pathspecs

- Location: tools/run_state.sh moved_change
- Why: closed as already fixed by run-state-backlog: The names are compared as text with grep -F -x and never handed to git as pathspecs, as the comment above moved_change says.
- Fix: tools-test: the moved cases

## The fold keeps a findings file's title as a second level-one heading

- Location: tools/run_state.sh file_entries
- Why: closed as already fixed by run-state-backlog: A line starting with one # ends the previous entry and opens none, so a findings file's title is never filed.
- Fix: tools-test: groom folds two changes' findings into the backlog

## The fold adds headings with no blank line before them

- Location: tools/run_state.sh file_entries
- Why: closed as already fixed by run-state-backlog: As the entry above 696: a blank line before every filed entry.
- Fix: tools-test: groom folds two changes' findings into the backlog

### Budget line names the sprint key too narrowly

- Location: tools/run_state.sh budget line
- Why: closed as gone by run-state-backlog: The budget line no longer carries the wording about the sprint key.
- Fix: a search of tools/run_state.sh

## Fold adds a level-one heading per findings file

- Location: tools/run_state.sh file_entries
- Why: closed as already fixed by run-state-backlog: As the entry above 820: no level-one heading is filed.
- Fix: tools-test: groom folds two changes' findings into the backlog

## Folded headings lack a blank line before them

- Location: tools/run_state.sh file_entries
- Why: closed as already fixed by run-state-backlog: As the entry above 696: a blank line before every filed entry.
- Fix: tools-test: groom folds two changes' findings into the backlog

### Groom's fold keeps producing format defects the records run hand-fixes (sprint-16-records retro)

- Location: tools/run_state.sh groom, fold_clean, removed_refs
- Why: closed as fixed by run-state-backlog: As above: the fold produces no format defect the records run fixed by hand.
- Fix: tools-test: the fold cases

### Groom's duplicate guard lets an unmarked security entry leave as a duplicate

- Location: tools/run_state.sh SECURITY_MARK
- Why: closed as already fixed by run-state-backlog: SECURITY_MARK takes an entry naming security and a severity in any wording or order, so a Low finding of the security review leaves only listed or fixed.
- Fix: tools-test: groom refuses a gone entry marked only by a Low finding of the periodic security review, a duplicate, and a merge into a plain entry

### Groom's listed proof accepts a heading as a bare substring of the queue item (`groom-proof` security Low (5))

- Location: tools/run_state.sh item_lists
- Why: closed as already fixed by run-state-backlog: The heading must stand bounded: no # before it, the same quote or backtick after it when quoted, the end of the item or a comma when bare.
- Fix: tools-test: the groom listed cases

### Groom's duplicate guard lets a security entry without a `security <severity>` marker leave (`groom-proof` security Low (3))

- Location: tools/run_state.sh SECURITY_MARK
- Why: closed as already fixed by run-state-backlog: The mark covers a severity and confidence pair, a Critical one, and a severity on another line than the word security.
- Fix: tools-test: groom refuses a gone entry carrying a Critical severity and confidence pair; a duplicate entry naming security in its heading and a severity only in its body

### Groom's output fails the check's docs-lint stage on its own (sprint-18-records retro 11)

- Location: tools/run_state.sh groom, removed_refs
- Why: closed as fixed by run-state-backlog: A backticked path to a findings file or the findings directory is written as the removed file or directory, so docs-lint finds no path that is gone.
- Fix: tools-test: the fold writes each findings reference as the removed file

### settled_round repeats the RECORDS_RE filtering of other records filters (review-lite quality advisory)

- Location: tools/run_state.sh settled_round, tools/gates.sh settled_at
- Why: closed as not fixed by run-state-backlog: One shared helper for the paths outside RECORDS_RE needs a tools/rules.sh edit, which goes first and alone.
- Fix: none

### Two security entries stay open though #214 fixed them

- Location: b5b0aec (the widening of SECURITY_MARK)
- Why: closed as already fixed by run-state-backlog: The two entries named docs/backlog.md lines that the folder replaced; SECURITY_MARK covers them since b5b0aec, and the cases above prove it.
- Fix: tools-test: the groom security mark cases

### SECURITY_MARK matches security and a severity word anywhere in a long entry (sprint-19 review quality)

- Location: tools/run_state.sh SECURITY_MARK
- Why: closed as not fixed by run-state-backlog: A window around security would let an entry naming security in its heading and its severity in a later line leave as a duplicate; the wide match errs on the safe side and only orders what groom refuses, so it stays.
- Fix: none

### The new --pr-text push kind accepts any commit, as long as a recorded (sprint-20 review security Low (3), run_state.sh:1330)

- Location: tools/run_state.sh push_branch
- Why: closed as fixed by run-state-backlog: push --pr-text refuses a commit that changes any path but the archived pr.md of the change since the recorded push.
- Fix: tools-test: a pull request text push refuses a commit that edits another file

### HEADER names 24 columns (sprint-20 sweep quality, run_state.sh:484)

- Location: docs/metrics-feature.tsv, docs/metrics-backlog.tsv
- Why: closed as already fixed by run-state-backlog: Line 1 of both lane files holds the 24 columns of HEADER, which history refuses to append under otherwise.
- Fix: tools-test: history refuses a lane file whose header is short of HEADER

### A check stage can forge its runner's job status files

- Location: tools/run_state.sh stage_launch, stages_reap
- Why: closed as already fixed by run-state-backlog: As the entry above: the job directory no longer exists.
- Fix: tools-test: a stage that rewrites a stage record by an absolute path fails the check

### Security: a check's escape scan leaves the XDG global git configuration and the branch the main checkout's HEAD names out

- Location: tools/run_state.sh escaped_paths, main_moved
- Why: closed as fixed by run-state-backlog: The XDG git configuration is scanned beside the HOME git configuration, and main_moved compares the main checkout's symbolic HEAD beside its commit.
- Fix: tools-test: a stage that writes the XDG git configuration by an absolute path fails the check, and one that switches the main checkout to another branch at the same commit fails it

### Quality: main_moved's ls-remote reaches the network with no prompt guard or time limit (quality advisory)

- Location: tools/run_state.sh main_moved, bounded
- Why: closed as fixed by run-state-backlog: ls-remote runs with GIT_TERMINAL_PROMPT=0 and, where timeout exists, a 60 second limit; a failure counts as moved as before.
- Fix: tools-test: the scan's ls-remote runs with git's terminal prompt off

### Security: stages run with the real HOME and the scan ignores its executed files (security Medium (6))

- Location: tools/run_state.sh CLONE_EXEC, escaped_paths
- Why: closed as fixed by run-state-backlog: Stages run with HOME a throwaway directory inside the clone and no XDG_CONFIG_HOME; the scan reads ~/.gitconfig, ~/.config/git, the shell startup files, and the hooks' settings of the real HOME.
- Fix: tools-test: a check stage's HOME is a throwaway directory inside its clone; a stage that writes HOME's profile by an absolute path fails the check

### Quality: a tracked path holding a tab, newline, quote, or backslash is reported as untracked

- Location: tools/run_state.sh main_scan
- Why: closed as fixed by run-state-backlog: git ls-files -z and find -print0 are compared as records, so a tab, newline, quote, or backslash in a tracked name matches.
- Fix: tools-test: a tracked path holding a tab is not reported as an untracked file

## Findings of grep-long-files after its package step

- Location: tools/run_state.sh plan_apply
- Why: closed as fixed by run-state-backlog: A new plan entry is appended after a blank line.
- Fix: tools-test: plan-apply separates a new entry from the findings file's last line by a blank line

### tools/run_state.sh:1143: [ -z "$HOME" ] under set -u (line 396) (sprint-22 review quality)

- Location: tools/run_state.sh escaped_paths
- Why: closed as fixed by run-state-backlog: The HOME test reads ${HOME:-}, so an unset HOME skips only its own files.
- Fix: tools-test: a check with HOME unset still reads the references and fails on a forged one

### history names the run state file as the lane file it appended to

- Location: tools/run_state.sh append_history
- Why: closed as fixed by run-state-backlog: The message names row_file, the lane history, not the run state's path.
- Fix: tools-test: history appends the row

### groom folds findings entries that still name the findings files it deletes (sprint-22-records retro note 4)

- Location: tools/run_state.sh groom, removed_refs
- Why: closed as fixed by run-state-backlog: No folded entry names a removed findings file.
- Fix: tools-test: the fold writes each findings reference as the removed file

### PRUNE_ALL_SPRINT dead after the sprint-24 close at tools/run_state.sh:439

- Location: tools/run_state.sh PRUNE_ALL_SPRINT
- Why: closed as gone by run-state-backlog: The constant, its line in backlog_oldest, and its case are gone.
- Fix: a search of tools/ and docs/codebase-map.md

### plan-apply copies a planned goals.md after the security review

- Location: tools/run_state.sh plan_apply
- Why: closed as fixed by run-state-backlog: plan-apply leaves a planned goals.md, and names it, once a security review passed for the change, so the goals change needs its own delivery and no edit of docs/goals.md follows the review.
- Fix: tools-test: plan-apply leaves a planned goals.md once a security review passed

### groom folds none/None placeholder lines from findings files

- Location: tools/run_state.sh fold_clean
- Why: closed as fixed by run-state-backlog: A none or None line of a findings file is dropped from the fold.
- Fix: tools-test: the fold drops the none and None placeholder lines

### groom folds the none/None lines of findings files (sprint-23-records retro note 11)

- Location: tools/run_state.sh fold_clean
- Why: closed as fixed by run-state-backlog: As the entry above.
- Fix: tools-test: the fold drops the none and None placeholder lines

### SPRINT_HEADER is never read (sprint-24 sweep quality)

- Location: tools/run_state.sh SPRINT_HEADER
- Why: closed as fixed by run-state-backlog: The constant, which nothing read, is deleted.
- Fix: tools-test: SPRINT_HEADER, which nothing read, is gone

### The escaped verdict lets any write under the main checkout's build/ through (security Medium (5))

- Location: tools/run_state.sh lane_written
- Why: closed as already fixed by run-state-backlog: LANE_WRITTEN names no path by default, so a write under the main checkout's build/, build/bin/carat included, reads failed with a fix round.
- Fix: tools-test: a write to the main checkout's build/bin/carat from a lane voids the check and ends in a failed verdict line

### duplication: backed_commit and check_stages (1082) each read phase.check and at tools/run_state.sh:681 (sprint-26 review quality, note 11)

- Location: tools/run_state.sh backed_commit, check_stages
- Why: closed as fixed by run-state-backlog: Both read the recorded phase.check through recorded_check.
- Fix: tools-test: the dirty-tree read, the failed verdict line, and the recorded check are one function each

### the runner refuses a dirty tracked tree with its at tools/run_state.sh:1204 (sprint-26 sweep quality, note 13)

- Location: tools/run_state.sh check_wait, check_run
- Why: closed as fixed by run-state-backlog: One dirty_tracked reads the dirty tree and one verdict_failed writes the failed verdict line, beside check_verdict.
- Fix: tools-test: the dirty-tree read, the failed verdict line, and the recorded check are one function each

### groom_row's untracked sprint marker (sprint-14 review security Low (3) and quality)

- Location: tools/run_state.sh sprint_row_at
- Why: closed as not fixed by run-state-backlog: The entry says no change is needed unless the marker gains another value; it has none.
- Fix: none

### base-figures save checks only tracked files and untracked makefiles at tools/run_state.sh:2069 (sprint-30 sweep security Low (3), note 2)

- Location: tools/run_state.sh base_figures save
- Why: closed as fixed by run-state-backlog: save refuses any untracked file of tmp/.base, not only a makefile, so no planted source is built and measured as main's; the BASE argument stays, as the stored figures name the commit they measured.
- Fix: tools-test: base-figures save refuses an untracked source file in the base

### merge_main pins only some of its git calls at tools/run_state.sh:4370 (sprint-31 review quality)

- Location: tools/run_state.sh merge_main
- Why: closed as already fixed by run-state-backlog: The merge, checkout, add, commit, abort, and conflict reads run with plain git by decision of the merge-main change; only the fetch is pinned.
- Fix: tools-test: merge_main runs plain git past its fetch

### Security: a check leaves the remote-tracking refs unchecked, so a stage can forge origin/main for the next lane

- Location: tools/run_state.sh lane_open
- Why: closed as fixed by run-state-backlog: lane-open asks origin first: it fetches origin's main and, for the branch, fetches its ref or removes the local remote-tracking ref when origin holds no such branch, so a ref a stage planted seeds no lane; an unreachable origin leaves the refs with a note.
- Fix: tools-test: lane-open starts a branch origin lacks from main, not from a planted remote-tracking ref

### Security: refs_view leaves refs/remotes/ out, and lane_open bases a new lane on a remote-tracking ref without fetching (security Low (5))

- Location: tools/run_state.sh lane_open
- Why: closed as fixed by run-state-backlog: As the entry above: the ref of BRANCH and origin/main are read after origin's own answer.
- Fix: tools-test: lane-open starts a branch origin lacks from main, not from a planted remote-tracking ref

### Plan notes reach the findings file twice (facet-design-doc retro note 17)

- Location: tools/run_state.sh plan_apply
- Why: closed as fixed by run-state-backlog: plan-apply appends an entry only when the findings file lacks its heading, so notes the implement step appended are not appended again by the package step.
- Fix: tools-test: a second plan-apply appends no entry twice

### lane_of misses a queue item that estimate_of and exception_item find

- Location: tools/run_state.sh item_named
- Why: closed as fixed by run-state-backlog: The item test reads the name as estimate_of does, the name in backticks first in the item, so an item whose name is followed by a word gets its lane.
- Fix: tools-test: lane takes a change whose queue item names it before a word

### A concurrent lane's benchmark log fails another lane's check (pr-trust-lows check)

- Location: tools/run_state.sh main_scan
- Why: closed as fixed by run-state-backlog: A file build/NAME.log of the main checkout, where another lane's benchmark agent redirects its make output, no longer voids a lane's check; any other file under its build/ still does.
- Fix: tools-test: a log written in the main checkout's build/ by another lane leaves a lane's check passing

### A concurrent lane's benchmark log fails another lane's check

- Location: tools/run_state.sh main_scan
- Why: closed as fixed by run-state-backlog: As the entry above: build/NAME.log of the main checkout is left out of the scan.
- Fix: tools-test: a log written in the main checkout's build/ by another lane leaves a lane's check passing

### Groom's listed check matches any archive name suffix (`sprint-planning` quality advisory)

- Location: tools/run_state.sh groom's listed check
- Why: closed as gone by run-state-backlog: The archive glob of the listed check is gone: groom's listed proof is item_lists over the sprint's own changes (sprint_change), which reads a queue item, no archive name.
- Fix: a search of tools/run_state.sh for archive/

### Usage header splits review-due's description (`ci-time` quality advisory)

- Location: tools/run_state.sh, the usage header
- Why: closed as already fixed by run-state-backlog: The ci-stages and tokens entries stand before review-due's description, which is whole.
- Fix: the usage header

### ci-stages may drop every step on fractional seconds (`ci-time` quality advisory)

- Location: tools/run_state.sh ci_stages
- Why: closed as already fixed by run-state-backlog: The jq computes each timestamp to the second through fromdateiso8601 and adds the fraction its capture reads, so a fractional step is kept, not dropped.
- Fix: tools-test: ci-stages records a fractional step, rounded to a tenth

### reviewed-edits fails open when git diff fails (pipeline-diet quality)

- Location: tools/run_state.sh reviewed_edits
- Why: closed as fixed by run-state-backlog: A failing git diff or ls-files returns 1 with a message; no empty list reads as none since the review.
- Fix: tools-test: reviewed-edits fails when git cannot list the changed files

## Agents leave scratch files in the repository root

- Location: tools/run_state.sh push_branch
- Why: closed as fixed by run-state-backlog: push refuses an untracked file outside the ignored paths (git ls-files --others --exclude-standard), naming up to three, so an agent's scratch file cannot be staged by a later git add; the agents' briefs are not edited here.
- Fix: tools-test: push refuses an untracked file outside the ignored paths

## The run state's writer has no lock beside the detached check runner

- Location: tools/run_state.sh write_key, drop_key
- Why: closed as not fixed by run-state-backlog: During a check only the runner writes the run state (stage_launch and stages_reap, as their comments say); a lock directory around write_key needs stale-lock handling after a killed writer and no tools-test case can show the race, so it is left for a change that can take both.
- Fix: a lock directory with a retry and a stale-lock test

## A lost check runner leaves its make running while a second one starts

- Location: tools/run_state.sh check_lost, check_wait
- Why: closed as not fixed by run-state-backlog: A runner killed by a signal it cannot trap leaves its stage's make in the dead runner's process group; stopping that group needs the group recorded in the pid file and a check that no other process reuses it, which is a design of its own with the check sandbox group.
- Fix: record the runner's group in the pid file and stop it in check_lost after checking its members

## A detached check runner outlives a stopped run and shares build/

- Location: tools/run_state.sh clone_make, in_clone
- Why: closed as already fixed by run-state-backlog: Every stage builds in the check clone's own build/ (clone_make, CLONE_EXEC), so a runner that outlives a stopped run no longer shares build/ with another change's check; a new check still stops a runner at another commit (check_wait).
- Fix: tools-test: every check outside its clone removes the clone

## The check verdict is read from a log read agents can write

- Location: tools/run_state.sh check_verdict
- Why: closed as not fixed by run-state-backlog: The verdict is still the last line of check.log under build/stages, which a same-user process can append to; deriving it from the stage records needs the records out of every stage's reach, which the check sandbox group cannot give without a separate user.
- Fix: derive the verdict from the run state's stage records or keep the log where no stage writes

## The check-pass budget line projects 6 total tokens per output token

- Location: tools/run_state.sh OUTPUT_SHARE, spent_line
- Why: closed as not fixed by run-state-backlog: The figure of total tokens per output token is a calibration decision (history rows run from 3.5 to 59 per output token), and SPENT_LINE of the workflow and the tools-test regex move with it; no value is chosen here. The entries of the same figure (the check-pass line changing no decision, the note firing under the total budget, the in-run line pricing 6 per output token) are merged into this one.
- Fix: derive the share from the history rows' median or print the total-token figure, with SPENT_LINE and the regex in step

## delivery-speed quality advisory at tools/run_state.sh:406

- Location: tools/run_state.sh main_stages
- Why: closed as not fixed by run-state-backlog: main_stages is still read by check_stages and carried_check and two tools-test cases pin it; deleting a shim with its readers and cases is a tidy-up for a change of its own.
- Fix: remove main_stages, its two cases, and the STAGES fallbacks that call it

## delivery-speed quality advisory at tools/run_state.sh:1217

- Location: tools/run_state.sh history, late findings
- Why: closed as not fixed by run-state-backlog: History appends late findings under one heading of bullets, which tools-test pins (the heading names the run); the Where, Why it matters, Fix outline shape per finding would change what the workflow writes.
- Fix: write one entry per finding in the Where, Why, Fix shape, or document the grouped form

### Groom lets every copy of a duplicated finding go (`sprint-planning` quality advisory)

- Location: tools/run_state.sh groom, duplicate guard
- Why: closed as not fixed by run-state-backlog: The guard still matches a location as a substring (grep -F of the location and a colon) and reads the unmodified file, so all copies of a finding can be removed together; an exact awk comparison and a refusal of removing every heading at a location need a fixture of two headings at one location.
- Fix: compare the location field exactly and refuse a groom.txt that removes every heading at a location

### plan-needed treats an unreviewed sprint plan as waiting (`sprint-planning` quality advisory)

- Location: tools/run_state.sh plan_needed
- Why: closed as not fixed by run-state-backlog: plan_needed still treats a waiting sprint plan as a plan without checking sprint_reviewed; one helper for review_due, groom, and plan_needed needs the planner's keep rule (planner.md) read together.
- Fix: one helper over sprint_waiting and sprint_reviewed, used by the three

### Sprint after a sixth merge reviews a change twice (`sprint-planning` quality advisory)

- Location: tools/run_state.sh sprint_names, sprint_row
- Why: closed as not fixed by run-state-backlog: sprint_names is still not cut at the sprint size, so a sixth merge is listed in the closing sprint and again in the next.
- Fix: cut sprint_names at the sprint size and end the combined diff at the last counted change

## records-once quality advisory at tools/run_state.sh:233

- Location: tools/tools_test.sh, TEST_ONLY
- Why: closed as not fixed by run-state-backlog: No case of a docs/sprints.tsv-only commit in the stage carry and the quality fix scope was added; TEST_ONLY reaches it through RECORDS_RE, which the carry cases of tools-test exercise with a test file.
- Fix: expect that a docs/sprints.tsv-only commit carries a compile stage and is left out of the fix scope

## records-once quality advisory at tools/run_state.sh:1586

- Location: tools/run_state.sh records_excluded
- Why: closed as not fixed by run-state-backlog: records_excluded and the dispatch still repeat the change-name case; a change_name helper is a refactor with no behavior to test.
- Fix: one change_name helper called by both

## history and groom skip on records of a branch that never merges (sprint-2 sweep)

- Location: tools/run_state.sh history, groom
- Why: closed as not fixed by run-state-backlog: history skips on a row recorded on any branch and groom retires the marker clone-wide; judging them against the current base changes how a stopped run is recovered and needs the carrier design (groom's carrier entries) first.
- Fix: skip only when the row is on the current base, retire the marker when the sprint row reaches the base

### Tests-only carry runs before the path scope in run_state.sh

- Location: tools/run_state.sh check_stages
- Why: closed as fixed by run-state-backlog: A stage recorded scoped is no longer carried across a tests-only commit; the path scope decides it again.
- Fix: tools-test: a stage recorded scoped is not carried across a tests-only commit, the scope deciding it again

### The ci-stages secs filter is never run by a test

- Location: tools/run_state.sh ci_stages, tools/tools_test.sh
- Why: closed as not fixed by run-state-backlog: The fake gh prints precomputed seconds, so the jq timestamp filter is still not run by a test.
- Fix: feed a jobs JSON through the same filter

### Planner does not know the beyond-the-sprint marker

- Location: tools/run_state.sh EXCEPTION_MARK, the planner brief, docs/goals.md
- Why: closed as not fixed by run-state-backlog: The planner brief and docs/goals.md are instruction records outside this change's scope, and the exception rules of review-due moved to queue_class since the entry.
- Fix: name the beyond-the-sprint words in the planner brief and docs/goals.md

### Three path classifiers decide which stages run

- Location: tools/run_state.sh TEST_ONLY, NOT_COMPILED, TOOLS_RE
- Why: closed as not fixed by run-state-backlog: Deriving the three path classifiers from the rules.sh classifiers touches the merge gate's rules, which go first and alone.
- Fix: derive them from rules.sh or record why each differs

### The sprint exception membership test is written three times

- Location: tools/run_state.sh queue_class, sprint_state, groom
- Why: closed as not fixed by run-state-backlog: The exception membership is now one function (queue_class) read by sprint_state, sprint_row, and groom through sprint_uncounted; the remaining index trick in the row filter is cosmetic and left.
- Fix: one helper for the membership test

### merged_since reads only the last metrics row's merged commit

- Location: tools/run_state.sh merged_since
- Why: closed as already fixed by run-state-backlog: merged_since walks every history row newest first up to the first one that does not descend from the reviewed commit, and the pending runs too, so a later merge in an earlier row is no longer missed.
- Fix: tools-test: plan-needed keeps a failing periodic security review a merge planned before it followed

### sprint_state picks an exception past the fifth counted row

- Location: tools/run_state.sh sprint_state
- Why: closed as gone by run-state-backlog: SPRINT_EXCEPTIONS and sprint_exceptions no longer exist; sprint_state classes each name of the window through queue_class, so review-due, groom, and the row read the same window.
- Fix: none

### history_rows walks the whole rev-list on every call

- Location: tools/run_state.sh history_rows
- Why: closed as not fixed by run-state-backlog: history_rows is still computed once per caller (groom calls it twice, status once); passing the rows is a speed change with no failing case.
- Fix: compute the rows once per command

### metrics_files breaks on a METRICS_PREFIX holding a space

- Location: tools/run_state.sh lane_rows, append_history
- Why: closed as fixed by run-state-backlog: The lane history files are read by lane name, so a metrics prefix holding a space no longer splits a file name.
- Fix: tools-test: status reads the history rows of a metrics prefix holding a space

### backlog-pick tries each backticked path twice

- Location: tools/run_state.sh backlog_pick
- Why: closed as not fixed by run-state-backlog: The bare-word pass still re-adds each backticked path, so each is looked up twice; a speed change with no failing case.
- Fix: run the bare-word pass over the Location with the backticked spans removed

### Top-level docs findings never reach a batch

- Location: tools/run_state.sh backlog_pick, docs/codebase-map.md
- Why: closed as not fixed by run-state-backlog: Mapping the top-level docs to an area of the code map is a change of the map and of the pick together, outside this file.
- Fix: map the top-level docs in an area or batch unmapped entries as their own item

### No case pins a bare directory word known only by its files

- Location: tools/run_state.sh backlog_pick named_file
- Why: closed as not fixed by run-state-backlog: No case pins a bare directory word known only by its files; the behavior is documented in the header and left as it is.
- Fix: a tools-test case pinning the unmapped result

### Concurrent lanes race on the shared origin/main ref lock

- Location: tools/run_state.sh merge_main
- Why: closed as not fixed by run-state-backlog: Two lanes fetching one ref at once can still fail on its lock; a retry cannot be tested without a race and merge-main keeps its plain git by the merge-main decision.
- Fix: retry the fetch once or fetch into a per-lane ref

### push --review-fix does not check that a review blocked

- Location: tools/run_state.sh push_branch --review-fix
- Why: closed as not fixed by run-state-backlog: A review fix push needs a marker the workflow writes when a review blocks, since the review record at the pushed head is rewritten by the re-review before the push. needs a change of the delivery workflow or of an agent brief, which this change leaves alone (its scope is tools/run_state.sh and its tools-test cases).
- Fix: a run-state marker written by the workflow when a review blocks, required by the push

### history writes late findings to a findings file the records change folded

- Location: tools/run_state.sh history
- Why: closed as not fixed by run-state-backlog: History still names the merged change's findings file; appending late findings to the packaging change's file changes the heading tools-test pins and the planner's reading of it.
- Fix: append late findings under the packaging change's own file and heading

### groom documents CHANGE as optional though it dies without one

- Location: tools/run_state.sh header, dispatch
- Why: closed as fixed by run-state-backlog: groom takes a required CHANGE in its usage and dispatch; a run with no change is a usage error.
- Fix: tools-test: groom with no change is a usage error

### plan-apply and history write into whatever checkout runs them

- Location: tools/run_state.sh plan_apply, append_history
- Why: closed as fixed by run-state-backlog: plan-apply and history for a change refuse, writing nothing, when its lane worktree tmp/.lane-CHANGE exists and the command runs elsewhere.
- Fix: tools-test: plan-apply and history refuse outside the change's lane worktree, and plan-apply runs inside it

### A merge that fails on a moved main has no push path

- Location: tools/run_state.sh push_branch
- Why: closed as already fixed by run-state-backlog: push --main-moved after merge-main is the push path of a merge that failed on a moved main, counted once, with its tools-test cases (a main-moved push needs a head holding main; a second one is refused).
- Fix: tools-test: a moved-main merge is pushed once as a main-moved push

### jobs_refusal has two arms for one message and runs twice (sprint-13 quality)

- Location: tools/run_state.sh jobs_refusal, check_stages
- Why: closed as fixed by run-state-backlog: jobs_refusal has one pattern (not a number, 0, or a leading zero) and the runner reads it once before any stage is queued, not after the compiled records were reset.
- Fix: tools-test: check refuses a CHECK_JOBS that is no number and one of 0

### squash_commit falls back to HEAD, so a branch commit can pass merged_at (security Low (4))

- Location: tools/run_state.sh squash_commit
- Why: closed as fixed by run-state-backlog: squash_commit reads only BASE (origin/main), never HEAD, so a branch commit titled like a squash commit is not one.
- Fix: tools-test: set refuses a branch commit titled like the squash commit when main has none

### merged_at without a pr accepts any ancestor of HEAD (sprint-14 review and sweep quality)

- Location: tools/run_state.sh merged_at
- Why: closed as fixed by run-state-backlog: With no pull request recorded, a merged value must be an ancestor of BASE whenever BASE names a commit, never of HEAD, where a lane's pushed head is; HEAD stands only where no main exists to compare, as the tools-test fixtures have none.
- Fix: tools-test: set refuses a branch commit with no pull request recorded as merged

### The security record keeps only the last review round (merge-record-check retro 7)

- Location: tools/run_state.sh review, the workflow's re-review
- Why: closed as not fixed by run-state-backlog: Keeping an earlier round's Lows counted after a re-review that found fewer changes how the security record is read by the gates and the workflow.
- Fix: count the earlier round's findings in the stored record

### The planner starts only to remove the delivered item (vim-line-commands-a retro 5)

- Location: tools/run_state.sh plan_needed
- Why: closed as already fixed by run-state-backlog: plan-needed answers not needed for a delivery of a queue's first item with an estimate and no pending change holding a proposal or finding, so the planner starts only for a decision.
- Fix: tools-test: plan-needed takes the queue head as written

### Records changes are judged against the small budget with the sprint reviews in their totals

- Location: tools/run_state.sh budget_line
- Why: closed as gone by run-state-backlog: budget_line reads metric.total_tokens, which only usage writes for the delivery's own starts; no sprint review phase is in it, so a records change is no longer judged with its sprint reviews in the total.
- Fix: none

### Two lanes' exception lines against one uncounted exception (sprint-size-six retro)

- Location: tools/run_state.sh sprint_state
- Why: closed as gone by run-state-backlog: SPRINT_EXCEPTIONS no longer exists; each exception line classes its own change through queue_class, so two lanes' lines no longer meet one uncounted exception.
- Fix: none

### A carried review trusts a moved record written by the branch's own run_state.sh

- Location: tools/run_state.sh carried_backed
- Why: closed as not fixed by run-state-backlog: The checker still runs the branch's copy of tools/run_state.sh; recomputing the moved comparison from the main checkout's copy needs the runner-from-a-copy design of the check sandbox group.
- Fix: run the carried check from a trusted copy or refuse to carry across an edit of tools/run_state.sh

### moved carries when the merge keeps the change's side of a file main also edited

- Location: tools/run_state.sh moved_change
- Why: closed as fixed by run-state-backlog: moved also reads the names main changed between the old and the new merge base and reruns the reviews when one is a file of the change, so a conflict resolved by keeping the change's side no longer carries.
- Fix: tools-test: moved reruns the reviews when the merge kept the change's side of a file main edited

### The merger reports the branch head as the merged commit

- Location: tools/run_state.sh phase merged, merged_at
- Why: closed as already fixed by run-state-backlog: phase merged records the squash commit read from main and notes a reported commit that differs as a merge-disagreement, so a branch head reported by the merger is never recorded; the entry's later copies (sprint-24-records note 13, 2 entries) are the same.
- Fix: tools-test: phase merged notes the reported head beside the squash commit

### The planner weighs quality-advisory notes the package step handled

- Location: the planner's input of tools/run_state.sh show
- Why: closed as not fixed by run-state-backlog: Leaving handled quality notes out of what the planner reads changes the planner's input and its brief. needs a change of the delivery workflow or of an agent brief, which this change leaves alone (its scope is tools/run_state.sh and its tools-test cases).
- Fix: leave handled quality notes out of the planner's input

### The planner runs on a first queue item already placed and estimated (secret-patterns retrospective)

- Location: tools/run_state.sh plan_needed
- Why: closed as already fixed by run-state-backlog: Same as the planner that starts only to remove the delivered item: plan-needed answers not needed for the first queue item with its estimate set and no pending note, while plan-apply still takes the delivered item out.
- Fix: tools-test: plan-needed takes the queue head as written

### plan-needed skips the planner for a security note recorded after a later sprint plan (pipeline-diet security Low (3))

- Location: tools/run_state.sh plan_needed
- Why: closed as not fixed by run-state-backlog: placed_by_sprint still applies to every note kind of PLAN_NOTES, a security note included; limiting it to retro and overrun notes changes which findings a planner places and needs the planner's rules read together.
- Fix: apply placed_by_sprint only to retro and overrun notes

### A lane's queue removal conflicts with a sprint-records rewrite of the queue (tab-close-d retro)

- Location: tools/run_state.sh merge_main
- Why: closed as already fixed by run-state-backlog: merge-main keeps the branch's own lane queue and main's other when only the queues conflict, so a lane whose base predates a records merge takes in main with no conflict and no contributor start.
- Fix: tools-test: merge-main keeps the branch's own lane queue and main's other

### The moved check reruns the reviews on a cleanly merged file and misses a hand-resolved one (tab-close-d retro)

- Location: tools/run_state.sh moved_change
- Why: closed as not fixed by run-state-backlog: Comparing the change's own diff of each file before and after the merge, a hand-resolved conflict file always counting, is a redesign of moved_change beyond the name comparison.
- Fix: rerun the reviews exactly when the change's own diff of some file differs

### Groom's listed proof still accepts a comma after an unquoted heading (`groom-proof` security Low (2))

- Location: tools/run_state.sh item_lists
- Why: closed as not fixed by run-state-backlog: A bare heading before a comma still counts as listed; accepting it only at the item's end changes how existing planner lines are read and needs a fixture with a heading that prefixes another.
- Fix: accept a bare heading only at the item's end, or treat a single quote as the others

### Groom's guard against a `#` before a listed heading has no test (`groom-proof` quality advisory)

- Location: tools/run_state.sh item_lists
- Why: closed as already fixed by run-state-backlog: The guard against a # before the heading is exercised by the case whose item holds a bare deeper heading before a comma, which only that guard refuses.
- Fix: tools-test: groom refuses a listed heading standing only inside a deeper unquoted one before a comma

### exception_item now counts a wrapped `beyond the sprint` mark without a test (`groom-proof` quality advisory)

- Location: tools/run_state.sh exception_item
- Why: closed as not fixed by run-state-backlog: No review-due case whose first parenthesis wraps before the mark was added.
- Fix: a review-due case whose item's parenthesis wraps before the mark

### Groom leaves references to the findings files it removes (sprint-17-records retro)

- Location: tools/run_state.sh groom
- Why: closed as fixed by run-state-backlog: groom writes a reference to a findings file it removes as the removed file, bare names included (removed_refs), the fix of the sprint-22-records entry of the same fold.
- Fix: tools-test: the fold writes each findings reference as the removed file

### The token weighting prices a mid-tier start at the cheap tier's price

- Location: tools/run_state.sh add_tokens, TIER_PRICES
- Why: closed as not fixed by run-state-backlog: Pricing each tier by its own price needs a price table the repository does not hold; no price figure is invented here.
- Fix: a price per tier and a label by tier

### Extra push allowed by push --pr-text without a blocked text review

- Location: tools/run_state.sh push_branch --pr-text
- Why: closed as not fixed by run-state-backlog: A pull request text push needs a marker the workflow writes when the text review blocks, and the push already refuses any change but the archived pr.md. needs a change of the delivery workflow or of an agent brief, which this change leaves alone (its scope is tools/run_state.sh and its tools-test cases).
- Fix: a run-state marker written by the workflow when the text review blocks, required by the push

### Shared state a check stage can still write without failing the check

- Location: tools/run_state.sh escaped_paths
- Why: closed as not fixed by run-state-backlog: Writes to shared state a stage can still make without failing the check (other run states, the compile records, the cache, the script itself) cannot be told from the runners' own writes without a sandbox of another user or a log no stage can write; none exists in a single-user checkout.
- Fix: run the stages under an operating-system sandbox or compare against a log of the runners' writes

### The checker's own figures stay writable by a stage during a check

- Location: tools/run_state.sh state_view
- Why: closed as merged by run-state-backlog: Merged into the entry on the run-state comparison leaving out every figure but the measurements: both need the log of caller writes that no stage can write.
- Fix: as the entry it is merged into

### Correction: an edit of tools/run_state.sh by a stage is listed by the scan

- Location: tools/run_state.sh check_wait
- Why: closed as merged by run-state-backlog: Merged into the entry on the check runner started from a copy of HEAD's blob (sprint-26 review security Low (3), note 3): both ask the runner to run from a copy made before the stages start.
- Fix: as the entry it is merged into

### The run-state comparison now leaves out every figure but the measurements (security Low (5), residual widened)

- Location: tools/run_state.sh state_view
- Why: closed as not fixed by run-state-backlog: A stage writes its own run state by an absolute path as the same user; accepting a changed figure only when a caller command logged writing it needs a log no stage can write, which a single-user checkout has none of. This entry stands for the group of run-state forgery entries (the checker's figures, forged metric lines, planted notes and closing phases).
- Fix: snapshot the metric lines at escape_mark and accept only logged writes

### Security: a stage's detached child can write after the escape scan (security Low (6), still present at package)

- Location: tools/run_state.sh stage_launch
- Why: closed as not fixed by run-state-backlog: A stage's detached child (setsid, nohup) can write after the escape scan; stopping it needs each stage in its own session and a kill of that group before the scan, which stage_launch cannot do without setsid in every environment.
- Fix: run each stage in its own process group and kill it before escaped_paths

### Security: a stage can forge its own run state's metric lines during a check (security Low (6), still present at package)

- Location: tools/run_state.sh state_view
- Why: closed as merged by run-state-backlog: Merged into the entry on the run-state comparison leaving out every figure but the measurements, whose design (a log of caller writes) covers forged metric lines.
- Fix: as the entry it is merged into

### Security: a stage can plant notes and closing phases in its own run state during a check (security Low (6), still present at package)

- Location: tools/run_state.sh state_view
- Why: closed as merged by run-state-backlog: Merged into the entry on the run-state comparison leaving out every figure but the measurements, whose design covers planted notes and closing phases.
- Fix: as the entry it is merged into

### The check-pass output budget line changed no decision

- Location: tools/run_state.sh spent_line
- Why: closed as merged by run-state-backlog: Merged into the entry on the check-pass budget line projecting 6 total tokens per output token: one figure, OUTPUT_SHARE.
- Fix: as the entry it is merged into

### An advisory-only fix round counts as rework and reruns every stage and review

- Location: tools/run_state.sh metric.rework, the workflow's fix round
- Why: closed as not fixed by run-state-backlog: Counting an advisory-only round apart is a rule of the delivery workflow and docs/goals.md. needs a change of the delivery workflow or of an agent brief, which this change leaves alone (its scope is tools/run_state.sh and its tools-test cases).
- Fix: count an advisory-only round apart from a blocking one

### review-due no longer bounds uncounted merges

- Location: tools/run_state.sh review_due
- Why: closed as not fixed by run-state-backlog: review-due still has no upper bound on uncounted merges; a bound needs a number the user decides, and the queue's exception rules moved since the entry.
- Fix: an upper bound on the uncounted merges of a sprint, with a case

### Security: a lane check accepts another lane's branch moved or its worktree files edited (security Low (6), reported three times, still present at package)

- Location: tools/run_state.sh refs_view, lane_branches, tree_scan
- Why: closed as not fixed by run-state-backlog: Recording each lane branch's object at escape_mark and scanning the other lanes' worktrees is a design of the check sandbox group still open.
- Fix: record each lane branch at escape_mark and compare

### Security: a stage-made worktree puts any local branch on the scan's skip list (security Low (6), reported twice, still present at package)

- Location: tools/run_state.sh lane_branches, lane_open
- Why: closed as not fixed by run-state-backlog: Skipping only the branches checked out at the mark, and refusing an existing branch with no run state, is a design of the check sandbox group still open.
- Fix: skip only branches checked out at escape_mark

### Quality: a check between the merger's lane-close and branch deletion fails as the references changed

- Location: tools/run_state.sh refs_view
- Why: closed as not fixed by run-state-backlog: A rare false failure between the merger's lane-close and the branch deletion; leaving a branch out needs the lane-close order changed.
- Fix: leave out a branch present at the mark and gone at the scan only when no worktree held it

### plan-needed names only the first failing review while merged_since clears every one before the planner's time

- Location: tools/run_state.sh plan_needed
- Why: closed as fixed by run-state-backlog: plan-needed names every failing review run, the first as before and each other after a semicolon, as merged_since clears each of them; the workflow's planReview text is not changed.
- Fix: tools-test: plan-needed names every failing periodic security review

### A lane's check fails on another lane's write into the main checkout's build/metrics

- Location: tools/run_state.sh clone_drop, main_scan
- Why: closed as already fixed by run-state-backlog: A lane's runner and bench write their figures under the lane's own build/ (METRICS_OUT is the lane's path while its worktree stands), and main_scan leaves the main checkout's build/ logs; a write there from another lane is not the lane's.
- Fix: tools-test: a check's metrics land under the change's lane

### A security review after a quality-only fix reads the whole branch again

- Location: the backlog heading list under review-trust-lows
- Why: closed as not fixed by run-state-backlog: A pointer entry to later parts of review-trust-lows, which name no code of tools/run_state.sh to change here.
- Fix: the later parts of review-trust-lows

### named_history and named_since repeat the groom pathspec (sprint-24 review quality)

- Location: tools/run_state.sh named_history, named_since
- Why: closed as not fixed by run-state-backlog: The groom pathspec is still written in both calls and a third place; building it once from queue_files is a refactor with no behavior to test.
- Fix: build the pathspec once from queue_files

### backlog-move's mismatch refusal has no test

- Location: tools/run_state.sh backlog_move
- Why: closed as not fixed by run-state-backlog: The mismatch refusal of backlog-move still has no case; no fixture makes the folder differ without a hook into the filing.
- Fix: let a test inject a filing that drops a line

### A refused filing leaves the entries filed before it in the folder

- Location: tools/run_state.sh file_entries
- Why: closed as fixed by run-state-backlog: file_entries checks every target (links, directories) in a first pass that writes none, so a refused filing leaves the earlier entries out of the folder and filing again files none twice.
- Fix: tools-test: a refused later entry leaves the earlier entry out of the folder

### plan-apply overwrote the lane queue with a plan older than the branch's queue

- Location: tools/run_state.sh plan_apply
- Why: closed as fixed by run-state-backlog: plan-apply refuses a lane queue plan that names, as a numbered item, a change the lane's history file already holds a row of, saying so and leaving the queue as it was.
- Fix: tools-test: plan-apply refuses a plan that queues a change the lane's history holds a row of

### plan-apply copies a plan older than the branch's queue

- Location: tools/run_state.sh plan_apply
- Why: closed as merged by run-state-backlog: Merged into the entry on plan-apply overwriting the queue with an older plan: the same refusal.
- Fix: as the entry it is merged into

### A change named only in a lane exception line resolves to the wrong lane (facet-design-doc retro note 16)

- Location: tools/run_state.sh item_named, lane_of
- Why: closed as fixed by run-state-backlog: A change named in backticks in a queue's The user-approved exception paragraph takes that queue's lane, so its history step writes that lane's file.
- Fix: tools-test: a change named only in a queue's exception line takes that queue's lane

### self_fix has no history column

- Location: tools/run_state.sh HEADER, history_row
- Why: closed as not fixed by run-state-backlog: A self_fix column adds a column 25 to both lane histories and the workflow's metric line, a records change.
- Fix: append the column and pad both lane files

### An exception paragraph naming a change without backticks leaves it counted in the sprint

- Location: tools/run_state.sh queue_class, tools/docs_lint.sh
- Why: closed as not fixed by run-state-backlog: Reading a bare change name in an exception paragraph, or refusing it in docs-lint, edits tools/docs_lint.sh, outside this file.
- Fix: read the name with or without backticks or refuse the bare form in docs-lint

### An exception paragraph naming a change without backticks leaves it counted

- Location: tools/run_state.sh queue_class, tools/docs_lint.sh
- Why: closed as merged by run-state-backlog: Merged into the entry on an exception paragraph naming a change without backticks leaving it counted in the sprint: the same two readers.
- Fix: as the entry it is merged into

### lane_of puts a docs change briefed to the feature lane in the backlog lane, so its history step writes a backlog file

- Location: tools/run_state.sh lane_of
- Why: closed as merged by run-state-backlog: Merged into the entry on a change named only in a lane exception line: the same fix, whose test is a docs change briefed to the feature lane.
- Fix: as the entry it is merged into

### A write outside the check clone is detected but never reverted (security Low (4))

- Location: tools/run_state.sh escaped_records
- Why: closed as not fixed by run-state-backlog: The escaped records are rewritten as escaped and the compile record cleared, but the planted file itself is not removed; deleting build outputs needs the list of those a stage may legitimately leave.
- Fix: delete or quarantine the escaped outputs under the main checkout's build/

### The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)

- Location: tools/run_state.sh phase merged (covers 2 identical entries)
- Why: closed as already fixed by run-state-backlog: phase merged records the commit git gives for main (the squash commit) and notes the reported one that differs as a merge-disagreement, keeping main's commit.
- Fix: tools-test: phase merged records the merge at the squash commit, not the reported head

### backlog-move is a one-shot migration left in run_state.sh (sprint-25 review quality)

- Location: tools/run_state.sh backlog_move
- Why: closed as not fixed by run-state-backlog: backlog-move's cases also pin the filing (links, dotted names, Also and Category lines) that groom shares through file_entries; removing the command with them loses that coverage, and RECORDS_RE is the merge gate's rule.
- Fix: remove backlog-move with its cases once the filing has its own

### In this sprint's diff (contributor-self-check). The checker now skips at tools/run_state.sh:1077 (sprint-26 review security Low (3), note 3)

- Location: tools/run_state.sh check_wait
- Why: closed as not fixed by run-state-backlog: The runner still starts from the working tree's copy; copying HEAD's blob would move its sibling files (rules.sh, the pid file's process match) and is a design of the check sandbox group still open.
- Fix: start the runner from a copy of HEAD's blob

### The planner's sprint queues reach a records change failing the docs-lint queue check (sprint-26-records retro note 4)

- Location: tools/run_state.sh plan_apply, tools/docs_lint.sh
- Why: closed as not fixed by run-state-backlog: Refusing a planner queue that fails the docs-lint queue check needs that check callable from run_state.sh, which edits docs_lint.sh.
- Fix: run the queue check on the planner's queue before copying it

### Head-form notes record a head git confirms (folded-row retro note 4, notes 1 and 5)

- Location: tools/run_state.sh, the workflow's head check
- Why: closed as not fixed by run-state-backlog: The head-form note is written by the workflow's head check. needs a change of the delivery workflow or of an agent brief, which this change leaves alone (its scope is tools/run_state.sh and its tools-test cases).
- Fix: no record when git corrects a head to the same commit

### The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)

- Location: tools/run_state.sh budget_line (covers 2 identical entries)
- Why: closed as gone by run-state-backlog: budget_line prints the recorded total tokens and no set-apart figure; the clipping at zero of the earlier line is gone with it.
- Fix: none

## tools/run_state.sh groom: security entries removed without a named fixing commit

- Location: tools/run_state.sh groom
- Why: closed as already fixed by run-state-backlog: A security entry leaves only by a merged item's heading (listed) or its fixing commit in the sprint (fixed); groom refuses any other kind for it, so no security entry goes without a named proof.
- Fix: tools-test: groom keeps a disputed security entry and a security finding inside a group

### The check-pass output-token note fires in runs that end under the total budget (ui-groups retro note 3)

- Location: tools/run_state.sh spent_line
- Why: closed as merged by run-state-backlog: Merged into the entry on the check-pass budget line projecting 6 total tokens per output token: one figure, OUTPUT_SHARE.
- Fix: as the entry it is merged into

### A records check is voided by build/dev/carat.timing escaping the check clone (sprint-27-records note 1)

- Location: tools/run_state.sh escaped_note, clone_make
- Why: closed as already fixed by run-state-backlog: dev-build writes build/dev/carat.timing in the check clone's own build/, which has no link to the lane's, so no stage writes the lane's file and the check records no security-escape note for it.
- Fix: tools-test: check runs the metrics stage in its clone without METRICS_OUT

### A check is voided as escaped for a file the dev-build stage is declared to write (sprint-27-records note 1, security-escape)

- Location: tools/run_state.sh compile_outputs, escaped_paths
- Why: closed as already fixed by run-state-backlog: The declared outputs of dev-build are read in the check clone, which holds its own build/; nothing in the lane's build/ is compared with them, so the declared output is not an escape.
- Fix: tools-test: dev-build keeps its code key across a commit to test/ and bench/, its outputs read in the clone

### A carrying delivery that never merges strands the sprint plan

- Location: tools/run_state.sh groom, sprint.carrier
- Why: closed as not fixed by run-state-backlog: A carrier that never merges still holds the plan until its file is removed by hand; releasing it by a run state check needs the carrier's lifecycle decided with the groom proof entries.
- Fix: treat a carrier whose run state is gone or stopped as no carrier, or add a release command

### groom-proof checks a carrier's plan line against evidence the carrier controls

- Location: tools/run_state.sh groom_proof
- Why: closed as not fixed by run-state-backlog: Judging a carrier's plan lines against the fork point is the design of the groom proof group still open (this entry, the fixed proof against the branch's commits, and the shared proof function).
- Fix: judge fixed and listed lines against the fork point only

### groom's fixed proof takes a commit of the carrying branch (sprint-29 review security Low (4))

- Location: tools/run_state.sh groom_proof, groom
- Why: closed as not fixed by run-state-backlog: Counting only commits merged before the carrier (merge-base --is-ancestor WORD FORK) needs the fork point passed to the proof and the gate's reading changed with it (tools/gates.sh).
- Fix: require the fixing commit to be an ancestor of the fork point

### groom and groom_proof copy the fixed proof (sprint-29 review quality)

- Location: tools/run_state.sh groom, groom_proof
- Why: closed as not fixed by run-state-backlog: One function returning the proof's failure reason for both callers is the refactor that lands with the fork-point proof of the entry above.
- Fix: one function returning the reason, groom printing it and groom_proof testing it

### Stored figures of main trust the saving lane's measuring script

- Location: tools/run_state.sh base_figures save
- Why: closed as already fixed by run-state-backlog: save measures with the script of tmp/.base, which it requires to be at origin/main with its tracked files unchanged and no untracked file, and with the outputs removed before the build, so the stored figures come from main's own script, never copied from a file anyone could write.
- Fix: tools-test: base-figures save refuses an untracked source file in the base

### The in-run budget line prices total tokens at 6 per output token (lsp-container-b retro note 13, sprint-security retro note 8)

- Location: tools/run_state.sh OUTPUT_SHARE, spent_line
- Why: closed as merged by run-state-backlog: Merged into the entry on the check-pass budget line projecting 6 total tokens per output token: one figure, OUTPUT_SHARE.
- Fix: as the entry it is merged into

### A change named in the other lane's exception paragraph takes that lane (run-state-backlog quality advisory)

- Location: tools/run_state.sh item_named, lane_of
- Why: item_named now counts a backticked name inside a paragraph of The user-approved exception as naming the change, and lane_of reads the feature queue first, so a change named in both queues' paragraphs, or only in the other lane's, takes the feature lane.
- Fix: read the paragraph's own lane clause, or take the lane of the queue whose paragraph says the change runs first in it, with a tools-test case for a name in the other queue's paragraph

### The first pass of file_entries creates directories before a refusal (run-state-backlog quality advisory)

- Location: tools/run_state.sh file_entries, entries_awk
- Why: the dry pass makes each backlog directory it checks, so a filing refused later leaves empty directories, no entry; harmless to the folder's entries but visible in git status of ignored paths only.
- Fix: test the directory chain with test -d and test -L instead of mkdir in the dry pass

### Correction: the build/NAME.log exemption of main_scan is removed (security Low (3), tools/run_state.sh)

- Location: `main_scan` in `tools/run_state.sh`, tools-test cases for `build/NAME.log`. The exemption of a regular single-link `build/NAME.log` of the main checkout (added for the entries "A concurrent lane's benchmark log fails another lane's check", both copies) let a stage forge a log a later reader trusts without voiding the check.
- Outcome: not fixed as exempted; the exemption is gone. Every log changed in the main checkout during a check is reported; a lane that owns one names it in `LANE_WRITTEN`, which ends the check in an escaped verdict with no fix round, as `build/metrics` does. The benchmark agent's own steps already run in the lane worktree, so its log lands under the lane's `build/`.
- Why it matters: the two benchmark-log entries read as fixed by the exemption now stand closed by `LANE_WRITTEN` and the lane-local logs instead; a deployment that wants another lane's log tolerated must list its path.
