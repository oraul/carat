# Design

## Context

`.claude/workflows/deliver-change.js` runs `verify(false)` on a resume past the push (a start that did not run the check and every review itself); `rounds(false)` stops on any blocked result with "blocked at HEAD on resume, where no fix can be pushed", because `tools/run_state.sh push` allows one push plus one per CI fix and `tools/gates.sh` `pushes` refuses more at the merge. `init` writes a fresh state when none exists and resumes otherwise, reading neither the lane histories nor `merged`. The contributor's implement steps keep the docs current and confirm the delta spec scenarios but carry no self-check against the brief; the planner has no rule about the merge gate's own rules.

## Decisions

- `resumeFix(by, used)`, a pure helper in the workflow, decides a blocked resume: '' (one fix round) only when the reviews blocked (`by` is `review`) and no review fix was used (`used`, the run state's `review_fixes` plus the rounds this start began); otherwise the reason the run stops. `rounds` records which step blocked (`check`, `review`, `bench`) and asks it only when `fixes` is false; the fix round still counts against `mayFix`.
- The round's re-check and reviews run through the same loop. `priorSecurity` returns no narrowed scope while a review fix round runs, so the security review covers the whole branch diff again; the quality review keeps its usual scope rules.
- After `verify(false)` passes with a review fix round begun, the merge block starts the contributor's `push` mode asking for `--review-fix`, then goes on to the merger at the new pushed head, which `keepPushed` keeps since `push` is a pushing mode.
- `run_state.sh push --review-fix`: needs a recorded `pushed` that is not HEAD and `review_fixes` 0; it allows one more push and writes `review_fixes` 1. The reviews pass again before the push, so a blocked review record cannot be its condition; the once-per-run count and the merge gates' records at the pushed head are.
- `gates.sh` `pushes` allows `1 + ci_fixes + review_fixes` pushes and fails a `review_fixes` above 1. This run's own merge is judged by main's `gates.sh`, which lacks the review fix, so this run never uses it.
- `init` refuses when the branch is not `main` and the change already merged: the run state's `merged` is a commit (`merged_commit`), or a lane history row names it (`has_row`). An unmerged run state resumes as before. The deliver workflow's resume prompt says to stop on the refusal and return its message. A branch of `main` marks the sprint and review run states, which set `merged` right after their `init` and may run `init` again on a resume.
- Budgets: CLAUDE.md, `contributor.md`, and `planner.md` sit within 5 to 16 bytes of their budgets; the new rules are made room for by shortening existing sentences, never by raising a budget.

## Risks

- A run merged but whose close did not finish can no longer be resumed by `/deliver` under the same name; its records stay in the run state and the next package step's `history` adds its row.
- The once-per-run limit is the run state's `review_fixes`, which `set` can rewrite like `pushes`; the merge gate and the security review at the pushed head stay the guard.
