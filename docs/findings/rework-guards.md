### The agent guard refuses the review fix push
- Location: tools/agent_guard.sh:601 (run_state_form, contributor push case), called by .claude/workflows/deliver-change.js:1156
- Why: security Low at confidence 9. The contributor push form allows only CHANGE [--ci-fix], so the push with --review-fix the workflow asks for is always refused. It fails closed and is not an exploit, but a resume past the push that uses its one review fix round stops at the push, so the new path can never complete.
- Fix: Extend run_state_form's contributor push case to also accept --review-fix as the third argument, still matching CHANGE_NAME, and add a tools_test case that runs the push through the guard with --review-fix.

### The one review fix round a run counts only pushed rounds
- Location: .claude/workflows/deliver-change.js:966 and 978 (resumeFix), tools/run_state.sh push (writes review_fixes)
- Why: review_fixes is written only by the push, so a round that began and stopped unpushed lets a later start begin another, against the proposal's rule that a second round, in the same start or a later one, is refused.
- Fix: Record the round in the run state when it begins (a review_fix_round key) and count it in resumeFix.

### The review fix push result is ignored
- Location: .claude/workflows/deliver-change.js:1156 and 1172
- Why: The result of the review fix contributor('push') is not checked, so a refused or failed push surfaces only as the pushedHead mismatch stop and its reason is lost.
- Fix: If the push start returns false, keep the stop the contributor set or set stopped with the push's reason, as the CI fix path at line 1217 breaks.

### A review fix round turns off review narrowing for the rest of the start
- Location: .claude/workflows/deliver-change.js:798 (priorSecurity)
- Why: Performance: once reviewFixRounds is above zero, every later CI fix round after the review fix push re-reviews the whole branch diff, costing tokens and time.
- Fix: Drop narrowing only for the review fix round's own reviews, for example remember the head the round began at and narrow from passes after it.

### A resume pushes an unpushed CI fix as the review fix
- Location: .claude/workflows/deliver-change.js:909 (resumePush)
- Why: resumePush pushes any head past the recorded push as the review fix, so an unpushed CI fix commit, from a start stopped between the CI fix commit and its --ci-fix push, is pushed with --review-fix: ci_fixes is not counted and the run's one review fix is spent, so a later blocking review on resume is refused.
- Fix: Push with --ci-fix when CI is recorded red and keep --review-fix for a blocked review only, or name the case in the comment and the README.

### push --review-fix does not check that a review blocked
- Location: tools/run_state.sh:931 (push, the --review-fix case)
- Why: The review fix push checks only that the recorded push differs from HEAD, not that a review blocked, so any caller gets one extra push beyond the push-once rule.
- Fix: Require a blocked review.quality or review.security record at the pushed head before allowing the --review-fix push, with a tools_test case refusing it otherwise.

### SELF_CHECK repeats the contributor's implement step 5
- Location: .claude/workflows/deliver-change.js:684 (SELF_CHECK), .claude/agents/contributor.md implement step 5
- Why: Every implement and fix prompt carries the same rule twice, and the two texts can drift apart.
- Fix: Keep the rule in the agent file and have the prompt point to step 5, or drop step 5's copy.

### CLAUDE.md sits 9 bytes under its docs budget
- Location: CLAUDE.md:1 (tools/docs_lint.sh budget of 30720 bytes)
- Why: CLAUDE.md is 30711 of its 30720 bytes after rework-guards trimmed unrelated lines (the hotfix and release branch examples, the Stack PATH note) to fit, so the next addition fails docs-lint.
- Fix: Move detail to the notes docs CLAUDE.md already points to rather than trimming more examples.

### The init usage line still says it refuses any merged run
- Location: tools/run_state.sh:59 (header usage of init)
- Why: Docs currency: the usage line says init refuses a CHANGE with merged recorded, but init now resumes a merged run without phase.retro.
- Fix: Say it refuses a merged run the close recorded (phase.retro) or one with a lane history row.

### The archived proposal omits init's merged-run exception
- Location: openspec/changes/archive/2026-11-16-rework-guards/proposal.md:12
- Why: Docs currency: the proposal says init refuses any run state with merged set, while the design and the code resume a merged run the close has not closed.
- Fix: Add that exception to the proposal's sentence.

### Task 1.3 names a test no case carries
- Location: openspec/changes/archive/2026-11-16-rework-guards/tasks.md:7
- Why: Task 1.3 names the test "workflow: the review fix round pushes once more", which no tools_test.sh case carries; the push is proved by "workflow: a passed resume pushes a head past the recorded push as the review fix".
- Fix: Name the existing test in the task.
