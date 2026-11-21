# Design

## Context

`reviews()` in `.claude/workflows/deliver-change.js` ran the quality and security reviewers in parallel at one commit, with the quality side's scope (`priorQuality`, `scope`), re-raise and first-pass-miss split (`qualitySplit`), advisories (`qualityAdvisory`), blocking rounds (`blockingQualityRounds`, escalation at two), carry over a moved main (`carryFrom`), and its place in the merge records (`ranAll`, `mergeRecords`) and in `tools/gates.sh`'s `passed` gate. The contributor's card rule 10 asked only for a re-read of the diff.

## Decisions

- The quality step is the contributor's, in the implement start that finishes the tasks: review the whole committed diff with the quality reviewer's instructions, a task per finding under `## Quality review` in `tasks.md`, fixed in the same session, a finding not fixed appended to the findings file with its reason; then archive. The guidance lives in `openspec/config.yaml` (`operations.apply.guidance`, `operations.archive.guidance`) and in the agent file's implement step and card rule 10, which `CONTRIBUTOR_CARD` repeats word for word.
- The result field `quality_review` is `{ status: 'done', added, fixed, recorded }`, the counts integers with `fixed + recorded = added`. `qualityReviewProblem(result)` names what is wrong; `contributor()` treats it like a refused head for an implement start's done result (noted `quality-refused`, escalated, restarted once, then stopped). A good one is kept as `metric.quality_review=ADDED/FIXED/RECORDED`, so a resume reads it back.
- `readyToPackage()` first runs `qualityStep()`: with no quality review recorded (a resume, a run started before this change) one implement start is asked for the step alone, then the check and the security review run on its commit as before. So the archive and package step never runs without one.
- The reviews are the security review alone: `reviews()` keeps its security block unchanged; the quality helpers, the blocked-file scope that only fed the quality review's scope, and the `quality_blocked` figure go. Fix in place, the closing loop, and the advisory-only round stay, fed by the security findings (the closing loop by the non-blocking ones the run keeps); a settled round now runs no review.
- The pull request text check stays: the same agent file, labelled `quality-reviewer: pull request text`, on `calibrate('quality')`, its cap `prtext`. `CALL_CAPS.quality` goes, so the quality reviewer's `maxTurns` (58) is now set by the sprint review's cap of 53 plus the margin, which tools-test checks.
- `tools/gates.sh` `passed` requires check, security, and bench. Main's copy judges each merge, so this change's own merge still needs its quality pass, which its run, under the old workflow, records.
- The run state keeps `quality` among its phases, gates, and review kinds, so older run states and the periodic and sprint reviews stay readable; no delivery records it now.
- No delta specs: `skip_specs: true`, archived with `--skip-specs`.

## Risks

The independent per-change quality check is gone; a bug the contributor's own review misses reaches main and is found by the sprint review or a later change. The user accepted that for the shorter loop; the security review still blocks every delivery.
