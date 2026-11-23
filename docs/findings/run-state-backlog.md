
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
