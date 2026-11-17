### The package step applies review advisories to reviewed files and the push is refused (markdown-reading-d retro)
- Location: `.claude/agents/contributor.md` package step; `.claude/workflows/deliver-change.js` package phase
- Why: markdown-reading-d's packaging contributor applied an advisory that reworded a reviewed comment and its code map line, the pre-push gates refused the push twice (gates_failed 2), and both files were put back in new commits, still claiming one marker scan; package took 22 calls against a last-10 feature median of 15.5, 3 of 3 advisories the cause. For `review-demotion`.
- Fix: an advisory whose fix touches a reviewed file goes to the findings file or a fix round, never a package edit; accepted when over the next 5 deliveries with advisories no package-phase push is refused (gates_failed 0).

### The checker agent costs far more than the verdict of run_state.sh check (markdown-reading-d retro)
- Location: `.claude/agents/checker.md`; `.claude/workflows/deliver-change.js` check phase
- Why: markdown-reading-d's check took 35,360 output tokens in 4 calls, 13.0% of the run's 272,795 output, for a verdict the script gives; first-pass check 136 of 138; ux-fixes-a 22,463 and palette-narrow 40,656 also over 20,000 on a first pass against a last-10 median of 6,425. For `check-skip`.
- Fix: run the check script from the workflow without an agent, or cap the agent; accepted when over the next 5 deliveries a first-pass check costs at most 5,000 output tokens and 4 calls, the stage records and first.check unchanged.
