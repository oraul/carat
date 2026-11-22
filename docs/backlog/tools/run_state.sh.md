# Backlog: tools/run_state.sh

## agent_hooks misses frontmatter keys that widen an agent's authority

- Where: `agent_hooks` in `tools/run_state.sh` (line 701), which counts only `tools` and hook lines as the guard's wiring and reads `git diff` with `2>/dev/null`. Security Low (6) of `pipeline-speed` at b0df2ac092ed, and a quality advisory at 1d187291be30.
- Why it matters: adding `permissionMode:`, `mcpServers:`, `disallowedTools:`, or a list-form tool item to an agent does not make the periodic review due, and a failing `git diff` fails open, so the review is skipped exactly when the agent's authority changes.
- Fix outline: treat any changed line between an agent file's frontmatter delimiters other than `name`, `description`, and `model` as guard and gates, and report the review due when the diff fails, with a `tools/tools_test.sh` case. Queued in the backlog-items change of `docs/queue.md` (review triggers).
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-04

## Agents leave scratch files in the repository root

- Where: the repository root, where agents left `build_check_out_tmp` and `.err` twice; the briefs under `.claude/agents/` name no place for scratch output, and the push gates of `tools/run_state.sh push` and `tools/gates.sh` do not look at untracked files (the checker and the security reviewer test `git status --porcelain --untracked-files=no`). The user's request in the brief of `pipeline-speed-b`.
- Why it matters: an untracked file outside `build/`, `dist/`, and `tmp/` can be staged by a later `git add` and reach a pull request, and it shows in every `git status` of the next run.
- Fix outline: the agents' briefs send scratch output under `build/` or `tmp/`, and a push gate refuses an untracked file outside the ignored paths, with a `tools/tools_test.sh` case. Queued in `merge-gate-tidy`.
- Also: tools/gates.sh, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## A compile pass is cached whatever make command ran it

- Where: `tools/run_state.sh` line 352, the compile-stage skip of `check`, and `compiled_set` and `compiled_same`, which key a pass in `build/pipeline/compiled` by the code key and the outputs only. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: a check run outside the workflow with `MAKE=true` records a diagnose pass that never ran diagnose, which CI does not run either, and every later change on that code key skips it, the forged-check case the design names as its risk.
- Fix outline: fold `make_cmd` into the cached line or the key in `compiled_set` and `compiled_same`, so only a pass by the same make command skips, with a `tools/tools_test.sh` case that a pass under `MAKE=true` does not skip a later run under `make`. Queued in `check-skip`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## The run state header omits the compiled-KEY stage suffix

- Where: the `stage.NAME` line of the header of `tools/run_state.sh` (line 9), which names only the `carried-from-COMMIT` suffix. Quality advisory at e8c5b43 in `pipeline-speed-c`.
- Why it matters: `check` now writes a `compiled-KEY` suffix too, and the header is where a reader of a run state learns its format.
- Fix outline: add 'or compiled-KEY when check skipped a compile stage on its code key' to that line. Queued in `run-resume`.
- Category: pipeline
- Added: 2026-11-04

## dev-build's code key changes with test/ and bench/

- Where: `code_key` in `tools/run_state.sh` (line 156 at f31f4e8), which hashes `test/` and `bench/` for every compile stage. Periodic quality advisory at f31f4e8.
- Why it matters: a test-only commit on main changes the key of `dev-build`, which compiles only `bin/carat.rb`, so the next change compiles again where it could skip.
- Fix outline: a per-stage key that leaves `test/` and `bench/` out of `dev-build`'s, with a `tools/tools_test.sh` case. Queued in `check-skip`.
- Also: bin/carat.rb, tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-04

## check_lost and check_wait re-read the run state and the pid file inline

- Where: `tools/run_state.sh` line 485 (`check_lost` greps and seds the state file, duplicating `keys_under` at line 937) and line 517 (`check_wait` reads the pid file although `read_pid` at line 569 does, and the lost-runner path removes it twice, lines 530 and 533). Quality advisories of `pipeline-durability`.
- Why it matters: two readers of the state file format and the pid file can drift apart, and the double removal hides which branch owns the cleanup.
- Fix outline: take the first `stage.*` entry whose value starts with `running` from `keys_under stage.`; call `read_pid` in `check_wait` and drop the `rm` in its `elif` branch.
- Category: pipeline
- Added: 2026-11-05

## An interrupted stage is recorded at the runner's head, not its start commit

- Where: `tools/run_state.sh` line 476 (`check_signalled` writes the stage record with `$head`, while `run_stage` writes each stage at the commit it started on). Quality advisory of `pipeline-durability`.
- Why it matters: the two writers of a stage record can disagree when HEAD moved between stages, so a killed stage can be attributed to a commit it never ran on.
- Fix outline: keep the stage's `at` in a global beside `running_stage` and write the killed record with it.
- Category: pipeline
- Added: 2026-11-05

## The run state's writer has no lock beside the detached check runner

