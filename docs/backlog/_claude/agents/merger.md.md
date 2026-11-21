# Backlog: .claude/agents/merger.md

## delivery-speed quality advisory at .claude/agents/merger.md:24

- Where: `.claude/agents/merger.md:24`. Delivery review of `delivery-speed` (quality advisory) at 2dcfd3d.
- Why it matters: checks has two formats, name, status, conclusion for every run and name: status, conclusion for pending, while staleRed splits on commas only.
- Fix outline: one format for every result.
- Category: pipeline
- Added: 2026-11-11

### The merge phase's output on a green first-pass CI varies fivefold
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js` (palette-narrow note 3, check-parallel note 8).
- Why: palette-narrow's merge took 69,031 of 304,750 output tokens (22.7%) in 11 calls with ci:1 and 4 CI wait calls; check-parallel's 22,685 in 11 calls; of the last 20 lane rows 19 passed CI first, 6 of them over 10,000 (up to 39,463) against a median near 7,100.
- Fix: make one CI wait and one merge cost about the same each run; accepted when the merge phase stays under 8,000 output tokens in 4 of the next 5 runs whose CI passes first.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

### The merger returns pending before its 30-minute CI wait ends (lsp-container-c retro)
- Location: `.claude/agents/merger.md` step 2; `.claude/workflows/deliver-change.js` merge phase
- Why: lsp-container-c's merger returned pending after 3 and then 0 of 30 minutes while CI was in progress, so the workflow started it three times on a CI that passed first time: merge took 30 of 119 calls (25.2%) and 12,961 output tokens, against a median of 12 merge calls over the last 10 feature rows. For `merge-gate-integrity`.
- Fix: the merger waits the full 30 minutes on a queued or running check before returning pending; accepted when over the next 5 runs no note reports an early pending return and merge stays at or under 15 calls on a first-pass green CI.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

### The merge phase's output tokens vary 14-fold on a first-pass green CI
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js`
- Why: its only decision on a green CI is to merge, yet tab-close-c spent 52,904 output tokens in 11 calls (17.6% of 300,034), against vim-line-commands-a 4,992 and tab-close 5,808 at 11 calls; palette-narrow 69,031.
- Fix: accepted when over the next 5 runs with first.ci=1 the merge phase stays under 10,000 output tokens.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-17

### The merger reports the branch head instead of the squash commit (vim-line-commands-b retro)
- Location: `.claude/agents/merger.md`, the merge phase of `.claude/workflows/deliver-change.js`
- Why: vim-line-commands-b's merger reported f230c3210a53 as the merged commit while main's squash commit was 25604e0ec359 (its merge-disagreement note 9), after record-squash-commit merged; the workflow's check recorded the right commit, so only the cross-check stands between a wrong head and the history's merged column.
- Fix: the merger reads the merged commit from the pull request's merge commit field (or main's first-parent commit naming the pull request number); accepted when a tools-test case or the next 3 merges record no merge-disagreement note.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-18

### The merge phase's output tokens do not follow its fixed work (vim-folds-b retro 5, extends merge-output-cap)
- Location: `.claude/agents/merger.md`, `.claude/workflows/deliver-change.js` (merge phase)
- Why: vim-folds-b's first-pass green CI with 2 waits, no main move, and no refusal cost 98,694 output tokens over 10 calls (9,869 per call), 25.6 percent of the run's 385,471 output, after pipeline-diet (#202) capped the merger's calls but not its tokens; last-ten feature merges 4,992 to 60,874 (median about 13,500), backlog about 12,000; the same problem as pipeline-diet retro 7 (39,483 on 10 calls), queued as `merge-output-cap`.
- Fix: merge into `merge-output-cap`; accepted when, over the next 5 runs with a first-pass green CI and no main move, the merge phase stays within twice the twenty-row median of its output and under 10 percent of the run's output, the green line, squash check, and merged record unchanged.
- Also: .claude/workflows/deliver-change.js
- Category: pipeline
- Added: 2026-11-18

### The agents' frontmatter hooks did not judge the workflow's tool calls
- Location: .claude/agents/merger.md and .claude/agents/contributor.md frontmatter `hooks:` (PreToolUse, tools/agent_guard.sh); .claude/workflows/deliver-change.js agent starts
- Why: the merger's merge calls of #234, #235, and #236 passed `expectedHeadSha` and, for #234 and #236, a one-paragraph `commit_message`; main's guard of that time refuses both (no `sha` key, a message other than pr.md's body), yet GitHub merged each, and in the merge-body-sections contributor start Bash commands holding `$` ran though the guard refuses `$` in any form. The allowlist, the merge-head check, and the squash message check are not in force for workflow-started agents, a security control the CLAUDE.md agents section relies on.
- Fix: find why the harness does not apply agent frontmatter hooks to the workflow's agent starts (agentType starts in deliver-change.js); apply the guard through a mechanism the harness honors (for example project settings hooks keyed by agent, or a workflow-side check of each tool call), and add a check the workflow runs at each start that a refused probe command is refused, stopping the run when it is not.
none
- Also: .claude/agents/contributor.md, tools/agent_guard.sh, .claude/workflows/deliver-change.js, CLAUDE.md
- Category: pipeline
- Added: 2026-11-20

### Two writers of the merged commit
- Location: .claude/agents/merger.md:29
- Why: merged now has two writers, the merger's set CHANGE merged in step 7 and the close's phase CHANGE merge, so there is no one clear way to record a merge.
- Fix: in a follow-up, let the merge phase be the one writer and drop set merged from the merger's step 7 line (keeping lane-close and the branch cleanup), or state in the merger file that the close fills it when step 7 did not run.
- Category: pipeline
- Added: 2026-11-20

### The merge phase spends output its work does not need on a green first CI (vim-folds-c retro 4, near-same to the pool's merge-output-cap)
- Location: .claude/agents/merger.md and the merge phase of .claude/workflows/deliver-change.js; docs/queue-backlog.md Pool `merge-output-cap`
- Why: vim-folds-c merge 32,655 output in 13 calls (11.2% of 292,577) with CI green in 9.6 min, 0 fixes, and 6 wait calls; the last 10 feature-lane merges have a median of 11,294 output (6,047 to 38,220).
- Fix: fold into `merge-output-cap`; accepted when, over the next 3 runs with a green first CI and no fix, merge output stays under 12,000 and CI-wait calls at most 4.
- Also: .claude/workflows/deliver-change.js, docs/queue-backlog.md
- Category: pipeline
- Added: 2026-11-20

### Main's short sha is still copied by hand in the merger and quality reviewer
- Location: .claude/agents/merger.md:28 (rule 6), .claude/agents/quality-reviewer.md:22 (rule 5) and :41 (skeptic mode)
- Why: they still ask the agent to copy `git rev-parse --short=12 origin/main` or `HEAD` of main into a result or a note; `tools/lane_facts.sh` reads a lane, not main, so this change left them, and a typed or placeholder sha there is the same defect head-form-restart named for the contributor.
- Fix: give the workflow (or a main mode of the script) the read of origin/main's head and compare or replace the reported value, as `laneHead` and `headForm` do for the contributor, then point those lines at it.
- Also: .claude/agents/quality-reviewer.md, tools/lane_facts.sh
- Category: pipeline
- Added: 2026-11-21
