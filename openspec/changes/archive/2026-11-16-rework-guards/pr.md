chore(pipeline): add the resume review fix round and the rework guards

## Summary

Cuts the delivery pipeline's rework: the contributor self-checks tests and documents before review, a resume past the push that meets a blocking quality or security review runs one fix round and pushes it once more instead of stopping, the planner lands merge gate rule edits first, and init refuses a delivery whose change name already merged. Over the last 41 deliveries the quality review failed the first pass 14 times, mostly on missing tests and stale documents, and three post-push defects each turned a nearly finished change into a redelivery.

---

## Changes

- Add the resume review fix round to the deliver workflow: the contributor fixes the blocking review, the check and both reviews rerun with the security review over the whole branch diff, and the contributor pushes with run_state.sh push --review-fix, once a run, a resume finding an unpushed fix commit pushing it from the run state.
- Add the push --review-fix form to tools/run_state.sh, needing a recorded push and a different head and counting review_fixes, allow it in tools/agent_guard.sh's contributor push form, and let the gates.sh pushes gate accept one review fix beyond one push plus one per CI fix.
- Change run_state.sh init to refuse a delivery branch whose change name already merged, by a lane history row or a merged run state the close recorded, while a merged run whose close has not run still resumes and sprint and review run states at main are untouched.
- Add the contributor's pre-review self-check to .claude/agents/contributor.md and the workflow's implement and fix prompts.
- Add the planner rule that a change editing the merge gate's own rules lands that rule edit first as its own small change.
- Add tools-test cases for the review fix round, its push and its refusal, the guard's push forms, the merged-name refusal and the unclosed merged resume, and make the CLAUDE.md budget case faster.
- Document the four rules in CLAUDE.md's Agents section and the README's pipeline section, shortening other CLAUDE.md lines to stay within its budget.
- Apply the user's Sprint 10 queue decisions to docs/queue-backlog.md and docs/queue-feature.md: exception lines for rework-guards, backlog-lane-b, and parallel-lanes, lsp-incremental-sync and markdown-reading-b as the numbered items, the S11 moves, and resume-fix-round and merged-name-guard absorbed.
- Record the planner's queue, the last metrics row, and this change's late review findings in docs/findings/rework-guards.md.

---

## Testing

- Run the security review of the committed diff at 798e59d128a6, pass with no high, medium, or low finding.
- Run the quality review at 798e59d128a6, pass with no blocking finding and three advisories, and the benchmark review, pass.
- Run the checker's stages at 798e59d128a6 (docs-lint, dev-build, test-build, test-run, diagnose, bench-budget, metrics, tools-test, gates), all pass.
- Run make spec-validate after the archive, 53 passed and 0 failed.
- Run make gates and make docs-lint after packaging, both pass.

---

## Notes

No spec under openspec/specs describes the delivery pipeline, so the change is archived with skip_specs. This run never uses the review fix push itself, since main's gates judge it. The late quality advisories left open (the review fix round counted only when pushed, the ignored push result, an unpushed CI fix pushable as the review fix, narrowing turned off after the fix round, the unchecked blocked review on push --review-fix, and docs currency in the init usage line, the archived proposal, and task 1.3) are recorded in docs/findings/rework-guards.md for the sprint grooming. CLAUDE.md is 9 bytes under its budget, so the next addition should move detail to the notes it points to.