- Where: `tools/run_state.sh` line 280 (`write_key`, a read-modify-rename with no lock, and `drop_key`), written by the detached runner (`check_run`, `run_stage` at a stage's start and end) while the checker's metric line on a rerun and `check_lost` in the waiter also write. Periodic quality advisory at eb0f1be.
- Why it matters: two writers at once can drop each other's key, so the run state forgets a stage record, a metric, or a phase, and a resume or gate acts on a wrong picture.
- Fix outline: take a lock around `write_key` and `drop_key` (a lock directory with retry, or `flock` where present), or have the runner write stage records only to its own file that `check` reads. Queued in `check-runner-safety`.
- Category: pipeline
- Added: 2026-11-05

## A lost check runner leaves its make running while a second one starts

- Where: `tools/run_state.sh` line 530 (`check_lost` records the stage as killed but leaves the stage's make and compilers in the dead runner's process group) and line 517 (the superseded branch starts a new runner when the old one has not stopped after 150 pauses). Periodic quality advisory at eb0f1be.
- Why it matters: two builds write the same `build/` directories at once, so a stage can pass or fail on the other runner's output.
- Fix outline: stop the dead runner's process group in `check_lost`, and refuse or wait instead of starting a second runner while the old one is alive. Queued in `check-runner-safety`.
- Category: pipeline
- Added: 2026-11-05

## A detached check runner outlives a stopped run and shares build/

- Where: `tools/run_state.sh` line 536 (the runner of one change keeps running after its run stops, and a check of another change builds into the same `build/`). Security Low (4) of the periodic review at eb0f1be.
- Why it matters: a stale runner can overwrite another change's build outputs or stage records, so a check passes on code it did not build.
- Fix outline: one check pid file for every change, so a new check stops any live runner, and record the stage as superseded when the tracked tree (git status or a tree hash), not only HEAD, changed while it ran. Queued in `check-runner-safety`.
- Category: security
- Added: 2026-11-05

## The check verdict is read from a log read agents can write

- Where: `tools/run_state.sh` line 439 (the verdict is the last line of `build/stages/CHANGE/check.log`, inside the redirect-writable `build/stages/`). Security Low (3) of the periodic review at eb0f1be.
- Why it matters: a read-profile agent can append a forged pass line so `check` exits 0; the stages gates still need the records, which limits it.
- Fix outline: keep `check.log` and `check.pid` outside `build/stages/`, or derive the verdict from the run state's stage records. Queued in `check-runner-safety`.
- Category: security
- Added: 2026-11-05

## Recording merged deletes refs on origin from the generic key writer

- Where: `tools/run_state.sh` line 1344 (`set CHANGE merged` pushes a ref deletion to origin, a network side effect hidden in the plain key writer beside the `push` and `abandon` paths). Quality advisory of `backup-secret-scan`.
- Why it matters: a reader of `set` does not expect a push, and a failed deletion surfaces in a step that only records.
- Fix outline: keep `set` a plain write and have the merger call `abandon` (or a `merged` command) explicitly after recording `merged`.
- Category: pipeline
- Added: 2026-11-05

## drop_backup joins the ref names by unquoted word splitting

- Where: `tools/run_state.sh` line 716 (`$(echo $refs)` outside the line the SC2086 disable covers). Quality advisory of `backup-secret-scan`.
- Why it matters: a glob character in a ref name would expand against the working directory, and the disable comment hides the intent.
- Fix outline: print the names with `printf '%s ' $refs` under the disable, or `tr '\n' ' '`.
- Category: pipeline
- Added: 2026-11-05

## abandon reports no backup left when origin is unreachable

- Where: `tools/run_state.sh` line 708 (`drop_backup` ignores a failed `git ls-remote`, the pipeline's status being awk's) and line 1352 (`abandon` then prints that no backup of the branch is left on origin). Periodic quality blocking at d386c74.
- Why it matters: with origin unreachable the record is dropped and the user is told nothing is left, while refs holding unreviewed commits may stay on the public origin.
- Fix outline: take `ls-remote`'s output and status separately; on failure keep the record, return 1, and name `abandon` in the message, with a `tools/tools_test.sh` case against an unreachable origin. Queued in `backup-records`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-05

## The backup's base record outlives the backup

- Where: `tools/run_state.sh` line 753 (`backup` writes `base` before the gates and the push) and line 718 (`drop_backup` drops only `backup`). Periodic quality advisory at d386c74.
- Why it matters: `base` survives a refused backup, the push, the merge, and `abandon`, naming a ref that no longer exists.
- Fix outline: write `base` after the push succeeds and drop it beside `backup`. Queued in `backup-records`.
- Category: pipeline
- Added: 2026-11-05

## The backup runs the branch's own gates

- Where: `tools/run_state.sh` line 754 (`backup` runs the branch's `tools/gates.sh` and `tools/rules.sh`, which the run may have edited before any review). Periodic security Low (5) at d386c74.
- Why it matters: a weakened secret pattern on the branch lets a secret reach the backup ref unchecked.
- Fix outline: run the backup gates from a worktree of `origin/main`, as the merge gates do, with the base and change passed in. Queued in `backup-records`.
- Also: tools/gates.sh, tools/rules.sh
- Category: security
- Added: 2026-11-05

## The run_state.sh bullet reads as if it listed every command

- Where: the Commands bullet of `sh tools/run_state.sh` in `CLAUDE.md` (line 231), "every command in the script's header:" followed by seven commands. Quality advisory of `docs-currency` at 13473da.
- Why it matters: a reader takes the seven for the whole set and misses `scope`, `bench`, `usage`, `plan-needed`, and the others the header lists.
- Fix outline: reword it to "a change's run state, every command listed in the script's header; those an agent acts on:" before the list, within the file's budget.
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-05

## run_state.sh became executable in run-budgets

- Where: `tools/run_state.sh`, whose mode changed from 100644 to 100755 in `run-budgets`, unmentioned in its proposal. Quality advisory of `run-budgets`, raised twice.
- Why it matters: it is always run as `sh tools/run_state.sh`, so the mode change is unrelated noise that the next diff of the file carries.
- Fix outline: restore mode 100644 with `git update-index --chmod=-x`.
- Category: pipeline
- Added: 2026-11-06

## spent_line repeats budget_line's budget lookup

- Where: `spent_line` in `tools/run_state.sh` (line 1138 at `run-budgets`) repeats the size-to-budget lookup of `budget_line` (line 1092, `printf TOKEN_BUDGETS | sed`). Quality advisory of `run-budgets`.
- Why it matters: two copies of one table lookup drift when the table's format changes.
- Fix outline: extract one `budget_of SIZE` helper that both call, covered by the existing `tools/tools_test.sh` cases.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-06

## A pipeline fix rode in the hover pull request

- Where: the `runner_finish` fix in `tools/run_state.sh` line 697 at 41297d6 (commit 13de267, with its `tools/tools_test.sh` case), on `feature/quick-docs`. Two quality advisories in `quick-docs`.
- Why it matters: CLAUDE.md asks one logical change and one type per squash commit; the CI fix the branch needed is a `fix` of the tooling inside a `feat` pull request, so its history is hidden under the hover change. The pull request's Notes name it as that CI fix.
- Fix outline: when a CI fix touches tooling outside the change, deliver it as its own change ahead of the feature, or have the push step name it in the pull request's Notes as this one does.
- Also: tools/tools_test.sh, CLAUDE.md
- Category: pipeline
- Added: 2026-11-07

## A link planted in the check clone's build directory survives

- Where: `clone_drop` in `tools/run_state.sh` line 566 at b0dd342 copies `build/` into the carry with `cp -RP`. Periodic security Low (5). Queued in `check-runner-safety`.
- Why it matters: a symbolic link a stage plants in `build/` reaches `build/stages/CHANGE/carry` and the next clone, so the clone is isolated by environment only.
- Fix outline: drop links from the carry or refuse them when copying, with a case.
- Category: security
- Added: 2026-11-07

## The runner's wait is longer than it says, in two copies

- Where: `runner_finish` in `tools/run_state.sh` line 698 and `check_wait` at line 646, at 38628bb (periodic quality). Queued in `check-runner-safety`.
- Why it matters: the 30-second wait is 150 pauses, 150 seconds where a pause falls back to one second, and the loop is copied.
- Fix outline: one wait helper bounded by elapsed seconds, used by both.
- Category: pipeline
- Added: 2026-11-09

## A run_state.sh paragraph splits its Usage list

- Where: `tools/run_state.sh` lines 63 to 66 at 38628bb (periodic quality, raised twice). Queued in `run-budgets-tidy`.
- Why it matters: the paragraph on refused keys sits between the set and phase entries.
- Fix outline: move it above or below the list.
- Raised again as "The run_state header splits its usage list": Where: `tools/run_state.sh:71`. Periodic quality. Why it matters: the refusal paragraph sits inside the list the usage prints. Fix outline: move it after the list. Queue item `run-budgets-tidy`.
- Category: pipeline
- Added: 2026-11-09

## The check-pass budget line projects 6 total tokens per output token

- Where: the check-pass budget projection in `tools/run_state.sh`. Retrospective of `implement-contracts-b` (#86). Queue item `phase-shares`.
- Why it matters: total per output token in the last 10 rows is 5.53 to 11.56 (median 7.74, 8 of 10 above 6); all three medium rows went over 1.2M, and #86's check pass said under at 146,753 output while the run ended at 1,998,500 total.
- Fix outline: project from the recorded ratio of comparable rows; the acceptance is the check-pass verdict matching the final over the next three runs.
- Category: pipeline
- Added: 2026-11-09

## A failed backup is retried by every start and never recorded

- Where: `tools/run_state.sh backup` and the contributor's start. Retrospective of `definitions`, queued in `backup-records`. Raised again at bff9a02 (#96): the backup failed on every try; queue item `backup-records`.
- Why it matters: four contributor starts made 11 attempts, all refused by the remote, with no run-state key, leaving 10 or more commits local only until the package push.
- Fix outline: write a run-state key on a failed backup, make at most one attempt per later start when it is set, and name the unbacked commits in the report, with a case.
- Category: pipeline
- Added: 2026-11-10

## drop_key repeats write_key's rewrite

- Where: `tools/run_state.sh:309`. Periodic quality at bd86828.
- Why it matters: two copies of the locked rewrite of the state file.
- Fix outline: one rewrite helper, or gone with the Ruby port. Queue item `harness-ruby`.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at tools/run_state.sh:406

- Where: `tools/run_state.sh:406`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: main_stages is a one-time migration shim: once this change merges every origin/main defines FAST_STAGES, so the function and its two tools_test cases are dead code.
- Fix outline: remove them in the next tooling change.
- Category: pipeline
- Added: 2026-11-11

## delivery-speed quality advisory at tools/run_state.sh:1217

- Where: `tools/run_state.sh:1217`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: late findings are appended as one heading of bare bullets, not the Where, Why it matters, Fix outline entry shape the rest of docs/backlog.md and CLAUDE.md use.
- Fix outline: write one entry per finding in that shape, or document the grouped form in the backlog header.
- Also: CLAUDE.md
- Category: pipeline
- Added: 2026-11-11

## pr-by-tag quality advisory at tools/run_state.sh:716

- Where: `tools/run_state.sh:716`. Delivery review of `pr-by-tag` (quality advisory) at 742ba5f.
- Why it matters: CHECK_BIN repeats the Makefile's DEV_BIN path and the run_state.sh entry of docs/codebase-map.md does not name it.
- Fix outline: name CHECK_BIN beside in_clone in the map entry, its comment naming DEV_BIN as the one source.
- Also: Makefile, docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-11

### Check clone's binary path not named in the map (late `pr-by-tag` quality advisory)

- Location: `tools/run_state.sh` `CHECK_BIN` (beside `in_clone`), and the `run_state.sh` entry of `docs/codebase-map.md`.
- Why it matters: `CHECK_BIN` repeats the Makefile's `DEV_BIN` path, so a change to one leaves the detached check running a stale or missing binary, and the map entry does not name it, so a reader cannot find it.
- Fix outline: name `CHECK_BIN` beside `in_clone` in the map entry and let its comment name `DEV_BIN` as the one source; a tools-test case fails when the two paths differ.
- Also: docs/codebase-map.md, Makefile
- Category: pipeline
- Added: 2026-11-11

### Groom's listed check matches any archive name suffix (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1358`, the archive check `openspec/changes/archive/*-WORD`.
- Why it matters: it matches any archived change whose name ends in -WORD, so `listed review` passes on `periodic-review`.
- Fix outline: match the date prefix exactly, `archive/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-WORD`.
- Category: pipeline
- Added: 2026-11-11

### Groom lets every copy of a duplicated finding go (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1373`.
- Why it matters: duplicate lines naming every heading at one location each pass, since `backlog_dups` reads the unmodified file, so all copies of a finding can be removed with no `groomed.md` entry; and `grep -F '$at: '` matches a location as a substring of a longer one.
- Fix outline: refuse a `groom.txt` that removes every heading at a location unless `groomed.md` names it, and compare the location field exactly with awk.
- Category: pipeline
- Added: 2026-11-11

### plan-needed treats an unreviewed sprint plan as waiting (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1423` `plan_needed`, the planner's keep rule (`.claude/agents/planner.md:25`), and the package brief.
- Why it matters: they treat any marker as a waiting plan through `sprint_waiting` without `sprint_reviewed`, so while `groom` holds an unreviewed plan deliveries take `build/plan/queue.md`'s head and the planner-not-run package path removes the item from `docs/queue.md`, where it is not, leaving the delivered change at the head of `build/plan/queue.md`.
- Fix outline: one helper (`sprint_waiting` and `sprint_reviewed`) used by `review_due`, `groom`, and `plan_needed`.
- Also: .claude/agents/planner.md
- Category: pipeline
- Added: 2026-11-11

### Sprint after a sixth merge reviews a change twice (`sprint-planning` quality advisory)

- Location: `tools/run_state.sh:1255` `sprint_names` and the due line, `sprint_row` (line 1324).
- Why it matters: when /sprint runs after a sixth merge, `sprint_names` and the due line list every change since the last sprint and the combined diff runs to `origin/main`, but `sprint_row` closes the sprint at its fifth row, so the sixth change is reviewed in this sprint and counted again in the next.
- Fix outline: cut `sprint_names` at `SPRINT_SIZE` and end the combined diff at the fifth change's merged commit.
- Category: pipeline
- Added: 2026-11-11

### Usage header splits review-due's description (`ci-time` quality advisory)

- Location: `tools/run_state.sh:137`.
- Why it matters: the ci-stages and tokens usage lines are inserted inside review-due's description, splitting it in the header that usage prints.
- Fix outline: move the two entries after the end of review-due's block.
- Category: pipeline
- Added: 2026-11-11

### Stale comment on who runs ci-stages (`ci-time` quality advisory)

- Location: `tools/run_state.sh:1184`.
- Why it matters: the comment says the merger's green and red lines run ci-stages, but the workflow queues it for the record or closing start and the merger's lines never run it.
- Fix outline: say the record or closing start runs it after CI finished.
- Category: pipeline
- Added: 2026-11-11

### ci-stages may drop every step on fractional seconds (`ci-time` quality advisory)

- Location: `tools/run_state.sh:1194`.
- Why it matters: the awk keeps only whole seconds, so if gh's fromdateiso8601 returns fractional seconds for GitHub's millisecond step timestamps every step is dropped and nothing is recorded; the fake gh never runs the jq.
- Fix outline: floor the difference in the jq, or accept a decimal and round in awk.
- Category: pipeline
- Added: 2026-11-11

### ci-stages step name can exceed 32 characters (`ci-time` quality advisory)

- Location: `tools/run_state.sh:1197`.
- Why it matters: a step name longer than 32 characters with no underscore in its first 33 stays 33 characters, against the documented limit of 32.
- Fix outline: fall back to substr(name, 1, 32) when the sub removes nothing.
- Category: pipeline
- Added: 2026-11-11

## records-once quality advisory at tools/run_state.sh:233

- Location: tools/run_state.sh:233, with the stage carry at line 475 and the quality fix scope at line 818.
- Why: TEST_ONLY now admits docs/sprints.tsv, which changes the stage carry and the quality fix scope, but no tools-test case covers a sprints.tsv-only commit in either.
- Fix outline: add an expect that a docs/sprints.tsv-only commit carries a compile stage and is left out of the fix scope.
- Also: docs/sprints.tsv
- Category: pipeline
- Added: 2026-11-12

## records-once quality advisory at tools/run_state.sh:1586

- Location: tools/run_state.sh:1586 and the dispatch at line 1697.
- Why: records_excluded repeats the change-name case of the dispatch, two copies that can drift.
- Fix outline: one change_name helper that both call.
- Category: pipeline
- Added: 2026-11-12

## history and groom skip on records of a branch that never merges (sprint-2 sweep)

- Where: `history` in `tools/run_state.sh:1372` skips a change whose run state records a row on any branch; `groom` retires the sprint marker clone-wide. Periodic quality at 8b9bf6a, raised twice.
- Why it matters: a package-step branch that never merges (a run stopped after three red CI rounds) loses its metrics row, its late findings, or the whole sprint plan for good.
- Fix outline: skip only when the recorded row is on the current base, and retire the marker only once the sprint row reaches the base, with a tools case for a stopped run. Pool item `sprint-tidy`.
- Category: pipeline
- Added: 2026-11-14

### Path-scope helpers split the stage-list comments in run_state.sh

- Location: tools/run_state.sh:461
- Why: scope_paths and out_of_scope were inserted between the comment blocks of check_stages and main_stages (lines 451-460) and main_stages, so those comments now sit above scope_paths and main_stages has none.
- Fix: move the two helpers and their comments above line 451, leaving the main_stages comment directly above main_stages.
- Category: pipeline
- Added: 2026-11-16

### Tests-only carry runs before the path scope in run_state.sh

- Location: tools/run_state.sh:503
- Why: the tests-only carry runs before the path scope, so a stage recorded scoped (never run) on a documentation-only commit is carried as carried-from after a later tests-only fix: dev-build is carried without building the binary test-run's smoke test uses, a false failure in that rare path.
- Fix: skip the carry for a record ending in scoped (let out_of_scope decide), with a tools_test.sh case.
- Category: pipeline
- Added: 2026-11-16

### The ci-stages secs filter is never run by a test

- Location: tools/run_state.sh:1250
- Why: the fake gh at tools/tools_test.sh:902 prints precomputed seconds, so the timestamp parsing of the new jq secs filter (and gojq's tonumber of a leading-dot string such as .44, whose error the // swallows into 0) is unproved (quality advisory, ci-time-tidy-b).
- Fix: capture only the digits and use ("0." + .f | tonumber), and add a case that feeds a jobs JSON through the same filter.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-16

### merged_on_main repeats supported
- Location: tools/run_state.sh:1121
- Why: quality advisory: merged_on_main repeats supported (tools/run_state.sh:1735) line for line, differing only in the base it reads.
- Fix: one helper taking the base, supported calling it after its shape check.
- Category: pipeline
- Added: 2026-11-16

### unmerged_list duplicates pending_list's loop
- Location: tools/run_state.sh:1143 and tools/run_state.sh:1146
- Why: quality advisory: unmerged_list repeats pending_list's loop (state files, merged_commit, has_row) with only the merged_on_main test inverted, and append_history walks the run states twice.
- Fix: one loop that classifies each run once, pending_list and unmerged_list filtering its output, or pending_list taking a mode argument or printing never-merged runs to stderr.
- Category: pipeline
- Added: 2026-11-16

### Planner does not know the beyond-the-sprint marker
- Location: tools/run_state.sh:287, .claude/agents/planner.md:25, docs/goals.md
- Why: quality advisory: the proposal says the planner writes the beyond-the-sprint marker, yet neither planner.md step 5 nor docs/goals.md names it, so only a hand edit of docs/queue.md ever marks an item and review-due's exception rule depends on memory.
- Fix: name EXCEPTION_MARK's words in planner.md's item parenthesis rule beside the pipeline-limit line, and in the sprint rule of docs/goals.md, for a change the user approves beyond the five.
- Also: .claude/agents/planner.md, docs/goals.md
- Category: pipeline
- Added: 2026-11-16

### Three path classifiers decide which stages run

- Location: tools/run_state.sh:233 TEST_ONLY, :242 NOT_COMPILED, :475 documentation plus TOOLS_RE (sprint-8 review, quality); queued in `ci-scope-quoting`.
- Why: three overlapping classifiers for one decision drift apart.
- Fix: derive TEST_ONLY and NOT_COMPILED from the rules.sh classifiers, or record why each differs.
- Category: pipeline
- Added: 2026-11-16

### The sprint exception membership test is written three times

- Location: tools/run_state.sh:1494, :1582, :1624 (sprint-8 review, quality); queued in `sprint-marker-tidy`.
- Why: the same index(" list ", " name ") trick in sprint_state, sprint_row, and groom.
- Fix: filter the counted names once in sprint_state and pass them, or one helper.
- Category: pipeline
- Added: 2026-11-16

### EXCEPTION_MARK names clash with the user-approved exception

- Location: tools/run_state.sh:289, :1507 (sprint-8 review, quality); queued in `sprint-marker-tidy`.
- Why: EXCEPTION_MARK, exception_item, and sprint_exceptions mean beyond the sprint while the user-approved exception of tools/docs_lint.sh:157 only lifts the pipeline limit, so a comment has to warn about the clash.
- Fix: rename to BEYOND_SPRINT_MARK, beyond_sprint_item, sprint_beyond.
- Also: tools/docs_lint.sh
- Category: pipeline
- Added: 2026-11-16

### merged_since reads only the last metrics row's merged commit

- Location: tools/run_state.sh:1729
- Why: quality advisory. Metrics rows follow run-state order, not merge order, so a later merge in an earlier row is missed and the planner keeps running; the pending loop also adds a subprocess per state file.
- Fix: since every commit on main is a squash merge, test that origin/main descends from COMMIT and differs from it.
- Category: pipeline
- Added: 2026-11-16

### sprint_state picks an exception past the fifth counted row

- Location: tools/run_state.sh:1502
- Why: quality advisory. sprint_state picks the exception from every name merged since the last sprint while sprint_row (tools/run_state.sh:1599) now ends at the fifth counted row, so review-due names an exception (x1 in tools/tools_test.sh:1178) that the groomed row leaves out and that then spends the next sprint's one exemption, x2 counted.
- Fix: pick sprint_exceptions only among the names before the SPRINT_SIZE-th counted one, so review-due, groom, and the row read the same window.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-16

### plan_needed lists run states differently from pending_list

- Location: tools/run_state.sh:1753
- Why: quality advisory. plan_needed lists run states with ls piped to sed and grep while pending_list (tools/run_state.sh:1142) globs the state directory's json files; one clear way to do each thing.
- Fix: loop over the state directory's json files with basename and a case on REVIEW_RUNS as pending_list does.
- Category: pipeline
- Added: 2026-11-16

### Unwrapped comment lines in run_state.sh

- Location: tools/run_state.sh:1726
- Why: quality advisory. Comment lines are left unwrapped beside wrapped ones (also tools/run_state.sh:1747), against the file's comment style.
- Fix: rewrap both comments at the width of the surrounding lines.
- Category: pipeline
- Added: 2026-11-16

### planned_commits re-implements the run-state key parsing of read_key
- Location: tools/run_state.sh:1752 (quality advisory, review-coverage-b)
- Why: duplication: the run-state JSON format gets a second parser that can drift from read_key.
- Fix: reuse read_key or one shared multi-key reader so the run-state format has one parser.
- Category: pipeline
- Added: 2026-11-16

### plan_needed and merged_since comments run past the comment wrap
- Location: tools/run_state.sh:1780 and tools/run_state.sh:1729 (quality advisory, review-coverage-b)
- Why: a line of the plan_needed comment ('overrun, a periodic finding) that only the planner places; otherwise the head item ...') runs past the block's wrap, and the merged_since comment appends 'A COMMIT git does not know is never merged since.' past it.
- Fix: rewrap both comments.
- Category: pipeline
- Added: 2026-11-16

### plan_needed lists review runs by parsing ls output
- Location: tools/run_state.sh:1786 (quality advisory, review-coverage-b)
- Why: parsing ls output is fragile shell.
- Fix: iterate "$state_dir"/*.json with a glob, strip the suffix, and match REVIEW_RUNS with case or grep on the name.
- Category: pipeline
- Added: 2026-11-16

### plan-needed wording says no change merged since though a merge planned before the review no longer counts
- Location: tools/run_state.sh:1798, .claude/workflows/deliver-change.js:977, README.md pipeline step 1 (quality advisory, review-coverage-b)
- Why: the plan-needed line 'and no change merged since', the planReview comment ('no merge since'), and the README step ('failed with no change merged since whose planner ran after it') misstate or garble the rule now that a merge planned before the review does not count.
- Fix: say 'no change planned after it has merged since' in all three.
- Also: .claude/workflows/deliver-change.js, README.md
- Category: pipeline
- Added: 2026-11-16

### Review-run listing and reviewed-commit resolution are repeated
- Location: tools/run_state.sh:1763 and tools/run_state.sh:1818 (quality advisory, review-coverage-b)
- Why: the review-run listing (ls state_dir, sed, grep REVIEW_RUNS) is repeated, and merged_since and passed_since each validate and rev-parse the same reviewed commit.
- Fix: extract a review_runs helper and resolve the reviewed commit once in plan_needed, passing the full commit to both.
- Category: pipeline
- Added: 2026-11-16

### plan-needed needed line omits the later passing review condition
- Location: tools/run_state.sh:1828 (quality advisory, review-coverage-b)
- Why: the needed line still says 'and no change merged since' though passed_since now also has to fail.
- Fix: say 'no change planned and merged since nor a later periodic security review passed' and adjust the tools_test expectations.
- Category: pipeline
- Added: 2026-11-16

### run_state.sh header plan-needed line and plan_needed comment have over-long lines
- Location: tools/run_state.sh:187, tools/run_state.sh:1807, tools/run_state.sh:1812 (quality advisory, review-coverage-b)
- Why: comment wrapping: over-long lines and a broken wrap.
- Fix: rewrap both to the file's comment width.
- Category: pipeline
- Added: 2026-11-16

### history_rows walks the whole rev-list on every call
- Location: tools/run_state.sh history_rows
- Why: groom calls it twice and status once, each walking HEAD and BASE
- Fix: compute it once per command and pass the rows
- Category: pipeline
- Added: 2026-11-16

### lane_of misses a queue item that estimate_of and exception_item find
- Location: tools/run_state.sh:1187 lane_of, estimate_of (1301), exception_item (1617)
- Why: each parses the queue item "N. `NAME`" with its own awk and lane_of alone requires "` (" after the name, so an item like "`git-panel` plugin (" gets an estimate but no lane and falls back to the feature lane
- Fix: one queue_item COMMIT NAME helper all three read, with a tools-test case for an item whose name is followed by a word
- Category: pipeline
- Added: 2026-11-16

### metrics_files breaks on a METRICS_PREFIX holding a space
- Location: tools/run_state.sh:236 metrics_files and every for f in $metrics_files
- Why: the space-joined list is split unquoted, so a prefix with a space breaks history, status, and bench where the quoted METRICS_FILE did not
- Fix: loop over the lane names and quote "$metrics_prefix-$l.tsv"
- Category: pipeline
- Added: 2026-11-16

### Review runs and full commits are looked up in several places of run_state.sh

- Location: tools/run_state.sh:1763 and :1818 (sprint-9 review, quality); queued in `sprint-marker-tidy`.
- Why it matters: passed_since and plan_needed repeat the review-run listing (ls of the state directory, sed, grep REVIEW_RUNS), and merged_since, passed_since, and supported repeat the valid check plus git rev-parse --verify of a full commit, so a fix lands in one copy only.
- Fix outline: add review_runs and full_commit helpers and call them from each place.
- Category: pipeline
- Added: 2026-11-16

### backlog-pick tries each backticked path twice
- Location: tools/run_state.sh:1831
- Why: candidates re-adds every backticked pathlike token in the bare-word pass after stripping the backticks, so each one is looked up twice, wasted work on every entry.
- Fix: run the bare-word pass over the Location with the backticked spans removed instead of only the backticks.
- Category: pipeline
- Added: 2026-11-17

### Top-level docs findings never reach a batch
- Location: tools/run_state.sh:1757
- Why: entries at README.md, CLAUDE.md, and docs/ paths are always unmapped since docs/codebase-map.md names no numbered area for them, so docs findings never reach a backlog-lane batch and only a planner decision mentions them.
- Fix: map the top-level docs in an area of docs/codebase-map.md, or batch unmapped entries as their own docs item.
- Also: README.md, CLAUDE.md, docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-17

### No case pins a bare directory word known only by its files
- Location: tools/run_state.sh:1821
- Why: a bare backticked directory word the map does not name itself but that holds mapped paths (`tools` with only tools/a.sh mapped) prints unmapped, while the same directory with a slash is placed by dir_area; the header documents the asymmetry but no tools_test case pins it.
- Fix: in named_file accept a word for which dir_area of the word with a slash is non-empty and the tree holds it, with a tools_test case, or add a case pinning the unmapped result.
- Category: pipeline
- Added: 2026-11-17

### Lane worktree trusts a branch-controlled build/pipeline
- Location: tools/run_state.sh:2347 (lane_open), the green line of .claude/workflows/deliver-change.js
- Why: security Medium (5): a branch that force-adds build/pipeline, as a directory or a symlink, stops lane-open from linking the lane to the main checkout's run state, so the merge gates running inside the lane read branch-controlled stage records, push counts, and body file instead of the workflow's own records.
- Fix: in lane_open refuse when git -C "$dir" ls-files lists anything under a LANE_LINKS path, or when "$dir/$l" exists but is not a symlink to "$top/$l"; pass gates.sh merge an absolute RUN_STATE_DIR and STAGE_DIR of the main checkout and read the body file from its absolute path.
- Also: .claude/workflows/deliver-change.js
- Category: security
- Added: 2026-11-17

### merge_main runs git merge with global configuration and hooks
- Location: tools/run_state.sh:2391 (merge_main)
- Why: security Low (3): a plain git merge reads global and system configuration and runs hooks, both writable by branch code the checks run, which is why the fetches and the merge-gates worktree use pinned git.
- Fix: run the merge through pinned_git (GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1, -c core.hooksPath=/dev/null), keeping the core.attributesFile and identity -c options.
- Category: security
- Added: 2026-11-17

### merge_main hides a merge failure that is not a conflict
- Location: tools/run_state.sh:2397 (merge_main)
- Why: correctness: git merge's output goes to /dev/null, so a failure that is not a conflict (an untracked file it would overwrite, a missing ref) reports conflicts with no file named, and the silent git merge --abort then fails.
- Fix: keep git's stderr and print it when no file is unmerged, aborting only when a merge is in progress.
- Category: pipeline
- Added: 2026-11-17

### Concurrent lanes race on the shared origin/main ref lock
- Location: tools/run_state.sh:2388 (merge_main) and the green line's fetch
- Why: correctness: two lanes share one .git and both fetch +refs/heads/main:refs/remotes/origin/main, so concurrent deliveries can fail on the ref lock.
- Fix: retry the fetch once on failure, or fetch into a per-lane ref such as refs/lanes/<change>/main.
- Category: pipeline
- Added: 2026-11-17

### lane_open and lane_close remove a worktree by different steps
- Location: tools/run_state.sh:2332 (lane_open), :2366 (lane_close)
- Why: correctness: lane_open removes a replaced run's worktree directly while lane_close removes the toolchain links first so no removal can reach their targets; the two paths can diverge in safety.
- Fix: share one lane_remove helper (links first, then git worktree remove --force) from both.
- Category: pipeline
- Added: 2026-11-17

### lane_of prints the shell's error for a missing queue file
- Location: tools/run_state.sh:1264
- Why: correctness: `item_named < "docs/queue-$l.md" 2>/dev/null` opens the input before stderr is redirected, so a missing queue file still prints the shell's error into the command's output.
- Fix: put 2>/dev/null before the input redirection, or test -f the queue first.
- Category: pipeline
- Added: 2026-11-17

### push --review-fix does not check that a review blocked
- Location: tools/run_state.sh:931 (push, the --review-fix case)
- Why: The review fix push checks only that the recorded push differs from HEAD, not that a review blocked, so any caller gets one extra push beyond the push-once rule.
- Fix: Require a blocked review.quality or review.security record at the pushed head before allowing the --review-fix push, with a tools_test case refusing it otherwise.
- Category: pipeline
- Added: 2026-11-17

### The init usage line still says it refuses any merged run
- Location: tools/run_state.sh:59 (header usage of init)
- Why: Docs currency: the usage line says init refuses a CHANGE with merged recorded, but init now resumes a merged run without phase.retro.
- Fix: Say it refuses a merged run the close recorded (phase.retro) or one with a lane history row.
- Category: pipeline
- Added: 2026-11-17

### Lane-open follows a committed tmp or build symlink out of the repository (sprint-10 security Low (5))
- Location: tools/run_state.sh:2350 (lane_open, parallel-lanes-b)
- Why: .gitignore ignores tmp/ and build/ only as directories, so a branch may commit a symlink named tmp or build, and lane-open's mkdir -p and ln -s then create the toolchain, cache, pipeline, stages, and plan links in any directory it names, outside the repository root. Queued in lane-guards.
- Fix: refuse a lane whose tmp or build path, or any parent of a link target, is a symlink, or a branch that tracks anything under tmp/ or build/.
- Also: .gitignore
- Category: security
- Added: 2026-11-17

### Two lanes share one writable toolchain and compile cache (sprint-10 security Low (3), disputed)
- Location: tools/run_state.sh:2312 (LANE_LINKS, parallel-lanes-b)
- Why: branch code run by one lane's checks can tamper with the binary or cache entries the other lane builds and benchmarks with. Disputed by the skeptic: the checks already run as the same user with write access to those paths by absolute path, and serial deliveries shared them; running at once adds timing, not capability.
- Fix: link the toolchain read-only for the lanes or check its hash before each check; give each lane its own compile cache or key entries by a content hash checked on read.
- Category: security
- Added: 2026-11-17

### history writes late findings to a findings file the records change folded
- Location: tools/run_state.sh:1708 (history), groom at tools/run_state.sh:2072
- Why: a merged change's late findings go to docs/findings/<that change>.md, which a sprint records change may have folded and deleted on main; a lane branch cut before it then hits a modify/delete conflict at its squash merge, or brings back folded entries, and merge-main's union driver settles neither. Queued in lane-records.
- Fix: append late findings to the packaging change's own findings file under its "Findings of X after its package step" heading.
- Category: pipeline
- Added: 2026-11-17

### groom documents CHANGE as optional though it dies without one
- Location: tools/run_state.sh:2014, the header, and the dispatch at :2504
- Why: drift: groom with no CHANGE always dies while a sprint plan waits. Folded into lane-records.
- Fix: make CHANGE required in the header, the usage, and the dispatch.
- Category: pipeline
- Added: 2026-11-17

### lane_open checks the branch with a line-wise grep and a third copy of the pattern
- Location: tools/run_state.sh:2323; tools/open_pr.sh:45; tools/agent_guard.sh:117
- Why: grep -c over printf passes a multi-line value whose first line matches, and the branch pattern is copied instead of the valid helper. Queued in lane-guards.
- Fix: valid "$BRANCH_RE" "$branch" with BRANCH_RE defined once in tools/rules.sh, in its own small change first since rules.sh holds merge-gate rules.
- Also: tools/open_pr.sh, tools/agent_guard.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-17

### checks-and-pr-lows security Low (4): run_state set still writes any note key
- Location: tools/run_state.sh:1675
- Why: the late-finding stamp is public once the run merges and `set` still writes any note.N key, so code running after the merge with write access to build/pipeline (for example the next change's branch code run by a check, if the run-state directory is reachable from there) can forge `set CHANGE note.N "late-finding MERGED text"`, which passes late_findings and lands in docs/findings and then the backlog the planner reads; LATE_TEXT_RE keeps the text to plain characters, 400 at most.
- Fix: make `set` refuse note.* keys so only add_note writes notes, as it already refuses review.*, phase.* and stage.*; optionally record which start wrote each note or check that note keys are numbered in sequence.
- Category: security
- Added: 2026-11-17

### The package step appends the planner's findings twice
- Location: the package step's findings append, `tools/run_state.sh` plan-apply (markdown-reading-c retro note 19).
- Why: 14 lines of the markdown-reading-c findings file (since folded here) repeated (commit 1fc49d8), raised by 2 quality advisories in a run with quality first pass 0 and rework 3.
- Fix: accepted when a tools-test case runs the append twice on one change and the second leaves the file unchanged.
- Category: pipeline
- Added: 2026-11-17

### plan-apply and history write into whatever checkout runs them
- Location: `tools/run_state.sh:1707` append_history, plan-apply (planner-split-rule retro note 5).
- Why: the package step ran both from the main checkout, edited main's backlog queue and history while another lane ran, keyed a row to main; package 10,276 output in 21 calls against a median of 14 over the last 10 backlog rows.
- Fix: accepted when both refuse, non-zero with the tree unchanged, outside the change's lane worktree (a tools-test case), and the next package phase stays within 15 calls.
- Category: pipeline
- Added: 2026-11-17

### A merge that fails on a moved main has no push path
- Location: tools/run_state.sh push_branch and .claude/workflows/deliver-change.js merge loop
- Why: a green pull request behind a moved, conflicting main stopped the run, since push --ci-fix needs a red CI
- Fix: let the merge loop run merge-main and push it as a main-moved push, counted once
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

## Groom folds a findings file without a trailing newline as is

- Location: docs/backlog.md:6640 (two folded findings run together with no blank line) and docs/backlog.md:6612 (a double blank line); tools/run_state.sh groom
- Why: groom concatenates a findings file that lacks a trailing newline as is, so entries run together or gain extra blank lines.
- Fix: make groom end each folded file with exactly one blank line, with a tools-test case.
- Category: pipeline
- Added: 2026-11-17

### The branch pattern and the trailer are spelled three times each

- Location: tools/run_state.sh:2347, :2420, tools/open_pr.sh:47, tools/agent_guard.sh:117, tools/gates.sh:78, tools/scan_text.sh:29 (sweep, quality, two notes).
- Why: three copies of BRANCH_RE and of the co-author trailer can drift.
- Fix outline: one BRANCH_RE and one TRAILER in tools/rules.sh, a tools_test equality case for the guard copy (a merge-gate rules edit, landed alone).
- Also: tools/open_pr.sh, tools/agent_guard.sh, tools/gates.sh, tools/scan_text.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-17

### A stage's branch code can forge its pass record through the runner's job files (security Medium, confidence 6)
- Location: tools/run_state.sh:637 (stages_reap and the jobs directory beside the check clone)
- Why: a stage runs the branch's own code in the check clone, and the runner's job files sit in ../jobs/ beside it; the code can overwrite ../jobs/NAME.start with a PID the runner did not start plus the current commit and write 0 to ../jobs/NAME.status, so stages_reap records stage.NAME as passed at HEAD for its own stage or any stage running beside it, and gate_stages in tools/gates.sh accepts it, weakening the clone isolation the README promises; before this change the exit status came straight from `wait`. Not blocking since a deliberate stage could already reach the run state through the tmp/.toolchain symlink.
- Fix: keep each job's PID, start second, and commit in runner shell variables, take the exit status from `wait PID` on the runner's own child (poll with `kill -0`, then `wait`), or keep status files in a runner-owned mktemp -d outside the clone's parent, and trust only a PID the runner launched.
- Also: tools/gates.sh
- Category: security
- Added: 2026-11-17

### A failing stage's log excerpt reaches the terminal unfiltered (security Low, confidence 4)
- Location: tools/run_state.sh:778
- Why: the last 20 lines of a failing stage's log go to the check's stdout and check.log as they are; branch code controls that log, so terminal escape sequences such as OSC 52 clipboard writes or title changes reach whoever runs the check or cats check.log.
- Fix: strip control characters from the excerpt before printing it, for example through `LC_ALL=C tr -d '\000-\010\013-\037\177'` ahead of the sed prefix, or print it with `cat -v`.
- Category: security
- Added: 2026-11-17

### stages_stop does not record a passed compile stage as compiled
- Location: tools/run_state.sh:666
- Why: a compile stage that passed while the check was stopping is recorded through stage_end but compiled_set is never called, so the next check compiles it again, costing minutes of a stage the cache already holds.
- Fix: share one record-a-passed-stage step (stage_end, then compiled_set for COMPILE_STAGES) between stages_reap and stages_stop.
- Category: pipeline
- Added: 2026-11-17

### Groom output needs a hand edit and draws the records runs' quality advisories
- Location: `tools/run_state.sh` (`groom`, `folded_backlog` near :1851)
- Why: sprint-12-records hand-edited `docs/backlog.md:6714` after groom because docs-lint refused a backticked path to a findings file groom had just removed (sprint-10-records the same, 2 of the last 3 records runs); all 3 of its 3 quality advisories were groom output (headings folded twice from a double append at :6775 and :6787; no blank line before folded headings at :6751, :6765, :6861); reviews took 9,975 of 36,282 output tokens (27.5%) (sprint-12-records retro note 5).
- Fix: accepted when a tools-test case shows groom leaving no backticked path to a removed findings file, no repeated folded heading, and a blank line before each folded heading, and the next records run applies groom with no hand edit and no advisory on groom output.
- Category: pipeline
- Added: 2026-11-17

## Folded backlog headings follow the previous entry with no blank line

- Location: docs/backlog.md:6751, docs/backlog.md:6765, docs/backlog.md:6861; tools/run_state.sh:1851 (folded_backlog)
- Why: findings entries are appended without a separator and folded_backlog keeps them as written, so the folded headings at those lines sit directly under the previous entry with no blank line, breaking the backlog's format.
- Fix: have the findings append or folded_backlog put one blank line before every heading.
- Category: pipeline
- Added: 2026-11-17

### groom output needs a hand edit after each records run (sprint-12-records retro note 5)
- Location: `tools/run_state.sh` groom and folded_backlog (about :1851); sprint-12-records run state note.5.
- Why: 2 of the last 3 records runs hand-edited docs/backlog.md after groom (a backticked path to a findings file groom deleted, docs-lint refusing it), and all 3 of sprint-12-records' quality advisories were groom output (headings folded twice from a double append, no blank line before folded headings); reviews took 9,975 of 36,282 output (27.5%).
- Fix: groom leaves no backticked path to a removed findings file, no repeated folded heading, and a blank line before each folded heading; accepted when a tools-test case shows all three and the next records run applies groom with no hand edit.
- Category: pipeline
- Added: 2026-11-17

### A check stage can fake a sibling stage's pass through the job files (sprint-13 security Medium (6))
- Location: tools/run_state.sh:639 (check-parallel, sprint-13 review).
- Why: the job files sit in ../jobs beside the check clone, writable by stage code; a stage's test writing 0 to ../jobs/SIBLING.status, or rewriting SIBLING.start, while the sibling runs makes stages_reap record it (for example diagnose) passed at HEAD, and gate_stages accepts that record; before check-parallel the status came from wait. Not blocking: a hostile stage could already reach the run state through the tmp/.toolchain symlink.
- Fix: take each exit status only from wait on a PID the runner itself started (poll with kill -0), or keep the status files in a runner-owned mktemp -d outside the clone's parent; accepted when a tools-test stage writing a sibling's status file cannot turn the sibling into a pass. Queue item `check-runner-safety`.
- Category: security
- Added: 2026-11-17

### The failing stage's log excerpt reaches the terminal unfiltered (sprint-13 security Low (4))
- Location: tools/run_state.sh:778 (check-parallel, sprint-13 review).
- Why: tail -n 20 of a log the branch code controls goes to the check's stdout and check.log as is, so test output can carry OSC 52 clipboard writes or title and terminal-state sequences to whoever runs the check or reads check.log.
- Fix: strip control characters before the prefix (LC_ALL=C tr -d of 000-010, 013-037, 177) or print through cat -v; accepted when a tools-test excerpt holding an escape prints none. Queue item `check-runner-safety`.
- Category: security
- Added: 2026-11-17

### jobs_refusal has two arms for one message and runs twice (sprint-13 quality)
- Location: tools/run_state.sh:569, :762, :969.
- Why: two case arms print the same message, the empty-string pattern never matches as CHECK_JOBS defaults to 3, and check_wait (:969) and check_stages (:762) both run it, the second after the queued stages' compiled records were reset.
- Fix: one pattern such as *[!0-9]*|0|0[0-9]*, checked once before the loop. Queue item `check-runner-safety`.
- Category: pipeline
- Added: 2026-11-17

### A doubled blank line before check_wait (sprint-13 quality)
- Location: tools/run_state.sh:962.
- Why: a second blank line was added before the check_wait comment.
- Fix: remove it. Queue item `tools-docs-tidy`.
- Category: pipeline
- Added: 2026-11-17

### squash_commit falls back to HEAD, so a branch commit can pass merged_at (security Low (4))
- Location: tools/run_state.sh:1560
- Why: squash_commit falls back to HEAD and merged_on_main also accepts an ancestor of HEAD, so while origin/main has no commit whose subject ends with the pull request number, a branch commit with that subject passes merged_at; an agent could record merged at an unmerged branch commit, which would skew the history rows and the sprint base the sprint-end security review starts from.
- Fix: have squash_commit and merged_at search only BASE (origin/main), with no fallback to HEAD, so a merged value must be the squash commit on main itself; this also removes the fallback loop that can never yield an accepted commit.
- Category: security
- Added: 2026-11-17

### merged_at without a pr accepts any ancestor of HEAD (sprint-14 review and sweep quality)

- Location: tools/run_state.sh:1581 (merged_at), :1539 (merged_on_main).
- Why: with no pr recorded, any ancestor of HEAD passes, a lane's pushed head included, against the comment that no pushed head is recorded as merged, and the refusal says "is no commit on main".
- Fix outline: require ancestry of origin/main only, or refuse until pr is recorded, with an expect case. Queued in `sprint-security-b`.
- Category: pipeline
- Added: 2026-11-17

### The security record keeps only the last review round (merge-record-check retro 7)

- Location: the security record of tools/run_state.sh and the workflow's re-review.
- Why: security at 0b4329979642 found 2 Lows, written to the findings file and the pull request, while the re-review at f7208b282704 stored low=0, so the record disagrees with both after a rework round.
- Fix outline: accepted when a re-review finding fewer keeps the earlier round's Lows counted, shown by a tools-test case. Queued in `review-pipeline-b`.
- Category: security
- Added: 2026-11-17

### The planner starts only to remove the delivered item (vim-line-commands-a retro 5)

- Location: plan-needed in tools/run_state.sh and the workflow's plan phase.
- Why: vim-line-commands-a's plan spent 11,391 output in 16 calls (6.2% of output, 10.6% of calls) and kept every decision; feature last-10 plan 9,255 to 21,937 output.
- Fix outline: accepted when the next 5 runs delivering an item as written show no plan phase and docs-lint passes the queue. Queued in `plan-skip`.
- Category: pipeline
- Added: 2026-11-17

### Records changes are judged against the small budget with the sprint reviews in their totals
- Location: the budget line of `sh tools/run_state.sh budget`, the estimate of a `sprint-N-records` change
- Why: sprint-12-records 2,147,268, sprint-13-records 1,264,361, and sprint-14-records 1,973,945 total tokens against 500,000 (3 of 3 over) with only 36,282, 42,893, and 32,743 output tokens; sprint-14-records weighted phases periodicreview 19,054,636 and review 3,756,759 against deliverchange 3,040,840; the same proposal is ci-trust-gaps retro note 6.
- Fix: accepted when the next records row's budget line compares only its delivery phases with its size, or budgets the sprint review in its own line, and does not start with over for that reason alone.
- Category: pipeline
- Added: 2026-11-17

### moved compares the change's files through unquoted, magic-capable pathspecs
- Location: tools/run_state.sh:2762 (moved_change)
- Why: Security Low (confidence 6). It passes `git diff --name-only` output back to git as pathspecs; with the default core.quotePath a name with non-ASCII or control characters comes out quoted, and a name starting with ':' is read as pathspec magic (a file named ':(exclude)*' becomes an exclude), so files of the change drop out of the at..HEAD comparison and `moved` can report the change the same after a main-moved merge altered it, carrying the quality and security passes to a head no review saw.
- Fix: List the files with `git -c core.quotePath=false diff -z --name-only` (read NUL-separated) and run the final `git diff` with `--literal-pathspecs` (or GIT_LITERAL_PATHSPECS=1), or compare `git diff old_base at` with `git diff new_base HEAD` over non-records paths without pathspecs; add tools_test cases with a quoted name and a ':(exclude)*' name.
- Category: security
- Added: 2026-11-18

### Two lanes' exception lines against one uncounted exception (sprint-size-six retro)
- Location: `SPRINT_EXCEPTIONS` in `tools/run_state.sh` (`:408`, the sprint_state branch at `:2005`)
- Why: SPRINT_EXCEPTIONS=1 against 2 exception lines (one per lane) leaves sprint-size-six counted, so review-due prints 4 of 5 against the user's "Sprint 16 finishes as planned"; the planner and the contributor noted it twice with 0 decisions changed, and sprint-16 now closes with tab-close-d and vim-folds-b left over.
- Fix: each lane's exception line leaves its change uncounted, or the conflict stops the run for the user's answer before the merge; accepted when review-due over such a history names both changes beyond the sprint.
- Category: pipeline
- Added: 2026-11-18

### A carried review trusts a moved record written by the branch's own run_state.sh
- Location: tools/run_state.sh:2806 (carried_backed)
- Why: security Low (4): the checker runs the branch's copy of tools/run_state.sh in the lane worktree, so a main-moved merge commit that edited the moved function could write the moved record although files changed after the review, carrying the earlier reviews to unreviewed code; not new, since before this change the moved line alone carried, and branch-controlled scripts already write the run state.
- Fix: in the review command's carried=1 path, run from the main checkout's trusted copy, compute the REVIEWED, CURRENT, and MOVED name diffs again (or call moved_change from that copy) instead of only reading the stored record, or refuse to carry whenever the diff from the reviewed commit to HEAD touches tools/run_state.sh or tools/agent_guard.sh.
- Also: tools/agent_guard.sh
- Category: security
- Added: 2026-11-18

### moved carries when the merge keeps the change's side of a file main also edited
- Location: tools/run_state.sh:2783 (moved_change)
- Why: correctness: a file both the change and main edited, merged keeping the change's text (a conflict resolved with checkout --ours), is in REVIEWED and CURRENT but not in MOVED, so HEAD reverts main's landed fix in that file and both reviews carry, the class of revert this change closed for main-only files (reproduced: moved names empty, git diff main HEAD shows -FIX +CHANGE).
- Fix: also read the names of git diff OLD_BASE NEW_BASE, its status checked, and run the reviews again when any of them outside RECORDS_RE is in REVIEWED, with a tools_test case merging a conflict resolved --ours.
- Category: pipeline
- Added: 2026-11-18

### The merger reports the branch head as the merged commit
- Location: the merger's result and the merge record of `tools/run_state.sh`; vim-line-commands-b note 9.
- Why: it reported f230c3210a53, the branch head, not the squash commit 25604e0ec359, which the fallback recorded instead; a record that trusted the report would point at a commit absent from main.
- Fix: the merger reports the squash commit read from main's log; accepted when a tools-test case shows a branch head refused as the merged commit.
- Category: pipeline
- Added: 2026-11-18

### The planner weighs quality-advisory notes the package step handled
- Location: the planner's input from `sh tools/run_state.sh show`; git-signs-transport retro note 6.
- Why: git-signs-transport 5 advisories (1 kept as a finding, 0 changed code) and secret-patterns 4, all 4 given a not-placed decision; quality first pass 83/151.
- Fix: leave handled `quality-*` notes out of what the planner reads; accepted when the next planner's decisions carry no line about them while a kept advisory still reaches docs/findings.
- Category: pipeline
- Added: 2026-11-18

## The fold keeps a findings file's title as a second level-one heading

- Location: docs/backlog.md:7555, tools/run_state.sh (folded_backlog)
- Why: groom folds the sprint-14-records findings file with its title, so the backlog gains a second level-one heading ('# Findings of sprint-14-records') that is no entry and nests every later folded entry under '## Two defects are recorded twice in the backlog'.
- Fix: drop the title line, and let folded_backlog in tools/run_state.sh skip a findings file's leading '# ' line.
- Category: pipeline
- Added: 2026-11-18

## The fold adds headings with no blank line before them

- Location: docs/backlog.md:7488 (also 7492, 7496, 7500, 7540, 7613, 7622), tools/run_state.sh (folded_backlog)
- Why: the fold adds seven headings with no blank line before them (main had 10, the branch 17), the groom defect the folded sprint-14-records finding names, which make docs-lint does not catch.
- Fix: insert the blank lines, and let folded_backlog separate every folded heading by one blank line.
- Category: pipeline
- Added: 2026-11-18

### The planner runs on a first queue item already placed and estimated (secret-patterns retrospective)
- Location: `tools/run_state.sh` plan-needed
- Why: secret-patterns' planner changed no decision (its queue only removed the delivered item and restated the Decisions) yet cost 11,077 of 127,363 output tokens (8.7 percent) and 12 of 112 tool calls (10.7 percent).
- Fix: plan-needed answers 0 for a delivery of the first queue item with its estimate set and no pending retro or overrun note, while plan-apply still removes the delivered item; accepted when such a run records planned=0 and no plan phase.
- Category: pipeline
- Added: 2026-11-18

### Budget line names the sprint key too narrowly
- Location: tools/run_state.sh:1795
- Why: the budget line says sprint-planning's reviews set apart though the sprint key also holds the due, notes, record, records-merged, and planner starts.
- Fix: say sprint-planning's own starts.
- Category: pipeline
- Added: 2026-11-18

### plan-needed skips the planner for a security note recorded after a later sprint plan (pipeline-diet security Low (3))
- Location: tools/run_state.sh:2613 (plan_needed)
- Why: plan-needed now skips the planner for a pending change's `security` notes (PLAN_NOTES includes security) whenever any sprint-N-records change merged after it; a security note recorded on that change after the sprint planner ran would never be placed by a planner, so an advisory security finding could sit unqueued. The blocking periodic-security check above the loop is unchanged, so no blocking finding is affected.
- Fix: In plan_needed, apply placed_by_sprint only to retro and overrun notes and keep `security` (and `quality`) notes always triggering the planner, or compare each note's recording time with the sprint-records merge time instead of the change's merge commit.
- Category: security
- Added: 2026-11-18

### reviewed-edits fails open when git diff fails (pipeline-diet quality)
- Location: tools/run_state.sh:1692 (reviewed_edits)
- Why: fail-open: reviewed_edits discards git's errors and chains git diff && git ls-files, so a failing git diff yields an empty list and 'none since the security review' with exit 0.
- Fix: run git diff outside the 2>/dev/null pipeline and return 1 when it fails.
- Category: pipeline
- Added: 2026-11-18

## Fold adds a level-one heading per findings file

- Location: docs/backlog.md:7740, tools/run_state.sh:2143 (folded_backlog)
- Why: the fold adds a third level-one heading ('# Findings of sprint-15-records'), the very defect the folded entry under it records, nesting every later entry under it.
- Fix: drop the title line here and let folded_backlog skip a findings file's leading '# ' line.
- Category: pipeline
- Added: 2026-11-18

## Folded headings lack a blank line before them

- Location: docs/backlog.md:7643, 7647, 7651, tools/run_state.sh (folded_backlog)
- Why: folded headings follow a text line with no blank line before them (the known fold defect, again).
- Fix: insert the blank lines and have folded_backlog separate every folded heading by one blank line.
- Category: pipeline
- Added: 2026-11-18

### A lane's queue removal conflicts with a sprint-records rewrite of the queue (tab-close-d retro)
- Location: `tools/run_state.sh` merge-main and plan-apply, `docs/queue-feature.md`.
- Why: after merge-main the delivery's own plan-apply edit of `docs/queue-feature.md` conflicted with the sprint-16-records rewrite; merge-main aborted, a contributor start redid the merge by hand, and the check, both reviews, and a second 16-minute CI ran again (merge 60,874 output tokens/21 calls against 24,917/7; ci_wait_calls 10 against 4 to 8).
- Fix: re-run plan-apply over the new main's queue in merge-main instead of merging the queue text, so a lane whose base predates a records merge takes in main with no conflict in `docs/queue-*.md` and no contributor start.
- Also: docs/queue-feature.md
- Category: pipeline
- Added: 2026-11-18

### The moved check reruns the reviews on a cleanly merged file and misses a hand-resolved one (tab-close-d retro)
- Location: `tools/run_state.sh` moved_change.
- Why: after the merge of main the moved check named `README.md` (merged cleanly, same diff against the new main) as changed and both reviews ran again, while the hand-merged `docs/queue-feature.md` was not named; reviews 37,844 output tokens/46 calls, 20 percent of the run's 227 calls, the rerun changing no decision.
- Fix: rerun the reviews exactly when the change's own diff of some file differs from its diff before the merge, a hand-resolved conflict file always counting; a tools-test case for each.
- Also: README.md, docs/queue-feature.md
- Category: pipeline
- Added: 2026-11-18

### Groom's fold keeps producing format defects the records run hand-fixes (sprint-16-records retro)
- Location: `tools/run_state.sh` folded_backlog (`:2143`), groom.
- Why: the docs-lint hand edit of a removed findings path recurred in sprints 10, 12, 13, and 16; 2 of sprint-16-records' 6 quality advisories were fold defects already in the backlog (a third level-one heading, headings at `docs/backlog.md:7643`, `:7647`, `:7651` with no blank line).
- Fix: folded_backlog skips a findings file's leading `# ` line and separates every folded heading by one blank line; accepted when a records run ends with no hand edit after groom and no fold-format finding.
- Category: pipeline
- Added: 2026-11-18

### Groom's duplicate guard lets an unmarked security entry leave as a duplicate
- Location: tools/run_state.sh:424 (SECURITY_MARK) and the duplicate check at tools/run_state.sh:2510; reached the branch through the merge of main (#209, 9674689), not this change's own commits.
- Why: security Low (6). The guard now uses SECURITY_MARK instead of any line naming security, so a security entry recorded without the 'security Low' or 'Low (N)' form (for example the benchmark's reused temporary report path, recorded as a Low finding of the periodic security review at 66fd52b) can be removed by a planner-written groom.txt `duplicate` line, and an open security finding leaves without a merged item or a fixing commit.
- Fix: Widen SECURITY_MARK so it also matches an entry naming a severity next to a security review (for example '(high|medium|low)( finding)? of the (periodic )?security review'), or keep the old case-insensitive 'security' test for duplicates while the narrow mark stays for ranking; add a tools_test.sh case where groom refuses to remove such an entry as a duplicate; separately, normalize stored entries to the 'security Low (N)' form.
- Category: security
- Added: 2026-11-18

### Groom's listed proof accepts a heading as a bare substring of the queue item (`groom-proof` security Low (5))
- Location: tools/run_state.sh:2387 (item_lists)
- Why: item_lists accepts the heading as a bare substring of the queue item, so a planner `listed` line for a short heading such as `## Foo` passes when the item only quotes a different, longer heading such as `### Foo bar`; a security entry can then leave the backlog without its merged item ever naming it, the proof this change set out to require.
- Fix: Require a bounded match: no `#` before it, and after it the closing quote the planner writes (`Backlog: "### title"`), a comma, or the end of the item; or match the quoted form `"` H `"`. Add a tools-test case refusing a shorter heading that prefixes a quoted longer one.
- Category: security
- Added: 2026-11-18

### Groom's duplicate guard lets a security entry without a `security <severity>` marker leave (`groom-proof` security Low (3))
- Location: tools/run_state.sh:422 (SECURITY_MARK)
- Why: The guard used to refuse any entry mentioning security and now refuses only text matching its severity marker, so a security entry written without it (an older entry, or one transcribed from a periodic note recorded as `High (8) file:line ...` under the note kind `security`) can leave as a `duplicate` without a listed item or a fixing commit. The design accepts the risk, since findings deliver-change.js hands over carry the `security <severity>` prefix, limiting the exposure to entries written some other way.
- Fix: Also treat an entry as a security entry when its heading or Location line carries a severity and confidence pair, `(High|Medium|Low) \([0-9]+\)`, or when it came from a security note; or make the planner's sprint mode write `security <severity>` into the heading of every security entry it adds, so the marker the guard reads always exists.
- Category: security
- Added: 2026-11-18

### Groom's listed proof still accepts a comma after an unquoted heading (`groom-proof` security Low (2))
- Location: tools/run_state.sh:2410 (item_lists)
- Why: item_lists accepts a comma after a heading that no double quote or backtick opens, so a short heading `## Foo` still counts as listed when an item mentions a longer heading `## Foo, bar` bare or in single quotes, and a security entry could then leave the backlog without its merged item naming it. It predates the change and is narrower now: the planner's double-quoted form is closed, so the residual needs a bare or single-quoted mention of a backlog heading that is the exact prefix of another heading followed by a comma.
- Fix: Accept a bare heading only at the end of the item, or treat a single quote like the other quote characters; stricter, require the planner's quoted form (Backlog: "H") outright. Add a tools-test case with a bare `## Foo, bar` against `## Foo`.
- Category: security
- Added: 2026-11-18

### Groom's guard against a `#` before a listed heading has no test (`groom-proof` quality advisory)
- Location: tools/run_state.sh:2406 (item_lists)
- Why: Untested branch: item_lists' guard against a `#` before the heading (a `## y` heading inside a quoted `### y` one) has no tools-test case; only the guard after it is exercised, so a regression in it would pass the suite.
- Fix: Add a listed case whose item quotes `### ...` for the same `## ...` heading, listed unquoted at the item's end or before a comma so the guard alone refuses it.
- Category: pipeline
- Added: 2026-11-18

### exception_item now counts a wrapped `beyond the sprint` mark without a test (`groom-proof` quality advisory)
- Location: tools/run_state.sh:2127 (exception_item)
- Why: Untested branch: exception_item now reads the item through queue_items, which joins continuation lines, so a `beyond the sprint` mark inside a first parenthesis wrapped onto the next line now counts as an exception in review-due and the sprint row, where main read the first line only; no review-due case pins the new behavior.
- Fix: Add a review-due tools-test case whose item's parenthesis wraps before the mark.
- Category: pipeline
- Added: 2026-11-18

### Groom leaves references to the findings files it removes (sprint-17-records retro)
- Location: `tools/run_state.sh` groom and its fold of docs/findings/, `tools/docs_lint.sh` path check
- Why: docs-lint refused 3 backticked paths to removed findings files that needed hand edits, as in earlier records changes, and missed a bare file name (`docs/queue-feature.md:44` naming vim-folds-b.md:36), 1 of 5 first-pass advisories that opened rework round 1 (rework 2 in sprint-17-records).
- Fix: groom rewrites or refuses references to the files it removes, bare names included; accepted when the next records change needs no hand edit for a removed findings file and no review reports one.
- Evidence: sprint-18-records again needed one hand edit, commit 1dba846 unquoting the removed findings directory in this entry's own Location line, since docs-lint refused it.
- Also: tools/docs_lint.sh, docs/queue-feature.md
- Category: pipeline
- Added: 2026-11-18

### The token weighting prices a mid-tier start at the cheap tier's price

- Location: `tools/run_state.sh` line 2009 (`add_tokens`; the alias list read from the agent files' `model:` lines at about line 1976, `TIER_PRICES` at line 448; the `weighted_phases` history column it feeds).
- Why: once `.claude/agents/contributor.md` has a `model:` line, the `tokens` command labels the contributor's starts cheap and prices them at 100/125/10/500 instead of a mid price, so `weighted_tokens` and `weighted_phases` are understated; the same starts are also recorded as `metric.start.N` `implement/cheap/...` and in `weighted_phases` under a `cheap` label the calibration profile no longer uses. The trial's revert rule uses total tokens, so its verdict is unaffected. Queued as Pool 30 `tier-price-mid`.
- Fix: in `tier-price-mid`, price each alias by its own tier, label such a start by the agent tier (or by the alias's own price key) together with its price, extend the design's no-cheap-label goal to the token labels then, and add a tools-test case that prices and labels a mid-tier start apart from a cheap one.
- Also: .claude/agents/contributor.md
- Category: pipeline
- Added: 2026-11-19

### Groom's output fails the check's docs-lint stage on its own (sprint-18-records retro 11)
- Location: `tools/run_state.sh` groom (the fold that deletes the findings files), docs-lint stage
- Why: groom deleted the findings directory while a carried backlog entry still named it in backticks, so sprint-18-records failed its first check at 399adffe0be5 (docs-lint) and needed a contributor fix and a hand edit of groom output; check first passes 168/172 overall.
- Fix: groom output passes `make docs-lint` as written; accepted by a tools-test case folding a findings file whose entry names the removed directory, and the next 3 records runs passing check first.
- Category: pipeline
- Added: 2026-11-19

### settled_round repeats the RECORDS_RE filtering of other records filters (review-lite quality advisory)

- Location: tools/run_state.sh:1248 and tools/run_state.sh:1264 (settled_round), beside settled_at in tools/gates.sh:122 and run_state.sh's own records filters around lines 1786 and 3170
- Why: the same filter of paths outside RECORDS_RE is written four times, so a change to what counts as a record must be repeated in each place or the settled round and the gates disagree; the two quality findings at lines 1248 and 1264 are merged here as one.
- Fix: one shared helper listing the paths outside RECORDS_RE, used by settled_round, settled_at, and the records filters, when review-lite-docs edits tools/rules.sh
- Also: tools/gates.sh, tools/rules.sh
- Category: pipeline
- Added: 2026-11-19

### Two security entries stay open though #214 fixed them

- Location: `docs/backlog.md:8392` and `:8416` (SECURITY_MARK misses unmarked security entries); `tools/run_state.sh:454`
- Why: both are carried open though b5b0aec (#214) widened SECURITY_MARK, so the backlog overstates open security work.
- Fix: list both as fixed by b5b0aec in the next `groom.txt` after checking its tools-test cases.
- Category: pipeline
- Added: 2026-11-19

### SECURITY_MARK matches security and a severity word anywhere in a long entry (sprint-19 review quality)

- Location: `tools/run_state.sh:461`
- Why: matched over the whole joined entry, the mark takes process entries as security ones: the repeated guide-colors retro entry at `docs/backlog.md:8377` and `:8396` (security 0 ... medium output budget) becomes a security entry that groom refuses as a duplicate; safe-side, but it grows with entry length.
- Fix: require the severity within a short window of security (or finding or review wording), with a tools-test case that an entry naming security 0 and a medium output budget is not a security entry. Queued in `groom-fold-format`.
- Category: security
- Added: 2026-11-19

### Extra push allowed by push --pr-text without a blocked text review
- Location: tools/run_state.sh:1327
- Why: `push --pr-text` only checks that the recorded push differs from HEAD, and agent_guard.sh lets the contributor pass `--pr-text` at any time, so a contributor gets one more push per run even when no pull request text review blocked, loosening the push-count rule. The merge gates still run on every head, so no unreviewed code reaches main. This came in with the merge of main (#224), not with this change's commit. Security Low, confidence 4.
- Fix: Have the workflow write a run-state marker (for example `pr_text_blocked`) when the text review blocks, make `push --pr-text` refuse unless it is set, clear it after the push, and add expect cases in tools/tools_test.sh.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-19

### The new --pr-text push kind accepts any commit, as long as a recorded (sprint-20 review security Low (3), run_state.sh:1330)

- Location: `tools/run_state.sh:1330`
- Why: In this change: the new --pr-text push kind accepts any commit, as long as a recorded push other than HEAD exists; it does not check that the commit only rewrites pr.md. Because RECORDS_RE exempts all of openspec/ and docs/goals.md from a new review, this adds one more push after review whose records-path content nobody reviews (specs, or the goals that drive tier routing).
- Fix: In push_branch --pr-text, require that git diff --name-only <pushed> HEAD lists only openspec/changes/archive/*-<change>/pr.md, and add a tools_test.sh expect case for a refused wider diff.
- Also: docs/goals.md
- Category: security
- Added: 2026-11-19

### HEADER names 24 columns (sprint-20 sweep quality, run_state.sh:484)

- Location: `tools/run_state.sh:484`
- Why: HEADER names 24 columns (advisories_closed, advisories_left added) but the committed header rows of docs/metrics-feature.tsv:1 and docs/metrics-backlog.tsv:1 still name 22, and history appends rows only to existing files, so the files' header and their newest rows disagree
- Fix: append the two column names to both header rows
- Also: docs/metrics-feature.tsv, docs/metrics-backlog.tsv
- Category: pipeline
- Added: 2026-11-19

### A check stage can forge its runner's job status files
- Location: `tools/run_state.sh`, `check_stages` (`job_dir=${check_root%/repo}/jobs`), `stage_launch`, `stages_reap`
- Why: the job files sit beside the clone (`../jobs/STAGE.status`), so a stage can write a passing status for itself or a stage still running before the runner reads it, and the runner records a pass it never saw; `escaped_paths` does not scan them, since the runner writes them during the check.
- Fix: keep the job directory under the delivery clone's `build/stages/<change>/`, outside every path a stage is handed, or have each job report its status through a pipe the runner holds instead of a file.
- Category: pipeline
- Added: 2026-11-20

### Shared state a check stage can still write without failing the check
- Location: `tools/run_state.sh`, `escaped_paths`: `build/pipeline` but the change's own run state (other changes' run states, `build/pipeline/compiled`), `build/stages`, `build/plan`, `build/spinel-cache`, and `tools/run_state.sh` itself
- Why: concurrent lanes and the runner write these during a check, so they are not compared; a stage can forge another lane's run state, a compile record that makes a later check skip a compile stage, or a cache object, or edit the runner while it reads its own script.
- Fix: run the stages under an operating-system sandbox (a separate user or a read-only bind of the delivery clone), or, without one, compare the compile records and the other run states by the writes the runners log.
- Category: pipeline
- Added: 2026-11-20

### The checker's own figures stay writable by a stage during a check
- Location: tools/run_state.sh, state_view (security Low (6), narrowed)
- Why: state_view now leaves out only the figures the checker's line writes (the names of the workflow's metricLine), so a measurement a stage forges fails the check; but a stage can still rewrite metric.first.*, metric.estimate, or another of those names in its change's run state by an absolute path, and they feed the first-pass rates, the budget, and the history rows. The list also has to follow metricLine: a new name there fails a rejoined check until it is added.
- Fix: snapshot those metric lines at escape_mark and accept only the values the rejoining checker's metric command logs that it wrote, the log kept where a stage cannot write it.
- Category: security
- Added: 2026-11-20

### Correction: an edit of tools/run_state.sh by a stage is listed by the scan
- Location: docs/findings/check-runner-safety.md, the entry listing tools/run_state.sh among the paths a stage can write without failing the check (quality advisory)
- Why: escaped_paths scans the delivery clone's tools/ (only tmp/, .git, and four build/ directories are pruned), so such an edit is listed; the narrower risk is an edit that changes the runner's behavior before the running shell reaches escaped_paths, since sh reads the script as it runs.
- Fix: read that entry with this narrower risk; have the runner run from a copy of the script made before the stages start, so an edit of the delivery clone's copy cannot change the running check.
- Category: pipeline
- Added: 2026-11-20

### The run-state comparison now leaves out every figure but the measurements (security Low (5), residual widened)
- Location: tools/run_state.sh `state_view`, the filter of the run-state comparison after a check.
- Why: so the figures /deliver's usage and tokens write while a detached check runs leave a rejoined check passing, the comparison now leaves out every `metric.*` line but the measurements (`allocs.*`, `rounds.*`, `us.*`, `analysis_ms.*`); a stage can therefore forge, by an absolute path, not only the checker line's figures (first-pass rates, the estimate, rework) but `metric.total_tokens`, `metric.wall_min`, `metric.start.*`, `metric.weighted.*`, and `metric.counted`, which feed the token budget and the history rows, and the check passes.
- Fix: as for the residual already recorded: at `escape_mark` snapshot the `metric.*` lines and accept a changed one only when a command the runner's caller ran (metric, usage, tokens) logged writing it, the log kept outside every path a stage can write.
- Category: security
- Added: 2026-11-20

### Security: a stage's detached child can write after the escape scan (security Low (6), still present at package)
- Location: tools/run_state.sh:738 stage_launch (reported at :731 and :738 across the review passes, code unchanged)
- Why: stage_launch waits only for the stage's direct child and escaped_paths runs once, after the stages pass, so a stage that starts a setsid or nohup child sleeping past the scan can then write the shared toolchain, a hook, or a tracked file, and the next check or delivery runs on what it left. Merges the four passes' reports of this gap, including the one asking that it be recorded.
- Fix: run each stage in its own session or process group and kill that group before escaped_paths runs, or repeat the scan of the shared toolchain and hooks at the start of each check from a mark kept since the last check ended.
- Merged: ### A stage's detached child can write after the scan
- Location: tools/run_state.sh:731, stage_launch, and escaped_paths (security Low (6))
- Why: stage_launch waits only for the stage's direct child, and escaped_paths runs once, after the stages pass. A stage that starts a detached child (setsid or nohup) sleeping until the scan passed can then write the shared toolchain, a hook, or a tracked file, so the next check or delivery runs on what it left.
- Fix: run each stage in its own session or process group and kill that group before escaped_paths runs, or repeat the scan of the shared toolchain and hooks at the start of each check from a mark kept since the last check's end.
- Category: security
- Added: 2026-11-20

### Security: a stage can forge its own run state's metric lines during a check (security Low (6), still present at package)
- Location: tools/run_state.sh:1007 state_view (reported at :1002, :1006, and :1007 across the review passes)
- Why: state_view leaves every metric.* line out of the run-state comparison except the measurements (allocs, rounds, us, analysis_ms), wider than the earlier list that mirrored the checker's metricLine; a stage writing its own change's run state by an absolute path can forge metric.phase.*, first.*, calib.*, estimate, rework, planned, total_tokens, wall_min, start.*, weighted.*, or counted, which feed the first-pass rates, the token budget, and the history rows, and the check still passes. read_key takes only a line's first key and trusted_state drops multi-key lines, so no review.* or phase.* record can be planted this way. Merges the four passes' reports, including the Low (5) one on the narrower list and the one noting a finding listed as fixed in place is still present.
- Fix: at escape_mark, snapshot the metric.* lines; after the stages, accept a changed or new metric.* value only when a command the runner's caller ran (metric, usage, tokens) logged writing it, the log kept where no stage can write (for example under build/pipeline beside the run state); any other metric.* difference fails the check.
- Category: security
- Added: 2026-11-20

### Security: a stage can plant notes and closing phases in its own run state during a check (security Low (6), still present at package)
- Location: tools/run_state.sh:1007 state_view with CLOSE_PHASES (reported at :1006 and :1007; the move of the list into CLOSE_PHASES matches the same lines and adds no injection)
- Why: state_view leaves every note.* line and the closing phases (plan, implement, package, ci, merge, retro, report) out of the run-state comparison, so a stage writing its own run state by an absolute path can plant a forged note, or a closing phase at a real commit, and the check still passes: that can mislead the planner, make a resume skip a phase, or make an unclosed run look closed through phase.retro. trusted_state still keeps review.*, phase.check, and merged compared, the merger checks CI live, and the merge gate reads the review records. Merges both passes' reports.
- Fix: while a check runs, have each caller command that writes a record (phase, note, metric, usage, tokens) log the key and value it wrote, somewhere no stage can write (for example beside the run state under build/pipeline with the runner's pid), and in state_unexpected accept a changed or new note.*, closing phase.*, or metric.* line only when that log names it.
none

None.

none
- Merged: ### A check stage can forge notes and closing phases in its own run state
- Location: `tools/run_state.sh`, `state_view`.
- Why: so that the close of a workflow that stops while its detached check runs leaves the rejoined check passing, the run-state comparison now also leaves out the notes (`note.*`) and the phases the close records (`phase.plan`, `implement`, `package`, `ci`, `merge`, `retro`, `report`), so a stage that writes its own change's run state by an absolute path during a check can plant such a note or phase and the check still passes; `phase.check`, `review.*`, `stage.*`, `merged`, and the measurements stay compared.
- Fix: log each record a caller's command (`phase`, `note`, `metric`, `usage`, `tokens`) writes while a check runs, outside any path a stage can write, and accept a changed note, phase, or figure only when that log names it; any other difference fails the check like the other run-state differences.
- Category: security
- Added: 2026-11-20

### The check-pass output budget line changed no decision
- Location: tools/run_state.sh, the check-pass budget line (finder-match-strict retro note 15); merge into `check-pass-budget-flag` (backlog queue Pool 19)
- Why: it printed over at 3 of 4 finder-match-strict check passes (256,092, 289,743, 307,646 of 200,000, notes 9, 10, 12) and the run went on unchanged; 8 of the last 9 medium feature rows exceed 200,000 output tokens (107,781 to 736,922) while 3 of 9 exceed the 1,200,000 total; this run 357,203 output, implement 185,448 (52%).
- Fix: calibrate the in-run output budget so it fires on at most 2 of the last 10 medium rows of a lane, or drop the check-pass line in favor of the total-token budget.
- Category: pipeline
- Added: 2026-11-20

### An advisory-only fix round counts as rework and reruns every stage and review

- Location: tools/run_state.sh (metric.rework) and .claude/workflows/deliver-change.js (the in-place fix round)
- Why: finder-grep-c (retro 5) had rework 2 of 3 with every first pass 1 (check, security, quality, bench, ci); its round 2 changed only README.md and docs prose and still reran every check stage and review. Near-same as the queued `rework-review-repeat` and `review-lite-docs`: merge into them.
- Fix: count an advisory-only round apart from a blocking one and let a docs-only advisory fix stand on the previous head's check, security, and bench; accepted when a tools-test case shows a docs-only advisory fix leaving metric.rework unchanged.
- Also: .claude/workflows/deliver-change.js, README.md
- Category: pipeline
- Added: 2026-11-20

### review-due no longer bounds uncounted merges
- Location: tools/run_state.sh:2235
- Why: review-due no longer caps how many merged changes go uncounted (SPRINT_EXCEPTIONS removed in #236, which came in through the merge of main). A queue edited to mark items T0, pool, beyond the sprint, or outside the 3 can keep the sprint-end security review of the combined diff from ever becoming due. Each delivery still gets its own security review. Security, Low, confidence 4.
- Fix: Bring back an upper bound so the sprint closes after at most sprint_size plus a fixed number of uncounted merges, whatever the queue text says. Add a tools_test.sh expect case where an uncounted run still trips the bound.
- Merged: ### review-due uncounted merges unbounded in sprint_state
- Location: tools/run_state.sh:2236
- Why: Same gap as the entry above, seen again at 040963076f86: sprint_state counts only the names not classed t0, outside, beyond, or pool, and nothing bounds how many go uncounted. Security, Low, confidence 4.
- Fix: Bring back an upper bound so the sprint closes after at most sprint_size plus a fixed number of uncounted merges, whatever the queue text says. Add a tools_test.sh expect case where an uncounted run still trips the bound.
- Category: security
- Added: 2026-11-20

### Security: a check leaves the remote-tracking refs unchecked, so a stage can forge origin/main for the next lane

- Location: `tools/run_state.sh`, `refs_view` and `main_moved`.
- Why: `refs_view` leaves out `refs/remotes/`, which every lane's fetch and push rewrite, and `main_moved` accepts the main checkout's HEAD at its branch's remote-tracking ref, so a stage can write `refs/remotes/origin/main` and fast-forward the main checkout to it; the forged ref lasts until the next fetch, and `lane-open` bases a new lane on the local `origin/main` without fetching.
- Fix: have `lane-open` fetch origin before it reads `origin/main`, or compare each remote-tracking ref after the check against `git ls-remote origin`, with a failing-stage case in `tools/tools_test.sh`.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-20

### Security: a check's escape scan leaves the XDG global git configuration and the branch the main checkout's HEAD names out

- Location: `tools/run_state.sh`, `escaped_paths` and `main_moved`.
- Why: git also reads `${XDG_CONFIG_HOME:-$HOME/.config}/git/config` as global configuration (a hook path, an alias, a credential helper), and `main_moved` compares only the commit the main checkout's HEAD names, so a stage writing the XDG file, or switching the main checkout's HEAD to another branch at the same commit, by an absolute path still passes the check; the queue item named only `$HOME/.gitconfig`, the main checkout, and the references.
- Fix: `escape_scan` the XDG configuration file beside `$HOME/.gitconfig`, and compare `git -C "$main_tree" symbolic-ref -q HEAD` beside the commit in `main_moved`, each with a failing-stage case in `tools/tools_test.sh`.
- Merged: ### Security: a check's escape scan leaves the XDG global git configuration and the main checkout's HEAD out
- Location: `tools/run_state.sh`, `escaped_paths` and `refs_view`.
- Why: git also reads `${XDG_CONFIG_HOME:-$HOME/.config}/git/config` as global configuration (a hook path, an alias, a credential helper), and `refs_view` lists `for-each-ref`, which leaves out the common directory's `HEAD`, so a stage writing either by an absolute path still passes the check; the queue item named only `$HOME/.gitconfig` and the references.
- Fix: `escape_scan` the XDG configuration file beside `$HOME/.gitconfig`, and add `git -C "$main_tree" symbolic-ref -q HEAD || git -C "$main_tree" rev-parse HEAD` to the compared views from a lane, each with a failing-stage case in `tools/tools_test.sh`.
- Merged: ### Quality: this findings file's first entry is superseded by a later one
- Location: the removed findings file of check-runner-safety-c
- Why: the first entry is superseded by the third (the same XDG gap, and its claim that the main checkout's HEAD is unchecked is stale since main_moved compares the commit), so the backlog receives a near-duplicate.
- Fix: Let groom merge the first entry into the third, dropping the stale HEAD claim.
- Also: tools/tools_test.sh
- Category: pipeline
- Added: 2026-11-20

### Security: refs_view leaves refs/remotes/ out, and lane_open bases a new lane on a remote-tracking ref without fetching (security Low (5))
- Location: tools/run_state.sh:1062, refs_view; tools/run_state.sh:3416, lane_open
- Why: lane_open bases a new lane on refs/remotes/origin/BRANCH when that ref exists, without a fetch first, so a stage can write refs/remotes/origin/NEXT-BRANCH at an attacker commit and the next delivery of that branch name tracks and starts from it, extending the recorded origin/main forging finding to the per-branch path.
- Fix: have lane_open run git fetch origin BRANCH before it reads refs/remotes/origin/BRANCH or origin/main, or after the check compare each remote-tracking ref against git ls-remote origin; add a failing-stage case in tools/tools_test.sh.
- Merged: ### Security: a forged remote-tracking ref seeds the next lane of that branch (security Low (5), reported twice, still present at package)
- Location: tools/run_state.sh:1062 (refs_view), tools/run_state.sh:3416 (lane_open)
- Why: refs_view leaves out all of refs/remotes/, and lane_open bases a new lane on refs/remotes/origin/BRANCH when that ref exists without fetching first, so a stage can write refs/remotes/origin/NEXT-BRANCH at an attacker commit and the next delivery of that branch name tracks and starts from it; this extends the recorded origin/main forging finding to the per-branch path.
- Fix: Have lane_open run git fetch origin BRANCH before it reads refs/remotes/origin/BRANCH or origin/main, or after the check compare each remote-tracking ref against git ls-remote origin; add a failing-stage case in tools/tools_test.sh.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-20

### Quality: main_moved's ls-remote reaches the network with no prompt guard or time limit (quality advisory)
- Location: tools/run_state.sh:1112, main_moved
- Why: the scan's git ls-remote origin can block on a credential prompt or a stalled connection, holding the check indefinitely.
- Fix: run it with GIT_TERMINAL_PROMPT=0 and a bounded timeout, a failure counting as moved as now, with a tools-test case for an unreachable origin.
- Merged: ### Quality: the scan's ls-remote has no prompt guard or time limit
- Location: tools/run_state.sh:1112 (main_moved)
- Why: the scan's git ls-remote reaches the network with no prompt guard or time limit, so a credential prompt or a stalled connection holds the check.
- Fix: Run it with GIT_TERMINAL_PROMPT=0 and a bounded timeout, the failure counting as moved as now.
- Category: pipeline
- Added: 2026-11-20

### Security: a lane check accepts another lane's branch moved or its worktree files edited (security Low (6), reported three times, still present at package)
- Location: tools/run_state.sh:1048 (refs_view, lane_branches, tree_scan)
- Why: refs_view skips every branch checked out in another lane's worktree (lane_branches), and tree_scan prunes the main checkout's tmp/, where the other lane worktrees live, so a stage can move another lane's branch to an attacker commit, or edit that lane's uncommitted files, and the check still passes, planting code in a concurrent delivery; the other lane's own committed-diff review partly mitigates this.
- Fix: Record each lane branch's object at escape_mark and accept a change only when it extends that object with commits not reachable from the check clone's HEAD, or better compare each other lane's branch tip against that lane's own run state; scan tmp/.lane-*/ for files whose status-change time is newer than the mark, outside the lanes' own pruned parts (.git, tmp, build links).
- Merged: ### Security: a lane check's scan skips other lanes' branches and worktrees, so a stage can move or edit a concurrent delivery (security Low (6))
- Location: tools/run_state.sh:1048, refs_view with lane_branches, and tree_scan pruning the main checkout's tmp/
- Why: refs_view skips every branch another lane's worktree has checked out, and tree_scan prunes tmp/, where the other lane worktrees live, so a stage can move another lane's branch to an attacker commit or edit that lane's uncommitted files and the check still passes, planting code in a concurrent delivery; that lane's own committed-diff review only partly mitigates it.
- Fix: record each lane branch's object at escape_mark and accept a change only when it extends that object with commits not reachable from the check clone's HEAD, or better compare each other lane's branch tip against that lane's own run state; scan tmp/.lane-*/ for files whose status-change time is newer than the mark, outside the lanes' own pruned parts (.git, tmp, build links).
- Category: security
- Added: 2026-11-20

### Security: a stage-made worktree puts any local branch on the scan's skip list (security Low (6), reported twice, still present at package)
- Location: tools/run_state.sh:1049 (lane_branches), tools/run_state.sh:3414 (lane_open)
- Why: lane_branches trusts every linked worktree that exists when the scan runs, so a stage can add its own (git worktree add -b NAME DIR COMMIT, or --force for an existing branch) and leave it, putting a new or moved local branch on refs_view's skip list; the admin entry under the common worktrees/ directory is not scanned, and lane_open reuses an existing refs/heads/BRANCH as is, so a stage can pre-create a queued change's branch at an attacker commit and the next delivery starts from it; that delivery's own diff review against origin/main partly mitigates this.
- Fix: Skip only the branches checked out at escape_mark (escape_lanes); for a branch first seen at scan time require that its worktree path is tmp/.lane-CHANGE of the main checkout and that build/pipeline/CHANGE.json names that branch, otherwise list it; alternatively have lane_open refuse an existing local branch that has no run state or no origin counterpart.
- Merged: ### Security: lane_branches trusts any linked worktree present at scan time, so a stage can hide a new or moved branch (security Low (6))
- Location: tools/run_state.sh:1049, lane_branches; tools/run_state.sh:3414, lane_open
- Why: a stage can create its own worktree (git worktree add -b NAME DIR COMMIT, or --force for an existing branch) and leave it, which puts any new or moved local branch on refs_view's skip list, while the admin entry under the common worktrees/ directory is not scanned; lane_open reuses an existing refs/heads/BRANCH as is, so a stage can pre-create a queued change's branch at an attacker commit and the next delivery starts from it, its diff review against origin/main only partly mitigating it.
- Fix: skip only branches checked out at escape_mark (escape_lanes); for a branch first seen at scan time require that its worktree path is tmp/.lane-CHANGE of the main checkout and that build/pipeline/CHANGE.json names that branch, else list it; alternatively have lane_open refuse an existing local branch with no run state or no origin counterpart.
- Category: security
- Added: 2026-11-20

### Security: stages run with the real HOME and the scan ignores its executed files (security Medium (6))
- Location: tools/run_state.sh:1131
- Why: apart from $HOME/.gitconfig the escape scan ignores every HOME file later tools execute: ~/.profile and the shell rc files agent Bash calls source, the hooks of ~/.claude/settings.json, and the XDG git configuration (already recorded), so a stage writing one of them by absolute path gets code execution in later agent sessions while the check passes.
- Fix: Run stages with HOME set to a throwaway directory inside the check clone (CLONE_EXEC), or escape_scan the profile and rc files, ~/.claude/, and ${XDG_CONFIG_HOME:-$HOME/.config}/git beside $HOME/.gitconfig, each with a failing-stage case in tools/tools_test.sh.
- Also: tools/tools_test.sh
- Category: security
- Added: 2026-11-20

### Quality: a check between the merger's lane-close and branch deletion fails as the references changed
- Location: tools/run_state.sh:1047 (refs_view)
- Why: the merger's step 7 runs lane-close, then ls-remote, the fast-forward, and git branch -D; a check whose escape_mark falls between lane-close and branch -D sees the closed lane's branch in no worktree at the mark or the scan, so its deletion fails the check, a rare false failure.
- Fix: Leave out of refs_view a branch present at the mark and gone at the scan only when no worktree held it, or have lane-close delete the branch with its worktree, with a test.
- Category: pipeline
- Added: 2026-11-20

### Quality: a tracked path holding a tab, newline, quote, or backslash is reported as untracked
- Location: tools/run_state.sh:1089 (main_scan)
- Why: core.quotePath=false still C-quotes a path holding a tab, newline, double quote, or backslash, so such a tracked file the merger's fast-forward rewrites is not matched by the find output and is reported as an untracked file.
- Fix: Read git ls-files -z and find -print0, or compare through git ls-files --others --ignored --exclude-standard instead.
- Category: pipeline
- Added: 2026-11-20

## Findings of grep-long-files after its package step

- quality advisory the removed findings file of grep-long-files docs format: the planner's appended entry '### A records run's advisories...' follows the previous entry's Fix line with no blank line, because plan-apply appends build/plan/ change /backlog.md with a bare cat (tools/run_state.sh:1926); fix: insert the blank line, and have plan_apply print a separating newline before appending to a non-empty fin
- Category: pipeline
- Added: 2026-11-20

### A concurrent lane's benchmark log fails another lane's check (pr-trust-lows check)
- Location: tools/run_state.sh tree_scan and main_scan; .claude/agents/benchmark.md step 1
- Why: the check of pr-trust-lows refused every pass because the main checkout's build/base-build.log changed while it ran; the feature lane's benchmark agent wrote that log while building origin/main in tmp/.base, so one lane's benchmark voids the other lane's check and costs a fix round with no defect in the change.
- Fix: have the benchmark agent write its base build log under tmp/.base (or name the log path in benchmark.md step 1 and let the guard refuse other build/ paths of the main checkout), or prune a named benchmark log directory in tree_scan as the stage logs are, with a tools-test case that a write there during a lane's check is not reported.
- Merged: ### A concurrent lane's bench fails another lane's check as an escape
- Location: tools/run_state.sh, escape_mark, main_scan and bench_compare (metrics_out, last.tsv)
- Why: the check of one lane failed with "a stage wrote outside its clone" naming the main checkout's build/metrics/current.tsv and last.tsv, written at 07:39:14 and 07:39:22 by the other lane's bench phase, which runs in the main checkout right after its own metrics stage; every stage of the failed check exited 0, so a clean change costs a full check round whenever two lanes overlap.
- Fix: have bench write its figures under the lane's own build/ (or build/stages/CHANGE/), or leave build/metrics out of main_scan like build/pipeline and build/stages, with a tools_test case running a bench beside a check.
- Also: .claude/agents/benchmark.md
- Category: pipeline
- Added: 2026-11-20

### tools/run_state.sh:1143: [ -z "$HOME" ] under set -u (line 396) (sprint-22 review quality)

- Location: `tools/run_state.sh:1143`
- Why: [ -z "$HOME" ] under set -u (line 396) aborts the escaped_paths command substitution when HOME is unset, the very case the test means to skip, so the later checks (toolchain, main checkout, config, refs, index, run state) never print and the check passes silently
- Fix: [ -z "${HOME:-}" ]
- Category: pipeline
- Added: 2026-11-20

### history names the run state file as the lane file it appended to
- Location: `tools/run_state.sh` `append_history`, the `echo "history: appended $change to $file"` line after `write_key row`.
- Why: `write_key` assigns the global `file` to the run state's path, so the message reads `appended second to build/pipeline/second.json` instead of the lane history; a reader of the package step's output is pointed at the wrong file.
- Fix: keep the lane file in its own variable (for example `lane_path`) or print the message before `write_key`, and add a tools-test case matching the lane file in the message.
None
- Category: pipeline
- Added: 2026-11-20

### plan-needed names only the first failing review while merged_since clears every one before the planner's time
- Location: tools/run_state.sh:3312 (plan_needed), with merged_since; quality advisory, pre-existing gap in the rule this change tightens
- Why: plan_needed hands the planner only the first failing review, yet merged_since clears every failing review recorded before that planner's at.plan-needed, so a second failing review is cleared without the planner having been given it
- Fix: name every failing review run in the needed line (and in planReview of .claude/workflows/deliver-change.js), or clear only the review that was named
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-20

### A concurrent lane's benchmark log fails another lane's check
- Location: `tools/run_state.sh` `escaped_paths` (`main_scan`) and `.claude/agents/benchmark.md` step 1
- Why: the check of picker-styles-b at 70f84e685dbd passed every stage but was refused because `build/scratch-base-build.log` appeared in the main checkout during its window; the file was written by another lane's benchmark agent redirecting its `make -C tmp/.base` output there, not by any stage, so a parallel delivery turns a clean check into a failed round.
- Fix: have the benchmark agent write its base logs under `tmp/.base/build/` (and the guard refuse a redirection into the main checkout's `build/`), or let `main_scan` skip ignored paths another lane's agent owns, with a tools test for each.
- Merged: ### Check refused on another lane's scratch logs in the shared build directory
- Location: tools/run_state.sh escaped_paths (main_scan of the main checkout's build/), check of picker-styles-b at 272ead28c383
- Why: an agent of the concurrent lane metrics-header-fix redirected its make output to build/scratch-lane-build.log, scratch-lane-metrics.log, scratch-base-build.log, and scratch-base-measure.log in the main checkout while this check ran, so every passed stage was discarded as an escape though no stage wrote them, costing a fix round with no code to change.
- Fix: have agents write scratch output under their own lane or the session scratchpad, never the main checkout's build/, or have escaped_paths ignore files whose writer is outside the check's process tree (for example by scanning only paths the stages can reach, or by refusing only with a stage's pid recorded).
- Also: .claude/agents/benchmark.md
- Category: pipeline
- Added: 2026-11-20

### groom folds findings entries that still name the findings files it deletes (sprint-22-records retro note 4)
- Location: `tools/run_state.sh` groom; seen at docs/backlog.md lines 9444, 9529, 9600 after sprint-22-records.
- Why: one folded reference failed docs-lint and was edited by hand, two more drew the run's one quality advisory and rework round 1 (quality=1164/4); records rows rework 0, 2, 2, 1, 1, 2, 1 over sprints 16 to 22. T1 pipeline defect, for the backlog lane.
- Fix: accepted when groom's output passes docs-lint and no folded entry names a removed findings file, so the next records run needs no hand edit and no rework round from this cause.
- Category: pipeline
- Added: 2026-11-20

### PRUNE_ALL_SPRINT dead after the sprint-24 close at tools/run_state.sh:439

- Location: tools/run_state.sh:439 (`PRUNE_ALL_SPRINT=sprint-24`, read by `backlog_oldest`), its case "run_state: backlog-oldest lists every entry at the close of PRUNE_ALL_SPRINT" in tools/tools_test.sh, and its mentions in the run_state.sh header and docs/codebase-map.md.
- Why: the constant makes the sprint-24 close's scan whole, the user's one whole-backlog scan of 2026-11-20; once sprint-24 closes it never matches again, dead code beside `PRUNE_COUNT`.
- Fix: after the sprint-24 close, remove `PRUNE_ALL_SPRINT`, its line in `backlog_oldest`, `sprint_next` when nothing else reads it, its test cases, and its header and code-map words.
- Also: tools/tools_test.sh, docs/codebase-map.md
- Category: pipeline
- Added: 2026-11-21

### A lane's check fails on another lane's write into the main checkout's build/metrics
- Location: tools/run_state.sh escaped_paths and main_scan (about :1158), clone_drop (about :1282, the copy to the relative metrics_out), bench (build/metrics/last.tsv)
- Why: groom-stale-prune's check at b46fe59 passed every stage, then failed as "stage none" because /home/user/carat/build/metrics/current.tsv changed at 19:13:45, the moment the feature lane's check runner (status-winbar-tabs-b) dropped its clone and wrote its carry, and last.tsv changed at 19:13:53; no stage of this lane wrote there (its own measurement went to the worktree's build/metrics at 19:20:15). A runner or bench whose working directory is the main checkout copies its figures into the main checkout's build/, and main_scan counts any such write against whichever lane's check is running, so two lanes at once can fail each other's check with a false escape.
- Fix: make clone_drop and bench write metrics_out under the runner's own top (an absolute path from check_run's pwd, refused when it is the main checkout while the clone is a lane), and leave the main checkout's build/metrics out of main_scan or attribute it by the writing runner's pid file; add a tools-test case running two lanes' runners where one writes the main checkout's build/metrics and the other's check still passes.
- Category: pipeline
- Added: 2026-11-21

### A security review after a quality-only fix reads the whole branch again
- Location: the locations listed under this heading in the backlog; the queue line of review-trust-lows names tools/run_state.sh:201 and the sprint and delivery workflows
- Why: a security or review Low handed to review-trust-lows, whose first part fixed only the instruction-record settle; left open here.
- Fix: queued by this heading in review-trust-lows-b (docs/queue-backlog.md Sprint 24) or review-trust-lows-c (Pool), the later parts of review-trust-lows; each part adds a tools-test case that fails before its fix.
- Also: docs/queue-backlog.md
- Category: security
- Added: 2026-11-21

### plan-apply copies a planned goals.md after the security review
- Location: tools/run_state.sh plan_apply (goals.md over docs/goals.md, in the package step)
- Why: since review-trust-lows the push gate settles no pass across a docs/goals.md commit, so a planner-written goals.md applied in the package step makes the security pass stale and reviewed-edits names it; the planned goals change is then restored away instead of landing.
- Fix: apply a planned goals.md in the implement step, where the reviews read it, or have plan-apply refuse it with a note that the goals change needs its own delivery.
- Merged: ### plan-apply copies goals.md after the security review that reviewed-edits says to restore (`review-trust-lows` quality advisory)
- Location: `tools/run_state.sh` `plan_apply` (about line 1960) against `reviewed_edits` (about line 2103)
- Why: the package step runs `plan-apply`, which copies `build/plan/CHANGE/goals.md` over `docs/goals.md` after the security review, while `reviewed-edits` now tells the contributor to restore any `docs/goals.md` change since that review, so the two rules contradict and a planned goals edit cannot land through a package step.
- Fix: have `plan-apply` leave `goals.md` and name it when a security pass is recorded (or apply it in the implement step, before the reviews), with a tools-test case.
- Merged: ### plan-apply copies a planned goals.md after the security review that reviewed-edits then asks to restore (review-trust-lows quality advisory, raised three times)
- Location: tools/run_state.sh:1970 plan_apply (also reported at :1960) and tools/run_state.sh:2112 reviewed_edits (also reported at :2103 and :2113)
- Why: the package step's plan-apply copies build/plan/CHANGE/goals.md over docs/goals.md after the security review, which makes the pass stale, and reviewed-edits then tells the contributor to restore the file, so the two rules contradict.
- Fix: have plan-apply leave docs/goals.md and name it when a security pass is recorded, or apply it in the implement step, with a tools-test case.
- Also: docs/goals.md
- Category: security
- Added: 2026-11-21

### groom folds none/None placeholder lines from findings files
- Location: docs/backlog.md:922 (a stray None in the LIMIT-doubles entry), :9956 and :9962 (none and None after a doubled blank line); tools/run_state.sh groom
- Why: the placeholder lines of syntax-tidy.md, contributor-tier-medium.md, and metrics-header-fix.md were folded verbatim into the backlog.
- Fix: have groom skip a findings file holding only none or None and drop a trailing none or None line, with a tools-test case; remove the three lines in the next records change.
- Category: pipeline
- Added: 2026-11-21

### groom folds the none/None lines of findings files (sprint-23-records retro note 11)
- Location: `tools/run_state.sh` groom's findings fold; `docs/backlog.md:922`, `:9956`, `:9962`; merge into the entry sprint-23-records recorded for its notes 1 and 4.
- Why: 3 stray lines raised 2 of the run's 7 advisories and one of its 2 rework rounds.
- Fix: accepted when a tools-test folds a findings file holding only none/None, or ending in such a line, without that line, and the next records run raises no placeholder advisory.
- Category: pipeline
- Added: 2026-11-21

### named_history and named_since repeat the groom pathspec (sprint-24 review quality)

- Location: `tools/run_state.sh:2999`, `:3013`, `:431`
- Why: both hard-code the backlog, findings, and queue pathspec, which must agree for the rev-list to match the log, and the queue glob repeats queue_files.
- Fix: build the pathspec once from queue_files and use it in both git calls.
- Category: pipeline
- Added: 2026-11-21

### SPRINT_HEADER is never read (sprint-24 sweep quality)

- Location: `tools/run_state.sh:571`
- Why: dead since the sprints change.
- Fix: delete it, or write it into an absent `docs/sprints.tsv`.
- Also: docs/sprints.tsv
- Category: pipeline
- Added: 2026-11-21

### backlog-move's mismatch refusal has no test

- Location: `tools/run_state.sh`, `backlog_move`, the `cmp -s "$before" "$after"` branch that keeps FILE and dies.
- Why: `file_entries` appends every entry line unchanged, so no fixture makes the folder differ from before plus FILE; the branch guards a future change to the filing, and a regression there would go unseen.
- Fix: let a test inject a filing that drops a line (for example an environment hook naming the filing command), then expect the refusal and FILE kept.
- Category: pipeline
- Added: 2026-11-21

### A refused filing leaves the entries filed before it in the folder
- Location: tools/run_state.sh file_entries (the linked and mkdir refusals), backlog_move
- Why: file_entries writes each entry as it reads it, so when it refuses a symbolic link or a directory midway, the entries before it are already appended; backlog-move then keeps FILE, and running it again after removing the link files those entries twice (groom likewise keeps the findings files).
- Fix: check every target file (linked, mkdir) in a first pass over the buffered entries and write only when all pass, or write into a copy of the folder and move it in place once the filing succeeded.
- Category: pipeline
- Added: 2026-11-21

### plan-apply overwrote the lane queue with a plan older than the branch's queue
- Location: `tools/run_state.sh` plan-apply; `build/plan/backlog-per-file/queue-backlog.md` (written 12:45 UTC, before #276 merged and before the branch's queue commits ec40276 and 9f981a9).
- Why: in this change's package step it re-queued the merged `backlog-records-rule` as Pool 1, dropped the backticks `queue_class` needs around `backlog-per-file` in the Sprint 25 exception line, and dropped three Decisions lines; the contributor restored the branch's queue by hand. Same defect as the queued `plan-apply-stale` (#263 lost 5 items).
- Fix: plan-apply refuses a plan whose files are older than the last commit touching the lane queue, or one naming a change already in the lane's metrics file, and says so; a tools-test case each.
- Category: pipeline
- Added: 2026-11-21

### plan-apply copies a plan older than the branch's queue

- Location: the package step's `plan-apply` in `tools/run_state.sh`; backlog-per-file note 3.
- Why: second occurrence: #263 lost 5 items; #278's plan predated #276 and branch commits ec40276, 9f981a9, re-adding merged backlog-records-rule and dropping 3 Decisions lines; the contributor restored it by hand, package 62,305 output on 20 calls (11.3 percent of 551,639).
- Fix: leave untouched, or refuse, a queue whose plan predates the queue's last commit; accepted when packaging needs no manual restore over the next three deliveries.
- Category: pipeline
- Added: 2026-11-21

### A change named only in a lane exception line resolves to the wrong lane (facet-design-doc retro note 16)
- Location: tools/run_state.sh:1907 lane_of and plan-apply; docs/queue-feature.md Sprint 25 exception line at 4a84ecee96f8
- Why: facet-design-doc, named in backticks only in the feature lane's exception line and merged with a docs subject, got a backlog-lane history row the contributor reverted by hand; the merged commit holds no docs/metrics-feature.tsv row (15 files) and plan-apply skipped its feature queue plan, so `one-accent` and `glyph-audit` (16 of 20 Known drift rows of docs/design.md section 7) were in 0 lines of docs/queue-feature.md.
- Fix: resolve a change named in a lane's exception line to that lane; accepted when a tools-test case does so and its package step writes only that lane's history row and applies only that lane's queue plan.
- Also: docs/queue-feature.md, docs/metrics-feature.tsv, docs/design.md
- Category: pipeline
- Added: 2026-11-21

### Plan notes reach the findings file twice (facet-design-doc retro note 17)
- Location: tools/run_state.sh plan-apply, the implement step's findings append; docs/findings/facet-design-doc.md at 4a84ecee96f8
- Why: the file holds 13 headings, the 6 plan retro notes each written twice (implement appended them, package plan-apply again) plus 1 lane note; the miscount fed a blocked pull request text round (prtext 4,870 output, 10 tool calls, a second push).
- Fix: append each plan note once; accepted when a run whose implement step appends the plan notes and whose package step runs plan-apply ends with each heading once, a tools-test case or docs-lint refusing a repeated heading in a findings file.
- Category: pipeline
- Added: 2026-11-21

### self_fix has no history column
- Location: tools/run_state.sh HEADER and history_row; .claude/workflows/deliver-change.js metricLine
- Why: the keep rules of docs/goals.md read rework plus self_fix, but self_fix lives only in the run state (metric.self_fix), so the planner comparing history rows cannot see the rework a contributor fixed in its own session; adding a column means rewriting line 1 and padding every row of both lane histories, and this change may not touch the feature lane's docs/metrics-feature.tsv.
- Fix: a sprint records change appends a self_fix column 25 to HEADER, pads both lane files with -, writes metric.self_fix in history_row, and points docs/goals.md at the column.
- Also: .claude/workflows/deliver-change.js, docs/goals.md, docs/metrics-feature.tsv
- Category: pipeline
- Added: 2026-11-21

### An exception paragraph naming a change without backticks leaves it counted in the sprint
- Location: tools/run_state.sh:2611, tools/docs_lint.sh:177; the groom-evidence-only line was docs/queue-backlog.md:7 at 01bee7b47329.
- Why: the sprint count and the docs lint read a change out of the 3 only when the exception paragraph names it in backticks, so a paragraph naming it in plain words, as that line does, leaves the change counted toward the sprint's 3 backlog changes and can close or overfill the sprint early.
- Fix: read a change name in an exception paragraph with or without backticks (a kebab-case word matching a merged or queued change), or have docs-lint refuse an exception paragraph that names a change without backticks; a tools-test case each.
- Also: tools/docs_lint.sh, docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### An exception paragraph naming a change without backticks leaves it counted
- Location: tools/run_state.sh:2611 (queue_class matches only a backticked name), tools/docs_lint.sh:177 (check_queue), docs/queue-backlog.md:7 at 01bee7b47329 (the groom-evidence-only line).
- Why: the Sprint 25 line "groom-evidence-only runs first in the backlog lane, outside the 3" names the change bare, so queue_class at #270 finds no `groom-evidence-only` in the clause and the change is not classed outside, though the user put it outside the 3; the contributor-tier-high brief quoted its line bare too, and only the planner's backticks keep it outside; docs-lint passes either form.
- Fix: docs-lint refuses a "The user-approved exception" paragraph holding "outside the 3" whose clause before " run "/" runs " names no backticked change, a tools-test case each for the bare and the backticked form; check how #270's history row was classed and correct its sprint count if it was counted.
- Also: tools/docs_lint.sh, docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-21

### lane_of puts a docs change briefed to the feature lane in the backlog lane, so its history step writes a backlog file
- Location: tools/run_state.sh lane_of (line 1905); docs/queue-feature.md:7 names the exception line but no numbered item
- Why: facet-design-doc runs first in the feature lane by the user's exception, yet no queue item names it, so lane_of falls to its chore branch type and answers backlog; its package step's history then appended review-in-openspec to docs/metrics-backlog.tsv against the brief's "touch no file of the backlog lane", reverted here, the row left to the backlog lane's next package step
- Fix: let a change named by an exception line under a queue heading take that queue's lane; accepted when lane facet-design-doc prints feature with the line in place and history appends to no other lane's file.

none
- Also: docs/queue-feature.md, docs/metrics-backlog.tsv
- Category: pipeline
- Added: 2026-11-21

### The escaped verdict lets any write under the main checkout's build/ through (security Medium (5))
- Location: tools/run_state.sh:826 (lane_written)
- Why: any escaped path under the main checkout's build/ reads escaped, including build/bin/carat (the release binary the README tells the user to alias as their editor), build/dev/carat, build/test/run_all, build/spinel/gen_respond_to_tables, and build/metrics/base.tsv, though no lane writes any of these: LANE_LINKS shares only build/pipeline, build/stages, build/plan, and build/spinel-cache, and tree_scan already skips all four. Branch code that makes one write planting a trojaned build/bin/carat (or a forged base.tsv) reads escaped, the check reruns with no fix round, the rerun's escape_mark takes the planted file into its baseline, the rerun passes, and only a security-escape note is left.
- Fix: keep the escaped verdict (rerun with no fix round) only for an explicit allowlist of paths another lane is known to write in the main checkout's build/, not the whole build/ prefix, which may well be empty since every LANE_LINKS build/ directory is already skipped; any write to build/bin, build/dev, build/test, build/spinel, build/bench, build/metrics, or anywhere else under build/ reads stage none failed with a fix round; add tools_test cases for a write to build/bin/carat from a lane.
- Category: security
- Added: 2026-11-21

### A write outside the check clone is detected but never reverted (security Low (4))
- Location: tools/run_state.sh:1060
- Why: the next check takes a planted file into its baseline. Branch code plants a trojaned build/bin/carat in the main checkout; that check fails and leaves a security-escape note, but the fix round's next check baselines the planted binary and can pass, and nothing in the merge gate reads the note, so the trojan stays where the README tells the user to alias their editor.
- Fix: when a check reads failed with escaped paths under the main checkout's build/bin, build/dev, build/test, or build/spinel, delete or quarantine those outputs so the next build regenerates them, or have the merge gate or the workflow refuse a run whose security-escape note has no matching resolution; add a tools_test case that runs a second check after a planted build/bin/carat.
none
- Category: security
- Added: 2026-11-21

### The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)
- Location: the merger's merged-commit report and its run state record (tools/run_state.sh, the merge-disagreement note)
- Why: sprint-24-records reported 50d8a3c00ee6 while the squash commit on main is 24df30ea9c94, recorded instead; a wrong merged commit would reach the history row's merged column without the check.
- Fix: the merger reports the commit `git rev-parse` gives for main after the merge; accepted when a tools-test case records a mismatched report as a disagreement and keeps main's commit.
- Category: pipeline
- Added: 2026-11-21

### The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)
- Location: the merger's merged-commit report and its run state record (tools/run_state.sh, the merge-disagreement note)
- Why: sprint-24-records reported 50d8a3c00ee6 while the squash commit on main is 24df30ea9c94, recorded instead; a wrong merged commit would reach the history row's merged column without the check.
- Fix: the merger reports the commit `git rev-parse` gives for main after the merge; accepted when a tools-test case records a mismatched report as a disagreement and keeps main's commit.
- Category: pipeline
- Added: 2026-11-21

### backlog-move is a one-shot migration left in run_state.sh (sprint-25 review quality)
- Location: `tools/run_state.sh:3044` (header lines 273 and 359), `tools/rules.sh:70`
- Why: `backlog_move` and its tools-test cases remain with nothing left to move since docs/backlog.md was removed, and RECORDS_RE and its comment still name docs/backlog.md.
- Fix: remove backlog-move with its tests and map text; drop the docs/backlog.md alternative from RECORDS_RE in the next rules.sh edit, alone, keeping docs_lint's RETIRED entry; accepted when tools-test passes and `grep -c backlog_move tools/run_state.sh` prints 0.
- Category: pipeline

### In this sprint's diff (contributor-self-check). The checker now skips at tools/run_state.sh:1077 (sprint-26 review security Low (3), note 3)

- Location: tools/run_state.sh:1077
- Why: In this sprint's diff (contributor-self-check). The checker now skips the stages that the contributor's own check passed at HEAD. Those stage records are written by the run_state.sh copy in the contributor's working tree. The contributor can edit that copy and run it before restoring it, so the waiter writes 'passed' records at a committed HEAD whose diff is reported as touching no machinery. The design documents and limits this: CI reruns every fast stage except diagnose and gates, the merge gates rerun gates, and the checker reruns diagnose (RERUN_STAGES). The remaining exposure is that local-only results can be faked until CI runs; no unchecked merge path was found.
- Fix: No change needed for merge safety. To close the local gap, start the runner from the main checkout's copy of tools/run_state.sh at origin/main, or from a copy of HEAD's blob (git show HEAD:tools/run_state.sh), instead of the working tree's file, so an uncommitted edit cannot write records.
- Category: security
- Added: 2026-11-22

### duplication: backed_commit and check_stages (1082) each read phase.check and at tools/run_state.sh:681 (sprint-26 review quality, note 11)

- Location: tools/run_state.sh:681
- Why: duplication: backed_commit and check_stages (1082) each read phase.check and convert it to its twelve-digit form with the same two lines
- Fix: one helper, for example recorded_check, used by both
- Category: pipeline
- Added: 2026-11-22

### the runner refuses a dirty tracked tree with its at tools/run_state.sh:1204 (sprint-26 sweep quality, note 13)

- Location: tools/run_state.sh:1204
- Why: the runner refuses a dirty tracked tree with its own copy of check_wait refusal (run_state.sh:1557), and the verdict line check: stage none failed at HEAD; read LOG is written at five places (1119, 1146, 1206, 1456, 1514), while check_verdict matches the verdict forms by pattern
- Fix: one dirty_tracked helper and one function that writes the failed verdict, beside check_verdict
- Category: pipeline
- Added: 2026-11-22

### The planner's sprint queues reach a records change failing the docs-lint queue check (sprint-26-records retro note 4)
- Location: tools/run_state.sh:4237 (plan-apply copies the planner's lane queue unchecked); tools/docs_lint.sh:68 (the queue check)
- Why: 6 Pool items (13 to 18) of docs/queue-backlog.md lacked an estimated size, failing make docs-lint in sprint-26-records and costing a hand edit of a queue in its implement start.
- Fix: refuse or flag a planner queue that fails the docs-lint queue check before groom and plan-apply copy it; accepted when the next sprint-N-records passes make docs-lint with no hand edit of docs/queue-*.md.
- Also: tools/docs_lint.sh, docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-22

### Head-form notes record a head git confirms (folded-row retro note 4, notes 1 and 5)
- Location: tools/run_state.sh and .claude/workflows/deliver-change.js, the head check of a contributor start; backlog queue Pool 14 `head-drop`: merge into it.
- Why: 39 taken-from-git notes across the run states, 0 refused; folded-row 2 more (implement be275416f50a, package 6ec0fe0457d8), neither refused; 43 head-form notes in 16 runs; none changed a decision.
- Fix: no record line when git corrects a reported head to the same commit; accepted when the next 5 runs record no head-form note and tools-test still shows a head that differs from git refused.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-22

### The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)
- Location: tools/run_state.sh `budget`; near backlog queue Pool 13 `budget-recalibrate` and "### The in-run budget line prices total tokens at 6 per output token", merge into it.
- Why: budget sprint-26-records printed 0 total with 34,373,476 set apart, against the row's 2,612,300 total.
- Fix: accepted when budget sprint-26-records prints a nonzero total no larger than 2,612,300 and set-apart plus own tokens match the records.
- Category: pipeline
- Added: 2026-11-22

### The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)
- Location: tools/run_state.sh `budget`; near backlog queue Pool 13 `budget-recalibrate` and "### The in-run budget line prices total tokens at 6 per output token", merge into it.
- Why: budget sprint-26-records printed 0 total with 34,373,476 set apart, against the row's 2,612,300 total.
- Fix: accepted when budget sprint-26-records prints a nonzero total no larger than 2,612,300 and set-apart plus own tokens match the records.
- Category: pipeline
- Added: 2026-11-22

## tools/run_state.sh groom: security entries removed without a named fixing commit

- Location: `tools/run_state.sh` (groom), `docs/queue-backlog.md` Groom line.
- Why it matters: groom removed four security Low entries (held-finding and unpushed-finding notes, the skeptic's quoted note) citing only counts, so a later reader cannot trace that they were closed by evidence; the fix exists in 9e4aca0 (#289).
- Fix outline: make groom refuse to remove a security-category entry unless a fixing commit is named, and record each removed security entry with that commit in the Groom proof line or groomed.md. This round only cites 9e4aca0 in the sprint-26 Groom line, briefly, the queue file being at its budget.
- Also: docs/queue-backlog.md
- Category: security
- Added: 2026-11-22
