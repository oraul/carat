### agent_hooks misses frontmatter keys that widen an agent's authority

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 2 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no agent_hooks in tools/ .claude/ Makefile at base or HEAD; removed by 6b7d489 (#109); review_due at base:3228 counts merges only.
- Fix: none left

### Agents leave scratch files in the repository root

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 3 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### A compile pass is cached whatever make command ran it

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 4 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a compile pass under one make command is not skipped under another" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### The run state header omits the compiled-KEY stage suffix

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 5 of run-state-backlog-b
- Why: Not fixed: the header comment is not printed by the usage and nothing reads it, so no behavior of the script differs; the comment names compiled-KEY at HEAD and lacked it at ce04c85, which a grep would show and no tools-test case can fail on.
- Fix: none; stays in the backlog

### dev-build's code key changes with test/ and bench/

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 6 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: dev-build keeps its code key across a commit to test/ and bench/" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### check_lost and check_wait re-read the run state and the pid file inline

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 7 of run-state-backlog-b
- Why: Not fixed: claim corrected: the earlier change said check_lost and check_wait no longer read the run state and the pid file inline, but check_wait still reads the pid file inline where read_pid does the same; the two reads differ in no observable behavior (the script has no errexit), so no case can fail at the base; the duplication stays.
- Fix: none; stays in the backlog

### An interrupted stage is recorded at the runner's head, not its start commit

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 8 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base run_state.sh:1107 stages_stop writes the killed record with $job_at from job_load (base:1000-1007); check_signalled no longer writes with $head.
- Fix: none left

### The run state's writer has no lock beside the detached check runner

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 9 of run-state-backlog-b
- Why: Fixed: the run state's writer takes a lock (state_lock): a live holder makes a write wait STATE_LOCK_WAIT seconds and refuse, a dead one's lock is taken over, a write leaves none behind. Case "run_state: a write refuses while a live process holds the run state's lock" fails at BASE (414eb5af5baa), passes at HEAD.
- Fix: none left

### A lost check runner leaves its make running while a second one starts

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 10 of run-state-backlog-b
- Why: Fixed: check_lost stops the dead runner's process group (runner_group_stop) before a second runner starts. Case "run_state: a check that finds its runner gone stops the processes the runner left" fails at BASE (414eb5af5baa), passes at HEAD.
- Fix: none left

### A detached check runner outlives a stopped run and shares build/

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 11 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base clone_make (base:1506-1516) builds every check in its own mktemp clone; per-change state/carry/pid files.
- Fix: none left

### The check verdict is read from a log read agents can write

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 12 of run-state-backlog-b
- Why: Not fixed: needs an operating-system sandbox: the runner writes the verdict line as the same user as the stages, so no check of the log can tell the runner's last line from one a stage forges.
- Fix: none; stays in the backlog

### Recording merged deletes refs on origin from the generic key writer

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 13 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no push --delete or backup refs at base; only git push is push's (base:1929); set merged -> merged_at (base:4573).
- Fix: none left

### drop_backup joins the ref names by unquoted word splitting

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 14 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no drop_backup/backup at base; base tools_test.sh:1246 "backup is no longer a command".
- Fix: none left

### abandon reports no backup left when origin is unreachable

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 15 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no abandon/drop_backup at base; base tools_test.sh:1424 "abandon is no longer a command".
- Fix: none left

### The backup's base record outlives the backup

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 16 of run-state-backlog-b
- Why: Gone, no code changed: evidence: backup command absent at base (base_test:1246).
- Fix: none left

### The backup runs the branch's own gates

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 17 of run-state-backlog-b
- Why: Gone, no code changed: evidence: backup command absent at base (base_test:1246).
- Fix: none left

### The run_state.sh bullet reads as if it listed every command

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 18 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### run_state.sh became executable in run-budgets

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 19 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### spent_line repeats budget_line's budget lookup

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 20 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### A pipeline fix rode in the hover pull request

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 21 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### A link planted in the check clone's build directory survives

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 22 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a link a stage plants in build/ reaches no carry" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### The runner's wait is longer than it says, in two copies

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 23 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: the wait on a runner ends at its limit by the clock under a whole-second sleep" fails at 414eb5af5baa and ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### A run_state.sh paragraph splits its Usage list

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 24 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### The check-pass budget line projects 6 total tokens per output token

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 25 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### A failed backup is retried by every start and never recorded

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 26 of run-state-backlog-b
- Why: Gone, no code changed: evidence: backup command absent at base (base_test:1246).
- Fix: none left

### drop_key repeats write_key's rewrite

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 27 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### delivery-speed quality advisory at tools/run_state.sh:406

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 28 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### delivery-speed quality advisory at tools/run_state.sh:1217

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 29 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### pr-by-tag quality advisory at tools/run_state.sh:716

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 30 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: same problem as entry 30, fixed there: run_state.sh:1857-1860 comment, docs/codebase-map.md:50, test tools_test.sh:3428.
- Fix: none left

### Check clone's binary path not named in the map (late `pr-by-tag` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 31 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Groom's listed check matches any archive name suffix (`sprint-planning` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 32 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no "archive/" in run_state.sh at base or HEAD; listed proof is item_lists (base:3631).
- Fix: none left

### Groom lets every copy of a duplicated finding go (`sprint-planning` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 33 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### plan-needed treats an unreviewed sprint plan as waiting (`sprint-planning` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 34 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Sprint after a sixth merge reviews a change twice (`sprint-planning` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 35 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Usage header splits review-due's description (`ci-time` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 36 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base:281 ci-stages and base:285 tokens precede base:289 review-due, whose block is contiguous to base:306.
- Fix: none left

### Stale comment on who runs ci-stages (`ci-time` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 37 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### ci-stages may drop every step on fractional seconds (`ci-time` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 38 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base ci_stages jq adds the fraction and awk accepts ^[0-9]+([.][0-9]+)?$; base tools_test.sh:2049 fractional case.
- Fix: none left

### ci-stages step name can exceed 32 characters (`ci-time` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 39 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### records-once quality advisory at tools/run_state.sh:233

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 40 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### records-once quality advisory at tools/run_state.sh:1586

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 41 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### history and groom skip on records of a branch that never merges (sprint-2 sweep)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 42 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Path-scope helpers split the stage-list comments in run_state.sh

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 43 of run-state-backlog-b
- Why: Not fixed: layout of comments only, no behavior a tools-test case can fail on.
- Fix: none; stays in the backlog

### Tests-only carry runs before the path scope in run_state.sh

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 44 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a stage recorded scoped is not carried across a tests-only commit, the scope deciding it again" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### The ci-stages secs filter is never run by a test

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 45 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### merged_on_main repeats supported

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 46 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### unmerged_list duplicates pending_list's loop

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 47 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Planner does not know the beyond-the-sprint marker

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 48 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Three path classifiers decide which stages run

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 49 of run-state-backlog-b
- Why: Not fixed: the three classifiers are TEST_ONLY and NOT_COMPILED here and TOOLS_RE in tools/rules.sh, an edit of which is out of scope; merging them changes no behavior, so no red case exists.
- Fix: none; stays in the backlog

### The sprint exception membership test is written three times

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 50 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### EXCEPTION_MARK names clash with the user-approved exception

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 51 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### merged_since reads only the last metrics row's merged commit

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 52 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base rs:4050-4072 already walked every history row newest first until one does not descend (same at HEAD rs:4257-4280); test 'plan-needed keeps a failing periodic security review a merge planned before it followed' (pre-existing tt:3687).
- Fix: none left

### sprint_state picks an exception past the fifth counted row

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 53 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no SPRINT_EXCEPTIONS/sprint_exceptions/exception_item at base or HEAD (grep); base sprint_state classes each name by queue_class, no single exemption to spend.
- Fix: none left

### plan_needed lists run states differently from pending_list

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 54 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Unwrapped comment lines in run_state.sh

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 55 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### planned_commits re-implements the run-state key parsing of read_key

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 56 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### plan_needed and merged_since comments run past the comment wrap

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 57 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### plan_needed lists review runs by parsing ls output

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 58 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: same as 53 (FIXED): review_runs rs:4310 globs, no ls parsing left.
- Fix: none left

### plan-needed wording says no change merged since though a merge planned before the review no longer counts

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 59 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Review-run listing and reviewed-commit resolution are repeated

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 60 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### plan-needed needed line omits the later passing review condition

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 61 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### run_state.sh header plan-needed line and plan_needed comment have over-long lines

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 62 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d. claim corrected: the earlier change fixed the plan_needed comment, but the plan-needed usage lines of the header stayed over-long (88, 81, and 92 columns), identical to the base
- Fix: see the item named

### history_rows walks the whole rev-list on every call

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 63 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### lane_of misses a queue item that estimate_of and exception_item find

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 64 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### metrics_files breaks on a METRICS_PREFIX holding a space

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 65 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Review runs and full commits are looked up in several places of run_state.sh

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 66 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: same as 59 (FIXED): review_runs rs:4310, full_commit rs:4320 used by merged_since, passed_since, plan_needed, supported.
- Fix: none left

### backlog-pick tries each backticked path twice

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 67 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Top-level docs findings never reach a batch

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 68 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### No case pins a bare directory word known only by its files

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 69 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### merge_main hides a merge failure that is not a conflict

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 70 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Concurrent lanes race on the shared origin/main ref lock

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 71 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### lane_open and lane_close remove a worktree by different steps

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 72 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### lane_of prints the shell's error for a missing queue file

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 73 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### push --review-fix does not check that a review blocked

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 74 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### The init usage line still says it refuses any merged run

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 75 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Two lanes share one writable toolchain and compile cache (sprint-10 security Low (3), disputed)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 76 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### history writes late findings to a findings file the records change folded

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 77 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### groom documents CHANGE as optional though it dies without one

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 78 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### lane_open checks the branch with a line-wise grep and a third copy of the pattern

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 79 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### The package step appends the planner's findings twice

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 80 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### plan-apply and history write into whatever checkout runs them

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 81 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### A merge that fails on a moved main has no push path

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 82 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base push_branch already had --main-moved (base rs:1900); deliver-change.js mainMoved/merge-main path present.
- Fix: none left

### Groom folds a findings file without a trailing newline as is

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 83 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base groom rs:3892 'for f ...; do cat "$f"; echo; done' and base file_entries prints a blank line before every entry and trims trailing blanks.
- Fix: none left

### The branch pattern and the trailer are spelled three times each

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 84 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### A stage's branch code can forge its pass record through the runner's job files (security Medium, confidence 6)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 85 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base rs:971-1006 job_table in runner memory, status from wait on the runner's own child (base 987-990, 1062-1064); no jobs/ directory at base.
- Fix: none left

### A failing stage's log excerpt reaches the terminal unfiltered (security Low, confidence 4)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 86 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base rs:1226 'tail -n 20 ... | visible_text', visible_text base 1023 replaces C0 and C1 controls.
- Fix: none left

### stages_stop does not record a passed compile stage as compiled

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 87 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a compile stage that passed while the check stopped is skipped on the same code" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### Groom output needs a hand edit and draws the records runs' quality advisories

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 88 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Folded backlog headings follow the previous entry with no blank line

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 89 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base file_entries prints "" before each filed heading (base rs:3317 flush).
- Fix: none left

### groom output needs a hand edit after each records run (sprint-12-records retro note 5)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 90 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: same as 87 (FIXED).
- Fix: none left

### A check stage can fake a sibling stage's pass through the job files (sprint-13 security Medium (6))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 91 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: same as 84 (ALREADY at base).
- Fix: none left

### The failing stage's log excerpt reaches the terminal unfiltered (sprint-13 security Low (4))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 92 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: same as 85 (ALREADY at base).
- Fix: none left

### jobs_refusal has two arms for one message and runs twice (sprint-13 quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 93 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a runner refusing its CHECK_JOBS leaves the compile records as they were" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### A doubled blank line before check_wait (sprint-13 quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 94 of run-state-backlog-b
- Why: Not fixed: a doubled blank line is layout only, no behavior a tools-test case can fail on.
- Fix: none; stays in the backlog

### squash_commit falls back to HEAD, so a branch commit can pass merged_at (security Low (4))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 95 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### merged_at without a pr accepts any ancestor of HEAD (sprint-14 review and sweep quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 96 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### The security record keeps only the last review round (merge-record-check retro 7)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 97 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### The planner starts only to remove the delivered item (vim-line-commands-a retro 5)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 98 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base plan_needed (base rs:4157-4200) already printed 'not needed' for a queue head with an estimate and no pending note.
- Fix: none left

### Records changes are judged against the small budget with the sprint reviews in their totals

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 99 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no sprint-N-records change after sprint-28 in the metrics files (sprint plans now apply in a delivery's package step); budget_line unchanged.
- Fix: none left

### moved compares the change's files through unquoted, magic-capable pathspecs

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 100 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base moved_change (base rs:4445-4475) compares names as text with grep -F -x and passes no pathspecs to git.
- Fix: none left

### Two lanes' exception lines against one uncounted exception (sprint-size-six retro)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 101 of run-state-backlog-b
- Why: Gone, no code changed: evidence: no SPRINT_EXCEPTIONS at base or HEAD (grep); base queue_class classes each change named in an exception paragraph as outside.
- Fix: none left

### A carried review trusts a moved record written by the branch's own run_state.sh

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 102 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### moved carries when the merge keeps the change's side of a file main also edited

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 103 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### The merger reports the branch head as the merged commit

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 104 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base run_state.sh:4583-4588 phase merge merged records squash_of_change and notes merge-disagreement; base tools_test.sh:2538.
- Fix: none left

### The planner weighs quality-advisory notes the package step handled

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 105 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### The fold keeps a findings file's title as a second level-one heading

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 106 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base file_entries (base run_state.sh ~3394 "/^#+ / { flush(); if (/^##+ /) ...}") never files a "# " line; base tools_test.sh:1466 (backlog-move with "# Findings of x" title, _general.md holds no title).
- Fix: none left

### The fold adds headings with no blank line before them

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 107 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base file_entries prints "" before every filed heading; base tools_test.sh:1466 expects a blank line before "## Findings of z".
- Fix: none left

### The planner runs on a first queue item already placed and estimated (secret-patterns retrospective)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 108 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base plan_needed returns "not needed" for an estimated head with no pending note; base tools_test.sh:3353 "plan-needed takes the queue head as written".
- Fix: none left

### Budget line names the sprint key too narrowly

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 109 of run-state-backlog-b
- Why: Gone, no code changed: evidence: base budget_line (base run_state.sh ~2930) holds no sprint wording; tokens comment at base :2846 already says "sprint-planning's own".
- Fix: none left

### plan-needed skips the planner for a security note recorded after a later sprint plan (pipeline-diet security Low (3))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 110 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### reviewed-edits fails open when git diff fails (pipeline-diet quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 111 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Fold adds a level-one heading per findings file

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 112 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: same as 105: base file_entries drops "# " lines; base tools_test.sh:1466.
- Fix: none left

### Folded headings lack a blank line before them

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 113 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: same as 106; base tools_test.sh:1466.
- Fix: none left

### A lane's queue removal conflicts with a sprint-records rewrite of the queue (tab-close-d retro)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 114 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base merge_main resolves a queue-only conflict keeping the branch's own lane queue and main's other; base tools_test.sh:3343.
- Fix: none left

### The moved check reruns the reviews on a cleanly merged file and misses a hand-resolved one (tab-close-d retro)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 115 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Groom's fold keeps producing format defects the records run hand-fixes (sprint-16-records retro)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 116 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Groom's duplicate guard lets an unmarked security entry leave as a duplicate

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 117 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: b5b0aec (#214) widened SECURITY_MARK, base run_state.sh:636; base tools_test.sh:3036-3040 (Low finding of the periodic security review refused as gone, duplicate, merge).
- Fix: none left

### Groom's listed proof accepts a heading as a bare substring of the queue item (`groom-proof` security Low (5))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 118 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base item_lists bounded match (identical at HEAD :3838-3851); base tools_test.sh:2995 "groom refuses a listed heading that only prefixes a longer quoted one".
- Fix: none left

### Groom's duplicate guard lets a security entry without a `security <severity>` marker leave (`groom-proof` security Low (3))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 119 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: b5b0aec SECURITY_MARK covers "(critical/high/medium/low) (N)" pair and either order; base tools_test.sh:3051 critical pair case.
- Fix: none left

### Groom's listed proof still accepts a comma after an unquoted heading (`groom-proof` security Low (2))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 120 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Groom's guard against a `#` before a listed heading has no test (`groom-proof` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 121 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base tools_test.sh:2997 item "### t near miss," vs listed "## t near miss": before is "#", after is ",", so only the # guard refuses.
- Fix: none left

### exception_item now counts a wrapped `beyond the sprint` mark without a test (`groom-proof` quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 122 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Groom leaves references to the findings files it removes (sprint-17-records retro)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 123 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c. claim corrected: removed_refs rewrites only the findings file name and the backticked directory inside backlog files; groom copies plan queues unrewritten and files groomed.md without it
- Fix: see the item named

### The token weighting prices a mid-tier start at the cheap tier's price

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 124 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Groom's output fails the check's docs-lint stage on its own (sprint-18-records retro 11)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 125 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### settled_round repeats the RECORDS_RE filtering of other records filters (review-lite quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 126 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Two security entries stay open though #214 fixed them

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 127 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: same issue as 116 and 118 (the two entries); code fixed at base by b5b0aec, base tools_test.sh:3036-3051.
- Fix: none left

### SECURITY_MARK matches security and a severity word anywhere in a long entry (sprint-19 review quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 128 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Extra push allowed by push --pr-text without a blocked text review

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 129 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### The new --pr-text push kind accepts any commit, as long as a recorded (sprint-20 review security Low (3), run_state.sh:1330)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 130 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### HEADER names 24 columns (sprint-20 sweep quality, run_state.sh:484)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 131 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: line 1 of docs/metrics-feature.tsv and docs/metrics-backlog.tsv at ce04c85 has 24 columns; base tools_test.sh:2005.
- Fix: none left

### A check stage can forge its runner's job status files

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 132 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base stage_launch (base run_state.sh ~987) gets the status from wait, no job_dir or .status files at base.
- Fix: none left

### Shared state a check stage can still write without failing the check

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 133 of run-state-backlog-b
- Why: Not fixed: needs an operating-system sandbox: build/pipeline, build/stages, build/plan, and build/spinel-cache are written by the runner and by concurrent lanes, so the scan cannot separate a stage's write there.
- Fix: none; stays in the backlog

### The checker's own figures stay writable by a stage during a check

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 134 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 135 (same state_view filter, run_state.sh:1380-1385 unchanged); problem NOT_DONE.
- Fix: none left

### Correction: an edit of tools/run_state.sh by a stage is listed by the scan

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 135 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of the sprint-26 review note 3 entry (runner from a copy of HEAD's blob, claimed not fixed); check_wait run_state.sh:1762-1764 still runs "$here/run_state.sh"; NOT_DONE.
- Fix: none left

### The run-state comparison now leaves out every figure but the measurements (security Low (5), residual widened)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 136 of run-state-backlog-b
- Why: Not fixed: needs an operating-system sandbox: a log of the caller's writes would be a file the same stage can write, so it separates nothing.
- Fix: none; stays in the backlog

### Security: a stage's detached child can write after the escape scan (security Low (6), still present at package)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 137 of run-state-backlog-b
- Why: Fixed: each stage job runs in its own session (setsid) and its group is killed when the job ends, before the escape scan. Case "run_state: a process a stage leaves running does not outlive the check" fails at BASE (414eb5af5baa), passes at HEAD.
- Fix: none left

### Security: a stage can forge its own run state's metric lines during a check (security Low (6), still present at package)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 138 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 135 (identical root and fix); NOT_DONE.
- Fix: none left

### Security: a stage can plant notes and closing phases in its own run state during a check (security Low (6), still present at package)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 139 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 135 (state_view also drops note.* and CLOSE_PHASES, same caller-write log fix); NOT_DONE.
- Fix: none left

### The check-pass output budget line changed no decision

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 140 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of "The check-pass budget line projects 6 total tokens per output token" (claimed not fixed); OUTPUT_SHARE=6 run_state.sh:628 unchanged; NOT_DONE.
- Fix: none left

### An advisory-only fix round counts as rework and reruns every stage and review

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 141 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### review-due no longer bounds uncounted merges

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 142 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Security: a check leaves the remote-tracking refs unchecked, so a stage can forge origin/main for the next lane

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 143 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: lane-open starts a branch origin lacks from main, not from a planted remote-tracking ref" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### Security: a check's escape scan leaves the XDG global git configuration and the branch the main checkout's HEAD names out

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 144 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a stage that switches the main checkout to another branch at the same commit fails the check" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### Security: refs_view leaves refs/remotes/ out, and lane_open bases a new lane on a remote-tracking ref without fetching (security Low (5))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 145 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: lane-open starts a branch origin lacks from main, not from a planted remote-tracking ref" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### Quality: main_moved's ls-remote reaches the network with no prompt guard or time limit (quality advisory)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 146 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: the scan's ls-remote ends at its time limit" fails at 414eb5af5baa and ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### Security: a lane check accepts another lane's branch moved or its worktree files edited (security Low (6), reported three times, still present at package)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 147 of run-state-backlog-b
- Why: Not fixed: another lane's own commits move its branch and edit its worktree, so no scan can tell them from a stage's without a registry of lanes or an operating-system sandbox; the ref guard of the stage-made worktree entry closes only a worktree made outside tmp/.lane-.
- Fix: none; stays in the backlog

### Security: a stage-made worktree puts any local branch on the scan's skip list (security Low (6), reported twice, still present at package)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 148 of run-state-backlog-b
- Why: Fixed: refs_view skips a branch of a worktree seen only now when the branch is new since the mark and its worktree lies at a tmp/.lane- path (new_lane_branches), so a worktree a stage makes elsewhere hides no branch. Case "run_state: a stage that forges a branch through a worktree it adds outside tmp/.lane- fails the check" fails at BASE (414eb5af5baa), passes at HEAD.
- Fix: none left

### Security: stages run with the real HOME and the scan ignores its executed files (security Medium (6))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 149 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a stage that writes HOME's profile by an absolute path fails the check" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### Quality: a check between the merger's lane-close and branch deletion fails as the references changed

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 150 of run-state-backlog-b
- Why: Not fixed: the window is a lane opened and closed within one check; skipping its branch while no worktree names it would also skip a stage's forged new branch, which the fix of the stage-made worktree entry compares when its worktree is not at a tmp/.lane- path, so the two cannot both be closed without a registry of lanes.
- Fix: none; stays in the backlog

### Quality: a tracked path holding a tab, newline, quote, or backslash is reported as untracked

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 151 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a tracked path holding a tab is not reported as an untracked file" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### Findings of grep-long-files after its package step

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 152 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c. claim corrected: the earlier change's case for the blank line before an appended entry does not exercise it
- Fix: see the item named

### A concurrent lane's benchmark log fails another lane's check (pr-trust-lows check)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 153 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base: agent_guard.sh read profile with no DIR refuses any redirect outside build/stages; benchmark.md step 1 runs in the lane (#280, #315); base-figures save sends make output to /dev/null; metrics_out and last.tsv go to the lane (run_state.sh:4788, also at base). claim corrected: what held is the guard's refusal of a redirect outside build/stages and the lane rule of the benchmark agent, not a change of run_state.sh
- Fix: none left

### tools/run_state.sh:1143: [ -z "$HOME" ] under set -u (line 396) (sprint-22 review quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 154 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: a check with HOME unset still reads the references and fails on a forged one" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### history names the run state file as the lane file it appended to

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 155 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### plan-needed names only the first failing review while merged_since clears every one before the planner's time

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 156 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d. claim corrected: run_state.sh names every run in the needed line, but the workflow's planReview still captures only the first run, and the planner's prompt gets only that text
- Fix: see the item named

### A concurrent lane's benchmark log fails another lane's check

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 157 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: same as 152: guard refuses read-profile redirects outside build/stages; benchmark.md lane rule at base; HEAD main_scan reports every log (tools_test.sh:775). claim corrected: what held is the guard's refusal of a redirect outside build/stages, the benchmark agent's lane rule, and the scan reporting every log of the main checkout
- Fix: none left

### groom folds findings entries that still name the findings files it deletes (sprint-22-records retro note 4)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 158 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### PRUNE_ALL_SPRINT dead after the sprint-24 close at tools/run_state.sh:439

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 159 of run-state-backlog-b
- Why: Gone, no code changed: evidence: grep -c PRUNE_ALL_SPRINT: 0 at base and 0 at HEAD; removed by 01bee7b (#270) before the base.
- Fix: none left

### A lane's check fails on another lane's write into the main checkout's build/metrics

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 160 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base run_state.sh:4530 (HEAD :4788): metrics_out goes to tmp/.lane-CHANGE/build/metrics while the lane exists; last.tsv is dirname(metrics_out); test tools_test.sh:1335.
- Fix: none left

### A security review after a quality-only fix reads the whole branch again

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 161 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### plan-apply copies a planned goals.md after the security review

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 162 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### groom folds none/None placeholder lines from findings files

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 163 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### groom folds the none/None lines of findings files (sprint-23-records retro note 11)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 164 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 162; same fold_clean and test.
- Fix: none left

### named_history and named_since repeat the groom pathspec (sprint-24 review quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 165 of run-state-backlog-b
- Why: Gone, no code changed: evidence: grep -c named_history and named_since: 0 at base and 0 at HEAD (removed by 01bee7b #270); no git call repeats a backlog/findings/queue pathspec. claim corrected: the repeated pathspec functions were removed with the earlier sprint cleanup, not by the earlier change
- Fix: none left

### SPRINT_HEADER is never read (sprint-24 sweep quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 166 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### backlog-move's mismatch refusal has no test

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 167 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### A refused filing leaves the entries filed before it in the folder

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 168 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### plan-apply overwrote the lane queue with a plan older than the branch's queue

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 169 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### plan-apply copies a plan older than the branch's queue

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 170 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 168; same refusal, run_state.sh:2605.
- Fix: none left

### A change named only in a lane exception line resolves to the wrong lane (facet-design-doc retro note 16)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 171 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### Plan notes reach the findings file twice (facet-design-doc retro note 17)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 172 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### self_fix has no history column

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 173 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### An exception paragraph naming a change without backticks leaves it counted in the sprint

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 174 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### An exception paragraph naming a change without backticks leaves it counted

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 175 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 173; same readers, NOT_DONE.
- Fix: none left

### lane_of puts a docs change briefed to the feature lane in the backlog lane, so its history step writes a backlog file

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 176 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 170; fixed by the same item_named change, test tools_test.sh:3599.
- Fix: none left

### The escaped verdict lets any write under the main checkout's build/ through (security Medium (5))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 177 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base lane_written returns 1 when LANE_WRITTEN is empty (base run_state.sh:953, :534); base tests 779-787 (HEAD tools_test.sh:856).
- Fix: none left

### A write outside the check clone is detected but never reverted (security Low (4))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 178 of run-state-backlog-b
- Why: Fixed: escaped_revert removes a regular file or link a stage planted under the main checkout's build/ that LANE_WRITTEN does not name. Case "run_state: a log planted in the main checkout's build/ from a lane is removed by the voided check" fails at BASE (414eb5af5baa), passes at HEAD.
- Fix: none left

### The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 179 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base run_state.sh:4588 add_note merge-disagreement keeps main's commit (HEAD :4846); base test 2537-2538.
- Fix: none left

### The merger reported a merged commit that is not the squash commit on main (sprint-24-records note 13)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 180 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 178, identical text.
- Fix: none left

### backlog-move is a one-shot migration left in run_state.sh (sprint-25 review quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 181 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### In this sprint's diff (contributor-self-check). The checker now skips at tools/run_state.sh:1077 (sprint-26 review security Low (3), note 3)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 182 of run-state-backlog-b
- Why: Not fixed: the runner is the branch's own script by design, its pass re-run by the checker and the merge gates from main's script; a copy of HEAD's blob is the same code, so it closes nothing without a sandbox.
- Fix: none; stays in the backlog

### duplication: backed_commit and check_stages (1082) each read phase.check and at tools/run_state.sh:681 (sprint-26 review quality, note 11)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 183 of run-state-backlog-b
- Why: Not fixed: a refactor that moves no behavior, so no case can fail at the base; the structural case at HEAD is a grep of the script and does not count.
- Fix: none; stays in the backlog

### the runner refuses a dirty tracked tree with its at tools/run_state.sh:1204 (sprint-26 sweep quality, note 13)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 184 of run-state-backlog-b
- Why: Not fixed: a refactor that moves no behavior, so no case can fail at the base; the structural case at HEAD is a grep of the script and does not count.
- Fix: none; stays in the backlog

### The planner's sprint queues reach a records change failing the docs-lint queue check (sprint-26-records retro note 4)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 185 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Head-form notes record a head git confirms (folded-row retro note 4, notes 1 and 5)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 186 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 187 of run-state-backlog-b
- Why: Gone, no code changed: evidence: the set-apart figure was removed by 28cb72f (#312) before the base; budget_line prints only metric.total_tokens.
- Fix: none left

### The budget line clips a records run's own tokens at zero (merge-gate-lows retro note 2)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 188 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of 186, identical text.
- Fix: none left

### tools/run_state.sh groom: security entries removed without a named fixing commit

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 189 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base groom refuses gone and duplicate for a security entry; only listed (a merged item) or fixed (a commit in the sprint range) remove one (base run_state.sh:3822).
- Fix: none left

### The check-pass output-token note fires in runs that end under the total budget (ui-groups retro note 3)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 190 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of the entry "The check-pass budget line projects 6 total tokens per output token" (outside this batch), which is NOT_DONE: OUTPUT_SHARE=6 is unchanged at run_state.sh:628.
- Fix: none left

### A records check is voided by build/dev/carat.timing escaping the check clone (sprint-27-records note 1)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 191 of run-state-backlog-b
- Why: Already fixed at the base, shown by a case that passes at both: "run_state: a stage writing build/dev/carat.timing in its clone leaves the check passing" (passes at BASE and at HEAD, so it cannot fail red); no code changed. claim corrected: the earlier change claimed no code change was needed without a case; stages run in a throwaway clone with its own build/, so the timing file stays there, now shown by a case that passes at the base
- Fix: none left

### A check is voided as escaped for a file the dev-build stage is declared to write (sprint-27-records note 1, security-escape)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 192 of run-state-backlog-b
- Why: Already fixed at the base, shown by a case that passes at both: "run_state: a stage writing build/dev/carat.timing in its clone leaves the check passing" (passes at BASE and at HEAD, so it cannot fail red); no code changed. claim corrected: as for the entry above, shown by a case that passes at the base and at the head
- Fix: none left

### A carrying delivery that never merges strands the sprint plan

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 193 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### groom-proof checks a carrier's plan line against evidence the carrier controls

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 194 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### groom's fixed proof takes a commit of the carrying branch (sprint-29 review security Low (4))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 195 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### groom and groom_proof copy the fixed proof (sprint-29 review quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 196 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### Stored figures of main trust the saving lane's measuring script

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 197 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: base base_figures save requires tmp/.base at origin/main with clean tracked files and runs tmp/.base/tools/metrics.sh, main's own script.
- Fix: none left

### The in-run budget line prices total tokens at 6 per output token (lsp-container-b retro note 13, sprint-security retro note 8)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 198 of run-state-backlog-b
- Why: Duplicate, no code changed: evidence: of the entry "The check-pass budget line projects 6 total tokens per output token", NOT_DONE (OUTPUT_SHARE=6 at run_state.sh:628).
- Fix: none left

### groom_row's untracked sprint marker (sprint-14 review security Low (3) and quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 199 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-c.
- Fix: see the item named

### base-figures save checks only tracked files and untracked makefiles at tools/run_state.sh:2069 (sprint-30 sweep security Low (3), note 2)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 200 of run-state-backlog-b
- Why: Fixed by the earlier change, now proved by behavior: case "run_state: base-figures save refuses an untracked source file in the base" fails at ce04c85 (the commit before it), passes at HEAD.
- Fix: none left

### merge_main pins only some of its git calls at tools/run_state.sh:4370 (sprint-31 review quality)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 201 of run-state-backlog-b
- Why: Already fixed, no code changed: evidence: at base only the fetch is pinned and the header says so (e8b9c6e #334 moved merge-main back to plain git); same at HEAD; test tools_test.sh:3495.
- Fix: none left

### Overrun notes repeat within a run (explorer-rows retro 14)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 202 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-d.
- Fix: see the item named

### The escape scan's changed-path list reaches the terminal unfiltered (Low)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 203 of run-state-backlog-b
- Why: Fixed: the escaped-path list is printed through visible_text. Case "run_state: the escaped-path list holds no escape byte" fails at BASE (414eb5af5baa), passes at HEAD.
- Fix: none left

### lane-open leaves a real directory at a shared-state path unchecked at tools/run_state.sh:4354 (sprint-32 security Low (4))

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 204 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### merge_main aborts a conflicted merge and then tells the contributor at tools/run_state.sh:4430 (sprint-32 sweep quality, note 14)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 205 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### merge_main repeats the identity and message flags (-c user.name=Claude -c at tools/run_state.sh:4403 (sprint-32 sweep quality, note 53)

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 206 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### merge_main runs git with the global configuration and hooks again

- Location: tools/run_state.sh and its cases in tools/tools_test.sh; work list line 207 of run-state-backlog-b
- Why: Not fixed here: queued to run-state-backlog-e.
- Fix: see the item named

### Two writers can both retake a stale run state lock (quality advisory)

- Location: tools/run_state.sh, state_lock
- Why: two processes that both read a lock whose owner is gone can each remove it and create their own, so both rewrite the run state at once; the window needs a killed writer and two live writers at the same moment.
- Fix: take a stale lock over with an atomic rename of the lock file to a name holding the taker's pid, so only one rename succeeds.

### The removal of a planted file may delete a concurrent lane's build file (quality advisory)

- Location: tools/run_state.sh, escaped_revert
- Why: a regular file or link under the main checkout's build/ that a concurrent lane wrote and no LANE_WRITTEN path names is removed with the stage's planted ones; it is a build output the lane rewrites, and its own check is void for the same write.
- Fix: record the files a lane's own tools write under the main checkout's build/ in LANE_WRITTEN by default, so only an unexplained file is removed.

### A stage that starts its own session leaves the group kill (quality advisory)

- Location: tools/run_state.sh, stage_launch
- Why: the job's group is killed when the job ends, but a process a stage moves into a session of its own with setsid is no longer in it and can still write after the escape scan.
- Fix: needs an operating-system sandbox or a cgroup per check; no shell-level fix closes it.

### Review round: the four security Lows are fixed (security Low (5) runner_group_stop, Low (4) escaped_revert, Low (5) new_lane_branches, Low (3) state_lock)
- Location: tools/run_state.sh valid_pid, runner_group_stop, check_wait, read_pid, escaped_revert, main_scan_raw, new_lane_branches, state_lock; tasks 7.1 to 7.4. They supersede the quality-review notes recorded earlier in this file on the stale lock takeover and on the removal of a planted file.
- Why: fixed with a case each, failing with the earlier tools/run_state.sh and passing at the head: "a pid file naming pid 0 does not make the check signal its own process group" (fails at BASE, passes at HEAD), "a planted name holding a newline lists as one removal", "a planted name whose second line names a file leaves that file" and "the voided check lists the file it removed in the check log" (fail at BASE, pass at HEAD), "a stage that forges a branch through a worktree at another checkout's tmp/.lane-NAME fails the check" (fails at BASE, passes at HEAD), and "a waiter does not take a lock a live process retook after it read the dead owner" (fails at BASE, passes at HEAD).
- Fix: none left for these four; the parts the findings called optional stay open. A pid naming a real orphaned group of another program is still signalled when the leader is gone (the optional check that the members run check-run or make is not made, since a runner's make children are recognised by no stable name); the cd -P and change-time conditions of the removal have no case, since find does not descend a link and a file's change time already passes the scan that named it, so they are defence in depth; a lock moved aside by mistake is linked back, so two processes retaking the lock in the same instant remain a fail-closed window of microseconds.

### Closed in the review round: state_lock's takeover window (security Low (2))

- Location: tools/run_state.sh, state_lock, state_unlock, state_rewrite.
- Outcome: fixed. The lock is a directory made with mkdir holding a pid file; a stale one is renamed aside, its owner checked again, and made again when live; release and the rewrite's rename need the pid file to name this process.
- Cases: "run_state: a writer that lost its lock to a third writer refuses and writes nothing", "the writer that lost its lock leaves the third writer's lock", "the lock a waiter moved aside and found live is back with its owner", and the take-over and refusal cases now on the lock directory: each fails at 1e292a28bef5 and passes at the head.
- Residual: a third writer making the lock in the microseconds between the moved-aside check and the make-again displaces the live owner, which then refuses its write (fails closed) and retries; the entry "Two writers can both retake a stale run state lock" above is closed by this fix.
