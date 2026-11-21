### Main's short sha is still copied by hand in the merger and quality reviewer
- Location: .claude/agents/merger.md:28 (rule 6), .claude/agents/quality-reviewer.md:22 (rule 5) and :41 (skeptic mode)
- Why: they still ask the agent to copy `git rev-parse --short=12 origin/main` or `HEAD` of main into a result or a note; `tools/lane_facts.sh` reads a lane, not main, so this change left them, and a typed or placeholder sha there is the same defect head-form-restart named for the contributor.
- Fix: give the workflow (or a main mode of the script) the read of origin/main's head and compare or replace the reported value, as `laneHead` and `headForm` do for the contributor, then point those lines at it.

### An agent's git fetch in the shared toolchain clone voids a lane's check
- Location: tools/agent_guard.sh (the hook's working directory is never read), and the agents' starting directory, the main checkout's tmp/.spinel, which every lane links as its tmp/.spinel.
- Why: the check of contributor-harness at 142649463415 passed every stage and was voided by writes to tmp/.spinel/.git (FETCH_HEAD, a pack, refs/remotes/origin/master), whose reflog records a plain `fetch -q origin` at 18:28:13 UTC, the form the reviewers' and planner's step 1 runs, made from the agents' starting directory while the stages ran; no stage and no line of this change fetches there, so a sound check counted as failed and cost a round.
- Fix: have tools/agent_guard.sh refuse a git call whose hook working directory is neither the project nor a tmp/.NAME worktree of it (or make the workflow start agents in the project), with a tools-test case for a fetch from tmp/.spinel.

### The merger profile can run a lane worktree's copies of run_state.sh and ci_wait.sh
- Location: tools/agent_guard.sh:717 (script_form, merger profile)
- Why: security Low, confidence 6, predating this change: after `cd tmp/.lane-CHANGE` the merger profile still allows tools/run_state.sh and tools/ci_wait.sh, so a branch, or code its checks run, that rewrites either script in the lane worktree runs arbitrary code with the merger's GitHub merge rights, outside every guard form; task 7.1 of the change named this entry.
- Fix: in script_form, refuse every tools/*.sh form of the merger profile while cd_worktree is set, as the open_pr.sh message and lane_facts.sh cases already are, keeping MERGE_GATES exempt as main's copy in tmp/.merge-gates; add a tools_test case for each refusal.
none
