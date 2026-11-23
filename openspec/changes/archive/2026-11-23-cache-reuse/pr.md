chore(pipeline): store main's figures once and carry a passed check

## Summary

Stores main's benchmark figures once per merge and carries a check that already passed at the head, so the benchmark and checker starts stop repeating work the run state holds. The user asked for the pipeline to use its caches more, after runs spent over a hundred thousand output tokens rebuilding main and tens of thousands re-running a check whose stages were all recorded passing.

---

## Changes

- Add run_state.sh base-figures, which stores main's figures in build/pipeline/main-figures.tsv keyed by main's commit, builds main only when none are stored for its current commit, and measures them with main's own script on save.
- Change run_state.sh bench to compare with the stored figures first, exiting 0 without a benchmark agent when allocations and rounds do not exceed main's and 1 as a regression otherwise, and to fall back to the recorded figures when none are stored.
- Add run_state.sh carried, which reports that every stage of make stages holds a pass record at the head, with the spent line and the benchmark comparison the checker would return, and otherwise says why not and exits 1.
- Change the delivery workflow's check round to ask a runner start for carried when the contributor's pass at the head is the backing, to record the check itself from the result and start no checker, and to start the checker as before on any other result.
- Change the benchmark agent to read the stored figures, to build the base only when none are stored, and to time the release build only when the brief states a time target.
- Add the carried form to the runner profile and the base-figures form to the read profile of tools/agent_guard.sh.
- Add tools-test cases for stored figures, the bench comparison against them, the carried command, its guard forms, and the workflow's carry helpers, including a planted makefile refused by the base build.
- Document both commands in the header of tools/run_state.sh, README.md, and CLAUDE.md, tightening existing CLAUDE.md prose to stay inside the docs-lint budget, which is not raised.
- Apply the waiting plan carried by this delivery, the backlog queue and the lane's metrics history row, and archive the cache-reuse change with skip_specs since no spec changes.

---

## Testing

- Security review of the committed diff at the reviewed head, pass with no High, Medium, or Low findings.
- Benchmark review at the reviewed head, pass with no blocking findings.
- Check of the stages dev-build, test-build, test-run, diagnose, bench-budget, tools-test, gates, docs-lint, and metrics at the head, all passed.
- Run make spec-validate after the archive, 56 passed and 0 failed.
- Run make gates and make docs-lint at the packaged head, all checks ok.

---

## Notes

The pull request text check folded into the package start and the stable-prefix ordering of agent prompts, parts three and four of the brief, are left for the planned follow-up change cache-reuse-b. No edit of tools/rules.sh. The carry accepts the trust the existing backing already has, the contributor's own check at the head, and diagnose still reruns unless scoped out.
