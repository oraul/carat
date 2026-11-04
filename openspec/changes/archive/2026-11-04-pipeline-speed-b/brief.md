# Brief

pipeline-speed-b: docs/queue.md item 1 as the planner wrote it (T1 user decision, estimated medium). The next item is already decided, so no planner decision is needed. Also: agents left stray scratch files in the repository root twice (build_check_out_tmp, .err); if it fits, scratch output goes under build/ or tmp/ and a gate refuses an untracked file outside the ignored paths at push time; otherwise record it in docs/backlog.md. Security review is never skipped.
