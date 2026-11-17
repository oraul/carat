# Design

## Context

`sprint-planning.js` reviews a sprint's combined diff (security, quality), runs the whole-tree sweep (`periodic-review.js`, run state `sprint-N-sweep`) in an even sprint, has the skeptic record findings, starts the planner, records the review results, and delivers `sprint-N-records`, whose `groom` applies the plan. `tools/run_state.sh`'s `sprint_reviewed` gates `groom` and `review-due` on `review.periodic-security` of `sprint-N`.

## Decisions

- The gate stays in one function. `sprint_reviewed` gains the sweep check, so `groom` and `review-due` refuse alike. The sweep's word may be pass, blocked, or partial; none or `not-run` refuses, `sprint_security` then reading `sweep <word or none>` for groom's message. The sweep sprint is the even one, the same rule `review-due` prints `sweep: yes` by.
- A sweep that failed to start is recorded as `not-run` in its own run state by the Record step, so the run state says why, never only the log; a sweep that returned writes its own record.
- The workflow, not an agent, writes each security finding: a Notes start right after the reviews runs one `note` per finding before the skeptic, so a capped skeptic loses no finding, and the planner reads them. Its text is the finding line the skeptic got, every control character a space, quoted as one single-quoted shell word (`shellWord`), since the record start runs it through Bash. A Notes start that fails leaves the review incomplete: no planner.
- The planner's condition becomes `ran && !missed && noted && skeptical && swept`: a plan `groom` would only hold is not written, and the report's Plan line already says the review did not complete.
- The report's Security line comes from `securityLine`, which names a partial review with its count of files left, the first few named, and asks for `/sprint` again.

## Risks

- A sweep that never starts holds an even sprint until `/sprint` succeeds once; that is the intent (the review is never skipped).
