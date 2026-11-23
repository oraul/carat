# Backlog: .claude/agents/benchmark.md

### The benchmark's release timing needs the base build the change removed from the common path
- Location: `.claude/agents/benchmark.md` step 4
- Why: step 4 now runs only when the brief states a time target, so a slowdown above ten percent on a change with no target is no longer reported (it was never blocking)
- Fix: store the release timing of main beside its figures, measured once per merge, and report against it
- Category: pipeline
- Added: 2026-11-23
