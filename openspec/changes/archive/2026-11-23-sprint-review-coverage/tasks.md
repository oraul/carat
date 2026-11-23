# Tasks

## 1. The continued quality review

- [x] 1.1 Add `mergeQuality`, `qualityLine`, and the QUALITY schema, and start the quality reviewer over the files the planner's review left (`.claude/workflows/sprint-planning.js`); record partial while files remain and join the continued notes; proved by the sprint-close cases in `tools/tools_test.sh`
- [x] 1.2 Add the Sprint mode of `.claude/agents/quality-reviewer.md` and the planner's `not_reviewed` sentence (`.claude/agents/planner.md`)

## 2. Tests and docs

- [x] 2.1 Add the whole-sprint-close cases and the merge case, and update the cases that counted quality-reviewer starts and the planner's wording (`tools/tools_test.sh`)
- [x] 2.2 Update CLAUDE.md and README.md

## Quality review

- [x] 3.1 The continued review's findings arrive after the planner wrote the queue, so they do not shape this sprint's queue; recorded in `docs/findings/sprint-review-coverage.md`, recorded
- [x] 3.2 `.claude/agents/planner.md` sits at its byte budget, so the sentence "a dropped one is not recorded" and two wordings were shortened (the schema description and CLAUDE.md keep the rule); recorded in `docs/findings/sprint-review-coverage.md`, recorded
- [x] 3.3 The continued start's files come from the planner's result and are written into the prompt as the security continuation's are; the quality reviewer runs under the read guard, recorded in `docs/findings/sprint-review-coverage.md`, recorded
