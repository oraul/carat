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

### The merged resume path is unreachable after init refuses merged names
- Location: tools/run_state.sh:2073 (init), .claude/workflows/deliver-change.js:1135 to 1147 (the comment on a restart after the merge), the !state.merged guards near 1061, 1090, and 1092, and the looking retrospective near 1234 to 1250
- Why: init now refuses a run state with merged set on a delivery branch, so the workflow's merged-resume handling can no longer be reached by /deliver, and a merged run whose close died never gets its retrospective.
- Fix: Let init resume a merged run state whose phase.retro is unset, or remove the dead guards and the stale comment.

### A review fix round turns off review narrowing for the rest of the start
- Location: .claude/workflows/deliver-change.js:798 (priorSecurity)
- Why: Performance: once reviewFixRounds is above zero, every later CI fix round after the review fix push re-reviews the whole branch diff, costing tokens and time.
- Fix: Drop narrowing only for the review fix round's own reviews, for example remember the head the round began at and narrow from passes after it.

### A resume pushes an unpushed CI fix as the review fix
- Location: .claude/workflows/deliver-change.js:909 (resumePush)
- Why: resumePush pushes any head past the recorded push as the review fix, so an unpushed CI fix commit, from a start stopped between the CI fix commit and its --ci-fix push, is pushed with --review-fix: ci_fixes is not counted and the run's one review fix is spent, so a later blocking review on resume is refused.
- Fix: Push with --ci-fix when CI is recorded red and keep --review-fix for a blocked review only, or name the case in the comment and the README.
