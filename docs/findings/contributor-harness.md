### Main's short sha is still copied by hand in the merger and quality reviewer
- Location: .claude/agents/merger.md:28 (rule 6), .claude/agents/quality-reviewer.md:22 (rule 5) and :41 (skeptic mode)
- Why: they still ask the agent to copy `git rev-parse --short=12 origin/main` or `HEAD` of main into a result or a note; `tools/lane_facts.sh` reads a lane, not main, so this change left them, and a typed or placeholder sha there is the same defect head-form-restart named for the contributor.
- Fix: give the workflow (or a main mode of the script) the read of origin/main's head and compare or replace the reported value, as `laneHead` and `headForm` do for the contributor, then point those lines at it.
